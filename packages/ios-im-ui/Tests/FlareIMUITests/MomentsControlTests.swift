import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// Batch 4 P3 (G18): people and comments in a moment are controls only when the host handles them, names read
/// in the accessible primary text colour, and a cover without an image is a quiet neutral band.
final class MomentsControlTests: XCTestCase {
    private let s = FlareStrings()
    private let colors = FlareColors.of(.light, brand: .violet)
    private let moment = Moment(
        id: "m1", author: MomentAuthor(id: "u_lin", name: "林夏"), text: "周末去爬山", time: "10 分钟前",
        likes: [MomentLike(id: "u_zhou", name: "周屿"), MomentLike(id: "u_su", name: "苏晚晴")],
        comments: [MomentComment(id: "c1", author: MomentAuthor(id: "u_he", name: "何川"), text: "带上我")])

    @MainActor
    private func buttons(_ view: some View) throws -> [InspectableView<ViewType.Button>] {
        try view.inspect().findAll(ViewType.Button.self)
    }

    @MainActor
    private func button(_ view: some View, named name: String) throws -> InspectableView<ViewType.Button> {
        try view.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == name })
    }

    func testTheReplyNameComesFromTheStringsTable() {
        XCTAssertEqual(s.momentReplyToComment("何川", "带上我"), "回复 何川：带上我")
        XCTAssertEqual(FlareStrings(momentReplyToComment: { "Reply to \($0): \($1)" }).momentReplyToComment("He", "me too"),
                       "Reply to He: me too")
    }

    @MainActor
    func testPeopleAndCommentsAreTextWhenTheHostDoesNothingWithThem() throws {
        let card = MomentCardView(moment: moment, onLike: {})
        let names = try buttons(card).compactMap { try? $0.labelView().find(ViewType.Text.self).string() }
        XCTAssertEqual(try buttons(card).count, 1, "only the actions key is a control: \(names)")
        XCTAssertNoThrow(try button(card, named: s.momentActions))
        XCTAssertNoThrow(try card.inspect().find(text: "林夏"))
        XCTAssertNoThrow(try card.inspect().find(text: "周屿, "))
        XCTAssertTrue(try CommentThreadView(comments: moment.comments).inspect().findAll(ViewType.Button.self).isEmpty)
    }

    @MainActor
    func testHandledPeopleAndCommentsAreNamedControls() throws {
        var events: [String] = []
        let card = MomentCardView(moment: moment,
                                  onSelectAuthor: { events.append("author \($0)") },
                                  onSelectLiker: { events.append("liker \($0)") },
                                  onSelectComment: { events.append("comment \($0.id)") })
        let author = try card.inspect().find(ViewType.Button.self, where: { try $0.labelView().text().string() == "林夏" })
        try author.tap()
        let avatar = try card.inspect().find(ViewType.Button.self, where: { (try? $0.labelView().find(AvatarView.self)) != nil })
        XCTAssertTrue(try avatar.accessibilityHidden(), "the avatar repeats the name control")
        try button(card, named: "苏晚晴").tap()
        XCTAssertNoThrow(try button(card, named: "周屿"), "a liker is named without the separator")
        let row = try button(card, named: "回复 何川：带上我")
        try row.tap()
        let authorShortcut = try card.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == "何川" })
        XCTAssertTrue(try authorShortcut.accessibilityHidden(), "inside a row control the author name is a pointer shortcut")
        try authorShortcut.tap()
        XCTAssertEqual(events, ["author u_lin", "liker u_su", "comment c1", "author u_he"])
    }

    @MainActor
    func testAnAuthorHandlerAloneMakesTheCommentAuthorTheControl() throws {
        var opened: [String] = []
        let thread = CommentThreadView(comments: moment.comments, onSelectAuthor: { opened.append($0) })
        let author = try thread.inspect().find(ViewType.Button.self)
        XCTAssertFalse(try author.accessibilityHidden(), "with no row control the name is the control")
        XCTAssertEqual(try author.accessibilityLabel().string(), "何川")
        try author.tap()
        XCTAssertEqual(opened, ["u_he"])
        XCTAssertThrowsError(try thread.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == "回复 何川：带上我" }))
    }

    @MainActor
    func testNamesUseThePrimaryTextToken() throws {
        // In the dark theme the brand primary is too dark to read as text: the accessible token differs from it.
        let dark = FlareColors.of(.dark, brand: .violet)
        XCTAssertNotEqual(dark.primaryText, dark.primary, "the dark theme tells the two tokens apart")
        XCTAssertEqual(try MomentCardView.personName("林夏", colors: dark, size: FlareSizes.fontSizeXl, weight: .semibold)
                        .inspect().text().attributes().foregroundColor(), dark.primaryText)
        // The card draws its author and likers with that name style.
        let card = MomentCardView(moment: moment)
        XCTAssertEqual(try card.inspect().find(text: "林夏").attributes().foregroundColor(), colors.primaryText)
        XCTAssertEqual(try card.inspect().find(text: "周屿, ").attributes().foregroundColor(), colors.primaryText)
        let reply = MomentComment(id: "c2", author: MomentAuthor(id: "u_he", name: "何川"), text: "好", replyToName: "林夏")
        let line = try CommentThreadView.line(colors, reply, strings: s).inspect().text()
        XCTAssertEqual(s.momentReplyTo, "回复")
        XCTAssertEqual(try line.string(), "何川 \(s.momentReplyTo) 林夏：好")
        let attributes = try line.attributes()
        let replyStart = 2 + s.momentReplyTo.count + 2
        XCTAssertEqual(try attributes[0..<2].foregroundColor(), colors.primaryText, "the author")
        XCTAssertEqual(try attributes[replyStart..<(replyStart + 2)].foregroundColor(), colors.primaryText, "the person replied to")
        XCTAssertEqual(try attributes[(replyStart + 3)...].foregroundColor(), colors.textPrimary, "the comment text")
        let darkLine = try CommentThreadView.line(dark, reply, strings: s).inspect().text().attributes()
        XCTAssertEqual(try darkLine[0..<2].foregroundColor(), dark.primaryText)
    }

    @MainActor
    func testACoverWithoutAnImageIsAQuietBand() throws {
        // No photo, no band to reserve: the header is the identity row and takes the height that row needs.
        // It used to reserve 140pt, which with the name pulled to the band's bottom-right left ~110pt empty.
        XCTAssertEqual(MomentsCoverHeaderView.coverHeight(hasImage: false), 0)
        XCTAssertEqual(MomentsCoverHeaderView.coverHeight(hasImage: true), 240)
        let quiet = MomentsCoverHeaderView(userId: "u_lin", name: "林夏", signature: "产品设计")
        let view = try quiet.inspect()
        XCTAssertThrowsError(try view.find(ViewType.LinearGradient.self), "no brand gradient and no scrim")
        let name = try view.find(text: "林夏")
        XCTAssertEqual(try name.attributes().foregroundColor(), colors.textPrimary)
        XCTAssertEqual(try view.find(text: "产品设计").attributes().foregroundColor(), colors.textSecondary)
        XCTAssertThrowsError(try name.shadow(), "no text shadow without an image")
        XCTAssertThrowsError(try view.find(button: s.changeCover), "no cover handler, no change-cover control")
        XCTAssertTrue(try view.findAll(ViewType.Button.self).isEmpty, "no avatar handler, no avatar control")

        var edits = 0
        let photo = MomentsCoverHeaderView(userId: "u_lin", name: "林夏", coverURL: "https://cdn.example.com/cover.jpg",
                                           signature: "产品设计", onEditCover: { edits += 1 })
        let photoView = try photo.inspect()
        XCTAssertNoThrow(try photoView.find(ViewType.LinearGradient.self), "a photo keeps its scrim")
        XCTAssertEqual(try photoView.find(text: "林夏").attributes().foregroundColor(), .white)
        XCTAssertNoThrow(try photoView.find(text: "林夏").shadow())
        try photoView.find(ViewType.Button.self, where: { (try? $0.labelView().find(text: self.s.changeCover)) != nil }).tap()
        XCTAssertEqual(edits, 1)
    }
}
