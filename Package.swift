// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MacDevEnvMover",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MacDevEnvMover", targets: ["App"]),
        .library(name: "SharedModels", targets: ["SharedModels"]),
        .library(name: "Core", targets: ["Core"]),
        .library(name: "Reporting", targets: ["Reporting"]),
        .library(name: "Exporters", targets: ["Exporters"]),
        .library(name: "Importers", targets: ["Importers"])
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
            dependencies: ["Core", "SharedModels", "Reporting"]
        ),
        .testTarget(
            name: "ExporterImporterTests",
            dependencies: ["Exporters", "Importers", "Core", "SharedModels", "Reporting"]
        ),
        .testTarget(
            name: "ManifestSchemaTests",
            dependencies: ["Core", "SharedModels"]
        )
    ]
)
