import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// The semantic icon registry (one name set on every platform) and the header action aliases.
final class IconRegistryTests: XCTestCase {
    private let added = [
        "recall", "unpin", "merge-forward", "multi-select", "quote", "reaction", "translate", "mention",
        "read", "mark", "rich-text", "attachment", "mark-unread", "archive", "unarchive", "clear-history",
        "mic-off", "camera-off", "speaker", "speaker-off", "end-call", "switch-camera", "screen-share",
        "play", "pause", "expand", "collapse", "zoom-in", "zoom-out", "rotate", "group", "admin",
        "remove-member", "transfer-owner", "silence", "report", "chevron-up", "chevron-left", "keyboard",
        "mini-app",
    ]

    func testTheRegistryHas109NamesAndEveryNameResolves() {
        XCTAssertEqual(flareIconNames.count, 109)
        XCTAssertEqual(flareIconNames.suffix(2), ["locate", "wallet"], "wallet follows locate on every kit")
        XCTAssertEqual(Set(flareIconNames).count, flareIconNames.count, "names are unique")
        XCTAssertEqual(Set(flareIconMap.keys), Set(flareIconNames), "every name has exactly one symbol")
        XCTAssertEqual(added.count, 40)
        for name in added { XCTAssertTrue(flareIconNames.contains(name), "\(name) is in the registry") }
        for name in ["heart-filled", "bookmark"] {
            XCTAssertFalse(flareIconNames.contains(name), "\(name) was removed")
            XCTAssertNil(flareIconMap[name])
        }
    }

    func testRemappedNamesDrawTheSharedConcept() {
        XCTAssertEqual(flareIconMap["error"], "exclamationmark.circle", "an x-circle reads as cancel")
        XCTAssertEqual(flareIconMap["location"], "mappin.and.ellipse", "a map pin, not the current-position arrow")
        XCTAssertEqual(flareIconMap["devices"], "laptopcomputer.and.iphone", "more than one device")
        XCTAssertEqual(flareIconMap["poll"], "chart.bar")
        XCTAssertEqual(flareIconMap["language"], "globe")
    }

    /// The glyphs chosen for concepts SF Symbols has no symbol for at the iOS 16 floor.
    func testSubstitutedConceptsUseSymbolsAvailableAtTheFloor() {
        XCTAssertEqual(flareIconMap["translate"], "character.bubble", "`translate` needs iOS 17.4")
        XCTAssertEqual(flareIconMap["read"], "envelope.open", "no double check in SF Symbols")
        XCTAssertEqual(flareIconMap["silence"], "waveform.slash", "no slashed speech bubble in SF Symbols")
        XCTAssertNotEqual(flareIconMap["silence"], flareIconMap["speaker-off"])
        XCTAssertNotEqual(flareIconMap["silence"], flareIconMap["mic-off"])
        XCTAssertEqual(flareIconMap["screen-share"], "rectangle.on.rectangle")
        XCTAssertNotEqual(flareIconMap["end-call"], flareIconMap["phone"], "hang up is its own glyph")
        XCTAssertNotEqual(flareIconMap["unpin"], flareIconMap["pin"])
        XCTAssertNotEqual(flareIconMap["remove-member"], flareIconMap["logout"])
        XCTAssertNotEqual(flareIconMap["transfer-owner"], flareIconMap["star"])
        XCTAssertNotEqual(flareIconMap["clear-history"], flareIconMap["delete"])
    }

    /// Concepts that were drawn under a name meaning something else, and now have their own.
    func testConceptsDrawnUnderAnotherNameGotTheirOwn() {
        let expected = ["pin-self": "bookmark", "diagnostics": "ladybug", "card": "person.crop.rectangle",
                        "id": "number", "join-request": "tray.and.arrow.down", "storage": "internaldrive"]
        XCTAssertEqual(Array(flareIconNames.suffix(10).dropLast(4)),
                       ["pin-self", "diagnostics", "card", "id", "join-request", "storage"])
        for (name, symbol) in expected { XCTAssertEqual(flareIconMap[name], symbol, name) }
        for (name, before) in [("pin-self", "pin"), ("card", "person"), ("id", "info"), ("id", "tag"),
                               ("join-request", "person-add"), ("join-request", "notification"),
                               ("storage", "folder"), ("diagnostics", "info")] {
            XCTAssertNotEqual(flareIconMap[name], flareIconMap[before], "\(name) no longer draws \(before)")
        }
    }

    /// Every symbol exists in the SF Symbols catalogue of the host and was introduced no later than
    /// iOS 16 / macOS 13 (the 2022 release), the package's deployment floor.
    func testEverySymbolIsInTheCatalogueAtTheDeploymentFloor() throws {
        let path = "/System/Library/CoreServices/CoreGlyphs.bundle/Contents/Resources/name_availability.plist"
        try XCTSkipUnless(FileManager.default.fileExists(atPath: path), "no SF Symbols catalogue on this host")
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let plist = try XCTUnwrap(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        let symbols = try XCTUnwrap(plist["symbols"] as? [String: String])
        let releases = try XCTUnwrap(plist["year_to_release"] as? [String: [String: String]])
        func iOSVersion(_ year: String) -> [Int] { (releases[year]?["iOS"] ?? "99").split(separator: ".").compactMap { Int($0) } }
        for (name, symbol) in flareIconMap {
            let year = try XCTUnwrap(symbols[symbol], "\(name): \(symbol) is not an SF Symbol")
            if let floor = flareIconFloorSymbols[name] {
                // A newer symbol has a floor symbol that every supported system has.
                let floorYear = try XCTUnwrap(symbols[floor], "\(name): \(floor) is not an SF Symbol")
                XCTAssertTrue(iOSVersion(floorYear).lexicographicallyPrecedes([16, 1]), "\(name): \(floor) needs iOS \(iOSVersion(floorYear))")
                XCTAssertTrue(iOSVersion(year).lexicographicallyPrecedes([18, 1]), "\(name): \(symbol) is drawn from iOS 18")
                continue
            }
            XCTAssertTrue(iOSVersion(year).lexicographicallyPrecedes([16, 1]), "\(name): \(symbol) needs iOS \(iOSVersion(year))")
        }
        XCTAssertEqual(Set(flareIconFloorSymbols.keys).subtracting(flareIconMap.keys), [], "a floor symbol for a registry name")
        XCTAssertEqual(flareIconMap["wallet"], "wallet.bifold")
        if #available(macOS 15.0, *) { XCTAssertEqual(flareIconSymbol("wallet"), "wallet.bifold") }
    }

    func testIconViewDrawsTheRegistrySymbolAndHidesDecorativeIcons() throws {
        let image = try IconView("end-call").inspect().image()
        XCTAssertEqual(try image.actualImage().name(), "phone.down")
        XCTAssertTrue(try image.accessibilityHidden())
        XCTAssertEqual(try IconView("no-such-icon").inspect().image().actualImage().name(), flareIconMap["plugin"])
        XCTAssertThrowsError(try IconView("").inspect().image(), "an empty name draws nothing")
    }

    // MARK: Header action aliases

    func testAHeaderActionWithoutAnIconDrawsItsAliasNeverMore() {
        func symbol(_ id: String, icon: String? = nil) -> String {
            ConversationHeaderView.symbol(ConversationHeaderAction(id: id, label: id, icon: icon))
        }
        XCTAssertEqual(symbol("audioCall"), flareIconMap["phone"])
        XCTAssertEqual(symbol("videoCall"), flareIconMap["video"])
        XCTAssertEqual(symbol("addMember"), flareIconMap["person-add"])
        XCTAssertEqual(symbol("details"), flareIconMap["info"])
        XCTAssertEqual(symbol("search"), flareIconMap["search"], "an id that is a kit name draws that name")
        XCTAssertEqual(symbol("videoCall", icon: "share"), flareIconMap["share"], "an explicit icon wins")
        XCTAssertEqual(symbol("export"), flareIconMap["plugin"], "an unknown id draws the plugin glyph")
        for id in ["audioCall", "videoCall", "addMember", "details", "export"] {
            XCTAssertNotEqual(symbol(id), flareIconMap["more"], "\(id) never draws more")
        }
    }

    func testHeaderMenuItemsResolveTheSameAliases() {
        func item(_ id: String, icon: String? = nil) -> FlareActionItem {
            ConversationHeaderView.menuItem(ConversationHeaderAction(id: id, label: id, icon: icon, placement: .overflow),
                                            kind: .direct, strings: FlareStrings())
        }
        XCTAssertEqual(item("details").icon, "details")
        XCTAssertEqual(ActionMenuRules.symbol(item("details")), flareIconMap["info"])
        XCTAssertEqual(ActionMenuRules.symbol(item("videoCall")), flareIconMap["video"])
        XCTAssertNil(item("export").icon, "an id that names no icon leaves the row text-only")
        XCTAssertNil(ActionMenuRules.symbol(item("export")))
        XCTAssertEqual(ActionMenuRules.symbol(item("export", icon: "download")), flareIconMap["download"])
    }

    @MainActor
    func testThePrimaryButtonOfAnIconlessCallActionDrawsThePhoneInA44ptTarget() throws {
        let header = ConversationHeaderView(
            identity: ConversationIdentity(id: "c1", title: "Ada"),
            configuration: ConversationHeaderConfiguration(replaceDefaults: true),
            actions: [ConversationHeaderAction(id: "audioCall", label: "Start audio call")],
            onAction: { _ in })
        // The kit's default English label is shown in the strings table's words.
        let button = try header.inspect().find(ViewType.Button.self, where: {
            try $0.accessibilityLabel().string() == FlareStrings().conversationHeaderAudioCall
        })
        XCTAssertEqual(try button.labelView().find(ViewType.Image.self).actualImage().name(), flareIconMap["phone"])
        // The target is the label's own frame; a frame set on a borderless button from outside is not hit.
        XCTAssertGreaterThanOrEqual(try button.labelView().flexFrame().minWidth, FlareSizes.touchTargetMin)
        XCTAssertGreaterThanOrEqual(try button.labelView().flexFrame().minHeight, FlareSizes.touchTargetMin)
    }

    // MARK: Shared contract tables

    func testContractTablesUseRegistryNames() {
        XCTAssertEqual(FlareMemberRoleAction.allCases.map { MemberRoleSheetView.symbol(for: $0) },
                       FlareMemberRoleAction.allCases.map { action -> String? in
                           switch action {
                           case .promote, .demote: return flareIconMap["admin"]
                           case .mute, .unmute: return flareIconMap["silence"]
                           case .transferOwner: return flareIconMap["transfer-owner"]
                           case .remove: return flareIconMap["remove-member"]
                           }
                       }.compactMap { $0 })
        XCTAssertEqual(GroupPermissionMatrixView.symbol(for: .muteAll), flareIconMap["silence"])
        let actions = messageMenuActions(FlareMessageActionAvailability(canCopy: true, canDelete: true, canRecall: true,
                                                                        canUnpin: true, canMultiSelect: true, canSave: true),
                                         strings: FlareStrings())
        let symbols = Dictionary(uniqueKeysWithValues: actions.map { ($0.id, flareIconSymbol($0.icon)) })
        XCTAssertEqual(symbols["recall"], flareIconMap["recall"])
        XCTAssertEqual(symbols["unpin"], flareIconMap["unpin"])
        XCTAssertEqual(symbols["multiSelect"], flareIconMap["multi-select"])
        XCTAssertEqual(symbols["mark"], flareIconMap["mark"])
        XCTAssertEqual(symbols["save"], flareIconMap["download"])
    }

    /// `red-packet` follows the concept names and the kit draws it: SF Symbols has no red packet. A raw symbol of
    /// the name falls back to the envelope.
    @MainActor
    func testRedPacketIsTheKitsOwnGlyph() throws {
        XCTAssertEqual(Array(flareIconNames.suffix(4)), ["red-packet", "plugin", "locate", "wallet"])
        XCTAssertEqual(flareIconMap["red-packet"], "envelope")
        XCTAssertTrue(flareKitGlyphNames.contains("red-packet"))
        XCTAssertNoThrow(try IconView("red-packet").inspect().find(FlareRedPacketIcon.self))
        XCTAssertThrowsError(try IconView("star").inspect().find(FlareRedPacketIcon.self))
        XCTAssertNoThrow(try ButtonView(label: "Packet", icon: "red-packet", action: {}).inspect().find(FlareRedPacketIcon.self))
        XCTAssertNoThrow(try IconButtonView(icon: "red-packet", accessibilityLabel: "Packet", action: {}).inspect()
            .find(FlareRedPacketIcon.self))
    }

    /// `plugin` is the generic plugin glyph, a single-colour puzzle piece, which a plugin's "+" tile draws when its
    /// icon is not a registry name.
    func testPluginIsAPuzzlePiece() throws {
        XCTAssertEqual(flareIconNames.dropLast(2).last, "plugin")
        XCTAssertEqual(flareIconMap["plugin"], "puzzlepiece.extension")
        XCTAssertFalse(flareKitGlyphNames.contains("plugin"), "SF Symbols has the concept")
        XCTAssertEqual(try IconView("plugin").inspect().image().actualImage().name(), "puzzlepiece.extension")
    }

    /// `locate` is the location picker's "use current location" key, a crosshair unlike the `location` pin; only
    /// `wallet` follows it.
    func testLocateIsTheLastNameAndACrosshair() throws {
        XCTAssertEqual(flareIconNames.dropLast().last, "locate")
        XCTAssertEqual(flareIconMap["locate"], "scope")
        XCTAssertNotEqual(flareIconMap["locate"], flareIconMap["location"])
        XCTAssertEqual(try IconView("locate").inspect().image().actualImage().name(), "scope")
    }
}
