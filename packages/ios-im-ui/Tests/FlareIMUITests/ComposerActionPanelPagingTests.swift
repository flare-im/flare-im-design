import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The "+" panel pages on a phone (rows × columns per page) and shows at most three scrolling rows on a desktop; a
/// new list keeps the page, and a composer whose menu is empty hides "+".
final class ComposerActionPanelPagingTests: XCTestCase {
    private func actions(_ count: Int) -> [FlareComposerAction] {
        (0..<count).map { FlareComposerAction(id: "a\($0)", label: "a\($0)", icon: "plugin") }
    }

    func testAPhonePagesTheGridByRowsAndColumns() {
        let ids = (0..<11).map { "a\($0)" }
        XCTAssertEqual(composerPanelPages(ids, rows: 2, columns: 4).map(\.count), [8, 3])
        XCTAssertEqual(composerPanelPages(ids, rows: 2, columns: 4)[1], ["a8", "a9", "a10"])
        XCTAssertEqual(composerPanelPages(ids, rows: 1, columns: 5).map(\.count), [5, 5, 1])
        XCTAssertTrue(composerPanelPages([String](), rows: 2, columns: 4).isEmpty)
    }

    func testANewListKeepsThePageAndClampsWhenPagesGoAway() {
        XCTAssertEqual(composerPanelPage(1, pages: 2), 1)
        XCTAssertEqual(composerPanelPage(1, pages: 1), 0)
        XCTAssertEqual(composerPanelPage(3, pages: 0), 0)
    }

    @MainActor
    func testAPhonePagesAndADesktopScrolls() throws {
        let phone = FlareComposerActionPanel(actions: actions(11))
        XCTAssertNoThrow(try phone.inspect().find(ViewType.GeometryReader.self))
        XCTAssertThrowsError(try phone.inspect().find(ViewType.ScrollView.self))
        let desktop = FlareComposerActionPanel(actions: actions(17), formFactor: .desktop)
        XCTAssertNoThrow(try desktop.inspect().find(ViewType.ScrollView.self))
        XCTAssertThrowsError(try desktop.inspect().find(ViewType.GeometryReader.self))
        XCTAssertEqual(try desktop.inspect().findAll(ViewType.Button.self).count, 17)
    }

    @MainActor
    func testAComposerWhoseMenuIsEmptyHidesPlus() throws {
        func keyNames(_ actions: [FlareComposerAction]) throws -> Set<String> {
            let view = ComposerView(onSend: { _ in }, actions: actions, onAction: { _ in })
            return Set(try view.inspect().findAll(ViewType.Button.self).compactMap { try? $0.accessibilityLabel().string() })
        }
        let more = FlareStrings().composerMore
        XCTAssertTrue(try keyNames(actions(1)).contains(more))
        XCTAssertFalse(try keyNames([]).contains(more))
    }
}
