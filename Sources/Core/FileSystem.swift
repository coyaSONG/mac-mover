import Foundation

public protocol FileSysteming: Sendable {
    func fileExists(at url: URL) -> Bool
    func createDirectory(at url: URL) throws
    func readData(at url: URL) throws -> Data
    func writeData(_ data: Data, to url: URL) throws
    func copyItem(at source: URL, to destination: URL) throws
    func moveItem(at source: URL, to destination: URL) throws
    func removeItem(at url: URL) throws
    func listDirectory(at url: URL) throws -> [URL]
}

public struct LocalFileSystem: FileSysteming {
    public init() {}

    public func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    public func createDirectory(at url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    public func readData(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    public func writeData(_ data: Data, to url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try createDirectory(at: directory)
        try data.write(to: url, options: .atomic)
    }

    public func copyItem(at source: URL, to destination: URL) throws {
        let directory = destination.deletingLastPathComponent()
        try createDirectory(at: directory)
        if fileExists(at: destination) {
            try removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: source, to: destination)
    }

    public func moveItem(at source: URL, to destination: URL) throws {
        let directory = destination.deletingLastPathComponent()
        try createDirectory(at: directory)
        if fileExists(at: destination) {
            try removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: source, to: destination)
    }

    public func removeItem(at url: URL) throws {
        if fileExists(at: url) {
            try FileManager.default.removeItem(at: url)
        }
    }

    public func listDirectory(at url: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    }
}

public final class InMemoryFileSystem: FileSysteming, @unchecked Sendable {
    private var files: [String: Data]
    private var directories: Set<String>
    private let lock = NSLock()

    public init(files: [String: Data] = [:], directories: Set<String> = []) {
        self.files = files
        self.directories = directories
    }

    public func fileExists(at url: URL) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return files[url.path] != nil || directories.contains(url.path)
    }

    public func createDirectory(at url: URL) throws {
        lock.lock()
        defer { lock.unlock() }
        directories.insert(url.path)
    }

    public func readData(at url: URL) throws -> Data {
        lock.lock()
        defer { lock.unlock() }
        guard let data = files[url.path] else {
            throw MoverError.ioFailure("No file at \(url.path)")
        }
        return data
    }

    public func writeData(_ data: Data, to url: URL) throws {
        lock.lock()
        defer { lock.unlock() }
        directories.insert(url.deletingLastPathComponent().path)
        files[url.path] = data
    }

    public func copyItem(at source: URL, to destination: URL) throws {
        lock.lock()
        defer { lock.unlock() }
        guard let data = files[source.path] else {
            throw MoverError.ioFailure("No source file at \(source.path)")
        }
        files[destination.path] = data
        directories.insert(destination.deletingLastPathComponent().path)
    }

    public func moveItem(at source: URL, to destination: URL) throws {
        lock.lock()
        defer { lock.unlock() }
        guard let data = files[source.path] else {
            throw MoverError.ioFailure("No source file at \(source.path)")
        }
        files.removeValue(forKey: source.path)
        files[destination.path] = data
        directories.insert(destination.deletingLastPathComponent().path)
    }

    public func removeItem(at url: URL) throws {
        lock.lock()
        defer { lock.unlock() }
        files.removeValue(forKey: url.path)
        directories.remove(url.path)
    }

    public func listDirectory(at url: URL) throws -> [URL] {
        lock.lock()
        defer { lock.unlock() }
        let prefix = url.path.hasSuffix("/") ? url.path : url.path + "/"
        let children = Set(files.keys.compactMap { path -> URL? in
            guard path.hasPrefix(prefix) else { return nil }
            let remainder = String(path.dropFirst(prefix.count))
            guard !remainder.isEmpty else { return nil }
            let first = remainder.split(separator: "/").first ?? ""
            return URL(fileURLWithPath: prefix + first)
        })
        return Array(children)
    }

    public func snapshotFiles() -> [String: Data] {
        lock.lock()
        defer { lock.unlock() }
        return files
    }
}
