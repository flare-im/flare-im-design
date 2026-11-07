import Foundation
import XCTest
@testable import FlareIMUI

/// The shared connection notice table (`spec/connection-notice-vectors.json`): statuses over time in, what the
/// notice shows at each moment out. The Vue, Flutter and Compose kits run the same file.
final class ConnectionNoticeTests: XCTestCase {
    private struct Table: Decodable {
        struct Thresholds: Decodable { let syncingDelayMs: Int64; let switchingDelayMs: Int64; let reconnectingMinShownMs: Int64 }
        let thresholds: Thresholds
        let cases: [Vector]
    }
    private struct Vector: Decodable { let name: String; let steps: [Step] }
    private struct Step: Decodable { let at: Int64; let status: Status?; let expect: Expect }
    private struct Status: Decodable {
        let phase: String
        let quality: String?
        let progress: Double?
        let nextRetryAt: Int64?
        let attempt: Int?
        let reason: String?
        let developmentMode: Bool?
    }
    private struct Expect: Decodable {
        let visible: Bool
        let text: String?
        let tone: String?
        let pulse: Bool?
        let countdown: Int?
        let progress: Double?
        let action: String?
        let badge: Bool?
        let next: Int64?
    }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        return try JSONDecoder().decode(
            Table.self, from: Data(contentsOf: root.appendingPathComponent("spec/connection-notice-vectors.json")))
    }

    private func status(_ s: Status) throws -> FlareConnectionStatus {
        FlareConnectionStatus(
            phase: try XCTUnwrap(FlareConnectionPhase(rawValue: s.phase), "unknown phase \(s.phase)"),
            quality: try s.quality.map { try XCTUnwrap(FlareConnectionQuality(rawValue: $0)) },
            progress: s.progress, nextRetryAt: s.nextRetryAt, attempt: s.attempt,
            reason: s.reason, developmentMode: s.developmentMode ?? false)
    }

    /// The SDK's reason is open text: switching carries its own reasons, and an actionRequired reason the kit does
    /// not explain reads as expired, the same as none.
    func testAnyReasonTextIsAcceptedAndOnlyTheActionReasonsAreExplained() {
        XCTAssertEqual(FlareConnectionStatus(phase: .actionRequired, reason: "kicked").actionReason, .kicked)
        XCTAssertNil(FlareConnectionStatus(phase: .switching, reason: "failure").actionReason)
        XCTAssertNil(FlareConnectionStatus(phase: .actionRequired).actionReason)

        let switching = FlareConnectionNoticeTracker()
        switching.observe(FlareConnectionStatus(phase: .switching, reason: "drain"), nowMs: 0)
        XCTAssertFalse(switching.present(nowMs: 1999).visible)
        let switched = switching.present(nowMs: 2000)
        XCTAssertEqual(switched.text, .switching)
        XCTAssertNil(switched.action)

        for reason in ["somethingNew", ""] {
            let tracker = FlareConnectionNoticeTracker()
            tracker.observe(FlareConnectionStatus(phase: .actionRequired, reason: reason), nowMs: 0)
            let model = tracker.present(nowMs: 0)
            XCTAssertEqual(model.text, .expired, reason)
            XCTAssertEqual(model.tone, .danger, reason)
            XCTAssertEqual(model.action, .signIn, reason)
        }
    }

    func testTheThresholdsAreTheSharedOnes() throws {
        let table = try table()
        XCTAssertEqual(FlareConnectionNoticeTracker.syncingDelayMs, table.thresholds.syncingDelayMs)
        XCTAssertEqual(FlareConnectionNoticeTracker.switchingDelayMs, table.thresholds.switchingDelayMs)
        XCTAssertEqual(FlareConnectionNoticeTracker.reconnectingMinShownMs, table.thresholds.reconnectingMinShownMs)
        XCTAssertGreaterThanOrEqual(table.cases.count, 23, "the shared table lost cases")
    }

    func testEveryMomentShowsWhatTheSharedTableSays() throws {
        for vector in try table().cases {
            let tracker = FlareConnectionNoticeTracker()
            for (index, step) in vector.steps.enumerated() {
                if let s = step.status { tracker.observe(try status(s), nowMs: step.at) }
                let model = tracker.present(nowMs: step.at)
                let label = "\(vector.name) — step \(index) at \(step.at)"
                XCTAssertEqual(model.visible, step.expect.visible, label)
                XCTAssertEqual(model.text?.rawValue, step.expect.text, label)
                XCTAssertEqual(model.tone?.rawValue, step.expect.tone, label)
                XCTAssertEqual(model.pulse, step.expect.pulse ?? false, label)
                XCTAssertEqual(model.countdown, step.expect.countdown, label)
                XCTAssertEqual(model.progress, step.expect.progress, label)
                XCTAssertEqual(model.action?.rawValue, step.expect.action, label)
                XCTAssertEqual(model.badge, step.expect.badge ?? false, label)
                XCTAssertEqual(tracker.nextChangeAt(nowMs: step.at), step.expect.next, label)
            }
        }
    }

    func testTheBannerSaysTheMessageThenTheCountdownOrTheProgress() {
        let zh = FlareStrings()
        XCTAssertEqual(FlareConnectionNoticeModel(visible: true, text: .reconnecting, countdown: 5).bannerText(zh),
                       "连接已断开，正在重连… 5 秒后重试")
        XCTAssertEqual(FlareConnectionNoticeModel(visible: true, text: .syncing, progress: 0.426).bannerText(zh),
                       "正在同步消息… 43%")
        XCTAssertEqual(FlareConnectionNoticeModel(visible: true, text: .kicked).bannerText(zh), "已在其他设备登录")
        XCTAssertEqual(FlareConnectionNoticeModel(visible: true, text: .reconnecting, countdown: 5).message(zh),
                       "连接已断开，正在重连…", "the countdown is not part of what is announced")
        XCTAssertEqual(FlareConnectionNoticeModel.hidden.bannerText(zh), "")
        XCTAssertEqual(FlareConnectionNoticeAction.retry.label(zh), "立即重试")
        XCTAssertEqual(FlareConnectionNoticeAction.update.label(zh), "立即更新")
        let en = FlareStrings.english
        XCTAssertEqual(FlareConnectionNoticeModel(visible: true, text: .reconnecting, countdown: 1).bannerText(en),
                       "Connection lost. Reconnecting… Retrying in 1s")
        XCTAssertEqual(FlareConnectionNoticeAction.signIn.label(en), "Sign in again")
    }

    func testEveryMessageAndActionHasChineseAndEnglishCopy() {
        let texts: [FlareConnectionNoticeText] = [.connecting, .syncing, .switching, .reconnecting, .waitingForNetwork,
                                                  .serviceUnavailable, .kicked, .expired, .upgradeRequired,
                                                  .tenantUnavailable]
        let actions: [FlareConnectionNoticeAction] = [.retry, .signIn, .update, .diagnose]
        for text in texts {
            let model = FlareConnectionNoticeModel(visible: true, text: text)
            let zh = model.bannerText(FlareStrings())
            let en = model.bannerText(.english)
            XCTAssertNotNil(zh.range(of: "\\p{Han}", options: .regularExpression), "\(text): \(zh)")
            XCTAssertNil(en.range(of: "\\p{Han}", options: .regularExpression), "\(text): \(en)")
        }
        for action in actions {
            XCTAssertNotEqual(action.label(FlareStrings()), action.label(.english), "\(action)")
        }
    }
}
