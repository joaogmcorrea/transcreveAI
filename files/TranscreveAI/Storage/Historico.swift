import Foundation
import Observation
import TranscreveMotores

/// O histórico local das transcrições, em Application Support/TranscreveAI/Historico: um índice leve
/// (`indice.json`, com os resumos para a lista e a busca) e um arquivo por transcrição com o texto completo.
/// Nada sai do Mac. Guarda as 500 mais recentes; desliga em Ajustes › Histórico.
/// Por padrão vale só para a sessão do Mac: ao abrir depois de desligar ou reiniciar, o histórico é apagado
/// (compara o horário em que o sistema ligou, `kern.boottime`, com o anotado em `sessao.txt`).
@Observable
final class Historico {
    struct Resumo: Codable, Identifiable, Equatable {
        let id: UUID
        let nome: String
        let caminho: String
        let data: Date
        let duracao: TimeInterval?
        let motor: Motor
        let segundos: TimeInterval
        /// O começo do texto, para mostrar e buscar sem abrir cada arquivo.
        let inicio: String
    }

    private struct Item: Codable {
        let resumo: Resumo
        let paragrafos: [Segmento]
    }

    static let compartilhado = Historico()
    static let limite = 500

    private(set) var itens: [Resumo] = []
    let pasta: URL

    private var indice: URL { pasta.appendingPathComponent("indice.json") }
    private var arquivoDaSessao: URL { pasta.appendingPathComponent("sessao.txt") }

    init() {
        pasta = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TranscreveAI/Historico", isDirectory: true)
        try? FileManager.default.createDirectory(at: pasta, withIntermediateDirectories: true)
        if let dados = try? Data(contentsOf: indice),
           let lidos = try? Self.decodificador.decode([Resumo].self, from: dados) {
            itens = lidos
        }
        conferirSessao()
    }

    /// Só até desligar ou reiniciar o Mac (Ajustes › Histórico).
    var soNaSessao: Bool {
        UserDefaults.standard.object(forKey: Preferencia.historicoSoNaSessao) as? Bool ?? true
    }

    /// Se o Mac foi desligado ou reiniciado desde a última anotação, apaga o histórico (quando `soNaSessao`).
    /// Sem anotação (primeira vez), também apaga o que houver: não dá para saber de que sessão era.
    private func conferirSessao() {
        let atual = String(Self.inicioDoSistema)
        let anotada = try? String(contentsOf: arquivoDaSessao, encoding: .utf8)
        if soNaSessao, anotada != atual, !itens.isEmpty { limpar() }
        try? atual.write(to: arquivoDaSessao, atomically: true, encoding: .utf8)
    }

    /// O horário em que o sistema ligou (segundos desde 1970); muda a cada desligar ou reiniciar.
    static var inicioDoSistema: Int {
        var tempo = timeval()
        var tamanho = MemoryLayout<timeval>.size
        var nome: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        guard sysctl(&nome, 2, &tempo, &tamanho, nil, 0) == 0 else { return 0 }
        return tempo.tv_sec
    }

    var ligado: Bool {
        UserDefaults.standard.object(forKey: Preferencia.guardarHistorico) as? Bool ?? true
    }

    /// Guarda uma transcrição nova no topo. Devolve o id, ou `nil` se o histórico estiver desligado.
    @discardableResult
    func adicionar(arquivo: ArquivoAudio, paragrafos: [Segmento], motor: Motor, segundos: TimeInterval) -> UUID? {
        guard ligado, !paragrafos.isEmpty else { return nil }
        let texto = Paragrafos.texto(paragrafos)
        let resumo = Resumo(
            id: UUID(), nome: arquivo.nome, caminho: arquivo.url.path, data: Date(), duracao: arquivo.duracao,
            motor: motor, segundos: segundos, inicio: String(texto.prefix(400)))
        do {
            let dados = try Self.codificador.encode(Item(resumo: resumo, paragrafos: paragrafos))
            try dados.write(to: arquivoDoItem(resumo.id), options: .atomic)
        } catch {
            NSLog("Histórico: não consegui gravar (%@)", error.localizedDescription)
            return nil
        }
        itens.insert(resumo, at: 0)
        while itens.count > Self.limite {
            let antigo = itens.removeLast()
            try? FileManager.default.removeItem(at: arquivoDoItem(antigo.id))
        }
        salvarIndice()
        return resumo.id
    }

    func paragrafos(de id: UUID) -> [Segmento]? {
        guard let dados = try? Data(contentsOf: arquivoDoItem(id)),
              let item = try? Self.decodificador.decode(Item.self, from: dados) else { return nil }
        return item.paragrafos
    }

    func apagar(_ id: UUID) {
        itens.removeAll { $0.id == id }
        try? FileManager.default.removeItem(at: arquivoDoItem(id))
        salvarIndice()
    }

    func limpar() {
        for item in itens { try? FileManager.default.removeItem(at: arquivoDoItem(item.id)) }
        itens.removeAll()
        salvarIndice()
    }

    /// Busca no nome e no começo do texto, sem diferenciar maiúsculas nem acentos.
    func filtrar(_ busca: String) -> [Resumo] {
        let termo = busca.trimmingCharacters(in: .whitespaces)
        guard !termo.isEmpty else { return itens }
        return itens.filter { $0.nome.localizedStandardContains(termo) || $0.inicio.localizedStandardContains(termo) }
    }

    private func arquivoDoItem(_ id: UUID) -> URL {
        pasta.appendingPathComponent("\(id.uuidString).json")
    }

    private func salvarIndice() {
        guard let dados = try? Self.codificador.encode(itens) else { return }
        try? dados.write(to: indice, options: .atomic)
    }

    private static let codificador: JSONEncoder = {
        let codificador = JSONEncoder()
        codificador.dateEncodingStrategy = .iso8601
        return codificador
    }()

    private static let decodificador: JSONDecoder = {
        let decodificador = JSONDecoder()
        decodificador.dateDecodingStrategy = .iso8601
        return decodificador
    }()

    /// "Hoje, 10:12", "Ontem, 18:03" ou "9 de nov, 14:20" (em inglês, "Today, 10:12 AM" ou "Nov 9, 2:20 PM"):
    /// idioma do app, formato de data e hora do Mac.
    static func quando(_ data: Date) -> String {
        let calendario = Calendar.current
        let hora = data.formatted(.dateTime.hour().minute())
        if calendario.isDateInToday(data) { return String(localized: "Hoje, \(hora)") }
        if calendario.isDateInYesterday(data) { return String(localized: "Ontem, \(hora)") }
        let dia = data.formatted(.dateTime.day().month(.abbreviated))
        return "\(dia.replacingOccurrences(of: ".", with: "")), \(hora)"
    }
}
