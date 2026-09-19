import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

final class CanonicalControlInteractionTests: XCTestCase {
    @MainActor
    func testLargeBlockButtonIsTheOnlyPrimaryActionAndKeepsBusyState() throws {
        var calls = 0
        let primary = ButtonView(label: "Sign in", size: .lg, block: true, action: { calls += 1 })
        try primary.inspect().find(ViewType.Button.self).tap()
        XCTAssertEqual(calls, 1)
        let busy = ButtonView(label: "Connecting", size: .lg, loading: true, block: true, action: { calls += 1 })
        let button = try busy.inspect().find(ViewType.Button.self)
        XCTAssertEqual(try button.find(text: "Connecting").string(), "Connecting")
        XCTAssertTrue(button.isDisabled())
        XCTAssertThrowsError(try button.tap())
        XCTAssertEqual(calls, 1)
    }

    @MainActor
    func testToastActionsAreRealControlsWithMinimumTargets() throws {
        var actions = 0
        var closes = 0
        let toast = ToastView(message: "Upload failed", variant: .error,
                              actionLabel: "Retry", onAction: { actions += 1 }, onClose: { closes += 1 })
        let buttons = try toast.inspect().findAll(ViewType.Button.self)
        XCTAssertEqual(buttons.count, 2)
        for button in buttons {
            XCTAssertGreaterThanOrEqual(try button.labelView().flexFrame().minHeight, FlareSizes.touchTarget)
            try button.tap()
        }
        XCTAssertEqual(actions, 1)
        XCTAssertEqual(closes, 1)
        let noHandler = ToastView(message: "Unavailable", actionLabel: "Retry")
        XCTAssertTrue(try noHandler.inspect().findAll(ViewType.Button.self).isEmpty)
    }

    @MainActor
    func testPackPickerEmitsCatalogKeyAndDisablesUnavailableInsert() throws {
        let catalog = FlareEmojiStickerCatalog.shared
        let key = try XCTUnwrap(catalog.loadedEmojiKeys().first)
        var inserted: String?
        let picker = FlareEmojiStickerPicker(onInsertEmoji: { inserted = $0 })
        let first = try picker.inspect().find(ViewType.Button.self)
        try first.tap()
        XCTAssertEqual(inserted, key)
        let disabled = try FlareEmojiStickerPicker().inspect().find(ViewType.Button.self)
        XCTAssertTrue(disabled.isDisabled())
        XCTAssertThrowsError(try disabled.tap())
    }
}
