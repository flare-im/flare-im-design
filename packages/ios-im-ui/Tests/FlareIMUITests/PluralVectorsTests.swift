import SwiftUI
import XCTest
@testable import FlareIMUI

/// `spec/plural-vectors.json`: which counts take the `one` form per locale, and the copy that has one.
final class PluralVectorsTests: XCTestCase {
    private func table() throws -> PluginJSONValue { try SpecVectors.table("plural-vectors.json") }

    func testEveryLocaleAndCountPicksTheFormTheTableSays() throws {
        let cases = try XCTUnwrap(try table()["cases"]?.arrayValue)
        XCTAssertGreaterThanOrEqual(cases.count, 96, "the shared table lost cases")
        for vector in cases {
            let locale = try XCTUnwrap(vector["locale"]?.stringValue)
            let count = try XCTUnwrap(vector["count"]?.intValue)
            let one = try XCTUnwrap(vector["one"]?.boolValue)
            XCTAssertEqual(flarePluralIsOne(count, locale: Locale(identifier: locale)), one, "\(locale) \(count)")
            // Foundation spells identifiers with "_".
            let underscored = locale.replacingOccurrences(of: "-", with: "_")
            XCTAssertEqual(flarePluralIsOne(count, locale: Locale(identifier: underscored)), one, "\(underscored) \(count)")
        }
    }

    /// The rule table in the vectors is the kit's table, language by language.
    func testTheRuleTableIsTheSharedTable() throws {
        let rules = try XCTUnwrap(try table()["rules"])
        let languages = try XCTUnwrap(rules["languages"]?.objectValue)
        XCTAssertEqual(Set(languages.keys), Set(FlarePluralFamily.allCases.map(\.rawValue)))
        for (family, list) in languages {
            for language in list.arrayValue ?? [] {
                let code = try XCTUnwrap(language.stringValue)
                // pt is is0or1 except in Portugal.
                XCTAssertEqual(flarePluralFamily(localeIdentifier: code).rawValue, family, code)
            }
        }
        XCTAssertEqual(flarePluralFamily(localeIdentifier: "pt-PT"), .is1)
        XCTAssertEqual(flarePluralFamily(localeIdentifier: "pt_BR"), .is0or1)
        XCTAssertEqual(flarePluralFamily(localeIdentifier: "zh-Hans-CN"), FlarePluralFamily.none)
        XCTAssertEqual(flarePluralFamily(localeIdentifier: "xx"), FlarePluralFamily(rawValue: rules["default"]?.stringValue ?? ""))
    }

    /// The copy with a one form, through the kit's own functions.
    func testTheCountCopyTakesTheOneForm() throws {
        let forms = try XCTUnwrap(try table()["forms"]?.arrayValue)
        XCTAssertGreaterThanOrEqual(forms.count, 8)
        for form in forms {
            let field = try XCTUnwrap(form["native"]?.stringValue)
            let language = try XCTUnwrap(form["locale"]?.stringValue)
            let count = try XCTUnwrap(form["count"]?.intValue)
            let strings = language.hasPrefix("en") ? FlareStrings.english : FlareStrings()
            let locale = Locale(identifier: language)
            let text: String
            switch field {
            case "pluginViewVotes": text = strings.pluginViewVotesText(count, locale: locale)
            case "forwardRecordTotal": text = strings.forwardRecordTotalText(count, locale: locale)
            case "forwardRecordMore": text = strings.forwardRecordMoreText(count, locale: locale)
            case "myInviteCountOnly": text = strings.myInviteCountOnlyText(count, locale: locale)
            case "messageBatchUnforwardable": text = strings.messageBatchUnforwardableText(count, locale: locale)
            case "storageUsageFileCount":
                let view = StorageUsageView(categories: [], locale: language)
                text = StorageUsageView.fileCountText(count, copy: view.resolveCopy(strings), locale: locale)
            default: XCTFail("no native copy for \(field)"); continue
            }
            XCTAssertEqual(text, form["text"]?.stringValue, "\(field) \(language) \(count)")
        }
    }

    /// The plugin view's vote copy and the group header follow the locale.
    func testVoteCountsInThePluginViewAreFormedByLocale() {
        let en = FlareStrings.english
        let us = Locale(identifier: "en_US")
        XCTAssertEqual(PluginViewFormat.votes(1, en, locale: us), "1 vote")
        XCTAssertEqual(PluginViewFormat.votes(2, en, locale: us), "2 votes")
        XCTAssertEqual(PluginViewFormat.votes(1, FlareStrings(), locale: Locale(identifier: "zh_CN")), "1 票")
        let group = PluginEntryGroup(key: "a", label: "火锅", count: 1, percent: 50)
        XCTAssertEqual(PluginViewFormat.groupHeader(group, en, locale: us), "火锅 · 1 vote · 50%")
    }
}
