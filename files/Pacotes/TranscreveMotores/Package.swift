// swift-tools-version: 6.2
// Os motores de transcrição do TranscreveAI, fora do app para compilar e testar pelo terminal:
//   swift run --package-path files/Pacotes/TranscreveMotores --scratch-path ~/Library/Caches/TranscreveAI-motores transcrever <áudio>
import PackageDescription

let package = Package(
    name: "TranscreveMotores",
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
            dependencies: [.product(name: "FluidAudio", package: "FluidAudio")]
        ),
        .executableTarget(
            name: "transcrever",
            dependencies: ["TranscreveMotores"]
        ),
    ]
)
