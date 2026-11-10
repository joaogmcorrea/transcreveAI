import FluidAudio
import Foundation

/// Parakeet TDT v3 (FluidAudio, CoreML): o padrão do "Automático", o mais rápido no benchmark (145× tempo real).
/// O modelo (~470 MB) é baixado uma vez para Application Support/TranscreveAI/Modelos e fica carregado na
/// memória depois do primeiro uso: a primeira carga compila para o Neural Engine e leva uns 40 s.
public actor MotorParakeet {
    public static let compartilhado = MotorParakeet()

    private let pasta: URL
    private var asr: AsrManager?
    private var camadas = 2
    private var preparo: Task<Void, Error>?

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TranscreveAI/Modelos", isDirectory: true)
        pasta = base.appendingPathComponent(
            AsrModels.defaultCacheDirectory(for: .v3).lastPathComponent, isDirectory: true)
    }

    /// O modelo já está no disco (pode ainda não estar carregado).
    public var baixado: Bool { AsrModels.modelsExist(at: pasta, version: .v3) }

    /// Carregado na memória: a próxima transcrição começa na hora.
    public var pronto: Bool { asr != nil }

    public enum Preparo: Sendable {
        case baixando(Double)  // 0…1
        case compilando
    }

    /// Baixa (se precisar) e carrega o modelo. Chamadas ao mesmo tempo esperam o mesmo preparo.
    public func preparar(progresso: (@Sendable (Preparo) -> Void)? = nil) async throws {
        if asr != nil { return }
        if let preparo { return try await preparo.value }
        let pasta = self.pasta
        let tarefa = Task {
            // O FluidAudio conta o download de 0 a 50% e a compilação de 50 a 100%.
            let modelos = try await AsrModels.downloadAndLoad(to: pasta, version: .v3, progressHandler: { p in
                switch p.phase {
                case .listing, .downloading: progresso?(.baixando(min(1, p.fractionCompleted * 2)))
                case .compiling: progresso?(.compilando)
                }
            })
            let gerente = AsrManager(config: .default)
            try await gerente.loadModels(modelos)
            self.instalar(gerente, camadas: modelos.version.decoderLayers)
        }
        preparo = tarefa
        do {
            try await tarefa.value
            preparo = nil
        } catch {
            preparo = nil
            throw error
        }
    }

    private func instalar(_ gerente: AsrManager, camadas: Int) {
        asr = gerente
        self.camadas = camadas
    }

    /// `idioma`: "pt", "en", "es"… ou `nil` para detectar sozinho.
    public func transcrever(
        _ audio: AudioPronto, idioma: String?, progresso: @escaping @Sendable (Progresso) -> Void
    ) async throws -> [Segmento] {
        if asr == nil {
            progresso(Progresso(etapa: .preparandoModelo))
            try await preparar()
        }
        guard let asr else { throw ErroDeTranscricao.modeloIndisponivel("Parakeet v3") }
        progresso(Progresso(etapa: .transcrevendo(0)))

        // O FluidAudio só emite progresso para áudios de mais de ~15 s.
        let fluxo = await asr.transcriptionProgressStream
        let acompanhar = Task {
            for try await fracao in fluxo { progresso(Progresso(etapa: .transcrevendo(fracao))) }
        }
        defer { acompanhar.cancel() }

        var estado = try TdtDecoderState(decoderLayers: camadas)
        let resultado = try await asr.transcribe(
            audio.url, decoderState: &estado, language: idioma.flatMap { Language(rawValue: $0) })
        try Task.checkCancellation()
        return Paragrafos.frases(tokens: resultado.tokenTimings, texto: resultado.text, duracao: audio.duracao)
    }
}
