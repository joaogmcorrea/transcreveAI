import FluidAudio
import Foundation

/// Parakeet TDT v3 (FluidAudio, CoreML): o padrão do "Automático", o mais rápido no benchmark (145× tempo real).
/// O modelo (~470 MB) é baixado uma vez para Application Support/TranscreveAI/Modelos e fica carregado na
/// memória depois do primeiro uso: a primeira carga compila para o Neural Engine e leva uns 40 s.
public actor MotorParakeet {
    public static let compartilhado = MotorParakeet()

    private let pasta: URL
    private var asr: AsrManager?
    private var camadas = 2
    private var preparo: Task<Void, Error>?

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TranscreveAI/Modelos", isDirectory: true)
        pasta = base.appendingPathComponent(
            AsrModels.defaultCacheDirectory(for: .v3).lastPathComponent, isDirectory: true)
    }

    /// O modelo já está no disco (pode ainda não estar carregado).
    public var baixado: Bool { AsrModels.modelsExist(at: pasta, version: .v3) }

    /// Carregado na memória: a próxima transcrição começa na hora.
    public var pronto: Bool { asr != nil }

    public enum Preparo: Sendable {
        case baixando(Double)  // 0…1
        case compilando
    }

    /// Baixa (se precisar) e carrega o modelo. Chamadas ao mesmo tempo esperam o mesmo preparo.
    public func preparar(progresso: (@Sendable (Preparo) -> Void)? = nil) async throws {
        if asr != nil { return }
        if let preparo { return try await preparo.value }
        let pasta = self.pasta
        let tarefa = Task {
            // O FluidAudio conta o download de 0 a 50% e a compilação de 50 a 100%.
            let modelos = try await AsrModels.downloadAndLoad(to: pasta, version: .v3, progressHandler: { p in
                switch p.phase {
                case .listing, .downloading: progresso?(.baixando(min(1, p.fractionCompleted * 2)))
                case .compiling: progresso?(.compilando)
                }
            })
            let gerente = AsrManager(config: .default)
            try await gerente.loadModels(modelos)
            self.instalar(gerente, camadas: modelos.version.decoderLayers)
        }
        preparo = tarefa
        do {
            try await tarefa.value
            preparo = nil
        } catch {
            preparo = nil
            throw error
        }
    }

    private func instalar(_ gerente: AsrManager, camadas: Int) {
        asr = gerente
        self.camadas = camadas
    }

    /// `idioma`: "pt", "en", "es"… ou `nil` para detectar sozinho.
    ///
    /// Transcreve aos pedaços para o texto aparecer enquanto o resto ainda é transcrito (pedido do owner,
    /// 17/11/2026). O áudio é lido aos poucos; cada emenda entre dois pedaços fica numa pausa, e cada pedaço passa
    /// pelo FluidAudio como um áudio inteiro, ouvindo 1 s a mais de cada lado da emenda. De cada pedaço só ficam as
    /// palavras que começam do lado dele: a palavra da emenda é ouvida inteira pelos dois e entra uma vez só (um corte
    /// seco chegava a comer uma palavra). O primeiro pedaço tem até 15 s, para o texto aparecer na hora; o segundo,
    /// 4 min; os outros, 10 min (cada emenda custa um pouco: dobrar aos poucos deixava 10 min de áudio 15% mais
    /// lentos). O próximo pedaço é lido e convertido enquanto o atual é transcrito, e por isso o total ficou igual ou
    /// mais rápido que o arquivo inteiro de uma vez (medido em 17/11/2026 no M4 Pro: 10 min em 2,4 s contra 2,7 s;
    /// 60 min em 13,2 s contra 13,0 s; o primeiro texto sai em 0,1 s).
    public func transcrever(
        _ audio: AudioPronto, idioma: String?, progresso: @escaping @Sendable (Progresso) -> Void
    ) async throws -> [Segmento] {
        if asr == nil {
            progresso(Progresso(etapa: .preparandoModelo))
            try await preparar()
        }
        guard let asr else { throw ErroDeTranscricao.modeloIndisponivel("Parakeet v3") }
        progresso(Progresso(etapa: .transcrevendo(0)))

        let cortador = try Pedacos(LeitorDeAmostras(audio.url))
        let taxa = LeitorDeAmostras.taxa
        let total = max(1, audio.duracao * taxa)
        let minimo = ASRConstants.minimumRequiredSamples(forSampleRate: Int(taxa))
        let lingua = idioma.flatMap { Language(rawValue: $0) }
        var tokens: [TokenTiming] = []
        var frases: [Segmento] = []
        var sobra: [[TokenTiming]] = []  // o que o pedaço anterior ouviu depois da emenda (só para costurar)

        // Um pedaço adiantado: a leitura do próximo corre junto com a transcrição deste. Cada leitura só começa
        // depois que a anterior terminou, então o cortador nunca é usado por duas tarefas ao mesmo tempo.
        var proximo = Task.detached { try cortador.proximo() }
        defer { proximo.cancel() }
        while let pedaco = try await proximo.value {
            proximo = Task.detached { try cortador.proximo() }
            try Task.checkCancellation()
            let deslocamento = Double(pedaco.inicio) / taxa
            let de = Double(pedaco.de) / taxa
            let ate = pedaco.ultimo ? .infinity : Double(pedaco.ate) / taxa

            if pedaco.amostras.count >= minimo {
                var estado = try TdtDecoderState(decoderLayers: camadas)
                let resultado = try await asr.transcribe(pedaco.amostras, decoderState: &estado, language: lingua)
                try Task.checkCancellation()
                if let tempos = resultado.tokenTimings, !tempos.isEmpty {
                    let palavras = Emenda.palavras(tempos.map {
                        TokenTiming(
                            token: $0.token, tokenId: $0.tokenId, startTime: $0.startTime + deslocamento,
                            endTime: $0.endTime + deslocamento, confidence: $0.confidence)
                    })
                    // Palavras inteiras pelo começo: as que começam antes de `de` ou depois de `ate` estão na margem,
                    // que é do vizinho.
                    var minhas = palavras.filter { $0[0].startTime >= de && $0[0].startTime < ate }
                    Emenda.costurar(&minhas, depoisDe: tokens, comoOAnteriorOuviu: sobra)
                    tokens += minhas.joined()
                    sobra = palavras.filter { $0[0].startTime >= ate }
                } else if !resultado.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // Sem os tempos das palavras: o pedaço vira uma frase só.
                    tokens.append(TokenTiming(
                        token: "▁" + resultado.text, tokenId: -1, startTime: de,
                        endTime: Double(pedaco.ate) / taxa, confidence: 1))
                }
                // Refeitas do zero a cada pedaço: uma frase que atravessa a emenda se junta de novo.
                frases = Paragrafos.frases(tokens: tokens, texto: "", duracao: audio.duracao)
            }
            progresso(Progresso(etapa: .transcrevendo(min(1, Double(pedaco.ate) / total)), previa: frases))
        }
        return frases
    }
}

/// A emenda entre dois pedaços: os dois ouvem a palavra que fica nela, e cada um pode marcar o começo dela de um
/// lado diferente da emenda (visto em 17/11/2026: "Qu Quando"), ou o de depois pode começar a frase com maiúscula
/// ("um link Do que"). Aqui a palavra entra uma vez só, com a caixa que o pedaço anterior, que ouviu a frase
/// desde o começo, deu a ela.
enum Emenda {
    /// Agrupa os tokens em palavras: um token que começa com espaço (o "▁" do SentencePiece, que o FluidAudio já
    /// troca por espaço) abre uma palavra; os seguintes (o resto da palavra e a pontuação) vão junto.
    static func palavras(_ tokens: [TokenTiming]) -> [[TokenTiming]] {
        var palavras: [[TokenTiming]] = []
        for token in tokens {
            if abreUmaPalavra(token) || palavras.isEmpty {
                palavras.append([token])
            } else {
                palavras[palavras.count - 1].append(token)
            }
        }
        return palavras
    }

    static func costurar(
        _ novas: inout [[TokenTiming]], depoisDe anteriores: [TokenTiming], comoOAnteriorOuviu sobra: [[TokenTiming]]
    ) {
        guard let primeira = novas.first, !anteriores.isEmpty else { return }
        let texto = normalizar(primeira)
        guard !texto.isEmpty else { return }

        // A mesma palavra dos dois lados (ou um pedaço dela): fica a do pedaço anterior.
        let inicioDaUltima = anteriores.lastIndex(where: abreUmaPalavra) ?? 0
        let ultima = Array(anteriores[inicioDaUltima...])
        let anterior = normalizar(ultima)
        if !anterior.isEmpty, abs(ultima[0].startTime - primeira[0].startTime) < 0.6,
           anterior == texto || (min(anterior.count, texto.count) >= 2
                                 && (anterior.hasPrefix(texto) || texto.hasPrefix(anterior))) {
            novas.removeFirst()
            return
        }

        // Maiúscula ou minúscula: como o pedaço anterior ouviu a mesma palavra, na margem dele.
        guard let mesma = sobra.first, normalizar(mesma) == texto,
              abs(mesma[0].startTime - primeira[0].startTime) < 0.6,
              let letra = primeiraLetra(mesma[0].token), let atual = primeiraLetra(primeira[0].token), letra != atual
        else { return }
        let token = primeira[0]
        novas[0][0] = TokenTiming(
            token: token.token.replacingCharacters(in: atualRange(token.token)!, with: String(letra)),
            tokenId: token.tokenId, startTime: token.startTime, endTime: token.endTime, confidence: token.confidence)
    }

    private static func abreUmaPalavra(_ token: TokenTiming) -> Bool {
        token.token.hasPrefix(" ") || token.token.hasPrefix("▁")
    }

    /// A palavra em minúsculas, sem espaço nem pontuação.
    private static func normalizar(_ palavra: [TokenTiming]) -> String {
        palavra.map(\.token).joined().lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private static func primeiraLetra(_ token: String) -> Character? {
        token.first { $0.isLetter }
    }

    private static func atualRange(_ token: String) -> Range<String.Index>? {
        token.firstIndex { $0.isLetter }.map { $0..<token.index(after: $0) }
    }
}

/// Corta o áudio em pedaços cujas emendas caem numa pausa: a primeira em até 14 s, a segunda 4 min depois e as
/// seguintes a cada 10 min.
/// Cada pedaço leva `margem` de áudio a mais de cada lado da emenda.
/// `@unchecked Sendable`: passa de uma tarefa para a seguinte, nunca por duas ao mesmo tempo (ver `transcrever`).
final class Pedacos: @unchecked Sendable {
    static let primeiro = 14 * 16_000  // amostras: com a margem, 15 s, um passo só do modelo (o texto sai na hora)
    static let segundo = 240 * 16_000
    static let maximo = 600 * 16_000
    static let folga = 10 * 16_000     // o último pedaço leva até isto a mais, para não sobrar um tiquinho solto
    static let margem = 16_000         // 1 s de cada lado da emenda
    static let busca = 5 * 16_000      // procura a pausa nos últimos 5 s antes do alvo
    static let quadro = 320            // 20 ms
    static let janela = 10             // quadros: a pausa é o trecho de 200 ms mais quieto

    struct Pedaco: Sendable {
        var amostras: [Float]
        var inicio: Int  // a amostra do áudio em que `amostras` começa (com a margem)
        var de: Int      // as palavras deste pedaço começam entre `de` e `ate` (sem as margens)
        var ate: Int
        var ultimo: Bool
    }

    private let leitor: LeitorDeAmostras
    private var buffer: [Float] = []
    private var bufferInicio = 0  // a amostra do áudio em que `buffer` começa
    private var emenda = 0        // onde começa o próximo pedaço
    private var alvo = Pedacos.primeiro

    init(_ leitor: LeitorDeAmostras) {
        self.leitor = leitor
    }

    /// O próximo pedaço, ou `nil` quando o áudio acabou.
    func proximo() throws -> Pedaco? {
        while bufferInicio + buffer.count - emenda < alvo + Self.folga + Self.margem,
              let bloco = try leitor.proximoBloco() {
            buffer.append(contentsOf: bloco)
        }
        let fimDoBuffer = bufferInicio + buffer.count
        guard fimDoBuffer > emenda else { return nil }
        let ultimo = leitor.acabou && fimDoBuffer - emenda <= alvo + Self.folga
        let novaEmenda = ultimo
            ? fimDoBuffer
            : bufferInicio + Self.pausa(em: buffer, de: emenda + alvo - Self.busca - bufferInicio,
                                        ate: emenda + alvo - bufferInicio)
        let comeco = max(bufferInicio, emenda - Self.margem)
        let fim = min(fimDoBuffer, novaEmenda + Self.margem)
        let pedaco = Pedaco(
            amostras: Array(buffer[(comeco - bufferInicio)..<(fim - bufferInicio)]),
            inicio: comeco, de: emenda, ate: novaEmenda, ultimo: ultimo)
        // Guarda só a margem antes da nova emenda: o começo do próximo pedaço.
        let descartar = min(buffer.count, max(0, novaEmenda - Self.margem - bufferInicio))
        buffer.removeFirst(descartar)
        bufferInicio += descartar
        emenda = novaEmenda
        alvo = alvo == Self.primeiro ? Self.segundo : Self.maximo
        return pedaco
    }

    /// O trecho de 200 ms mais quieto entre `de` e `ate` (posições em `amostras`): o meio dele é a emenda.
    static func pausa(em amostras: [Float], de: Int, ate: Int) -> Int {
        let fim = min(ate, amostras.count)
        let comeco = max(0, de)
        guard fim - comeco >= quadro * janela else { return fim }
        let quadros = (fim - comeco) / quadro
        var energias = [Float](repeating: 0, count: quadros)
        amostras.withUnsafeBufferPointer { ponteiro in
            for q in 0..<quadros {
                var soma: Float = 0
                let base = comeco + q * quadro
                for i in base..<(base + quadro) { soma += ponteiro[i] * ponteiro[i] }
                energias[q] = soma
            }
        }
        // 200 ms: uma pausa de verdade, não o vale de uma sílaba. No empate, a mais tardia.
        var melhor = 0
        var menor = Float.greatestFiniteMagnitude
        var soma: Float = energias[0..<janela].reduce(0, +)
        for q in 0...(quadros - janela) {
            if q > 0 { soma += energias[q + janela - 1] - energias[q - 1] }
            if soma <= menor {
                menor = soma
                melhor = q
            }
        }
        return comeco + (melhor * quadro) + (janela * quadro) / 2
    }
}
