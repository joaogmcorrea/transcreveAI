import AppKit

/// Janela transparente da tela inteira que aparece por um instante durante um arraste vindo do Dock (ou do
/// Finder) para descobrir o que está sendo arrastado.
///
/// Por quê: o Dock não usa a área de arraste comum do sistema (`NSPasteboard(name: .drag)`) e sim uma
/// própria, que outros programas não enxergam (visto no diagnóstico de 10/11/2026; o Yoink tem o mesmo
/// limite). Quem *recebe* o arraste, porém, ganha a área certa em `draggingPasteboard`, venha de onde vier.
/// Esta janela recebe, lê os arquivos, avisa e sai da frente para o arraste seguir até o destino real.
///
/// Segurança: quem a mostra (`DetectorDeArraste`) a tira ao soltar o botão, e ela mesma se tira ao receber
/// o arraste ou depois de 4 s. Nunca aceita o arraste (devolve `[]`).
final class ApanhadorDeArraste: NSPanel {
    var aoReceber: (([URL], [NSPasteboard.PasteboardType]) -> Void)?
    private var limite: DispatchWorkItem?

    init() {
        super.init(
            contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        isOpaque = false
        hasShadow = false
        // Quase transparente (invisível a olho), mas não totalmente: janela com alfa zero não recebe nada.
        backgroundColor = NSColor.black.withAlphaComponent(0.01)
        ignoresMouseEvents = false
        level = .popUpMenu  // acima do Dock e das pilhas
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isReleasedWhenClosed = false
        let vista = VistaApanhadora()
        vista.aoEntrar = { [weak self] info in self?.receber(info) }
        contentView = vista
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    var armado: Bool { isVisible }

    /// Cobre a tela onde está o ponteiro.
    func armar() {
        let ponto = NSEvent.mouseLocation
        let tela = NSScreen.screens.first { $0.frame.contains(ponto) } ?? NSScreen.main
        guard let tela else { return }
        setFrame(tela.frame, display: false)
        orderFrontRegardless()
        limite?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.desarmar() }
        limite = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: item)
    }

    func desarmar() {
        limite?.cancel()
        limite = nil
        if isVisible { orderOut(nil) }
    }

    private func receber(_ info: NSDraggingInfo) {
        let quadro = info.draggingPasteboard
        let urls = DetectorDeArraste.arquivos(em: quadro)
        let tipos = quadro.types ?? []
        // Sai da frente no próximo ciclo (mexer na janela dentro do próprio evento de arraste é arriscado).
        DispatchQueue.main.async { [weak self] in self?.desarmar() }
        aoReceber?(urls, tipos)
    }
}

private final class VistaApanhadora: NSView {
    var aoEntrar: ((NSDraggingInfo) -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        registerForDraggedTypes([
            .fileURL, .URL, NSPasteboard.PasteboardType("NSFilenamesPboardType"),
            NSPasteboard.PasteboardType("com.apple.NSFilePromiseItemMetaData"),
            NSPasteboard.PasteboardType("com.apple.pasteboard.promised-file-url"),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        aoEntrar?(sender)
        return []
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation { [] }
}
