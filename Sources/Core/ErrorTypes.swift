import Foundation

public enum MoverError: Error, LocalizedError, Sendable {
    case commandFailed(executable: String, arguments: [String], code: Int32, stderr: String)
    case missingRequiredFile(String)
    case invalidManifest(String)
    case unsupportedSchemaVersion(String)
    case blockedByPreflight(String)
    case ioFailure(String)

    public var errorDescription: String? {
        switch self {
        case .commandFailed(let executable, let arguments, let code, let stderr):
            return "Command failed: \(executable) \(arguments.joined(separator: " ")) (\(code)) \(stderr)"
        case .missingRequiredFile(let path):
            return "Missing required file: \(path)"
        case .invalidManifest(let reason):
            return "Invalid manifest: \(reason)"
        case .unsupportedSchemaVersion(let version):
            return "Unsupported schema version: \(version)"
        case .blockedByPreflight(let reason):
            return "Preflight blocked execution: \(reason)"
        case .ioFailure(let reason):
            return "I/O failure: \(reason)"
        }
    }
}
