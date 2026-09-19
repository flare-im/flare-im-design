import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// FR-097: the emoji and sticker panel belonged to every app instead of the composer, so a native app
/// mounted one itself and sent emoji as standalone messages. The composer owns it when the host does
/// not, and a host that handles the key still gets its own.
final class ComposerEmojiPanelTests: XCTestCase {
    private let s = FlareStrings()

    @MainActor
    func testTheComposerOpensItsOwnPanelWhenNoHostHandlesTheKey() throws {
        let composer = ComposerView()
        XCTAssertThrowsError(try composer.inspect().find(FlareEmojiStickerPicker.self), "closed until the key is pressed")
        let key = try composer.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == s.composerEmoji })
        XCTAssertNoThrow(try key.tap())
    }

    @MainActor
    func testAHostThatHandlesTheKeyKeepsItsOwnPanel() throws {
        var pressed = 0
        let composer = ComposerView(onEmoji: { pressed += 1 })
        try composer.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == s.composerEmoji }).tap()
        XCTAssertEqual(pressed, 1)
        XCTAssertThrowsError(try composer.inspect().find(FlareEmojiStickerPicker.self),
                             "the host's own panel is the one that opens")
    }
}
