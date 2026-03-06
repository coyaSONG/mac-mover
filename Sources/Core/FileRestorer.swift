import Foundation

public struct FileRestorer {
    private let fileSystem: FileSysteming

    public init(fileSystem: FileSysteming = LocalFileSystem()) {
        self.fileSystem = fileSystem
    }

    @discardableResult
    public func backupIfNeeded(destination: URL, timestamp: Date = Date()) throws -> URL? {
        guard fileSystem.fileExists(at: destination) else {
            return nil
        }

        let backupURL = BackupNamer.backupURL(for: destination, timestamp: timestamp)
        try fileSystem.copyItem(at: destination, to: backupURL)
        return backupURL
    }

    public func restoreFile(from source: URL, to destination: URL, timestamp: Date = Date()) throws -> URL? {
        let backupURL = try backupIfNeeded(destination: destination, timestamp: timestamp)
        try fileSystem.copyItem(at: source, to: destination)
        return backupURL
    }

    public func restoreDirectoryContents(from sourceDirectory: URL, to destinationDirectory: URL, timestamp: Date = Date()) throws -> [URL] {
        try fileSystem.createDirectory(at: destinationDirectory)
        let children = try fileSystem.listDirectory(at: sourceDirectory)
        var backups: [URL] = []

        for child in children {
            let destination = destinationDirectory.appendingPathComponent(child.lastPathComponent)
            if let backup = try backupIfNeeded(destination: destination, timestamp: timestamp) {
                backups.append(backup)
            }
            try fileSystem.copyItem(at: child, to: destination)
        }

        return backups
    }
}
