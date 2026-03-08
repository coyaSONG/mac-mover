import Foundation

public enum L10nKey: String, CaseIterable, Sendable {
    case appTitle = "app.title"
    case appTabOverview = "app.tab.overview"
    case appTabRepo = "app.tab.repo"
    case appTabDrift = "app.tab.drift"
    case appTabExport = "app.tab.export"
    case appTabImport = "app.tab.import"
    case appTabReports = "app.tab.reports"
    case actionBrowse = "action.browse"
    case actionScanWorkspace = "action.scan_workspace"
    case actionSelect = "action.select"
    case overviewAppOverviewTitle = "overview.app_overview.title"
    case overviewAppOverviewDescription = "overview.app_overview.description"
    case overviewCurrentMachineTitle = "overview.current_machine.title"
    case overviewRecentRunsTitle = "overview.recent_runs.title"
    case overviewLegacyBundleWorkflowsTitle = "overview.legacy_bundle_workflows.title"
    case overviewNoWorkspaceConnected = "overview.no_workspace_connected"
    case overviewNoExportYet = "overview.no_export_yet"
    case overviewNoImportYet = "overview.no_import_yet"
    case overviewDriftItemsCount = "overview.drift_items.count"
    case labelHost = "label.host"
    case labelArchitecture = "label.architecture"
    case labelMacOS = "label.macos"
    case labelHome = "label.home"
    case labelBrewPrefix = "label.brew_prefix"
    case labelUnknown = "label.unknown"
    case repoConnectedWorkspaceTitle = "repo.connected_workspace.title"
    case repoWorkspacePathPlaceholder = "repo.workspace_path.placeholder"
    case repoWorkspaceScanSummaryTitle = "repo.workspace_scan_summary.title"
    case driftOverviewTitle = "drift.overview.title"
    case driftModified = "drift.modified"
    case driftMissing = "drift.missing"
    case driftExtra = "drift.extra"
    case driftManual = "drift.manual"
    case driftUnsupported = "drift.unsupported"
    case driftWorkspaceSummaryTitle = "drift.workspace_summary.title"
    case workspaceToolHomebrew = "workspace.tool.homebrew"
    case workspaceToolChezmoi = "workspace.tool.chezmoi"
    case workspaceToolPlainDotfiles = "workspace.tool.plain_dotfiles"
    case workspaceToolGit = "workspace.tool.git"
    case workspaceToolVSCode = "workspace.tool.vscode"
    case workspaceToolMise = "workspace.tool.mise"
    case workspaceToolAsdf = "workspace.tool.asdf"
    case workspaceCategoryHomebrew = "workspace.category.homebrew"
    case workspaceCategoryDotfiles = "workspace.category.dotfiles"
    case workspaceCategoryGitGlobal = "workspace.category.git_global"
    case workspaceCategoryVSCode = "workspace.category.vscode"
    case workspaceCategoryToolVersions = "workspace.category.tool_versions"
    case workspaceCategoryManual = "workspace.category.manual"
    case workspaceResolutionApply = "workspace.resolution.apply"
    case workspaceResolutionPromote = "workspace.resolution.promote"
    case workspaceResolutionIgnore = "workspace.resolution.ignore"
    case workspaceApplyPreviewTitle = "workspace.apply_preview.title"
    case workspacePromotePreviewTitle = "workspace.promote_preview.title"
    case workspacePreviewReadyItemsCount = "workspace.preview.ready_items.count"
    case reportsWorkspaceScanTitle = "reports.workspace_scan.title"
    case reportsWorkspaceDriftTitle = "reports.workspace_drift.title"
    case reportsLegacyExportTitle = "reports.legacy_export.title"
    case reportsLegacyImportTitle = "reports.legacy_import.title"
    case reportsLegacyVerifyTitle = "reports.legacy_verify.title"
    case reportsLogsTitle = "reports.logs.title"
    case reportPreflightTitle = "report.preflight.title"
    case reportExportSummaryTitle = "report.export_summary.title"
    case reportImportSummaryTitle = "report.import_summary.title"
    case reportVerifySummaryTitle = "report.verify_summary.title"
    case reportVerifyReportTitle = "report.verify_report.title"
    case reportWorkspaceApplySummaryTitle = "report.workspace_apply_summary.title"
    case reportWorkspacePromoteSummaryTitle = "report.workspace_promote_summary.title"
    case reportGeneratedAt = "report.generated_at"
    case reportChecksTitle = "report.checks.title"
    case reportSuccessTitle = "report.success.title"
    case reportFailedTitle = "report.failed.title"
    case reportSkippedTitle = "report.skipped.title"
    case reportWarningsTitle = "report.warnings.title"
    case reportManualFollowUpTitle = "report.manual_follow_up.title"
    case reportBlockingYes = "report.blocking.yes"
    case reportBlockingNo = "report.blocking.no"
    case reportReasonLabel = "report.reason.label"
    case reportActionLabel = "report.action.label"
    case reportWorkspaceRoot = "report.workspace_root"
    case reportDetectedTools = "report.detected_tools"
    case reportRepoItems = "report.repo_items"
    case reportLocalItems = "report.local_items"
    case reportRepoCategoriesTitle = "report.repo_categories.title"
    case reportLocalCategoriesTitle = "report.local_categories.title"
    case exportLegacyTitle = "export.legacy.title"
    case exportLegacyDescription = "export.legacy.description"
    case importLegacyTitle = "import.legacy.title"
    case importLegacyDescription = "import.legacy.description"
    case workspaceDetectedToolsCount = "workspace.detected_tools.count"
    case statusIdle = "status.idle"
    case statusWorkspaceScanRunning = "status.workspace_scan.running"
    case statusWorkspaceScanCompleted = "status.workspace_scan.completed"
    case statusWorkspaceScanCompletedWithDrift = "status.workspace_scan.completed_with_drift"
    case statusWorkspaceScanFailed = "status.workspace_scan.failed"
    case statusExportRunning = "status.export.running"
    case statusExportCompleted = "status.export.completed"
    case statusExportFailed = "status.export.failed"
    case statusImportBundleBlockingPreflight = "status.import_bundle.blocking_preflight"
    case statusImportBundleReady = "status.import_bundle.ready"
    case statusImportPreflightFailed = "status.import_preflight.failed"
    case statusSelectImportBundleFirst = "status.import.select_bundle_first"
    case statusImportRunning = "status.import.running"
    case statusImportCompleted = "status.import.completed"
    case statusImportFailed = "status.import.failed"
    case statusVerifyRunning = "status.verify.running"
    case statusVerifyBlockedByPreflight = "status.verify.blocked_by_preflight"
    case statusVerifyCompleted = "status.verify.completed"
    case statusVerifyCompletedWithFailures = "status.verify.completed_with_failures"
    case statusVerifyFailed = "status.verify.failed"
    case placeholderNoWorkspaceScanExecuted = "placeholder.no_workspace_scan_executed"
    case placeholderNoWorkspaceDriftComputed = "placeholder.no_workspace_drift_computed"
    case placeholderNoWorkspaceApplyPreview = "placeholder.no_workspace_apply_preview"
    case placeholderNoWorkspacePromotePreview = "placeholder.no_workspace_promote_preview"
    case placeholderNoExportExecuted = "placeholder.no_export_executed"
    case placeholderNoImportExecuted = "placeholder.no_import_executed"
    case placeholderNoVerifyExecuted = "placeholder.no_verify_executed"
    case placeholderNoLogs = "placeholder.no_logs"
    case placeholderNone = "placeholder.none"
    case machineSummaryFormat = "machine.summary.format"
    case manualTaskMissingBrewTitle = "manual_task.missing_brew.title"
    case manualTaskMissingBrewReason = "manual_task.missing_brew.reason"
    case manualTaskMissingBrewAction = "manual_task.missing_brew.action"
    case manualTaskMissingCodeCLITitle = "manual_task.missing_code_cli.title"
    case manualTaskMissingCodeCLIReason = "manual_task.missing_code_cli.reason"
    case manualTaskMissingCodeCLIAction = "manual_task.missing_code_cli.action"
    case manualTaskArchitectureMismatchTitle = "manual_task.architecture_mismatch.title"
    case manualTaskArchitectureMismatchReason = "manual_task.architecture_mismatch.reason"
    case manualTaskArchitectureMismatchAction = "manual_task.architecture_mismatch.action"
    case manualTaskExcludedSecretTitle = "manual_task.excluded_secret.title"
    case manualTaskExcludedSecretReason = "manual_task.excluded_secret.reason"
    case manualTaskExcludedSecretAction = "manual_task.excluded_secret.action"
    case manualTaskUnsupportedFileTitle = "manual_task.unsupported_file.title"
    case manualTaskUnsupportedFileReason = "manual_task.unsupported_file.reason"
    case manualTaskUnsupportedFileAction = "manual_task.unsupported_file.action"
    case manualTaskOverwriteConfirmationTitle = "manual_task.overwrite_confirmation.title"
    case manualTaskOverwriteConfirmationReason = "manual_task.overwrite_confirmation.reason"
    case manualTaskOverwriteConfirmationAction = "manual_task.overwrite_confirmation.action"
    case preflightMacOSTitle = "preflight.macos.title"
    case preflightArchitectureTitle = "preflight.architecture.title"
    case preflightHomeTitle = "preflight.home.title"
    case preflightBrewTitle = "preflight.brew.title"
    case preflightBrewCommandNotFound = "preflight.brew.command_not_found"
    case preflightBrewPrefixTitle = "preflight.brew_prefix.title"
    case preflightBrewPrefixFailed = "preflight.brew_prefix.failed"
    case preflightBrewPrefixUnavailable = "preflight.brew_prefix.unavailable"
    case preflightGitTitle = "preflight.git.title"
    case preflightGitAvailable = "preflight.git.available"
    case preflightGitCommandNotFound = "preflight.git.command_not_found"
    case preflightVSCodeTitle = "preflight.vscode.title"
    case preflightVSCodeAppNotFound = "preflight.vscode.app_not_found"
    case preflightCodeCLITitle = "preflight.code_cli.title"
    case preflightCodeCLIAvailable = "preflight.code_cli.available"
    case preflightCodeCLICommandNotFound = "preflight.code_cli.command_not_found"
    case preflightImportBundleExistsTitle = "preflight.import_bundle_exists.title"
    case preflightWriteTitle = "preflight.write.title"
    case preflightBlockingFailures = "preflight.blocking_failures"
    case exportHomebrewTitle = "export.homebrew.title"
    case exportBrewCommandNotFound = "export.brew.command_not_found"
    case exportBrewfileCreationFailedWarning = "export.brewfile_creation_failed.warning"
    case exportBrewFormulaTitle = "export.brew_formula.title"
    case exportBrewCaskTitle = "export.brew_cask.title"
    case exportBrewTapTitle = "export.brew_tap.title"
    case exportBrewServiceTitle = "export.brew_service.title"
    case exportGitGlobalTitle = "export.git_global.title"
    case exportGitCommandNotFound = "export.git.command_not_found"
    case exportGitReadFailed = "export.git.read_failed"
    case exportGitEntries = "export.git.entries"
    case exportExcludedBySecretPolicy = "export.excluded_by_secret_policy"
    case exportFileNotFound = "export.file_not_found"
    case exportOverwriteBackupNote = "export.overwrite_backup.note"
    case exportVSCodeSettingsTitle = "export.vscode.settings.title"
    case exportVSCodeKeybindingsTitle = "export.vscode.keybindings.title"
    case exportVSCodeSnippetsTitle = "export.vscode.snippets.title"
    case exportVSCodeExtensionsTitle = "export.vscode.extensions.title"
    case exportVSCodeSettingsExported = "export.vscode.settings.exported"
    case exportVSCodeSettingsNotFound = "export.vscode.settings.not_found"
    case exportVSCodeKeybindingsExported = "export.vscode.keybindings.exported"
    case exportVSCodeSnippetsFilesExported = "export.vscode.snippets.files_exported"
    case exportVSCodeCodeCLINotFound = "export.vscode.code_cli.not_found"
    case exportVSCodeExtensionsExported = "export.vscode.extensions.exported"
    case exportEmptyTitle = "export.empty.title"
    case exportEmptyMessage = "export.empty.message"
    case exportEmptyNote = "export.empty.note"
    case exportEmptyWarning = "export.empty.warning"
    case verifyPendingTitle = "verify.pending.title"
    case verifyPendingDetail = "verify.pending.detail"
    case importPackagesTitle = "import.packages.title"
    case importPackagesBrewMissing = "import.packages.brew_missing"
    case importBrewfileRestoreTitle = "import.brewfile_restore.title"
    case importBrewBundleApplied = "import.brew.bundle_applied"
    case importMissingSourceMetadata = "import.missing_source_metadata"
    case importRestored = "import.restored"
    case importRestoredWithBackup = "import.restored_with_backup"
    case importGitTitle = "import.git.title"
    case importGitBackupTitle = "import.git.backup.title"
    case importMissingKeyValuePayload = "import.missing_key_value_payload"
    case importGitConfigApplied = "import.git.config_applied"
    case importGitConfigAppliedWithBackup = "import.git.config_applied_with_backup"
    case importVSCodeExtensionsTitle = "import.vscode.extensions.title"
    case importMissingVSCodePayloadMetadata = "import.missing_vscode_payload_metadata"
    case importDirectoryRestored = "import.directory_restored"
    case importMissingExtensionIdentifier = "import.missing_extension_identifier"
    case importExtensionInstalled = "import.extension_installed"
    case importVerifyFailedWarning = "import.verify_failed.warning"
    case workspaceApplyUnsupportedCategory = "workspace.apply.unsupported_category"
    case workspaceApplySecretManualTransfer = "workspace.apply.secret_manual_transfer"
    case workspaceApplyMissingRepoMetadata = "workspace.apply.missing_repo_metadata"
    case workspaceApplyAppliedFromWorkspace = "workspace.apply.applied_from_workspace"
    case workspacePromoteUnsupportedCategory = "workspace.promote.unsupported_category"
    case workspacePromoteSecretManualTransfer = "workspace.promote.secret_manual_transfer"
    case workspacePromoteMissingLocalMetadata = "workspace.promote.missing_local_metadata"
    case workspacePromoteStagedCandidate = "workspace.promote.staged_candidate"
    case verifySpecNotProvided = "verify.spec_not_provided"
    case verifyFileExists = "verify.file_exists"
    case verifyFileMissing = "verify.file_missing"
    case verifyInvalidCommand = "verify.invalid_command"
    case verifyExpectedValueMatched = "verify.expected_value_matched"
    case verifyExpectedValueMismatch = "verify.expected_value_mismatch"
    case verifyCommandSucceeded = "verify.command_succeeded"
    case verifyUnsupportedSpec = "verify.unsupported_spec"
    case artifactNotFound = "artifact.not_found"
    case artifactUnreadable = "artifact.unreadable"
    case errorCommandFailed = "error.command_failed"
    case errorMissingRequiredFile = "error.missing_required_file"
    case errorInvalidManifest = "error.invalid_manifest"
    case errorInvalidWorkspace = "error.invalid_workspace"
    case errorUnsupportedSchemaVersion = "error.unsupported_schema_version"
    case errorBlockedByPreflight = "error.blocked_by_preflight"
    case errorIOFailure = "error.io_failure"

    fileprivate var fallback: String {
        switch self {
        case .appTitle:
            return "MacMover"
        case .appTabOverview:
            return "Overview"
        case .appTabRepo:
            return "Repo"
        case .appTabDrift:
            return "Drift"
        case .appTabExport:
            return "Export"
        case .appTabImport:
            return "Import"
        case .appTabReports:
            return "Reports"
        case .actionBrowse:
            return "Browse"
        case .actionScanWorkspace:
            return "Scan Workspace"
        case .actionSelect:
            return "Select"
        case .overviewAppOverviewTitle:
            return "App Overview"
        case .overviewAppOverviewDescription:
            return "Manage a local developer environment repo, compare it against the current Mac, and preview workspace drift before apply or promote actions."
        case .overviewCurrentMachineTitle:
            return "Current Machine"
        case .overviewRecentRunsTitle:
            return "Recent Runs"
        case .overviewLegacyBundleWorkflowsTitle:
            return "Legacy Bundle Workflows"
        case .overviewNoWorkspaceConnected:
            return "No workspace connected"
        case .overviewNoExportYet:
            return "No export yet"
        case .overviewNoImportYet:
            return "No import yet"
        case .overviewDriftItemsCount:
            return "%#@drift_items@"
        case .labelHost:
            return "Host"
        case .labelArchitecture:
            return "Architecture"
        case .labelMacOS:
            return "macOS"
        case .labelHome:
            return "Home"
        case .labelBrewPrefix:
            return "Brew Prefix"
        case .labelUnknown:
            return "Unknown"
        case .repoConnectedWorkspaceTitle:
            return "Connected Workspace"
        case .repoWorkspacePathPlaceholder:
            return "Workspace path"
        case .repoWorkspaceScanSummaryTitle:
            return "Workspace Scan Summary"
        case .driftOverviewTitle:
            return "Drift Overview"
        case .driftModified:
            return "Modified"
        case .driftMissing:
            return "Missing"
        case .driftExtra:
            return "Extra"
        case .driftManual:
            return "Manual"
        case .driftUnsupported:
            return "Unsupported"
        case .driftWorkspaceSummaryTitle:
            return "Workspace Drift Summary"
        case .workspaceToolHomebrew:
            return "Homebrew"
        case .workspaceToolChezmoi:
            return "chezmoi"
        case .workspaceToolPlainDotfiles:
            return "Plain Dotfiles"
        case .workspaceToolGit:
            return "Git"
        case .workspaceToolVSCode:
            return "VS Code"
        case .workspaceToolMise:
            return "mise"
        case .workspaceToolAsdf:
            return "asdf"
        case .workspaceCategoryHomebrew:
            return "Homebrew"
        case .workspaceCategoryDotfiles:
            return "Dotfiles"
        case .workspaceCategoryGitGlobal:
            return "Git Global"
        case .workspaceCategoryVSCode:
            return "VS Code"
        case .workspaceCategoryToolVersions:
            return "Tool Versions"
        case .workspaceCategoryManual:
            return "Manual"
        case .workspaceResolutionApply:
            return "Apply"
        case .workspaceResolutionPromote:
            return "Promote"
        case .workspaceResolutionIgnore:
            return "Ignore"
        case .workspaceApplyPreviewTitle:
            return "Workspace Apply Preview"
        case .workspacePromotePreviewTitle:
            return "Workspace Promote Preview"
        case .workspacePreviewReadyItemsCount:
            return "Ready items: %ld"
        case .reportsWorkspaceScanTitle:
            return "Workspace Scan"
        case .reportsWorkspaceDriftTitle:
            return "Workspace Drift"
        case .reportsLegacyExportTitle:
            return "Legacy Export Report"
        case .reportsLegacyImportTitle:
            return "Legacy Import Report"
        case .reportsLegacyVerifyTitle:
            return "Legacy Verify Report"
        case .reportsLogsTitle:
            return "Logs"
        case .reportPreflightTitle:
            return "Preflight"
        case .reportExportSummaryTitle:
            return "Export Summary"
        case .reportImportSummaryTitle:
            return "Import Summary"
        case .reportVerifySummaryTitle:
            return "Verify Summary"
        case .reportVerifyReportTitle:
            return "Verify Report"
        case .reportWorkspaceApplySummaryTitle:
            return "Workspace Apply Summary"
        case .reportWorkspacePromoteSummaryTitle:
            return "Workspace Promote Summary"
        case .reportGeneratedAt:
            return "Generated at: %@"
        case .reportChecksTitle:
            return "Checks"
        case .reportSuccessTitle:
            return "Success"
        case .reportFailedTitle:
            return "Failed"
        case .reportSkippedTitle:
            return "Skipped"
        case .reportWarningsTitle:
            return "Warnings"
        case .reportManualFollowUpTitle:
            return "Manual Follow-up"
        case .reportBlockingYes:
            return "yes"
        case .reportBlockingNo:
            return "no"
        case .reportReasonLabel:
            return "reason"
        case .reportActionLabel:
            return "action"
        case .reportWorkspaceRoot:
            return "Workspace root: %@"
        case .reportDetectedTools:
            return "Detected tools: %@"
        case .reportRepoItems:
            return "Repo items: %ld"
        case .reportLocalItems:
            return "Local items: %ld"
        case .reportRepoCategoriesTitle:
            return "Repo Categories"
        case .reportLocalCategoriesTitle:
            return "Local Categories"
        case .exportLegacyTitle:
            return "Legacy Export"
        case .exportLegacyDescription:
            return "Legacy bundle export remains available through AppState, but the main navigation now centers on repo, drift, and reports."
        case .importLegacyTitle:
            return "Legacy Import"
        case .importLegacyDescription:
            return "Legacy bundle import and verify flows still exist behind AppState for compatibility, but the shell now surfaces repo control tower workflows first."
        case .workspaceDetectedToolsCount:
            return "%#@tools@"
        case .statusIdle:
            return "Idle"
        case .statusWorkspaceScanRunning:
            return "Workspace scan running..."
        case .statusWorkspaceScanCompleted:
            return "Workspace scan completed"
        case .statusWorkspaceScanCompletedWithDrift:
            return "Workspace scan completed with drift"
        case .statusWorkspaceScanFailed:
            return "Workspace scan failed: %@"
        case .statusExportRunning:
            return "Export running..."
        case .statusExportCompleted:
            return "Export completed"
        case .statusExportFailed:
            return "Export failed: %@"
        case .statusImportBundleBlockingPreflight:
            return "Import bundle has blocking preflight issues"
        case .statusImportBundleReady:
            return "Import bundle ready"
        case .statusImportPreflightFailed:
            return "Import preflight failed: %@"
        case .statusSelectImportBundleFirst:
            return "Select an import bundle first"
        case .statusImportRunning:
            return "Import running..."
        case .statusImportCompleted:
            return "Import completed"
        case .statusImportFailed:
            return "Import failed: %@"
        case .statusVerifyRunning:
            return "Verify running..."
        case .statusVerifyBlockedByPreflight:
            return "Verify blocked by preflight"
        case .statusVerifyCompleted:
            return "Verify completed"
        case .statusVerifyCompletedWithFailures:
            return "Verify completed with failures"
        case .statusVerifyFailed:
            return "Verify failed: %@"
        case .placeholderNoWorkspaceScanExecuted:
            return "No workspace scan executed"
        case .placeholderNoWorkspaceDriftComputed:
            return "No workspace drift computed"
        case .placeholderNoWorkspaceApplyPreview:
            return "No workspace apply preview"
        case .placeholderNoWorkspacePromotePreview:
            return "No workspace promote preview"
        case .placeholderNoExportExecuted:
            return "No export executed"
        case .placeholderNoImportExecuted:
            return "No import executed"
        case .placeholderNoVerifyExecuted:
            return "No verify executed"
        case .placeholderNoLogs:
            return "No logs"
        case .placeholderNone:
            return "(none)"
        case .machineSummaryFormat:
            return "Host: %@\nArchitecture: %@\nmacOS: %@\nHome: %@\nBrew Prefix: %@"
        case .manualTaskMissingBrewTitle:
            return "Homebrew installation required"
        case .manualTaskMissingBrewReason:
            return "Homebrew is not installed on this machine."
        case .manualTaskMissingBrewAction:
            return "Install Homebrew from https://brew.sh and rerun import."
        case .manualTaskMissingCodeCLITitle:
            return "VS Code CLI (code) required"
        case .manualTaskMissingCodeCLIReason:
            return "`code` CLI is unavailable, so extension restore cannot run automatically."
        case .manualTaskMissingCodeCLIAction:
            return "In VS Code, run: Shell Command: Install code command in PATH."
        case .manualTaskArchitectureMismatchTitle:
            return "Architecture mismatch"
        case .manualTaskArchitectureMismatchReason:
            return "Export machine (%@) differs from current machine (%@)."
        case .manualTaskArchitectureMismatchAction:
            return "If compatibility issues occur, reinstall affected packages manually and check Rosetta if needed."
        case .manualTaskExcludedSecretTitle:
            return "Secret item requires manual transfer"
        case .manualTaskExcludedSecretReason:
            return "Security policy excluded %@ from automatic transfer."
        case .manualTaskExcludedSecretAction:
            return "Transfer it manually via a secure channel if needed."
        case .manualTaskUnsupportedFileTitle:
            return "Unsupported file"
        case .manualTaskUnsupportedFileReason:
            return "Item is outside v1 support scope: %@"
        case .manualTaskUnsupportedFileAction:
            return "Review and transfer this file manually."
        case .manualTaskOverwriteConfirmationTitle:
            return "Overwrite backup created"
        case .manualTaskOverwriteConfirmationReason:
            return "Existing file detected; backup will be created before overwrite: %@"
        case .manualTaskOverwriteConfirmationAction:
            return "If needed, restore from the generated .bak file."
        case .preflightMacOSTitle:
            return "macOS version"
        case .preflightArchitectureTitle:
            return "CPU architecture"
        case .preflightHomeTitle:
            return "Home directory"
        case .preflightBrewTitle:
            return "Homebrew installed"
        case .preflightBrewCommandNotFound:
            return "brew command not found"
        case .preflightBrewPrefixTitle:
            return "Homebrew prefix"
        case .preflightBrewPrefixFailed:
            return "brew --prefix failed"
        case .preflightBrewPrefixUnavailable:
            return "brew prefix unavailable"
        case .preflightGitTitle:
            return "git installed"
        case .preflightGitAvailable:
            return "git available"
        case .preflightGitCommandNotFound:
            return "git command not found"
        case .preflightVSCodeTitle:
            return "VS Code installed"
        case .preflightVSCodeAppNotFound:
            return "VS Code.app not found"
        case .preflightCodeCLITitle:
            return "code CLI available"
        case .preflightCodeCLIAvailable:
            return "code CLI available"
        case .preflightCodeCLICommandNotFound:
            return "code command not found"
        case .preflightImportBundleExistsTitle:
            return "Import bundle exists"
        case .preflightWriteTitle:
            return "Target path writable"
        case .preflightBlockingFailures:
            return "Preflight has blocking failures"
        case .exportHomebrewTitle:
            return "Homebrew export"
        case .exportBrewCommandNotFound:
            return "brew command not found"
        case .exportBrewfileCreationFailedWarning:
            return "Brewfile creation failed; package restore accuracy may be reduced."
        case .exportBrewFormulaTitle:
            return "brew formula %@"
        case .exportBrewCaskTitle:
            return "brew cask %@"
        case .exportBrewTapTitle:
            return "brew tap %@"
        case .exportBrewServiceTitle:
            return "brew service %@"
        case .exportGitGlobalTitle:
            return "Git global config"
        case .exportGitCommandNotFound:
            return "git command not found"
        case .exportGitReadFailed:
            return "failed to read git global config"
        case .exportGitEntries:
            return "%ld entries"
        case .exportExcludedBySecretPolicy:
            return "excluded by secret policy"
        case .exportFileNotFound:
            return "file not found"
        case .exportOverwriteBackupNote:
            return "overwrite creates timestamped .bak backup"
        case .exportVSCodeSettingsTitle:
            return "VS Code settings"
        case .exportVSCodeKeybindingsTitle:
            return "VS Code keybindings"
        case .exportVSCodeSnippetsTitle:
            return "VS Code snippets"
        case .exportVSCodeExtensionsTitle:
            return "VS Code extensions"
        case .exportVSCodeSettingsExported:
            return "settings.json exported"
        case .exportVSCodeSettingsNotFound:
            return "settings.json not found"
        case .exportVSCodeKeybindingsExported:
            return "keybindings.json exported"
        case .exportVSCodeSnippetsFilesExported:
            return "%ld files exported"
        case .exportVSCodeCodeCLINotFound:
            return "code CLI not found"
        case .exportVSCodeExtensionsExported:
            return "%ld extensions exported"
        case .exportEmptyTitle:
            return "No supported items exported"
        case .exportEmptyMessage:
            return "No supported resources were found during export."
        case .exportEmptyNote:
            return "Import will only provide manual guidance for this bundle."
        case .exportEmptyWarning:
            return "No supported items were collected; manifest includes a manual note item."
        case .verifyPendingTitle:
            return "Verify"
        case .verifyPendingDetail:
            return "Run import + verify on target machine"
        case .importPackagesTitle:
            return "Homebrew packages"
        case .importPackagesBrewMissing:
            return "brew missing; bootstrap manual task added"
        case .importBrewfileRestoreTitle:
            return "Brewfile restore"
        case .importBrewBundleApplied:
            return "brew bundle applied"
        case .importMissingSourceMetadata:
            return "missing source metadata"
        case .importRestored:
            return "restored"
        case .importRestoredWithBackup:
            return "restored with backup: %@"
        case .importGitTitle:
            return "Git global config"
        case .importGitBackupTitle:
            return "Git global config backup"
        case .importMissingKeyValuePayload:
            return "missing key/value payload"
        case .importGitConfigApplied:
            return "git config applied"
        case .importGitConfigAppliedWithBackup:
            return "git config applied with backup: %@"
        case .importVSCodeExtensionsTitle:
            return "VS Code extensions"
        case .importMissingVSCodePayloadMetadata:
            return "missing vscode payload metadata"
        case .importDirectoryRestored:
            return "directory restored"
        case .importMissingExtensionIdentifier:
            return "missing extension identifier"
        case .importExtensionInstalled:
            return "extension installed"
        case .importVerifyFailedWarning:
            return "Verify phase contains failed checks."
        case .workspaceApplyUnsupportedCategory:
            return "category not yet supported by workspace apply"
        case .workspaceApplySecretManualTransfer:
            return "secret policy requires manual transfer"
        case .workspaceApplyMissingRepoMetadata:
            return "missing repo metadata for selected item"
        case .workspaceApplyAppliedFromWorkspace:
            return "applied from workspace"
        case .workspacePromoteUnsupportedCategory:
            return "category not yet supported by workspace promote"
        case .workspacePromoteSecretManualTransfer:
            return "secret policy requires manual transfer"
        case .workspacePromoteMissingLocalMetadata:
            return "missing local metadata for selected item"
        case .workspacePromoteStagedCandidate:
            return "staged candidate at %@"
        case .verifySpecNotProvided:
            return "verify spec not provided"
        case .verifyFileExists:
            return "File exists: %@"
        case .verifyFileMissing:
            return "File missing: %@"
        case .verifyInvalidCommand:
            return "Invalid verify command"
        case .verifyExpectedValueMatched:
            return "Expected value matched"
        case .verifyExpectedValueMismatch:
            return "Expected %@, got %@"
        case .verifyCommandSucceeded:
            return "Command succeeded"
        case .verifyUnsupportedSpec:
            return "No supported verify spec"
        case .artifactNotFound:
            return "Not found: %@"
        case .artifactUnreadable:
            return "Unreadable: %@"
        case .errorCommandFailed:
            return "Command failed: %@ %@ (%d) %@"
        case .errorMissingRequiredFile:
            return "Missing required file: %@"
        case .errorInvalidManifest:
            return "Invalid manifest: %@"
        case .errorInvalidWorkspace:
            return "Invalid workspace: %@"
        case .errorUnsupportedSchemaVersion:
            return "Unsupported schema version: %@"
        case .errorBlockedByPreflight:
            return "Preflight blocked execution: %@"
        case .errorIOFailure:
            return "I/O failure: %@"
        }
    }
}

public enum L10n {
    public static func string(_ key: L10nKey, locale: Locale? = nil) -> String {
        localizedString(for: key, locale: locale)
    }

    static func string(_ key: L10nKey, preferredLanguages: [String]) -> String {
        localizedString(for: key, locale: nil, preferredLanguages: preferredLanguages)
    }

    public static func format(_ key: L10nKey, locale: Locale? = nil, _ arguments: CVarArg...) -> String {
        let format = localizedString(for: key, locale: locale)
        return String(format: format, locale: locale ?? .autoupdatingCurrent, arguments: arguments)
    }

    static func format(_ key: L10nKey, preferredLanguages: [String], _ arguments: CVarArg...) -> String {
        let format = localizedString(for: key, locale: nil, preferredLanguages: preferredLanguages)
        let formatLocale = preferredLanguages.first.map(Locale.init(identifier:)) ?? .autoupdatingCurrent
        return String(format: format, locale: formatLocale, arguments: arguments)
    }

    private static func localizedString(
        for key: L10nKey,
        locale: Locale?,
        preferredLanguages: [String]? = nil
    ) -> String {
        let bundle = locale.map(localizedBundle(for:)) ?? preferredLocalizationBundle(preferredLanguages: preferredLanguages)
        return NSLocalizedString(key.rawValue, tableName: nil, bundle: bundle, value: key.fallback, comment: "")
    }

    private static func preferredLocalizationBundle(preferredLanguages: [String]? = nil) -> Bundle {
        let preferences = preferredLanguages ?? defaultPreferredLanguages()
        let matches = Bundle.preferredLocalizations(from: localizationBundle.localizations, forPreferences: preferences)

        for identifier in matches {
            if let path = localizationBundle.path(forResource: identifier, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle
            }
        }

        return localizationBundle
    }

    private static func defaultPreferredLanguages() -> [String] {
        let bundlePreferences = Bundle.main.preferredLocalizations
        let localePreferences = Locale.preferredLanguages
        let combined = bundlePreferences + localePreferences
        return Array(NSOrderedSet(array: combined)) as? [String] ?? ["en"]
    }

    private static func localizedBundle(for locale: Locale) -> Bundle {
        for identifier in languageIdentifiers(for: locale) {
            if let path = localizationBundle.path(forResource: identifier, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle
            }
        }

        return localizationBundle
    }

    private static func languageIdentifiers(for locale: Locale) -> [String] {
        var candidates: [String] = []
        let normalizedIdentifier = locale.identifier.replacingOccurrences(of: "_", with: "-")
        candidates.append(normalizedIdentifier)

        if let languageCode = locale.language.languageCode?.identifier {
            candidates.append(languageCode)
        } else if let baseIdentifier = normalizedIdentifier.split(separator: "-").first {
            candidates.append(String(baseIdentifier))
        }

        candidates.append("en")
        return Array(NSOrderedSet(array: candidates)) as? [String] ?? ["en"]
    }
}

private final class BundleToken {}

private let localizationBundle: Bundle = {
#if SWIFT_PACKAGE
    return .module
#else
    return Bundle(for: BundleToken.self)
#endif
}()
