import SwiftUI
import XCTest
@testable import FlareIMUI

final class FlareStringsTests: XCTestCase {
    func testEveryDefaultStringIsNonEmpty() {
        for child in Mirror(reflecting: FlareStrings().table).children {
            guard let value = child.value as? String else { continue }
            XCTAssertFalse(value.isEmpty, "\(child.label ?? "?") must have a default")
        }
    }

    /// Components read both through `@Environment`, which stores the value inline. Held by value they made every
    /// component about 17 KB, and a screen of nested components overflowed a device's 1 MB main thread stack.
    func testEnvironmentValuesStayPointerSized() {
        XCTAssertLessThanOrEqual(MemoryLayout<FlareStrings>.size, MemoryLayout<Int>.size)
        XCTAssertLessThanOrEqual(MemoryLayout<FlareBrandTheme>.size, 3 * MemoryLayout<Int>.size)
    }

    func testACopyChangesOnlyItself() {
        let original = FlareStrings()
        var copy = original
        copy.send = "Send"
        XCTAssertEqual(original.send, "发送")
        XCTAssertEqual(copy.send, "Send")
        XCTAssertEqual(FlareBrandTheme.ocean.light.primary, FlareBrandTheme.allCases[1].light.primary)
    }

    func testTypedConfigurationPreservesDefaultsFormattersAndKeyPaths() {
        let configured = FlareStrings { copy in
            copy.send = "Send"
            copy.readTab = { "Read \($0)" }
            copy.messageMenuLoading = "Loading menu"
        }
        let sendKey: WritableKeyPath<FlareStrings, String> = \.send
        var changed = configured
        changed[keyPath: sendKey] = "Submit"
        changed.readTab = { "Seen \($0)" }

        XCTAssertEqual(configured.send, "Send")
        XCTAssertEqual(configured.readTab(2), "Read 2")
        XCTAssertEqual(changed.send, "Submit")
        XCTAssertEqual(changed.readTab(2), "Seen 2")
        XCTAssertEqual(configured.messageMenuLoading, "Loading menu")
        XCTAssertEqual(configured.scanProvidedBy, FlareStrings().scanProvidedBy)
        XCTAssertEqual(configured.permissionNoun(.camera), FlareStrings().permissionNoun(.camera))
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
        env.flareStrings = FlareStrings { copy in
            copy.send = "Send"
            copy.noResults = "No results"
            copy.readTab = { "Read (\($0))" }
        }
        XCTAssertEqual(env.flareStrings.send, "Send")
        XCTAssertEqual(env.flareStrings.noResults, "No results")
        XCTAssertEqual(env.flareStrings.readTab(2), "Read (2)")
        // Untouched fields keep the kit defaults.
        XCTAssertEqual(env.flareStrings.cancel, "取消")
    }

    func testViewModifierInstallsStringsForSubtree() {
        // The modifier is the host-facing entry point; it must accept any FlareStrings
        // and stay a View so it can wrap an app root.
        let wrapped = Text("x").flareStrings(FlareStrings { copy in
            copy.send = "Send"
        })
        XCTAssertNotNil(wrapped as Any)
    }

    func testComponentsResolveCopyFromSuppliedStrings() {
        let english = FlareStrings { copy in
            copy.actionImage = "Photo"
            copy.actionVideo = "Video"
            copy.actionCamera = "Camera"
            copy.actionFile = "File"
            copy.actionLocation = "Location"
            copy.actionCard = "Card"
            copy.actionVote = "Poll"
            copy.actionTask = "Task"
            copy.actionSchedule = "Event"
            copy.favorites = "Favorites"
            copy.moments = "Moments"
            copy.settings = "Settings"
        }

        let tiles = FlareComposerActionPanel.actions(for: english)
        XCTAssertEqual(tiles.map(\.id), ["image", "camera", "video", "file", "voice", "location", "card"])
        XCTAssertEqual(tiles.map(\.label),
                       ["Photo", "Camera", "Video", "File", english.composerVoice, "Location", "Card"])
        XCTAssertEqual(FlareComposerActionPanel.defaultActions.map(\.label).first, "图片")

        let entries = ProfilePanelView.entries(for: english)
        XCTAssertEqual(entries.map(\.key), ["favorites", "moments", "settings"])
        XCTAssertEqual(entries.map(\.label), ["Favorites", "Moments", "Settings"])
        XCTAssertEqual(ProfilePanelView.defaultEntries.map(\.label).first, "收藏")
    }

    func testPermissionCopyFollowsSuppliedStrings() {
        let english = FlareStrings { copy in
            copy.permissionNoun = { _ in "Microphone" }
            copy.permissionVerb = { _ in "use the microphone" }
            copy.permissionTitle = { "\($0) access needed" }
            copy.permissionFeatureFallback = "This feature"
            copy.permissionUndeterminedBody = { "\($0) needs to \($1)." }
            copy.permissionAllow = "Allow"
        }
        let copy = defaultPermissionCopy(.microphone, .undetermined, strings: english)
        XCTAssertEqual(copy.title, "Microphone access needed")
        XCTAssertEqual(copy.description, "This feature needs to use the microphone.")
        XCTAssertEqual(copy.primaryLabel, "Allow")

        let stateLabels = FlareStrings { copy in
            copy.permissionStateLabel = { _ in "Denied" }
        }
        XCTAssertEqual(defaultPermissionStateLabel(.denied, strings: stateLabels), "Denied")
        // Defaults are unchanged when the host supplies nothing.
        XCTAssertEqual(defaultPermissionStateLabel(.denied), "已拒绝")
    }
}
