import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// Batch 2b K8: with a roster the composer's mention key and a typed "@" open the kit mention picker, and a
/// pick writes "@label " into the text. The send stays plain text: the core finds the mentions in it.
final class ComposerMentionTests: XCTestCase {
    private let s = FlareStrings()
    private let ann = MentionCandidate(id: "u-ann", name: "Ann")
    private let bob = MentionCandidate(id: "u-bob", name: "张伟")
    private let everyone = MentionCandidate(id: "__all__", name: "所有人", isEveryone: true)

    func testAnAtTypedAtTheStartOfAWordOpensThePickerAndAnEmailDoesNot() {
        XCTAssertEqual(ComposerView.typedMentionTrigger(previous: "", next: "@"), 0)
        XCTAssertEqual(ComposerView.typedMentionTrigger(previous: "hi ", next: "hi @"), 3)
        XCTAssertEqual(ComposerView.typedMentionTrigger(previous: "你好 ", next: "你好 @"), 3, "offsets count characters")
        XCTAssertEqual(ComposerView.typedMentionTrigger(previous: "hi  there", next: "hi @ there"), 3, "typed in the middle")
        XCTAssertNil(ComposerView.typedMentionTrigger(previous: "mail", next: "mail@"), "inside a word")
        XCTAssertNil(ComposerView.typedMentionTrigger(previous: "hi @", next: "hi "), "a deletion")
        XCTAssertNil(ComposerView.typedMentionTrigger(previous: "abc", next: "xyz@"), "a replacement, not an insertion")
        XCTAssertEqual(ComposerView.typedMentionTrigger(previous: "👍🏽 ", next: "👍🏽 @"), 2, "an emoji is one character")
        XCTAssertNil(ComposerView.typedMentionTrigger(previous: "a ", next: "a 👍🏽@"), "an @ right after an emoji is inside a word")
    }

    func testPickingPutsTheNameOverTheTypedAtOrAtTheEnd() {
        XCTAssertEqual(ComposerView.insertingMention("Ann", into: "hi @ there", at: 3), "hi @Ann  there")
        XCTAssertEqual(ComposerView.insertingMention("Ann", into: "hi", at: nil), "hi @Ann ")
        XCTAssertEqual(ComposerView.insertingMention("Ann", into: "hi ", at: nil), "hi @Ann ")
        XCTAssertEqual(ComposerView.insertingMention("Ann", into: "", at: nil), "@Ann ")
        XCTAssertEqual(ComposerView.insertingMention("Ann", into: "hi x", at: 3), "hi x @Ann ",
                       "the typed @ is gone: the name goes at the end")
    }

    func testTheFlowOpensOnATypedAtOrTheKeyAndAPickWritesTheLabel() {
        var flow = ComposerMentionFlow()
        XCTAssertTrue(flow.textChanged(previous: "hi ", next: "hi @"))
        XCTAssertTrue(flow.open)
        var text = flow.pick(ann, into: "hi @", everyoneLabel: s.everyone)
        XCTAssertEqual(text, "hi @Ann ")
        XCTAssertFalse(flow.open, "picking closes the picker")

        flow.toggleFromKey()
        XCTAssertTrue(flow.open)
        text = flow.pick(bob, into: text + "and", everyoneLabel: s.everyone)
        XCTAssertEqual(text, "hi @Ann and @张伟 ", "the key's pick goes at the end")
    }

    func testTheEveryoneMentionIsWrittenWithTheStringsTableWord() {
        var flow = ComposerMentionFlow()
        flow.toggleFromKey()
        XCTAssertEqual(flow.pick(everyone, into: "", everyoneLabel: s.everyone), "@\(s.everyone) ")
        XCTAssertEqual(s.everyone, "所有人", "a token the core's mention parser recognises")
    }

    func testAnOpenPickerIsNotReopenedByAnotherAt() {
        var flow = ComposerMentionFlow()
        flow.toggleFromKey()
        XCTAssertFalse(flow.textChanged(previous: "", next: "@"))
        XCTAssertNil(flow.trigger, "the key opened it, so a pick goes at the end")
        flow.close()
        XCTAssertFalse(flow.open)
    }

    @MainActor
    func testWithoutCandidatesTheMentionKeyTypesAnAt() throws {
        var text = "hi"
        let binding = Binding(get: { text }, set: { text = $0 })
        let composer = ComposerView(text: binding, onSend: { _ in })
        try composer.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == self.s.composerMention }).tap()
        XCTAssertEqual(text, "hi@")
        XCTAssertThrowsError(try composer.inspect().find(MentionPickerView.self))
    }

    @MainActor
    func testWithCandidatesTheMentionKeyDoesNotTypeAndTheSendIsPlainText() throws {
        var text = "@Ann hello"
        var sent: [String] = []
        let binding = Binding(get: { text }, set: { text = $0 })
        let composer = ComposerView(text: binding, onSend: { sent.append($0) }, mentionCandidates: [ann])
        try composer.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == self.s.composerMention }).tap()
        XCTAssertEqual(text, "@Ann hello", "the key opens the picker instead of typing")
        try composer.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == self.s.send }).tap()
        XCTAssertEqual(sent, ["@Ann hello"], "the text carries the mention")
    }
}
