import Foundation
import SwiftUI
import XCTest
@testable import FlareIMUI

/// The shared table (`spec/resource-overlay-vectors.json`): what a resource pack may change. The Vue, Flutter and Compose
/// kits run the same file. Rows are read with `JSONSerialization`, because `entries`, `group` and `packs` are meant to
/// come in every wrong shape.
final class ResourceOverlayTests: XCTestCase {
    private func table() throws -> [String: Any] {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let data = try Data(contentsOf: root.appendingPathComponent("spec/resource-overlay-vectors.json"))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func rows(_ name: String) throws -> [[String: Any]] {
        try XCTUnwrap(try table()[name] as? [[String: Any]])
    }

    private func strings(_ row: [String: Any], _ key: String) -> [String: String] {
        row[key] as? [String: String] ?? [:]
    }

    private func list(_ row: [String: Any], _ key: String) -> [String] {
        row[key] as? [String] ?? []
    }

    func testContent() throws {
        for row in try rows("content") {
            let content = flareResourceContent(kind: row["kind"] as! String, contentJson: row["contentJson"] as! String)
            XCTAssertEqual(content != nil, row["accepted"] as? Bool, row["name"] as? String ?? "")
        }
    }

    func testPlaceholders() throws {
        for row in try rows("placeholders") {
            XCTAssertEqual(flareResourcePlaceholders(row["text"] as! String), list(row, "expect"), row["text"] as! String)
        }
    }

    func testStrings() throws {
        for row in try rows("strings") {
            let builtIn = strings(row, "builtIn")
            let accepted = flareResourceStrings(builtIn: { builtIn[$0] }, entries: row["entries"])
            XCTAssertEqual(accepted, strings(row, "expect"), row["name"] as! String)
        }
    }

    func testLocales() throws {
        for row in try rows("locales") {
            XCTAssertEqual(
                flareResourceLocale(row["requested"] as! String, available: list(row, "available")),
                row["expect"] as? String,
                row["requested"] as! String
            )
        }
    }

    func testColors() throws {
        for row in try rows("colors") {
            let accepted = flareResourceColors(known: Set(list(row, "known")), group: row["group"])
            XCTAssertEqual(accepted, strings(row, "expect"), row["name"] as! String)
        }
    }

    func testArgb() throws {
        for row in try rows("argb") {
            XCTAssertEqual(
                Int64(flareResourceColorArgb(row["value"] as! String)),
                (row["argb"] as! NSNumber).int64Value,
                row["value"] as! String
            )
        }
    }

    private func sticker(_ raw: [String: Any]) -> FlareResourceSticker {
        FlareResourceSticker(
            stickerId: raw["stickerId"] as! String, url: raw["url"] as! String,
            previewUrl: raw["previewUrl"] as? String, alt: raw["alt"] as? String
        )
    }

    func testEmoji() throws {
        for row in try rows("emoji") {
            let want = try XCTUnwrap(row["expect"] as? [String: Any])
            let expected = FlareResourceEmojiResult(
                emoji: (want["emoji"] as? [[String: Any]] ?? []).map {
                    FlareResourceEmoji(
                        key: $0["key"] as! String, url: $0["url"] as! String,
                        previewUrl: $0["previewUrl"] as? String, labels: $0["labels"] as? [String: String] ?? [:]
                    )
                },
                stickerPacks: (want["stickerPacks"] as? [[String: Any]] ?? []).map {
                    FlareResourceStickerPack(
                        id: $0["id"] as! String, title: $0["title"] as! String, iconUrl: $0["iconUrl"] as? String,
                        stickers: ($0["stickers"] as? [[String: Any]] ?? []).map(sticker)
                    )
                }
            )
            let result = flareResourceEmoji(
                builtInEmoji: list(row, "builtInEmoji"),
                builtInPacks: list(row, "builtInPacks"),
                packs: row["packs"]
            )
            XCTAssertEqual(result, expected, row["name"] as! String)
        }
    }

    func testFold() throws {
        for row in try rows("fold") {
            let name = row["name"] as! String
            let overlay = FlareResourceOverlay(packs: (row["packs"] as? [[String: Any]] ?? []).map {
                FlareResourcePack(
                    id: $0["id"] as! String, kind: $0["kind"] as! String,
                    packVersion: ($0["packVersion"] as! NSNumber).int64Value, contentJson: $0["contentJson"] as! String
                )
            })
            let builtIn = strings(row, "builtIn")
            let known = Set(list(row, "known"))
            let want = try XCTUnwrap(row["expect"] as? [String: Any])
            XCTAssertEqual(
                overlay.stringValues(locale: row["locale"] as! String, builtIn: { builtIn[$0] }),
                strings(want, "strings"), name
            )
            XCTAssertEqual(overlay.colorValues(dark: false, known: known), strings(want, "light"), name)
            XCTAssertEqual(overlay.colorValues(dark: true, known: known), strings(want, "dark"), name)
        }
    }

    private func pack(_ kind: String, _ content: [String: Any], version: Int64 = 1) throws -> FlareResourcePack {
        var body = content
        body["schema"] = flareResourceSchema
        body["kind"] = kind
        let data = try JSONSerialization.data(withJSONObject: body)
        return FlareResourcePack(id: kind, kind: kind, packVersion: version, contentJson: String(decoding: data, as: UTF8.self))
    }

    func testStringsReplaceAFieldByItsName() throws {
        let overlay = FlareResourceOverlay(packs: [try pack("strings", ["locales": ["en": ["send": "Post"]]])])
        let folded = overlay.strings(.english, locale: "en-US")
        XCTAssertEqual(folded.send, "Post")
        XCTAssertEqual(folded.cancelReply, FlareStrings.english.cancelReply)
    }

    func testAFunctionFieldIsNotAKey() throws {
        XCTAssertNil(FlareStrings().stringValue(forKey: "readTab"))
        let overlay = FlareResourceOverlay(packs: [try pack("strings", ["locales": ["en": ["readTab": "Seen"]]])])
        XCTAssertEqual(overlay.strings(.english, locale: "en").readTab(3), FlareStrings.english.readTab(3))
    }

    func testColorsKeepLightAndDarkApart() throws {
        let overlay = FlareResourceOverlay(packs: [
            try pack("tokens", ["colors": ["primary": "#112233"], "dark": ["bgPrimary": "#44556677"]])
        ])
        let light = overlay.colors(.light, dark: false)
        XCTAssertEqual(light.primary, Color(.sRGB, red: 0x11 / 255.0, green: 0x22 / 255.0, blue: 0x33 / 255.0, opacity: 1))
        XCTAssertEqual(light.bgPrimary, FlareColors.light.bgPrimary)
        XCTAssertEqual(overlay.colors(.dark, dark: true).primary, FlareColors.dark.primary)
    }

    func testABrandWithNewColoursIsADifferentValue() throws {
        let overlay = FlareResourceOverlay(packs: [try pack("tokens", ["colors": ["primary": "#112233"]], version: 3)])
        let brand = overlay.brandTheme(.violet)
        // Brands compare by name: the environment only passes the new colours down if this differs.
        XCTAssertNotEqual(brand, FlareBrandTheme.violet)
        XCTAssertEqual(brand.name, "violet+tokens.3")
        XCTAssertEqual(FlareColors.of(.light, brand: brand).bgPrimary, FlareColors.light.bgPrimary)
        XCTAssertNotEqual(FlareColors.of(.light, brand: brand).primary, FlareColors.light.primary)
    }

    func testABrandWithNothingToSetStaysTheSame() {
        XCTAssertEqual(FlareResourceOverlay.empty.brandTheme(.ocean), .ocean)
    }

    @MainActor
    func testEmojiAddsAndLeavesWhatShipsAlone() throws {
        let catalog = FlareEmojiStickerCatalog.shared
        defer {
            catalog.clearRegisteredEmojiAssets()
            catalog.clearRegisteredStickerPacks()
        }
        let builtIn = try XCTUnwrap(catalog.bundledEmojiKeys().first)
        let before = catalog.emojiImageURL(builtIn)
        let entry: [String: Any] = [
            "id": "acme",
            "title": "Acme",
            "stickers": [["stickerId": "wave", "url": "https://cdn.example/w.webp"]],
            "emoji": [
                ["key": "acme_wave", "url": "https://cdn.example/e.webp"],
                ["key": builtIn, "url": "https://cdn.example/b.webp"],
            ],
        ]
        let overlay = FlareResourceOverlay(packs: [try pack("emoji", ["packs": [entry]])])

        overlay.registerEmoji(in: catalog)

        XCTAssertTrue(catalog.hasEmojiKey("acme_wave"))
        XCTAssertEqual(catalog.emojiImageURL("acme_wave")?.absoluteString, "https://cdn.example/e.webp")
        XCTAssertEqual(catalog.emojiImageURL(builtIn), before)
        XCTAssertEqual(catalog.loadedStickerPacks().first { $0.id == "acme" }?.stickerIds, ["wave"])
    }
}
