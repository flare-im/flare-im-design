import XCTest
@testable import FlareIMUI

final class MessageActionSheetTests: XCTestCase {
    private let reply = FlareMessageMenuEntry(id: "reply", label: "回复", icon: "reply", group: .primary)
    private let pin = FlareMessageMenuEntry(id: "pin", label: "置顶", icon: "pin")
    private let delete = FlareMessageMenuEntry(id: "delete", label: "删除", icon: "delete", group: .destructive, enabled: false)

    func testGroupsRenderInContractOrderAndDropEmptyGroups() {
        let groups = messageMenuGroups([delete, pin, reply]).map { $0.map(\.id) }
        XCTAssertEqual(groups, [["reply"], ["pin"], ["delete"]])
        XCTAssertEqual(messageMenuGroups([pin]).map { $0.map(\.id) }, [["pin"]])
        XCTAssertTrue(messageMenuGroups([]).isEmpty)
    }

    func testEntryDefaultsAndStrings() {
        XCTAssertEqual(pin.group, .organize)
        XCTAssertTrue(pin.enabled)
        XCTAssertEqual(FlareStrings().messageActionSheetLabel, "消息操作")
        XCTAssertEqual(FlareStrings().messageActionSheetEmpty, "暂无可用操作")
        _ = MessageActionSheetView(actions: [reply, pin, delete], reactions: ["👍", "❤️"]).body
        _ = MessageActionSheetView().body
        _ = MessageActionSheetView(availability: everything, hiddenActions: ["preview"]).body
    }

    private let everything = FlareMessageActionAvailability(
        canReply: true, canForward: true, canCopy: true, canEdit: true, canDelete: true, canRecall: true,
        canPin: true, canUnpin: true, canReact: true, canMultiSelect: true, canSave: true, canResend: true)

    /// Every availability check below is read on a text message, the body copy applies to; K2 covers
    /// the bodies that have no text.
    private func ids(_ availability: FlareMessageActionAvailability, hidden: Set<String> = [],
                     content: FlareMessageContent? = FlareTextContent("周五评审挪到三点")) -> [String] {
        messageMenuActions(availability, strings: FlareStrings(), hidden: hidden, content: content).map(\.id)
    }

    func testStandardActionsFollowTheCoreFlagsInContractOrder() {
        XCTAssertEqual(ids(everything), ["reply", "forward", "recall", "resend", "multiSelect", "mark", "pin",
                                         "pinSelf", "unpin", "copy", "preview", "save", "edit", "delete"])
        XCTAssertTrue(ids(FlareMessageActionAvailability()).isEmpty)
    }

    func testEachStandardActionHangsOnItsCoreFlag() {
        XCTAssertEqual(ids(.init(canDelete: true)), ["mark", "delete"])
        XCTAssertEqual(ids(.init(canPin: true)), ["pin", "pinSelf"])
        XCTAssertEqual(ids(.init(canMultiSelect: true)), ["multiSelect", "preview"])
        XCTAssertEqual(ids(.init(canUnpin: true)), ["unpin"])
        XCTAssertEqual(ids(.init(canResend: true)), ["resend"])
        XCTAssertTrue(ids(.init(canReact: true)).isEmpty)
    }

    func testGroupsAndLabelsBelongToTheKit() {
        let entries = messageMenuActions(everything, strings: FlareStrings(), content: FlareTextContent("hi"))
        XCTAssertEqual(entries.filter { $0.group == .primary }.map(\.id), ["reply", "forward", "recall", "resend"])
        XCTAssertEqual(entries.filter { $0.group == .destructive }.map(\.id), ["delete"])
        XCTAssertEqual(entries.first { $0.id == "recall" }?.label, "撤回")
        var english = FlareStrings()
        english.messageActionRecall = "Recall"
        XCTAssertEqual(messageMenuActions(everything, strings: english).first { $0.id == "recall" }?.label, "Recall")
    }

    func testHiddenActionsAreLeftOut() {
        let shown = ids(everything, hidden: ["multiSelect", "preview"])
        XCTAssertFalse(shown.contains("multiSelect"))
        XCTAssertFalse(shown.contains("preview"))
        XCTAssertEqual(shown.count, 12)
    }

    // K2: the core sets canCopy from its preview text, which falls back to "[图片]" for media, so the
    // sheet reads the body instead — an image message must not offer a copy that copies nothing.
    func testCopyNeedsABodyWithText() {
        XCTAssertFalse(ids(everything, content: FlareImageContent(url: "https://flare.im/a.png")).contains("copy"))
        XCTAssertFalse(ids(everything, content: FlareAudioContent(url: "https://flare.im/a.m4a", durationSec: 3)).contains("copy"))
        XCTAssertFalse(ids(everything, content: FlareFileContent(name: "a.pdf", url: "https://flare.im/a.pdf")).contains("copy"))
        XCTAssertFalse(ids(everything, content: nil).contains("copy"))
        XCTAssertFalse(ids(everything, content: FlareTextContent("   ")).contains("copy"))
        XCTAssertTrue(ids(everything, content: FlareTextContent("周五评审挪到三点")).contains("copy"))
        // A body with text still needs the core's permission.
        XCTAssertFalse(ids(.init(canCopy: false), content: FlareTextContent("hi")).contains("copy"))
    }

    func testCopyableTextKeepsTheBodyAsWritten() {
        XCTAssertEqual(flareCopyableText(FlareTextContent(" 周五评审 ")), " 周五评审 ")
        XCTAssertNil(flareCopyableText(FlareTextContent("\n ")))
        XCTAssertNil(flareCopyableText(nil))
        XCTAssertNil(flareCopyableText(FlareImageContent(url: "https://flare.im/a.png")))
    }

    func testAvailabilityReadsTheCoreJson() {
        let parsed = FlareMessageActionAvailability(json: ["canReply": true, "canPin": false, "canCopy": "true", "unknown": true])
        XCTAssertEqual(parsed, FlareMessageActionAvailability(canReply: true))
        XCTAssertEqual(FlareMessageActionAvailability(json: [:]), FlareMessageActionAvailability())
    }
}
