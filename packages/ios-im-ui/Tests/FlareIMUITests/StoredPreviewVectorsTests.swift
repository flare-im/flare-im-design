import Foundation
import XCTest
@testable import FlareIMUI

/// The shared table's `stored` list (`spec/message-preview-vectors.json`): each token exactly as the core
/// writes it for a conversation's last message, a quote or a search hit, and the line it reads as. Vue
/// (`displayTextFromStoredPreview`) and the Compose and Flutter kits read the same list.
final class StoredPreviewVectorsTests: XCTestCase {
    private struct Table: Decodable {
        let stored: [Vector]
    }

    private struct Vector: Decodable {
        let id: String
        let token: String
        let expected: [String: String]
    }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let url = root.appendingPathComponent("spec/message-preview-vectors.json")
        return try JSONDecoder().decode(Table.self, from: Data(contentsOf: url))
    }

    func testEveryStoredTokenReadsTheSameInBothLocales() throws {
        let stored = try table().stored
        XCTAssertGreaterThanOrEqual(stored.count, 40, "the shared table lost tokens")
        let strings = ["zh-CN": FlareStrings(), "en-US": FlareStrings.english]
        for vector in stored {
            for (locale, s) in strings {
                XCTAssertEqual(flareStoredPreviewText(vector.token, strings: s, locale: locale),
                               vector.expected[locale], "\(vector.id) @ \(locale)")
            }
        }
    }

    /// A host names the events it owns; the kit names the rest, and the server's own words beat both.
    func testAHostNamesItsOwnEventsFirst() {
        let s = FlareStrings()
        let host: (String) -> String = { $0 == "shop.order_paid" ? "订单已支付" : "" }
        XCTAssertEqual(flareStoredPreviewText(#"{"k":"im.preview.system","a":{"ek":"shop.order_paid"}}"#,
                                              strings: s, locale: "zh-CN", systemEventText: host), "订单已支付")
        XCTAssertEqual(flareStoredPreviewText(#"{"k":"im.preview.system","a":{"ek":"group.member_left"}}"#,
                                              strings: s, locale: "zh-CN", systemEventText: host),
                       s.systemEventGroupMemberLeft)
        XCTAssertEqual(flareStoredPreviewText(#"{"k":"im.preview.system","a":{"ek":"shop.order_paid","fb":"已付款"}}"#,
                                              strings: s, locale: "zh-CN", systemEventText: host), "已付款")
        XCTAssertEqual(flareStoredPreviewText(nil, strings: s), "")
        XCTAssertEqual(flareStoredPreviewText("   ", strings: s), "")
    }
}
