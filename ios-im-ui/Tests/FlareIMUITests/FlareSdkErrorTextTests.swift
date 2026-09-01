import XCTest
@testable import FlareIMUI

/// 用户不该看到原始 JSON，也不该看到裸的 i18n key。
///
/// 核心用 FlareError::localized 抛的是 key（如 sdk.message.card.avatar.invalid_url），
/// 客户端直接显示 error 的 message 就会把它甩给用户。Web 端实测过一模一样的问题，
/// 这里把同一条契约在 iOS 侧也锁住。
final class FlareSdkErrorTextTests: XCTestCase {

    private func envelope(_ message: String) -> String {
        #"{"code":"sdk.error","message":"\#(message)","operation":"message.send"}"#
    }

    func testUnwrapsJsonEnvelopeAndTranslates() {
        let out = FlareSdkErrorText.describe(
            envelope("错误 [INVALID_PARAMETER] sdk.message.card.avatar.invalid_url"))
        XCTAssertFalse(out.contains("{"), "不能把 JSON 信封显示给用户")
        XCTAssertFalse(out.contains("sdk.message"), "不能把 i18n key 显示给用户")
        XCTAssertTrue(out.contains("contact card avatar"), out)
    }

    func testDistinguishesFields() {
        let link = FlareSdkErrorText.describe(
            envelope("错误 [INVALID_PARAMETER] sdk.message.link_card.url.invalid_url"))
        let thumb = FlareSdkErrorText.describe(
            envelope("错误 [INVALID_PARAMETER] sdk.message.app_card.thumbnail_url.invalid_url"))
        XCTAssertTrue(link.contains("link URL"), link)
        XCTAssertTrue(thumb.contains("thumbnail"), thumb)
        XCTAssertNotEqual(link, thumb)
    }

    func testUnknownFieldDoesNotLeakInternalPath() {
        let out = FlareSdkErrorText.describe(
            envelope("错误 [INVALID_PARAMETER] sdk.message.unknown_thing.some_field.invalid_url"))
        XCTAssertFalse(out.contains("unknown_thing"), out)
        XCTAssertFalse(out.contains("some_field"), out)
        XCTAssertTrue(out.contains("this field"), out)
    }

    func testUnknownReasonFallsBackInsteadOfLeakingKey() {
        let out = FlareSdkErrorText.describe(
            envelope("错误 [INVALID_PARAMETER] sdk.message.foo.bar.some_unknown_reason"),
            fallback: "Sending failed.")
        XCTAssertEqual(out, "Sending failed.")
    }

    func testPlainErrorsPassThrough() {
        XCTAssertEqual(FlareSdkErrorText.describe("Network connection lost"), "Network connection lost")
    }

    func testEmptyFallsBack() {
        XCTAssertEqual(FlareSdkErrorText.describe("", fallback: "Sending failed."), "Sending failed.")
    }
}
