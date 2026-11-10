// Atualizações pelo Sparkle 2: o app lê o appcast da última versão no GitHub Releases (SUFeedURL do
// TranscreveAI-Info.plist) e só instala o que vier assinado com a chave EdDSA do projeto (SUPublicEDKey).
// O instalador e o appcast saem do _dev/distribuir.sh.
import AppKit
import Sparkle

/// Um atualizador para o app inteiro. Nos builds de debug ele não procura nada: as cópias de teste
/// rodam escondidas e a janela do Sparkle apareceria na tela.
enum Atualizacoes {
    static let controlador = SPUStandardUpdaterController(
        startingUpdater: ativo, updaterDelegate: nil, userDriverDelegate: LembretesDeAtualizacao.compartilhado)

    static var atualizador: SPUUpdater { controlador.updater }

    static var ativo: Bool {
        #if DEBUG
        false
        #else
        true
        #endif
    }
}

/// App de barra de menus (sem Dock): o Sparkle pede suporte a "lembretes discretos" para avisos agendados.
/// Antes de mostrar a janela da atualização, o app se ativa para ela aparecer na frente das outras.
final class LembretesDeAtualizacao: NSObject, SPUStandardUserDriverDelegate {
    static let compartilhado = LembretesDeAtualizacao()

    nonisolated var supportsGentleScheduledUpdateReminders: Bool { true }

    nonisolated func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState
    ) {
        guard handleShowingUpdate else { return }
        MainActor.assumeIsolated { NSApp.activate() }
    }
}
