import XCTest
@testable import FlareIMUI

final class ApplicationCompositionTests: XCTestCase {
    func testResponsiveModesUseSharedBreakpoints() {
        XCTAssertEqual(resolveApplicationResponsiveMode(width: 375), .mobile)
        XCTAssertEqual(resolveApplicationResponsiveMode(width: 800), .tablet)
        XCTAssertEqual(resolveApplicationResponsiveMode(width: 1200), .desktop)
        XCTAssertEqual(resolveApplicationResponsiveMode(width: 1600), .wideDesktop)
    }

    func testMessageActionExtensionsRespectCapabilitiesAndPredicate() {
        let actions = [
            FlareMessageActionExtension(id: "translate", label: "Translate", capability: "translate", order: 1, invoke: { _ in }),
            FlareMessageActionExtension(id: "debug", label: "Debug", order: 2, enabled: { _ in false }, invoke: { _ in }),
            FlareMessageActionExtension(id: "hidden", label: "Hidden", available: { _ in false }, invoke: { _ in }),
        ]
        let resolved = resolveMessageActionExtensions(actions, capabilities: FlareCapabilitySet(["translate"]), messageID: "m1")
        XCTAssertEqual(resolved.map(\.id), ["translate", "debug"])
        XCTAssertFalse(resolved.last!.enabled("m1"))
    }

    func testNavigationDefaultsAreReplaceableAndOrdered() {
        XCTAssertEqual(flareDefaultIMNavigation().map(\.id), ["chats", "contacts", "profile"])
        XCTAssertEqual(flareDefaultContactNavigation().map(\.id), ["friends", "groups", "newFriends", "favorites"])
        let items = [
            FlareApplicationNavigationItem(id: "profile", label: "Me", icon: "person", order: 3),
            FlareApplicationNavigationItem(id: "contacts", label: "Contacts", icon: "people", visible: false),
            FlareApplicationNavigationItem(id: "chats", label: "Chats", icon: "chats", order: 0),
            FlareApplicationNavigationItem(id: "work", label: "Work", icon: "folder", order: 2),
        ]
        XCTAssertEqual(resolveNavigationItems(defaults: flareDefaultIMNavigation(), items: items).map(\.id), ["chats", "work", "profile"])
    }
}
