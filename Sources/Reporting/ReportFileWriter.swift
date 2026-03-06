import Foundation
import SharedModels
import Core

public struct ReportFileWriter {
    private let fileSystem: FileSysteming
    private let markdownWriter: MarkdownReportWriter

    public init(fileSystem: FileSysteming = LocalFileSystem(), markdownWriter: MarkdownReportWriter = MarkdownReportWriter()) {
        self.fileSystem = fileSystem
        self.markdownWriter = markdownWriter
    }

    public func writePreflight(_ result: PreflightResult, to url: URL) throws {
        try fileSystem.writeData(Data(markdownWriter.renderPreflight(result).utf8), to: url)
    }

    public func writeReport(_ report: OperationReport, to url: URL) throws {
        try fileSystem.writeData(Data(markdownWriter.renderOperationReport(report).utf8), to: url)
    }
}
