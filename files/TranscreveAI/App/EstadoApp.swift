import Foundation
import Observation

/// O que o painel mostra. Compartilhado entre o ícone (arquivo solto nele) e o painel.
@Observable
final class EstadoApp {
    private(set) var arquivo: ArquivoAudio?
    private(set) var aviso: String?

    /// Aceita o primeiro áudio da lista. Devolve `false` quando nenhum dos arquivos é áudio.
    @discardableResult
    func receber(_ urls: [URL]) -> Bool {
        guard let url = urls.first(where: FormatosAudio.aceita) else {
            aviso = urls.isEmpty ? nil : "Esse arquivo não parece ser um áudio."
            return false
        }
        aviso = nil
        let novo = ArquivoAudio(url: url)
        arquivo = novo
        Task {
            let duracao = await FormatosAudio.duracao(de: url)
            guard arquivo?.id == novo.id else { return }
            arquivo?.duracao = duracao
        }
        return true
    }

    func limpar() {
        arquivo = nil
        aviso = nil
    }
}

struct ArquivoAudio: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    var duracao: TimeInterval?

    var nome: String { url.lastPathComponent }

    var tamanho: Int64? {
        (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) }
    }
}
