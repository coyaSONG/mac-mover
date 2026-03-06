import Foundation

public struct PathNormalizer {
    public static func expandTilde(_ path: String, homeDirectory: String = FileManager.default.homeDirectoryForCurrentUser.path) -> String {
        guard path.hasPrefix("~/") else { return path }
        return homeDirectory + "/" + path.dropFirst(2)
    }

    public static func collapseHome(_ absolutePath: String, homeDirectory: String = FileManager.default.homeDirectoryForCurrentUser.path) -> String {
        guard absolutePath.hasPrefix(homeDirectory + "/") else { return absolutePath }
        return "~/" + absolutePath.dropFirst(homeDirectory.count + 1)
    }

    public static func normalizedDotfileRelativePath(_ path: String, homeDirectory: String = FileManager.default.homeDirectoryForCurrentUser.path) -> String {
        let absolute = expandTilde(path, homeDirectory: homeDirectory)
        guard absolute.hasPrefix(homeDirectory + "/") else {
            return path.replacingOccurrences(of: "//", with: "/")
        }
        return String(absolute.dropFirst(homeDirectory.count + 1))
    }
}

public struct BackupNamer {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    public static func backupURL(for fileURL: URL, timestamp: Date = Date()) -> URL {
        let suffix = ".bak.\(formatter.string(from: timestamp))"
        return URL(fileURLWithPath: fileURL.path + suffix)
    }
}
