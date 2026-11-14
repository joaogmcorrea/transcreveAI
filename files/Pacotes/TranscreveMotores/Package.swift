// swift-tools-version: 6.2
// Os motores de transcrição do TranscreveAI, fora do app para compilar e testar pelo terminal:
//   swift run --package-path files/Pacotes/TranscreveMotores --scratch-path ~/Library/Caches/TranscreveAI-motores transcrever <áudio>
import PackageDescription

let package = Package(
    name: "TranscreveMotores",
    // As mensagens de erro saem no idioma do app (Localizable.xcstrings do alvo): pt-BR, en e es.
    defaultLocalization: "pt-BR",
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "TranscreveMotores", targets: ["TranscreveMotores"]),
        .executable(name: "transcrever", targets: ["transcrever"]),
    ],
    dependencies: [
        // Só reconhecimento de fala (ASR/VAD): `traits: []` desliga síntese de voz, separação de falantes e a
        // normalização de texto, que somam uns 57 MB a mais no app (recomendação do próprio FluidAudio).
        .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.18.3", traits: []),
    ],
    targets: [
        .target(
            name: "TranscreveMotores",
            dependencies: [.product(name: "FluidAudio", package: "FluidAudio")],
            resources: [.process("Localizable.xcstrings")]
        ),
        .executableTarget(
            name: "transcrever",
            dependencies: ["TranscreveMotores"]
        ),
    ]
)
