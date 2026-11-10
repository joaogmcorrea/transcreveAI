import Foundation

/// Um trecho do texto com o tempo em que foi falado.
public struct Segmento: Sendable, Hashable, Codable {
    public var inicio: TimeInterval
    public var fim: TimeInterval
    public var texto: String

    public init(inicio: TimeInterval, fim: TimeInterval, texto: String) {
        self.inicio = inicio
        self.fim = fim
        self.texto = texto
    }
}

/// Os motores que o app usa (benchmark da v0.2.0).
public enum Motor: String, Sendable, Codable, CaseIterable {
    case parakeet, apple

    public var nome: String {
        switch self {
        case .parakeet: "Parakeet v3"
        case .apple: "Apple Speech"
        }
    }
}

/// Em que ponto a transcrição está, para o painel e o ícone da barra.
public enum Etapa: Sendable, Equatable {
    case convertendo
    case preparandoModelo
    case transcrevendo(Double)  // 0…1
}

public struct Progresso: Sendable {
    public var etapa: Etapa
    /// O texto que já saiu (o Apple Speech entrega aos poucos; o Parakeet entrega tudo no fim).
    public var previa: [Segmento]

    public init(etapa: Etapa, previa: [Segmento] = []) {
        self.etapa = etapa
        self.previa = previa
    }
}

public enum ErroDeTranscricao: LocalizedError, Sendable {
    case formatoNaoSuportado(String)
    case conversaoFalhou(String)
    case idiomaIndisponivel(String)
    case modeloIndisponivel(String)

    public var errorDescription: String? {
        switch self {
        case .formatoNaoSuportado(let extensao):
            "Não consegui abrir esse arquivo (.\(extensao))."
        case .conversaoFalhou(let detalhe):
            "Não consegui converter o áudio. \(detalhe)".trimmingCharacters(in: .whitespaces)
        case .idiomaIndisponivel(let idioma):
            "O Apple Speech não tem o idioma \(idioma)."
        case .modeloIndisponivel(let detalhe):
            "O modelo não está pronto. \(detalhe)".trimmingCharacters(in: .whitespaces)
        }
    }
}
