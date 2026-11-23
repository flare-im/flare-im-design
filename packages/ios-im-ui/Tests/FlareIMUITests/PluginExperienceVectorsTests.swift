import XCTest
@testable import FlareIMUI

/// docs/plugin-experience.md §2 (R1–R12) against the shared tables: `spec/plugin-view-vectors.json` (actionRoles,
/// statusValues, references, blockBoundInputs, cardHeader, refreshKey, accountDerivation, formPlacement, formCounter,
/// selectOptions, actionDedupe, result, pageStates, statusCard) and `spec/plugin-refresh-vectors.json` (afterAction,
/// afterReturn). The same rows run in the Vue, Flutter and Compose kits.
final class PluginExperienceVectorsTests: XCTestCase {
    private let s = FlareStrings()

    private func spec(_ name: String) throws -> PluginJSONValue {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let data = try Data(contentsOf: root.appendingPathComponent("spec/\(name)"))
        return try JSONDecoder().decode(PluginJSONValue.self, from: data)
    }

    private func decode<T: Decodable>(_ type: T.Type, _ json: PluginJSONValue?) throws -> T {
        try JSONDecoder().decode(T.self, from: JSONEncoder().encode(try XCTUnwrap(json)))
    }

    /// A view of the table: the groups write only what they test, so a view without `available` is an available one.
    private func viewModel(_ json: PluginJSONValue?) throws -> PluginViewModel {
        var object = try XCTUnwrap(json?.objectValue)
        if object["available"] == nil { object["available"] = true }
        if object["title"] == nil { object["title"] = "" }
        return try decode(PluginViewModel.self, .object(object))
    }

    /// The rows of a group that run on iOS (a row without platforms runs everywhere).
    private func rows(_ group: String, in table: PluginJSONValue) throws -> [PluginJSONValue] {
        let all = try XCTUnwrap(table[group]?.arrayValue, "the table lost \(group)")
        let mine = all.filter { row in
            guard let platforms = row["platforms"]?.arrayValue else { return true }
            return platforms.contains(.string("ios"))
        }
        XCTAssertFalse(mine.isEmpty, "\(group) has no iOS rows")
        return mine
    }

    private func name(_ row: PluginJSONValue) -> String { row["name"]?.stringValue ?? "?" }
    private func ids(_ value: PluginJSONValue?) -> [String] { (value?.arrayValue ?? []).compactMap(\.stringValue) }

    // MARK: R2

    func testActionRolesPlaceEveryAction() throws {
        for row in try rows("actionRoles", in: try spec("plugin-view-vectors.json")) {
            let view = try viewModel(row["view"])
            let places = PluginExperienceRules.places(view, embedded: row["embedded"]?.boolValue ?? false,
                                                      inlineFormActionId: row["inlineFormActionId"]?.stringValue)
            let expect = try XCTUnwrap(row["expect"])
            XCTAssertEqual(places.archetype.rawValue, expect["archetype"]?.stringValue, name(row))
            let want = expect["places"]?.objectValue ?? [:]
            let got: [String: [String]] = [
                "quick": places.quick.map(\.id), "bar": places.bar.map(\.id), "barSecondary": places.barSecondary.map(\.id),
                "more": places.more.map(\.id), "header": places.header.map(\.id), "commands": places.commands.map(\.id),
                "danger": places.danger.map(\.id), "footer": places.footer.map(\.id), "menu": places.menu.map(\.id),
            ]
            for (place, drawn) in got {
                XCTAssertEqual(drawn, ids(want[place]), "\(name(row)) \(place)")
            }
            let lists = (want["list"]?.arrayValue ?? []).map { ($0["group"]?.stringValue, ids($0["ids"])) }
            XCTAssertEqual(places.list.map(\.group), lists.map(\.0), "\(name(row)) list groups")
            XCTAssertEqual(places.list.map { $0.actions.map(\.id) }, lists.map(\.1), "\(name(row)) list rows")
            let actions = view.actions + view.menuActions
            for (id, role) in expect["roles"]?.objectValue ?? [:] {
                let action = try XCTUnwrap(actions.first { $0.id == id })
                XCTAssertEqual(PluginExperienceRules.role(action).rawValue, role.stringValue, "\(name(row)) \(id)")
            }
            if let chevron = expect["chevron"] {
                let listed = places.list.flatMap(\.actions)
                XCTAssertEqual(listed.filter { PluginExperienceRules.role($0) == .destination }.map(\.id), ids(chevron),
                               "\(name(row)) chevrons")
            }
        }
    }

    /// §6.3: a capture action writing `into` an input of the page's inline form is that input's slot, not a key; a
    /// capture into an input outside that form, and every capture without an inline form, stays a key.
    func testCaptureIntoTheInlineFormIsNotAKey() throws {
        let view = try viewModel([
            "actions": [
                ["id": "submit", "label": "提交", "style": "primary", "form": ["front", "note"],
                 "target": ["kind": "operation", "operation": "submit"]],
                ["id": "captureFront", "label": "拍正面",
                 "target": ["kind": "native", "capability": "documentCapture", "into": "front"]],
                ["id": "captureOther", "label": "拍其他",
                 "target": ["kind": "native", "capability": "documentCapture", "into": "other"]],
            ],
            "inputs": [["id": "front", "kind": "document", "label": "正面"], ["id": "note", "kind": "text", "label": "备注"],
                       ["id": "other", "kind": "document", "label": "其他"]],
        ])
        func drawn(_ inline: String?) -> [String] {
            let places = PluginExperienceRules.places(view, embedded: true, inlineFormActionId: inline)
            return [places.quick, places.bar, places.barSecondary, places.more, places.header, places.commands,
                    places.danger, places.list.flatMap(\.actions)].flatMap { $0.map(\.id) }
        }
        XCTAssertFalse(drawn("submit").contains("captureFront"), "the inline form's input slot runs it")
        XCTAssertTrue(drawn("submit").contains("captureOther"), "an input outside the inline form keeps its key")
        XCTAssertTrue(drawn(nil).contains("captureFront"), "without an inline form the capture is a key")
    }

    func testDuplicateLabelsDrawOnce() throws {
        for row in try rows("actionDedupe", in: try spec("plugin-view-vectors.json")) {
            let actions = try decode([PluginViewAction].self, row["actions"])
            let result = PluginExperienceRules.dedupe(actions)
            XCTAssertEqual(result.drawn.map(\.id), ids(row["expect"]?["drawn"]), name(row))
            XCTAssertEqual(!result.dropped.isEmpty, row["expect"]?["warn"]?.boolValue, name(row))
        }
    }

    /// R2.5: an action the core marked with a reason draws disabled in its usual place, the reason under it; a hidden
    /// one is not in the view at all.
    func testDisabledActionsKeepTheirPlaceAndSayWhy() throws {
        for row in try rows("actionDisabled", in: try spec("plugin-view-vectors.json")) {
            let actions = try decode([PluginViewAction].self, row["actions"])
            let view = PluginViewModel(available: true, title: "", actions: actions)
            let drawn = PluginExperienceRules.topLevelActions(view, embedded: true)
            let expect = try XCTUnwrap(row["expect"])
            XCTAssertEqual(drawn.map(\.id), ids(expect["drawn"]), name(row))
            XCTAssertEqual(drawn.filter { $0.disabledReason != nil }.map(\.id), ids(expect["disabled"]), name(row))
            var captions: [String: String] = [:]
            for action in drawn { captions[action.id] = action.disabledReason }
            XCTAssertEqual(captions, (expect["captions"]?.objectValue ?? [:]).compactMapValues(\.stringValue), name(row))
        }
    }

    // MARK: R3

    func testStatusValuesDrawTagsAndNeverTheRawUnmappedValue() throws {
        for row in try rows("statusValues", in: try spec("plugin-view-vectors.json")) {
            let item = row["item"]
            let draw: PluginStatusDraw
            switch row["where"]?.stringValue {
            case "field":
                let field = try decode(PluginViewField.self, item)
                draw = PluginExperienceRules.statusDraw(text: field.value, tone: field.tone, unmapped: field.unmapped)
            case "cell":
                let cell = try decode(PluginRowCell.self, item)
                draw = PluginExperienceRules.statusDraw(text: cell.text, tone: cell.tone, unmapped: cell.unmapped)
            case "status":
                let block = try decode(PluginStatusBlock.self, item)
                draw = PluginExperienceRules.statusDraw(text: block.text, tone: block.tone, unmapped: block.unmapped)
            default:
                let badge = try decode(PluginBadge.self, item)
                draw = PluginExperienceRules.statusDraw(text: badge.text, tone: badge.tone, unmapped: badge.unmapped)
            }
            let expect = try XCTUnwrap(row["expect"])
            XCTAssertEqual(draw.tag ? "tag" : "text", expect["draw"]?.stringValue, name(row))
            XCTAssertEqual(draw.unknown, expect["unknown"]?.boolValue ?? false, name(row))
            if let tone = expect["tone"]?.stringValue { XCTAssertEqual(draw.tone?.rawValue, tone, name(row)) }
            if let text = expect["text"]?.stringValue { XCTAssertEqual(draw.text, text, name(row)) }
            if draw.unknown { XCTAssertTrue(draw.text.isEmpty, "\(name(row)) never draws the raw value") }
        }
    }

    func testReferenceFieldsFoldAfterTheOthers() throws {
        for row in try rows("references", in: try spec("plugin-view-vectors.json")) {
            let split = PluginExperienceRules.splitReferences(try decode([PluginViewField].self, row["fields"]))
            XCTAssertEqual(split.main.map(\.label), ids(row["expect"]?["main"]), name(row))
            XCTAssertEqual(split.references.map(\.label), ids(row["expect"]?["references"]), name(row))
        }
    }

    // MARK: R5, R6.1

    func testCardHeadOrder() throws {
        for row in try rows("cardHeader", in: try spec("plugin-view-vectors.json")) {
            let head = PluginExperienceRules.cardHead(detail: row["detail"]?.boolValue ?? false,
                                                      footerActions: Int(row["footerActions"]?.numberValue ?? 0),
                                                      menuActions: Int(row["menuActions"]?.numberValue ?? 0))
            XCTAssertEqual(head.order, ids(row["expect"]?["order"]), name(row))
            if let inFooter = row["expect"]?["detailInFooter"]?.boolValue {
                XCTAssertEqual(head.detailInFooter, inFooter, name(row))
            }
        }
    }

    func testBlockBoundInputsAreNeverFields() throws {
        for row in try rows("blockBoundInputs", in: try spec("plugin-view-vectors.json")) {
            let view = try viewModel(row["view"])
            let bound = PluginExperienceRules.boundInputs(view)
            var fields: [String] = []
            for action in view.actions {
                for input in PluginExperienceRules.drawnInputs(view, action) where !fields.contains(input.id) {
                    fields.append(input.id)
                }
            }
            let expect = try XCTUnwrap(row["expect"])
            XCTAssertEqual(fields, ids(expect["formFields"]), name(row))
            XCTAssertEqual(PluginExperienceRules.topLevelActions(view, embedded: true).map(\.id), ids(expect["topLevel"]),
                           name(row))
            XCTAssertEqual(view.actions.filter { PluginExperienceRules.isBlockAction($0, bound: bound) }.map(\.id),
                           ids(expect["blockActions"]), name(row))
            XCTAssertEqual(PluginExperienceRules.pageInlineForm(view, hasAction: true),
                           expect["inlineFormActionId"]?.stringValue, name(row))
        }
    }

    // MARK: R1, R12

    func testRefreshKeyOnlyOnDataPages() throws {
        for row in try rows("refreshKey", in: try spec("plugin-view-vectors.json")) {
            let view = try viewModel(row["view"])
            XCTAssertEqual(PluginExperienceRules.showsRefreshKey(view, inlineFormActionId: row["inlineFormActionId"]?.stringValue),
                           row["expect"]?.boolValue, name(row))
        }
    }

    func testAccountAppearanceIsDerivedFromStructure() throws {
        for row in try rows("accountDerivation", in: try spec("plugin-view-vectors.json")) {
            let view = try viewModel(row["view"])
            let explicit: FlarePluginPageAppearance? = switch row["appearance"]?.stringValue {
            case "account": .account
            case "document": .document
            default: nil
            }
            let derived = PluginExperienceRules.appearance(explicit, view)
            XCTAssertEqual(derived == .account ? "account" : "document", row["expect"]?.stringValue, name(row))
        }
    }

    // MARK: R6

    func testFormPlacementCounterAndSelect() throws {
        let table = try spec("plugin-view-vectors.json")
        for row in try rows("formPlacement", in: table) {
            let kinds = try ids(row["inputs"]).map { try XCTUnwrap(PluginInputKind(rawValue: $0)) }
            XCTAssertEqual(PluginExperienceRules.formPlacement(kinds, inline: row["inline"]?.boolValue ?? false).rawValue,
                           row["expect"]?.stringValue, name(row))
        }
        for row in try rows("formCounter", in: table) {
            XCTAssertEqual(PluginExperienceRules.showsCounter(maxLength: row["maxLength"]?.numberValue.map { Int($0) },
                                                              length: Int(row["length"]?.numberValue ?? 0)),
                           row["expect"]?.boolValue, name(row))
        }
        for row in try rows("selectOptions", in: table) {
            let control = PluginExperienceRules.selectControl(choices: Int(row["choices"]?.numberValue ?? 0))
            let expect = try XCTUnwrap(row["expect"])
            XCTAssertEqual(control.control.rawValue, expect["control"]?.stringValue, name(row))
            XCTAssertEqual(control.disabled, expect["disabled"]?.boolValue, name(row))
            XCTAssertEqual(control.disabled, expect["submitDisabled"]?.boolValue, "\(name(row)) submit")
            if expect["placeholder"]?.stringValue == "pluginView.noOptions" { XCTAssertFalse(s.pluginViewNoOptions.isEmpty) }
        }
    }

    // MARK: R7, R8, 6.1

    func testResultBlockFacts() throws {
        for row in try rows("result", in: try spec("plugin-view-vectors.json")) {
            let block = try decode(PluginResultBlock.self, row["block"])
            let facts = PluginExperienceRules.resultFacts(block, unknownTitle: s.pluginViewUnknownStatus)
            let expect = try XCTUnwrap(row["expect"])
            XCTAssertEqual(facts.icon, expect["icon"]?.stringValue, name(row))
            XCTAssertEqual(facts.tone.rawValue, expect["tone"]?.stringValue, name(row))
            XCTAssertEqual(facts.unknown, expect["unknown"]?.boolValue ?? false, name(row))
            XCTAssertEqual(facts.title, expect["title"]?.stringValue ?? s.pluginViewUnknownStatus, name(row))
            XCTAssertEqual(facts.poll, expect["poll"]?.boolValue, name(row))
            if let announce = expect["announce"]?.stringValue { XCTAssertEqual(facts.announce, announce, name(row)) }
            if facts.poll {
                XCTAssertEqual(PluginExperienceRules.resultPollMs, Int(expect["pollMs"]?.numberValue ?? 0), name(row))
                XCTAssertEqual(PluginExperienceRules.resultPollForMs, Int(expect["pollForMs"]?.numberValue ?? 0), name(row))
            }
        }
    }

    func testPageStates() throws {
        for row in try rows("pageStates", in: try spec("plugin-view-vectors.json")) {
            // `nil` here would be PluginJSONValue's nil literal (.null), so test `isNull` and build the view directly.
            let view: PluginViewModel? = try row["view"].flatMap { $0.isNull ? nil : try viewModel($0) }
            let face = PluginExperienceRules.face(loading: row["loading"]?.boolValue ?? false,
                                                  elapsedMs: Int(row["elapsedMs"]?.numberValue ?? 0),
                                                  error: row["error"]?.stringValue, hasView: view != nil)
            let expect = try XCTUnwrap(row["expect"])
            switch expect["state"]?.stringValue {
            case "blank": XCTAssertEqual(face, .blank, name(row))
            case "skeleton": XCTAssertEqual(face, .skeleton(rows: Int(expect["rows"]?.numberValue ?? 0)), name(row))
            case "error": XCTAssertEqual(face, .error, name(row))
            default: XCTAssertEqual(face, .loaded, name(row))
            }
            if let empty = expect["blockEmpty"], let view {
                let places = PluginExperienceRules.places(view, embedded: true, inlineFormActionId: nil)
                XCTAssertEqual(PluginExperienceRules.emptyCreateAction(view, places: places)?.id,
                               empty["action"]?.stringValue, name(row))
                XCTAssertEqual(view.rowsBlock?.emptyText, empty["title"]?.stringValue, name(row))
            }
        }
    }

    func testStatusCardIsDeclaredOrDerived() throws {
        for row in try rows("statusCard", in: try spec("plugin-view-vectors.json")) {
            XCTAssertEqual(PluginExperienceRules.statusCard(try viewModel(row["view"])),
                           row["expect"]?.boolValue, name(row))
        }
    }

    // MARK: R4

    func testRefreshAfterActionAndReturn() throws {
        let table = try spec("plugin-refresh-vectors.json")
        for row in try XCTUnwrap(table["afterAction"]?.arrayValue) {
            let settle = try XCTUnwrap(PluginRefreshRules.Settle(rawValue: row["settle"]?.stringValue ?? ""))
            let reason = PluginRefreshRules.afterAction(settle, visible: row["visible"]?.boolValue ?? true)
            XCTAssertEqual(reason != nil, row["expect"]?["refresh"]?.boolValue, name(row))
            if let want = row["expect"]?["reason"]?.stringValue { XCTAssertEqual(reason?.rawValue, want, name(row)) }
        }
        for row in try XCTUnwrap(table["afterReturn"]?.arrayValue) {
            let event = try XCTUnwrap(PluginRefreshRules.Return(rawValue: row["event"]?.stringValue ?? ""))
            let result = PluginRefreshRules.afterReturn(event, origin: row["origin"]?.boolValue ?? false)
            XCTAssertEqual(result.refresh, row["expect"]?["refresh"]?.boolValue, name(row))
            XCTAssertEqual(result.page, row["expect"]?["page"]?.stringValue, name(row))
        }
    }
}
