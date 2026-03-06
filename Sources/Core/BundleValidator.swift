import Foundation
import SharedModels

public struct BundleValidator {
    private let fileSystem: FileSysteming
    private let manifestStore: ManifestStore
    private let validator: ManifestValidator

    public init(
        fileSystem: FileSysteming = LocalFileSystem(),
        manifestStore: ManifestStore = ManifestStore(),
        validator: ManifestValidator = ManifestValidator()
    ) {
        self.fileSystem = fileSystem
        self.manifestStore = manifestStore
        self.validator = validator
    }

    public func validateBundle(at root: URL) throws -> Manifest {
        let layout = BundleLayout(root: root)
        let manifest = try manifestStore.read(from: layout.manifestURL)
        try validator.validate(manifest)

        if manifest.items.contains(where: { $0.kind == .brewFormula || $0.kind == .brewCask || $0.kind == .brewTap || $0.kind == .brewService }) {
            guard fileSystem.fileExists(at: layout.brewfileURL) else {
                throw MoverError.missingRequiredFile(layout.brewfileURL.path)
            }
        }

        return manifest
    }
}
