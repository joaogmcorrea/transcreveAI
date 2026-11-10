// transcrever <áudio> [parakeet|apple] [idioma] — testa os motores pelo terminal, sem o app.
// O FFmpeg (formatos que o macOS não abre) vem de TRANSCREVE_FFMPEG ou do Homebrew.
import Foundation
import TranscreveMotores

let argumentos = CommandLine.arguments
guard argumentos.count >= 2 else {
    print("uso: transcrever <áudio> [parakeet|apple] [idioma]")
    exit(1)
}
let entrada = URL(fileURLWithPath: argumentos[1])
let motor = Motor(rawValue: argumentos.count > 2 ? argumentos[2] : "parakeet") ?? .parakeet
let idioma = argumentos.count > 3 ? argumentos[3] : nil
let ffmpeg = ProcessInfo.processInfo.environment["TRANSCREVE_FFMPEG"].map { URL(fileURLWithPath: $0) }
    ?? URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg")

func relogio(_ segundos: TimeInterval) -> String {
    let total = Int(segundos)
    return String(format: "%02d:%02d", total / 60, total % 60)
}

let progresso: @Sendable (Progresso) -> Void = { p in
    if case .transcrevendo(let fracao) = p.etapa {
        FileHandle.standardError.write("\r  \(Int(fracao * 100))%   ".data(using: .utf8)!)
    } else {
        FileHandle.standardError.write("\r  \(p.etapa)   ".data(using: .utf8)!)
    }
}

do {
    let audio = try await AudioDeEntrada.preparar(entrada, ffmpeg: ffmpeg)
    defer { audio.descartar() }
    if motor == .parakeet {
        let carga = Date()
        try await MotorParakeet.compartilhado.preparar { etapa in
            let texto = switch etapa {
            case .baixando(let fracao): "baixando \(Int(fracao * 100))%"
            case .compilando: "preparando o modelo"
            }
            FileHandle.standardError.write("\r  \(texto)   ".data(using: .utf8)!)
        }
        FileHandle.standardError.write("\r  modelo pronto em \(String(format: "%.1f", Date().timeIntervalSince(carga))) s\n".data(using: .utf8)!)
    }
    let inicio = Date()
    let frases = motor == .parakeet
        ? try await MotorParakeet.compartilhado.transcrever(audio, idioma: idioma, progresso: progresso)
        : try await MotorApple.transcrever(audio, idioma: idioma, progresso: progresso)
    let tempo = Date().timeIntervalSince(inicio)
    FileHandle.standardError.write("\r".data(using: .utf8)!)
    if ProcessInfo.processInfo.environment["TRANSCREVE_FRASES"] != nil {
        for f in frases { print(String(format: "  %.2f–%.2f  %@", f.inicio, f.fim, f.texto)) }
        print()
    }
    for paragrafo in Paragrafos.agrupar(frases) {
        print("[\(relogio(paragrafo.inicio))] \(paragrafo.texto)")
    }
    print(String(format: "\n%@ · áudio %.0f s · transcrito em %.2f s (%.0f× tempo real) · %d frases",
                 motor.nome, audio.duracao, tempo, audio.duracao / max(tempo, 0.001), frases.count))
} catch {
    print("erro: \(error.localizedDescription)")
    exit(1)
}
