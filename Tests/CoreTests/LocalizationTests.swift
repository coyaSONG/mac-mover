import Foundation
import Testing
@testable import Localization

struct LocalizationTests {
    @Test
    func englishLookupReturnsDefaultText() {
        let locale = Locale(identifier: "en")

        #expect(L10n.string(.appTabOverview, locale: locale) == "Overview")
    }

    @Test
    func koreanLookupReturnsTranslatedText() {
        let locale = Locale(identifier: "ko")

        #expect(L10n.string(.appTabOverview, locale: locale) == "개요")
    }

    @Test
    func englishPluralizedToolCountUsesStringsdict() {
        let locale = Locale(identifier: "en")

        #expect(L10n.format(.workspaceDetectedToolsCount, locale: locale, 1) == "1 tool detected")
        #expect(L10n.format(.workspaceDetectedToolsCount, locale: locale, 3) == "3 tools detected")
    }

    @Test
    func koreanPluralizedToolCountUsesStringsdict() {
        let locale = Locale(identifier: "ko-KR")

        #expect(L10n.format(.workspaceDetectedToolsCount, locale: locale, 1) == "도구 1개 감지됨")
        #expect(L10n.format(.workspaceDetectedToolsCount, locale: locale, 3) == "도구 3개 감지됨")
    }

    @Test
    func preferredLanguageSelectionCanBeTestedWithoutProcessWideMutation() {
        #expect(
            L10n.string(
                .appTabOverview,
                preferredLanguages: ["ko"]
            ) == "개요"
        )
        #expect(
            L10n.format(
                .workspaceDetectedToolsCount,
                preferredLanguages: ["ko"],
                2
            ) == "도구 2개 감지됨"
        )
    }
}
