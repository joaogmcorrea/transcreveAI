import AppKit
import FinderSync
import UniformTypeIdentifiers

/// O botão direito do Finder (pedido do owner, 17/11/2026, como o PowerClick): "Transcrever com o TranscreveAI" ›
/// "Copiar o texto" ou "Exportar como .txt", nos áudios e vídeos selecionados. A extensão só monta o menu e passa os
/// arquivos ao app pelo endereço `transcreveai://copiar?arquivo=…` (ou `exportar`); quem transcreve é o app, em
/// segundo plano, sem abrir o painel. A Apple exige sandbox nas extensões: daqui não dá para ler os áudios, só os
/// caminhos que o Finder entrega.
///
/// O Finder pede o menu (e chama as ações) numa fila do XPC, fora da thread principal, e o modelo de extensão da
/// Apple monta o `NSMenu` ali mesmo. Por isso este alvo compila no modo Swift 5, sem isolamento padrão: no modo
/// Swift 6 (o do app), o `MainActor.assumeIsolated` derrubava a extensão a cada clique com o botão direito e o item
/// nunca aparecia (visto pelo owner em 17/11/2026).
final class FinderSync: FIFinderSync {
    private var observadores: [NSObjectProtocol] = []

    override init() {
        super.init()
        vigiarVolumes()
        let central = NSWorkspace.shared.notificationCenter
        for nome in [NSWorkspace.didMountNotification, NSWorkspace.didUnmountNotification] {
            observadores.append(central.addObserver(forName: nome, object: nil, queue: .main) { [weak self] _ in
                self?.vigiarVolumes()
            })
        }
    }

    /// O Finder só chama a extensão nas pastas vigiadas: o disco todo e cada volume montado (discos externos).
    private func vigiarVolumes() {
        var pastas: Set<URL> = [URL(fileURLWithPath: "/")]
        let volumes = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: nil, options: [.skipHiddenVolumes]) ?? []
        pastas.formUnion(volumes)
        FIFinderSyncController.default().directoryURLs = pastas
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems, !audiosSelecionados().isEmpty else { return nil }
        let opcoes = NSMenu(title: "")
        opcoes.addItem(withTitle: String(localized: "Copiar o texto"), action: #selector(copiar(_:)), keyEquivalent: "")
        opcoes.addItem(
            withTitle: String(localized: "Exportar como .txt"), action: #selector(exportar(_:)), keyEquivalent: "")
        let item = NSMenuItem(title: String(localized: "Transcrever com o TranscreveAI"), action: nil, keyEquivalent: "")
        item.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: nil)
        item.submenu = opcoes
        let menu = NSMenu(title: "")
        menu.addItem(item)
        return menu
    }

    @IBAction func copiar(_ sender: AnyObject?) { pedir("copiar") }

    @IBAction func exportar(_ sender: AnyObject?) { pedir("exportar") }

    private func pedir(_ acao: String) {
        let audios = audiosSelecionados()
        guard !audios.isEmpty else { return }
        var endereco = URLComponents()
        endereco.scheme = "transcreveai"
        endereco.host = acao
        endereco.queryItems = audios.map { URLQueryItem(name: "arquivo", value: $0.path) }
        if let url = endereco.url { NSWorkspace.shared.open(url) }
    }

    private func audiosSelecionados() -> [URL] {
        (FIFinderSyncController.default().selectedItemURLs() ?? []).filter(Self.aceita)
    }

    /// A mesma regra de `FormatosAudio.aceita` no app: áudio ou vídeo pelo tipo, mais as extensões que o macOS nem
    /// sempre reconhece como áudio.
    private static let extensoesExtras: Set<String> = [
        "opus", "ogg", "oga", "webm", "wma", "mkv", "amr", "3gp", "m4b", "flac", "caf",
    ]

    private static func aceita(_ url: URL) -> Bool {
        let extensao = url.pathExtension.lowercased()
        if extensoesExtras.contains(extensao) { return true }
        guard let tipo = UTType(filenameExtension: extensao) else { return false }
        return tipo.conforms(to: .audio) || tipo.conforms(to: .audiovisualContent)
    }
}
