// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WhisperSwift",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "WhisperSwift", targets: ["WhisperSwift"]),
    ],
    dependencies: [
        .package(path: "../whisper.cpp"),
    ],
    targets: [
        .target(
            name: "WhisperC",
            dependencies: [
                .product(name: "whispercpp", package: "whispercpp"),
            ],
            path: "Sources/WhisperC",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
                .headerSearchPath("../../whisper.cpp/include"),
                .headerSearchPath("../../whisper.cpp/ggml/include"),
            ],
            cxxSettings: [
                .unsafeFlags(["-std=c++17"]),
            ]
        ),
        .target(
            name: "WhisperSwift",
            dependencies: ["WhisperC"],
            path: "Sources/WhisperSwift"
        ),
    ]
)

