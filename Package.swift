// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "GemIDScanner",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "GemIDScanner",
            targets: ["GemIDScanner"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "GemIDScanner",
            dependencies: [],
            path: "GemIDScanner/Sources",
            resources: []
        ),
    ]
)
