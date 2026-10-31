import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// A picture, a video or a voice message the host has no address for (it hands the kit ``FlareGenericContent``
/// under the media's wire type) is still that kind of message: it says it is not available right now, in the
/// host's language, and never reads as "unsupported". The other three kits draw the same body.
final class MediaUnavailableTests: XCTestCase {
    @MainActor
    func testMediaWithoutAnAddressSaysItIsNotAvailable() throws {
        let cases: [(String, String)] = [("image", "图片暂时无法加载"), ("video", "视频暂时无法加载"), ("audio", "语音暂时无法加载")]
        for (type, words) in cases {
            let view = MessageContentView(content: FlareGenericContent(contentType: type, label: type))
            let body = try view.inspect().find(MediaUnavailableView.self)
            XCTAssertNoThrow(try body.find(text: words), type)
            XCTAssertEqual(try body.hStack().accessibilityLabel().string(), words, type)
            XCTAssertThrowsError(try view.inspect().find(UnknownMessageView.self), type)
            XCTAssertTrue(try view.inspect().findAll(ViewType.Button.self).isEmpty, "\(type): nothing to tap")
        }
    }

    func testTheWordsFollowTheHostsLanguage() {
        let en = FlareStrings.english
        XCTAssertEqual(MediaUnavailableView.line("image", strings: en)?.text, "Image isn't available right now")
        XCTAssertEqual(MediaUnavailableView.line("video", strings: en)?.text, "Video isn't available right now")
        XCTAssertEqual(MediaUnavailableView.line("audio", strings: en)?.text, "Voice message isn't available right now")
        XCTAssertEqual(MediaUnavailableView.line("voice", strings: en)?.icon, "mic")
        XCTAssertNil(MediaUnavailableView.line("flare.poll.v9", strings: en))
    }

    @MainActor
    func testAnyOtherTypeIsStillTheUnsupportedCard() throws {
        let view = MessageContentView(content: FlareGenericContent(contentType: "flare.poll.v9", label: "投票"))
        XCTAssertNoThrow(try view.inspect().find(UnknownMessageView.self))
        XCTAssertThrowsError(try view.inspect().find(MediaUnavailableView.self))
    }
}
