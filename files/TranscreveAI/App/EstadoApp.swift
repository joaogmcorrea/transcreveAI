import AppKit
import Foundation
import Observation
import TranscreveMotores

/// O que o painel e o ícone mostram, e quem conduz a transcrição: escolhe o motor, acompanha o progresso,
/// guarda o resultado, copia ou exporta o texto ao terminar e passa para o próximo áudio da fila.
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
        /// O texto que já saiu, em parágrafos: o painel mostra enquanto o resto é transcrito.
        var paragrafos: [Segmento] = []
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

    /// O que fazer com o texto: mostrar no painel (arrastar, abrir, "Abrir com") ou, pelo botão direito do
    /// Finder, copiar ou salvar um .txt ao lado do áudio, sem abrir o painel.
    enum Destino: String, Equatable {
        case painel, copiar, exportarTxt
    }

    struct Pedido: Equatable {
        var arquivo: ArquivoAudio
        var destino: Destino
    }

    private(set) var arquivo: ArquivoAudio?
    private(set) var fase: Fase = .vazio
    private(set) var aviso: String?
    /// Nota sobre o Parakeet baixando em segundo plano (enquanto o Apple Speech cobre a transcrição).
    private(set) var notaDoModelo: String?
    /// Nota sobre o fim da fila: o que foi copiado ou exportado e o que falhou.
    private(set) var notaDaFila: String?
    /// O painel mostra a lista completa do histórico em vez da área de arrastar.
    var mostrandoHistorico = false
    /// O aviso "Copiado" que aparece por 2 s no painel depois de copiar um texto.
    private(set) var mostrandoCopiado = false
    private var tarefaDoCopiado: Task<Void, Never>?

    /// Os áudios que esperam a vez, na ordem em que chegaram (vários soltos de uma vez, ou o botão direito do
    /// Finder com vários selecionados). Um áudio que chega durante uma transcrição entra no fim da fila.
    private(set) var fila: [Pedido] = []
    private var atual: Pedido?
    /// A leva: os áudios que se seguiram sem pausa (zera quando a fila esvazia).
    private var feitosNaLeva = 0
    private var falhasNaLeva: [String] = []
    private var copiadosNaLeva: [(nome: String, paragrafos: [Segmento])] = []
    private var exportadosNaLeva: [URL] = []
    /// Conta cada entrega aceita (para o painel aberto por um arraste saber se o arquivo veio para ele).
    private(set) var recebimentos = 0

    enum Fim { case pronto, entregue, erro }

    /// O ícone da barra acompanha: fração de 0 a 1 enquanto transcreve, `nil` quando para, e o `Fim` quando termina.
    /// `.entregue`: o texto já foi copiado ou exportado (botão direito do Finder), sem nada novo para ver no painel.
    var aoMudarProgresso: ((_ fracao: Double?, _ fim: Fim?) -> Void)?

    private var tarefa: Task<Void, Never>?

    /// "2 de 3" enquanto há uma fila; `nil` com um áudio só.
    var posicaoNaFila: (atual: Int, total: Int)? {
        let total = feitosNaLeva + 1 + fila.count
        guard total > 1, case .trabalhando = fase else { return nil }
        return (feitosNaLeva + 1, total)
    }

    /// O progresso do áudio atual.
    var progressoAtual: Double? {
        guard case .trabalhando(let trabalho) = fase else { return nil }
        if let baixando = trabalho.baixando { return baixando }
        if case .transcrevendo(let fracao) = trabalho.etapa { return fracao }
        return 0
    }

    /// O ícone mostra a fila inteira: com 3 áudios, o fim do primeiro é 33%.
    private var progressoDaLeva: Double? {
        guard let fracao = progressoAtual else { return nil }
        guard let posicao = posicaoNaFila else { return fracao }
        return (Double(posicao.atual - 1) + fracao) / Double(posicao.total)
    }

    private var trabalhando: Bool {
        if case .trabalhando = fase { return true }
        return false
    }

    // MARK: Receber e transcrever

    /// Aceita os áudios da lista: o primeiro já começa (ou, se outro está sendo transcrito, todos entram na fila).
    /// Devolve `false` quando nenhum é áudio.
    @discardableResult
    func receber(_ urls: [URL], destino: Destino = .painel) -> Bool {
        let audios = urls.filter(FormatosAudio.aceita)
        guard !audios.isEmpty else {
            if destino == .painel {
                aviso = urls.isEmpty ? nil : String(localized: "Esse arquivo não parece ser um áudio.")
            }
            return false
        }
        recebimentos += 1
        let pedidos = audios.map { Pedido(arquivo: ArquivoAudio(url: $0), destino: destino) }
        if trabalhando {
            fila += pedidos
            informarProgresso()
            return true
        }
        aviso = nil
        notaDaFila = nil
        feitosNaLeva = 0
        falhasNaLeva = []
        copiadosNaLeva = []
        exportadosNaLeva = []
        fila = Array(pedidos.dropFirst())
        comecar(pedidos[0])
        return true
    }

    private func comecar(_ pedido: Pedido) {
        tarefa?.cancel()
        rodada += 1
        atual = pedido
        arquivo = pedido.arquivo
        mostrandoHistorico = false
        tarefa = Task { await transcrever(pedido) }
    }

    /// Para o áudio atual e esvazia a fila.
    func cancelar() {
        limpar()
    }

    func limpar() {
        tarefa?.cancel()
        tarefa = nil
        atual = nil
        fila = []
        arquivo = nil
        aviso = nil
        notaDaFila = nil
        fase = .vazio
        aoMudarProgresso?(nil, nil)
    }

    // MARK: Histórico

    /// Reabre uma transcrição guardada no painel.
    func abrir(_ resumo: Historico.Resumo) {
        guard let paragrafos = Historico.compartilhado.paragrafos(de: resumo.id) else {
            Historico.compartilhado.apagar(resumo.id)
            aviso = String(localized: "Não encontrei essa transcrição no histórico.")
            return
        }
        tarefa?.cancel()
        tarefa = nil
        atual = nil
        fila = []
        aviso = nil
        notaDaFila = nil
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
        avisarCopiado()
        return true
    }

    /// Copia o texto da transcrição aberta (clique no texto do painel). Durante a transcrição, copia o que já
    /// saiu (pedido do owner); o resto continua chegando.
    func copiarResultado() {
        let paragrafos: [Segmento]
        switch fase {
        case .pronto(let transcricao): paragrafos = transcricao.paragrafos
        case .trabalhando(let trabalho): paragrafos = trabalho.paragrafos
        default: return
        }
        guard !paragrafos.isEmpty else { return }
        Self.copiarTexto(paragrafos)
        avisarCopiado()
    }

    /// Mostra o "Copiado" por 2 s; uma cópia nova reinicia a contagem.
    func avisarCopiado() {
        mostrandoCopiado = true
        tarefaDoCopiado?.cancel()
        tarefaDoCopiado = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            mostrandoCopiado = false
        }
    }

    static func copiarTexto(_ paragrafos: [Segmento]) {
        copiar(Paragrafos.texto(paragrafos))
    }

    private static func copiar(_ texto: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(texto, forType: .string)
    }

    func tentarDeNovo() {
        guard let arquivo else { return }
        receber([arquivo.url], destino: atual?.destino ?? .painel)
    }

    private func transcrever(_ pedido: Pedido) async {
        let alvo = pedido.arquivo
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
                // No automático, se o Parakeet falhar, o Apple Speech tenta (do começo: some o que já tinha saído).
                motor = .apple
                if case .trabalhando(var trabalho) = fase {
                    trabalho.paragrafos = []
                    fase = .trabalhando(trabalho)
                }
                frases = try await rodar(.apple, audio: audio, idioma: idioma)
            }
            try Task.checkCancellation()
            let segundos = Date().timeIntervalSince(inicio)
            let paragrafos = Paragrafos.agrupar(frases)
            let copiado = entregar(paragrafos, de: pedido)
            Historico.compartilhado.adicionar(arquivo: arquivo ?? alvo, paragrafos: paragrafos, motor: motor, segundos: segundos)
            terminou(Transcricao(paragrafos: paragrafos, motor: motor, segundos: segundos, copiado: copiado))
        } catch is CancellationError {
            return
        } catch {
            guard arquivo?.id == alvo.id else { return }
            falhasNaLeva.append(alvo.nome)
            terminou(nil, erro: error.localizedDescription)
        }
    }

    /// Um áudio terminou: segue para o próximo da fila ou fecha a leva (som, ícone e notas).
    private func terminou(_ transcricao: Transcricao?, erro: String? = nil) {
        feitosNaLeva += 1
        if !fila.isEmpty {
            comecar(fila.removeFirst())
            return
        }
        notaDaFila = notaDoFim()
        let soPeloFinder = atual.map { $0.destino != .painel } ?? false
        if let transcricao {
            fase = .pronto(transcricao)
            if transcricao.copiado { avisarCopiado() }
        } else {
            fase = .erro(erro ?? "")
        }
        if falhasNaLeva.isEmpty {
            tocarSom("Glass")
            aoMudarProgresso?(nil, soPeloFinder ? .entregue : .pronto)
        } else {
            tocarSom("Basso")
            aoMudarProgresso?(nil, .erro)
        }
    }

    /// Copia ou exporta o texto conforme o destino. Devolve `true` se o texto foi para a área de transferência.
    private func entregar(_ paragrafos: [Segmento], de pedido: Pedido) -> Bool {
        switch pedido.destino {
        case .painel:
            return copiarSePedido(paragrafos)
        case .copiar:
            guard !paragrafos.isEmpty else { return false }
            copiadosNaLeva.append((pedido.arquivo.nome, paragrafos))
            // Vários áudios: tudo junto, cada texto com o nome do arquivo em cima. A cada áudio a cópia é refeita,
            // então a área de transferência já tem o que terminou, mesmo se a pessoa cancelar o resto.
            if copiadosNaLeva.count == 1 {
                Self.copiarTexto(paragrafos)
            } else {
                Self.copiar(copiadosNaLeva
                    .map { "\($0.nome)\n\n\(Paragrafos.texto($0.paragrafos))" }
                    .joined(separator: "\n\n\n"))
            }
            return true
        case .exportarTxt:
            guard !paragrafos.isEmpty else { return false }
            do {
                exportadosNaLeva.append(try Exportacao.txt(paragrafos, ao: pedido.arquivo.url))
            } catch {
                falhasNaLeva.append(pedido.arquivo.nome)
            }
            return false
        }
    }

    /// O que dizer no painel no fim da fila: onde o texto foi parar e o que não deu certo.
    private func notaDoFim() -> String? {
        var partes: [String] = []
        if copiadosNaLeva.count > 1 {
            partes.append(String(localized: "O texto dos \(copiadosNaLeva.count) áudios foi copiado."))
        }
        if exportadosNaLeva.count == 1, let unico = exportadosNaLeva.first {
            partes.append(String(localized: "Salvo como \(unico.lastPathComponent), ao lado do áudio."))
        } else if exportadosNaLeva.count > 1 {
            partes.append(String(localized: "\(exportadosNaLeva.count) arquivos .txt salvos ao lado dos áudios."))
        }
        if !falhasNaLeva.isEmpty {
            partes.append(String(localized: "Não consegui transcrever: \(falhasNaLeva.joined(separator: ", "))."))
        }
        return partes.isEmpty ? nil : partes.joined(separator: " ")
    }

    /// Cada chamada a um motor tem um número: um aviso de progresso atrasado (de um áudio que já terminou, ou do
    /// Parakeet depois que o Apple Speech assumiu) não se mistura com o texto do seguinte.
    private var rodada = 0

    private func rodar(_ motor: Motor, audio: AudioPronto, idioma: IdiomaAudio) async throws -> [Segmento] {
        rodada += 1
        let esta = rodada
        let atualizar: @Sendable (Progresso) -> Void = { [weak self] progresso in
            Task { @MainActor in
                guard let self, self.rodada == esta else { return }
                self.atualizar(progresso, motor: motor)
            }
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
        if !progresso.previa.isEmpty { trabalho.paragrafos = Paragrafos.agrupar(progresso.previa) }
        fase = .trabalhando(trabalho)
        informarProgresso()
    }

    private func informarProgresso() {
        aoMudarProgresso?(progressoDaLeva, nil)
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
        notaDoModelo = String(localized: "Baixando o Parakeet v3 (470 MB) para as próximas transcrições…")
        Task {
            do {
                try await MotorParakeet.compartilhado.preparar { [weak self] preparo in
                    Task { @MainActor in
                        switch preparo {
                        case .baixando(let fracao):
                            self?.notaDoModelo = String(
                                localized: "Baixando o Parakeet v3 para as próximas transcrições… \(Int(fracao * 100))%")
                        case .compilando:
                            self?.notaDoModelo = String(
                                localized: "Preparando o Parakeet v3 para as próximas transcrições…")
                        }
                    }
                }
                notaDoModelo = nil
            } catch {
                notaDoModelo = String(
                    localized: "Não consegui baixar o Parakeet v3; o Apple Speech continua transcrevendo.")
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
