import SwiftUI
import XCTest
@testable import FlareIMUI

final class FlareStringsTests: XCTestCase {
    func testEveryDefaultStringIsNonEmpty() {
        for child in Mirror(reflecting: FlareStrings()).children {
            guard let value = child.value as? String else { continue }
            XCTAssertFalse(value.isEmpty, "\(child.label ?? "?") must have a default")
        }
    }

    func testDefaultFormattersProduceCopy() {
        let s = FlareStrings()
        XCTAssertEqual(s.readTab(3), "已读 (3)")
        XCTAssertEqual(s.unreadTab(0), "未读 (0)")
        XCTAssertEqual(s.typingOne("Ada"), "Ada 正在输入…")
        XCTAssertEqual(s.typingMany(4), "4 人正在输入…")
        XCTAssertEqual(s.newMessages(0), "新消息")
        XCTAssertEqual(s.newMessages(7), "7 条新消息")
        XCTAssertEqual(s.memberCount(12), "12 名成员")
        XCTAssertEqual(s.selfSuffix("Ada"), "Ada（我）")
        XCTAssertEqual(s.joinedCount(3, "已接通"), "3 人已加入 · 已接通")
        XCTAssertEqual(s.confirmCount(2), "确定 (2)")
        XCTAssertEqual(s.pollOptionHint(1), "选项 1")
        XCTAssertEqual(s.yearMonth(2026, 9), "2026年9月")
    }

    func testEnvironmentDefaultsAndOverride() {
        var env = EnvironmentValues()
        XCTAssertEqual(env.flareStrings.send, "发送")
        env.flareStrings = FlareStrings(send: "Send", noResults: "No results",
                                        readTab: { "Read (\($0))" })
        XCTAssertEqual(env.flareStrings.send, "Send")
        XCTAssertEqual(env.flareStrings.noResults, "No results")
        XCTAssertEqual(env.flareStrings.readTab(2), "Read (2)")
        // Untouched fields keep the kit defaults.
        XCTAssertEqual(env.flareStrings.cancel, "取消")
    }

    func testViewModifierInstallsStringsForSubtree() {
        // The modifier is the host-facing entry point; it must accept any FlareStrings
        // and stay a View so it can wrap an app root.
        let wrapped = Text("x").flareStrings(FlareStrings(send: "Send"))
        XCTAssertNotNil(wrapped as Any)
    }

    func testComponentsResolveCopyFromSuppliedStrings() {
        let english = FlareStrings(actionImage: "Photo", actionCamera: "Camera", actionFile: "File",
                                   actionLocation: "Location", actionCard: "Card", actionVote: "Poll",
                                   actionTask: "Task", actionSchedule: "Event",
                                   favorites: "Favorites", moments: "Moments", settings: "Settings")

        let tiles = MessageActionSheetView.actions(for: english)
        XCTAssertEqual(tiles.map(\.id), ["image", "camera", "file", "location", "card", "vote", "task", "schedule"])
        XCTAssertEqual(tiles.map(\.label),
                       ["Photo", "Camera", "File", "Location", "Card", "Poll", "Task", "Event"])
        XCTAssertEqual(MessageActionSheetView.defaultActions.map(\.label).first, "图片")

        let entries = ProfilePanelView.entries(for: english)
        XCTAssertEqual(entries.map(\.key), ["favorites", "moments", "settings"])
        XCTAssertEqual(entries.map(\.label), ["Favorites", "Moments", "Settings"])
        XCTAssertEqual(ProfilePanelView.defaultEntries.map(\.label).first, "收藏")
    }

    func testPermissionCopyFollowsSuppliedStrings() {
        let english = FlareStrings(
            permissionNoun: { _ in "Microphone" },
            permissionVerb: { _ in "use the microphone" },
            permissionTitle: { "\($0) access needed" },
            permissionFeatureFallback: "This feature",
            permissionUndeterminedBody: { "\($0) needs to \($1)." },
            permissionAllow: "Allow"
        )
        let copy = defaultPermissionCopy(.microphone, .undetermined, strings: english)
        XCTAssertEqual(copy.title, "Microphone access needed")
        XCTAssertEqual(copy.description, "This feature needs to use the microphone.")
        XCTAssertEqual(copy.primaryLabel, "Allow")

        let stateLabels = FlareStrings(permissionStateLabel: { _ in "Denied" })
        XCTAssertEqual(defaultPermissionStateLabel(.denied, strings: stateLabels), "Denied")
        // Defaults are unchanged when the host supplies nothing.
        XCTAssertEqual(defaultPermissionStateLabel(.denied), "已拒绝")
    }
}
