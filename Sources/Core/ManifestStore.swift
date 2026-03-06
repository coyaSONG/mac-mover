import Foundation
import SharedModels

public struct ManifestStore: Sendable {
    private let fileSystem: FileSysteming

    public init(fileSystem: FileSysteming = LocalFileSystem()) {
        self.fileSystem = fileSystem
    }

    public func write(_ manifest: Manifest, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(manifest)
        try fileSystem.writeData(data, to: url)
    }

    public func read(from url: URL) throws -> Manifest {
        guard fileSystem.fileExists(at: url) else {
            throw MoverError.missingRequiredFile(url.path)
        }
        let data = try fileSystem.readData(at: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest = try decoder.decode(Manifest.self, from: data)
        return manifest
    }
}
