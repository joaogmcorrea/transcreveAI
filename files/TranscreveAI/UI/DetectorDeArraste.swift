import AppKit

/// Percebe quando a pessoa começa a arrastar um arquivo de áudio em qualquer app (Finder, Mesa, pilha de
/// Downloads no Dock…), para o painel abrir sozinho e esperar o arquivo.
///
/// Como: enquanto o botão do mouse está pressionado, compara o `changeCount` da área de transferência de arraste
/// do sistema (`NSPasteboard(name: .drag)`). Quando ela muda, começou um arraste; se ele leva um áudio, avisa.
/// Monitorar o mouse de outros apps não exige permissão de Acessibilidade (só o teclado exigiria).
///
/// Limite: arquivos "prometidos" (anexo arrastado do Mail, alguns itens de navegador) ainda não chegam como
/// arquivo de verdade, então não abrem o painel.
final class DetectorDeArraste {
    var aoComecar: (() -> Void)?
    var aoTerminar: (() -> Void)?

    private var monitor: Any?
    private var contagemNoClique = 0
    private var aguardando = false
    private var emAndamento = false

    func ligar() {
        guard monitor == nil else { return }
        let tipos: NSEvent.EventTypeMask = [.leftMouseDown, .leftMouseDragged, .leftMouseUp]
        monitor = NSEvent.addGlobalMonitorForEvents(matching: tipos) { [weak self] evento in
            MainActor.assumeIsolated { self?.tratar(evento) }
        }
    }

    private func tratar(_ evento: NSEvent) {
        switch evento.type {
        case .leftMouseDown:
            contagemNoClique = NSPasteboard(name: .drag).changeCount
            aguardando = true
            emAndamento = false
        case .leftMouseDragged:
            // Uma checagem por clique: depois de decidir, ignora o resto do arraste.
            guard aguardando else { return }
            let quadro = NSPasteboard(name: .drag)
            guard quadro.changeCount != contagemNoClique else { return }
            aguardando = false
            if Self.temAudio(quadro) {
                emAndamento = true
                aoComecar?()
            }
        case .leftMouseUp:
            aguardando = false
            if emAndamento {
                emAndamento = false
                aoTerminar?()
            }
        default:
            break
        }
    }

    private static func temAudio(_ quadro: NSPasteboard) -> Bool {
        let urls = quadro.readObjects(
            forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        return urls.contains(where: FormatosAudio.aceita)
    }
}
