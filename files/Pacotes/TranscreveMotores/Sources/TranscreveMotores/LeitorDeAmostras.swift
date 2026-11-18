import AVFoundation

/// Lê o áudio aos poucos já no formato do Parakeet (16 kHz, mono, Float32). Um único conversor atravessa o arquivo
/// inteiro, na qualidade padrão, como o FluidAudio faz nos áudios de mais de 30 s (a qualidade "Mastering" deixava a
/// leitura tão lenta quanto a transcrição). A transcrição começa sem esperar o arquivo todo, e a memória não cresce
/// com a duração.
final class LeitorDeAmostras {
    static let taxa = 16_000.0

    private let arquivo: AVAudioFile
    private let bloco: AVAudioPCMBuffer       // um pedaço do arquivo, no formato de leitura (N canais)
    private let mono: AVAudioPCMBuffer        // o mesmo pedaço em mono, na taxa original
    private let saida: AVAudioPCMBuffer?      // ~1 s já em 16 kHz
    private let conversor: AVAudioConverter?  // nil quando o arquivo já está em 16 kHz
    private var arquivoAcabou = false
    private var leuAlgo = false
    /// O áudio terminou: `proximoBloco()` já devolveu `nil`.
    private(set) var acabou = false

    init(_ url: URL) throws {
        arquivo = try AVAudioFile(forReading: url)
        let formato = arquivo.processingFormat
        let quadros = AVAudioFrameCount(max(4096, Int(formato.sampleRate)))
        guard
            let monoFormato = AVAudioFormat(
                commonFormat: .pcmFormatFloat32, sampleRate: formato.sampleRate, channels: 1, interleaved: false),
            let destino = AVAudioFormat(
                commonFormat: .pcmFormatFloat32, sampleRate: Self.taxa, channels: 1, interleaved: false),
            let bloco = AVAudioPCMBuffer(pcmFormat: formato, frameCapacity: quadros),
            let mono = AVAudioPCMBuffer(pcmFormat: monoFormato, frameCapacity: quadros)
        else { throw ErroDeTranscricao.formatoNaoSuportado(url.pathExtension.lowercased()) }
        self.bloco = bloco
        self.mono = mono
        if formato.sampleRate == Self.taxa {
            conversor = nil
            saida = nil
        } else {
            guard let conversor = AVAudioConverter(from: monoFormato, to: destino),
                  let saida = AVAudioPCMBuffer(pcmFormat: destino, frameCapacity: AVAudioFrameCount(Self.taxa))
            else { throw ErroDeTranscricao.formatoNaoSuportado(url.pathExtension.lowercased()) }
            self.conversor = conversor
            self.saida = saida
        }
    }

    /// As próximas amostras (cerca de 1 s), ou `nil` no fim do áudio.
    func proximoBloco() throws -> [Float]? {
        if acabou { return nil }
        guard let conversor, let saida else {
            guard try lerDoArquivo() else {
                acabou = true
                return nil
            }
            return Self.amostras(de: mono)
        }

        var falha: Error?
        var erro: NSError?
        saida.frameLength = 0
        let status = conversor.convert(to: saida, error: &erro) { _, situacao in
            do {
                if try self.lerDoArquivo() {
                    situacao.pointee = .haveData
                    return self.mono
                }
            } catch {
                falha = error
            }
            situacao.pointee = .endOfStream
            return nil
        }
        if let falha { throw falha }
        if status == .error { throw erro ?? ErroDeTranscricao.conversaoFalhou("") }
        if status == .endOfStream { acabou = saida.frameLength == 0 }
        if saida.frameLength == 0 {
            acabou = true
            return nil
        }
        // Depois do fim do arquivo o conversor ainda pode devolver o resto do filtro: a próxima chamada pega.
        return Self.amostras(de: saida)
    }

    /// Lê um pedaço do arquivo e o mistura em mono. `false` no fim.
    private func lerDoArquivo() throws -> Bool {
        guard !arquivoAcabou, arquivo.framePosition < arquivo.length else {
            arquivoAcabou = true
            return false
        }
        let restante = AVAudioFrameCount(arquivo.length - arquivo.framePosition)
        do {
            try arquivo.read(into: bloco, frameCount: min(bloco.frameCapacity, restante))
        } catch {
            // Em MP3/AAC o `length` é uma estimativa e a leitura do finalzinho às vezes falha: o que dava para
            // ler já foi lido (o FluidAudio faz o mesmo). Falhar na primeira leitura é arquivo ruim de verdade.
            if !leuAlgo { throw error }
            arquivoAcabou = true
            return false
        }
        guard bloco.frameLength > 0, let origem = bloco.floatChannelData, let destino = mono.floatChannelData else {
            arquivoAcabou = true
            return false
        }
        leuAlgo = true
        let quadros = Int(bloco.frameLength)
        let canais = Int(bloco.format.channelCount)
        if canais == 1 {
            destino[0].update(from: origem[0], count: quadros)
        } else {
            let peso = 1 / Float(canais)
            for i in 0..<quadros {
                var soma: Float = 0
                for c in 0..<canais { soma += origem[c][i] }
                destino[0][i] = soma * peso
            }
        }
        mono.frameLength = bloco.frameLength
        return true
    }

    private static func amostras(de buffer: AVAudioPCMBuffer) -> [Float] {
        guard let canal = buffer.floatChannelData else { return [] }
        return Array(UnsafeBufferPointer(start: canal[0], count: Int(buffer.frameLength)))
    }
}
