import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// docs/plugin-experience.md §4 and §6.3–6.4: the rules behind the red packet review, the composer's field errors,
/// the open sheet's review-on-error, the payment confirmation's insufficient and countdown states, the document
/// slot and the capture viewfinder.
final class RedPacketExperienceTests: XCTestCase {
    private let zh = FlareStrings()

    func testArchIsThirtyTwoHighCompactAndTheDetailHeaderOtherwise() {
        XCTAssertEqual(RedPacketArchView.height(compact: true), 32)
        XCTAssertEqual(RedPacketArchView.height(compact: false), FlareSizes.componentRedPacketDetailHeaderHeight)
    }

    func testComposerErrorGoesToItsFieldOrTheForm() {
        typealias Composer = RedPacketComposerView<EmptyView>
        XCTAssertEqual(Composer.error("Too much", errorField: nil, for: .form), "Too much", "no field: the form banner")
        XCTAssertNil(Composer.error("Too much", errorField: nil, for: .amount))
        XCTAssertEqual(Composer.error("At most 100", errorField: .count, for: .count), "At most 100")
        XCTAssertNil(Composer.error("At most 100", errorField: .count, for: .form))
        XCTAssertNil(Composer.error("", errorField: .amount, for: .amount))
    }

    @MainActor
    func testReviewOnErrorOffersTheResultInsteadOfAnotherTry() throws {
        XCTAssertTrue(RedPacketOpenSheet.reviews(.error, reviewOnError: true))
        XCTAssertFalse(RedPacketOpenSheet.reviews(.error, reviewOnError: false))
        XCTAssertFalse(RedPacketOpenSheet.reviews(.ready, reviewOnError: true))
        var events: [String] = []
        let view = try RedPacketOpenSheet(senderName: "Ann", blessing: "Wish", state: .error, reviewOnError: true,
                                          onOpen: { events.append("open") }, onViewDetails: { events.append("details") },
                                          onClose: {}).inspect()
        XCTAssertThrowsError(try view.find(button: zh.packetOpenAction), "no second claim")
        try view.find(button: "查看结果").tap()
        XCTAssertEqual(events, ["details"])
    }

    func testPaymentShortfallTurnsConfirmOffAndSaysHowMuch() {
        let order = FlarePaymentOrder(orderId: "o1", amount: "26.64", currency: "CNY", payee: "Red packet", title: "",
                                      expiresAtMs: 10_000)
        XCTAssertEqual(FlarePaymentConfirmation.insufficientText("¥6.64", strings: zh), "余额不足，还差 ¥6.64")
        XCTAssertNil(FlarePaymentConfirmation.insufficientText(nil, strings: zh))
        XCTAssertNil(FlarePaymentConfirmation.insufficientText("", strings: zh))
        XCTAssertTrue(FlarePaymentConfirmation.confirmEnabled(order: order, nowMs: 0, busy: false, confirmDisabled: false))
        XCTAssertFalse(FlarePaymentConfirmation.confirmEnabled(order: order, nowMs: 0, busy: false, confirmDisabled: false,
                                                               shortfall: "¥6.64"))
    }

    func testCountdownWarnsInItsLastMinute() {
        XCTAssertTrue(FlarePaymentConfirmation.countdownUrgent(remainingMs: 59_000))
        XCTAssertFalse(FlarePaymentConfirmation.countdownUrgent(remainingMs: 60_000))
        XCTAssertFalse(FlarePaymentConfirmation.countdownUrgent(remainingMs: 0), "expired is not urgent, it is over")
    }

    func testDocumentSlotIsSixteenByTenAndNeverUnderItsMinimum() {
        XCTAssertEqual(FlareDocumentSlot.height(width: 320), 200)
        XCTAssertEqual(FlareDocumentSlot.height(width: 100), FlareSizes.componentDocumentSlotHeight)
    }

    func testDocumentSlotReadsItsState() {
        XCTAssertEqual(FlareDocumentSlot.stateText(.empty, strings: zh), zh.documentSlotTapToCapture)
        XCTAssertEqual(FlareDocumentSlot.stateText(.failed, strings: zh), zh.documentSlotUploadFailed)
        XCTAssertEqual(FlareDocumentSlot.stateText(.captured, strings: zh), zh.documentSlotCaptured)
        XCTAssertEqual(FlareDocumentSlot.stateText(.uploading(42.4), strings: zh), "正在上传 42%")
        XCTAssertEqual(FlareDocumentSlot.percent(130), 100)
        XCTAssertEqual(FlareDocumentSlot.percent(-3), 0)
    }

    @MainActor
    func testDocumentSlotCapturesOrRetriesByItsState() throws {
        var events: [String] = []
        func slot(_ state: FlareDocumentSlotState) -> FlareDocumentSlot {
            FlareDocumentSlot(side: .front, label: zh.pluginFormDocumentFront, state: state,
                              onCapture: { events.append("capture") }, onRetry: { events.append("retry") })
        }
        try slot(.empty).inspect().find(ViewType.Button.self).tap()
        try slot(.captured).inspect().find(ViewType.Button.self).tap()
        try slot(.failed).inspect().find(ViewType.Button.self).tap()
        XCTAssertEqual(events, ["capture", "capture", "retry"])
        XCTAssertTrue(try slot(.uploading(10)).inspect().find(ViewType.Button.self).isDisabled())
    }

    @MainActor
    func testGroupComposerSaysHowManyMembersThereAre() throws {
        let view = try RedPacketComposerView(kinds: [.lucky, .normal], kind: .lucky, amount: "", total: "¥0.00",
                                             memberCount: 12).inspect()
        XCTAssertNoThrow(try view.find(text: zh.packetGroupMembers.replacingOccurrences(of: "{count}", with: "12")))
        XCTAssertNoThrow(try view.find(text: zh.packetBadgeLuckyShort), "a lucky amount row carries its badge")
        XCTAssertNoThrow(try view.find(text: zh.packetCountUnit), "the count reads with its unit")
    }

    func testCaptureFramesAreIdOneAndTheHoldingFaceSitsAboveTheCard() {
        let stage = CGSize(width: 390, height: 600)
        let front = FlareDocumentCapture.guides(side: .front, in: stage)
        XCTAssertNil(front.face)
        XCTAssertEqual(front.card.width, 390 - 2 * FlareSizes.spacing2xl, accuracy: 0.01)
        XCTAssertEqual(front.card.width / front.card.height, FlareSizes.componentDocumentFrameRatio, accuracy: 0.001)
        XCTAssertEqual(front.card.midY, 300, accuracy: 0.01)

        let wide = FlareDocumentCapture.guides(side: .back, in: CGSize(width: 560, height: 350))
        XCTAssertLessThanOrEqual(wide.card.height, 350 - 2 * FlareSizes.spacing2xl + 0.01, "a short stage shrinks it")

        let holding = FlareDocumentCapture.guides(side: .holding, in: stage)
        let face = try? XCTUnwrap(holding.face)
        XCTAssertEqual(face?.width ?? 0, 195, accuracy: 0.01, "the face oval is half the width")
        XCTAssertEqual(holding.card.width, 390 * 0.6, accuracy: 0.01)
        XCTAssertGreaterThan(holding.card.minY, face?.maxY ?? .infinity)
        XCTAssertGreaterThan(holding.card.midX, 195, "the card sits right of centre")
        XCTAssertEqual(holding.card.width / holding.card.height, FlareSizes.componentDocumentFrameRatio, accuracy: 0.001)
    }

    func testPinKeepsSixDigitsAndReadsTheirCount() {
        XCTAssertEqual(PinInputView.clean("12a3４56789"), "123567")
        XCTAssertEqual(PinInputView.clean(""), "")
        XCTAssertEqual(PinInputView.progress(label: "支付密码", count: 3, strings: zh), "支付密码，已输入 3 位")
    }

    func testActionPanelFillsTheRowWithLoadingTiles() {
        XCTAssertEqual(FlareComposerActionPanel.loadingSlots(after: 7, columns: 4), 1)
        XCTAssertEqual(FlareComposerActionPanel.loadingSlots(after: 8, columns: 4), 4, "a full row gets one more row")
    }

    func testProtectedMediaThumbnailsComeThreeToARow() {
        let items = (1...4).map { PluginProtectedItem(id: "m\($0)", label: "M\($0)") }
        XCTAssertEqual(PluginProtectedMediaBlockView.rows(items).map { $0.map(\.id) }, [["m1", "m2", "m3"], ["m4"]])
        XCTAssertTrue(PluginProtectedMediaBlockView.rows([]).isEmpty)
    }
}
