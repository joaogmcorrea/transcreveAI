import AppKit
import Foundation
import Observation
import TranscreveMotores

/// O que o painel e o ícone mostram, e quem conduz a transcrição: escolhe o motor, acompanha o progresso,
/// guarda o resultado e copia o texto ao terminar.
@Observable
final class EstadoApp {
    enum Fase: Equatable {
        case vazio
        case trabalhando(Trabalho)
        case pronto(Transcricao)
        case erro(String)
    }

    struct Trabalho: Equatable {
        var motor: Motor
        var etapa: Etapa
        var previa: [Segmento] = []
        var baixando: Double?  // fração do download do Parakeet, quando ele é o motor e ainda está baixando
    }

    struct Transcricao: Equatable {
        var paragrafos: [Segmento]
        var motor: Motor
        var segundos: TimeInterval
        var copiado: Bool
        /// Aberta do histórico (e quando), em vez de recém-transcrita.
        var doHistorico: Date? = nil

        var texto: String { Paragrafos.texto(paragrafos) }
    }

    private(set) var arquivo: ArquivoAudio?
    private(set) var fase: Fase = .vazio
    private(set) var aviso: String?
    /// Nota sobre o Parakeet baixando em segundo plano (enquanto o Apple Speech cobre a transcrição).
    private(set) var notaDoModelo: String?
    /// O painel mostra a lista completa do histórico em vez da área de arrastar.
    var mostrandoHistorico = false

    enum Fim { case pronto, erro }

    /// O ícone da barra acompanha: fração de 0 a 1 enquanto transcreve, `nil` quando para, e o `Fim` quando termina.
    var aoMudarProgresso: ((_ fracao: Double?, _ fim: Fim?) -> Void)?

    private var tarefa: Task<Void, Never>?

    var progressoAtual: Double? {
        guard case .trabalhando(let trabalho) = fase else { return nil }
        if let baixando = trabalho.baixando { return baixando }
        if case .transcrevendo(let fracao) = trabalho.etapa { return fracao }
        return 0
    }

    // MARK: Receber e transcrever

    /// Aceita o primeiro áudio da lista e já começa a transcrever. Devolve `false` quando nenhum é áudio.
    @discardableResult
    func receber(_ urls: [URL]) -> Bool {
        guard let url = urls.first(where: FormatosAudio.aceita) else {
            aviso = urls.isEmpty ? nil : "Esse arquivo não parece ser um áudio."
            return false
        }
        tarefa?.cancel()
        aviso = nil
        let novo = ArquivoAudio(url: url)
        arquivo = novo
        tarefa = Task { await transcrever(novo) }
        return true
    }

    func cancelar() {
        tarefa?.cancel()
        tarefa = nil
        limpar()
    }

    func limpar() {
        tarefa?.cancel()
        tarefa = nil
        arquivo = nil
        aviso = nil
        fase = .vazio
        aoMudarProgresso?(nil, nil)
    }

    // MARK: Histórico

    /// Reabre uma transcrição guardada no painel.
    func abrir(_ resumo: Historico.Resumo) {
        guard let paragrafos = Historico.compartilhado.paragrafos(de: resumo.id) else {
            Historico.compartilhado.apagar(resumo.id)
            aviso = "Não encontrei essa transcrição no histórico."
            return
        }
        tarefa?.cancel()
        tarefa = nil
        aviso = nil
        mostrandoHistorico = false
        arquivo = ArquivoAudio(url: URL(fileURLWithPath: resumo.caminho), duracao: resumo.duracao)
        fase = .pronto(Transcricao(
            paragrafos: paragrafos, motor: resumo.motor, segundos: resumo.segundos, copiado: false,
            doHistorico: resumo.data))
    }

    /// Copia o texto de uma transcrição guardada sem abri-la.
    @discardableResult
    func copiar(_ resumo: Historico.Resumo) -> Bool {
        guard let paragrafos = Historico.compartilhado.paragrafos(de: resumo.id) else { return false }
        Self.copiarTexto(paragrafos)
        return true
    }

    static func copiarTexto(_ paragrafos: [Segmento]) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(Paragrafos.texto(paragrafos), forType: .string)
    }

    func tentarDeNovo() {
        guard let arquivo else { return }
        receber([arquivo.url])
    }

    private func transcrever(_ alvo: ArquivoAudio) async {
        // Com o painel fechado o app fica sem janela: sem isto o macOS pode pô-lo em espera (App Nap) ou
        // dormir no meio de um áudio longo. A transcrição não depende do painel; só o Cancelar a interrompe.
        let atividade = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled], reason: "Transcrevendo um áudio")
        defer { ProcessInfo.processInfo.endActivity(atividade) }
        let modelo = ModeloTranscricao.atual
        let idioma = IdiomaAudio.atual
        var motor = await escolherMotor(para: modelo)
        fase = .trabalhando(Trabalho(motor: motor, etapa: .convertendo))
        informarProgresso()
        do {
            let audio = try await AudioDeEntrada.preparar(alvo.url, ffmpeg: Self.ffmpeg)
            defer { audio.descartar() }
            guard arquivo?.id == alvo.id else { return }
            arquivo?.duracao = audio.duracao

            if motor == .parakeet, !(await MotorParakeet.compartilhado.pronto) {
                // Carregar (e, na primeira vez neste app, compilar para o Neural Engine) leva alguns segundos.
                if case .trabalhando(var trabalho) = fase {
                    trabalho.etapa = .preparandoModelo
                    fase = .trabalhando(trabalho)
                }
                try await prepararParakeet()
            }
            let inicio = Date()
            let frases: [Segmento]
            do {
                frases = try await rodar(motor, audio: audio, idioma: idioma)
            } catch where motor == .parakeet && modelo == .automatico && !(error is CancellationError) {
                // No automático, se o Parakeet falhar, o Apple Speech tenta.
                motor = .apple
                frases = try await rodar(.apple, audio: audio, idioma: idioma)
            }
            try Task.checkCancellation()
            let segundos = Date().timeIntervalSince(inicio)
            let paragrafos = Paragrafos.agrupar(frases)
            let copiado = copiarSePedido(paragrafos)
            Historico.compartilhado.adicionar(arquivo: arquivo ?? alvo, paragrafos: paragrafos, motor: motor, segundos: segundos)
            fase = .pronto(Transcricao(paragrafos: paragrafos, motor: motor, segundos: segundos, copiado: copiado))
            tocarSom("Glass")
            aoMudarProgresso?(nil, .pronto)
        } catch is CancellationError {
            return
        } catch {
            guard arquivo?.id == alvo.id else { return }
            fase = .erro(error.localizedDescription)
            tocarSom("Basso")
            aoMudarProgresso?(nil, .erro)
        }
    }

    private func rodar(_ motor: Motor, audio: AudioPronto, idioma: IdiomaAudio) async throws -> [Segmento] {
        let atualizar: @Sendable (Progresso) -> Void = { [weak self] progresso in
            Task { @MainActor in self?.atualizar(progresso, motor: motor) }
        }
        switch motor {
        case .parakeet:
            return try await MotorParakeet.compartilhado.transcrever(
                audio, idioma: idioma.codigoParakeet, progresso: atualizar)
        case .apple:
            return try await MotorApple.transcrever(audio, idioma: idioma.codigoApple, progresso: atualizar)
        }
    }

    private func atualizar(_ progresso: Progresso, motor: Motor) {
        guard case .trabalhando(var trabalho) = fase else { return }
        trabalho.motor = motor
        trabalho.etapa = progresso.etapa
        trabalho.baixando = nil
        if !progresso.previa.isEmpty { trabalho.previa = progresso.previa }
        fase = .trabalhando(trabalho)
        informarProgresso()
    }

    private func informarProgresso() {
        aoMudarProgresso?(progressoAtual, nil)
    }

    /// Som do sistema ao terminar (Glass) ou ao falhar (Basso); desliga em … › Som ao terminar.
    private func tocarSom(_ nome: String) {
        let ligado = UserDefaults.standard.object(forKey: Preferencia.somAoTerminar) as? Bool ?? true
        if ligado { NSSound(named: NSSound.Name(nome))?.play() }
    }

    // MARK: Escolha do motor e preparo do Parakeet

    /// Automático: o Parakeet se ele já estiver no Mac; senão, o Apple Speech transcreve este arquivo e o
    /// Parakeet baixa em segundo plano para os próximos.
    private func escolherMotor(para modelo: ModeloTranscricao) async -> Motor {
        switch modelo {
        case .apple:
            return .apple
        case .parakeet:
            return .parakeet
        case .automatico, .whisperTurbo:
            let parakeet = MotorParakeet.compartilhado
            let pronto = await parakeet.pronto
            let baixado = await parakeet.baixado
            if pronto || baixado { return .parakeet }
            baixarParakeetEmSegundoPlano()
            return .apple
        }
    }

    /// Parakeet escolhido à mão e ainda não carregado: o painel mostra o download e o preparo.
    private func prepararParakeet() async throws {
        try await MotorParakeet.compartilhado.preparar { [weak self] preparo in
            Task { @MainActor in self?.mostrarPreparo(preparo) }
        }
    }

    private func mostrarPreparo(_ preparo: MotorParakeet.Preparo) {
        guard case .trabalhando(var trabalho) = fase, trabalho.motor == .parakeet else { return }
        switch preparo {
        case .baixando(let fracao):
            trabalho.baixando = fracao
            trabalho.etapa = .preparandoModelo
        case .compilando:
            trabalho.baixando = nil
            trabalho.etapa = .preparandoModelo
        }
        fase = .trabalhando(trabalho)
        informarProgresso()
    }

    private func baixarParakeetEmSegundoPlano() {
        guard notaDoModelo == nil else { return }
        notaDoModelo = "Baixando o Parakeet v3 (470 MB) para as próximas transcrições…"
        Task {
            do {
                try await MotorParakeet.compartilhado.preparar { [weak self] preparo in
                    Task { @MainActor in
                        switch preparo {
                        case .baixando(let fracao):
                            self?.notaDoModelo = "Baixando o Parakeet v3 para as próximas transcrições… \(Int(fracao * 100))%"
                        case .compilando:
                            self?.notaDoModelo = "Preparando o Parakeet v3 para as próximas transcrições…"
                        }
                    }
                }
                notaDoModelo = nil
            } catch {
                notaDoModelo = "Não consegui baixar o Parakeet v3; o Apple Speech continua transcrevendo."
            }
        }
    }

    /// Na abertura do app: se o Parakeet já está no Mac, carrega na memória para a primeira transcrição sair na hora.
    func aquecerMotor() {
        Task {
            let parakeet = MotorParakeet.compartilhado
            guard ModeloTranscricao.atual != .apple, await parakeet.baixado else { return }
            try? await parakeet.preparar()
        }
    }

    // MARK: Copiar ao terminar

    private func copiarSePedido(_ paragrafos: [Segmento]) -> Bool {
        let ligado = UserDefaults.standard.object(forKey: Preferencia.copiarAoTerminar) as? Bool ?? true
        guard ligado, !paragrafos.isEmpty else { return false }
        Self.copiarTexto(paragrafos)
        return true
    }

    /// O FFmpeg embutido (Contents/Helpers); nos builds de debug, o do Homebrew serve enquanto ele não existe.
    private static var ffmpeg: URL? {
        let embutido = Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/ffmpeg")
        if FileManager.default.isExecutableFile(atPath: embutido.path) { return embutido }
        #if DEBUG
        let homebrew = URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg")
        if FileManager.default.isExecutableFile(atPath: homebrew.path) { return homebrew }
        #endif
        return nil
    }
}

struct ArquivoAudio: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    var duracao: TimeInterval?

    var nome: String { url.lastPathComponent }

    var tamanho: Int64? {
        (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) }
    }
}
