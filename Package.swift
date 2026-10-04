// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GemIDScanner",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
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
