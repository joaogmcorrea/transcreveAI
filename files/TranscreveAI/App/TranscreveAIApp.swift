import SwiftUI

/// App de barra de menus: sem janela principal nem ícone no Dock (LSUIElement).
/// O ícone e o painel ficam com a `BarraDeMenus` (AppKit), que aceita áudio solto direto no ícone.
@main
struct TranscreveAIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // O app precisa de uma cena; os ajustes abrem numa janela própria (BarraDeMenus.abrirAjustes).
        Settings {
            EmptyView()
        }
    }
}
