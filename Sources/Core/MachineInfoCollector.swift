import Foundation
import SharedModels

public struct MachineInfoCollector {
    private let runner: CommandRunning

    public init(runner: CommandRunning = ProcessCommandRunner()) {
        self.runner = runner
    }

    public func collect() -> MachineInfo {
        let hostname = trimmedOutput(executable: "/bin/hostname", arguments: [])
            ?? Host.current().localizedName
            ?? "unknown-host"

        let archRaw = trimmedOutput(executable: "/usr/bin/uname", arguments: ["-m"]) ?? "arm64"
        let architecture: MachineArchitecture = archRaw == "x86_64" ? .x86_64 : .arm64

        let macosVersion = trimmedOutput(executable: "/usr/bin/sw_vers", arguments: ["-productVersion"])
            ?? ProcessInfo.processInfo.operatingSystemVersionString

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let brewPrefix: String

        if runner.commandExists("brew"),
           let prefix = trimmedOutput(executable: "/usr/bin/env", arguments: ["brew", "--prefix"]),
           !prefix.isEmpty {
            brewPrefix = prefix
        } else {
            brewPrefix = architecture == .arm64 ? "/opt/homebrew" : "/usr/local"
        }

        return MachineInfo(
            hostname: hostname,
            architecture: architecture,
            macosVersion: macosVersion,
            homeDirectory: home,
            homebrewPrefix: brewPrefix,
            userName: ProcessInfo.processInfo.environment["USER"]
        )
    }

    private func trimmedOutput(executable: String, arguments: [String]) -> String? {
        guard let result = try? runner.run(executable: executable, arguments: arguments) else {
            return nil
        }
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
