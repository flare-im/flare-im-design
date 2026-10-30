import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// `spec/me-menu-vectors.json`: the 我 page menu as settings sections, and the fallback for icon names from data.
final class MeMenuVectorsTests: XCTestCase {
    private func table() throws -> PluginJSONValue { try SpecVectors.table("me-menu-vectors.json") }

    private func menu(_ json: PluginJSONValue) throws -> FlareMeMenu {
        try JSONDecoder().decode(FlareMeMenu.self, from: JSONEncoder().encode(json))
    }

    private func strings(_ locale: String?) -> FlareStrings { locale == "en" ? .english : FlareStrings() }

    private func map(_ json: PluginJSONValue?) -> [String: String] {
        (json?.objectValue ?? [:]).compactMapValues(\.stringValue)
    }

    func testEveryCaseMapsTheSdkMenuAsTheTableSays() throws {
        let cases = try XCTUnwrap(try table()["cases"]?.arrayValue)
        XCTAssertGreaterThanOrEqual(cases.count, 8, "the shared table lost cases")
        for vector in cases {
            let id = vector["id"]?.stringValue ?? "?"
            let sections = flareMeMenuSections(try menu(try XCTUnwrap(vector["menu"], id)),
                                               labels: map(vector["labels"]), summaries: map(vector["summaries"]),
                                               strings: strings(vector["locale"]?.stringValue))
            let expected = try XCTUnwrap(vector["expect"]?.arrayValue, id)
            XCTAssertEqual(sections.count, expected.count, "\(id) sections")
            for (section, fact) in zip(sections, expected) {
                let items = fact["items"]?.arrayValue ?? []
                XCTAssertNil(section.title, "\(id): the menu's sections have no title")
                XCTAssertEqual(section.items.map(\.key), items.compactMap { $0["key"]?.stringValue }, "\(id) keys")
                XCTAssertEqual(section.items.map(\.label), items.compactMap { $0["label"]?.stringValue }, "\(id) labels")
                XCTAssertEqual(section.items.map(\.icon), items.map { $0["icon"]?.stringValue }, "\(id) icons")
                XCTAssertEqual(section.items.map(\.detail), items.map { $0["detail"]?.stringValue }, "\(id) details")
                for item in section.items { XCTAssertEqual(item.kind, .navigation, "\(id) \(item.key)") }
            }
        }
    }

    func testTheKitCopyIsTheSharedCopy() throws {
        let copy = try XCTUnwrap(try table()["copy"])
        for language in ["zh", "en"] {
            let s = strings(language)
            let facts = try XCTUnwrap(copy[language], language)
            XCTAssertEqual(s.meMenuMoments, facts["moments"]?.stringValue, language)
            XCTAssertEqual(s.meMenuReports, facts["reports"]?.stringValue, language)
            XCTAssertEqual(s.meMenuInvite, facts["invite"]?.stringValue, language)
            XCTAssertEqual(s.meMenuSettings, facts["settings"]?.stringValue, language)
            XCTAssertEqual(s.meMenuPluginFallback, facts["pluginFallback"]?.stringValue, language)
        }
    }

    func testIconNamesFromDataFallBackToThePluginGlyph() throws {
        let block = try XCTUnwrap(try table()["iconFallback"])
        let cases = try XCTUnwrap(block["cases"]?.arrayValue)
        XCTAssertGreaterThanOrEqual(cases.count, 6)
        for vector in cases {
            let name = try XCTUnwrap(vector["name"]?.stringValue)
            XCTAssertEqual(flareIconNameOrFallback(name), vector["expect"]?.stringValue, "\"\(name)\"")
        }
        XCTAssertNil(flareIconNameOrFallback(nil), "no name, no icon")
        XCTAssertNil(flareIconNameOrFallback("   "))
    }

    /// The SDK JSON as it comes: extra fields are ignored, a kind from a newer SDK is dropped, `complete` is read.
    func testTheMenuDecodesTheSdkJson() throws {
        let json = #"{"items":[{"kind":"builtin","id":"moments","icon":"moments","order":10,"target":{"route":"moments"}},{"kind":"shortcut","id":"x","order":16},{"kind":"plugin","id":"plugin:a","title":"A","order":100,"summary":{"operation":"a","path":"/x"}}],"complete":false}"#
        let menu = try XCTUnwrap(FlareMeMenu.parse(json))
        XCTAssertEqual(menu.items.map(\.id), ["moments", "plugin:a"])
        XCTAssertEqual(menu.items.map(\.kind), [.builtin, .plugin])
        XCTAssertFalse(menu.complete)
        XCTAssertNil(FlareMeMenu.parse("[]"))
    }

    /// A settings row whose icon is not a registry name draws the plugin glyph: no question mark, no name as text.
    @MainActor
    func testARowDrawsThePluginGlyphForAnUnknownName() throws {
        let row = FlareSettingsRow(item: FlareSettingsItem(key: "k", label: "积分", icon: "coins-stack"))
        let drawn = try row.inspect().findAll(ViewType.Image.self).map { try $0.actualImage().name() }
        XCTAssertEqual(drawn.filter { $0 != "chevron.right" }, [flareIconMap["plugin"]].compactMap { $0 })
        XCTAssertThrowsError(try row.inspect().find(text: "coins-stack"))
        let blank = FlareSettingsRow(item: FlareSettingsItem(key: "k", label: "积分", icon: ""))
        let names = try blank.inspect().findAll(ViewType.Image.self).map { try $0.actualImage().name() }
        XCTAssertEqual(names, ["chevron.right"], "an empty name draws no icon, only the chevron")
    }
}
