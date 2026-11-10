import Foundation
import ServiceManagement

/// Chaves do UserDefaults.
enum Preferencia {
    static let modelo = "modelo"
    static let idioma = "idioma"
    static let copiarAoTerminar = "copiarAoTerminar"
    /// Som do sistema quando a transcrição termina (padrão: ligado).
    static let somAoTerminar = "somAoTerminar"
    /// Guardar cada transcrição no histórico local (padrão: ligado).
    static let guardarHistorico = "guardarHistorico"
    /// O histórico vale só até desligar ou reiniciar o Mac (padrão: ligado, pedido do owner).
    static let historicoSoNaSessao = "historicoSoNaSessao"
    /// Abrir o painel sozinho quando um áudio começa a ser arrastado em qualquer app (padrão: ligado).
    static let abrirAoArrastar = "abrirAoArrastar"

    static var abrirAoArrastarLigado: Bool {
        UserDefaults.standard.object(forKey: abrirAoArrastar) as? Bool ?? true
    }
}

/// Motores aprovados no benchmark da v0.2.0. "Automático" usa o mais rápido instalado (hoje: Parakeet v3).
enum ModeloTranscricao: String, CaseIterable, Identifiable {
    case automatico, parakeet, apple, whisperTurbo

    var id: String { rawValue }

    /// O escolhido no painel (o Whisper Turbo ainda não existe: vale como Automático).
    static var atual: ModeloTranscricao {
        let salvo = ModeloTranscricao(rawValue: UserDefaults.standard.string(forKey: Preferencia.modelo) ?? "")
        return salvo?.disponivel == true ? salvo! : .automatico
    }

    /// O Whisper Turbo (WhisperKit) entra na v0.6.
    var disponivel: Bool { self != .whisperTurbo }

    var nome: String {
        switch self {
        case .automatico: "Automático"
        case .parakeet: "Parakeet v3"
        case .apple: "Apple Speech"
        case .whisperTurbo: "Whisper Large v3 Turbo"
        }
    }

    /// O texto do botão no rodapé do painel.
    var rotuloCurto: String {
        switch self {
        case .automatico: "Mais rápido"
        case .parakeet: "Parakeet v3"
        case .apple: "Apple Speech"
        case .whisperTurbo: "Whisper Turbo"
        }
    }

    var descricao: String {
        switch self {
        case .automatico: "Usa sempre o mais rápido instalado. Hoje: Parakeet v3."
        case .parakeet: "O mais rápido · download único (470 MB)"
        case .apple: "Nativo do macOS · sem download"
        case .whisperTurbo: "Alternativa de qualidade · em breve"
        }
    }

    /// O motor que de fato vai transcrever.
    var motor: String { self == .automatico ? "Parakeet v3" : nome }

    var simbolo: String { self == .automatico ? "bolt" : "cpu" }
}

enum IdiomaAudio: String, CaseIterable, Identifiable {
    case auto, portugues = "pt", ingles = "en", espanhol = "es"

    var id: String { rawValue }

    static var atual: IdiomaAudio {
        IdiomaAudio(rawValue: UserDefaults.standard.string(forKey: Preferencia.idioma) ?? "") ?? .auto
    }

    /// Parakeet: `nil` detecta o idioma sozinho.
    var codigoParakeet: String? { self == .auto ? nil : rawValue }

    /// Apple Speech: não detecta sozinho; no "Auto" vale pt-BR (o motor trata `nil` assim).
    var codigoApple: String? {
        switch self {
        case .auto: nil
        case .portugues: "pt-BR"
        case .ingles: "en-US"
        case .espanhol: "es-ES"
        }
    }

    var nome: String {
        switch self {
        case .auto: "Auto"
        case .portugues: "Português"
        case .ingles: "English"
        case .espanhol: "Español"
        }
    }
}

/// "Abrir ao iniciar o Mac" (SMAppService). Funciona melhor com o app em /Applications.
enum InicioAutomatico {
    static var ativo: Bool { SMAppService.mainApp.status == .enabled }

    static func definir(_ ligar: Bool) {
        do {
            if ligar { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("Abrir ao iniciar o Mac: %@", error.localizedDescription)
        }
    }
}
