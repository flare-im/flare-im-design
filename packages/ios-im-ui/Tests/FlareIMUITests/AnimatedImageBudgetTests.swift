import Foundation
import XCTest
@testable import FlareIMUI

final class AnimatedImageBudgetTests: XCTestCase {
    @MainActor
    func testAsyncDecodePreservesBudgetAndCancelsBeforePublishing() async throws {
        let url = try XCTUnwrap(FlareEmojiStickerCatalog.shared.emojiImageURL("grinning_face"))
        let data = try Data(contentsOf: url)
        let fileResult = await flareDecodeAnimatedFileAsync(url: url, firstFrameOnly: true)
        XCTAssertEqual(fileResult?.frames.count, 1)
        let dataResult = await flareDecodeAnimatedDataAsync(data, firstFrameOnly: true)
        XCTAssertEqual(dataResult?.frames.count, 1)
        let invalid = await flareDecodeAnimatedDataAsync(Data("invalid".utf8))
        XCTAssertNil(invalid)
        let task = Task { @MainActor in
            await flareDecodeAnimatedFileAsync(url: url)
        }
        task.cancel()
        let cancelled = await task.value
        XCTAssertNil(cancelled)
    }

    func testEncodedBudgetAndInvalidDataFailClosed() {
        XCTAssertNil(flareDecodeAnimatedData(Data(repeating: 0, count: FlareAnimatedImageBudget.encodedBytes + 1)))
        XCTAssertNil(flareDecodeAnimatedData(Data("not an image".utf8)))
        XCTAssertNil(flareDecodeAnimatedWebp(url: URL(string: "https://example.com/remote.webp")))
    }

    func testBundledAnimationIsBoundedAndReducedMotionDecodesOneFrame() throws {
        let url = try XCTUnwrap(FlareEmojiStickerCatalog.shared.emojiImageURL("grinning_face"))
        let data = try Data(contentsOf: url)
        let animated = try XCTUnwrap(flareDecodeAnimatedData(data))
        XCTAssertGreaterThan(animated.frames.count, 0)
        XCTAssertLessThanOrEqual(animated.frames.count, FlareAnimatedImageBudget.frameCount)
        let staticFrame = try XCTUnwrap(flareDecodeAnimatedData(data, firstFrameOnly: true))
        XCTAssertEqual(staticFrame.frames.count, 1)
        XCTAssertFalse(staticFrame.isAnimated)
        XCTAssertTrue(animated.durations.allSatisfy { $0.isFinite && $0 >= 0.02 && $0 <= 10 })
    }

    func testStreamLimitCannotBeBypassedByMissingContentLength() async throws {
        func stream(_ count: Int) -> AsyncStream<UInt8> {
            AsyncStream { continuation in
                for _ in 0..<count { continuation.yield(7) }
                continuation.finish()
            }
        }
        let accepted = try await flareCollectLimitedBytes(stream(4), maximum: 4)
        XCTAssertEqual(accepted.count, 4)
        do {
            _ = try await flareCollectLimitedBytes(stream(5), maximum: 4)
            XCTFail("Oversized stream accepted")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .dataLengthExceedsMaximum)
        }
    }
}
