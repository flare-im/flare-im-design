import Foundation
import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The shared server clock table (spec/server-clock-vectors.json): server now from the device clock and the host's
/// offset, and the plugin countdown and invite cooldown rules run at that now; then the views that judge
/// server-issued instants, drawn with an offset handed in. Every table's size is asserted, so a section the test stops
/// reading is a failure, not silence.
final class ServerClockVectorsTests: XCTestCase {
    private let s = FlareStrings()
    private let en = FlareStrings.english

    private struct Now: Decodable { let id: String; let deviceNowMs: Int64; let offsetMs: Int64?; let expected: Int64 }
    private struct Countdown: Decodable {
        let id: String; let atMs: Int64; let deviceNowMs: Int64; let offsetMs: Int64?
        let zh: String; let en: String; let refreshMs: Int?; let deviceClockZh: String
    }
    private struct Remaining: Decodable { let unit: String; let count: Int }
    private struct Expected: Decodable { let shown: Bool; let enabled: Bool; let remaining: Remaining? }
    private struct Regenerate: Decodable {
        let id: String; let canRegenerate: Bool; let availableAt: Int64; let deviceNowMs: Int64; let offsetMs: Int64?
        let expected: Expected; let deviceClockEnabled: Bool
    }
    private struct Vectors: Decodable { let now: [Now]; let countdown: [Countdown]; let regenerate: [Regenerate] }

    private func vectors() throws -> Vectors {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("spec/server-clock-vectors.json")
        return try JSONDecoder().decode(Vectors.self, from: Data(contentsOf: url))
    }

    private var deviceNow: Int64 { Int64((Date().timeIntervalSince1970 * 1000).rounded(.down)) }

    override func tearDown() {
        FlareServerClock.setOffsetMs(nil)
        super.tearDown()
    }

    func testServerNowIsTheDeviceClockPlusTheOffset() throws {
        let rows = try vectors().now
        XCTAssertEqual(rows.count, 5)
        for v in rows { XCTAssertEqual(FlareServerClock.now(deviceNowMs: v.deviceNowMs, offsetMs: v.offsetMs), v.expected, v.id) }
    }

    func testCountdownsRunOnTheServerClock() throws {
        let rows = try vectors().countdown
        XCTAssertEqual(rows.count, 5)
        for v in rows {
            let now = FlareServerClock.now(deviceNowMs: v.deviceNowMs, offsetMs: v.offsetMs)
            let shown = PluginViewFormat.countdown(atMs: v.atMs, nowMs: now, s)
            XCTAssertEqual(shown.text, v.zh, v.id)
            XCTAssertEqual(shown.refreshMs, v.refreshMs, "\(v.id) refresh")
            XCTAssertEqual(PluginViewFormat.countdown(atMs: v.atMs, nowMs: now, en).text, v.en, "\(v.id) en")
            XCTAssertEqual(PluginViewFormat.countdown(atMs: v.atMs, nowMs: v.deviceNowMs, s).text, v.deviceClockZh, "\(v.id) device")
        }
    }

    func testCooldownsRunOnTheServerClock() throws {
        let rows = try vectors().regenerate
        XCTAssertEqual(rows.count, 2)
        for v in rows {
            let now = FlareServerClock.now(deviceNowMs: v.deviceNowMs, offsetMs: v.offsetMs)
            let a = regenerateAvailability(canRegenerate: v.canRegenerate, availableAt: v.availableAt, now: now)
            XCTAssertEqual(a.shown, v.expected.shown, v.id)
            XCTAssertEqual(a.enabled, v.expected.enabled, v.id)
            XCTAssertEqual(a.remaining?.count, v.expected.remaining?.count, "\(v.id) count")
            XCTAssertEqual(a.remaining?.unit.rawValue, v.expected.remaining?.unit, "\(v.id) unit")
            XCTAssertEqual(regenerateAvailability(canRegenerate: true, availableAt: v.availableAt, now: v.deviceNowMs).enabled,
                           v.deviceClockEnabled, "\(v.id) device")
        }
    }

    func testThePluginViewClockIsTheServerClock() {
        FlareServerClock.setOffsetMs(-300_000)
        XCTAssertEqual(FlareServerClock.offsetMs, -300_000)
        let before = deviceNow
        let now = PluginViewClock.system.now()
        XCTAssertGreaterThanOrEqual(now, before - 300_000)
        XCTAssertLessThanOrEqual(now, deviceNow - 300_000)
        XCTAssertEqual(PluginViewClock(nowMs: 7, utcOffsetMinutes: nil).now(), 7, "a pinned clock stays pinned")
    }

    @MainActor
    func testATimeBlockCountsDownOnTheServerClock() throws {
        // The card closes 30 minutes after the server's now; this device runs 5 minutes fast.
        FlareServerClock.setOffsetMs(-300_000)
        let block = PluginTimeBlock(atMs: deviceNow - 300_000 + 1_800_500, countdown: true)
        XCTAssertNoThrow(try PluginTimeBlockView(block: block, clock: .system).inspect().find(text: "剩余 30:00"))
        FlareServerClock.setOffsetMs(nil)
        XCTAssertNoThrow(try PluginTimeBlockView(block: block, clock: .system).inspect().find(text: "剩余 25:00"))
    }

    @MainActor
    func testTheInviteCooldownRunsOnTheServerClock() throws {
        // Ten minutes of cooldown left on the server; this device runs 15 minutes fast.
        FlareServerClock.setOffsetMs(-15 * 60_000)
        let availableAt = deviceNow - 15 * 60_000 + 10 * 60_000 - 5_000
        let cooling = MyInvitePanelView(code: "AB12CD", canRegenerate: true, regenerateAvailableAt: availableAt)
        XCTAssertNoThrow(try cooling.inspect().find(text: "10 分钟 后可重新生成"))
        FlareServerClock.setOffsetMs(nil)
        let device = MyInvitePanelView(code: "AB12CD", canRegenerate: true, regenerateAvailableAt: availableAt)
        XCTAssertThrowsError(try device.inspect().find(text: "10 分钟 后可重新生成"))
    }
}
