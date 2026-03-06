#if canImport(XCTest)
import XCTest
@testable import SharedModels
@testable import Core

final class ManifestTests: XCTestCase {
    func testManifestEncodeDecodeRoundTrip() throws {
        let manifest = makeManifest()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(manifest)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Manifest.self, from: data)

        XCTAssertEqual(decoded.schemaVersion, .v1_0_0)
        XCTAssertEqual(decoded.machine.hostname, "test-host")
        XCTAssertEqual(decoded.items.count, 2)
        XCTAssertEqual(decoded.restorePlan.last?.phase, .verify)
    }

    func testSchemaCompatibilityWithSampleManifest() throws {
        let sampleURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("spec")
            .appendingPathComponent("manifest.sample.json")

        let data = try Data(contentsOf: sampleURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest = try decoder.decode(Manifest.self, from: data)

        let validator = ManifestValidator()
        XCTAssertNoThrow(try validator.validate(manifest))
    }

    func testValidatorRejectsUnknownRestoreIds() throws {
        var manifest = makeManifest()
        manifest.restorePlan.append(RestoreStep(phase: .config, itemIds: ["missing.id"]))

        let validator = ManifestValidator()
        XCTAssertThrowsError(try validator.validate(manifest))
    }

    func testManifestStoreReadWriteRoundTrip() throws {
        let manifest = makeManifest()
        let fileSystem = InMemoryFileSystem()
        let store = ManifestStore(fileSystem: fileSystem)
        let manifestURL = URL(fileURLWithPath: "/tmp/export/manifest.json")

        try store.write(manifest, to: manifestURL)
        let decoded = try store.read(from: manifestURL)

        XCTAssertEqual(decoded, manifest)
    }

    private func makeManifest() -> Manifest {
        Manifest(
            exportedAt: Date(timeIntervalSince1970: 1_700_000_000),
            machine: MachineInfo(
                hostname: "test-host",
                architecture: .arm64,
                macosVersion: "15.3",
                homeDirectory: "/Users/test",
                homebrewPrefix: "/opt/homebrew",
                userName: "test"
            ),
            items: [
                ManifestItem(
                    id: "brew.formula.git",
                    kind: .brewFormula,
                    title: "git",
                    restorePhase: .packages,
                    payload: ["name": .string("git")],
                    secret: false
                ),
                ManifestItem(
                    id: "dotfile.zshrc",
                    kind: .dotfile,
                    title: "~/.zshrc",
                    restorePhase: .config,
                    source: ItemSource(path: "~/.zshrc"),
                    payload: ["relativePath": .string("files/dotfiles/.zshrc")],
                    secret: false,
                    verify: VerifySpec(expectedFile: "~/.zshrc")
                )
            ],
            restorePlan: [
                RestoreStep(phase: .packages, itemIds: ["brew.formula.git"]),
                RestoreStep(phase: .config, itemIds: ["dotfile.zshrc"]),
                RestoreStep(phase: .verify, itemIds: ["brew.formula.git", "dotfile.zshrc"])
            ],
            reports: ManifestReports(exportSummaryPath: "reports/export-summary.md", verifySummaryPath: "reports/verify-summary.md")
        )
    }
}
#endif
