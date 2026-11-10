import AVFoundation
import Speech

/// Apple Speech (`SpeechAnalyzer` + `SpeechTranscriber`): já vem no macOS, sem download para o pt-BR, e entrega o
/// texto aos poucos (a prévia ao vivo). É o motor de reserva enquanto o Parakeet baixa e compila.
public enum MotorApple {
    /// `idioma`: código BCP 47 ("pt-BR", "en"…) ou `nil` para pt-BR. O Apple Speech não detecta o idioma sozinho,
    /// e usar o idioma do sistema erra feio num Mac em inglês com áudio em português (visto no teste da v0.4).
    public static func transcrever(
        _ audio: AudioPronto, idioma: String?, progresso: @escaping @Sendable (Progresso) -> Void
    ) async throws -> [Segmento] {
        let pedido = Locale(identifier: idioma ?? "pt-BR")
        guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: pedido) else {
            throw ErroDeTranscricao.idiomaIndisponivel(pedido.identifier)
        }

        let transcritor = SpeechTranscriber(locale: locale, preset: .transcription)
        if let instalacao = try await AssetInventory.assetInstallationRequest(supporting: [transcritor]) {
            progresso(Progresso(etapa: .preparandoModelo))
            try await instalacao.downloadAndInstall()
        }
        let analisador = SpeechAnalyzer(modules: [transcritor])
        let arquivo = try AVAudioFile(forReading: audio.url)
        progresso(Progresso(etapa: .transcrevendo(0)))

        async let frases = coletar(transcritor, duracao: audio.duracao, progresso: progresso)
        try await withTaskCancellationHandler {
            if let ultimo = try await analisador.analyzeSequence(from: arquivo) {
                try await analisador.finalizeAndFinish(through: ultimo)
            } else {
                await analisador.cancelAndFinishNow()
            }
        } onCancel: {
            Task { await analisador.cancelAndFinishNow() }
        }
        return try await frases
    }

    private static func coletar(
        _ transcritor: SpeechTranscriber, duracao: TimeInterval, progresso: @escaping @Sendable (Progresso) -> Void
    ) async throws -> [Segmento] {
        var frases: [Segmento] = []
        for try await resultado in transcritor.results {
            var texto = String(resultado.text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
            // Às vezes o resultado começa com o ponto final do anterior (". Parte dois…"): devolve o sinal à frase anterior.
            if let primeiro = texto.first, primeiro.isPunctuation, var anterior = frases.last {
                let sinais = texto.prefix { $0.isPunctuation || $0 == " " }.filter { $0 != " " }
                if let ultimo = anterior.texto.last, !ultimo.isPunctuation { anterior.texto += String(sinais.prefix(1)) }
                frases[frases.count - 1] = anterior
                texto = String(texto.drop { $0.isPunctuation || $0 == " " })
            }
            guard !texto.isEmpty else { continue }
            let frase = Segmento(inicio: resultado.range.start.seconds, fim: resultado.range.end.seconds, texto: texto)
            frases.append(frase)
            progresso(Progresso(etapa: .transcrevendo(min(1, frase.fim / max(duracao, 0.1))), previa: frases))
        }
        return frases
    }
}
