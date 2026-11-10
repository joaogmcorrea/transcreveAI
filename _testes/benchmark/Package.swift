// swift-tools-version: 6.0
// Benchmark de motores de transcrição em pt-BR (TranscreveAI v0.2.0).
// Build fora do Dropbox: swift build -c release --scratch-path ~/Library/Caches/TranscreveBench/build
import PackageDescription

let package = Package(
    name: "TranscreveBench",
    platforms: [.macOS("26.0")],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "1.1.1"),
        .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.18.3"),
    ],
    targets: [
        .executableTarget(
            name: "bench",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit"),
                .product(name: "FluidAudio", package: "FluidAudio"),
            ],
            path: "Sources/bench",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
