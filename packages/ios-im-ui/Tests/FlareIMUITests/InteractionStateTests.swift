import XCTest
@testable import FlareIMUI

final class InteractionStateTests: XCTestCase {
    func testComposerPrecedenceAndActions() {
        XCTAssertEqual(resolveComposerMode(.init(recording: true, online: false, readOnly: true)), .readOnly)
        XCTAssertEqual(resolveComposerMode(.init(online: false, permissionGranted: false)), .permissionDenied)
        XCTAssertFalse(composerAllowedActions(.offline).contains(.send))
    }

    func testMessageLifecycleOutranksHover() {
        XCTAssertEqual(resolveMessageMode(.init(mutation: .recalled), hovered: true), .recalled)
        XCTAssertEqual(resolveMessageMode(.init(read: .read)), .read)
    }

    func testSelectionShortcutsAndGestures() {
        let anchor = reduceSelection(.init(), .replace("b"))
        let range = reduceSelection(anchor, .extend("d", orderedIds: ["a", "b", "c", "d"]))
        XCTAssertEqual(range.selectedIds, ["b", "c", "d"])
        XCTAssertEqual(resolveDesktopShortcut("k", primary: true), .commandPalette)
        XCTAssertEqual(resolveSwipeIntent(deltaX: 80, deltaY: 70, message: true), .none)
        XCTAssertEqual(resolveSwipeIntent(deltaX: 80, deltaY: 8, message: true), .reply)
    }

    func testMessageCapabilitiesFollowOwnershipAndTerminalLifecycle() {
        let own = resolveMessageCapabilities(.init(lifecycle: .init(), own: true))
        XCTAssertTrue(own.contains(.edit))
        XCTAssertFalse(own.contains(.report))
        let recalled = resolveMessageCapabilities(
            .init(lifecycle: .init(mutation: .recalled), own: true)
        )
        XCTAssertTrue(recalled.isEmpty)
    }

    func testExtendedActionsAndShortcutsShareTheCapabilityContract() {
        let actions = resolveMessageCapabilities(.init(
            lifecycle: .init(), own: true, supportsMergeForward: true,
            pinned: true, hasThread: true, hasQuote: true
        ))
        XCTAssertTrue(actions.isSuperset(of: [.unpin, .openThread, .jumpToQuote, .mergeForward]))
        XCTAssertEqual(resolveDesktopShortcut("f", scope: .conversation), .forward)
        XCTAssertEqual(resolveDesktopShortcut("t", scope: .conversation), .openThread)
    }

    func testActionPresentationStaysDownstreamOfAvailability() {
        let actions = resolveMessageActions(.init(lifecycle: .init(), own: false), presentation: .hoverToolbar)
        XCTAssertTrue(actions.first(where: { $0.id == .reply })?.promoted == true)
        XCTAssertEqual(actions.first(where: { $0.id == .report })?.group, .destructive)
    }
}
