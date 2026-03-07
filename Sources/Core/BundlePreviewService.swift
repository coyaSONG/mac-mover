import Foundation
import SharedModels

public protocol BundleArtifactReading {
    func readText(at url: URL) -> String
    func readLogPreview(at logsDirectory: URL) -> String
}

public struct BundleArtifactReader: BundleArtifactReading {
    private let fileSystem: FileSysteming

    public init(fileSystem: FileSysteming = LocalFileSystem()) {
        self.fileSystem = fileSystem
    }

    public func readText(at url: URL) -> String {
        guard fileSystem.fileExists(at: url) else {
            return "Not found: \(url.path)"
        }

        guard let data = try? fileSystem.readData(at: url),
              let content = String(data: data, encoding: .utf8) else {
            return "Unreadable: \(url.path)"
        }

        return content
    }

    public func readLogPreview(at logsDirectory: URL) -> String {
        guard let files = try? fileSystem.listDirectory(at: logsDirectory),
              let first = files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }).first else {
            return "No logs"
        }

        return readText(at: first)
    }
}

public struct BundlePreview: Sendable {
    public let bundleURL: URL
    public let manifest: Manifest
    public let preflight: PreflightResult
    public let exportSummary: String
    public let importSummary: String
    public let verifySummary: String
    public let logsPreview: String

    public init(
        bundleURL: URL,
        manifest: Manifest,
        preflight: PreflightResult,
        exportSummary: String,
        importSummary: String,
        verifySummary: String,
        logsPreview: String
    ) {
        self.bundleURL = bundleURL
        self.manifest = manifest
        self.preflight = preflight
        self.exportSummary = exportSummary
        self.importSummary = importSummary
        self.verifySummary = verifySummary
        self.logsPreview = logsPreview
    }
}

public protocol BundlePreviewLoading {
    func load(from bundleURL: URL) throws -> BundlePreview
}

public struct BundlePreviewService: BundlePreviewLoading {
    private let bundleValidator: BundleValidator
    private let preflightService: PreflightService
    private let artifactReader: BundleArtifactReading

    public init(
        fileSystem: FileSysteming = LocalFileSystem(),
        bundleValidator: BundleValidator? = nil,
        preflightService: PreflightService? = nil,
        artifactReader: BundleArtifactReading? = nil
    ) {
        self.bundleValidator = bundleValidator ?? BundleValidator(fileSystem: fileSystem)
        self.preflightService = preflightService ?? PreflightService(fileSystem: fileSystem)
        self.artifactReader = artifactReader ?? BundleArtifactReader(fileSystem: fileSystem)
    }

    public func load(from bundleURL: URL) throws -> BundlePreview {
        let layout = BundleLayout(root: bundleURL)
        let manifest = try bundleValidator.validateBundle(at: bundleURL)
        let preflight = preflightService.run(mode: .import(bundle: bundleURL))

        return BundlePreview(
            bundleURL: bundleURL,
            manifest: manifest,
            preflight: preflight,
            exportSummary: artifactReader.readText(at: layout.exportSummaryURL),
            importSummary: artifactReader.readText(at: layout.importSummaryURL),
            verifySummary: artifactReader.readText(at: layout.verifySummaryURL),
            logsPreview: artifactReader.readLogPreview(at: layout.logsDirectory)
        )
    }
}
