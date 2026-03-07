// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MacMover",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MacMover", targets: ["App"]),
        .library(name: "SharedModels", targets: ["SharedModels"]),
        .library(name: "Core", targets: ["Core"]),
        .library(name: "Reporting", targets: ["Reporting"]),
        .library(name: "Exporters", targets: ["Exporters"]),
        .library(name: "Importers", targets: ["Importers"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", from: "0.99.0")
    ],
    targets: [
        .target(
            name: "SharedModels"
        ),
        .target(
            name: "Core",
            dependencies: ["SharedModels"]
        ),
        .target(
            name: "Reporting",
            dependencies: ["SharedModels", "Core"]
        ),
        .target(
            name: "Exporters",
            dependencies: ["Core", "SharedModels", "Reporting"]
        ),
        .target(
            name: "Importers",
            dependencies: ["Core", "SharedModels", "Reporting"]
        ),
        .executableTarget(
            name: "App",
            dependencies: ["Core", "SharedModels", "Exporters", "Importers", "Reporting"],
            path: "Sources/App"
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: [
                "Core",
                "SharedModels",
                "Reporting",
                .product(name: "Testing", package: "swift-testing")
            ]
        ),
        .testTarget(
            name: "ExporterImporterTests",
            dependencies: [
                "Exporters",
                "Importers",
                "Core",
                "SharedModels",
                "Reporting",
                .product(name: "Testing", package: "swift-testing")
            ]
        ),
        .testTarget(
            name: "ManifestSchemaTests",
            dependencies: [
                "Core",
                "SharedModels",
                .product(name: "Testing", package: "swift-testing")
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                "App",
                "Core",
                "SharedModels",
                "Reporting",
                .product(name: "Testing", package: "swift-testing")
            ]
        )
    ]
)
