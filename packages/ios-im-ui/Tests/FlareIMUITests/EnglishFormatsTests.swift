import XCTest
@testable import FlareIMUI

/// `strings/en-formats.json`: the fields of `FlareStrings` that are functions, in Chinese (the defaults) and in English
/// (`FlareStrings.english`) for the table's arguments.
final class EnglishFormatsTests: XCTestCase {
    private func cases() throws -> [PluginJSONValue] {
        try XCTUnwrap(try SpecVectors.table("../strings/en-formats.json")["cases"]?.arrayValue)
    }

    /// A case's arguments: numbers, strings, `{kind}` and `{state}`, in order within each type.
    private struct Args {
        let values: [PluginJSONValue]
        func int(_ index: Int) -> Int { values.compactMap(\.intValue)[index] }
        func text(_ index: Int) -> String { values.compactMap(\.stringValue)[index] }
        func kind() throws -> FlarePermissionKind {
            try XCTUnwrap(values.first?["kind"]?.stringValue.flatMap(FlarePermissionKind.init(rawValue:)))
        }
        func state() throws -> FlarePermissionState {
            try XCTUnwrap(values.first?["state"]?.stringValue.flatMap(FlarePermissionState.init(rawValue:)))
        }
    }

    /// The function field `field` of `s` for `a`; nil for a name that is not one.
    private func render(_ s: FlareStrings, _ field: String, _ a: Args) throws -> String? {
        switch field {
        case "readTab": return s.readTab(a.int(0))
        case "unreadTab": return s.unreadTab(a.int(0))
        case "viewAll": return s.viewAll(a.int(0))
        case "typingOne": return s.typingOne(a.text(0))
        case "typingMany": return s.typingMany(a.int(0))
        case "newMessages": return s.newMessages(a.int(0))
        case "joinedCount": return s.joinedCount(a.int(0), a.text(0))
        case "selfSuffix": return s.selfSuffix(a.text(0))
        case "selectedCount": return s.selectedCount(a.int(0))
        case "packetFromSender": return s.packetFromSender(a.text(0))
        case "translatedBy": return s.translatedBy(a.text(0))
        case "pollOptionHint": return s.pollOptionHint(a.int(0))
        case "yearMonth": return s.yearMonth(a.int(0), a.int(1))
        case "confirmCount": return s.confirmCount(a.int(0))
        case "memberCount": return s.memberCount(a.int(0))
        case "wordCharCount": return s.wordCharCount(a.int(0), a.int(1))
        case "permissionNoun": return s.permissionNoun(try a.kind())
        case "permissionVerb": return s.permissionVerb(try a.kind())
        case "permissionTitle": return s.permissionTitle(a.text(0))
        case "permissionUndeterminedBody": return s.permissionUndeterminedBody(a.text(0), a.text(1))
        case "permissionDeniedBody": return s.permissionDeniedBody(a.text(0), a.text(1))
        case "permissionRestrictedBody": return s.permissionRestrictedBody(a.text(0), a.text(1))
        case "permissionUnavailableBody": return s.permissionUnavailableBody(a.text(0), a.text(1))
        case "permissionStateLabel": return s.permissionStateLabel(try a.state())
        case "messageImageGroupLabel": return s.messageImageGroupLabel(a.int(0))
        case "messageImageGroupItem": return s.messageImageGroupItem(a.int(0), a.int(1))
        case "messageImageGroupItemMore": return s.messageImageGroupItemMore(a.int(0), a.int(1), a.int(2))
        case "messageRecalledGroupOther": return s.messageRecalledGroupOther(a.text(0))
        case "messageQuoteLabel": return s.messageQuoteLabel(a.text(0), a.text(1))
        case "jumpedToMessage": return s.jumpedToMessage(a.text(0), a.text(1))
        case "conversationHeaderIdentityLabel": return s.conversationHeaderIdentityLabel(a.text(0), a.text(1))
        case "momentAudienceSheetSelected": return s.momentAudienceSheetSelected(a.int(0))
        case "announcementReadBarReadCount": return s.announcementReadBarReadCount(a.int(0), a.int(1))
        case "imagePreviewPosition": return s.imagePreviewPosition(a.int(0), a.int(1))
        case "voiceSeconds": return s.voiceSeconds(a.int(0))
        case "ratingStar": return s.ratingStar(a.int(0))
        case "connectionDisconnectedReason": return s.connectionDisconnectedReason(a.text(0))
        case "groupDetailMembersTitle": return s.groupDetailMembersTitle(a.int(0))
        case "profilePanelEditProfile": return s.profilePanelEditProfile(a.text(0))
        case "momentReplyToComment": return s.momentReplyToComment(a.text(0), a.text(1))
        case "previewImageNamed": return s.previewImageNamed(a.text(0))
        case "previewFileNamed": return s.previewFileNamed(a.text(0))
        case "previewLocationNamed": return s.previewLocationNamed(a.text(0))
        case "previewCardNamed": return s.previewCardNamed(a.text(0))
        case "previewForwardCount": return s.previewForwardCount(a.int(0))
        case "previewImageGroupCount": return s.previewImageGroupCount(a.int(0))
        case "systemEventGroupProfileUpdatedNamed": return s.systemEventGroupProfileUpdatedNamed(a.text(0))
        default: return nil
        }
    }

    func testEveryCaseReadsAsTheTableSays() throws {
        var checked = 0
        for vector in try cases() where vector["kits"]?.arrayValue?.contains(.string("ios")) == true {
            let field = try XCTUnwrap(vector["field"]?.stringValue)
            let args = Args(values: vector["args"]?.arrayValue ?? [])
            let id = "\(field)(\(args.values.map { $0.stringValue ?? $0.intValue.map(String.init) ?? "\($0)" }.joined(separator: ", ")))"
            XCTAssertEqual(try render(FlareStrings(), field, args), vector["zh"]?.stringValue, "\(id) zh")
            XCTAssertEqual(try render(FlareStrings.english, field, args), vector["en"]?.stringValue, "\(id) en")
            checked += 1
        }
        XCTAssertGreaterThanOrEqual(checked, 50)
    }

    /// Every function field the kit declares has a case listing ios, and at least one of them reads differently in
    /// English — so a count field added later cannot stay Chinese in the English preset.
    func testEveryFunctionFieldHasAnEnglishCase() throws {
        let functions = Mirror(reflecting: FlareStrings()).children.compactMap { child -> String? in
            guard let label = child.label, String(describing: type(of: child.value)).contains("->") else { return nil }
            return label
        }
        XCTAssertGreaterThanOrEqual(functions.count, 40, "the kit's function fields were not found")
        let vectors = try cases().filter { $0["kits"]?.arrayValue?.contains(.string("ios")) == true }
        for field in functions {
            let mine = vectors.filter { $0["field"]?.stringValue == field }
            XCTAssertFalse(mine.isEmpty, "\(field): no case in strings/en-formats.json lists ios")
            XCTAssertTrue(mine.contains { $0["en"] != $0["zh"] }, "\(field): no case where English differs")
        }
    }

    func testACountTakesTheEnglishOneFormAtOne() {
        let en = FlareStrings.english
        XCTAssertEqual(en.previewForwardCount(1), "[Forward] 1 message")
        XCTAssertEqual(en.previewForwardCount(0), "[Forward] 0 messages")
        XCTAssertEqual(en.memberCount(21), "21 members")
        XCTAssertEqual(en.yearMonth(2026, 1), "January 2026")
    }
}
