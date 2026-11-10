import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The call record card against the shared table (`spec/call-record-vectors.json`): the status line, its tone, the
/// one action and the copy in both languages, then the view that draws them. Also the 1:1 call view's minimize.
final class CallRecordComponentsTests: XCTestCase {
    private let zh = FlareStrings()
    private let en = FlareStrings.english

    private struct Vectors: Decodable {
        struct Duration: Decodable { let seconds: Int; let label: String }
        struct Input: Decodable {
            let media: String
            let scope: String
            let state: String
            let endReason: String?
            let durationSeconds: Int?
            let joinedCount: Int?
            let viewerIsInitiator: Bool
            let canJoin: Bool
            let canCallBack: Bool
            let disabled: Bool?
            let busy: Bool?
        }
        struct Text: Decodable { let zh: String; let en: String }
        struct Case: Decodable {
            let id: String
            let input: Input
            let status: String
            let tone: String
            let action: String?
            let actionEnabled: Bool
            let text: Text
        }
        let duration: [Duration]
        let cases: [Case]
    }

    private func vectors() throws -> Vectors {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        return try JSONDecoder().decode(
            Vectors.self, from: Data(contentsOf: root.appendingPathComponent("spec/call-record-vectors.json")))
    }

    private func card(_ input: Vectors.Input, onJoin: (() -> Void)? = {}, onCallBack: (() -> Void)? = {}) -> CallRecordCardView {
        CallRecordCardView(
            media: input.media == "video" ? .video : .audio,
            scope: FlareCallRecordScope(rawValue: input.scope)!,
            state: FlareCallRecordState(rawValue: input.state)!,
            endReason: input.endReason.map { FlareCallEndReason(rawValue: $0)! },
            durationSeconds: input.durationSeconds, joinedCount: input.joinedCount,
            viewerIsInitiator: input.viewerIsInitiator, canJoin: input.canJoin, canCallBack: input.canCallBack,
            disabled: input.disabled ?? false, busy: input.busy ?? false, onJoin: onJoin, onCallBack: onCallBack)
    }

    func testDurationFollowsTheSharedTable() throws {
        let table = try vectors().duration
        XCTAssertGreaterThanOrEqual(table.count, 10, "the shared table lost rows")
        for row in table { XCTAssertEqual(FlareCallRecordRules.durationLabel(row.seconds), row.label, "\(row.seconds)") }
    }

    func testRulesAndCopyFollowTheSharedTable() throws {
        let table = try vectors().cases
        XCTAssertGreaterThanOrEqual(table.count, 30, "the shared table lost cases")
        for vector in table {
            let input = vector.input
            let scope = FlareCallRecordScope(rawValue: input.scope)!
            let state = FlareCallRecordState(rawValue: input.state)!
            let status = FlareCallRecordRules.status(
                scope: scope, state: state, viewerIsInitiator: input.viewerIsInitiator,
                endReason: input.endReason.map { FlareCallEndReason(rawValue: $0)! },
                durationSeconds: input.durationSeconds, joinedCount: input.joinedCount)
            XCTAssertEqual(status.rawValue, vector.status, vector.id)
            XCTAssertEqual(FlareCallRecordRules.tone(status).rawValue, vector.tone, vector.id)
            let action = FlareCallRecordRules.action(scope: scope, state: state, canJoin: input.canJoin,
                                                     canCallBack: input.canCallBack, disabled: input.disabled ?? false)
            XCTAssertEqual(action?.rawValue, vector.action, vector.id)
            let text = { (strings: FlareStrings) in
                FlareCallRecordRules.text(status, strings: strings, joinedCount: input.joinedCount,
                                          durationSeconds: input.durationSeconds)
            }
            XCTAssertEqual(text(zh), vector.text.zh, vector.id)
            XCTAssertEqual(text(en), vector.text.en, vector.id)
        }
    }

    func testCardDrawsEveryCase() throws {
        for vector in try vectors().cases {
            let view = card(vector.input)
            XCTAssertNoThrow(try view.inspect().find(text: vector.text.zh), vector.id)
            let buttons = try view.inspect().findAll(ViewType.Button.self)
            XCTAssertEqual(buttons.count, vector.action == nil ? 0 : 1, vector.id)
            if vector.action != nil {
                XCTAssertEqual(buttons[0].isDisabled(), !vector.actionEnabled, vector.id)
            }
        }
    }

    func testJoinReachesTheHostAndCallBackWaitsForConfirmation() throws {
        var joins = 0, callBacks = 0
        let join = CallRecordCardView(media: .video, scope: .group, state: .ongoing, joinedCount: 4,
                                      viewerIsInitiator: false, canJoin: true, canCallBack: false,
                                      onJoin: { joins += 1 }, onCallBack: { callBacks += 1 })
        XCTAssertNoThrow(try join.inspect().find(text: zh.callRecordJoin))
        try join.inspect().find(ViewType.Button.self).tap()
        XCTAssertEqual(joins, 1)
        XCTAssertEqual(callBacks, 0)

        let callBack = CallRecordCardView(media: .audio, scope: .single, state: .ended, endReason: .completed,
                                          durationSeconds: 75, viewerIsInitiator: true, canJoin: false,
                                          canCallBack: true, onCallBack: { callBacks += 1 })
        XCTAssertNoThrow(try callBack.inspect().find(text: "通话时长 01:15"))
        XCTAssertThrowsError(try callBack.inspect().find(text: zh.callRecordCallBack),
                             "the card itself is the callback control, as on Flutter")
        try callBack.inspect().find(ViewType.Button.self).tap()
        XCTAssertEqual(callBacks, 0, "tapping a record must not start a call before confirmation")
    }

    func testNamesTheMediaAndTheStatus() throws {
        let view = CallRecordCardView(media: .audio, scope: .single, state: .ended, endReason: .missed,
                                      viewerIsInitiator: false, canJoin: false, canCallBack: false)
        let summary = try view.inspect().find(ViewType.VStack.self, where: {
            (try? $0.accessibilityLabel().string()) == zh.callRecordVoice
        })
        XCTAssertEqual(try summary.accessibilityValue().string(), zh.callRecordMissed)
    }

    func testUnavailablePluginKeepsTheRecordAndDropsTheAction() throws {
        let view = CallRecordCardView(media: .audio, scope: .group, state: .ongoing, joinedCount: 2,
                                      viewerIsInitiator: false, canJoin: true, canCallBack: true, disabled: true)
        XCTAssertNoThrow(try view.inspect().find(text: "群通话进行中 · 2 人"))
        XCTAssertTrue(try view.inspect().findAll(ViewType.Button.self).isEmpty)
    }

    func testMissingCallBackHandlerLeavesTheRecordInert() throws {
        let view = CallRecordCardView(media: .audio, scope: .single, state: .ended,
                                      viewerIsInitiator: true, canJoin: false, canCallBack: true)
        XCTAssertTrue(try view.inspect().find(ViewType.Button.self).isDisabled())
    }

    func testCallBackConfirmationCancelsAndConfirmsOnlyOnce() throws {
        var shown = true
        var calls = 0
        let binding = Binding(get: { shown }, set: { shown = $0 })
        let actions = CallRecordConfirmationActions(isPresented: binding, enabled: true) { calls += 1 }
        let buttons = try actions.inspect().findAll(ViewType.Button.self)
        try buttons[0].tap()
        XCTAssertFalse(shown)
        XCTAssertEqual(calls, 0)
        // A queued confirm from a dismissed dialog cannot start a call.
        try buttons[1].tap()
        XCTAssertEqual(calls, 0)
        shown = true
        try buttons[1].tap()
        try buttons[1].tap()
        XCTAssertFalse(shown)
        XCTAssertEqual(calls, 1)

        shown = true
        let unavailable = CallRecordConfirmationActions(isPresented: binding, enabled: false) { calls += 1 }
        XCTAssertTrue(try unavailable.inspect().findAll(ViewType.Button.self)[1].isDisabled())
        XCTAssertEqual(calls, 1)
    }

    func testCallViewMinimizesOnlyWhenTheHostCan() throws {
        let without = CallView(peerName: "Ada", mode: .audio, state: .connected)
        XCTAssertThrowsError(try without.inspect().find(viewWithAccessibilityLabel: zh.callMinimize))
        var minimized = 0
        let with = CallView(peerName: "Ada", mode: .audio, state: .connected, onMinimize: { minimized += 1 })
        try with.inspect().find(viewWithAccessibilityLabel: zh.callMinimize).button().tap()
        XCTAssertEqual(minimized, 1)
    }
}

#if os(macOS)
import AppKit

final class CallRecordLayoutTests: XCTestCase {
    @MainActor
    func testShortRecordFitsItsContentAndLongRecordWrapsWithinAvailableWidth() {
        _ = NSApplication.shared
        let record = CallRecordCardView(media: .video, scope: .single, state: .ended,
                                        durationSeconds: 30, viewerIsInitiator: true,
                                        canJoin: false, canCallBack: true, onCallBack: {})
        let host = NSHostingController(rootView: record)
        let roomy = host.sizeThatFits(in: CGSize(width: 400, height: 1_000))
        let narrow = host.sizeThatFits(in: CGSize(width: 140, height: 1_000))
        XCTAssertLessThan(roomy.width, FlareSizes.componentRichCardWidth - 20,
                          "short records must not stretch their white surface to the card cap")
        XCTAssertLessThanOrEqual(narrow.width, 140)
        XCTAssertGreaterThan(narrow.height, roomy.height, "the status wraps instead of overflowing")
    }

    @MainActor
    func testQuotedCompactCardStillFitsAvailableWidth() {
        _ = NSApplication.shared
        let quote = AnyView(Text(String(repeating: "Long quote ", count: 20))
            .lineLimit(1).frame(maxWidth: .infinity, alignment: .leading))
        let card = FlareMessageCardShell(padded: false, fillWidth: false) {
            Text("Short record").padding(FlareSizes.spacingSm)
        }.environment(\.flareMessageCardQuote, quote)
        let size = NSHostingController(rootView: card).sizeThatFits(in: CGSize(width: 160, height: 1_000))
        XCTAssertLessThanOrEqual(size.width, 160)
        XCTAssertGreaterThan(size.height, 40)
    }

    @MainActor
    func testFullWidthCardsKeepTheirCapAndCallBackMeetsTheTouchTarget() {
        _ = NSApplication.shared
        let full = FlareMessageCardShell(padded: true) { Text("Contact") }
        let fullHost = NSHostingController(rootView: full)
        XCTAssertEqual(fullHost.sizeThatFits(in: CGSize(width: 500, height: 1_000)).width,
                       FlareSizes.componentRichCardWidth, accuracy: 0.5)
        XCTAssertEqual(fullHost.sizeThatFits(in: CGSize(width: 160, height: 1_000)).width, 160, accuracy: 0.5)

        let record = CallRecordCardView(media: .audio, scope: .single, state: .ended,
                                        durationSeconds: 754, viewerIsInitiator: false,
                                        canJoin: false, canCallBack: true, onCallBack: {})
        let regular = NSHostingController(rootView: record)
            .sizeThatFits(in: CGSize(width: 200, height: 1_000))
        XCTAssertGreaterThanOrEqual(regular.height, FlareSizes.touchTarget)
    }
}
#endif

#if os(iOS)
import UIKit

final class CallRecordDynamicTypeLayoutTests: XCTestCase {
    @MainActor
    func testLargeTextGrowsWithoutLeavingTheTimeline() {
        let record = CallRecordCardView(media: .audio, scope: .single, state: .ended,
                                        durationSeconds: 754, viewerIsInitiator: false,
                                        canJoin: false, canCallBack: true, onCallBack: {})
        let regular = UIHostingController(rootView: record)
            .sizeThatFits(in: CGSize(width: 200, height: 1_000))
        let large = UIHostingController(rootView: record.dynamicTypeSize(.accessibility3))
            .sizeThatFits(in: CGSize(width: 200, height: 1_000))
        XCTAssertLessThanOrEqual(large.width, 200)
        XCTAssertGreaterThan(large.height, regular.height)
    }
}
#endif
