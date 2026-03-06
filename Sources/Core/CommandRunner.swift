import Foundation

public struct CommandResult: Sendable {
    public let executable: String
    public let arguments: [String]
    public let exitCode: Int32
    public let stdout: String
    public let stderr: String

    public init(executable: String, arguments: [String], exitCode: Int32, stdout: String, stderr: String) {
        self.executable = executable
        self.arguments = arguments
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
    }

    public var succeeded: Bool {
        exitCode == 0
    }
}

public protocol CommandRunning: Sendable {
    func run(
        executable: String,
        arguments: [String],
        currentDirectory: URL?,
        environment: [String: String]?
    ) throws -> CommandResult
}

public extension CommandRunning {
    func run(executable: String, arguments: [String]) throws -> CommandResult {
        try run(executable: executable, arguments: arguments, currentDirectory: nil, environment: nil)
    }

    func commandExists(_ command: String) -> Bool {
        guard let result = try? run(executable: "/usr/bin/env", arguments: ["which", command]) else {
            return false
        }
        return result.succeeded
    }
}

public struct ProcessCommandRunner: CommandRunning {
    public init() {}

    public func run(
        executable: String,
        arguments: [String],
        currentDirectory: URL? = nil,
        environment: [String: String]? = nil
    ) throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectory
        if let environment {
            process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""

        let result = CommandResult(
            executable: executable,
            arguments: arguments,
            exitCode: process.terminationStatus,
            stdout: stdout,
            stderr: stderr
        )

        if !result.succeeded {
            throw MoverError.commandFailed(
                executable: executable,
                arguments: arguments,
                code: result.exitCode,
                stderr: result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        return result
    }
}

public final class MockCommandRunner: CommandRunning, @unchecked Sendable {
    public struct Stub: Sendable {
        public var executable: String
        public var arguments: [String]
        public var result: Result<CommandResult, Error>

        public init(executable: String, arguments: [String], result: Result<CommandResult, Error>) {
            self.executable = executable
            self.arguments = arguments
            self.result = result
        }
    }

    private var stubs: [Stub]
    private(set) public var history: [(String, [String])]
    private let lock = NSLock()

    public init(stubs: [Stub] = []) {
        self.stubs = stubs
        self.history = []
    }

    public func append(_ stub: Stub) {
        lock.lock()
        defer { lock.unlock() }
        stubs.append(stub)
    }

    public func run(
        executable: String,
        arguments: [String],
        currentDirectory: URL?,
        environment: [String: String]?
    ) throws -> CommandResult {
        lock.lock()
        defer { lock.unlock() }
        history.append((executable, arguments))
        guard let index = stubs.firstIndex(where: { $0.executable == executable && $0.arguments == arguments }) else {
            throw MoverError.commandFailed(executable: executable, arguments: arguments, code: 127, stderr: "No stub")
        }
        let stub = stubs.remove(at: index)
        return try stub.result.get()
    }
}
