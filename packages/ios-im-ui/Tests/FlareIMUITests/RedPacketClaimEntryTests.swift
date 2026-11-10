import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

final class RedPacketClaimEntryTests: XCTestCase {
    private func detail(unknown: Bool) throws -> PluginViewModel {
        let details = FlareRedPacketDetailsView(viewerRole: .eligible, status: .open, kind: .normal,
            greeting: "A red packet", currency: "CNY", currencyExponent: 2, claimedCount: 0, shareCount: 1,
            createdAtMs: 0, expiresAtMs: 4_102_444_800_000, claimsListed: false)
        let encoded = try JSONDecoder().decode(PluginJSONValue.self, from: JSONEncoder().encode(details))
        return PluginViewModel(available: true, title: "Red packet",
            actions: [PluginViewAction(id: "claim", label: "Claim red packet")],
            presentation: PluginPresentation(renderer: "redPacket.detail",
                props: ["senderId": .string("sender"), "details": encoded,
                        "journal": .object(["known": .bool(!unknown)])],
                actions: ["open": "claim"]))
    }

    @MainActor
    func testClaimEntryUsesTheFullWidthFamilyActionAndPreservesBlocking() throws {
        for (busy, unknown) in [(false, false), (true, false), (false, true)] {
            var requests = 0
            let view = ResolvedPresentationView(view: try detail(unknown: unknown), busy: busy, error: nil,
                formErrors: [], members: [], settleToken: 0, resolveUser: nil, onAction: nil,
                onRequest: { _ in requests += 1 })
            let family = try view.inspect().find(RedPacketActionButton.self)
            let button = try family.find(ViewType.Button.self)
            let frame = try button.labelView().flexFrame()
            XCTAssertEqual(frame.maxWidth, .infinity)
            XCTAssertGreaterThanOrEqual(frame.minHeight, FlareSizes.touchTarget)
            XCTAssertNoThrow(try button.find(text: "Claim red packet"))
            XCTAssertEqual(button.isDisabled(), busy || unknown)
            if busy || unknown { XCTAssertThrowsError(try button.tap()) }
            XCTAssertEqual(requests, 0, "The entry only opens the envelope; it never starts a claim itself")
        }
    }

    @MainActor
    func testOpenLabelStaysOnOneLineInsideTheCoinAndKeepsItsAction() throws {
        var requests = 0
        // ViewInspector expands an unmounted body with default Environment values.
        // English rendering needs a simulator visual check; this test covers sizing and tap semantics.
        let strings = FlareStrings()
        let view = try RedPacketOpenSheet(senderName: "Ann", blessing: "A red packet",
            onOpen: { requests += 1 }, onClose: {}).inspect()
        let label = try view.find(text: strings.packetOpenAction)
        XCTAssertEqual(try label.lineLimit(), 1)
        XCTAssertLessThan(try label.minimumScaleFactor(), 1)
        XCTAssertEqual(try label.fixedWidth(), FlareSizes.componentRedPacketOpenButtonSize)
        let button = try view.find(button: strings.packetOpenAction)
        try button.tap()
        XCTAssertEqual(requests, 1)
    }
}
