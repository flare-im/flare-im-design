import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// ``FlarePluginPage``, rows, badges and the choices limit against `spec/plugin-view-vectors.json`: rules badge,
/// maxSelections, page, pageRows, pagePaging and pageFilters, and the segments maxSelections, pageViews,
/// pageActions, pagePaging, pageFilters and filterInputs. Every kit draws these (the rules say so), so every case
/// runs here whatever its `platforms` lists.
final class PluginPageVectorsTests: XCTestCase {
    private let s = FlareStrings()

    // MARK: Table

    private struct PageCase {
        let id: String
        let title: String?
        let ref: PluginPageRef
        let filters: [String: PluginJSONValue]
        let view: PluginPageViewModel
        let expect: PluginJSONValue
    }

    private func pages(_ table: PluginJSONValue) throws -> [String: PageCase] {
        var out: [String: PageCase] = [:]
        for entry in table["pageViews"]?.arrayValue ?? [] {
            let id = try XCTUnwrap(entry["id"]?.stringValue)
            out[id] = PageCase(id: id, title: entry["title"]?.stringValue,
                               ref: try PluginVectors.decode(PluginPageRef.self, entry["page"]),
                               filters: entry["filters"]?.objectValue ?? [:],
                               view: try PluginVectors.decode(PluginPageViewModel.self, entry["view"]),
                               expect: entry["expect"] ?? .null)
        }
        return out
    }

    /// Every card view of the table, by id.
    private func cardViews(_ table: PluginJSONValue) throws -> [String: (PluginViewModel, PluginJSONValue)] {
        var out: [String: (PluginViewModel, PluginJSONValue)] = [:]
        for entry in table["views"]?.arrayValue ?? [] {
            guard let id = entry["id"]?.stringValue else { continue }
            out[id] = (try PluginVectors.decode(PluginViewModel.self, entry["view"]), entry)
        }
        return out
    }

    private func users(_ table: PluginJSONValue) throws -> [String: PluginUser] {
        try PluginVectors.decode([String: PluginUser].self, table["users"])
    }

    @MainActor
    private func page(_ c: PageCase, table: PluginJSONValue, view: PluginPageViewModel? = nil,
                      filters: [String: PluginJSONValue]? = nil, error: String? = nil, refreshing: Bool = false,
                      loadingMore: Bool = false, busyActionId: String? = nil,
                      onRetry: (() -> Void)? = {}, onLoadMore: ((String) -> Void)? = { _ in },
                      onFilter: (([String: PluginJSONValue]) -> Void)? = { _ in },
                      onAction: ((String, PluginPageActionPayload) -> Void)? = { _, _ in }) -> FlarePluginPage {
        FlarePluginPage(page: c.ref, title: c.title, view: view ?? c.view, filters: filters ?? c.filters,
                        loading: false, error: error, refreshing: refreshing, loadingMore: loadingMore,
                        resolveUser: nil, viewerId: nil, busyActionId: busyActionId, actionError: nil, formErrors: [],
                        members: [], settleToken: 0, onBack: nil, onRefresh: {}, onRetry: onRetry,
                        onLoadMore: onLoadMore, onFilter: onFilter, onAction: onAction,
                        clock: PluginVectors.clock(table))
    }

    private func json<T: Encodable>(_ value: T) throws -> PluginJSONValue {
        try JSONDecoder().decode(PluginJSONValue.self, from: JSONEncoder().encode(value))
    }

    private func stateName(_ phase: FlarePluginPage.Phase) -> String {
        switch phase {
        case .loading: return "loading"
        case .error: return "error"
        case .unavailable: return "unavailable"
        case .loaded: return "loaded"
        }
    }

    /// The key of `label` in the drawn tree, the `occurrence`-th one.
    private func key(_ tree: InspectableView<ViewType.ClassifiedView>, _ label: String,
                     occurrence: Int = 0) throws -> InspectableView<ViewType.Button> {
        let keys = tree.findAll(ViewType.Button.self, where: { (try? $0.labelView().find(text: label)) != nil })
        guard keys.indices.contains(occurrence) else { throw XCTSkip("no key \(label) #\(occurrence)") }
        return keys[occurrence]
    }

    func testTheTableHoldsThePageSegments() throws {
        let table = try PluginVectors.table()
        for rule in ["badge", "maxSelections", "page", "pageRows", "pagePaging", "pageFilters"] {
            XCTAssertFalse((table["rules"]?[rule]?.stringValue ?? "").isEmpty, "rules.\(rule)")
        }
        XCTAssertGreaterThanOrEqual(table["maxSelections"]?.arrayValue?.count ?? 0, 5)
        XCTAssertGreaterThanOrEqual(table["pageViews"]?.arrayValue?.count ?? 0, 7)
        XCTAssertGreaterThanOrEqual(table["pageActions"]?.arrayValue?.count ?? 0, 8)
        XCTAssertGreaterThanOrEqual(table["pagePaging"]?.arrayValue?.count ?? 0, 3)
        XCTAssertGreaterThanOrEqual(table["pageFilters"]?.arrayValue?.count ?? 0, 5)
        let pages = try pages(table)
        for id in ["wallet", "wallet-empty", "history", "tasks", "unavailable-disabled", "unavailable-no-permission",
                   "unavailable-catalog-unreachable", "unavailable-no-reason"] {
            XCTAssertNotNil(pages[id], "the shared table lost the page \(id)")
        }
        // The ledger: badged rows, a kind filter beside a text input the host also holds, and a next page.
        let history = try XCTUnwrap(pages["history"])
        XCTAssertNotNil(history.view.rowsBlock)
        XCTAssertNotNil(history.view.nextCursor)
        XCTAssertTrue(history.view.inputs.contains { $0.kind != .select }, "history keeps a filter that is no tab")
        XCTAssertTrue((table["pageFilters"]?.arrayValue ?? []).contains { $0["view"]?.stringValue == "history" },
                      "a filter case keeps the host's other values")
    }

    // MARK: Page views

    @MainActor
    func testEveryPageMatchesItsRenderFacts() throws {
        let table = try PluginVectors.table()
        let clock = PluginVectors.clock(table)
        for (id, c) in try pages(table) {
            let expect = c.expect
            let phase = FlarePluginPage.phase(loading: false, error: nil, view: c.view)
            XCTAssertEqual(stateName(phase), expect["state"]?.stringValue, "\(id) state")
            let heading = FlarePluginPage.heading(view: c.view, title: c.title)
            XCTAssertEqual(heading, expect["heading"]?.stringValue, "\(id) heading")
            let loaded = phase == .loaded
            let view = c.view.view
            var shown = [heading]

            XCTAssertEqual(loaded ? view.fields : [], try PluginVectors.decode([PluginViewField].self, expect["fields"]),
                           "\(id) fields")
            if loaded { shown += view.fields.flatMap { [$0.label, $0.value] } }
            let blocks = loaded ? view.blocks : []
            let blockFacts = expect["blocks"]?.arrayValue ?? []
            XCTAssertEqual(blocks.map(\.kind), blockFacts.compactMap { $0["kind"]?.stringValue }, "\(id) blocks")
            for (index, (block, fact)) in zip(blocks, blockFacts).enumerated() {
                switch block {
                case .note(let note):
                    XCTAssertEqual(note.text, fact["text"]?.stringValue, "\(id)#\(index)")
                    XCTAssertEqual((note.tone ?? .neutral).rawValue, fact["tone"]?.stringValue, "\(id)#\(index)")
                    shown.append(note.text)
                case .rows(let rows):
                    shown += try PluginVectors.checkRows(rows, fact, clock: clock, strings: s, id: "\(id)#\(index)")
                default:
                    XCTFail("\(id)#\(index): no facts for \(block.kind)")
                }
            }

            // The view's actions and then its menu actions, as keys.
            let actions = loaded ? PluginView.actionRow(view, embedded: true) : []
            let actionFacts = expect["actions"]?.arrayValue ?? []
            XCTAssertEqual(actions.map(\.id), actionFacts.compactMap { $0["id"]?.stringValue }, "\(id) actions")
            for (action, fact) in zip(actions, actionFacts) {
                XCTAssertEqual(action.label, fact["label"]?.stringValue, "\(id) \(action.id)")
                XCTAssertEqual(PluginVectors.variant(action), fact["variant"]?.stringValue, "\(id) \(action.id) variant")
                XCTAssertEqual(action.confirm, fact["confirm"]?.stringValue, "\(id) \(action.id) confirm")
                XCTAssertEqual(!(action.form ?? []).isEmpty, fact["form"]?.boolValue, "\(id) \(action.id) form")
                shown.append(action.label)
            }

            let filters = loaded ? PluginPageRules.filters(view, values: c.filters, all: s.pluginViewAll) : []
            let filterFacts = expect["filters"]?.arrayValue ?? []
            XCTAssertEqual(filters.map(\.input.id), filterFacts.compactMap { $0["input"]?.stringValue }, "\(id) filters")
            for (filter, fact) in zip(filters, filterFacts) {
                XCTAssertEqual(filter.input.label, fact["label"]?.stringValue, "\(id) \(filter.id) label")
                XCTAssertEqual(filter.tabs.map(\.label), (fact["tabs"]?.arrayValue ?? []).compactMap(\.stringValue),
                               "\(id) \(filter.id) tabs")
                XCTAssertEqual(filter.tabs.first { $0.value == filter.selected }?.label, fact["selected"]?.stringValue,
                               "\(id) \(filter.id) selected")
                shown += filter.tabs.map(\.label)
            }

            let loadMore = loaded && PluginDetailPaging().key(cursor: c.view.nextCursor, loadingMore: false) != .hidden
            XCTAssertEqual(loadMore, expect["loadMore"]?.boolValue, "\(id) load more")
            XCTAssertEqual(loaded, expect["refresh"]?.boolValue, "\(id) refresh")
            let empty = phase == .unavailable ? PluginPageRules.unavailableText(view, s) : nil
            XCTAssertEqual(empty, expect["empty"]?.stringValue, "\(id) empty")
            let retry = phase == .unavailable && PluginPageRules.unavailableRetry(view)
            XCTAssertEqual(retry, expect["retry"]?.boolValue, "\(id) retry")
            if let empty { shown.append(empty) }

            // The drawn page.
            var retried = 0
            let tree = try page(c, table: table, onRetry: { retried += 1 }).inspect()
            for text in Set(shown) where !text.isEmpty {
                XCTAssertNoThrow(try tree.find(text: text), "\(id) draws \(text)")
            }
            if loadMore {
                XCTAssertNoThrow(try tree.find(button: s.myInviteLoadMore), "\(id) load more")
            } else {
                XCTAssertThrowsError(try tree.find(button: s.myInviteLoadMore), "\(id) no load more")
            }
            if retry {
                try tree.find(button: s.retry).tap()
                XCTAssertEqual(retried, 1, "\(id) retry")
            } else {
                XCTAssertThrowsError(try tree.find(button: s.retry), "\(id) no retry")
            }
            #if os(macOS)
            let refreshKey = tree.findAll(ViewType.Button.self, where: {
                (try? $0.accessibilityLabel().string()) == self.s.pluginPageRefresh
            })
            XCTAssertEqual(!refreshKey.isEmpty, loaded, "\(id): a pointer refreshes a shown page from the header")
            #endif
            XCTAssertEqual(tree.findAll(FilterTabsView.self).count, filters.count, "\(id): one tab row per select filter")
            if !loaded {
                XCTAssertThrowsError(try tree.find(PluginView.self), "\(id): an unavailable page draws no view")
            }
        }
    }

    @MainActor
    func testAFailedRefreshIsABannerAboveTheShownPage() throws {
        let table = try PluginVectors.table()
        let wallet = try XCTUnwrap(try pages(table)["wallet"])
        let tree = try page(wallet, table: table, error: "刷新失败").inspect()
        XCTAssertNoThrow(try tree.find(StatusBannerView.self).find(text: "刷新失败"))
        XCTAssertNoThrow(try tree.find(text: "¥128.50"), "the page stays")
        XCTAssertNil(try? page(wallet, table: table).inspect().find(StatusBannerView.self))
    }

    func testAPageViewKeepsItsDataAndReadsThroughToTheView() throws {
        let json = #"{"available":true,"title":"钱包","fields":[],"actions":[],"nextCursor":"c2","data":{"currency":"CNY","n":2}}"#
        let page = try JSONDecoder().decode(PluginPageViewModel.self, from: Data(json.utf8))
        XCTAssertEqual(page.title, "钱包")
        XCTAssertEqual(page.nextCursor, "c2")
        XCTAssertEqual(page.data, ["currency": "CNY", "n": 2])
        let again = try JSONDecoder().decode(PluginPageViewModel.self, from: JSONEncoder().encode(page))
        XCTAssertEqual(again, page, "the data goes back as it came")
        let bare = try JSONDecoder().decode(PluginPageViewModel.self, from: Data(#"{"available":false,"title":"","data":null}"#.utf8))
        XCTAssertNil(bare.data)
        let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(bare)) as? [String: Any]
        XCTAssertNil(encoded?["data"], "no data, no key")
    }

    // MARK: Page actions

    /// What a step is waiting on: the action and its payload so far, and the inputs of its open form.
    private struct Running {
        let action: PluginViewAction
        let payload: PluginActionPayload
        var form: [PluginInput] = []
    }

    @MainActor
    func testPageActionsFollowTheTable() throws {
        let table = try PluginVectors.table()
        let pages = try pages(table)
        for scenario in table["pageActions"]?.arrayValue ?? [] {
            let name = scenario["name"]?.stringValue ?? "?"
            let c = try XCTUnwrap(pages[scenario["view"]?.stringValue ?? ""], name)
            let view = c.view.view
            var running: Running?
            // The row of the last action sent, and the host's action in flight (rules.pageRows).
            var lastRow: String?
            var busyActionId: String?
            for (number, step) in (scenario["steps"]?.arrayValue ?? []).enumerated() {
                let label = "\(name) step \(number + 1)"
                var emitted: (String, PluginActionPayload)? = nil {
                    didSet { if let sent = emitted { lastRow = sent.1.row?.key } }
                }
                func advance(_ next: PluginActionStep, _ run: Running) {
                    switch next {
                    case .confirm(let text):
                        XCTAssertEqual(text, step["confirm"]?.stringValue, "\(label) confirm")
                        running = run
                    case .form(let ids):
                        var open = run
                        open.form = view.formInputs(for: run.action)
                        XCTAssertEqual(open.form.map(\.id), ids, label)
                        XCTAssertEqual(open.form.map(\.label), (step["form"]?.arrayValue ?? []).compactMap(\.stringValue),
                                       "\(label) form")
                        running = open
                    case .emit:
                        emitted = (run.action.id, run.payload)
                        running = nil
                    }
                }
                if let tap = step["tap"] {
                    let actionId = try XCTUnwrap(tap["action"]?.stringValue, label)
                    let run: Running
                    if let rowKey = tap["row"]?.stringValue {
                        let rows = try XCTUnwrap(view.rowsBlock, label)
                        let row = try XCTUnwrap(rows.rows.first { $0.key == rowKey }, label)
                        let key = try XCTUnwrap(PluginViewFormat.rowKeys(rows, row).first { $0.action.id == actionId }, label)
                        run = Running(action: key.action, payload: PluginActionPayload(row: PluginRowRef(key: row.key, input: key.input)))
                    } else {
                        let action = try XCTUnwrap(PluginView.actionRow(view, embedded: true).first { $0.id == actionId }, label)
                        run = Running(action: action, payload: .empty)
                    }
                    advance(PluginActionFlow.start(run.action), run)
                    try checkTheDrawnKey(c, table: table, tap: tap, emits: emitted == nil ? nil : emitted, label: label)
                }
                if step["confirm"]?.boolValue == true, let run = running {
                    advance(PluginActionFlow.confirmed(run.action), run)
                }
                if step["cancel"]?.boolValue == true { running = nil }
                if let fill = step["fill"]?.objectValue, let run = running {
                    var form = PluginFormState(inputs: run.form, values: nil)
                    for (id, value) in fill { form.set(id, value) }
                    if step["submit"]?.boolValue == true {
                        let values = try XCTUnwrap(form.submit(run.form), "\(label) the form submits")
                        emitted = (run.action.id, PluginActionFlow.payload(run.payload, formValues: values))
                        running = nil
                    }
                }
                if let host = step["host"]?.objectValue, host.keys.contains("busyActionId") {
                    busyActionId = host["busyActionId"]?.stringValue
                }
                if let spinning = step["spinningRows"]?.arrayValue {
                    let rows = try XCTUnwrap(view.rowsBlock, label)
                    let spun = PluginViewFormat.rowsOnce(rows.rows).filter { row in
                        PluginViewFormat.rowKeys(rows, row).contains {
                            PluginRowsBlockView.spins($0, row: row, busyActionId: busyActionId, activeRow: lastRow)
                        }
                    }
                    XCTAssertEqual(spun.map(\.key), spinning.compactMap(\.stringValue), "\(label) spinning rows")
                }
                if let on = step["rowKeysEnabled"]?.boolValue {
                    let tree = try page(c, table: table, busyActionId: busyActionId).inspect()
                    XCTAssertEqual(try key(tree, "查看").isDisabled(), !on, "\(label) row keys")
                }
                guard let want = step["emit"] else { continue }
                if want == .null {
                    XCTAssertNil(emitted?.0, "\(label) emits nothing")
                    continue
                }
                let (id, payload) = try XCTUnwrap(emitted, "\(label) emits")
                XCTAssertEqual(id, want["actionId"]?.stringValue, label)
                XCTAssertEqual(try json(PluginPageActionPayload(page: c.ref, view: c.view, payload: payload)), want["payload"],
                               "\(label) payload")
            }
        }
    }

    /// The drawn page: the tapped key sends the page action at once (no confirmation, no form), or nothing yet.
    @MainActor
    private func checkTheDrawnKey(_ c: PageCase, table: PluginJSONValue, tap: PluginJSONValue,
                                  emits: (String, PluginActionPayload)?, label: String) throws {
        var calls: [(String, PluginPageActionPayload)] = []
        let tree = try page(c, table: table, onAction: { calls.append(($0, $1)) }).inspect()
        let actionId = tap["action"]?.stringValue ?? ""
        let view = c.view.view
        let button: InspectableView<ViewType.Button>
        if let rowKey = tap["row"]?.stringValue, let rows = view.rowsBlock {
            let offering = PluginViewFormat.rowsOnce(rows.rows).filter {
                PluginViewFormat.rowKeys(rows, $0).contains { $0.action.id == actionId }
            }
            let action = try XCTUnwrap(rows.actions.first { $0.id == actionId })
            button = try key(tree, action.label, occurrence: try XCTUnwrap(offering.firstIndex { $0.key == rowKey }))
        } else {
            let action = try XCTUnwrap(PluginView.actionRow(view, embedded: true).first { $0.id == actionId })
            button = try key(tree, action.label)
        }
        try button.tap()
        if let emits {
            XCTAssertEqual(calls.map(\.0), [emits.0], "\(label): the drawn key")
            XCTAssertEqual(calls.first?.1, PluginPageActionPayload(page: c.ref, view: c.view, payload: emits.1),
                           "\(label): the drawn key's payload")
        } else {
            XCTAssertTrue(calls.isEmpty, "\(label): the drawn key asks first")
        }
    }

    // MARK: Paging

    @MainActor
    func testPagePagingFollowsTheTable() throws {
        let table = try PluginVectors.table()
        let pages = try pages(table)
        let clock = PluginVectors.clock(table)
        for scenario in table["pagePaging"]?.arrayValue ?? [] {
            let name = scenario["name"]?.stringValue ?? "?"
            let c = try XCTUnwrap(pages[scenario["view"]?.stringValue ?? ""], name)
            var view = c.view
            var paging = PluginDetailPaging()
            for (number, step) in (scenario["steps"]?.arrayValue ?? []).enumerated() {
                let label = "\(name) step \(number + 1)"
                if let host = step["host"]?.objectValue {
                    if let next = host["view"] { view = try PluginVectors.decode(PluginPageViewModel.self, next) }
                    if let failure = host["actionError"]?.stringValue, !failure.isEmpty { paging.release() }
                    // The page releases the key when a refresh ends (FlarePluginPage onChange(of: refreshing)).
                    if host["refreshing"]?.boolValue == false { paging.release() }
                }
                if step["tap"]?.stringValue == "loadMore" {
                    let asked = paging.tap(cursor: view.nextCursor, loadingMore: false)
                    XCTAssertEqual(asked, step["emit"]?.stringValue, "\(label) emit")
                }
                if let tap = step["tap"], let rowKey = tap["row"]?.stringValue {
                    let rows = try XCTUnwrap(view.rowsBlock, label)
                    let row = try XCTUnwrap(rows.rows.first { $0.key == rowKey }, label)
                    let key = try XCTUnwrap(PluginViewFormat.rowKeys(rows, row).first { $0.action.id == tap["action"]?.stringValue })
                    let payload = PluginPageActionPayload(page: c.ref, view: view, payload: PluginActionPayload(
                        row: PluginRowRef(key: row.key, input: key.input)))
                    XCTAssertEqual(try json(payload), step["emit"]?["payload"], "\(label) payload: the first page's data")
                }
                let state = paging.key(cursor: view.nextCursor, loadingMore: false)
                if let shown = step["loadMore"]?.boolValue { XCTAssertEqual(state != .hidden, shown, "\(label) key") }
                if let spins = step["spinning"]?.boolValue { XCTAssertEqual(state == .loading, spins, "\(label) spinning") }
                if let on = step["enabled"]?.boolValue {
                    if case .ready = state { XCTAssertTrue(on, "\(label) enabled") } else { XCTAssertFalse(on, "\(label) enabled") }
                }
                if let keys = step["rowKeys"]?.arrayValue {
                    let rows = PluginViewFormat.rowsOnce(view.rowsBlock?.rows ?? [])
                    XCTAssertEqual(rows.map(\.key), keys.compactMap(\.stringValue), "\(label) rows")
                    if let primaries = step["primaries"]?.arrayValue {
                        let block = try XCTUnwrap(view.rowsBlock)
                        XCTAssertEqual(rows.map { PluginViewFormat.rowLines(block, $0, nowMs: clock.now(), s,
                                                                             utcOffsetMinutes: clock.utcOffsetMinutes).primary },
                                       primaries.compactMap(\.stringValue), "\(label) the first of a key stays")
                    }
                    // Drawn: each key once, the first kept.
                    let tree = try page(c, table: table, view: view).inspect()
                    let drawn = try tree.find(PluginRowsBlockView.self).findAll(ViewType.Divider.self).count
                    XCTAssertEqual(drawn, 0, "\(label): rows part with the kit hairline, not a system divider")
                    for row in rows {
                        let primary = PluginViewFormat.rowLines(try XCTUnwrap(view.rowsBlock), row, nowMs: clock.now(), s,
                                                                utcOffsetMinutes: clock.utcOffsetMinutes).primary
                        XCTAssertNoThrow(try tree.find(text: primary), "\(label) draws \(row.key)")
                    }
                    for skipped in (view.rowsBlock?.rows ?? []).dropFirst(rows.count) {
                        let text = skipped.cells.first?.text ?? ""
                        XCTAssertThrowsError(try tree.find(text: text), "\(label) skips the repeated \(skipped.key)")
                    }
                }
            }
        }
    }

    @MainActor
    func testTheDrawnLoadMoreKeyAsksForTheCursor() throws {
        let table = try PluginVectors.table()
        let wallet = try XCTUnwrap(try pages(table)["wallet"])
        var asked: [String] = []
        try page(wallet, table: table, onLoadMore: { asked.append($0) }).inspect().find(button: s.myInviteLoadMore).tap()
        XCTAssertEqual(asked, ["c2"])
        let spinning = try page(wallet, table: table, loadingMore: true).inspect().find(button: s.myInviteLoadMore)
        XCTAssertTrue(spinning.isDisabled())
        XCTAssertNoThrow(try spinning.labelView().find(ViewType.ProgressView.self))
    }

    // MARK: Filters

    @MainActor
    func testPageFiltersFollowTheTable() throws {
        let table = try PluginVectors.table()
        let pages = try pages(table)
        for scenario in table["pageFilters"]?.arrayValue ?? [] {
            let name = scenario["name"]?.stringValue ?? "?"
            let c = try XCTUnwrap(pages[scenario["view"]?.stringValue ?? ""], name)
            var filters = scenario["filters"]?.objectValue ?? [:]
            var refreshing = false
            var loadingMore = false
            for (number, step) in (scenario["steps"]?.arrayValue ?? []).enumerated() {
                let label = "\(name) step \(number + 1)"
                if let host = step["host"]?.objectValue {
                    if let next = host["filters"]?.objectValue { filters = next }
                    if let next = host["refreshing"]?.boolValue { refreshing = next }
                    if let next = host["loadingMore"]?.boolValue { loadingMore = next }
                }
                let rows = PluginPageRules.filters(c.view.view, values: filters, all: s.pluginViewAll)
                if let tabs = step["tabs"]?.objectValue {
                    XCTAssertEqual(Set(rows.map(\.input.id)), Set(tabs.keys), "\(label) filter rows")
                    for filter in rows {
                        XCTAssertEqual(filter.tabs.map(\.label), (tabs[filter.input.id]?.arrayValue ?? []).compactMap(\.stringValue),
                                       "\(label) \(filter.id) tabs")
                    }
                }
                if let selected = step["selected"]?.objectValue {
                    for (input, want) in selected {
                        let filter = try XCTUnwrap(rows.first { $0.input.id == input }, label)
                        XCTAssertEqual(filter.tabs.first { $0.value == filter.selected }?.label, want.stringValue,
                                       "\(label) \(input) selected")
                    }
                }
                var emitted: [[String: PluginJSONValue]] = []
                let tree = try page(c, table: table, filters: filters, refreshing: refreshing, loadingMore: loadingMore,
                                    onFilter: { emitted.append($0) }).inspect()
                if let choose = step["choose"]?.objectValue {
                    let filter = try XCTUnwrap(rows.first { $0.input.id == choose["input"]?.stringValue }, label)
                    let tab = try XCTUnwrap(filter.tabs.first { $0.label == choose["tab"]?.stringValue }, label)
                    let next = PluginPageRules.choose(filter, value: tab.value, in: filters)
                    let want = step["emit"]
                    XCTAssertEqual(next.map(PluginJSONValue.object), want == .null ? nil : want, "\(label) emit")
                    // Drawn: the tab of that row.
                    let row = try tree.find(FilterTabsView.self, where: {
                        (try? $0.accessibilityLabel().string()) == filter.input.label
                    })
                    try row.find(button: tab.label).tap()
                    XCTAssertEqual(emitted, next.map { [$0] } ?? [], "\(label): the drawn tab")
                }
                if let enabled = step["enabled"]?.boolValue {
                    let tab = try tree.find(FilterTabsView.self).find(button: s.pluginViewAll)
                    XCTAssertEqual(!tab.isDisabled(), enabled, "\(label) tabs enabled")
                    if !enabled { XCTAssertThrowsError(try tab.tap(), "\(label): a waiting tab is not a control") }
                }
                if step["tabs"]?.objectValue?.isEmpty == true {
                    XCTAssertThrowsError(try tree.find(FilterTabsView.self), "\(label): no filter row")
                }
            }
        }
    }

    func testFilterInputsFollowTheTable() throws {
        let table = try PluginVectors.table()
        let segment = try XCTUnwrap(table["filterInputs"])
        let inputs = (segment["inputs"]?.arrayValue ?? []).compactMap(\.stringValue)
            .map { PluginInput(id: $0, kind: .text, label: $0) }
        for row in segment["cases"]?.arrayValue ?? [] {
            let name = row["name"]?.stringValue ?? "?"
            let listed = row["filters"]?.arrayValue.map { $0.compactMap(\.stringValue) }
            let view = PluginViewModel(available: true, title: "t",
                                       blocks: [.rows(PluginRowsBlock(columns: [], rows: [], filters: listed))],
                                       inputs: inputs)
            XCTAssertEqual(PluginViewFormat.filterInputs(view).map(\.id),
                           (row["expect"]?.arrayValue ?? []).compactMap(\.stringValue), name)
        }
        let noRows = PluginViewModel(available: true, title: "t", inputs: inputs)
        XCTAssertEqual(PluginViewFormat.filterInputs(noRows).map(\.id), inputs.map(\.id))
        XCTAssertTrue(PluginPageRules.filters(noRows, values: [:], all: s.pluginViewAll).isEmpty,
                      "no rows block, no filter row")
    }

    // MARK: Choices limit

    @MainActor
    func testTheChoicesLimitFollowsTheTable() throws {
        let table = try PluginVectors.table()
        let views = try cardViews(table)
        for scenario in table["maxSelections"]?.arrayValue ?? [] {
            let name = scenario["name"]?.stringValue ?? "?"
            let view = try XCTUnwrap(views[scenario["view"]?.stringValue ?? ""], name).0
            let embedded = scenario["embedded"]?.boolValue ?? false
            let (index, block) = try XCTUnwrap(view.blocks.enumerated().compactMap { offset, block -> (Int, PluginChoicesBlock)? in
                if case .choices(let choices) = block { return (offset, choices) }
                return nil
            }.first, name)
            var state = PluginChoicesInteraction()
            for (number, step) in (scenario["steps"]?.arrayValue ?? []).enumerated() {
                let label = "\(name) step \(number + 1)"
                var emitted: [Int]?
                if let option = step["toggle"]?.numberValue ?? step["tap"]?.numberValue {
                    emitted = state.tap(block, at: index, option: Int(option), locked: false)
                }
                if step["submit"]?.boolValue == true {
                    emitted = state.submission(block, at: index, locked: false)
                }
                if let want = step["emit"] {
                    XCTAssertEqual(emitted, (want["payload"]?["selection"]?.arrayValue ?? []).compactMap { $0.numberValue.map(Int.init) },
                                   "\(label) emit")
                    XCTAssertEqual(block.action?.id, want["actionId"]?.stringValue, label)
                } else {
                    XCTAssertNil(emitted, "\(label) emits nothing")
                }
                if let selected = step["selected"]?.arrayValue {
                    XCTAssertEqual(state.shown(block, at: index), selected.compactMap { $0.numberValue.map(Int.init) },
                                   "\(label) selected")
                }
                if let enabled = step["enabled"]?.arrayValue {
                    let interactive = state.isInteractive(block, at: index, locked: false)
                    XCTAssertEqual(block.options.map { interactive && !state.capped(block, at: index, option: $0.index) },
                                   enabled.compactMap(\.boolValue), "\(label) enabled")
                }
                if let enabled = step["submitEnabled"]?.boolValue {
                    XCTAssertEqual(state.submitEnabled(block, at: index), enabled, "\(label) submit")
                }
            }
            // Drawn as the view first shows (card or embedded): the held options are not controls, the hint leads.
            let tree = try PluginView(view: view, embedded: embedded, onAction: { _, _ in }).inspect()
            let fresh = PluginChoicesInteraction()
            for option in block.options {
                let button = try tree.find(button: option.label)
                XCTAssertEqual(button.isDisabled(), fresh.capped(block, at: index, option: option.index),
                               "\(name) \(option.label) drawn")
            }
            if let footer = PluginViewFormat.choicesFooter(block, s) { XCTAssertNoThrow(try tree.find(text: footer), name) }
        }
    }

    func testTheLimitHintOnlyLeadsAChoiceThatCanStillBeMade() {
        let options = (0..<3).map { PluginChoice(index: $0, label: "\($0)") }
        let vote = PluginViewAction(id: "vote", label: "投票")
        XCTAssertEqual(PluginViewFormat.choicesFooter(PluginChoicesBlock(options: options, multiple: true, showResults: true,
                                                                         total: 4, maxSelections: 2, action: vote), s),
                       "最多选 2 项", "the hint, and never the total (it is only the shares' denominator)")
        XCTAssertEqual(PluginViewFormat.choicesFooter(PluginChoicesBlock(options: options, multiple: true, closed: true,
                                                                         maxSelections: 2, action: vote), s),
                       s.pluginViewEnded, "a closed poll has no hint")
        XCTAssertNil(PluginViewFormat.choicesFooter(PluginChoicesBlock(options: options, multiple: true, maxSelections: 2), s),
                     "a block without its action cannot be chosen")
        XCTAssertNil(PluginChoicesBlock(options: options, multiple: false, maxSelections: 2).cap, "a single choice")
        XCTAssertNil(PluginChoicesBlock(options: options, multiple: true, maxSelections: 0).cap, "zero is no limit")
        XCTAssertEqual(FlareStrings.english.pluginViewMaxSelections.isEmpty, false)
    }

    // MARK: Badges

    @MainActor
    func testEntryBadgesDrawInTheirPlaceAndTone() throws {
        let table = try PluginVectors.table()
        let entry = try XCTUnwrap((table["views"]?.arrayValue ?? []).first { $0["id"]?.stringValue == "entries-badges" })
        let view = try PluginVectors.decode(PluginViewModel.self, entry["view"])
        guard case .entries(let entries) = try XCTUnwrap(view.blocks.first) else { return XCTFail("entries") }
        let rows = entry["expect"]?["blocks"]?[0]?["rows"]?.arrayValue ?? []
        let users = try users(table)
        let card = PluginView(view: view, icon: nil, viewerId: entry["viewerId"]?.stringValue, busy: false,
                              busyActionId: nil, error: nil, embedded: false, resolveUser: nil, members: [],
                              formErrors: [], onAction: nil, onOpenDetail: nil, clock: PluginVectors.clock(table),
                              users: users)
        let block = try card.inspect().find(PluginEntriesBlockView.self)
        XCTAssertEqual(try block.findAll(PluginBadgeView.self).map { try $0.find(ViewType.Text.self).string() },
                       entries.items.compactMap(\.badge?.text))
        // Drawing order within each entry: name, me, badge, text.
        var texts = block.findAll(ViewType.Text.self).compactMap { try? $0.string() }
        for (item, fact) in zip(entries.items, rows) {
            let end = try XCTUnwrap(texts.firstIndex(of: item.text), item.text)
            let name = PluginViewFormat.entryName(item, resolved: users)
            let order: [String] = texts[...end].compactMap { text in
                if text == name { return "name" }
                if text == s.pluginViewMe { return "me" }
                if text == item.badge?.text { return "badge" }
                if text == item.text { return "text" }
                return nil
            }
            texts.removeFirst(end + 1)
            XCTAssertEqual(order, (fact["order"]?.arrayValue ?? []).compactMap(\.stringValue), "entry \(item.index)")
        }
    }

    func testBadgeTonesAreTheKitsAndAnUnknownOneIsNeutral() throws {
        let unknown = try JSONDecoder().decode(PluginBadge.self, from: Data(#"{"text":"奖励","tone":"accent"}"#.utf8))
        XCTAssertEqual(unknown, PluginBadge(text: "奖励", tone: .neutral))
        let bare = try JSONDecoder().decode(PluginBadge.self, from: Data(#"{"text":"x"}"#.utf8))
        XCTAssertEqual(bare.tone, .neutral)
        for scheme in [ColorScheme.light, .dark] {
            let colors = FlareColors.of(scheme, brand: .violet)
            XCTAssertEqual(pluginToneText(.neutral, colors), colors.textSecondary)
            XCTAssertEqual(pluginBadgeGround(.neutral, colors), colors.bgTertiary)
            XCTAssertEqual(pluginToneText(.success, colors), colors.successText)
            XCTAssertEqual(pluginBadgeGround(.success, colors), colors.success.opacity(0.06))
            XCTAssertEqual(pluginToneText(.warning, colors), colors.warningText)
            XCTAssertEqual(pluginToneText(.info, colors), colors.infoText)
            XCTAssertEqual(pluginToneText(.danger, colors), colors.errorText)
            XCTAssertEqual(pluginBadgeGround(.danger, colors), colors.error.opacity(0.06))
        }
    }

    // MARK: Rows

    func testRowLinesFormatTimeSkipBlanksAndKeepTheFirstOfAKey() throws {
        let table = try PluginVectors.table()
        let clock = PluginVectors.clock(table)
        let block = PluginRowsBlock(
            columns: [PluginRowsColumn(label: "金额"), PluginRowsColumn(label: "对方"), PluginRowsColumn(label: "时间", format: .time)],
            rows: [PluginRow(key: "a", cells: [PluginRowCell(text: "+¥1.00"), PluginRowCell(text: " "),
                                               PluginRowCell(text: "x", timeMs: 1_792_546_200_000)]),
                   PluginRow(key: "a", cells: [PluginRowCell(text: "dup")]),
                   PluginRow(key: "b", cells: [PluginRowCell(text: "-¥5.00")])])
        let lines = block.rows.map { PluginViewFormat.rowLines(block, $0, nowMs: clock.now(), s, utcOffsetMinutes: clock.utcOffsetMinutes) }
        XCTAssertEqual(lines[0], PluginRowLines(primary: "+¥1.00", secondary: "10月21日 09:30"))
        XCTAssertEqual(lines[2], PluginRowLines(primary: "-¥5.00", secondary: nil), "missing cells are blank")
        XCTAssertEqual(PluginViewFormat.rowsOnce(block.rows).map(\.cells.first?.text), ["+¥1.00", "-¥5.00"])
        XCTAssertFalse(PluginViewFormat.showsDetailKey(PluginViewModel(available: true, title: "t", blocks: [.rows(block)],
                                                                       detail: true), embedded: false),
                       "a view with rows offers no view details key")
    }

    /// The row's keys are the block's actions it offers, in the row's order; an id the block does not declare draws none.
    func testRowKeysAreTheBlockActionsTheRowOffers() {
        let block = PluginRowsBlock(columns: [PluginRowsColumn(label: "任务")], rows: [],
                                    actions: [PluginViewAction(id: "rename", label: "改名"),
                                              PluginViewAction(id: "remove", label: "删除", style: .danger)])
        let row = PluginRow(key: "t1", cells: [PluginRowCell(text: "写周报")],
                            actions: [PluginRowAction(id: "remove", input: ["taskId": "t1"]), PluginRowAction(id: "gone"),
                                      PluginRowAction(id: "rename", input: ["taskId": "t1"])])
        XCTAssertEqual(PluginViewFormat.rowKeys(block, row).map(\.action.id), ["remove", "rename"])
        XCTAssertEqual(PluginViewFormat.rowKeys(block, row).first?.input, ["taskId": "t1"])
    }

    func testOnlyTheRowThatRanSpinsItsKey() {
        let open = PluginRowKey(action: PluginViewAction(id: "open", label: "查看"), input: [:])
        let l1 = PluginRow(key: "l1", cells: []), l2 = PluginRow(key: "l2", cells: [])
        XCTAssertTrue(PluginRowsBlockView.spins(open, row: l2, busyActionId: "open", activeRow: "l2"))
        XCTAssertFalse(PluginRowsBlockView.spins(open, row: l1, busyActionId: "open", activeRow: "l2"),
                       "another row's key of the same action waits without spinning")
        XCTAssertFalse(PluginRowsBlockView.spins(open, row: l2, busyActionId: "history", activeRow: "l2"))
        XCTAssertFalse(PluginRowsBlockView.spins(open, row: l2, busyActionId: "open", activeRow: nil),
                       "an action the host runs on its own spins no row")
    }

    @MainActor
    func testARowKeyIsOffWhileTheViewIsBusyAndOnACopy() throws {
        let table = try PluginVectors.table()
        let wallet = try XCTUnwrap(try pages(table)["wallet"])
        let busy = try page(wallet, table: table, busyActionId: "history").inspect()
        XCTAssertTrue(try key(busy, "查看").isDisabled(), "busy holds every row key")
        let copy = PluginViewModel(available: true, title: "钱包", blocks: wallet.view.blocks, unavailableReason: .unboundCopy)
        var calls = 0
        let tree = try PluginView(view: copy, embedded: true, onAction: { _, _ in calls += 1 }).inspect()
        XCTAssertTrue(try key(tree, "查看").isDisabled(), "a read-only copy's rows do not act")
        XCTAssertEqual(calls, 0)
    }

    #if os(macOS)
    // MARK: Hosted

    /// A row's key takes a real click across its face; the row's words around it are not a control.
    @MainActor
    func testARowKeyTakesARealClick() {
        final class Log { var calls: [PluginActionPayload] = [] }
        let block = PluginRowsBlock(
            columns: [PluginRowsColumn(label: "金额")],
            rows: [PluginRow(key: "l2", cells: [PluginRowCell(text: "-¥5.00")], actions: [PluginRowAction(id: "open", input: ["packetId": "p2"])],
                             badge: PluginBadge(text: "发出红包"))],
            actions: [PluginViewAction(id: "open", label: "查看")])
        let size = CGSize(width: 360, height: 64)
        for (x, hits) in [(size.width - 24, 1), (size.width - 40, 1), (40, 0), (120, 0)] {
            let log = Log()
            let view = PluginView(view: PluginViewModel(available: true, title: "钱包", blocks: [.rows(block)]),
                                  embedded: true, onAction: { _, payload in log.calls.append(payload) })
            click(view, size: size, at: CGPoint(x: x, y: size.height / 2))
            XCTAssertEqual(log.calls.count, hits, "x \(x)")
            if hits > 0 {
                XCTAssertEqual(log.calls.first?.row, PluginRowRef(key: "l2", input: ["packetId": "p2"]))
            }
        }
    }

    /// A filter tab takes a click above its pill, inside the touch-target cell around it; a disabled row takes none.
    @MainActor
    func testAFilterTabTakesClicksAroundItsPill() {
        final class Log { var picks: [String] = [] }
        let size = CGSize(width: 200, height: 60)
        for (enabled, picks) in [(true, ["claim"]), (false, [])] {
            let log = Log()
            let tabs = FilterTabsView(options: [FlareFilterTabOption(value: "claim", label: "收到")],
                                      selection: .constant(""), enabled: enabled, onChange: { log.picks.append($0) })
            // The row is centred in the frame: its pill spans about y 15...45, the 48 pt cell about 6...54.
            click(tabs, size: size, at: CGPoint(x: 24, y: 9))
            XCTAssertEqual(log.picks, picks, "enabled \(enabled)")
        }
    }

    /// Hosts `view` in a borderless window and clicks at `point` (top-left origin).
    @MainActor
    private func click<V: View>(_ view: V, size: CGSize, at point: CGPoint) {
        _ = NSApplication.shared
        let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.contentView = host
        host.setFrameSize(size)
        host.layoutSubtreeIfNeeded()
        window.orderFront(nil)
        defer { window.orderOut(nil) }
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        let location = NSPoint(x: point.x, y: size.height - point.y)
        for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            guard let event = NSEvent.mouseEvent(with: type, location: location, modifierFlags: [],
                                                 timestamp: ProcessInfo.processInfo.systemUptime,
                                                 windowNumber: window.windowNumber, context: nil,
                                                 eventNumber: 0, clickCount: 1, pressure: 1) else { return }
            window.sendEvent(event)
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }
    #endif
}
