import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// FlareGroupDetail's host slots and the message button rule (FR-028).
final class GroupDetailSlotsTests: XCTestCase {
    private let copy = FlareGroupDetailLabels().resolve(FlareStrings())
    private let model = FlareGroupDetailModel(groupId: "g1", name: "Design", memberCount: 2,
                                              members: [Contact(id: "me", name: "Me"), Contact(id: "u2", name: "Ann")],
                                              ownerId: "me",
                                              capabilities: FlareGroupCapabilities(canManageInfo: true, canInvite: true))

    private func texts(_ detail: FlareGroupDetail) throws -> [String] {
        try detail.inspect().findAll(ViewType.Text.self).map { try $0.string() }
    }

    @MainActor
    func testSlotsSitAfterTheInfoSectionAndAfterTheButtons() throws {
        let detail = FlareGroupDetail(model: model,
                                      afterInfo: AnyView(Text("READ BAR")), footer: AnyView(Text("REPORT")),
                                      onOpenChat: { _, _ in })
        let order = try texts(detail)
        func index(_ text: String) throws -> Int { try XCTUnwrap(order.firstIndex(of: text), "\(text) is drawn") }
        // afterInfo: after the group information section, before the next section.
        XCTAssertLessThan(try index(copy.sectionInfo), try index("READ BAR"))
        XCTAssertLessThan(try index(copy.members), try index("READ BAR"))
        XCTAssertLessThan(try index("READ BAR"), try index(copy.sectionMyInGroup))
        // The footer slot follows the management actions in the scrollable content.
        XCTAssertLessThan(try index(copy.leave), try index("REPORT"))
        XCTAssertLessThan(try index("REPORT"), try index(copy.message))
        XCTAssertEqual(order.last, copy.message)
    }

    @MainActor
    func testSlotsKeepThePageInset() throws {
        let detail = FlareGroupDetail(model: model,
                                      afterInfo: AnyView(Text("READ BAR")), footer: AnyView(Text("REPORT")))
        let afterInfo = try detail.inspect().find(ViewType.AnyView.self, where: { try $0.text().string() == "READ BAR" })
        XCTAssertEqual(try afterInfo.padding(), EdgeInsets(top: 0, leading: FlareSizes.spacingMd,
                                                            bottom: 0, trailing: FlareSizes.spacingMd))
        let footer = try detail.inspect().find(ViewType.AnyView.self, where: { try $0.text().string() == "REPORT" })
        XCTAssertEqual(try footer.padding(), EdgeInsets(top: 0, leading: FlareSizes.spacingLg,
                                                         bottom: 0, trailing: FlareSizes.spacingLg))
    }

    @MainActor
    func testNothingIsDrawnWithoutSlots() throws {
        let detail = FlareGroupDetail(model: model, onOpenChat: { _, _ in })
        XCTAssertThrowsError(try detail.inspect().find(ViewType.AnyView.self))
        let order = try texts(detail)
        XCTAssertEqual(Array(order.suffix(2)), [copy.leave, copy.message])
    }

    @MainActor
    func testTheMessageButtonNeedsAnOpenChatHandler() throws {
        XCTAssertThrowsError(try FlareGroupDetail(model: model).inspect().find(button: copy.message),
                             "no handler, no message button")
        XCTAssertNoThrow(try FlareGroupDetail(model: model).inspect().find(button: copy.leave),
                         "leaving keeps its own rule")

        var opened: [([String], String)] = []
        let detail = FlareGroupDetail(model: model, onOpenChat: { ids, name in opened.append((ids, name)) })
        try detail.inspect().find(button: copy.message).tap()
        XCTAssertEqual(opened.map(\.0), [["me", "u2"]])
        XCTAssertEqual(opened.map(\.1), ["Design"])
    }
}
