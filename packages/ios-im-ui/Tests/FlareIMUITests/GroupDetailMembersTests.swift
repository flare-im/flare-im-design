import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// K5 (FR-089): the member grid previews at most 20 cells and the 群成员 row opens everyone with search.
final class GroupDetailMembersTests: XCTestCase {
    private let strings = FlareStrings()
    private let members = (1...30).map { Contact(id: "u\($0)", name: $0 == 7 ? "Ann Lee" : "成员\($0)") }

    func testThePreviewHoldsTwentyCellsWithTheAddTileCounted() {
        XCTAssertEqual(FlareGroupDetail.memberPreviewCells, 20)
        XCTAssertEqual(FlareGroupDetail.previewMembers(members, canManage: true).map(\.id), (1...19).map { "u\($0)" },
                       "19 people and the add tile")
        XCTAssertEqual(FlareGroupDetail.previewMembers(members, canManage: false).count, 20)
        XCTAssertEqual(FlareGroupDetail.previewMembers(Array(members.prefix(5)), canManage: true).count, 5)
    }

    func testSearchMatchesNamesInAnyCaseAndBlankShowsEveryone() {
        XCTAssertEqual(FlareGroupDetail.matchingMembers(members, query: "  ann ").map(\.id), ["u7"])
        XCTAssertEqual(FlareGroupDetail.matchingMembers(members, query: "成员1").map(\.id),
                       ["u1", "u10", "u11", "u12", "u13", "u14", "u15", "u16", "u17", "u18", "u19"])
        XCTAssertEqual(FlareGroupDetail.matchingMembers(members, query: " ").count, 30)
        XCTAssertTrue(FlareGroupDetail.matchingMembers(members, query: "nobody").isEmpty)
    }

    func testRemoteMemberSearchResultsReplaceLocalFilteringOnlyWhenSupplied() {
        let remote = [Contact(id: "remote", name: "Remote Ann")]
        XCTAssertEqual(
            FlareGroupDetail.visibleMembers(members, query: "ann", searched: remote, remoteEnabled: true).map(\.id),
            ["remote"]
        )
        XCTAssertEqual(
            FlareGroupDetail.visibleMembers(members, query: "ann", searched: nil, remoteEnabled: true).map(\.id),
            ["u7"],
            "while a host-backed query is pending the sheet keeps the local fallback visible"
        )
        XCTAssertEqual(
            FlareGroupDetail.visibleMembers(members, query: "ann", searched: remote, remoteEnabled: false).map(\.id),
            ["u7"]
        )
    }

    func testTheMembersSheetSpeaksTheStringsTable() {
        XCTAssertEqual(strings.groupDetailMembersTitle(30), "群成员（30）")
        XCTAssertEqual(strings.groupDetailSearchMembers, "搜索群成员")
        XCTAssertEqual(strings.groupDetailNoMatchingMembers, "没有匹配的群成员")
    }

    @MainActor
    func testTheGridDrawsThePreviewAndTheHeaderCountsTheWholeGroup() throws {
        let model = FlareGroupDetailModel(groupId: "g1", name: "Design", memberCount: 30, members: members,
                                          ownerId: "u1", canManage: true, isOwner: true)
        let grid = try FlareGroupDetail(model: model).inspect().find(GroupMemberGridView.self)
        let names = grid.findAll(ViewType.Text.self).compactMap { try? $0.string() }
        XCTAssertTrue(names.contains("成员19"), "\(names)")
        XCTAssertFalse(names.contains("成员20"), "the 20th cell is the add tile")
        XCTAssertTrue(names.contains(strings.memberCount(30)), "the header counts the group, not the preview: \(names)")
        XCTAssertTrue(names.contains(strings.addMember))
    }

    @MainActor
    func testTheMembersRowIsANavigationRow() throws {
        let model = FlareGroupDetailModel(groupId: "g1", name: "Design", memberCount: 30, members: members, ownerId: "u1")
        let row = try FlareGroupDetail(model: model).inspect().find(FlareSettingsRow.self, where: {
            (try? $0.find(text: FlareGroupDetailLabels().resolve(self.strings).members)) != nil
        })
        XCTAssertNoThrow(try row.find(ViewType.Image.self, where: { try $0.actualImage().name() == "chevron.right" }),
                         "the row navigates to the members sheet")
        XCTAssertNoThrow(try row.find(text: "30"))
    }
}
