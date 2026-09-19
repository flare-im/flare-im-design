import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// Batch 4 P2 (G18): the profile header is a quiet identity card — the list groups' surface and text colours,
/// not the brand bubble colour — with the identity row and the QR key as two separate, named controls.
final class ProfilePanelHeaderTests: XCTestCase {
    private let s = FlareStrings()
    private let colors = FlareColors.of(.light, brand: .violet)
    private let user = UserProfile(id: "u_lin", name: "林夏", signature: "产品设计", flareId: "lin")

    @MainActor
    private func button(_ view: some View, _ name: String) throws -> InspectableView<ViewType.Button> {
        try view.inspect().find(ViewType.Button.self, where: { try $0.accessibilityLabel().string() == name })
    }

    func testTheEditLabelComesFromTheStringsTable() {
        XCTAssertEqual(s.profilePanelEditProfile("林夏"), "林夏，编辑资料")
        XCTAssertEqual(FlareStrings(profilePanelEditProfile: { "\($0), edit profile" }).profilePanelEditProfile("Lin"), "Lin, edit profile")
    }

    @MainActor
    func testTheIdentityRowAndTheQrKeyAreSeparateNamedControls() throws {
        var events: [String] = []
        let panel = ProfilePanelView(user: user, onEdit: { events.append("edit") }, onQr: { events.append("qr") })
        let identity = try button(panel, "林夏，编辑资料")
        XCTAssertTrue(try identity.labelView().findAll(ViewType.Button.self).isEmpty, "the QR key is not nested inside the identity row")
        XCTAssertNoThrow(try identity.labelView().find(text: "产品设计"), "the row holds the avatar, name, signature and id")
        XCTAssertNoThrow(try identity.labelView().find(ViewType.Image.self, where: { try $0.actualImage().name() == "chevron.right" }))
        XCTAssertGreaterThanOrEqual(try identity.labelView().flexFrame().minHeight, FlareSizes.touchTargetMin)

        let qr = try button(panel, s.myQrCode)
        XCTAssertGreaterThanOrEqual(try qr.labelView().flexFrame().minWidth, FlareSizes.touchTargetMin)
        XCTAssertGreaterThanOrEqual(try qr.labelView().flexFrame().minHeight, FlareSizes.touchTargetMin)
        try qr.tap()
        try identity.tap()
        XCTAssertEqual(events, ["qr", "edit"])
    }

    @MainActor
    func testTheCardUsesTheListTextColoursNotTheBrandBubbleColours() throws {
        let panel = ProfilePanelView(user: user, onEdit: {}, onQr: {})
        let view = try panel.inspect()
        XCTAssertEqual(try view.find(text: "林夏").attributes().foregroundColor(), colors.textPrimary)
        XCTAssertEqual(try view.find(text: "产品设计").attributes().foregroundColor(), colors.textSecondary)
        XCTAssertEqual(try view.find(text: "Flare ID: lin").attributes().foregroundColor(), colors.textTertiary)
        XCTAssertEqual(try view.find(ViewType.Image.self, where: { try $0.actualImage().name() == "chevron.right" }).foregroundColor(),
                       colors.textTertiary)
        XCTAssertNotEqual(colors.textPrimary, colors.messageOutgoingForeground, "the check tells the two apart")
        let placeholder = ProfilePanelView(user: UserProfile(id: "u", name: "Ann"), signaturePlaceholder: "轻触编辑个人资料")
        XCTAssertEqual(try placeholder.inspect().find(text: "轻触编辑个人资料").attributes().foregroundColor(), colors.textTertiary)
    }

    @MainActor
    func testWithoutHandlersTheIdentityIsContentAndThereIsNoQrKey() throws {
        let panel = ProfilePanelView(user: user)
        XCTAssertThrowsError(try button(panel, "林夏，编辑资料"), "no editor, no control")
        XCTAssertThrowsError(try button(panel, s.myQrCode), "no QR handler, no QR key")
        func chevrons(_ view: ProfilePanelView) throws -> Int {
            try view.inspect().findAll(ViewType.Image.self, where: { try $0.actualImage().name() == "chevron.right" }).count
        }
        // The default entries are navigation rows with their own chevrons; only the editable header adds one.
        XCTAssertEqual(try chevrons(panel), ProfilePanelView.entries(for: s).count, "no chevron on a header that opens nothing")
        XCTAssertEqual(try chevrons(ProfilePanelView(user: user, onEdit: {})), ProfilePanelView.entries(for: s).count + 1)
        XCTAssertNoThrow(try panel.inspect().find(text: "林夏"))
        XCTAssertEqual(ProfilePanelView.qrTrailingInset(opensEditor: true),
                       FlareSizes.spacingMd + FlareSizes.iconSizeSm + FlareSizes.spacingMd, "the key sits on the room left before the chevron")
    }
}
