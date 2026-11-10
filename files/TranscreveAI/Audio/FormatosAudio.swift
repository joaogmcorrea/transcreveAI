import AVFoundation
import UniformTypeIdentifiers

/// Quais arquivos o app aceita e o que dá para saber deles antes de transcrever.
enum FormatosAudio {
    /// Formatos que o macOS nem sempre reconhece como áudio pelo tipo, mas que o app aceita
    /// (os que o AVFoundation não lê serão convertidos pelo FFmpeg a partir da v0.4).
    static let extensoesExtras: Set<String> = [
        "opus", "ogg", "oga", "webm", "wma", "mkv", "amr", "3gp", "m4b", "flac", "caf",
    ]

    /// Tipos para o seletor de arquivos.
    static var tipos: [UTType] {
        [.audio, .audiovisualContent] + extensoesExtras.compactMap { UTType(filenameExtension: $0) }
    }

    static func aceita(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        let extensao = url.pathExtension.lowercased()
        if extensoesExtras.contains(extensao) { return true }
        guard let tipo = UTType(filenameExtension: extensao) else { return false }
        return tipo.conforms(to: .audio) || tipo.conforms(to: .audiovisualContent)
    }

    /// Duração lida pelo AVFoundation; `nil` nos formatos que ele não abre (Opus, OGG…).
    static func duracao(de url: URL) async -> TimeInterval? {
        let asset = AVURLAsset(url: url)
        guard let tempo = try? await asset.load(.duration), tempo.isNumeric, tempo.seconds > 0 else { return nil }
        return tempo.seconds
    }

    static func formatar(duracao: TimeInterval) -> String {
        let total = Int(duracao.rounded())
        let horas = total / 3600, minutos = (total % 3600) / 60, segundos = total % 60
        return horas > 0
            ? String(format: "%d:%02d:%02d", horas, minutos, segundos)
            : String(format: "%d:%02d", minutos, segundos)
    }
}
