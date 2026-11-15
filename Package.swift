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
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", exact: "12.19.3"),
    ],
    targets: [
        .target(
            name: "GemIDScanner",
            dependencies: [
                .product(name: "FirebaseAILogic", package: "Firebase"),
                .product(name: "FirebaseAppCheck", package: "Firebase"),
                .product(name: "FirebaseRemoteConfig", package: "Firebase"),
                .product(name: "FirebaseAuth", package: "Firebase"),
                .product(name: "FirebaseFirestore", package: "Firebase"),
                .product(name: "FirebaseCore", package: "Firebase"),
            ],
            path: "GemIDScanner/Sources",
            resources: []
        ),
    ]
)
