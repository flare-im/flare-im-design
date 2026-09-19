import XCTest
@testable import FlareIMUI

final class GroupPermissionMatrixTests: XCTestCase {
    private let settings = FlareGroupPermissionSettings(
        muteAll: false, onlyAdminCanAtAll: true, onlyAdminCanPin: false,
        shareCardPermission: true, joinPolicy: .approval)

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
        XCTAssertEqual(row(rows, .joinPolicy)?.value, .policy(.approval))
        XCTAssertEqual(row(rows, .joinPolicy)?.value.policyValue, .approval)
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

    func testUnknownJoinPolicyStaysUnknown() {
        // The host does not know the policy: the row carries nil, never a guessed default.
        XCTAssertNil(FlareGroupPermissionSettings().joinPolicy)
        let rows = groupPermissionRows(FlareGroupPermissionSettings(joinPolicy: nil), canManage: true)
        XCTAssertEqual(row(rows, .joinPolicy)?.value, .policy(nil))
        XCTAssertNil(row(rows, .joinPolicy)?.value.policyValue)
        XCTAssertNil(FlareGroupPermissionValue.flag(true).policyValue, "a flag carries no policy")
    }

    func testJoinChoicesAreInDisplayOrder() {
        let view = GroupPermissionMatrixView(settings: settings, canManage: true, onChange: { _, _ in })
        XCTAssertEqual(FlareGroupJoinPolicy.allCases, [.open, .approval, .invite])
        XCTAssertEqual(view.joinOptions.map(\.value), [.open, .approval, .invite])
        let strings = FlareStrings()
        XCTAssertEqual(view.joinOptions.map(\.label), [strings.groupPermissionMatrixJoinOpen,
                                                       strings.groupPermissionMatrixJoinApproval,
                                                       strings.groupPermissionMatrixJoinInvite])
    }

    @MainActor
    func testChoosingAPolicyReportsTheEnum() throws {
        var changes: [(FlareGroupPermissionKey, FlareGroupPermissionValue)] = []
        let strings = FlareStrings()
        let view = GroupPermissionMatrixView(settings: FlareGroupPermissionSettings(joinPolicy: nil), canManage: true,
                                             onChange: { changes.append(($0, $1)) })
        // An unknown policy is said so under the choices, and choosing one reports the enum.
        XCTAssertNoThrow(try view.inspect().find(text: strings.groupPermissionMatrixUnknownJoinPolicy))
        try view.inspect().find(button: strings.groupPermissionMatrixJoinInvite).tap()
        XCTAssertEqual(changes.map(\.0), [.joinPolicy])
        XCTAssertEqual(changes.map(\.1), [.policy(.invite)])
    }

    @MainActor
    func testAReadOnlyPanelShowsThePolicyOrThatItIsUnknown() throws {
        let strings = FlareStrings()
        let unknown = GroupPermissionMatrixView(settings: FlareGroupPermissionSettings(joinPolicy: nil), canManage: false)
        XCTAssertNoThrow(try unknown.inspect().find(text: strings.groupPermissionMatrixUnknownJoinPolicy))
        let known = GroupPermissionMatrixView(settings: FlareGroupPermissionSettings(joinPolicy: .approval), canManage: false)
        XCTAssertNoThrow(try known.inspect().find(text: strings.groupPermissionMatrixJoinApproval))
        XCTAssertThrowsError(try known.inspect().find(text: strings.groupPermissionMatrixUnknownJoinPolicy))
    }

    func testLabelsAndPolicyTextFollowTextProps() {
        let view = GroupPermissionMatrixView(settings: settings, canManage: true,
                                             joinOpenText: "Open", muteAllLabel: "Mute everyone")
        XCTAssertEqual(view.labelFor(.muteAll), "Mute everyone")
        XCTAssertEqual(view.labelFor(.onlyAdminCanPin), "仅管理员可置顶消息")
        XCTAssertEqual(view.joinPolicyText(.open), "Open")
        XCTAssertEqual(view.joinPolicyText(nil), "当前加群方式未知，请重新选择")
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
