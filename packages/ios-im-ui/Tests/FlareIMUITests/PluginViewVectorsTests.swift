import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// PluginView v2, PluginFormView and PluginDetailSheetView against `spec/plugin-view-vectors.json`, the table the four
/// kits run: every block's render facts (views), the optimistic choices (optimistic), time and countdown text (time,
/// countdown) and the form's check, values and error texts (form). Copy comes from the strings table.
final class PluginViewVectorsTests: XCTestCase {
    private let s = FlareStrings()
    private let en = FlareStrings.english

    // MARK: Table

    private func table() throws -> PluginJSONValue {
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { root.deleteLastPathComponent() }
        let data = try Data(contentsOf: root.appendingPathComponent("spec/plugin-view-vectors.json"))
        return try JSONDecoder().decode(PluginJSONValue.self, from: data)
    }

    private func decode<T: Decodable>(_ type: T.Type, _ json: PluginJSONValue?) throws -> T {
        try JSONDecoder().decode(T.self, from: JSONEncoder().encode(try XCTUnwrap(json)))
    }

    private func users(_ table: PluginJSONValue) throws -> [String: PluginUser] {
        try decode([String: PluginUser].self, table["users"])
    }

    private func views(_ table: PluginJSONValue) throws -> [String: (PluginViewModel, PluginJSONValue)] {
        var out: [String: (PluginViewModel, PluginJSONValue)] = [:]
        for entry in table["views"]?.arrayValue ?? [] {
            let platforms = (entry["platforms"]?.arrayValue ?? []).compactMap(\.stringValue)
            guard platforms.contains("ios"), let id = entry["id"]?.stringValue else { continue }
            out[id] = (try decode(PluginViewModel.self, entry["view"]), entry["expect"] ?? .null)
        }
        return out
    }

    private func nowMs(_ table: PluginJSONValue) -> Int64 { Int64(table["nowMs"]?.numberValue ?? 0) }
    private func offset(_ table: PluginJSONValue) -> Int { Int(table["utcOffsetMinutes"]?.numberValue ?? 0) }

    @MainActor
    private func card(_ view: PluginViewModel, table: PluginJSONValue, busyActionId: String? = nil,
                      embedded: Bool = false, displayName: String? = nil, viewerId: String? = nil,
                      onAction: ((String, PluginActionPayload) -> Void)? = { _, _ in },
                      onOpenDetail: (() -> Void)? = nil) throws -> PluginView {
        PluginView(view: view, icon: "poll", displayName: displayName, viewerId: viewerId, busy: false,
                   busyActionId: busyActionId, error: nil, embedded: embedded,
                   resolveUser: nil, members: [], formErrors: [], onAction: onAction, onOpenDetail: onOpenDetail,
                   clock: PluginViewClock(nowMs: nowMs(table), utcOffsetMinutes: offset(table)), users: try users(table))
    }

    /// The table's per-view host facts: embedded, the viewer, the envelope's display name.
    private func host(_ table: PluginJSONValue, _ id: String) -> (embedded: Bool, viewerId: String?, displayName: String?) {
        let entry = (table["views"]?.arrayValue ?? []).first { $0["id"]?.stringValue == id }
        return (entry?["embedded"]?.boolValue ?? false, entry?["viewerId"]?.stringValue, entry?["displayName"]?.stringValue)
    }

    private func string(_ value: PluginJSONValue?) -> String? { value?.stringValue }
    private func int(_ value: PluginJSONValue?) -> Int? { value?.numberValue.map { Int($0) } }

    // MARK: Views

    func testTheTableCoversTheNativeViews() throws {
        let views = try views(try table())
        for id in ["poll-open-single", "poll-open-multi", "poll-voted-single", "poll-voted-multi", "poll-closed",
                   "solitaire-more", "task", "schedule", "announcement", "blocks-misc", "v1", "unavailable"] {
            XCTAssertNotNil(views[id], "the shared table lost \(id)")
        }
        XCTAssertNil(views["admin-rows"], "rows are the Vue kit's only")
    }

    @MainActor
    func testEveryViewMatchesItsRenderFacts() throws {
        let table = try table()
        let users = try users(table)
        let now = nowMs(table)
        let zone = offset(table)
        for (id, (view, expect)) in try views(table) {
            let host = host(table, id)
            XCTAssertEqual(view.title, string(expect["title"]), id)
            let hidden = expect["bodyHidden"]?.boolValue ?? false
            XCTAssertEqual(!view.available, hidden, id)
            let blocks = hidden ? [] : view.blocks
            let facts = expect["blocks"]?.arrayValue ?? []
            XCTAssertEqual(blocks.map(\.kind), facts.compactMap { string($0["kind"]) }, "\(id) blocks")
            // An embedded view has no title row (the sheet or the page carries the title).
            var shown: [String] = host.embedded && view.available ? [] : [view.title]
            for (index, (block, fact)) in zip(blocks, facts).enumerated() {
                shown += try check(block, at: index, fact, users: users, viewerId: host.viewerId, nowMs: now, zone: zone,
                                   id: "\(id)#\(index)")
            }
            let fields = hidden ? [] : view.fields
            XCTAssertEqual(fields, try decode([PluginViewField].self, expect["fields"] ?? []), "\(id) fields")
            shown += fields.flatMap { [$0.label, $0.value] }
            let actions = hidden ? [] : view.actions
            let actionFacts = expect["actions"]?.arrayValue ?? []
            XCTAssertEqual(actions.map(\.id), actionFacts.compactMap { string($0["id"]) }, "\(id) actions")
            // Menu actions: the ⋯ key on a card, keys after the footer actions on an embedded view.
            let menuFacts = expect["menu"]?.arrayValue ?? []
            XCTAssertEqual((hidden ? [] : view.menuActions).map(\.id), menuFacts.compactMap { string($0["id"]) },
                           "\(id) menu")
            if !menuFacts.isEmpty {
                let keys = expect["menuPresentation"]?.stringValue == "keys"
                XCTAssertEqual(keys, host.embedded, "\(id) menu presentation")
                XCTAssertEqual(PluginView.showsMenuKey(view, embedded: host.embedded), !keys, "\(id) ⋯ key")
                XCTAssertEqual(PluginView.actionRow(view, embedded: host.embedded).map(\.id),
                               view.actions.map(\.id) + (keys ? view.menuActions.map(\.id) : []), "\(id) action row")
                XCTAssertEqual(PluginView.menuItems(view).map(\.danger),
                               menuFacts.map { $0["variant"]?.stringValue == "danger" }, "\(id) menu danger")
                if keys { shown += view.menuActions.map(\.label) }
            } else {
                XCTAssertFalse(PluginView.showsMenuKey(view, embedded: host.embedded), "\(id) no ⋯ key")
            }
            for (action, fact) in zip(view.menuActions, menuFacts) {
                XCTAssertEqual(action.label, string(fact["label"]), id)
                XCTAssertEqual(action.confirm, string(fact["confirm"]), "\(id) \(action.id) confirm")
                XCTAssertEqual(!(action.form ?? []).isEmpty, fact["form"]?.boolValue, "\(id) \(action.id) form")
            }
            // The reason line.
            let reason = PluginViewFormat.reasonLine(view, displayName: host.displayName, s)
            XCTAssertEqual(reason, string(expect["reason"]), "\(id) reason")
            if let reason { shown.append(reason) }
            for (action, fact) in zip(actions, actionFacts) {
                XCTAssertEqual(action.label, string(fact["label"]), id)
                let variant: String
                switch PluginViewFormat.variant(action) {
                case .danger: variant = "danger"
                case .primary: variant = "primary"
                default: variant = "secondary"
                }
                XCTAssertEqual(variant, string(fact["variant"]), "\(id) \(action.id) variant")
                XCTAssertEqual(action.confirm, string(fact["confirm"]), "\(id) \(action.id) confirm")
                XCTAssertEqual(!(action.form ?? []).isEmpty, fact["form"]?.boolValue, "\(id) \(action.id) form")
                shown.append(action.label)
            }
            if let opens = expect["seeAllOpensDetail"]?.boolValue {
                let more = blocks.contains { if case .entries(let e) = $0 { return e.more }; return false }
                XCTAssertEqual(more, opens, "\(id) see all")
            }

            // The drawn card shows every fact, and nothing of a hidden body.
            let tree = try card(view, table: table, embedded: host.embedded, displayName: host.displayName,
                                viewerId: host.viewerId).inspect()
            for text in Set(shown) where !text.isEmpty {
                XCTAssertNoThrow(try tree.find(text: text), "\(id) draws \(text)")
            }
            if hidden {
                for field in view.fields { XCTAssertThrowsError(try tree.find(text: field.value), "\(id) hides fields") }
                for action in view.actions { XCTAssertThrowsError(try tree.find(button: action.label), "\(id) hides actions") }
                XCTAssertThrowsError(try tree.find(PluginStatusBlockView.self), "\(id) hides blocks")
            }
        }
    }

    /// Checks one block's facts and returns the texts the card must draw for it.
    private func check(_ block: PluginBlock, at index: Int, _ fact: PluginJSONValue, users: [String: PluginUser],
                       viewerId: String? = nil, nowMs: Int64, zone: Int, id: String) throws -> [String] {
        var shown: [String] = []
        switch block {
        case .text(let text):
            XCTAssertEqual(text.text, string(fact["text"]), id)
            XCTAssertEqual(text.style.rawValue, string(fact["style"]), id)
            XCTAssertEqual(text.maxLines, int(fact["maxLines"]), id)
            shown.append(text.text)
        case .fields(let fields):
            XCTAssertEqual(fields.fields, try decode([PluginViewField].self, fact["fields"]), id)
            shown += fields.fields.flatMap { [$0.label, $0.value] }
        case .choices(let choices):
            let state = PluginChoicesInteraction()
            XCTAssertEqual(state.isInteractive(choices, at: index, locked: false), fact["interactive"]?.boolValue, id)
            XCTAssertEqual(choices.multiple, fact["multiple"]?.boolValue, id)
            if let submit = fact["submit"], submit != .null {
                XCTAssertEqual(choices.action?.label, string(submit["label"]), id)
                XCTAssertEqual(state.submitEnabled(choices, at: index), submit["enabled"]?.boolValue, id)
                shown.append(choices.action?.label ?? "")
            } else {
                XCTAssertFalse(choices.multiple && choices.action != nil && !choices.closed, "\(id) has no submit key")
            }
            let options = fact["options"]?.arrayValue ?? []
            XCTAssertEqual(choices.options.map(\.label), options.compactMap { string($0["label"]) }, id)
            let chosen = Set(state.shown(choices, at: index))
            for (option, f) in zip(choices.options, options) {
                XCTAssertEqual(chosen.contains(option.index), f["selected"]?.boolValue, "\(id) \(option.label) selected")
                let percent = PluginViewFormat.percentText(option, showResults: choices.showResults)
                let votes = PluginViewFormat.votesText(option, showResults: choices.showResults, s)
                XCTAssertEqual(percent, string(f["percentText"]), "\(id) \(option.label) percent")
                XCTAssertEqual(votes, string(f["votesText"]), "\(id) \(option.label) votes")
                XCTAssertEqual(choices.showResults ? option.percent : nil, int(f["bar"]), "\(id) \(option.label) bar")
                shown += [option.label, percent, votes].compactMap { $0 }
            }
            let footer = PluginViewFormat.choicesFooter(choices, s)
            XCTAssertEqual(footer, string(fact["footer"]), "\(id) footer")
            if let footer { shown.append(footer) }
        case .entries(let entries):
            let rows = fact["rows"]?.arrayValue ?? []
            XCTAssertEqual(entries.items.count, rows.count, id)
            for (entry, row) in zip(entries.items, rows) {
                let number = PluginViewFormat.entryNumber(entry, block: entries)
                XCTAssertEqual(number, string(row["number"]), id)
                let name = PluginViewFormat.entryName(entry, resolved: users)
                XCTAssertEqual(name, string(row["name"]), "\(id) entry \(entry.index) name")
                XCTAssertEqual(entry.text, string(row["text"]), id)
                XCTAssertEqual(entry.userId, string(row["userId"]), id)
                let header = entry.group.map { PluginViewFormat.groupHeader($0, s) }
                if row.objectValue?.keys.contains("group") == true {
                    XCTAssertEqual(header, string(row["group"]), "\(id) entry \(entry.index) group")
                }
                let me = PluginViewFormat.isMe(entry, viewerId: viewerId)
                if let want = row["me"]?.boolValue { XCTAssertEqual(me, want, "\(id) entry \(entry.index) me") }
                shown += [number.map { "\($0)." }, entry.text, name, header, me ? s.pluginViewMe : nil].compactMap { $0 }
            }
            let seeAll = entries.more ? PluginViewFormat.seeAll(entries.total, s) : nil
            XCTAssertEqual(seeAll, string(fact["seeAll"]), "\(id) see all")
            let empty = entries.items.isEmpty ? entries.emptyText : nil
            XCTAssertEqual(empty, string(fact["empty"]), "\(id) empty")
            shown += [seeAll, empty].compactMap { $0 }
        case .people(let people):
            let groups = fact["groups"]?.arrayValue ?? []
            XCTAssertEqual(people.groups.count, groups.count, id)
            for (group, g) in zip(people.groups, groups) {
                XCTAssertEqual(group.label, string(g["label"]), id)
                XCTAssertEqual(String(group.count), string(g["countText"]), id)
                XCTAssertEqual(group.userIds, (g["avatars"]?.arrayValue ?? []).compactMap(\.stringValue), id)
                XCTAssertEqual(group.userIds.map { PluginViewFormat.user($0, resolved: users).name },
                               (g["names"]?.arrayValue ?? []).compactMap(\.stringValue), "\(id) names")
                XCTAssertEqual((group.tone ?? .neutral).rawValue, string(g["tone"]), "\(id) tone")
                shown += [group.label, String(group.count)]
            }
        case .status(let status):
            XCTAssertEqual(status.label, string(fact["label"]), id)
            XCTAssertEqual(status.text, string(fact["text"]), id)
            XCTAssertEqual(status.tone.rawValue, string(fact["tone"]), id)
            shown += [status.label, status.text].compactMap { $0 }
        case .progress(let progress):
            XCTAssertEqual(progress.label, string(fact["label"]), id)
            XCTAssertEqual(PluginViewFormat.progressText(progress), string(fact["text"]), id)
            XCTAssertEqual(progress.percent, int(fact["percent"]), id)
            shown += [progress.label, PluginViewFormat.progressText(progress)].compactMap { $0 }
        case .time(let time):
            XCTAssertEqual(time.label, string(fact["label"]), id)
            let text = PluginViewFormat.timeText(atMs: time.atMs, endMs: time.endMs, nowMs: nowMs, s, utcOffsetMinutes: zone)
            XCTAssertEqual(text, string(fact["text"]), "\(id) time")
            let countdown = time.countdown ? PluginViewFormat.countdown(atMs: time.atMs, nowMs: nowMs, s) : nil
            XCTAssertEqual(countdown?.text, string(fact["countdown"]), "\(id) countdown")
            XCTAssertEqual(countdown?.refreshMs, int(fact["refreshMs"]), "\(id) refresh")
            shown += [time.label, text, countdown?.text].compactMap { $0 }
        case .divider:
            break
        case .note(let note):
            XCTAssertEqual(note.text, string(fact["text"]), id)
            XCTAssertEqual((note.tone ?? .neutral).rawValue, string(fact["tone"]), id)
            shown.append(note.text)
        }
        return shown
    }

    func testUnknownBlocksAndInputsAreSkippedAndV1RoundTrips() throws {
        let json = #"""
        {"available":true,"title":"Next","fields":[],"actions":[{"id":"a","label":"A","target":{"kind":"operation","operation":"a"},"input":{},"hiddenWhen":[]}],
         "blocks":[{"kind":"chart","series":[]},{"kind":"divider"},{"kind":"rows","source":"list","columns":[],"rows":[],"actions":[]}],
         "inputs":[{"id":"x","kind":"color","label":"X"},{"id":"y","kind":"text","label":"Y"}]}
        """#
        let view = try JSONDecoder().decode(PluginViewModel.self, from: Data(json.utf8))
        XCTAssertEqual(view.blocks, [.divider], "a kind the kit does not know (and rows) is skipped")
        XCTAssertEqual(view.inputs.map(\.id), ["y"])
        XCTAssertEqual(view.actions, [PluginViewAction(id: "a", label: "A")])
        let v1 = PluginViewModel(available: true, title: "Wallet", fields: [PluginViewField(label: "CNY", value: "9")])
        let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(v1)) as? [String: Any]
        XCTAssertEqual(Set(encoded?.keys.map { $0 } ?? []), ["available", "title", "fields", "actions"],
                       "a v1 card's JSON does not change")
    }

    // MARK: Behaviour on the card

    @MainActor
    func testChoicesSubmitOnTapAndAClosedPollIsReadOnly() throws {
        let table = try table()
        let views = try views(table)
        var calls: [(String, PluginActionPayload)] = []
        let record: (String, PluginActionPayload) -> Void = { calls.append(($0, $1)) }

        let open = try card(try XCTUnwrap(views["poll-open-single"]).0, table: table, onAction: record).inspect()
        try open.find(button: "桌游").tap()
        XCTAssertEqual(calls.map(\.0), ["vote"])
        XCTAssertEqual(calls.last?.1, PluginActionPayload(selection: [1]))

        calls = []
        let voted = try card(try XCTUnwrap(views["poll-voted-single"]).0, table: table, onAction: record).inspect()
        try voted.find(button: "桌游").tap()
        XCTAssertTrue(calls.isEmpty, "a tap on the only selected option is ignored")
        try voted.find(button: "爬山").tap()
        XCTAssertEqual(calls.last?.1, PluginActionPayload(selection: [0]))

        let closed = try card(try XCTUnwrap(views["poll-closed"]).0, table: table, onAction: record).inspect()
        XCTAssertTrue(try closed.find(button: "桌游").isDisabled())
        XCTAssertThrowsError(try closed.find(button: "桌游").tap())

        calls = []
        let multi = try card(try XCTUnwrap(views["poll-open-multi"]).0, table: table, onAction: record).inspect()
        try multi.find(button: "火锅").tap()
        XCTAssertTrue(calls.isEmpty, "a multiple choice toggles a draft")
        XCTAssertTrue(try multi.find(ButtonView.self, where: { try $0.find(text: "投票").string() == "投票" })
            .find(ViewType.Button.self).isDisabled(), "the submit key waits for a changed draft")

        let busy = try card(try XCTUnwrap(views["poll-open-single"]).0, table: table, busyActionId: "close",
                            onAction: record).inspect()
        XCTAssertTrue(try busy.find(button: "爬山").isDisabled(), "busyActionId disables every choice")
    }

    @MainActor
    func testFooterActionsConfirmOrCollectTheirFormBeforeTheyGoOut() throws {
        let table = try table()
        let views = try views(table)
        var calls: [(String, PluginActionPayload)] = []
        let record: (String, PluginActionPayload) -> Void = { calls.append(($0, $1)) }
        try card(try XCTUnwrap(views["poll-open-single"]).0, table: table, onAction: record).inspect()
            .find(button: "结束投票").tap()
        try card(try XCTUnwrap(views["solitaire-more"]).0, table: table, onAction: record).inspect()
            .find(button: "参与接龙").tap()
        XCTAssertTrue(calls.isEmpty, "confirm asks first, form collects first")
        try card(try XCTUnwrap(views["task"]).0, table: table, onAction: record).inspect().find(button: "完成").tap()
        XCTAssertEqual(calls.map(\.0), ["complete"])
        XCTAssertEqual(calls.first?.1, .empty)

        var opened = 0
        let solitaire = try card(try XCTUnwrap(views["solitaire-more"]).0, table: table, onAction: record,
                                 onOpenDetail: { opened += 1 }).inspect()
        try solitaire.find(button: PluginViewFormat.seeAll(12, s)).tap()
        XCTAssertEqual(opened, 1, "see all opens the detail")

        let spinning = try card(try XCTUnwrap(views["task"]).0, table: table, busyActionId: "complete").inspect()
        XCTAssertNoThrow(try spinning.find(ViewType.ProgressView.self), "the busy action's key spins")
    }

    // MARK: View details key

    @MainActor
    func testTheViewDetailsKeyFollowsTheTable() throws {
        let table = try table()
        let views = try views(table)
        let cases = (table["detailKey"]?.arrayValue ?? []).filter {
            ($0["platforms"]?.arrayValue ?? []).compactMap(\.stringValue).contains("ios")
        }
        XCTAssertGreaterThanOrEqual(cases.count, 8)
        for scenario in cases {
            let name = string(scenario["name"]) ?? "?"
            let base = try XCTUnwrap(views[string(scenario["view"]) ?? ""], name).0
            let view = scenario["detail"]?.boolValue.map {
                PluginViewModel(available: base.available, title: base.title, fields: base.fields,
                                actions: base.actions, blocks: base.blocks, inputs: base.inputs, detail: $0,
                                nextCursor: base.nextCursor)
            } ?? base
            let embedded = scenario["embedded"]?.boolValue ?? false
            var opened = 0
            let card = PluginView(
                view: view, icon: nil, busy: scenario["busy"]?.boolValue ?? false,
                busyActionId: string(scenario["busyActionId"]), error: nil, embedded: embedded, resolveUser: nil,
                members: [], formErrors: [], onAction: { _, _ in },
                onOpenDetail: scenario["handler"]?.boolValue == false ? nil : { opened += 1 },
                clock: PluginViewClock(nowMs: nowMs(table), utcOffsetMinutes: offset(table)), users: try users(table))
            let tree = try card.inspect()
            let expect = scenario["expect"]
            if let key = expect?["key"], let label = string(key["label"]) {
                XCTAssertEqual(label, s.pluginViewDetail, name)
                let button = try tree.find(button: label)
                XCTAssertEqual(try button.isDisabled(), !(key["enabled"]?.boolValue ?? true), "\(name) enabled")
                XCTAssertNoThrow(try tree.find(ButtonView.self, where: { try $0.find(text: label).string() == label }))
                if expect?["opens"]?.boolValue == true {
                    try button.tap()
                    XCTAssertEqual(opened, 1, "\(name) opens the detail")
                }
            } else {
                XCTAssertThrowsError(try tree.find(button: s.pluginViewDetail), "\(name) no key")
            }
            if let seeAll = expect?["seeAll"] {
                if let text = seeAll.stringValue {
                    XCTAssertNoThrow(try tree.find(button: text), "\(name) see all")
                } else {
                    XCTAssertThrowsError(try tree.find(ViewType.Text.self, where: {
                        try $0.string().hasPrefix(PluginViewFormat.seeAll(0, s).components(separatedBy: "（").first ?? "")
                    }), "\(name) no see all")
                }
            }
        }
        XCTAssertEqual(PluginViewFormat.showsDetailKey(try XCTUnwrap(views["solitaire-more"]).0, embedded: false), false,
                       "entries offer it themselves")
    }

    @MainActor
    func testTheShellCarriesTheIconAndEmbeddedDropsTheTitleRowAndTheErrorShows() throws {
        let view = PluginViewModel(available: true, title: "Card", blocks: [.note(PluginNoteBlock(text: "n"))])
        XCTAssertNoThrow(try PluginView(view: view, icon: "poll").inspect().find(text: "Card"))
        XCTAssertThrowsError(try PluginView(view: view, embedded: true).inspect().find(text: "Card"))
        XCTAssertNoThrow(try PluginView(view: view, embedded: true).inspect().find(text: "n"))
        XCTAssertNoThrow(try PluginView(view: view, error: "网络异常").inspect().find(text: "网络异常"))
    }

    func testUsersResolveThroughTheHostAndOthersFallBack() async throws {
        let table = try table()
        let known = try users(table)
        let found = await PluginView.resolved(["u_alice01", "u_dave9876", "u_alice01"], known: [:]) { known[$0] }
        XCTAssertEqual(found, ["u_alice01": known["u_alice01"]!])
        let none = await PluginView.resolved(["u_alice01"], known: known) { _ in XCTFail("known ids are not asked"); return nil }
        XCTAssertTrue(none.isEmpty)
        for row in table["fallbackNames"]?.arrayValue ?? [] {
            XCTAssertEqual(PluginViewFormat.fallbackName(string(row["userId"]) ?? ""), string(row["name"]))
        }
    }

    // MARK: Optimistic choices

    func testOptimisticStepsFollowTheTable() throws {
        let table = try table()
        let views = try views(table)
        for scenario in table["optimistic"]?.arrayValue ?? [] {
            let name = string(scenario["name"]) ?? "?"
            var view = try XCTUnwrap(views[string(scenario["view"]) ?? ""]).0
            var state = PluginChoicesInteraction()
            // The host's signals, applied as the view sees them: one value per change (error, busyActionId and
            // settleToken together).
            var signal = PluginHostSignal()
            var busyActionId: String? { signal.busyActionId }
            for (number, step) in (scenario["steps"]?.arrayValue ?? []).enumerated() {
                let label = "\(name) step \(number + 1)"
                func choices() throws -> (Int, PluginChoicesBlock) {
                    for (index, block) in view.blocks.enumerated() { if case .choices(let c) = block { return (index, c) } }
                    throw XCTSkip("no choices block")
                }
                var (index, block) = try choices()
                let locked = busyActionId != nil
                var emitted: (String, [Int])?
                if let option = int(step["tap"]) ?? int(step["toggle"]) {
                    if let selection = state.tap(block, at: index, option: option, locked: locked), let action = block.action {
                        state.submitted(block: index, actionId: action.id, selection: selection)
                        emitted = (action.id, selection)
                    }
                }
                if step["submit"]?.boolValue == true, let selection = state.submission(block, at: index, locked: locked),
                   let action = block.action {
                    state.submitted(block: index, actionId: action.id, selection: selection)
                    emitted = (action.id, selection)
                }
                if let host = step["host"]?.objectValue {
                    if let next = host["view"]?.stringValue {
                        view = try XCTUnwrap(views[next]).0
                        state.viewChanged()
                        (index, block) = try choices()
                    }
                    var next = signal
                    if let change = host["error"] { next.error = change.stringValue }
                    if let change = host["busyActionId"] { next.busyActionId = change.stringValue }
                    if let token = int(host["settleToken"]) { next.settleToken = token }
                    state.hostChanged(from: signal, to: next)
                    signal = next
                }
                if let emit = step["emit"] {
                    XCTAssertEqual(emitted?.0, string(emit["actionId"]), label)
                    XCTAssertEqual(emitted?.1, (emit["payload"]?["selection"]?.arrayValue ?? []).compactMap { int($0) }, label)
                } else {
                    XCTAssertNil(emitted?.0, "\(label) emits nothing")
                }
                if let selected = step["selected"]?.arrayValue {
                    XCTAssertEqual(state.shown(block, at: index), selected.compactMap { int($0) }, "\(label) selected")
                }
                if let interactive = step["interactive"]?.boolValue {
                    XCTAssertEqual(state.isInteractive(block, at: index, locked: busyActionId != nil), interactive,
                                   "\(label) interactive")
                }
                if let enabled = step["submitEnabled"]?.boolValue {
                    XCTAssertEqual(state.submitEnabled(block, at: index), enabled, "\(label) submit")
                }
            }
        }
    }

    // MARK: Time

    func testTimeTextFollowsTheTableInBothLanguages() throws {
        let table = try table()
        let now = nowMs(table)
        let cases = table["time"]?.arrayValue ?? []
        XCTAssertGreaterThanOrEqual(cases.count, 7)
        for row in cases {
            let at = Int64(row["atMs"]?.numberValue ?? 0)
            let end = row["endMs"]?.numberValue.map { Int64($0) }
            let zone = int(row["utcOffsetMinutes"])
            let name = string(row["name"]) ?? "?"
            XCTAssertEqual(PluginViewFormat.timeText(atMs: at, endMs: end, nowMs: now, s, utcOffsetMinutes: zone),
                           string(row["zh"]), name)
            XCTAssertEqual(PluginViewFormat.timeText(atMs: at, endMs: end, nowMs: now, en, utcOffsetMinutes: zone),
                           string(row["en"]), "\(name) en")
        }
    }

    func testCountdownFollowsTheTableAndTurnsOverOnItsBoundary() throws {
        let table = try table()
        for row in table["countdown"]?.arrayValue ?? [] {
            let at = Int64(row["atMs"]?.numberValue ?? 0)
            let now = Int64(row["nowMs"]?.numberValue ?? 0)
            let name = string(row["name"]) ?? "?"
            let zh = PluginViewFormat.countdown(atMs: at, nowMs: now, s)
            XCTAssertEqual(zh.text, string(row["zh"]), name)
            XCTAssertEqual(zh.refreshMs, int(row["refreshMs"]), "\(name) refresh")
            XCTAssertEqual(PluginViewFormat.countdown(atMs: at, nowMs: now, en).text, string(row["en"]), "\(name) en")
            // The next draw comes no later than the cadence, the text holds until then, and under a day it is
            // exactly where the text changes.
            if let delay = PluginViewFormat.countdownDelay(atMs: at, nowMs: now) {
                XCTAssertLessThanOrEqual(delay, Int64(zh.refreshMs ?? 0), name)
                XCTAssertEqual(PluginViewFormat.countdown(atMs: at, nowMs: now + delay - 1, s).text, zh.text, name)
                if at - now < 86_400_000 {
                    XCTAssertNotEqual(PluginViewFormat.countdown(atMs: at, nowMs: now + delay, s).text, zh.text, name)
                }
            } else {
                XCTAssertNil(zh.refreshMs, name)
            }
        }
        XCTAssertNil(PluginViewFormat.countdownDelay(atMs: 1, nowMs: 1))
        XCTAssertEqual(PluginViewFormat.countdownDelay(atMs: 3_600_000, nowMs: 0), 1, "an hour turns into 59:59 next")
    }

    // MARK: Forms

    private func formTable() throws -> (inputs: [PluginInput], form: PluginJSONValue) {
        let form = try XCTUnwrap(try table()["form"])
        return (try decode([PluginInput].self, form["inputs"]), form)
    }

    func testTheFormStartsFromTheTableDefaults() throws {
        let (inputs, form) = try formTable()
        let state = PluginFormState(inputs: inputs, values: nil)
        let options = try XCTUnwrap(inputs.first { $0.id == "options" })
        let initial = try XCTUnwrap(form["initial"])
        XCTAssertEqual(state.rows("options").count, int(initial["options"]?["rows"]))
        XCTAssertEqual(state.canAddRow(options), initial["options"]?["canAdd"]?.boolValue)
        XCTAssertEqual(state.canRemoveRow(options), initial["options"]?["canRemove"]?.boolValue)
        for id in ["owner", "assignees"] {
            let input = try XCTUnwrap(inputs.first { $0.id == id })
            XCTAssertEqual(PluginFormRules.maxItems(input) == 1, initial[id]?["single"]?.boolValue, id)
        }
        for (id, counter) in initial["counters"]?.objectValue ?? [:] {
            let input = try XCTUnwrap(inputs.first { $0.id == id })
            XCTAssertEqual(PluginFormRules.counter(input, state.draft[id]), counter.stringValue, id)
        }
        XCTAssertEqual(state.draft["anonymous"], .bool(false))
        XCTAssertEqual(state.draft["owner"], .array([]))
    }

    func testTheClientCheckAndTheSubmittedValuesFollowTheTable() throws {
        let (inputs, form) = try formTable()
        for row in form["cases"]?.arrayValue ?? [] {
            let name = string(row["name"]) ?? "?"
            let values = try decode([String: PluginJSONValue].self, row["values"])
            var state = PluginFormState(inputs: inputs, values: values)
            let expected = try decode([PluginFormError].self, row["clientErrors"])
            XCTAssertEqual(PluginFormRules.check(inputs, state.draft), expected, name)
            let submitted = state.submit(inputs)
            if let want = row["submitted"], want != .null {
                XCTAssertEqual(submitted.map(PluginJSONValue.object), want, "\(name) submitted")
            } else {
                XCTAssertNil(submitted, "\(name) does not submit")
            }
            XCTAssertTrue(state.attempted)
            for error in expected {
                let input = inputs.first { $0.id == error.input }
                XCTAssertEqual(state.errorText(try XCTUnwrap(input), hostErrors: [], s),
                               PluginFormRules.issueText(error.issue, input, s), "\(name): every issue shows after submit")
            }
        }
    }

    func testIssueTextsAndHostErrorsFollowTheTable() throws {
        let (inputs, form) = try formTable()
        var hostErrors: [PluginFormError] = []
        for row in form["hostErrors"]?.arrayValue ?? [] {
            let error = try decode(PluginFormError.self, row["error"])
            hostErrors.append(error)
            let input = inputs.first { $0.id == error.input }
            XCTAssertEqual(PluginFormRules.issueText(error.issue, input, s), string(row["zh"]), error.issue.rawValue)
            XCTAssertEqual(PluginFormRules.issueText(error.issue, input, en), string(row["en"]), "\(error.issue.rawValue) en")
        }
        var state = PluginFormState(inputs: inputs, values: nil)
        for (id, text) in form["shownPerInput"]?.objectValue ?? [:] {
            let input = try XCTUnwrap(inputs.first { $0.id == id })
            XCTAssertEqual(state.errorText(input, hostErrors: hostErrors, s), text.stringValue, "\(id): the first host error")
        }
        let limit = try XCTUnwrap(inputs.first { $0.id == "limit" })
        state.set("limit", .number(5))
        XCTAssertNil(state.errorText(limit, hostErrors: hostErrors, s), "an edited input drops its host error")
        state.hostErrorsChanged()
        XCTAssertEqual(state.errorText(limit, hostErrors: hostErrors, s), s.pluginFormOutOfRange, "new errors apply again")
        let title = try XCTUnwrap(inputs.first { $0.id == "title" })
        var fresh = PluginFormState(inputs: inputs, values: nil)
        XCTAssertNil(fresh.errorText(title, hostErrors: [], s), "nothing shows before an edit or a submit")
        fresh.set("title", .string(" "))
        XCTAssertEqual(fresh.errorText(title, hostErrors: [], s), s.pluginFormRequired, "an edited input shows its issue")
    }

    func testOptionRowsStayWithinTheirBounds() throws {
        let (inputs, _) = try formTable()
        let options = try XCTUnwrap(inputs.first { $0.id == "options" })
        var state = PluginFormState(inputs: inputs, values: nil)
        state.removeRow(options, 0)
        XCTAssertEqual(state.rows("options").count, 2, "never below max(min, 1)")
        for _ in 0..<10 { state.addRow(options) }
        XCTAssertEqual(state.rows("options").count, 5, "never above max")
        XCTAssertFalse(state.canAddRow(options))
        state.setRow(options, 4, "x")
        state.removeRow(options, 0)
        XCTAssertEqual(state.rows("options"), ["", "", "", "x"])
        let bare = PluginInput(id: "o", kind: .options, label: "O")
        XCTAssertEqual(PluginFormState(inputs: [bare], values: nil).rows("o").count, 1, "no default: one row")
        XCTAssertEqual(PluginFormRules.maxItems(bare), 50)
        XCTAssertEqual(PluginFormRules.maxItems(PluginInput(id: "m", kind: .members, label: "M")), 500)
    }

    @MainActor
    func testTheFormViewDrawsCountersRowsAndErrorsAndSubmitsCleanValues() throws {
        let (inputs, form) = try formTable()
        let empty = try PluginFormView(inputs: inputs).inspect()
        XCTAssertNoThrow(try empty.find(text: "0/10"))
        XCTAssertNoThrow(try empty.find(text: "0/20"))
        XCTAssertNoThrow(try empty.find(text: s.pollOptionHint(2)), "two option rows to start")
        let remove = try empty.findAll(IconButtonView.self).filter {
            (try? $0.find(ViewType.Button.self).accessibilityLabel().string()) == s.removeOption
        }
        XCTAssertEqual(remove.count, 2)
        XCTAssertTrue(try remove.allSatisfy { try $0.find(ViewType.Button.self).isDisabled() }, "at the fewest rows")
        XCTAssertNoThrow(try empty.find(button: s.addOption))
        XCTAssertNoThrow(try empty.find(text: "所有人"), "select lists its choices")
        XCTAssertNoThrow(try empty.find(button: s.selectDate), "datetime starts with a key")

        var submitted: [[String: PluginJSONValue]] = []
        try PluginFormView(inputs: inputs, onSubmit: { submitted.append($0) }).inspect()
            .find(button: s.pluginViewSubmit).tap()
        XCTAssertTrue(submitted.isEmpty, "required inputs stop the submit")

        let valid = try XCTUnwrap(form["cases"]?.arrayValue?.first { $0["name"]?.stringValue == "valid" })
        let values = try decode([String: PluginJSONValue].self, valid["values"])
        let members = [PluginMember(userId: "u_carol003", name: "Carol")]
        let filled = try PluginFormView(inputs: inputs, values: values, members: members,
                                        onSubmit: { submitted.append($0) }).inspect()
        XCTAssertNoThrow(try filled.find(text: "Carol"), "a chosen member reads by name")
        try filled.find(button: s.pluginViewSubmit).tap()
        XCTAssertEqual(submitted.map(PluginJSONValue.object), [try XCTUnwrap(valid["submitted"])])

        let errors = [PluginFormError(input: "limit", issue: .outOfRange), PluginFormError(input: "assignees", issue: .tooManyItems)]
        let failed = try PluginFormView(inputs: inputs, errors: errors, busy: true, error: "保存失败").inspect()
        XCTAssertNoThrow(try failed.find(text: s.pluginFormOutOfRange))
        XCTAssertNoThrow(try failed.find(text: "最多 3 项"))
        XCTAssertNoThrow(try failed.find(text: "保存失败"))
        XCTAssertTrue(try failed.find(button: s.cancel).isDisabled(), "busy holds the form")
    }

    // MARK: Detail sheet

    @MainActor
    func testTheDetailSheetLoadsFailsWithRetryAndShowsTheEmbeddedView() throws {
        XCTAssertEqual(PluginDetailSheetView.phase(loading: true, error: "x", view: nil), .loading)
        XCTAssertEqual(PluginDetailSheetView.phase(loading: false, error: "x", view: nil), .error)
        XCTAssertEqual(PluginDetailSheetView.phase(loading: false, error: nil, view: nil), .loading)
        let table = try table()
        let detail = try XCTUnwrap(try views(table)["solitaire-more"]).0
        XCTAssertEqual(PluginDetailSheetView.phase(loading: false, error: "", view: detail), .loaded)
        XCTAssertEqual(PluginDetailSheetView.heading(view: detail, title: "Card"), detail.title)
        XCTAssertEqual(PluginDetailSheetView.heading(view: nil, title: "Card"), "Card")

        let loading = try PluginDetailSheetView(title: "Card", loading: true).inspect()
        XCTAssertEqual(try loading.find(ViewType.ProgressView.self).accessibilityLabel().string(), s.loading)

        var retries = 0
        let failed = try PluginDetailSheetView(title: "Card", error: "加载失败", onRetry: { retries += 1 }).inspect()
        XCTAssertNoThrow(try failed.find(text: "加载失败"))
        try failed.find(button: s.retry).tap()
        XCTAssertEqual(retries, 1)

        var calls: [String] = []
        let loaded = try PluginDetailSheetView(view: detail, onAction: { id, _ in calls.append(id) }).inspect()
        XCTAssertNoThrow(try loaded.find(text: "《三体》"))
        XCTAssertThrowsError(try loaded.find(text: detail.title), "embedded: no title row (the sheet carries it)")
        XCTAssertNoThrow(try loaded.find(PluginView.self))
    }

    @MainActor
    func testDetailPagingFollowsTheTable() throws {
        let table = try table()
        let views = try views(table)
        let cases = table["detailPaging"]?.arrayValue ?? []
        XCTAssertGreaterThanOrEqual(cases.count, 4)
        for row in cases {
            let name = string(row["name"]) ?? "?"
            let base = try XCTUnwrap(views[string(row["view"]) ?? ""]).0
            let view = PluginViewModel(available: base.available, title: base.title, fields: base.fields,
                                       actions: base.actions, blocks: base.blocks, inputs: base.inputs,
                                       detail: base.detail, nextCursor: string(row["nextCursor"]))
            let loadingMore = row["loadingMore"]?.boolValue ?? false
            let expect = row["expect"] ?? .null
            let state = PluginDetailSheetView.loadMore(cursor: view.nextCursor, requested: nil, loadingMore: loadingMore)
            var asked: [String] = []
            let sheet = try PluginDetailSheetView(view: view, loadingMore: loadingMore,
                                                  onLoadMore: { asked.append($0) }).inspect()
            guard expect["loadMore"]?.boolValue == true else {
                XCTAssertEqual(state, .hidden, name)
                XCTAssertThrowsError(try sheet.find(button: s.myInviteLoadMore), "\(name): no key")
                continue
            }
            let key = try sheet.find(button: s.myInviteLoadMore)
            let enabled = expect["enabled"]?.boolValue ?? false
            XCTAssertEqual(!key.isDisabled(), enabled, "\(name) enabled")
            let spinning = (try? key.labelView().find(ViewType.ProgressView.self)) != nil
            XCTAssertEqual(spinning, expect["spinning"]?.boolValue ?? false, "\(name) spinning")
            XCTAssertEqual(state == .loading, spinning, name)
            if expect.objectValue?.keys.contains("emit") == true {
                if enabled { try key.tap() } else { XCTAssertThrowsError(try key.tap(), name) }
                XCTAssertEqual(asked, string(expect["emit"]).map { [$0] } ?? [], "\(name) emit")
            }
            // Steps: the cursor asked for spins until the merged view moves it on or the host frees it.
            var cursor = view.nextCursor
            var loading = loadingMore
            var paging = PluginDetailPaging()
            for (number, step) in (row["steps"]?.arrayValue ?? []).enumerated() {
                let label = "\(name) step \(number + 1)"
                if let host = step["host"]?.objectValue {
                    if let next = host["nextCursor"] { cursor = next.stringValue }
                    if let next = host["loadingMore"]?.boolValue {
                        if next != loading, !next { paging.release() }
                        loading = next
                    }
                    if let failure = host["actionError"]?.stringValue, !failure.isEmpty { paging.release() }
                    if host["settleToken"] != nil { paging.release() }
                }
                var emitted: String?
                if step["tap"]?.boolValue == true { emitted = paging.tap(cursor: cursor, loadingMore: loading) }
                if step.objectValue?.keys.contains("emit") == true {
                    XCTAssertEqual(emitted, string(step["emit"]), "\(label) emit")
                }
                let now = paging.key(cursor: cursor, loadingMore: loading)
                if let shown = step["loadMore"]?.boolValue { XCTAssertEqual(now != .hidden, shown, "\(label) key") }
                if let spins = step["spinning"]?.boolValue { XCTAssertEqual(now == .loading, spins, "\(label) spinning") }
                if let on = step["enabled"]?.boolValue {
                    if case .ready = now { XCTAssertTrue(on, "\(label) enabled") } else { XCTAssertFalse(on, "\(label) enabled") }
                }
            }
        }
    }

    // MARK: Map credit

    @MainActor
    func testOpenStreetMapIsCreditedOnTheStaticMapOnly() throws {
        XCTAssertEqual(FlareMapSnapshot.attribution(.osm, s), "© OpenStreetMap contributors")
        XCTAssertEqual(FlareMapSnapshot.attribution(.osm, en), s.locationOsmAttribution, "the same in every language")
        XCTAssertNil(FlareMapSnapshot.attribution(.amap, s))
        let picture = AsyncImagePhase.success(Image(systemName: "map"))

        let osm = try LocationMessageView(title: "西湖", snapshotUrl: "https://geo.example.com/s.png", provider: .osm)
            .inspect().find(ViewType.AsyncImage.self)
        XCTAssertNoThrow(try osm.contentView(picture).find(text: s.locationOsmAttribution), "osm over the picture")
        XCTAssertThrowsError(try osm.contentView(.empty).find(text: s.locationOsmAttribution), "not over the drawn ground")
        let amap = try LocationMessageView(title: "西湖", snapshotUrl: "https://geo.example.com/s.png", provider: .amap)
            .inspect().find(ViewType.AsyncImage.self)
        XCTAssertThrowsError(try amap.contentView(picture).find(text: s.locationOsmAttribution), "never for amap")
        XCTAssertThrowsError(try LocationMessageView(title: "西湖").inspect().find(text: s.locationOsmAttribution))

        let here = FlareLocationCoordinate(latitude: 30.2741, longitude: 120.1551)
        var model = FlareLocationPickerModel()
        model.located(here)
        model.previewStarted(here)
        model.previewLoaded("https://geo.example.com/a.png", for: here)
        for (provider, credited) in [(FlareLocationProvider.osm, true), (.amap, false)] {
            let map = try LocationPickerView(initialLocation: nil, zoom: 16, locateTimeoutMs: 5000,
                                             requestCurrentLocation: nil, reverseGeocode: nil, searchNearby: nil,
                                             previewUrl: nil, onSend: nil, onCancel: nil, model: model,
                                             provider: provider)
                .inspect().find(ViewType.AsyncImage.self)
            if credited {
                XCTAssertNoThrow(try map.contentView(picture).find(text: s.locationOsmAttribution))
            } else {
                XCTAssertThrowsError(try map.contentView(picture).find(text: s.locationOsmAttribution))
            }
        }
    }
}
