import Foundation
import XCTest
@testable import FlareIMUI

/// The shared invite table (spec/invite-vectors.json), run vector by vector so a rule that drifts on
/// one platform reddens here and nowhere else. Every table's size is asserted, so a section the test
/// stops reading is a failure, not silence.
final class InviteVectorsTests: XCTestCase {
    private struct CheckResult: Decodable { let valid: Bool; let inviterDisplayName: String? }
    private struct Stats: Decodable { let direct: Int; let l2: Int; let l3: Int; let total: Int }
    private struct Normalize: Decodable { let id: String; let raw: String; let length: Int?; let expected: String }
    private struct FieldState: Decodable {
        let id: String; let mode: String; let value: String; let checking: Bool?
        let checkResult: CheckResult?; let error: String?; let disabled: Bool?; let expected: String
    }
    private struct CheckRequest: Decodable {
        let id: String; let value: String; let length: Int?; let mode: String?; let disabled: Bool?; let expected: String?
    }
    private struct DepthRows: Decodable { let id: String; let stats: Stats?; let maxDepthShown: Int; let expected: [String] }
    private struct Remaining: Decodable { let unit: String; let count: Int }
    private struct RegenerateExpected: Decodable { let shown: Bool; let enabled: Bool; let remaining: Remaining? }
    private struct Regenerate: Decodable {
        let id: String; let canRegenerate: Bool; let availableAt: Int64?; let now: Int64; let expected: RegenerateExpected
    }
    private struct JoinedDate: Decodable { let id: String; let year: Int; let month: Int; let day: Int; let expected: String }
    private struct Vectors: Decodable {
        let normalize: [Normalize]; let fieldState: [FieldState]; let checkRequest: [CheckRequest]
        let depthRows: [DepthRows]; let regenerate: [Regenerate]; let joinedDate: [JoinedDate]
    }

    private func vectors() throws -> Vectors {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("spec/invite-vectors.json")
        return try JSONDecoder().decode(Vectors.self, from: Data(contentsOf: url))
    }

    private func mode(_ name: String?) -> FlareInviteCodeMode { FlareInviteCodeMode(rawValue: name ?? "optional") ?? .optional }
    private func result(_ raw: CheckResult?) -> FlareInviteCodeCheckResult? {
        raw.map { FlareInviteCodeCheckResult(valid: $0.valid, inviterDisplayName: $0.inviterDisplayName) }
    }
    private func stats(_ raw: Stats?) -> FlareReferralStats? {
        raw.map { FlareReferralStats(direct: $0.direct, l2: $0.l2, l3: $0.l3, total: $0.total) }
    }

    func testNormalizesLikeTheTableAndIdempotently() throws {
        let rows = try vectors().normalize
        XCTAssertEqual(rows.count, 10)
        for v in rows {
            let once = normalizeInviteCode(v.raw, length: v.length ?? flareInviteCodeDefaultLength)
            XCTAssertEqual(once, v.expected, v.id)
            XCTAssertEqual(normalizeInviteCode(once, length: v.length ?? flareInviteCodeDefaultLength), once, "\(v.id) idempotent")
        }
    }

    func testResolvesTheFieldState() throws {
        let rows = try vectors().fieldState
        XCTAssertEqual(rows.count, 13)
        for v in rows {
            let state = inviteCodeFieldState(mode: mode(v.mode), value: v.value, checking: v.checking ?? false,
                                             checkResult: result(v.checkResult), error: v.error, disabled: v.disabled ?? false)
            XCTAssertEqual(state.rawValue, v.expected, v.id)
        }
    }

    func testAsksForACheckOnlyForACompleteEnabledCode() throws {
        let rows = try vectors().checkRequest
        XCTAssertEqual(rows.count, 6)
        for v in rows {
            XCTAssertEqual(inviteCodeToCheck(value: v.value, length: v.length ?? flareInviteCodeDefaultLength,
                                             mode: mode(v.mode), disabled: v.disabled ?? false), v.expected, v.id)
        }
    }

    func testListsDepthRowsPerVisibility() throws {
        let rows = try vectors().depthRows
        XCTAssertEqual(rows.count, 6)
        for v in rows {
            XCTAssertEqual(referralDepthRows(stats(v.stats), maxDepthShown: v.maxDepthShown).map(\.rawValue), v.expected, v.id)
        }
    }

    func testResolvesRegenerateCooldownRoundingUp() throws {
        let rows = try vectors().regenerate
        XCTAssertEqual(rows.count, 10)
        for v in rows {
            let a = regenerateAvailability(canRegenerate: v.canRegenerate, availableAt: v.availableAt, now: v.now)
            XCTAssertEqual(a.shown, v.expected.shown, "\(v.id) shown")
            XCTAssertEqual(a.enabled, v.expected.enabled, "\(v.id) enabled")
            if let remaining = v.expected.remaining {
                XCTAssertEqual(a.remaining?.unit.rawValue, remaining.unit, "\(v.id) unit")
                XCTAssertEqual(a.remaining?.count, remaining.count, "\(v.id) count")
            } else {
                XCTAssertNil(a.remaining, v.id)
            }
        }
    }

    func testFormatsJoinedDates() throws {
        let rows = try vectors().joinedDate
        XCTAssertEqual(rows.count, 2)
        for v in rows {
            XCTAssertEqual(formatInviteJoinedDate(year: v.year, month: v.month, day: v.day), v.expected, v.id)
        }
    }

    func testCooldownAndDepthCopyComeFromTheStringsTable() {
        let s = FlareStrings()
        XCTAssertEqual(inviteCooldownText(s, FlareInviteCooldown(unit: .minute, count: 15)), "15 分钟 后可重新生成")
        XCTAssertEqual(inviteDepthLabel(s, .total), "团队总数")
        let en = FlareStrings(myInviteCooldown: "You can regenerate in {time}", myInviteUnitDays: "{n} d")
        XCTAssertEqual(inviteCooldownText(en, FlareInviteCooldown(unit: .day, count: 3)), "You can regenerate in 3 d")
    }
}
