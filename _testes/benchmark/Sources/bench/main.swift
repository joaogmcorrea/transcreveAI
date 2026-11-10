// bench — mede um motor de transcrição em um arquivo de áudio.
//
// Uso: bench <motor> <audio.wav> <pasta-saida>
// Motores: apple | parakeet | whisper-turbo | whisper-large
//
// Grava <pasta-saida>/<motor>.txt (texto) e <pasta-saida>/<motor>.json (métricas).
// O carregamento do modelo é medido à parte da transcrição: no app o modelo
// fica carregado, então o tempo que importa é o de transcrição.

import AVFoundation
import FluidAudio
import Foundation
import Speech
import WhisperKit

let cacheDir = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Caches/TranscreveBench/models", isDirectory: true)

struct Run {
    let text: String
    let loadSeconds: Double
    let transcribeSeconds: Double
    let detail: String
}

enum BenchError: Error, CustomStringConvertible {
    case usage
    case unknownEngine(String)
    case localeUnavailable

    var description: String {
        switch self {
        case .usage: return "uso: bench <apple|parakeet|whisper-turbo|whisper-large> <audio.wav> <pasta-saida>"
        case .unknownEngine(let e): return "motor desconhecido: \(e)"
        case .localeUnavailable: return "Apple Speech não suporta pt-BR neste Mac"
        }
    }
}

func elapsed(since start: DispatchTime) -> Double {
    Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1e9
}

// MARK: - Apple Speech (SpeechAnalyzer + SpeechTranscriber)

func runApple(_ url: URL) async throws -> Run {
    let t0 = DispatchTime.now()
    guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: "pt-BR")) else {
        throw BenchError.localeUnavailable
    }
    let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)
    if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
        try await request.downloadAndInstall()
    }
    let analyzer = SpeechAnalyzer(modules: [transcriber])
    let load = elapsed(since: t0)

    let t1 = DispatchTime.now()
    let file = try AVAudioFile(forReading: url)
    async let parts: [String] = transcriber.results.reduce(into: [String]()) { acc, result in
        acc.append(String(result.text.characters))
    }
    if let last = try await analyzer.analyzeSequence(from: file) {
        try await analyzer.finalizeAndFinish(through: last)
    } else {
        await analyzer.cancelAndFinishNow()
    }
    let text = try await parts.joined(separator: " ")
    return Run(text: text, loadSeconds: load, transcribeSeconds: elapsed(since: t1), detail: "SpeechTranscriber \(locale.identifier)")
}

// MARK: - Parakeet TDT v3 (FluidAudio)

func runParakeet(_ url: URL) async throws -> Run {
    let t0 = DispatchTime.now()
    let models = try await AsrModels.downloadAndLoad(
        to: cacheDir.appendingPathComponent("fluidaudio", isDirectory: true), version: .v3)
    let asr = AsrManager(config: .default)
    try await asr.loadModels(models)
    var state = try TdtDecoderState(decoderLayers: models.version.decoderLayers)
    let load = elapsed(since: t0)

    let t1 = DispatchTime.now()
    let result = try await asr.transcribe(url, decoderState: &state, language: .portuguese)
    return Run(text: result.text, loadSeconds: load, transcribeSeconds: elapsed(since: t1), detail: "parakeet-tdt-0.6b-v3")
}

// MARK: - Whisper (WhisperKit / CoreML)

func runWhisper(_ url: URL, variant: String) async throws -> Run {
    let t0 = DispatchTime.now()
    let config = WhisperKitConfig(
        model: variant,
        downloadBase: cacheDir.appendingPathComponent("whisperkit", isDirectory: true),
        verbose: false,
        logLevel: .error,
        prewarm: true,
        load: true,
        download: true
    )
    let whisper = try await WhisperKit(config)
    let load = elapsed(since: t0)

    let options = DecodingOptions(
        verbose: false,
        task: .transcribe,
        language: "pt",
        temperature: 0,
        usePrefillPrompt: true,
        detectLanguage: false,
        skipSpecialTokens: true,
        withoutTimestamps: false,
        chunkingStrategy: .vad
    )
    let t1 = DispatchTime.now()
    let results = try await whisper.transcribe(audioPath: url.path, decodeOptions: options)
    let text = results.map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }.joined(separator: " ")
    return Run(text: text, loadSeconds: load, transcribeSeconds: elapsed(since: t1), detail: variant)
}

// MARK: - WER (taxa de erro por palavra)

func normalizedWords(_ text: String) -> [Substring] {
    let lowered = text.lowercased()
    let cleaned = String(lowered.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : " " })
    return cleaned.split(separator: " ")
}

/// Distância de edição em palavras (substituição, inserção, remoção) dividida pelo nº de palavras da referência.
func wordErrorRate(reference: String, hypothesis: String) -> (wer: Double, refWords: Int, hypWords: Int) {
    let ref = normalizedWords(reference)
    let hyp = normalizedWords(hypothesis)
    guard !ref.isEmpty else { return (hyp.isEmpty ? 0 : 1, 0, hyp.count) }
    var prev = Array(0...hyp.count)
    var cur = [Int](repeating: 0, count: hyp.count + 1)
    for i in 1...ref.count {
        cur[0] = i
        if !hyp.isEmpty {
            for j in 1...hyp.count {
                let cost = ref[i - 1] == hyp[j - 1] ? 0 : 1
                cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
            }
        }
        swap(&prev, &cur)
    }
    return (Double(prev[hyp.count]) / Double(ref.count), ref.count, hyp.count)
}

// MARK: - Main

func audioSeconds(_ url: URL) throws -> Double {
    let file = try AVAudioFile(forReading: url)
    return Double(file.length) / file.fileFormat.sampleRate
}

let args = CommandLine.arguments
do {
    guard args.count == 4 else { throw BenchError.usage }
    if args[1] == "wer" {
        // bench wer <referencia.txt> <hipotese.txt>
        let ref = try String(contentsOfFile: args[2], encoding: .utf8)
        let hyp = try String(contentsOfFile: args[3], encoding: .utf8)
        let r = wordErrorRate(reference: ref, hypothesis: hyp)
        print(String(format: "{\"wer\": %.4f, \"refWords\": %d, \"hypWords\": %d}", r.wer, r.refWords, r.hypWords))
        exit(0)
    }
    let engine = args[1]
    let input = URL(fileURLWithPath: args[2])
    let outDir = URL(fileURLWithPath: args[3], isDirectory: true)
    try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

    let run: Run
    switch engine {
    case "apple": run = try await runApple(input)
    case "parakeet": run = try await runParakeet(input)
    case "whisper-turbo": run = try await runWhisper(input, variant: "openai_whisper-large-v3-v20240930_turbo")
    case "whisper-large": run = try await runWhisper(input, variant: "openai_whisper-large-v3")
    default: throw BenchError.unknownEngine(engine)
    }

    let duration = try audioSeconds(input)
    let metrics: [String: Any] = [
        "engine": engine,
        "detail": run.detail,
        "audioSeconds": duration,
        "loadSeconds": run.loadSeconds,
        "transcribeSeconds": run.transcribeSeconds,
        "realtimeFactor": duration / max(run.transcribeSeconds, 0.001),
        "chars": run.text.count,
    ]
    try run.text.write(to: outDir.appendingPathComponent("\(engine).txt"), atomically: true, encoding: .utf8)
    let json = try JSONSerialization.data(withJSONObject: metrics, options: [.prettyPrinted, .sortedKeys])
    try json.write(to: outDir.appendingPathComponent("\(engine).json"))
    print(String(format: "%@  áudio %.0fs  carga %.1fs  transcrição %.1fs  (%.0f× tempo real)",
                 engine, duration, run.loadSeconds, run.transcribeSeconds, duration / max(run.transcribeSeconds, 0.001)))
} catch {
    FileHandle.standardError.write("erro: \(error)\n".data(using: .utf8)!)
    exit(1)
}
