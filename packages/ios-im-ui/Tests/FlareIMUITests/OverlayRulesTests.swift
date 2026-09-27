import SwiftUI
import XCTest
@testable import FlareIMUI

/// The pure rules the overlay family resolves with (BottomSheet auto, Drawer, Modal): form factor, form,
/// widths, height cap, placement, escape and naming. Spec: Overlay/BottomSheet, Overlay/Drawer, Overlay/Modal.
final class OverlayRulesTests: XCTestCase {
    // MARK: Form factor

    func testCompactFollowsTheShellModeFirstThenTheHostWidth() {
        // Inside a shell its responsive mode decides, whatever the host measured.
        XCTAssertTrue(FlareOverlayRules.compact(shellMode: .mobile, hostWidth: 1024))
        XCTAssertFalse(FlareOverlayRules.compact(shellMode: .tablet, hostWidth: 390))
        XCTAssertFalse(FlareOverlayRules.compact(shellMode: .desktop, hostWidth: nil))
        // Otherwise the host's live width against the rail breakpoint (600).
        XCTAssertTrue(FlareOverlayRules.compact(shellMode: nil, hostWidth: 390))
        XCTAssertTrue(FlareOverlayRules.compact(shellMode: nil, hostWidth: FlareSizes.navigationRailMinWidth - 1))
        XCTAssertFalse(FlareOverlayRules.compact(shellMode: nil, hostWidth: FlareSizes.navigationRailMinWidth))
        XCTAssertFalse(FlareOverlayRules.compact(shellMode: nil, hostWidth: 1024))
    }

    func testAnUnknownWidthKeepsTheSheet() {
        // No host, nothing measured yet, or the platform default's infinite width: today's sheet.
        XCTAssertTrue(FlareOverlayRules.compact(shellMode: nil, hostWidth: nil))
        XCTAssertTrue(FlareOverlayRules.compact(shellMode: nil, hostWidth: 0))
        XCTAssertTrue(FlareOverlayRules.compact(shellMode: nil, hostWidth: .infinity))
    }

    func testEnvironmentPublishesTheResolvedFormFactor() {
        var environment = EnvironmentValues()
        XCTAssertTrue(environment.flareCompactOverlays, "no host and no shell: the sheet")
        environment.flareOverlayHostSize = CGSize(width: 1024, height: 768)
        XCTAssertFalse(environment.flareCompactOverlays)
        environment.flareShellResponsiveMode = .mobile
        XCTAssertTrue(environment.flareCompactOverlays, "the shell's mode wins over the host's width")
    }

    func testBottomSheetAutoIsASheetWhenCompactAndAModalOtherwise() {
        XCTAssertEqual(FlareOverlayRules.sheetForm(.auto, compact: true), .sheet)
        XCTAssertEqual(FlareOverlayRules.sheetForm(.auto, compact: false), .cover)
        XCTAssertEqual(FlareOverlayRules.sheetForm(.sheet, compact: false), .sheet)
        XCTAssertEqual(FlareOverlayRules.sheetForm(.sheet, compact: true), .sheet)
    }

    func testDrawerPushesOnlyWhenCompactAndAskedTo() {
        XCTAssertEqual(FlareOverlayRules.drawerForm(.push, compact: true), .push)
        XCTAssertEqual(FlareOverlayRules.drawerForm(.push, compact: false), .cover)
        XCTAssertEqual(FlareOverlayRules.drawerForm(.none, compact: true), .cover)
        XCTAssertEqual(FlareOverlayRules.drawerForm(.none, compact: false), .cover)
    }

    // MARK: Geometry

    func testDrawerWidthDefaultsToTheSheetTokenAndLeavesAScrimStrip() {
        XCTAssertEqual(FlareOverlayRules.drawerWidth(requested: nil, window: 1024), FlareSizes.componentSheetWidth)
        XCTAssertEqual(FlareOverlayRules.drawerWidth(requested: 300, window: 1024), 300)
        // A narrow window keeps a touch-target-wide strip of scrim to tap.
        XCTAssertEqual(FlareOverlayRules.drawerWidth(requested: nil, window: 390), 390 - FlareSizes.touchTarget)
        XCTAssertEqual(FlareOverlayRules.drawerWidth(requested: 2000, window: 800), 800 - FlareSizes.touchTarget)
        XCTAssertEqual(FlareOverlayRules.drawerWidth(requested: nil, window: 10), 0)
    }

    func testModalWidthDefaultsToTheDialogTokenWithinAGutter() {
        XCTAssertEqual(FlareOverlayRules.modalWidth(requested: nil, window: 1024), FlareSizes.componentSheetDialogWidth)
        XCTAssertEqual(FlareOverlayRules.modalWidth(requested: 720, window: 1024), 720)
        XCTAssertEqual(FlareOverlayRules.modalWidth(requested: nil, window: 390), 390 - 2 * FlareSizes.spacingXl)
        XCTAssertEqual(FlareOverlayRules.modalWidth(requested: 720, window: 700), 700 - 2 * FlareSizes.spacingXl)
    }

    func testHeightCapIs72PercentByDefaultAndNeverExceedsWhatIsAvailable() {
        XCTAssertEqual(FlareOverlayRules.maxHeight(requested: nil, available: 1000), 720, accuracy: 0.001)
        XCTAssertEqual(FlareOverlayRules.maxHeight(requested: 400, available: 1000), 400)
        XCTAssertEqual(FlareOverlayRules.maxHeight(requested: 1200, available: 1000), 1000)
        XCTAssertEqual(FlareOverlayRules.maxHeight(requested: nil, available: -5), 0)
    }

    func testPlacementUsesInlineEdgesAndRoundsTheCornersFacingThePage() {
        XCTAssertEqual(FlareOverlayRules.edge(.end), .trailing)
        XCTAssertEqual(FlareOverlayRules.edge(.start), .leading)
        XCTAssertEqual(FlareOverlayRules.alignment(.end), .trailing)
        XCTAssertEqual(FlareOverlayRules.alignment(.start), .leading)
        // Left-to-right: an end drawer sits on the right, so its left corners face the page.
        XCTAssertTrue(FlareOverlayRules.roundsLeftCorners(.end, layoutDirection: .leftToRight))
        XCTAssertFalse(FlareOverlayRules.roundsLeftCorners(.start, layoutDirection: .leftToRight))
        // Right-to-left mirrors both.
        XCTAssertFalse(FlareOverlayRules.roundsLeftCorners(.end, layoutDirection: .rightToLeft))
        XCTAssertTrue(FlareOverlayRules.roundsLeftCorners(.start, layoutDirection: .rightToLeft))
    }

    // MARK: Behaviour

    func testDismissIsAllowedOnlyWhenNothingHoldsTheLayer() {
        XCTAssertTrue(FlareOverlayRules.dismissAllowed(dismissible: true, busy: false, locked: false))
        XCTAssertFalse(FlareOverlayRules.dismissAllowed(dismissible: false, busy: false, locked: false))
        XCTAssertFalse(FlareOverlayRules.dismissAllowed(dismissible: true, busy: true, locked: false))
        XCTAssertFalse(FlareOverlayRules.dismissAllowed(dismissible: true, busy: false, locked: true))
    }

    func testEscapeStepsBackWhenOfferedElseClosesAndDoesNothingWhileLocked() {
        XCTAssertEqual(FlareOverlayRules.escape(showBack: false, dismissAllowed: true), .close)
        XCTAssertEqual(FlareOverlayRules.escape(showBack: true, dismissAllowed: true), .back)
        XCTAssertEqual(FlareOverlayRules.escape(showBack: true, dismissAllowed: false), .none)
        XCTAssertEqual(FlareOverlayRules.escape(showBack: false, dismissAllowed: false), .none)
    }

    func testEveryLayerHasAnAccessibleName() {
        XCTAssertEqual(FlareOverlayRules.accessibleName(title: "Details", label: "Panel", fallback: "Side panel"), "Details")
        XCTAssertEqual(FlareOverlayRules.accessibleName(title: "", label: "Panel", fallback: "Side panel"), "Panel")
        XCTAssertEqual(FlareOverlayRules.accessibleName(title: nil, label: nil, fallback: "Side panel"), "Side panel")
        XCTAssertEqual(FlareOverlayRules.accessibleName(title: nil, label: "", fallback: "Dialog"), "Dialog")
        XCTAssertEqual(FlareStrings().drawerLabel, "侧边面板")
        XCTAssertEqual(FlareStrings.english.modalLabel, "Dialog")
    }

    func testHeaderRowOnlyWhenItHasSomething() {
        XCTAssertFalse(FlareOverlayRules.showsHeader(visibleTitle: false, hasActions: false, showBack: false, showClose: false))
        XCTAssertTrue(FlareOverlayRules.showsHeader(visibleTitle: true, hasActions: false, showBack: false, showClose: false))
        XCTAssertTrue(FlareOverlayRules.showsHeader(visibleTitle: false, hasActions: true, showBack: false, showClose: false))
        XCTAssertTrue(FlareOverlayRules.showsHeader(visibleTitle: false, hasActions: false, showBack: true, showClose: false))
        XCTAssertTrue(FlareOverlayRules.showsHeader(visibleTitle: false, hasActions: false, showBack: false, showClose: true))
    }

    func testSheetDetentFitsTheContentUpToTheCap() {
        XCTAssertEqual(FlareBottomSheetFrame<EmptyView>.detents(forHeight: 0, cap: 500), [.medium])
        XCTAssertEqual(FlareBottomSheetFrame<EmptyView>.detents(forHeight: 320, cap: 500), [.height(320)])
        XCTAssertEqual(FlareBottomSheetFrame<EmptyView>.detents(forHeight: 900, cap: 500), [.height(500)])
        XCTAssertEqual(FlareBottomSheetFrame<EmptyView>.detents(forHeight: 900), [.height(900)])
    }
}
