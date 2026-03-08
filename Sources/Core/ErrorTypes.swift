import Foundation
import Localization

public enum MoverError: Error, LocalizedError, Sendable {
    case commandFailed(executable: String, arguments: [String], code: Int32, stderr: String)
    case missingRequiredFile(String)
    case invalidManifest(String)
    case invalidWorkspace(String)
    case unsupportedSchemaVersion(String)
    case blockedByPreflight(String)
    case ioFailure(String)

    public var errorDescription: String? {
        switch self {
        case .commandFailed(let executable, let arguments, let code, let stderr):
            return L10n.format(.errorCommandFailed, executable, arguments.joined(separator: " "), code, stderr)
        case .missingRequiredFile(let path):
            return L10n.format(.errorMissingRequiredFile, path)
        case .invalidManifest(let reason):
            return L10n.format(.errorInvalidManifest, reason)
        case .invalidWorkspace(let reason):
            return L10n.format(.errorInvalidWorkspace, reason)
        case .unsupportedSchemaVersion(let version):
            return L10n.format(.errorUnsupportedSchemaVersion, version)
        case .blockedByPreflight(let reason):
            return L10n.format(.errorBlockedByPreflight, reason)
        case .ioFailure(let reason):
            return L10n.format(.errorIOFailure, reason)
        }
    }
}
