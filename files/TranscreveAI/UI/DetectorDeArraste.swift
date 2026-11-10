import AppKit
import os

private let registro = Logger(subsystem: "io.github.joaogmcorrea.transcreveai", category: "arraste")

/// Percebe quando a pessoa começa a arrastar um arquivo de áudio em qualquer lugar (Finder, Mesa, pilhas do
/// Dock…), para o painel abrir sozinho e esperar o arquivo. Sem permissão de Acessibilidade: monitorar o
/// mouse de outros apps não exige (só o teclado exigiria).
///
/// Dois caminhos, enquanto o botão do mouse está pressionado:
/// 1. **Área de arraste comum** (`NSPasteboard(name: .drag)`): a cada 50 ms, se o `changeCount` mudou desde
///    o repouso (anotado 4×/s com o botão solto) e há um áudio, avisa. Serve ao Finder, à Mesa e às capturas
///    de tela, que gravam nessa área.
/// 2. **Apanhador** (`ApanhadorDeArraste`): o Dock usa uma área de arraste própria, invisível aos outros
///    programas (diagnóstico de 10/11/2026: o `changeCount` nunca mudou num arraste vindo do Dock). Então,
///    se o clique começou sobre uma janela do Dock ou do Finder e o ponteiro andou 6 pt, uma janela
///    transparente cobre a tela por um instante: ela recebe o arraste, lê os arquivos e sai da frente.
///    Só para Dock e Finder, para nunca entrar na frente de um arraste comum noutro app (pincel do
///    Photoshop, seleção de texto).
///
/// Limite: arquivos "prometidos" (anexo arrastado do Mail, alguns itens de navegador) não chegam como
/// arquivo de verdade, então não abrem o painel.
final class DetectorDeArraste {
    var aoComecar: (() -> Void)?
    var aoTerminar: (() -> Void)?

    /// Donos de janela em que um clique pode virar arraste de arquivo pela área própria (Dock) ou não.
    private static let origensComApanhador: Set<String> = ["Dock", "Finder"]

    private var monitor: Any?
    private var vigia: Timer?
    private var conferencia: Timer?
    private let apanhador = ApanhadorDeArraste()
    /// O `changeCount` com o botão solto: a referência para saber se um arraste começou neste clique.
    /// Não é trocada no clique: o aviso do clique chega depois de quem arrasta já ter gravado.
    private var contagemEmRepouso = NSPasteboard(name: .drag).changeCount
    private var pontoDoClique: NSPoint = .zero
    private var origemDoClique: String?
    private var decidido = false
    private var emAndamento = false

    private var botaoPressionado: Bool { NSEvent.pressedMouseButtons & 1 != 0 }

    func ligar() {
        guard monitor == nil else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] evento in
            MainActor.assumeIsolated { self?.botaoDesceu(evento) }
        }
        let vigia = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.vigiar() }
        }
        RunLoop.main.add(vigia, forMode: .common)
        self.vigia = vigia
        apanhador.aoReceber = { [weak self] urls, tipos in self?.apanhou(urls, tipos: tipos) }
    }

    // MARK: Botão do mouse

    private func vigiar() {
        if !botaoPressionado {
            contagemEmRepouso = NSPasteboard(name: .drag).changeCount
        } else if conferencia == nil {
            // Botão pressionado sem o aviso do clique ter chegado.
            comecarClique(origem: Self.dono(em: NSEvent.mouseLocation))
        }
    }

    private func botaoDesceu(_ evento: NSEvent) {
        comecarClique(origem: Self.dono(de: evento))
    }

    private func comecarClique(origem: String?) {
        pontoDoClique = NSEvent.mouseLocation
        origemDoClique = origem
        decidido = false
        emAndamento = false
        iniciarConferencia()
    }

    private func iniciarConferencia() {
        guard conferencia == nil else { return }
        let conferencia = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.passo() }
        }
        RunLoop.main.add(conferencia, forMode: .common)
        self.conferencia = conferencia
    }

    private func passo() {
        guard botaoPressionado else {
            conferencia?.invalidate()
            conferencia = nil
            botaoSubiu()
            return
        }
        guard !decidido else { return }
        conferirAreaComum()
        if !decidido, !apanhador.armado, let origem = origemDoClique, Self.origensComApanhador.contains(origem) {
            let agora = NSEvent.mouseLocation
            if hypot(agora.x - pontoDoClique.x, agora.y - pontoDoClique.y) > 6 {
                registro.debug("arraste começou sobre \(origem, privacy: .public); arma o apanhador")
                apanhador.armar()
            }
        }
    }

    private func botaoSubiu() {
        apanhador.desarmar()
        decidido = false
        origemDoClique = nil
        contagemEmRepouso = NSPasteboard(name: .drag).changeCount
        if emAndamento {
            emAndamento = false
            aoTerminar?()
        }
    }

    // MARK: Os dois caminhos

    private func conferirAreaComum() {
        let quadro = NSPasteboard(name: .drag)
        guard quadro.changeCount != contagemEmRepouso else { return }
        if Self.arquivos(em: quadro).contains(where: FormatosAudio.aceita) {
            registro.debug("áudio na área de arraste comum; abre o painel")
            percebido()
        }
    }

    private func apanhou(_ urls: [URL], tipos: [NSPasteboard.PasteboardType]) {
        let audio = urls.contains(where: FormatosAudio.aceita)
        registro.debug("apanhador recebeu o arraste: \(urls.count) arquivo(s), áudio \(audio); tipos: \(tipos.prefix(8).map(\.rawValue).joined(separator: ", "), privacy: .public)")
        guard botaoPressionado else { return }
        if audio {
            percebido()
        } else {
            decidido = true  // não é áudio: não arma de novo neste arraste
        }
    }

    private func percebido() {
        guard !decidido else { return }
        decidido = true
        emAndamento = true
        aoComecar?()
    }

    // MARK: Utilidades

    /// As URLs de arquivo de um arraste: o formato atual (`public.file-url`) ou a lista antiga de caminhos
    /// (`NSFilenamesPboardType`), que alguns apps do sistema ainda usam.
    static func arquivos(em quadro: NSPasteboard) -> [URL] {
        if let urls = quadro.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
           !urls.isEmpty {
            return urls
        }
        let antigo = NSPasteboard.PasteboardType("NSFilenamesPboardType")
        if let caminhos = quadro.propertyList(forType: antigo) as? [String] {
            return caminhos.map { URL(fileURLWithPath: $0) }
        }
        return []
    }

    /// O app dono da janela em que o clique caiu: pela janela do evento ou, sem ela, pelo ponto na tela.
    private static func dono(de evento: NSEvent) -> String? {
        if evento.windowNumber > 0,
           let info = (CGWindowListCopyWindowInfo([.optionIncludingWindow], CGWindowID(evento.windowNumber))
               as? [[String: Any]])?.first,
           let dono = info[kCGWindowOwnerName as String] as? String {
            return dono
        }
        return dono(em: NSEvent.mouseLocation)
    }

    /// A janela mais à frente que contém o ponto (a lista vem da frente para trás; coordenadas do CG começam
    /// no canto superior esquerdo da tela principal).
    private static func dono(em ponto: NSPoint) -> String? {
        guard let principal = NSScreen.screens.first else { return nil }
        let alvo = CGPoint(x: ponto.x, y: principal.frame.maxY - ponto.y)
        let lista = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
        for janela in lista {
            guard let limites = janela[kCGWindowBounds as String] as? NSDictionary,
                  let quadro = CGRect(dictionaryRepresentation: limites as CFDictionary),
                  quadro.contains(alvo) else { continue }
            let dono = janela[kCGWindowOwnerName as String] as? String
            if dono == "TranscreveAI" { continue }
            return dono
        }
        return nil
    }
}
