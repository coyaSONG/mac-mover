import Foundation

public final class StructuredLogger: @unchecked Sendable {
    public enum Level: String, Sendable {
        case debug
        case info
        case warning
        case error
    }

    private let fileURL: URL
    private let dateFormatter: ISO8601DateFormatter
    private let lock = NSLock()

    public init(fileURL: URL) {
        self.fileURL = fileURL
        self.dateFormatter = ISO8601DateFormatter()
        self.dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    public func log(_ level: Level, message: String, context: [String: String] = [:]) {
        lock.lock()
        defer { lock.unlock() }
        var line: [String: String] = [
            "timestamp": dateFormatter.string(from: Date()),
            "level": level.rawValue,
            "message": message
        ]
        for (key, value) in context {
            line[key] = value
        }

        guard let data = try? JSONSerialization.data(withJSONObject: line, options: []),
              let string = String(data: data, encoding: .utf8) else {
            return
        }

        let final = string + "\n"
        if FileManager.default.fileExists(atPath: fileURL.path),
           let handle = try? FileHandle(forWritingTo: fileURL),
           let encoded = final.data(using: .utf8) {
            defer { try? handle.close() }
            do {
                try handle.seekToEnd()
                try handle.write(contentsOf: encoded)
            } catch {
                // Logging should never crash workflows.
            }
        } else {
            try? final.data(using: .utf8)?.write(to: fileURL, options: .atomic)
        }
    }
}
