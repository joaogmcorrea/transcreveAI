import FluidAudio
import Foundation

public enum Paragrafos {
    /// Junta frases em parágrafos: quebra numa pausa de 1,2 s ou quando o parágrafo passa de ~300 caracteres
    /// (fechando na frase). Cada parágrafo leva o tempo da primeira frase.
    public static func agrupar(_ frases: [Segmento]) -> [Segmento] {
        var paragrafos: [Segmento] = []
        for frase in frases {
            if var atual = paragrafos.last, frase.inicio - atual.fim < 1.2, atual.texto.count < 300 {
                atual.texto += " " + frase.texto
                atual.fim = frase.fim
                paragrafos[paragrafos.count - 1] = atual
            } else {
                paragrafos.append(frase)
            }
        }
        return paragrafos
    }

    /// O texto corrido, um parágrafo por bloco.
    public static func texto(_ segmentos: [Segmento]) -> String {
        segmentos.map(\.texto).joined(separator: "\n\n")
    }

    /// Frases a partir dos tokens do Parakeet: fecha a frase em ponto, interrogação ou exclamação, ou numa
    /// pausa de mais de 1,2 s. Sem os tempos, devolve o texto inteiro como uma frase só.
    static func frases(tokens: [TokenTiming]?, texto: String, duracao: TimeInterval) -> [Segmento] {
        guard let tokens, !tokens.isEmpty else {
            let limpo = texto.trimmingCharacters(in: .whitespacesAndNewlines)
            return limpo.isEmpty ? [] : [Segmento(inicio: 0, fim: duracao, texto: limpo)]
        }
        var frases: [Segmento] = []
        var atual = ""
        var inicio: TimeInterval?
        var fim: TimeInterval = 0

        func fechar() {
            let limpo = atual.trimmingCharacters(in: .whitespacesAndNewlines)
            if !limpo.isEmpty, let inicio {
                // Pontuação solta numa pausa ("."): gruda na frase anterior, sem repetir o sinal.
                if limpo.allSatisfy({ $0.isPunctuation }), var anterior = frases.last {
                    if let ultimo = anterior.texto.last, !ultimo.isPunctuation { anterior.texto += limpo }
                    anterior.fim = max(anterior.fim, fim)
                    frases[frases.count - 1] = anterior
                } else {
                    frases.append(Segmento(inicio: inicio, fim: fim, texto: limpo))
                }
            }
            atual = ""
            inicio = nil
        }

        for token in tokens {
            if inicio != nil, token.startTime - fim > 1.2 { fechar() }
            // SentencePiece marca o começo de palavra com "▁".
            let peca = token.token.replacingOccurrences(of: "▁", with: " ")
            if inicio == nil { inicio = token.startTime }
            atual += peca
            fim = token.endTime
            if let ultimo = atual.trimmingCharacters(in: .whitespaces).last, ".?!…".contains(ultimo) { fechar() }
        }
        fechar()
        return frases
    }
}
