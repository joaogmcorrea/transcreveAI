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

    /// No idioma do app que usa o pacote (Localizable.xcstrings deste alvo).
    public var errorDescription: String? {
        switch self {
        case .formatoNaoSuportado(let extensao):
            String(localized: "Não consegui abrir esse arquivo (.\(extensao)).", bundle: .module)
        case .conversaoFalhou(let detalhe):
            String(localized: "Não consegui converter o áudio. \(detalhe)", bundle: .module)
                .trimmingCharacters(in: .whitespaces)
        case .idiomaIndisponivel(let idioma):
            String(localized: "O Apple Speech não tem o idioma \(idioma).", bundle: .module)
        case .modeloIndisponivel(let detalhe):
            String(localized: "O modelo não está pronto. \(detalhe)", bundle: .module)
                .trimmingCharacters(in: .whitespaces)
        }
    }
}
