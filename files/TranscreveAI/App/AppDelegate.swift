import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let estado = EstadoApp()
    private var barra: BarraDeMenus?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // O Sparkle procura versões novas desde a abertura (nunca nos builds de debug).
        _ = Atualizacoes.controlador
        let barra = BarraDeMenus(estado: estado)
        self.barra = barra
        // Parakeet já baixado: carrega na memória agora, para a primeira transcrição sair na hora.
        estado.aquecerMotor()
        abrirPorArgumentos(barra)
    }

    /// "Abrir com" no Finder, ou arquivos soltos no ícone do app.
    func application(_ application: NSApplication, open urls: [URL]) {
        if estado.receber(urls) { barra?.mostrarPainel() }
    }

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
            estado.receber([URL(fileURLWithPath: argumentos[i + 1])])
            barra.mostrarPainel()
        } else if argumentos.contains("--abrir-painel") {
            barra.mostrarPainel()
        }
    }
}
