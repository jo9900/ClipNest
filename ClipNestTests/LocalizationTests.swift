import XCTest
@testable import ClipNest

final class LocalizationTests: XCTestCase {
    private let languages: Set<String> = [
        "en", "zh-Hans", "zh-Hant", "ja", "ko", "es", "ar", "pt-BR", "pt-PT",
        "ms", "vi", "id", "fr", "de", "it", "ru", "hi", "th"
    ]

    func testEveryBundledLanguageLoadsAllMessagesAndPreservesArguments() throws {
        let app = Bundle.main
        XCTAssertEqual(app.developmentLocalization, "en")
        XCTAssertTrue(languages.isSubset(of: Set(app.localizations)))
        let english = try strings(in: languageBundle("en"))
        XCTAssertFalse(english.isEmpty)
        let placeholders = try NSRegularExpression(pattern: "%(@|lld)")
        func arguments(_ text: String) -> [String] {
            let source = text as NSString
            return placeholders.matches(in: text, range: NSRange(location: 0, length: source.length))
                .map { source.substring(with: $0.range) }.sorted()
        }
        for language in languages {
            let bundle = try languageBundle(language)
            let translated = try strings(in: bundle)
            XCTAssertEqual(Set(translated.keys), Set(english.keys), language)
            for key in english.keys {
                let value = bundle.localizedString(forKey: key, value: "MISSING", table: nil)
                XCTAssertEqual(value, translated[key], "\(language): \(key)")
                XCTAssertFalse(value.isEmpty, "\(language): \(key)")
                XCTAssertEqual(arguments(value), arguments(key), "\(language): \(key)")
            }
        }
        let chinese = try languageBundle("zh-Hans")
        let clip = "مرحبا · 日本語 · 안녕하세요 · Tiếng Việt 👋"
        let label = String(localized: "Copy \(clip)", bundle: chinese)
        // Foundation may wrap mixed-direction arguments in Unicode isolation marks.
        XCTAssertTrue(label.hasPrefix("复制 "))
        XCTAssertTrue(label.contains(clip))
        XCTAssertEqual(String(localized: "Settings…", bundle: chinese), "设置…")
        XCTAssertEqual(Bundle.preferredLocalizations(from: app.localizations, forPreferences: ["zh-TW"]), ["zh-Hant"])
    }

    private func languageBundle(_ language: String) throws -> Bundle {
        let root = try XCTUnwrap(Bundle.main.resourceURL)
        return try XCTUnwrap(Bundle(url: root.appendingPathComponent("\(language).lproj")))
    }

    private func strings(in bundle: Bundle) throws -> [String: String] {
        let url = try XCTUnwrap(bundle.url(forResource: "Localizable", withExtension: "strings"))
        return try XCTUnwrap(PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: String])
    }
}
