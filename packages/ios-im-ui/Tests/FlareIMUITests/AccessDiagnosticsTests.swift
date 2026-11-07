import Foundation
import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The shared diagnostics table (`spec/access-diagnostics-vectors.json`): what the host read in, what the page shows
/// out. The Vue, Flutter and Compose kits run the same file.
final class AccessDiagnosticsTests: XCTestCase {
    private struct Table: Decodable {
        struct Thresholds: Decodable { let rttGoodBelowMs: Int; let rttPoorAboveMs: Int }
        struct Rtt: Decodable { let rttMs: Double?; let shownMs: Int?; let grade: String? }
        struct ProtocolRow: Decodable { let `protocol`: String?; let label: String? }
        struct Source: Decodable { let source: String?; let kind: String; let detail: String? }
        struct Answer: Decodable { let outcome: String?; let code: String?; let text: String?; let tone: String? }
        let thresholds: Thresholds
        let rtt: [Rtt]
        let protocols: [ProtocolRow]
        let sources: [Source]
        let refresh: [Answer]
        let `import`: [Answer]
        let export: [Answer]
        let points: [PointVector]
        let cases: [Vector]
    }
    private struct Ack: Decodable { let accessPointId: String?; let accessPointMismatch: Bool? }
    private struct Recovering: Decodable { let rounds: Int; let nextRoundAtMs: Int64? }
    private struct Status: Decodable {
        let loaded: Bool
        let serial: Int64?
        let source: String?
        let stale: Bool?
        let developmentMode: Bool?
        let regionId: String?
        let accessPointId: String?
        let `protocol`: String?
        let connectAck: Ack?
        let recovering: Recovering?
    }
    private struct Point: Decodable {
        let accessPointId: String
        let regionId: String?
        let host: String?
        let status: String
        let rttMs: Double?
        let breaker: String
        let pinned: Bool
        let current: Bool
    }
    private struct Notice: Decodable, Equatable { let text: String; let tone: String; let pulse: Bool }
    private struct Region: Decodable, Equatable { let regionId: String?; let accessPoints: [String] }
    private struct Expect: Decodable {
        let state: String
        let notices: [Notice]
        let manifest: String
        let rttMs: Int?
        let rttGrade: String?
        let reportedAccessPointId: String?
        let recoveryRounds: Int?
        let regions: [Region]
    }
    private struct Vector: Decodable {
        let name: String
        let status: Status?
        let accessPoints: [Point]
        let expect: Expect
    }
    private struct RowExpect: Decodable {
        let status: String
        let statusTone: String
        let breaker: String?
        let breakerTone: String?
        let pin: String?
    }
    private struct PointVector: Decodable { let name: String; let point: Point; let expect: RowExpect }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        return try JSONDecoder().decode(
            Table.self, from: Data(contentsOf: root.appendingPathComponent("spec/access-diagnostics-vectors.json")))
    }

    private func status(_ s: Status?) -> FlareAccessStatus? {
        s.map {
            FlareAccessStatus(
                loaded: $0.loaded, serial: $0.serial, source: $0.source, stale: $0.stale ?? false,
                developmentMode: $0.developmentMode ?? false, regionId: $0.regionId, accessPointId: $0.accessPointId,
                protocol: $0.protocol,
                connectAck: $0.connectAck.map {
                    FlareAccessConnectAck(accessPointId: $0.accessPointId, accessPointMismatch: $0.accessPointMismatch ?? false)
                },
                recovering: $0.recovering.map { FlareAccessRecovering(rounds: $0.rounds, nextRoundAtMs: $0.nextRoundAtMs) })
        }
    }

    private func point(_ p: Point) -> FlareAccessPoint {
        FlareAccessPoint(accessPointId: p.accessPointId, regionId: p.regionId, host: p.host, status: p.status,
                         rttMs: p.rttMs, breaker: p.breaker, pinned: p.pinned, current: p.current)
    }

    func testTheThresholdsAreTheSharedOnes() throws {
        let table = try table()
        XCTAssertEqual(FlareAccessRttThresholds.goodBelowMs, table.thresholds.rttGoodBelowMs)
        XCTAssertEqual(FlareAccessRttThresholds.poorAboveMs, table.thresholds.rttPoorAboveMs)
        XCTAssertGreaterThanOrEqual(table.cases.count, 14)
    }

    func testEveryCaseShowsWhatTheSharedTableSays() throws {
        for vector in try table().cases {
            let model = flareAccessDiagnostics(status(vector.status), accessPoints: vector.accessPoints.map(point))
            let want = vector.expect
            XCTAssertEqual(model.state.rawValue, want.state, vector.name)
            XCTAssertEqual(model.notices.map { Notice(text: $0.text.rawValue, tone: $0.tone.rawValue, pulse: $0.pulse) },
                           want.notices, vector.name)
            XCTAssertEqual(model.manifest.rawValue, want.manifest, vector.name)
            XCTAssertEqual(model.rtt.shownMs, want.rttMs, vector.name)
            XCTAssertEqual(model.rtt.grade?.rawValue, want.rttGrade, vector.name)
            XCTAssertEqual(model.reportedAccessPointId, want.reportedAccessPointId, vector.name)
            XCTAssertEqual(model.recoveryRounds, want.recoveryRounds, vector.name)
            XCTAssertEqual(model.regions.map { Region(regionId: $0.regionId, accessPoints: $0.accessPoints.map(\.accessPointId)) },
                           want.regions, vector.name)
        }
    }

    func testEveryRowReadsWhatTheSharedTableSays() throws {
        for vector in try table().points {
            let row = flareAccessPointRow(point(vector.point))
            XCTAssertEqual(row.status.rawValue, vector.expect.status, vector.name)
            XCTAssertEqual(row.statusTone.rawValue, vector.expect.statusTone, vector.name)
            XCTAssertEqual(row.breaker?.rawValue, vector.expect.breaker, vector.name)
            XCTAssertEqual(row.breakerTone?.rawValue, vector.expect.breakerTone, vector.name)
            XCTAssertEqual(row.pin?.rawValue, vector.expect.pin, vector.name)
        }
    }

    func testLatencyIsGradedOnTheWholeMillisecondsItShows() throws {
        for row in try table().rtt {
            let rtt = flareAccessRtt(row.rttMs)
            XCTAssertEqual(rtt.shownMs, row.shownMs, "\(String(describing: row.rttMs))")
            XCTAssertEqual(rtt.grade?.rawValue, row.grade, "\(String(describing: row.rttMs))")
        }
        XCTAssertNil(flareAccessRtt(.nan).grade)
        XCTAssertNil(flareAccessRtt(.infinity).grade)
    }

    func testTheProtocolIsNamed() throws {
        for row in try table().protocols { XCTAssertEqual(flareAccessProtocolLabel(row.protocol), row.label) }
    }

    func testTheSourceReadsApart() throws {
        for row in try table().sources {
            let source = flareAccessSource(row.source)
            XCTAssertEqual(source.kind.rawValue, row.kind, row.source ?? "nil")
            XCTAssertEqual(source.detail, row.detail, row.source ?? "nil")
        }
    }

    func testTheActionsAreAnswered() throws {
        let table = try table()
        for row in table.refresh {
            let feedback = flareAccessRefreshFeedback(row.outcome)
            XCTAssertEqual(feedback?.text.rawValue, row.text, row.outcome ?? "nil")
            XCTAssertEqual(feedback?.tone.rawValue, row.tone, row.outcome ?? "nil")
        }
        for row in table.import {
            let feedback = flareAccessImportFeedback(row.outcome, code: row.code)
            XCTAssertEqual(feedback?.text.rawValue, row.text, "\(row.outcome ?? "nil") \(row.code ?? "nil")")
            XCTAssertEqual(feedback?.tone.rawValue, row.tone, "\(row.outcome ?? "nil") \(row.code ?? "nil")")
        }
        for row in table.export {
            let feedback = flareAccessExportFeedback(row.outcome)
            XCTAssertEqual(feedback?.text.rawValue, row.text, row.outcome ?? "nil")
            XCTAssertEqual(feedback?.tone.rawValue, row.tone, row.outcome ?? "nil")
        }
    }

    func testTheWordsReadInBothLanguages() {
        let zh = FlareStrings()
        let en = FlareStrings.english
        XCTAssertEqual(FlareAccessNoticeText.serviceUnavailable.label(zh), "服务暂时不可用，正在自动恢复…")
        XCTAssertEqual(FlareAccessNoticeText.healthy.label(en), "Connection is healthy")
        XCTAssertEqual(flareAccessRtt(86).label(zh), "86 ms · 良好")
        XCTAssertEqual(flareAccessRtt(420).label(en), "420 ms · Poor")
        XCTAssertNil(flareAccessRtt(nil).label(zh))
        XCTAssertEqual(flareAccessSourceLabel("https:https://cfg.example.org/flare/", strings: zh), "镜像 cfg.example.org")
        XCTAssertEqual(flareAccessSourceLabel("wellKnown:ap-1", strings: en), "Access point ap-1")
        XCTAssertEqual(FlareAccessImportText.rollback.label(en), "This link is older than the lines on this device.")
    }

    private let healthy = FlareAccessStatus(
        loaded: true, serial: 42, source: "https:https://cfg-b.other-cloud.net/flare/v1/abc/", regionId: "sg",
        accessPointId: "ap-sg-1", protocol: "quic")
    private let lines = [
        FlareAccessPoint(accessPointId: "ap-sg-1", regionId: "sg", host: "sg1.example.net", status: "active",
                         rttMs: 86, breaker: "closed", current: true),
        FlareAccessPoint(accessPointId: "ap-sg-2", regionId: "sg", status: "active", rttMs: 420, breaker: "open"),
        FlareAccessPoint(accessPointId: "ap-de-1", regionId: "de", status: "draining", breaker: "closed"),
    ]

    func testTheViewDrawsTheCurrentLineAndTheLinesByRegion() throws {
        let view = try AccessDiagnosticsView(status: healthy, accessPoints: lines).inspect()
        XCTAssertNoThrow(try view.find(text: "线路正常"))
        XCTAssertNoThrow(try view.find(text: "QUIC"))
        XCTAssertNoThrow(try view.find(text: "镜像 cfg-b.other-cloud.net"))
        XCTAssertNoThrow(try view.find(text: "de"))
        XCTAssertNoThrow(try view.find(text: "有效"))
    }

    func testAPinIsOfferedOnlyWhereItCanHoldAndTheHostHandlesIt() throws {
        var pinned: [String] = []
        let view = AccessDiagnosticsView(status: healthy, accessPoints: lines, onPin: { pinned.append($0) })
        let buttons = try view.inspect().findAll(ButtonView.self)
        XCTAssertEqual(buttons.count, 1, "only the active line whose breaker is closed takes a pin")
        try buttons[0].find(ViewType.Button.self).tap()
        XCTAssertEqual(pinned, ["ap-sg-1"])
        XCTAssertEqual(try AccessDiagnosticsView(status: healthy, accessPoints: lines).inspect().findAll(ButtonView.self).count, 0)
    }

    func testAPinnedLineLetsGo() throws {
        var unpinned = 0
        let point = FlareAccessPoint(accessPointId: "ap-sg-1", status: "active", breaker: "closed", pinned: true, current: true)
        let view = AccessDiagnosticsView(status: healthy, accessPoints: [point], onUnpin: { unpinned += 1 })
        XCTAssertNoThrow(try view.inspect().find(text: "取消固定"))
        try view.inspect().find(ButtonView.self).find(ViewType.Button.self).tap()
        XCTAssertEqual(unpinned, 1)
    }

    func testRecoveringSaysTheKitsWordsAndComesFirst() throws {
        let status = FlareAccessStatus(loaded: true, recovering: FlareAccessRecovering(rounds: 2, nextRoundAtMs: 91_000))
        let view = try AccessDiagnosticsView(status: status).inspect()
        XCTAssertNoThrow(try view.find(text: "服务暂时不可用，正在自动恢复…"))
        XCTAssertNoThrow(try view.find(text: "已尝试恢复轮数"))
        let titles = try view.findAll(ViewType.Text.self).map { try $0.string() }
        XCTAssertLessThan(try XCTUnwrap(titles.firstIndex(of: "恢复工具")), try XCTUnwrap(titles.firstIndex(of: "当前线路")))
    }

    func testAMismatchShowsWhatTheServerReports() throws {
        let status = FlareAccessStatus(loaded: true, accessPointId: "ap-a",
                                       connectAck: FlareAccessConnectAck(accessPointId: "ap-b", accessPointMismatch: true))
        let view = try AccessDiagnosticsView(status: status).inspect()
        XCTAssertNoThrow(try view.find(text: "服务端报告的接入点与当前线路不一致，连接不受影响"))
        XCTAssertNoThrow(try view.find(text: "ap-b"))
    }

    func testTheRecoveryToolsAreDrawnOnlyWhileTheHostHandlesThem() throws {
        let bare = try AccessDiagnosticsView(status: healthy).inspect()
        XCTAssertThrowsError(try bare.find(text: "立即刷新"))
        XCTAssertThrowsError(try bare.find(text: "复制诊断"))
        XCTAssertThrowsError(try bare.find(text: "导入恢复链接"))
        let bound = try AccessDiagnosticsView(status: healthy, refreshOutcome: "upToDate", exportOutcome: "copied",
                                              onRefresh: {}, onImportRecovery: { _ in }, onExportDiagnostics: {}).inspect()
        XCTAssertNoThrow(try bound.find(text: "导入恢复链接"))
        XCTAssertNoThrow(try bound.find(text: "线路已是最新"))
        XCTAssertNoThrow(try bound.find(text: "诊断信息已复制"))
    }
}
