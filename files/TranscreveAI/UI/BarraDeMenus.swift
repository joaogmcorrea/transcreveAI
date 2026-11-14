import AppKit
import SwiftUI

/// O ícone na barra de menus e o painel embaixo dele. Aceita áudio solto direto no ícone, abre o painel sozinho
/// quando um áudio começa a ser arrastado em qualquer app e mostra um menu curto no clique com o botão direito.
final class BarraDeMenus: NSObject, NSWindowDelegate, NSDraggingDestination {
    private let estado: EstadoApp
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let simbolo: NSImage? = {
        let imagem = NSImage(systemSymbolName: "waveform", accessibilityDescription: "TranscreveAI")
        imagem?.isTemplate = true
        return imagem
    }()
    private var progressoNoIcone: Double?
    private var concluidoAte: Date?
    /// Terminou (ou falhou) com o painel fechado e a pessoa ainda não abriu: bolinha vermelha no ícone.
    private var resultadoNaoVisto = false
    private let painel = PainelFlutuante()
    private let detector = DetectorDeArraste()
    private var janelaAjustes: NSWindow?
    private var monitores: [Any] = []
    private var iconeNaTela: NSRect = .zero
    private var abertoPorArraste = false
    private var arquivoAntesDoArraste: UUID?

    init(estado: EstadoApp) {
        self.estado = estado
        super.init()
        painel.definirConteudo(PainelView(
            estado: estado,
            historico: .compartilhado,
            escolherArquivo: { [weak self] in self?.escolherArquivo() },
            procurarAtualizacoes: { [weak self] in self?.procurarAtualizacoes() },
            abrirAjustes: { [weak self] in self?.abrirAjustes() },
            sair: { NSApp.terminate(nil) }))
        configurarIcone()
        estado.aoMudarProgresso = { [weak self] fracao, fim in
            self?.atualizarIcone(fracao: fracao, fim: fim)
        }
        detector.aoComecar = { [weak self] in self?.arrasteComecou() }
        detector.aoTerminar = { [weak self] in self?.arrasteTerminou() }
        detector.ligar()
    }

    // MARK: Ícone

    private func configurarIcone() {
        guard let botao = item.button else { return }
        botao.image = simbolo
        botao.imagePosition = .imageLeft
        botao.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        botao.toolTip = String(localized: "TranscreveAI: clique ou solte um áudio aqui")
        botao.target = self
        botao.action = #selector(cliqueNoIcone)
        botao.sendAction(on: [.leftMouseDown, .rightMouseDown])
        aceitarArquivosNoIcone()
    }

    /// A janela do ícone repassa os eventos de arrastar ao delegate dela (este objeto).
    private func aceitarArquivosNoIcone() {
        guard let janela = item.button?.window else {
            DispatchQueue.main.async { [weak self] in self?.aceitarArquivosNoIcone() }
            return
        }
        janela.registerForDraggedTypes([.fileURL, NSPasteboard.PasteboardType("NSFilenamesPboardType")])
        janela.delegate = self
    }

    /// Clique esquerdo abre ou fecha o painel; botão direito (ou Control + clique) mostra o menu curto
    /// (Procurar atualizações…, Ajustes…, Abrir ao iniciar o Mac, Sair).
    @objc private func cliqueNoIcone() {
        let evento = NSApp.currentEvent
        if evento?.type == .rightMouseDown || evento?.modifierFlags.contains(.control) == true {
            mostrarMenuDoIcone()
        } else {
            painel.isVisible ? fecharPainel() : mostrarPainel()
        }
    }

    // MARK: Progresso no ícone

    /// Com o painel fechado, o ícone vira um anel com a porcentagem. Ao terminar, mostra um ✓ por alguns
    /// segundos e depois a bolinha vermelha, que fica até a pessoa abrir o painel (no erro, só a bolinha).
    private func atualizarIcone(fracao: Double?, fim: EstadoApp.Fim?) {
        progressoNoIcone = fracao
        if fim != nil && !painel.isVisible {
            resultadoNaoVisto = true
            if fim == .pronto {
                let ate = Date().addingTimeInterval(4)
                concluidoAte = ate
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.1) { [weak self] in
                    guard let self, self.concluidoAte == ate else { return }
                    self.concluidoAte = nil
                    self.redesenharIcone()
                }
            }
        }
        if fim == nil && fracao == nil { resultadoNaoVisto = false }  // "Novo": nada pendente
        redesenharIcone()
    }

    private func redesenharIcone() {
        guard let botao = item.button else { return }
        if painel.isVisible {
            concluidoAte = nil
            resultadoNaoVisto = false
            botao.image = simbolo
            botao.title = ""
        } else if let fracao = progressoNoIcone {
            botao.image = Self.anel(fracao)
            botao.title = " \(Int(fracao * 100))%"
        } else if concluidoAte != nil {
            let pronto = NSImage(
                systemSymbolName: "checkmark", accessibilityDescription: String(localized: "Transcrição pronta"))
            pronto?.isTemplate = true
            botao.image = pronto
            botao.title = ""
        } else {
            botao.image = simbolo
            botao.title = ""
        }
        mostrarBolinha(resultadoNaoVisto && !painel.isVisible && progressoNoIcone == nil && concluidoAte == nil)
    }

    /// A bolinha vermelha fica numa camada por cima do botão: o símbolo continua "template" e o macOS o pinta
    /// na cor certa da barra (desenhar tudo numa imagem colorida deixava o símbolo cinza).
    private lazy var bolinha: NSView = {
        let ponto = NSView(frame: NSRect(x: 0, y: 0, width: 7, height: 7))
        ponto.wantsLayer = true
        ponto.layer?.backgroundColor = NSColor.systemRed.cgColor
        ponto.layer?.cornerRadius = 3.5
        ponto.isHidden = true
        ponto.setAccessibilityLabel(String(localized: "Transcrição nova"))
        return ponto
    }()

    private func mostrarBolinha(_ visivel: Bool) {
        guard let botao = item.button else { return }
        if bolinha.superview == nil { botao.addSubview(bolinha) }
        let x = botao.bounds.midX + 3
        let y = botao.isFlipped ? 2.5 : botao.bounds.height - 2.5 - bolinha.frame.height
        bolinha.setFrameOrigin(NSPoint(x: x, y: y))
        bolinha.isHidden = !visivel
    }

    private static func anel(_ fracao: Double) -> NSImage {
        let imagem = NSImage(size: NSSize(width: 16, height: 16), flipped: false) { area in
            let centro = NSPoint(x: area.midX, y: area.midY)
            let raio: CGFloat = 6.25
            let trilho = NSBezierPath()
            trilho.appendArc(withCenter: centro, radius: raio, startAngle: 0, endAngle: 360)
            trilho.lineWidth = 2
            NSColor.black.withAlphaComponent(0.3).setStroke()
            trilho.stroke()
            let arco = NSBezierPath()
            arco.appendArc(
                withCenter: centro, radius: raio, startAngle: 90,
                endAngle: 90 - 360 * CGFloat(max(0.02, min(1, fracao))), clockwise: true)
            arco.lineWidth = 2
            arco.lineCapStyle = .round
            NSColor.black.setStroke()
            arco.stroke()
            return true
        }
        imagem.isTemplate = true
        return imagem
    }

    // MARK: Menu do botão direito

    func mostrarMenuDoIcone() {
        fecharPainel()
        let menu = NSMenu()
        menu.autoenablesItems = false

        let atualizacoes = NSMenuItem(
            title: String(localized: "Procurar atualizações…"), action: #selector(procurarAtualizacoesPeloMenu),
            keyEquivalent: "")
        atualizacoes.target = self
        atualizacoes.isEnabled = Atualizacoes.atualizador.canCheckForUpdates
        menu.addItem(atualizacoes)

        let ajustes = NSMenuItem(
            title: String(localized: "Ajustes…"), action: #selector(abrirAjustesPeloMenu), keyEquivalent: ",")
        ajustes.target = self
        menu.addItem(ajustes)

        let inicio = NSMenuItem(
            title: String(localized: "Abrir ao iniciar o Mac"), action: #selector(alternarInicioAutomatico),
            keyEquivalent: "")
        inicio.target = self
        inicio.state = InicioAutomatico.ativo ? .on : .off
        menu.addItem(inicio)

        menu.addItem(.separator())

        let sair = NSMenuItem(
            title: String(localized: "Sair do TranscreveAI"), action: #selector(sairDoApp), keyEquivalent: "q")
        sair.target = self
        menu.addItem(sair)

        // Com o menu preso ao item, o clique programado abre o menu no lugar certo e com o ícone destacado.
        item.menu = menu
        item.button?.performClick(nil)
        item.menu = nil
    }

    @objc private func procurarAtualizacoesPeloMenu() { procurarAtualizacoes() }

    @objc private func abrirAjustesPeloMenu() { abrirAjustes() }

    @objc private func alternarInicioAutomatico() { InicioAutomatico.definir(!InicioAutomatico.ativo) }

    @objc private func sairDoApp() { NSApp.terminate(nil) }

    // MARK: Painel

    /// Logo depois da abertura do app o ícone ainda não tem lugar na barra: tenta de novo em instantes.
    /// `ativar: false` (aberto por um arraste) não tira o foco do app de onde o arquivo vem.
    func mostrarPainel(ativar: Bool = true, tentativas: Int = 50) {
        guard let botao = item.button, let janela = botao.window, janela.frame.minY > 0 else {
            if tentativas > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.mostrarPainel(ativar: ativar, tentativas: tentativas - 1)
                }
            }
            return
        }
        let icone = janela.convertToScreen(botao.convert(botao.bounds, to: nil))
        iconeNaTela = icone
        if ativar { NSApp.activate() }
        painel.mostrar(abaixoDe: icone, tornarChave: ativar)
        botao.highlight(true)
        redesenharIcone()
        instalarMonitores()
    }

    func fecharPainel() {
        painel.orderOut(nil)
        item.button?.highlight(false)
        removerMonitores()
        abertoPorArraste = false
        redesenharIcone()
    }

    private func escolherArquivo() {
        fecharPainel()
        NSApp.activate()
        let seletor = NSOpenPanel()
        seletor.title = String(localized: "Escolher áudio")
        seletor.prompt = String(localized: "Transcrever")
        seletor.allowsMultipleSelection = false
        seletor.canChooseDirectories = false
        seletor.allowedContentTypes = FormatosAudio.tipos
        if seletor.runModal() == .OK, estado.receber(seletor.urls) {
            mostrarPainel()
        }
    }

    private func procurarAtualizacoes() {
        fecharPainel()
        NSApp.activate()
        Atualizacoes.atualizador.checkForUpdates()
    }

    func abrirAjustes() {
        fecharPainel()
        if janelaAjustes == nil {
            // Tamanho fixo: deixar a janela seguir o Form agrupado criava um ciclo de layout que derrubava o app.
            let controlador = NSHostingController(rootView: AjustesView(historico: .compartilhado))
            controlador.sizingOptions = []
            let janela = NSWindow(contentViewController: controlador)
            janela.title = String(localized: "Ajustes do TranscreveAI")
            janela.styleMask = [.titled, .closable]
            janela.setContentSize(AjustesView.tamanho)
            janela.isReleasedWhenClosed = false
            janela.center()
            janelaAjustes = janela
        }
        NSApp.activate()
        janelaAjustes?.makeKeyAndOrderFront(nil)
        janelaAjustes?.orderFrontRegardless()
    }

    // MARK: Abrir sozinho ao arrastar um áudio

    private func arrasteComecou() {
        guard Preferencia.abrirAoArrastarLigado, !painel.isVisible else { return }
        arquivoAntesDoArraste = estado.arquivo?.id
        mostrarPainel(ativar: false)
        abertoPorArraste = true
    }

    /// Soltou o arquivo: se ele não veio para o painel nem para o ícone, o painel fecha de novo.
    /// Espera um instante porque a entrega do arquivo chega logo depois do "soltar".
    private func arrasteTerminou() {
        guard abertoPorArraste else { return }
        let antes = arquivoAntesDoArraste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, self.abertoPorArraste, self.painel.isVisible else { return }
            self.abertoPorArraste = false
            if self.estado.arquivo?.id == antes {
                self.fecharPainel()
            } else {
                NSApp.activate()
                self.painel.makeKey()
            }
        }
    }

    // MARK: Fechar ao clicar fora

    /// Fecha com Esc ou no instante em que o botão do mouse desce fora do painel (sem esperar soltar).
    /// Quem estava trazendo um arquivo do Finder não perde nada: o painel reabre sozinho quando o arraste
    /// de um áudio começa ("Abrir ao arrastar um áudio"), e soltar no ícone da barra também funciona.
    private func instalarMonitores() {
        guard monitores.isEmpty else { return }
        let tipos: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        if let fora = NSEvent.addGlobalMonitorForEvents(matching: tipos, handler: { [weak self] _ in
            MainActor.assumeIsolated { self?.cliqueFora() }
        }) {
            monitores.append(fora)
        }
        if let teclas = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { [weak self] evento in
            guard evento.keyCode == 53 else { return evento }  // Esc
            MainActor.assumeIsolated { self?.fecharPainel() }
            return nil
        }) {
            monitores.append(teclas)
        }
    }

    private func removerMonitores() {
        monitores.forEach(NSEvent.removeMonitor)
        monitores.removeAll()
    }

    /// No macOS 26+ o clique no próprio ícone da barra também chega a este monitor, como se fosse de outro app.
    /// Esse clique é ignorado aqui: quem abre e fecha pelo ícone é a ação do botão.
    private func cliqueFora() {
        let noIcone = iconeNaTela.insetBy(dx: -4, dy: -4).contains(NSEvent.mouseLocation)
        if !noIcone { fecharPainel() }
    }

    // MARK: Soltar no ícone

    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard !audios(em: sender).isEmpty else { return [] }
        item.button?.highlight(true)
        return .copy
    }

    func draggingExited(_ sender: NSDraggingInfo?) {
        if !painel.isVisible { item.button?.highlight(false) }
    }

    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard estado.receber(audios(em: sender)) else { return false }
        mostrarPainel()
        return true
    }

    private func audios(em info: NSDraggingInfo) -> [URL] {
        DetectorDeArraste.arquivos(em: info.draggingPasteboard).filter(FormatosAudio.aceita)
    }
}
