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

    func testJoinAndCallBackReachTheHost() throws {
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
        try callBack.inspect().find(ViewType.Button.self).tap()
        XCTAssertEqual(callBacks, 1)
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

    func testCallViewMinimizesOnlyWhenTheHostCan() throws {
        let without = CallView(peerName: "Ada", mode: .audio, state: .connected)
        XCTAssertThrowsError(try without.inspect().find(viewWithAccessibilityLabel: zh.callMinimize))
        var minimized = 0
        let with = CallView(peerName: "Ada", mode: .audio, state: .connected, onMinimize: { minimized += 1 })
        try with.inspect().find(viewWithAccessibilityLabel: zh.callMinimize).button().tap()
        XCTAssertEqual(minimized, 1)
    }
}
