import AppKit
import SwiftUI

/// A janela sem borda embaixo do ícone, com o material dos menus do macOS e cantos arredondados.
/// A altura acompanha o conteúdo; o topo fica sempre preso logo abaixo do ícone.
final class PainelFlutuante: NSPanel {
    static let largura: CGFloat = 380
    private static let raio: CGFloat = 16

    private var hospedeiro: NSView?
    private var topoEsquerdo: NSPoint = .zero
    private var alturaConteudo: CGFloat = 320

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Self.largura, height: 320),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        isFloatingPanel = true
        level = .popUpMenu
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        isMovable = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]

        let fundo = NSVisualEffectView()
        fundo.material = .popover
        fundo.blendingMode = .behindWindow
        fundo.state = .active
        fundo.maskImage = Self.mascara(raio: Self.raio)
        contentView = fundo
    }

    override var canBecomeKey: Bool { true }

    func definirConteudo<Conteudo: View>(_ conteudo: Conteudo) {
        let raiz = conteudo
            .frame(width: Self.largura)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { [weak self] altura in
                self?.ajustar(altura: altura)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        let vista = NSHostingView(rootView: raiz)
        vista.sizingOptions = []
        vista.frame = contentView?.bounds ?? .zero
        vista.autoresizingMask = [.width, .height]
        contentView?.addSubview(vista)
        hospedeiro = vista
        vista.layoutSubtreeIfNeeded()
    }

    /// `tornarChave: false` mostra o painel sem tirar o foco do app atual (usado quando abre por um arraste).
    func mostrar(abaixoDe icone: NSRect, tornarChave: Bool = true) {
        let tela = NSScreen.screens.first { $0.frame.intersects(icone) } ?? NSScreen.main
        let area = tela?.visibleFrame ?? icone
        let x = min(max(icone.midX - Self.largura / 2, area.minX + 8), area.maxX - Self.largura - 8)
        topoEsquerdo = NSPoint(x: x, y: icone.minY - 6)
        hospedeiro?.layoutSubtreeIfNeeded()
        posicionar()
        if tornarChave { makeKeyAndOrderFront(nil) } else { orderFrontRegardless() }
    }

    private func ajustar(altura: CGFloat) {
        guard altura > 1 else { return }
        alturaConteudo = altura
        if isVisible { posicionar() }
    }

    private func posicionar() {
        let novo = NSRect(
            x: topoEsquerdo.x, y: topoEsquerdo.y - alturaConteudo, width: Self.largura, height: alturaConteudo)
        guard frame != novo else { return }
        setFrame(novo, display: true)
        invalidateShadow()
    }

    private static func mascara(raio: CGFloat) -> NSImage {
        let lado = raio * 2 + 1
        let imagem = NSImage(size: NSSize(width: lado, height: lado), flipped: false) { retangulo in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: retangulo, xRadius: raio, yRadius: raio).fill()
            return true
        }
        imagem.capInsets = NSEdgeInsets(top: raio, left: raio, bottom: raio, right: raio)
        imagem.resizingMode = .stretch
        return imagem
    }
}
