import Foundation

public enum WorkspaceTool: String, Codable, CaseIterable, Sendable {
    case homebrew
    case chezmoi
    case plainDotfiles = "plain_dotfiles"
    case git
    case vscode
    case mise
    case asdf
}

public enum WorkspaceItemCategory: String, Codable, CaseIterable, Sendable {
    case homebrew
    case dotfiles
    case gitGlobal = "git_global"
    case vscode
    case toolVersions = "tool_versions"
    case manual
}

public struct WorkspaceItem: Codable, Hashable, Sendable {
    public var category: WorkspaceItemCategory
    public var identifier: String
    public var value: JSONValue?
    public var details: [String: JSONValue]

    public init(
        category: WorkspaceItemCategory,
        identifier: String,
        value: JSONValue? = nil,
        details: [String: JSONValue] = [:]
    ) {
        self.category = category
        self.identifier = identifier
        self.value = value
        self.details = details
    }
}

public struct ConnectedWorkspace: Codable, Hashable, Sendable {
    public var rootPath: String
    public var repoURL: String?
    public var detectedTools: [WorkspaceTool]
    public var lastScannedAt: Date?

    public init(
        rootPath: String,
        repoURL: String? = nil,
        detectedTools: [WorkspaceTool] = [],
        lastScannedAt: Date? = nil
    ) {
        self.rootPath = rootPath
        self.repoURL = repoURL
        self.detectedTools = detectedTools
        self.lastScannedAt = lastScannedAt
    }
}

public struct RepoSnapshot: Codable, Hashable, Sendable {
    public var capturedAt: Date?
    public var items: [WorkspaceItem]

    public init(capturedAt: Date? = nil, items: [WorkspaceItem] = []) {
        self.capturedAt = capturedAt
        self.items = items
    }
}

public struct EnvironmentSnapshot: Codable, Hashable, Sendable {
    public var capturedAt: Date?
    public var items: [WorkspaceItem]

    public init(capturedAt: Date? = nil, items: [WorkspaceItem] = []) {
        self.capturedAt = capturedAt
        self.items = items
    }
}

public enum DriftStatus: String, Codable, CaseIterable, Sendable {
    case missing
    case extra
    case modified
    case manual
    case unsupported
}

public enum DriftResolution: String, Codable, CaseIterable, Sendable {
    case apply
    case promote
    case ignore
}

public struct DriftItem: Codable, Hashable, Sendable {
    public var category: WorkspaceItemCategory
    public var identifier: String
    public var repoValue: JSONValue?
    public var localValue: JSONValue?
    public var status: DriftStatus
    public var suggestedResolutions: [DriftResolution]

    public init(
        category: WorkspaceItemCategory,
        identifier: String,
        repoValue: JSONValue? = nil,
        localValue: JSONValue? = nil,
        status: DriftStatus,
        suggestedResolutions: [DriftResolution] = []
    ) {
        self.category = category
        self.identifier = identifier
        self.repoValue = repoValue
        self.localValue = localValue
        self.status = status
        self.suggestedResolutions = suggestedResolutions
    }
}
