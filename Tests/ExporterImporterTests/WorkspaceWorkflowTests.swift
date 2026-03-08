import Foundation
import Testing
@testable import Localization
@testable import SharedModels
@testable import Core
@testable import Exporters
@testable import Importers

struct WorkspaceWorkflowTests {
    @Test
    func applyCreatesBackupBeforeOverwritingDotfile() throws {
        let homeDirectory = "/Users/test"
        let workspaceRoot = URL(fileURLWithPath: "/tmp/dev-env-repo")
        let localDotfile = URL(fileURLWithPath: "\(homeDirectory)/.zshrc")
        let timestamp = Date(timeIntervalSince1970: 1_735_872_123)
        let fileSystem = InMemoryFileSystem(
            files: [
                workspaceRoot.appendingPathComponent(".zshrc").path: Data("export PATH=/opt/homebrew/bin:$PATH\n".utf8),
                localDotfile.path: Data("export PATH=/usr/bin:$PATH\n".utf8)
            ],
            directories: [
                workspaceRoot.path,
                homeDirectory
            ]
        )
        let workspace = ConnectedWorkspace(rootPath: workspaceRoot.path, detectedTools: [.plainDotfiles])
        let snapshot = RepoSnapshot(items: [
            WorkspaceItem(
                category: .dotfiles,
                identifier: "~/.zshrc",
                value: .string("repo-hash"),
                details: ["relativePath": .string(".zshrc")]
            )
        ])
        let selection = DriftItem(
            category: .dotfiles,
            identifier: "~/.zshrc",
            repoValue: .string("repo-hash"),
            localValue: .string("local-hash"),
            status: .modified,
            suggestedResolutions: [.apply]
        )

        let result = try WorkspaceApplyCoordinator(
            fileSystem: fileSystem,
            fileRestorer: FileRestorer(fileSystem: fileSystem),
            manualTaskEngine: ManualTaskEngine()
        ).apply(
            workspace: workspace,
            repoSnapshot: snapshot,
            selections: [selection],
            homeDirectory: homeDirectory,
            timestamp: timestamp
        )

        let restoredData = try fileSystem.readData(at: localDotfile)
        let backupURL = BackupNamer.backupURL(for: localDotfile, timestamp: timestamp)

        #expect(String(data: restoredData, encoding: .utf8) == "export PATH=/opt/homebrew/bin:$PATH\n")
        #expect(fileSystem.fileExists(at: backupURL))
        #expect(result.backupURLs == [backupURL])
        #expect(result.report.successes.count == 1)
        #expect(result.report.manualTasks.contains(where: { $0.id.contains("manual.overwrite") }))
    }

    @Test
    func applySkipsSecretDotfilesAndCreatesManualTask() throws {
        let homeDirectory = "/Users/test"
        let workspaceRoot = URL(fileURLWithPath: "/tmp/dev-env-repo")
        let fileSystem = InMemoryFileSystem(
            files: [
                workspaceRoot.appendingPathComponent(".ssh/id_ed25519").path: Data("secret".utf8)
            ],
            directories: [
                workspaceRoot.path,
                workspaceRoot.appendingPathComponent(".ssh").path,
                homeDirectory
            ]
        )
        let workspace = ConnectedWorkspace(rootPath: workspaceRoot.path, detectedTools: [.plainDotfiles])
        let snapshot = RepoSnapshot(items: [
            WorkspaceItem(
                category: .dotfiles,
                identifier: "~/.ssh/id_ed25519",
                value: .string("secret-hash"),
                details: ["relativePath": .string(".ssh/id_ed25519")]
            )
        ])
        let selection = DriftItem(
            category: .dotfiles,
            identifier: "~/.ssh/id_ed25519",
            repoValue: .string("secret-hash"),
            localValue: nil,
            status: .missing,
            suggestedResolutions: [.apply]
        )

        let result = try WorkspaceApplyCoordinator(
            fileSystem: fileSystem,
            fileRestorer: FileRestorer(fileSystem: fileSystem),
            manualTaskEngine: ManualTaskEngine()
        ).apply(
            workspace: workspace,
            repoSnapshot: snapshot,
            selections: [selection],
            homeDirectory: homeDirectory
        )

        let destinationURL = URL(fileURLWithPath: "\(homeDirectory)/.ssh/id_ed25519")

        #expect(!fileSystem.fileExists(at: destinationURL))
        #expect(result.report.successes.isEmpty)
        #expect(result.report.skipped.count == 1)
        #expect(result.report.manualTasks.contains(where: { $0.id.contains("manual.secret") }))
    }

    @Test
    func applyRestoresNestedDotfilePaths() throws {
        let homeDirectory = "/Users/test"
        let workspaceRoot = URL(fileURLWithPath: "/tmp/dev-env-repo")
        let nestedLocalDotfile = URL(fileURLWithPath: "\(homeDirectory)/.config/starship.toml")
        let fileSystem = InMemoryFileSystem(
            files: [
                workspaceRoot.appendingPathComponent(".config/starship.toml").path: Data("[character]\nsuccess_symbol = \"[➜](bold green)\"\n".utf8)
            ],
            directories: [
                workspaceRoot.path,
                workspaceRoot.appendingPathComponent(".config").path,
                homeDirectory
            ]
        )
        let workspace = ConnectedWorkspace(rootPath: workspaceRoot.path, detectedTools: [.plainDotfiles])
        let snapshot = RepoSnapshot(items: [
            WorkspaceItem(
                category: .dotfiles,
                identifier: "~/.config/starship.toml",
                value: .string("repo-hash"),
                details: ["relativePath": .string(".config/starship.toml")]
            )
        ])
        let selection = DriftItem(
            category: .dotfiles,
            identifier: "~/.config/starship.toml",
            repoValue: .string("repo-hash"),
            localValue: nil,
            status: .missing,
            suggestedResolutions: [.apply]
        )

        let result = try WorkspaceApplyCoordinator(
            fileSystem: fileSystem,
            fileRestorer: FileRestorer(fileSystem: fileSystem),
            manualTaskEngine: ManualTaskEngine()
        ).apply(
            workspace: workspace,
            repoSnapshot: snapshot,
            selections: [selection],
            homeDirectory: homeDirectory
        )

        let restoredData = try fileSystem.readData(at: nestedLocalDotfile)

        #expect(fileSystem.fileExists(at: URL(fileURLWithPath: "\(homeDirectory)/.config")))
        #expect(String(data: restoredData, encoding: .utf8) == "[character]\nsuccess_symbol = \"[➜](bold green)\"\n")
        #expect(result.report.successes.count == 1)
    }

    @Test
    func promoteStagesDotfileCandidatesWithoutWritingIntoWorkspace() throws {
        let homeDirectory = "/Users/test"
        let workspaceRoot = URL(fileURLWithPath: "/tmp/dev-env-repo")
        let stagingRoot = URL(fileURLWithPath: "/tmp/dev-env-staging")
        let localDotfile = URL(fileURLWithPath: "\(homeDirectory)/.zshrc")
        let fileSystem = InMemoryFileSystem(
            files: [
                localDotfile.path: Data("set -o vi\n".utf8)
            ],
            directories: [
                workspaceRoot.path,
                stagingRoot.path,
                homeDirectory
            ]
        )
        let workspace = ConnectedWorkspace(rootPath: workspaceRoot.path, detectedTools: [.plainDotfiles])
        let environment = EnvironmentSnapshot(items: [
            WorkspaceItem(
                category: .dotfiles,
                identifier: "~/.zshrc",
                value: .string("local-hash"),
                details: ["path": .string("~/.zshrc")]
            )
        ])
        let selection = DriftItem(
            category: .dotfiles,
            identifier: "~/.zshrc",
            repoValue: nil,
            localValue: .string("local-hash"),
            status: .extra,
            suggestedResolutions: [.promote]
        )

        let result = try WorkspacePromoteCoordinator(
            fileSystem: fileSystem,
            manualTaskEngine: ManualTaskEngine()
        ).promote(
            workspace: workspace,
            environmentSnapshot: environment,
            selections: [selection],
            homeDirectory: homeDirectory,
            stagingRoot: stagingRoot
        )

        let stagedURL = stagingRoot.appendingPathComponent(".zshrc")
        let stagedData = try fileSystem.readData(at: stagedURL)

        #expect(fileSystem.fileExists(at: stagedURL))
        #expect(String(data: stagedData, encoding: .utf8) == "set -o vi\n")
        #expect(!fileSystem.fileExists(at: workspaceRoot.appendingPathComponent(".zshrc")))
        #expect(result.stagedFiles == [stagedURL])
        #expect(result.report.successes.count == 1)
    }

    @Test
    func promoteStagesNestedDotfileCandidatesForPlainWorkspace() throws {
        let homeDirectory = "/Users/test"
        let workspaceRoot = URL(fileURLWithPath: "/tmp/dev-env-repo")
        let stagingRoot = URL(fileURLWithPath: "/tmp/dev-env-staging")
        let localDotfile = URL(fileURLWithPath: "\(homeDirectory)/.config/starship.toml")
        let fileSystem = InMemoryFileSystem(
            files: [
                localDotfile.path: Data("[character]\n".utf8)
            ],
            directories: [
                workspaceRoot.path,
                stagingRoot.path,
                homeDirectory
            ]
        )
        let workspace = ConnectedWorkspace(rootPath: workspaceRoot.path, detectedTools: [.plainDotfiles])
        let environment = EnvironmentSnapshot(items: [
            WorkspaceItem(
                category: .dotfiles,
                identifier: "~/.config/starship.toml",
                value: .string("local-hash"),
                details: ["path": .string("~/.config/starship.toml")]
            )
        ])
        let selection = DriftItem(
            category: .dotfiles,
            identifier: "~/.config/starship.toml",
            repoValue: nil,
            localValue: .string("local-hash"),
            status: .extra,
            suggestedResolutions: [.promote]
        )

        let result = try WorkspacePromoteCoordinator(
            fileSystem: fileSystem,
            manualTaskEngine: ManualTaskEngine()
        ).promote(
            workspace: workspace,
            environmentSnapshot: environment,
            selections: [selection],
            homeDirectory: homeDirectory,
            stagingRoot: stagingRoot
        )

        let stagedURL = stagingRoot.appendingPathComponent(".config/starship.toml")
        let stagedData = try fileSystem.readData(at: stagedURL)

        #expect(fileSystem.fileExists(at: stagingRoot.appendingPathComponent(".config")))
        #expect(String(data: stagedData, encoding: .utf8) == "[character]\n")
        #expect(result.stagedFiles == [stagedURL])
    }

    @Test
    func promoteStagesChezmoiCandidatesUsingDotNamingWhileSkippingSecrets() throws {
        let homeDirectory = "/Users/test"
        let workspaceRoot = URL(fileURLWithPath: "/tmp/dev-env-repo")
        let stagingRoot = URL(fileURLWithPath: "/tmp/dev-env-staging")
        let localConfig = URL(fileURLWithPath: "\(homeDirectory)/.config/starship.toml")
        let localNpmrc = URL(fileURLWithPath: "\(homeDirectory)/.npmrc")
        let fileSystem = InMemoryFileSystem(
            files: [
                localConfig.path: Data("[character]\n".utf8),
                localNpmrc.path: Data("//registry.npmjs.org/:_authToken=test\n".utf8)
            ],
            directories: [
                workspaceRoot.path,
                stagingRoot.path,
                homeDirectory
            ]
        )
        let workspace = ConnectedWorkspace(rootPath: workspaceRoot.path, detectedTools: [.chezmoi])
        let environment = EnvironmentSnapshot(items: [
            WorkspaceItem(category: .dotfiles, identifier: "~/.config/starship.toml", value: .string("cfg"), details: ["path": .string("~/.config/starship.toml")]),
            WorkspaceItem(category: .dotfiles, identifier: "~/.npmrc", value: .string("npm"), details: ["path": .string("~/.npmrc")])
        ])
        let selections = [
            DriftItem(category: .dotfiles, identifier: "~/.config/starship.toml", repoValue: nil, localValue: .string("cfg"), status: .extra, suggestedResolutions: [.promote]),
            DriftItem(category: .dotfiles, identifier: "~/.npmrc", repoValue: nil, localValue: .string("npm"), status: .extra, suggestedResolutions: [.promote])
        ]

        let result = try WorkspacePromoteCoordinator(
            fileSystem: fileSystem,
            manualTaskEngine: ManualTaskEngine()
        ).promote(
            workspace: workspace,
            environmentSnapshot: environment,
            selections: selections,
            homeDirectory: homeDirectory,
            stagingRoot: stagingRoot
        )

        let stagedConfig = stagingRoot.appendingPathComponent("dot_config/starship.toml")
        let stagedNpmrc = stagingRoot.appendingPathComponent("private_dot_npmrc")

        #expect(fileSystem.fileExists(at: stagedConfig))
        #expect(result.stagedFiles.contains(stagedConfig))
        #expect(!fileSystem.fileExists(at: stagedNpmrc))
        #expect(!result.stagedFiles.contains(stagedNpmrc))
        #expect(result.report.skipped.contains(where: { $0.id.contains("workspace.promote.~/.npmrc") }))
        #expect(result.report.manualTasks.contains(where: { $0.id.contains("manual.secret") && $0.reason.contains(".npmrc") }))
    }

    @Test
    func workspaceApplyAndPromoteCanRenderKoreanReports() throws {
        let homeDirectory = "/Users/test"
        let workspaceRoot = URL(fileURLWithPath: "/tmp/dev-env-repo")
        let stagingRoot = URL(fileURLWithPath: "/tmp/dev-env-staging")
        let localDotfile = URL(fileURLWithPath: "\(homeDirectory)/.zshrc")
        let locale = Locale(identifier: "ko")
        let fileSystem = InMemoryFileSystem(
            files: [
                workspaceRoot.appendingPathComponent(".zshrc").path: Data("repo-value\n".utf8),
                localDotfile.path: Data("local-value\n".utf8)
            ],
            directories: [
                workspaceRoot.path,
                stagingRoot.path,
                homeDirectory
            ]
        )
        let workspace = ConnectedWorkspace(rootPath: workspaceRoot.path, detectedTools: [.plainDotfiles])
        let repoSnapshot = RepoSnapshot(items: [
            WorkspaceItem(
                category: .dotfiles,
                identifier: "~/.zshrc",
                value: .string("repo-hash"),
                details: ["relativePath": .string(".zshrc")]
            )
        ])
        let environmentSnapshot = EnvironmentSnapshot(items: [
            WorkspaceItem(
                category: .dotfiles,
                identifier: "~/.zshrc",
                value: .string("local-hash"),
                details: ["path": .string("~/.zshrc")]
            )
        ])
        let selection = DriftItem(
            category: .dotfiles,
            identifier: "~/.zshrc",
            repoValue: .string("repo-hash"),
            localValue: .string("local-hash"),
            status: .modified,
            suggestedResolutions: [.apply, .promote]
        )

        let applyResult = try WorkspaceApplyCoordinator(
            fileSystem: fileSystem,
            fileRestorer: FileRestorer(fileSystem: fileSystem),
            manualTaskEngine: ManualTaskEngine(locale: locale),
            locale: locale
        ).apply(
            workspace: workspace,
            repoSnapshot: repoSnapshot,
            selections: [selection],
            homeDirectory: homeDirectory
        )
        let promoteResult = try WorkspacePromoteCoordinator(
            fileSystem: fileSystem,
            manualTaskEngine: ManualTaskEngine(locale: locale),
            locale: locale
        ).promote(
            workspace: workspace,
            environmentSnapshot: environmentSnapshot,
            selections: [selection],
            homeDirectory: homeDirectory,
            stagingRoot: stagingRoot
        )

        #expect(applyResult.report.title == "워크스페이스 적용 요약")
        #expect(applyResult.report.successes.first?.detail == "워크스페이스에서 적용됨")
        #expect(promoteResult.report.title == "워크스페이스 반영 요약")
        #expect(promoteResult.report.successes.first?.detail.contains("후보 파일 스테이징 완료") == true)
    }
}
