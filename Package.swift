// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MacMover",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MacMover", targets: ["App"]),
        .library(name: "Localization", targets: ["Localization"]),
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
            name: "Localization",
            resources: [.process("Resources")]
        ),
        .target(
            name: "SharedModels"
        ),
        .target(
            name: "Core",
            dependencies: ["SharedModels", "Localization"]
        ),
        .target(
            name: "Reporting",
            dependencies: ["SharedModels", "Core", "Localization"]
        ),
        .target(
            name: "Exporters",
            dependencies: ["Core", "SharedModels", "Reporting", "Localization"]
        ),
        .target(
            name: "Importers",
            dependencies: ["Core", "SharedModels", "Reporting", "Localization"]
        ),
        .executableTarget(
            name: "App",
            dependencies: ["Core", "SharedModels", "Exporters", "Importers", "Reporting", "Localization"],
            path: "Sources/App",
            exclude: ["Info.plist"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/App/Info.plist"
                ])
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: [
                "Core",
                "SharedModels",
                "Reporting",
                "Localization",
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
                "Localization",
                .product(name: "Testing", package: "swift-testing")
            ]
        )
    ]
)
