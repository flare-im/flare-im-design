import XCTest
@testable import FlareIMUI

final class GroupPermissionMatrixTests: XCTestCase {
    private let settings = FlareGroupPermissionSettings(
        muteAll: false, onlyAdminCanAtAll: true, onlyAdminCanPin: false,
        shareCardPermission: true, joinPolicy: flareGroupJoinApproval)

    private func row(_ rows: [FlareGroupPermissionRow], _ key: FlareGroupPermissionKey) -> FlareGroupPermissionRow? {
        rows.first { $0.key == key }
    }

    func testCanonicalOrderOfRealBackendKeys() {
        XCTAssertEqual(groupPermissionRows(settings, canManage: true).map(\.key),
                       [.joinPolicy, .muteAll, .onlyAdminCanAtAll, .onlyAdminCanPin, .shareCardPermission])
    }

    func testJoinPolicyIsTheOnlyChoiceRowAndValuesCarryThrough() {
        let rows = groupPermissionRows(settings, canManage: true)
        XCTAssertEqual(rows.filter { $0.kind == .choice }.map(\.key), [.joinPolicy])
        XCTAssertEqual(row(rows, .joinPolicy)?.value, .policy(flareGroupJoinApproval))
        XCTAssertEqual(row(rows, .muteAll)?.value, .flag(false))
        XCTAssertEqual(row(rows, .onlyAdminCanAtAll)?.value, .flag(true))
        XCTAssertEqual(row(rows, .shareCardPermission)?.value, .flag(true))
    }

    func testEditableFollowsCanManageOnly() {
        XCTAssertTrue(groupPermissionRows(settings, canManage: false).allSatisfy { !$0.editable })
        let rows = groupPermissionRows(settings, canManage: true, busyKeys: ["muteAll"], errors: ["muteAll": "网络错误"])
        XCTAssertTrue(rows.allSatisfy(\.editable))
    }

    func testBusyAndErrorArePerKey() {
        let rows = groupPermissionRows(settings, canManage: true,
                                       busyKeys: ["muteAll"], errors: ["onlyAdminCanPin": "权限不足"])
        XCTAssertEqual(rows.filter(\.busy).map(\.key), [.muteAll])
        XCTAssertEqual(rows.filter { $0.error != nil }.map(\.key), [.onlyAdminCanPin])
        XCTAssertEqual(row(rows, .onlyAdminCanPin)?.error, "权限不足")
    }

    func testIgnoresUnknownBusyKeysAndEmptyInputs() {
        let rows = groupPermissionRows(settings, canManage: true, busyKeys: ["nope", "muteAll", "muteAll"])
        XCTAssertEqual(rows.filter(\.busy).map(\.key), [.muteAll])
        XCTAssertTrue(groupPermissionRows(settings, canManage: true).allSatisfy { !$0.busy && $0.error == nil })
    }

    func testKeepsErrorVisibleOnReadOnlyPanel() {
        let rows = groupPermissionRows(settings, canManage: false, errors: ["muteAll": "你已不是管理员"])
        XCTAssertEqual(row(rows, .muteAll)?.editable, false)
        XCTAssertEqual(row(rows, .muteAll)?.error, "你已不是管理员")
    }

    func testUnknownJoinPolicyPassesThrough() {
        let rows = groupPermissionRows(FlareGroupPermissionSettings(joinPolicy: 9), canManage: true)
        XCTAssertEqual(row(rows, .joinPolicy)?.value, .policy(9))
        XCTAssertFalse(isGroupJoinPolicy(9))
        XCTAssertTrue([flareGroupJoinInvite, flareGroupJoinApproval, flareGroupJoinOpen].allSatisfy(isGroupJoinPolicy))
    }

    func testLabelsAndPolicyTextFollowTextProps() {
        let view = GroupPermissionMatrixView(settings: settings, canManage: true,
                                             joinOpenText: "Open", muteAllLabel: "Mute everyone")
        XCTAssertEqual(view.labelFor(.muteAll), "Mute everyone")
        XCTAssertEqual(view.labelFor(.onlyAdminCanPin), "仅管理员可置顶消息")
        XCTAssertEqual(view.joinPolicyText(flareGroupJoinOpen), "Open")
        XCTAssertEqual(view.joinPolicyText(9), "当前加群方式未知，请重新选择")
    }

    func testWithoutAChangeCallbackThePanelIsReadOnly() {
        let readOnly = GroupPermissionMatrixView(settings: settings, canManage: true)
        XCTAssertFalse(readOnly.canEdit)
        let editable = GroupPermissionMatrixView(settings: settings, canManage: true, onChange: { _, _ in })
        XCTAssertTrue(editable.canEdit)
    }

    func testRetryFallsBackToFlippingAToggleAndNothingForAChoice() {
        let view = GroupPermissionMatrixView(settings: settings, canManage: true, onChange: { _, _ in })
        let rows = groupPermissionRows(settings, canManage: true, errors: ["muteAll": "e", "joinPolicy": "e"])
        XCTAssertEqual(view.retryValue(row(rows, .muteAll)!), .flag(true))
        XCTAssertNil(view.retryValue(row(rows, .joinPolicy)!))
    }
}
