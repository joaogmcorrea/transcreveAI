import Foundation
import TranscreveMotores

/// Salvar a transcrição em arquivo. `.txt` = só o texto, um parágrafo por bloco (o `.md` com título, metadados e
/// tempos entra na v0.6).
enum Exportacao {
    /// Grava `<nome do áudio>.txt` na pasta do áudio; se o nome já existe, `<nome> 2.txt`, `<nome> 3.txt`…
    /// Sem permissão de escrita ali, vai para Downloads. Devolve onde ficou.
    static func txt(_ paragrafos: [Segmento], ao audio: URL) throws -> URL {
        let texto = Paragrafos.texto(paragrafos) + "\n"
        let nome = audio.deletingPathExtension().lastPathComponent
        do {
            let destino = livre(nome, em: audio.deletingLastPathComponent())
            try texto.write(to: destino, atomically: true, encoding: .utf8)
            return destino
        } catch {
            let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
            let destino = livre(nome, em: downloads)
            try texto.write(to: destino, atomically: true, encoding: .utf8)
            return destino
        }
    }

    private static func livre(_ nome: String, em pasta: URL) -> URL {
        var destino = pasta.appendingPathComponent(nome).appendingPathExtension("txt")
        var numero = 2
        while FileManager.default.fileExists(atPath: destino.path) {
            destino = pasta.appendingPathComponent("\(nome) \(numero)").appendingPathExtension("txt")
            numero += 1
        }
        return destino
    }
}
