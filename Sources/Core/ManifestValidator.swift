import Foundation
import SharedModels

public struct ManifestValidator {
    public init() {}

    public func validate(_ manifest: Manifest) throws {
        guard manifest.schemaVersion == .v1_0_0 else {
            throw MoverError.unsupportedSchemaVersion(manifest.schemaVersion.rawValue)
        }

        if manifest.items.isEmpty {
            throw MoverError.invalidManifest("items must contain at least one element")
        }

        let ids = Set(manifest.items.map(\.id))
        if ids.count != manifest.items.count {
            throw MoverError.invalidManifest("item ids must be unique")
        }

        for step in manifest.restorePlan {
            for itemId in step.itemIds where !ids.contains(itemId) {
                throw MoverError.invalidManifest("restorePlan contains unknown item id: \(itemId)")
            }
        }
    }
}
