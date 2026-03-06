import Foundation
import SharedModels
import Core

struct DotfilesExporter {
    private let fileSystem: FileSysteming
    private let allowlist: DotfileAllowlist
    private let manualTaskEngine: ManualTaskEngine
    private let homeDirectory: String

    init(
        fileSystem: FileSysteming,
        allowlist: DotfileAllowlist,
        manualTaskEngine: ManualTaskEngine,
        homeDirectory: String
    ) {
        self.fileSystem = fileSystem
        self.allowlist = allowlist
        self.manualTaskEngine = manualTaskEngine
        self.homeDirectory = homeDirectory
    }

    func export(to layout: BundleLayout) -> ComponentExportResult {
        var result = ComponentExportResult()

        for configuredPath in allowlist.paths {
            if SecretPolicy.shouldExclude(path: configuredPath) {
                result.manualTasks.append(manualTaskEngine.taskForExcludedSecret(configuredPath))
                result.skipped.append(
                    StepResult(id: "dotfile.skip.\(IdentifierSanitizer.sanitize(configuredPath))", title: configuredPath, status: .skipped, detail: "excluded by secret policy")
                )
                continue
            }

            let absolutePath = PathNormalizer.expandTilde(configuredPath, homeDirectory: homeDirectory)
            let sourceURL = URL(fileURLWithPath: absolutePath)
            guard fileSystem.fileExists(at: sourceURL) else {
                result.skipped.append(
                    StepResult(id: "dotfile.missing.\(IdentifierSanitizer.sanitize(configuredPath))", title: configuredPath, status: .skipped, detail: "file not found")
                )
                continue
            }

            let relativePath = PathNormalizer.normalizedDotfileRelativePath(configuredPath, homeDirectory: homeDirectory)
            let bundleRelative = "files/dotfiles/\(relativePath)"
            let destinationURL = layout.root.appendingPathComponent(bundleRelative)

            do {
                try fileSystem.copyItem(at: sourceURL, to: destinationURL)
                result.successes.append(
                    StepResult(id: "dotfile.export.\(IdentifierSanitizer.sanitize(configuredPath))", title: configuredPath, status: .success, detail: bundleRelative)
                )

                result.items.append(
                    ManifestItem(
                        id: "dotfile.\(IdentifierSanitizer.sanitize(relativePath))",
                        kind: .dotfile,
                        title: configuredPath,
                        restorePhase: .config,
                        source: ItemSource(path: configuredPath),
                        payload: ["relativePath": .string(bundleRelative)],
                        secret: false,
                        risk: .medium,
                        verify: VerifySpec(expectedFile: configuredPath),
                        notes: ["overwrite creates timestamped .bak backup"]
                    )
                )
            } catch {
                result.failures.append(
                    StepResult(id: "dotfile.export.\(IdentifierSanitizer.sanitize(configuredPath))", title: configuredPath, status: .failed, detail: error.localizedDescription)
                )
            }
        }

        return result
    }
}
