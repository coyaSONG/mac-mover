import Foundation

public enum SchemaVersion: String, Codable, Sendable {
    case v1_0_0 = "1.0.0"
}

public enum MachineArchitecture: String, Codable, Sendable {
    case arm64
    case x86_64
}

public enum ItemKind: String, Codable, CaseIterable, Sendable {
    case brewFormula = "brew_formula"
    case brewCask = "brew_cask"
    case brewTap = "brew_tap"
    case brewService = "brew_service"
    case dotfile = "dotfile"
    case gitGlobal = "git_global"
    case vscodeExtension = "vscode_extension"
    case vscodeSettings = "vscode_settings"
    case manualNote = "manual_note"
}

public enum RestorePhase: String, Codable, CaseIterable, Comparable, Sendable {
    case preflight
    case bootstrap
    case packages
    case config
    case ide
    case manual
    case verify

    public static func < (lhs: RestorePhase, rhs: RestorePhase) -> Bool {
        lhs.order < rhs.order
    }

    public var order: Int {
        switch self {
        case .preflight: return 0
        case .bootstrap: return 1
        case .packages: return 2
        case .config: return 3
        case .ide: return 4
        case .manual: return 5
        case .verify: return 6
        }
    }
}

public enum ItemRisk: String, Codable, Sendable {
    case low
    case medium
    case high
}

public struct ItemSource: Codable, Hashable, Sendable {
    public var path: String?
    public var command: String?
    public var details: [String: JSONValue]

    public init(path: String? = nil, command: String? = nil, details: [String: JSONValue] = [:]) {
        self.path = path
        self.command = command
        self.details = details
    }

    enum CodingKeys: String, CodingKey {
        case path
        case command
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var path: String?
        var command: String?
        var details: [String: JSONValue] = [:]

        for key in container.allKeys {
            switch key.stringValue {
            case CodingKeys.path.rawValue:
                path = try container.decode(String.self, forKey: key)
            case CodingKeys.command.rawValue:
                command = try container.decode(String.self, forKey: key)
            default:
                details[key.stringValue] = try container.decode(JSONValue.self, forKey: key)
            }
        }

        self.path = path
        self.command = command
        self.details = details
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        if let path {
            try container.encode(path, forKey: DynamicCodingKey(stringValue: CodingKeys.path.rawValue)!)
        }
        if let command {
            try container.encode(command, forKey: DynamicCodingKey(stringValue: CodingKeys.command.rawValue)!)
        }
        for (key, value) in details {
            try container.encode(value, forKey: DynamicCodingKey(stringValue: key)!)
        }
    }
}

public struct VerifySpec: Codable, Hashable, Sendable {
    public var command: String?
    public var expectedFile: String?
    public var expectedValue: JSONValue?

    public init(command: String? = nil, expectedFile: String? = nil, expectedValue: JSONValue? = nil) {
        self.command = command
        self.expectedFile = expectedFile
        self.expectedValue = expectedValue
    }
}

public struct ManifestItem: Codable, Hashable, Sendable {
    public var id: String
    public var kind: ItemKind
    public var title: String
    public var restorePhase: RestorePhase
    public var source: ItemSource?
    public var payload: [String: JSONValue]
    public var secret: Bool
    public var risk: ItemRisk?
    public var verify: VerifySpec?
    public var notes: [String]

    public init(
        id: String,
        kind: ItemKind,
        title: String,
        restorePhase: RestorePhase,
        source: ItemSource? = nil,
        payload: [String: JSONValue],
        secret: Bool,
        risk: ItemRisk? = nil,
        verify: VerifySpec? = nil,
        notes: [String] = []
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.restorePhase = restorePhase
        self.source = source
        self.payload = payload
        self.secret = secret
        self.risk = risk
        self.verify = verify
        self.notes = notes
    }
}

public struct RestoreStep: Codable, Hashable, Sendable {
    public var phase: RestorePhase
    public var itemIds: [String]

    public init(phase: RestorePhase, itemIds: [String]) {
        self.phase = phase
        self.itemIds = itemIds
    }
}

public struct ManualTask: Codable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var reason: String
    public var action: String
    public var blocking: Bool

    public init(id: String, title: String, reason: String, action: String, blocking: Bool = false) {
        self.id = id
        self.title = title
        self.reason = reason
        self.action = action
        self.blocking = blocking
    }
}

public struct MachineInfo: Codable, Hashable, Sendable {
    public var hostname: String
    public var architecture: MachineArchitecture
    public var macosVersion: String
    public var homeDirectory: String
    public var homebrewPrefix: String
    public var userName: String?

    public init(
        hostname: String,
        architecture: MachineArchitecture,
        macosVersion: String,
        homeDirectory: String,
        homebrewPrefix: String,
        userName: String? = nil
    ) {
        self.hostname = hostname
        self.architecture = architecture
        self.macosVersion = macosVersion
        self.homeDirectory = homeDirectory
        self.homebrewPrefix = homebrewPrefix
        self.userName = userName
    }
}

public struct ManifestReports: Codable, Hashable, Sendable {
    public var exportSummaryPath: String
    public var verifySummaryPath: String?
    public var warnings: [String]

    public init(exportSummaryPath: String, verifySummaryPath: String? = nil, warnings: [String] = []) {
        self.exportSummaryPath = exportSummaryPath
        self.verifySummaryPath = verifySummaryPath
        self.warnings = warnings
    }
}

public struct Manifest: Codable, Hashable, Sendable {
    public var schemaVersion: SchemaVersion
    public var exportedAt: Date
    public var machine: MachineInfo
    public var items: [ManifestItem]
    public var restorePlan: [RestoreStep]
    public var manualTasks: [ManualTask]
    public var reports: ManifestReports

    public init(
        schemaVersion: SchemaVersion = .v1_0_0,
        exportedAt: Date,
        machine: MachineInfo,
        items: [ManifestItem],
        restorePlan: [RestoreStep],
        manualTasks: [ManualTask] = [],
        reports: ManifestReports
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.machine = machine
        self.items = items
        self.restorePlan = restorePlan
        self.manualTasks = manualTasks
        self.reports = reports
    }
}

private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
