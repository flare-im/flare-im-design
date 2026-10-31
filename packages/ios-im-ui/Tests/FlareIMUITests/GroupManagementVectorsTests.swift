import Foundation
import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The shared group management table (`spec/group-management-vectors.json`): the viewer's capabilities map to
/// the management entries they name, each member's actions to the sheet's labels, and GroupDetail's member sheet
/// reads the host's `memberActions` entry. Vue, Compose and Flutter run the same table.
final class GroupManagementVectorsTests: XCTestCase {
    private struct Table: Decodable {
        let entryOrder: [String]
        let entries: [EntryVector]
        let memberActions: [ActionVector]
        let detailSheet: [DetailVector]
    }

    private struct EntryVector: Decodable {
        let id: String
        let capabilities: [String: Bool]
        let expected: [String]
    }

    private struct Member: Decodable {
        let role: String
        let muted: Bool
    }

    private struct Entry: Decodable, Equatable {
        let action: String
        let danger: Bool
    }

    private struct ActionVector: Decodable {
        let id: String
        let member: Member
        let actions: [String: Bool]?
        let expected: [Entry]
    }

    private struct DetailModel: Decodable {
        let ownerId: String
        let adminIds: [String]
        let mutedIds: [String]
        let memberActions: [String: [String: Bool]]
    }

    private struct DetailVector: Decodable {
        let id: String
        let model: DetailModel
        let memberId: String
        let expected: [Entry]
    }

    private func table() throws -> Table {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let url = root.appendingPathComponent("spec/group-management-vectors.json")
        return try JSONDecoder().decode(Table.self, from: Data(contentsOf: url))
    }

    /// Only the fields the kit reads; any other key in the table (the SDK's other fields) grants nothing.
    private func capabilities(_ raw: [String: Bool]) -> FlareGroupCapabilities {
        FlareGroupCapabilities(canManageInfo: raw["canManageInfo"] == true,
                               canManageJoinSettings: raw["canManageJoinSettings"] == true,
                               canManageJoinRequests: raw["canManageJoinRequests"] == true,
                               canInvite: raw["canInvite"] == true,
                               canDissolve: raw["canDissolve"] == true)
    }

    private func actions(_ raw: [String: Bool]) -> FlareMemberActions {
        FlareMemberActions(canRemove: raw["canRemove"] == true, canMute: raw["canMute"] == true,
                           canChangeRole: raw["canChangeRole"] == true,
                           canTransferOwner: raw["canTransferOwner"] == true)
    }

    private func entries(_ got: [FlareMemberRoleActionEntry]) -> [Entry] {
        got.map { Entry(action: $0.action.rawValue, danger: $0.danger) }
    }

    func testTheDisplayOrderIsTheSharedOne() throws {
        XCTAssertEqual(FlareGroupManagementEntry.allCases.map(\.rawValue), try table().entryOrder)
    }

    func testEachCapabilityShowsTheEntriesItNamesAndNothingElse() throws {
        let vectors = try table().entries
        XCTAssertGreaterThanOrEqual(vectors.count, 8, "the shared table lost cases")
        for vector in vectors {
            XCTAssertEqual(groupManagementEntries(capabilities(vector.capabilities)).map(\.rawValue),
                           vector.expected, vector.id)
        }
    }

    func testEachMemberActionIsLabelledFromTheAnswerAndTheMembersState() throws {
        for vector in try table().memberActions {
            let role = try XCTUnwrap(FlareGroupMemberRole(rawValue: vector.member.role), vector.id)
            let got = memberRoleActions(role: role, muted: vector.member.muted, actions: vector.actions.map(actions))
            XCTAssertEqual(entries(got), vector.expected, vector.id)
        }
    }

    func testTheDetailSheetOffersOnlyWhatTheHostAllowsForThatMember() throws {
        for vector in try table().detailSheet {
            let model = FlareGroupDetailModel(groupId: "g", name: "g", ownerId: vector.model.ownerId,
                                              adminIds: vector.model.adminIds, mutedIds: vector.model.mutedIds,
                                              memberActions: vector.model.memberActions.mapValues(actions))
            XCTAssertEqual(entries(groupDetailMemberActions(model: model, memberId: vector.memberId)),
                           vector.expected, vector.id)
        }
    }

    func testAMatrixRowIsEditableExactlyWhenItsEntryIsOffered() throws {
        let settings = FlareGroupPermissionSettings(joinPolicy: .approval)
        for vector in try table().entries {
            let editable = groupPermissionRows(settings, capabilities: capabilities(vector.capabilities))
                .filter(\.editable).map(\.key.rawValue)
            XCTAssertEqual(editable, FlareGroupPermissionKey.allCases.map(\.rawValue).filter(vector.expected.contains),
                           vector.id)
        }
    }

    /// An admin who may only mute: the host answered mute for the plain member and nothing for the peer admin.
    @MainActor
    func testAnAdminWhoMayOnlyMuteGetsMuteForAMemberAndNothingForAPeerAdmin() throws {
        let copy = FlareGroupDetailLabels().resolve(FlareStrings())
        let kim = Contact(id: "kim", name: "Kim")
        let peer = Contact(id: "peer", name: "Peer")
        let model = FlareGroupDetailModel(groupId: "g", name: "Team", memberCount: 3,
                                          members: [Contact(id: "own", name: "Owner"), peer, kim], ownerId: "own",
                                          adminIds: ["me", "peer"],
                                          memberActions: ["kim": FlareMemberActions(canMute: true), "peer": .none])
        var muted: [String] = []
        let detail = FlareGroupDetail(model: model, onMuteMember: { id, on in muted.append("\(id) \(on)") })
        let sheet = try AnyView(detail.memberActionButtons(for: kim)).inspect()
        let labels = sheet.findAll(ViewType.Button.self).compactMap { try? $0.labelView().text().string() }
        XCTAssertEqual(labels, [copy.mute, copy.cancel])
        try sheet.find(button: copy.mute).tap()
        XCTAssertEqual(muted, ["kim true"])
        for member in [peer, Contact(id: "own", name: "Owner")] {
            let other = try AnyView(detail.memberActionButtons(for: member)).inspect()
            let otherLabels = other.findAll(ViewType.Button.self).compactMap { try? $0.labelView().text().string() }
            XCTAssertEqual(otherLabels, [copy.cancel], member.id)
        }
        XCTAssertTrue(groupDetailMemberActions(model: model, memberId: "peer").isEmpty)
        XCTAssertTrue(groupDetailMemberActions(model: model, memberId: "own").isEmpty)
    }

    /// Each management row shows only for the capability that names it; leaving turns into dissolving only
    /// with the capability to dissolve.
    @MainActor
    func testEachManagementRowShowsOnlyForTheCapabilityThatNamesIt() throws {
        func rows(_ caps: FlareGroupCapabilities) -> [String] {
            let model = FlareGroupDetailModel(groupId: "g", name: "Team", capabilities: caps)
            let detail = FlareGroupDetail(model: model)
            return (detail.manageItems(model) + detail.permsItems(model)).map(\.key)
        }
        XCTAssertEqual(rows(FlareGroupCapabilities(canManageJoinRequests: true)), ["joinRequests"])
        XCTAssertEqual(rows(FlareGroupCapabilities(canInvite: true)), ["inviteLink"])
        XCTAssertEqual(rows(FlareGroupCapabilities(canManageInfo: true)), ["muteAll", "atAll", "pinPerm", "shareCard"])
        XCTAssertEqual(rows(FlareGroupCapabilities(canManageJoinSettings: true)), ["discoverable", "joinPolicy"])
        XCTAssertEqual(rows(.none), [])

        let copy = FlareGroupDetailLabels().resolve(FlareStrings())
        func texts(_ caps: FlareGroupCapabilities) throws -> [String] {
            try FlareGroupDetail(model: FlareGroupDetailModel(groupId: "g", name: "Team", capabilities: caps))
                .inspect().findAll(ViewType.Text.self).map { try $0.string() }
        }
        let member = try texts(.none)
        XCTAssertTrue(member.contains(copy.leave))
        XCTAssertFalse(member.contains(copy.dissolve))
        XCTAssertFalse(member.contains(copy.sectionManage), "an empty section is not drawn")
        XCTAssertFalse(member.contains(copy.sectionPerms), "an empty section is not drawn")
        let owner = try texts(FlareGroupCapabilities(canDissolve: true))
        XCTAssertTrue(owner.contains(copy.dissolve))
        XCTAssertFalse(owner.contains(copy.leave))
    }
}
