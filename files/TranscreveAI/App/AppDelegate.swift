import AppKit
import Darwin
import FinderSync
import OSLog

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let estado = EstadoApp()
    private var barra: BarraDeMenus?
    private let registro = Logger(subsystem: "io.github.joaogmcorrea.transcreveai", category: "finder")

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Os pedidos do botão direito do Finder (transcreveai://…) chegam como evento "abrir endereço". Instalado
        // aqui, antes do fim da abertura, para pegar também o pedido que abriu o app.
        NSAppleEventManager.shared().setEventHandler(
            self, andSelector: #selector(receberEndereco(_:resposta:)),
            forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // O Sparkle procura versões novas desde a abertura (nunca nos builds de debug).
        _ = Atualizacoes.controlador
        let barra = BarraDeMenus(estado: estado)
        self.barra = barra
        // Parakeet já baixado: carrega na memória agora, para a primeira transcrição sair na hora.
        estado.aquecerMotor()
        MenuDoFinder.ativarNaPrimeiraVez()
        abrirPorArgumentos(barra)
    }

    /// "Abrir com" no Finder, ou arquivos soltos no ícone do app.
    func application(_ application: NSApplication, open urls: [URL]) {
        if estado.receber(urls.filter(\.isFileURL)) { barra?.mostrarPainel() }
    }

    // MARK: Botão direito do Finder

    /// `transcreveai://copiar?arquivo=<caminho>&arquivo=…` ou `transcreveai://exportar?…`: transcreve em segundo
    /// plano, sem abrir o painel; o ícone da barra mostra o progresso e o ✓.
    @objc private func receberEndereco(_ evento: NSAppleEventDescriptor, resposta: NSAppleEventDescriptor) {
        guard let texto = evento.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let endereco = URLComponents(string: texto), endereco.scheme == "transcreveai"
        else { return }
        // Só a extensão do Finder pode pedir: um site não consegue mandar o app transcrever um arquivo do Mac.
        guard let remetente = Self.remetente(de: evento), MenuDoFinder.ehAExtensao(remetente) else {
            registro.error("Pedido recusado: não veio da extensão do Finder (\(Self.remetente(de: evento) ?? "?", privacy: .public))")
            return
        }
        let destino: EstadoApp.Destino
        switch endereco.host {
        case "copiar": destino = .copiar
        case "exportar": destino = .exportarTxt
        default: return
        }
        let arquivos = (endereco.queryItems ?? [])
            .filter { $0.name == "arquivo" }
            .compactMap(\.value)
            .map { URL(fileURLWithPath: $0) }
        estado.receber(arquivos, destino: destino)
    }

    /// O executável do processo que mandou o evento.
    private static func remetente(de evento: NSAppleEventDescriptor) -> String? {
        guard let pid = evento.attributeDescriptor(forKeyword: AEKeyword(keySenderPIDAttr))?.int32Value, pid > 0
        else { return nil }
        var caminho = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
        guard proc_pidpath(pid, &caminho, UInt32(caminho.count)) > 0 else { return nil }
        return String(cString: caminho)
    }

    // MARK: Testes

    /// Para testes: `--abrir-painel` abre o painel, `--arquivo <caminho>` já entrega um áudio a ele e
    /// `--menu-icone` abre o menu do botão direito, `--ajustes` abre os Ajustes e `--historico`, a lista do histórico.
    private func abrirPorArgumentos(_ barra: BarraDeMenus) {
        let argumentos = CommandLine.arguments
        if argumentos.contains("--historico") {
            estado.mostrandoHistorico = true
            barra.mostrarPainel()
        } else if argumentos.contains("--ajustes") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { barra.abrirAjustes() }
        } else if argumentos.contains("--menu-icone") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { barra.mostrarMenuDoIcone() }
        } else if let i = argumentos.firstIndex(of: "--arquivo-fundo"), i + 1 < argumentos.count {
            // Transcreve com o painel fechado (para ver o progresso no ícone).
            let caminho = argumentos[i + 1]
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [estado] in
                estado.receber([URL(fileURLWithPath: caminho)])
            }
        } else if let i = argumentos.firstIndex(of: "--arquivo"), i + 1 < argumentos.count {
            estado.receber(argumentos[(i + 1)...].map { URL(fileURLWithPath: $0) })
            barra.mostrarPainel()
        } else if argumentos.contains("--abrir-painel") {
            barra.mostrarPainel()
        }
    }
}

/// A extensão do Finder (alvo TranscreveFinder), embutida em Contents/PlugIns.
enum MenuDoFinder {
    static let identificador = "io.github.joaogmcorrea.transcreveai.finder"

    /// Ligada em Ajustes do Sistema › Geral › Itens de Início e Extensões.
    static var ativo: Bool { FIFinderSyncController.isExtensionEnabled }

    static func abrirAjustesDoSistema() {
        FIFinderSyncController.showExtensionManagementInterface()
    }

    /// O executável está dentro de uma TranscreveFinder.appex com o nosso identificador (de qualquer cópia do app:
    /// no Mac do owner convivem o app instalado e os builds do Xcode).
    static func ehAExtensao(_ executavel: String) -> Bool {
        guard let fim = executavel.range(of: ".appex/", options: .backwards) else { return false }
        let pacote = String(executavel[..<fim.lowerBound]) + ".appex"
        return Bundle(path: pacote)?.bundleIdentifier == identificador
    }

    /// A pessoa pediu o botão direito: na primeira abertura com a extensão, liga sozinho (uma vez só; se ela
    /// desligar depois nos Ajustes do Sistema, fica desligado).
    static func ativarNaPrimeiraVez() {
        let chave = "menuDoFinderAtivado"
        guard !UserDefaults.standard.bool(forKey: chave) else { return }
        UserDefaults.standard.set(true, forKey: chave)
        guard !ativo else { return }
        let processo = Process()
        processo.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        processo.arguments = ["-e", "use", "-i", identificador]
        try? processo.run()
    }
}
