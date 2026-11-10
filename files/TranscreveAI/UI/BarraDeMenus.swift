import AppKit
import SwiftUI

/// O ícone na barra de menus e o painel embaixo dele. Aceita áudio solto direto no ícone, abre o painel sozinho
/// quando um áudio começa a ser arrastado em qualquer app e mostra um menu curto no clique com o botão direito.
final class BarraDeMenus: NSObject, NSWindowDelegate, NSDraggingDestination {
    private let estado: EstadoApp
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let painel = PainelFlutuante()
    private let detector = DetectorDeArraste()
    private var janelaAjustes: NSWindow?
    private var monitores: [Any] = []
    private var iconeNaTela: NSRect = .zero
    private var cliqueForaPendente = false
    private var arrastouFora = false
    private var abertoPorArraste = false
    private var arquivoAntesDoArraste: UUID?

    init(estado: EstadoApp) {
        self.estado = estado
        super.init()
        painel.definirConteudo(PainelView(
            estado: estado,
            escolherArquivo: { [weak self] in self?.escolherArquivo() },
            procurarAtualizacoes: { [weak self] in self?.procurarAtualizacoes() },
            abrirAjustes: { [weak self] in self?.abrirAjustes() },
            sair: { NSApp.terminate(nil) }))
        configurarIcone()
        detector.aoComecar = { [weak self] in self?.arrasteComecou() }
        detector.aoTerminar = { [weak self] in self?.arrasteTerminou() }
        detector.ligar()
    }

    // MARK: Ícone

    private func configurarIcone() {
        guard let botao = item.button else { return }
        let imagem = NSImage(systemSymbolName: "waveform", accessibilityDescription: "TranscreveAI")
        imagem?.isTemplate = true
        botao.image = imagem
        botao.toolTip = "TranscreveAI: clique ou solte um áudio aqui"
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
        janela.registerForDraggedTypes([.fileURL])
        janela.delegate = self
    }

    /// Clique esquerdo abre ou fecha o painel; botão direito (ou Control + clique) mostra o menu curto.
    @objc private func cliqueNoIcone() {
        let evento = NSApp.currentEvent
        if evento?.type == .rightMouseDown || evento?.modifierFlags.contains(.control) == true {
            mostrarMenuDoIcone()
        } else {
            painel.isVisible ? fecharPainel() : mostrarPainel()
        }
    }

    // MARK: Menu do botão direito

    func mostrarMenuDoIcone() {
        fecharPainel()
        let menu = NSMenu()
        menu.autoenablesItems = false

        let atualizacoes = NSMenuItem(
            title: "Procurar atualizações…", action: #selector(procurarAtualizacoesPeloMenu), keyEquivalent: "")
        atualizacoes.target = self
        atualizacoes.isEnabled = Atualizacoes.atualizador.canCheckForUpdates
        menu.addItem(atualizacoes)

        let inicio = NSMenuItem(
            title: "Abrir ao iniciar o Mac", action: #selector(alternarInicioAutomatico), keyEquivalent: "")
        inicio.target = self
        inicio.state = InicioAutomatico.ativo ? .on : .off
        menu.addItem(inicio)

        menu.addItem(.separator())

        let sair = NSMenuItem(title: "Sair do TranscreveAI", action: #selector(sairDoApp), keyEquivalent: "q")
        sair.target = self
        menu.addItem(sair)

        // Com o menu preso ao item, o clique programado abre o menu no lugar certo e com o ícone destacado.
        item.menu = menu
        item.button?.performClick(nil)
        item.menu = nil
    }

    @objc private func procurarAtualizacoesPeloMenu() { procurarAtualizacoes() }

    @objc private func alternarInicioAutomatico() { InicioAutomatico.definir(!InicioAutomatico.ativo) }

    @objc private func sairDoApp() { NSApp.terminate(nil) }

    // MARK: Painel

    /// Logo depois da abertura do app o ícone ainda não tem lugar na barra: tenta de novo em instantes.
    /// `ativar: false` (aberto por um arraste) não tira o foco do app de onde o arquivo vem.
    func mostrarPainel(ativar: Bool = true, tentativas: Int = 20) {
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
        instalarMonitores()
    }

    func fecharPainel() {
        painel.orderOut(nil)
        item.button?.highlight(false)
        removerMonitores()
        abertoPorArraste = false
    }

    private func escolherArquivo() {
        fecharPainel()
        NSApp.activate()
        let seletor = NSOpenPanel()
        seletor.title = "Escolher áudio"
        seletor.prompt = "Transcrever"
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

    private func abrirAjustes() {
        fecharPainel()
        if janelaAjustes == nil {
            let controlador = NSHostingController(rootView: AjustesView())
            controlador.sizingOptions = [.preferredContentSize]
            let janela = NSWindow(contentViewController: controlador)
            janela.title = "Ajustes do TranscreveAI"
            janela.styleMask = [.titled, .closable]
            janela.isReleasedWhenClosed = false
            janela.center()
            janelaAjustes = janela
        }
        NSApp.activate()
        janelaAjustes?.makeKeyAndOrderFront(nil)
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

    /// Fecha com Esc ou com um clique fora. Um clique fora que vira arraste não fecha: a pessoa pode
    /// estar trazendo um arquivo do Finder para o painel.
    private func instalarMonitores() {
        guard monitores.isEmpty else { return }
        cliqueForaPendente = false
        arrastouFora = false
        let tipos: NSEvent.EventTypeMask = [.leftMouseDown, .leftMouseDragged, .leftMouseUp, .rightMouseDown]
        if let fora = NSEvent.addGlobalMonitorForEvents(matching: tipos, handler: { [weak self] evento in
            MainActor.assumeIsolated { self?.cliqueFora(evento) }
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

    /// No macOS 26+ o clique no ícone da barra também chega ao monitor global, como se fosse de outro app:
    /// o "soltar" do clique que abriu o painel o fechava na hora. Por isso só fecha um clique que **começou**
    /// fora do ícone depois que o painel abriu (e que não virou arraste).
    private func cliqueFora(_ evento: NSEvent) {
        let noIcone = iconeNaTela.insetBy(dx: -4, dy: -4).contains(NSEvent.mouseLocation)
        switch evento.type {
        case .leftMouseDown:
            cliqueForaPendente = !noIcone
            arrastouFora = false
        case .leftMouseDragged:
            if cliqueForaPendente { arrastouFora = true }
        case .leftMouseUp:
            if cliqueForaPendente && !arrastouFora { fecharPainel() }
            cliqueForaPendente = false
        case .rightMouseDown:
            if !noIcone { fecharPainel() }
        default:
            break
        }
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
        let urls = info.draggingPasteboard.readObjects(
            forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        return urls.filter(FormatosAudio.aceita)
    }
}
