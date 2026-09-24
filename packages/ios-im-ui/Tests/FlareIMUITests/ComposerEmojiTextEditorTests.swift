import XCTest
@testable import FlareIMUI

final class ComposerEmojiTextEditorTests: XCTestCase {
    func testFindsOnlyKnownComposerEmojiTokensAndKeepsUtf16Ranges() {
        let runs = composerEmojiTokenRuns("你好 [alien] [unknown_key] [cry_loudly]") {
            ["alien", "cry_loudly"].contains($0)
        }

        XCTAssertEqual(runs.map(\.key), ["alien", "cry_loudly"])
        let source = "你好 [alien] [unknown_key] [cry_loudly]" as NSString
        XCTAssertEqual(runs.map { source.substring(with: $0.range) }, ["[alien]", "[cry_loudly]"])
    }
}
