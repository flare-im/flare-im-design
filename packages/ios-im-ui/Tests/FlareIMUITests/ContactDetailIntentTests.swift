import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// Batch 4 P1 (X23, FR-089): the contact detail offers an intent only when the host handles it, so a host
/// without calls shows no call buttons and a stranger's profile shows no friend-only actions. P6: the Flare ID
/// row shows the public handle only, never the account id.
final class ContactDetailIntentTests: XCTestCase {
    private let s = FlareStrings()
    private let stranger = Contact(id: "u_lin", name: "林夏", presence: .online)
    private let friend = Contact(id: "u_lin", name: "林夏", presence: .online, flareId: "linxia", remark: "设计评审")
    private var copy: FlareContactDetailLabels.Resolved { FlareContactDetailLabels().resolve(s) }

    @MainActor
    private func rowLabels(_ detail: FlareContactDetail) throws -> [String] {
        try detail.inspect().findAll(FlareSettingsRow.self).map { row in
            try row.find(ViewType.Text.self, where: { text in
                [self.copy.flareId, self.copy.remark, self.copy.description, self.copy.star].contains(try text.string())
            }).string()
        }
    }

    @MainActor
    private func hasButton(_ detail: FlareContactDetail, _ label: String) -> Bool {
        (try? detail.inspect().find(button: label)) != nil
    }

    func testOnlyHandledIntentsAndRowsAreOffered() {
        XCTAssertEqual(FlareContactDetail.intents(message: true, call: false, video: false), [.message])
        XCTAssertEqual(FlareContactDetail.intents(message: true, call: true, video: true), [.message, .call, .video])
        XCTAssertTrue(FlareContactDetail.intents(message: false, call: false, video: false).isEmpty)

        let strangerRows = FlareContactDetail.infoItems(contact: stranger, description: "", starred: false, copy: copy,
                                                        editsRemark: false, editsDescription: false, togglesStar: false)
        XCTAssertTrue(strangerRows.isEmpty, "no public handle, no empty read-only rows, no star toggle")

        let readOnly = FlareContactDetail.infoItems(contact: friend, description: "响应快", starred: true, copy: copy,
                                                    editsRemark: false, editsDescription: false, togglesStar: false)
        XCTAssertEqual(readOnly.map(\.key), ["flareId", "remark", "description"])
        XCTAssertEqual(readOnly.map(\.kind), [.value, .value, .value], "a set value without an edit handler is read-only")
        XCTAssertEqual(readOnly[0].detail, "linxia", "the public handle, not the account id")
        XCTAssertEqual(readOnly[1].detail, "设计评审")

        let editable = FlareContactDetail.infoItems(contact: stranger, description: "", starred: true, copy: copy,
                                                    editsRemark: true, editsDescription: true, togglesStar: true)
        XCTAssertEqual(editable.map(\.key), ["remark", "description", "star"], "no Flare ID row without a handle")
        XCTAssertEqual(editable.map(\.kind), [.navigation, .navigation, .toggle])
        XCTAssertEqual(editable[0].detail, copy.notSet, "an editable row without a value says it is not set")
        XCTAssertTrue(editable[2].value)
    }

    @MainActor
    func testAStrangerGetsOnlyTheMessageButtonAndNoFriendOnlyActions() throws {
        let detail = FlareContactDetail(contact: stranger, onMessage: {})
        XCTAssertTrue(hasButton(detail, copy.message))
        XCTAssertFalse(hasButton(detail, copy.voice), "no call UI without a call handler")
        XCTAssertFalse(hasButton(detail, copy.video))
        XCTAssertFalse(hasButton(detail, copy.block), "no danger zone without its handlers")
        XCTAssertFalse(hasButton(detail, copy.remove))
        XCTAssertEqual(try rowLabels(detail), [], "no rows: no handle, no remark, no description, no star toggle")
        XCTAssertThrowsError(try detail.inspect().find(text: copy.info), "no empty 资料 card")
        XCTAssertThrowsError(try detail.inspect().find(text: "u_lin"), "the account id is never shown")
        XCTAssertThrowsError(try detail.inspect().find(ViewType.Toggle.self), "no star toggle without its handler")

        let nothing = FlareContactDetail(contact: stranger)
        XCTAssertFalse(hasButton(nothing, copy.message), "no action row without any handler")
    }

    @MainActor
    func testAFriendGetsEditableRowsTheStarToggleAndTheDangerZone() throws {
        var events: [String] = []
        let detail = FlareContactDetail(
            contact: friend, starred: false, description: "响应快",
            onMessage: { events.append("message") }, onCall: { events.append("call") },
            onEditRemark: { events.append("remark") }, onEditDescription: { events.append("description") },
            onToggleStar: { events.append("star \($0)") }, onBlock: { events.append("block") },
            onRemove: { events.append("remove") })
        XCTAssertTrue(hasButton(detail, copy.voice))
        XCTAssertFalse(hasButton(detail, copy.video), "only the handled call kinds")
        XCTAssertEqual(try rowLabels(detail), [copy.flareId, copy.remark, copy.description, copy.star])

        let rows = try detail.inspect().findAll(FlareSettingsRow.self)
        func chevron(_ row: InspectableView<ViewType.View<FlareSettingsRow>>) -> Bool {
            (try? row.find(ViewType.Image.self, where: { try $0.actualImage().name() == "chevron.right" })) != nil
        }
        XCTAssertFalse(chevron(rows[0]), "Flare ID is a value")
        XCTAssertTrue(chevron(rows[1]), "remark navigates to its editor")
        try rows[1].find(ViewType.Button.self).tap()
        try rows[2].find(ViewType.Button.self).tap()
        try detail.inspect().find(ViewType.Toggle.self).tap()
        try detail.inspect().find(button: copy.message).tap()
        try detail.inspect().find(button: copy.block).tap()
        try detail.inspect().find(button: copy.remove).tap()
        XCTAssertEqual(events, ["remark", "description", "star true", "message", "block", "remove"])

        let removeOnly = FlareContactDetail(contact: friend, onRemove: {})
        XCTAssertTrue(hasButton(removeOnly, copy.remove))
        XCTAssertFalse(hasButton(removeOnly, copy.block), "each danger action needs its own handler")
    }

    @MainActor
    func testTheProfileCardShowsOnlyAPublicHandleAndHandledActions() throws {
        XCTAssertNil(ProfileCardView.meta(Contact(id: "u_lin", name: "林夏"), flareIdLabel: copy.flareId),
                     "no handle and no region: no meta line, and never the account id")
        XCTAssertEqual(ProfileCardView.meta(Contact(id: "u_lin", name: "林夏", flareId: "linxia"), flareIdLabel: copy.flareId),
                       "Flare ID · linxia")
        XCTAssertEqual(ProfileCardView.meta(Contact(id: "u_lin", name: "林夏", flareId: "linxia", region: "杭州"), flareIdLabel: copy.flareId),
                       "Flare ID · linxia · 杭州")
        XCTAssertEqual(ProfileCardView.meta(Contact(id: "u_lin", name: "林夏", region: "杭州"), flareIdLabel: copy.flareId), "杭州")

        let bare = ProfileCardView(user: Contact(id: "u_lin", name: "林夏"))
        XCTAssertTrue(try bare.inspect().findAll(ViewType.Button.self).isEmpty, "no handlers, no action keys")
        XCTAssertThrowsError(try bare.inspect().find(text: "Flare ID · u_lin"))
        var events: [String] = []
        let card = ProfileCardView(user: Contact(id: "u_lin", name: "林夏"), onMessage: { events.append("message") },
                                   onVideo: { events.append("video") })
        XCTAssertThrowsError(try card.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == self.copy.voice }))
        let video = try card.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == self.copy.video })
        XCTAssertGreaterThanOrEqual(try video.labelView().flexFrame().minHeight, FlareSizes.touchTargetMin)
        try video.tap()
        try card.inspect().find(button: s.sendMessage).tap()
        XCTAssertEqual(events, ["video", "message"])
    }

    @MainActor
    func testAReadOnlyRowIsNotAControl() throws {
        let detail = FlareContactDetail(contact: friend, description: "响应快")
        let rows = try detail.inspect().findAll(FlareSettingsRow.self)
        XCTAssertEqual(rows.count, 3)
        for row in rows {
            XCTAssertThrowsError(try row.find(ViewType.Button.self), "a value row is not a control")
            XCTAssertThrowsError(try row.find(ViewType.Image.self, where: { try $0.actualImage().name() == "chevron.right" }))
        }
        XCTAssertNoThrow(try detail.inspect().find(text: "设计评审"), "the value still shows")
    }
}
