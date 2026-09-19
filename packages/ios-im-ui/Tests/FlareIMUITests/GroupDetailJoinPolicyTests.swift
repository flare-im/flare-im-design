import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The group join policy is a kit enum, never an SDK number; unknown is nil and never guessed (FR-028).
final class GroupDetailJoinPolicyTests: XCTestCase {
    private let copy = FlareGroupDetailLabels().resolve(FlareStrings())

    func testTheModelDoesNotGuessAPolicy() {
        XCTAssertNil(FlareGroupDetailModel(groupId: "g1", name: "Design").joinPolicy)
        XCTAssertEqual(FlareGroupDetailModel(groupId: "g1", name: "Design", joinPolicy: .invite).joinPolicy, .invite)
    }

    func testTheRowNamesThePolicyAndReadsNotSetWhenUnknown() {
        XCTAssertEqual(FlareGroupDetail.joinPolicyLabel(.open, copy: copy), copy.joinOpen)
        XCTAssertEqual(FlareGroupDetail.joinPolicyLabel(.approval, copy: copy), copy.joinApproval)
        XCTAssertEqual(FlareGroupDetail.joinPolicyLabel(.invite, copy: copy), copy.joinInvite)
        XCTAssertEqual(FlareGroupDetail.joinPolicyLabel(nil, copy: copy), copy.notSet)
    }

    func testChoicesAreInDisplayOrder() {
        let options = FlareGroupDetail.joinPolicyOptions(copy)
        XCTAssertEqual(options.map(\.value), ["open", "approval", "invite"])
        XCTAssertEqual(options.map(\.label), [copy.joinOpen, copy.joinApproval, copy.joinInvite])
    }

    @MainActor
    func testThePickerSelectsTheCurrentPolicyAndNothingWhenUnknown() throws {
        let options = FlareGroupDetail.joinPolicyOptions(copy)
        let unknown = try FlareGroupJoinPolicyPicker(policy: nil, options: options, onPick: { _ in })
            .inspect().find(RadioGroupView.self)
        XCTAssertFalse(options.map(\.value).contains(try selection(of: unknown)), "nothing selected")
        let known = try FlareGroupJoinPolicyPicker(policy: .approval, options: options, onPick: { _ in })
            .inspect().find(RadioGroupView.self)
        XCTAssertEqual(try selection(of: known), "approval")
    }

    @MainActor
    func testPickingAPolicyReportsTheEnum() throws {
        var picked: [FlareGroupJoinPolicy] = []
        let picker = FlareGroupJoinPolicyPicker(policy: nil, options: FlareGroupDetail.joinPolicyOptions(copy),
                                                onPick: { picked.append($0) })
        try picker.inspect().find(button: copy.joinInvite).tap()
        try picker.inspect().find(button: copy.joinOpen).tap()
        XCTAssertEqual(picked, [.invite, .open])
    }

    @MainActor
    func testTheManageRowShowsTheModelsPolicy() throws {
        func texts(_ policy: FlareGroupJoinPolicy?) throws -> [String] {
            // Announcement and nickname are set, so "not set" can only come from the join policy row.
            let detail = FlareGroupDetail(
                model: FlareGroupDetailModel(groupId: "g1", name: "Design", announcement: "Hello", canManage: true,
                                             isOwner: true, myNickname: "Me", joinPolicy: policy),
                onSetJoinPolicy: { _ in })
            return try detail.inspect().findAll(ViewType.Text.self).map { try $0.string() }
        }
        let approval = try texts(.approval)
        XCTAssertTrue(approval.contains(copy.joinApproval))
        XCTAssertFalse(approval.contains(copy.notSet))
        let unknown = try texts(nil)
        XCTAssertEqual(unknown.filter { $0 == copy.notSet }.count, 1)
        XCTAssertFalse(unknown.contains(copy.joinOpen), "an unknown policy is never shown as open")
    }

    /// The radio group's bound value, read through its selection binding.
    private func selection(of radio: InspectableView<ViewType.View<RadioGroupView>>) throws -> String {
        let binding = Mirror(reflecting: try radio.actualView()).children.first { $0.label == "_selection" }?.value
        return try XCTUnwrap(binding as? Binding<String>).wrappedValue
    }
}
