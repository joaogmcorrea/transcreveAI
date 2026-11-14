import AVFoundation

/// O áudio pronto para os motores: o arquivo original, quando o macOS abre, ou um WAV temporário convertido.
public struct AudioPronto: Sendable {
    public let url: URL
    public let duracao: TimeInterval
    let temporario: Bool

    /// Apaga o WAV temporário, se houver.
    public func descartar() {
        if temporario { try? FileManager.default.removeItem(at: url) }
    }
}

public enum AudioDeEntrada {
    /// O macOS 27 abre sozinho MP3, M4A/AAC, MP4/MOV, WAV, AIFF, FLAC, OGG e Opus (o do WhatsApp). O resto
    /// (WebM, WMA, MKV, AMR…) vira um WAV 16 kHz mono temporário pelo FFmpeg embutido no app.
    public static func preparar(_ url: URL, ffmpeg: URL?) async throws -> AudioPronto {
        if let duracao = duracaoNativa(url) {
            return AudioPronto(url: url, duracao: duracao, temporario: false)
        }
        guard let ffmpeg, FileManager.default.isExecutableFile(atPath: ffmpeg.path) else {
            throw ErroDeTranscricao.formatoNaoSuportado(url.pathExtension.lowercased())
        }
        let destino = FileManager.default.temporaryDirectory
            .appendingPathComponent("transcreveai-\(UUID().uuidString).wav")
        try await converter(url, para: destino, ffmpeg: ffmpeg)
        guard let duracao = duracaoNativa(destino) else {
            try? FileManager.default.removeItem(at: destino)
            throw ErroDeTranscricao.conversaoFalhou(String(localized: "O arquivo convertido ficou vazio.", bundle: .module))
        }
        return AudioPronto(url: destino, duracao: duracao, temporario: true)
    }

    static func duracaoNativa(_ url: URL) -> TimeInterval? {
        guard let arquivo = try? AVAudioFile(forReading: url), arquivo.length > 0 else { return nil }
        return Double(arquivo.length) / arquivo.fileFormat.sampleRate
    }

    private static func converter(_ origem: URL, para destino: URL, ffmpeg: URL) async throws {
        try await withCheckedThrowingContinuation { (continuacao: CheckedContinuation<Void, Error>) in
            let processo = Process()
            processo.executableURL = ffmpeg
            processo.arguments = [
                "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
                "-i", origem.path, "-vn", "-ac", "1", "-ar", "16000", "-c:a", "pcm_s16le", destino.path,
            ]
            let erros = Pipe()
            processo.standardError = erros
            processo.standardOutput = FileHandle.nullDevice
            processo.terminationHandler = { terminado in
                if terminado.terminationStatus == 0 {
                    continuacao.resume()
                } else {
                    let detalhe = String(data: erros.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                    continuacao.resume(throwing: ErroDeTranscricao.conversaoFalhou(
                        detalhe.split(separator: "\n").last.map(String.init) ?? ""))
                }
            }
            do {
                try processo.run()
            } catch {
                continuacao.resume(throwing: error)
            }
        }
    }
}
