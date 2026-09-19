import Foundation
import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The shared layout table (`spec/image-group-layout-vectors.json`) and the album body built on it.
final class ImageGroupMessageViewTests: XCTestCase {
    private struct Table: Decodable {
        let maxVisible: Int
        let cases: [Case]
        struct Case: Decodable { let count: Int; let columns: Int; let visible: Int; let more: Int }
    }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        return try JSONDecoder().decode(Table.self, from: Data(contentsOf: root.appendingPathComponent("spec/image-group-layout-vectors.json")))
    }

    private func album(_ count: Int) -> [FlareImageContent] {
        (0..<count).map { FlareImageContent(url: "https://cdn.example/\($0).jpg") }
    }

    func testEveryCountLaysOutAsTheTableSays() throws {
        let table = try table()
        XCTAssertEqual(FlareImageGroupLayout.maxVisible, table.maxVisible)
        XCTAssertGreaterThanOrEqual(table.cases.count, 13)
        for c in table.cases {
            XCTAssertEqual(FlareImageGroupLayout.forCount(c.count),
                           FlareImageGroupLayout(columns: c.columns, visible: c.visible, more: c.more), "\(c.count) image(s)")
        }
    }

    func testTilesAreNamedByPositionAndTheCoveredOneCountsWhatIsNotDrawn() {
        let strings = FlareStrings()
        let layout = FlareImageGroupLayout.forCount(12)
        XCTAssertEqual(ImageGroupMessageView.label(0, count: 12, layout: layout, strings: strings), "第 1 张图片，共 12 张")
        XCTAssertEqual(ImageGroupMessageView.label(8, count: 12, layout: layout, strings: strings), "第 9 张图片，共 12 张，另有 4 张未显示")
    }

    func testTheBodyDrawsNineTilesAndTheCountAndOpensTheTappedImage() throws {
        var opened: [Int] = []
        let view = ImageGroupMessageView(images: album(12), description: "周末爬山") { opened.append($0) }
        let buttons = try view.inspect().findAll(ViewType.Button.self)
        XCTAssertEqual(buttons.count, 9)
        XCTAssertNoThrow(try view.inspect().find(text: "+4"))
        XCTAssertNoThrow(try view.inspect().find(text: "周末爬山"))
        try buttons[1].tap()
        try buttons[8].tap()
        XCTAssertEqual(opened, [1, 8])
        // Without a handler the tiles are pictures, not buttons.
        XCTAssertTrue(try ImageGroupMessageView(images: album(3)).inspect().findAll(ViewType.Button.self).isEmpty)
    }

    func testAnEmptyAlbumDrawsNothingAndSummarisesAsTheTerm() throws {
        XCTAssertThrowsError(try ImageGroupMessageView(images: []).inspect().find(ViewType.VStack.self))
        let s = FlareStrings()
        XCTAssertEqual(flareMessagePreviewText(FlareImageGroupContent(images: []), strings: s), s.previewImageGroup)
        XCTAssertEqual(flareMessagePreviewText(FlareImageGroupContent(images: album(3)), strings: s), s.previewImageGroupCount(3))
    }

    func testTheDispatcherHandsTheHostTheWholeAlbum() throws {
        let content = FlareImageGroupContent(images: album(3))
        var handled: FlareMessageContent?
        let view = MessageContentView(content: content, onMediaAction: { handled = $0 })
        let body = try view.inspect().find(ImageGroupMessageView.self)
        try body.findAll(ViewType.Button.self)[2].tap()
        XCTAssertTrue(handled is FlareImageGroupContent)
        XCTAssertEqual((handled as? FlareImageGroupContent)?.images.count, 3)
    }
}
