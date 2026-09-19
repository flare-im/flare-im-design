import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// A poll's options and a task's checkbox are controls in a timeline only when the host takes the intent (R9-B8):
/// `onVote` with the option's index, `onTaskToggle` with the state the user asks for. Without a handler they are
/// read-only, so nothing looks actionable that cannot act.
final class PollTaskIntentTests: XCTestCase {
    private let poll = FlarePollContent(id: "vote-1", title: "周五聚餐", options: ["火锅", "烤肉", "日料"])
    private let openTask = FlareTaskContent(id: "task-1", title: "提交周报", detail: "今天 18:00", done: false)
    private let doneTask = FlareTaskContent(id: "task-2", title: "订会议室", done: true)

    @MainActor
    func testWithoutHandlersPollsAndTasksAreReadOnly() throws {
        XCTAssertTrue(try MessageContentView(content: poll).inspect().findAll(ViewType.Button.self).isEmpty)
        XCTAssertTrue(try MessageContentView(content: openTask).inspect().findAll(ViewType.Button.self).isEmpty)
    }

    @MainActor
    func testAVoteNamesTheTappedOption() throws {
        var votes: [Int] = []
        let body = MessageContentView(content: poll, onVote: { votes.append($0) })
        let options = try body.inspect().find(VoteMessageView.self).findAll(ViewType.Button.self)
        XCTAssertEqual(options.count, 3)
        try options[1].tap()
        try options[2].tap()
        XCTAssertEqual(votes, [1, 2])
        // Each option is a full-size target.
        XCTAssertGreaterThanOrEqual(try options[0].labelView().flexFrame().minHeight ?? 0, FlareSizes.touchTarget)
    }

    @MainActor
    func testATaskToggleAsksForTheOtherState() throws {
        var asked: [Bool] = []
        try MessageContentView(content: openTask, onTaskToggle: { asked.append($0) }).inspect()
            .find(TaskMessageView.self).find(ViewType.Button.self).tap()
        try MessageContentView(content: doneTask, onTaskToggle: { asked.append($0) }).inspect()
            .find(TaskMessageView.self).find(ViewType.Button.self).tap()
        XCTAssertEqual(asked, [true, false])
    }

    @MainActor
    func testTheBubbleAndTheListHandTheHostTheMessage() throws {
        let message = FlareMessageData(id: "m1", senderId: "ann", senderName: "Ann", content: poll)
        var votes: [String] = []
        let bubble = MessageBubbleView(message: message, currentUserId: "me",
                                       onVote: { votes.append("\($0.id):\($1)") })
        try XCTUnwrap(bubble.inspect().find(VoteMessageView.self).findAll(ViewType.Button.self).first).tap()
        // In multi-select mode a tap selects the row, so the poll is not a control.
        let selecting = MessageBubbleView(message: message, currentUserId: "me", multiSelectMode: true,
                                          onToggleSelect: { _ in }, onVote: { votes.append("selecting \($0.id):\($1)") })
        XCTAssertTrue(try selecting.inspect().find(VoteMessageView.self).findAll(ViewType.Button.self).isEmpty)

        let task = FlareMessageData(id: "m2", senderId: "ann", senderName: "Ann", content: openTask)
        var toggles: [String] = []
        let list = MessageListView(messages: [message, task], currentUserId: "me",
                                   onVote: { votes.append("list \($0.id):\($1)") },
                                   onTaskToggle: { toggles.append("\($0.id):\($1)") })
        let listOptions = try list.inspect().find(VoteMessageView.self).findAll(ViewType.Button.self)
        XCTAssertEqual(listOptions.count, 3, "the list hands its vote handler to every poll")
        if listOptions.count == 3 { try listOptions[2].tap() }
        try list.inspect().find(TaskMessageView.self).find(ViewType.Button.self).tap()
        XCTAssertEqual(votes, ["m1:0", "list m1:2"])
        XCTAssertEqual(toggles, ["m2:true"])
    }
}
