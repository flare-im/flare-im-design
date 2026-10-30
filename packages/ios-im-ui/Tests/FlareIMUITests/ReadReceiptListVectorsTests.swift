import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// `spec/read-receipt-list-vectors.json`: the read list's paging without UI, step by step against one holder, and the
/// sheet and view modifier that hand it to a host.
@MainActor
final class ReadReceiptListVectorsTests: XCTestCase {
    /// A loader whose calls stay in flight until a step settles them: the calls the step made, or a column's oldest.
    @MainActor
    private final class Loader {
        private(set) var asks: [[String?]] = []
        /// Each call in the order it was made; nil once settled.
        private var calls: [(column: FlareReadReceiptColumn, call: CheckedContinuation<FlareReadReceiptMembers?, Error>?)] = []

        func page(_ column: FlareReadReceiptColumn, _ cursor: String?) async throws -> FlareReadReceiptMembers? {
            asks.append([column.rawValue, cursor])
            return try await withCheckedThrowingContinuation { calls.append((column, $0)) }
        }

        /// Settles `column`'s oldest call in flight.
        func settle(_ column: FlareReadReceiptColumn, _ answer: PluginJSONValue, _ id: String) throws {
            guard let index = calls.firstIndex(where: { $0.column == column && $0.call != nil }) else {
                return XCTFail("\(id): no \(column) call in flight to settle")
            }
            try settle(call: index, answer, id)
        }

        /// Settles the call made `index`-th with `answer`: a members page, null (not offered) or "throw"; "pending"
        /// leaves it in flight.
        func settle(call index: Int, _ answer: PluginJSONValue, _ id: String) throws {
            if answer.stringValue == "pending" { return }
            guard index < calls.count, let call = calls[index].call else {
                return XCTFail("\(id): call \(index) is not in flight")
            }
            calls[index].call = nil
            if answer.stringValue == "throw" {
                call.resume(throwing: Failure())
            } else if answer.isNull {
                call.resume(returning: nil)
            } else {
                call.resume(returning: try Self.members(answer, id))
            }
        }

        /// Ends every call still in flight, so none outlives its case.
        func finish() {
            for index in calls.indices {
                calls[index].call?.resume(throwing: CancellationError())
                calls[index].call = nil
            }
        }

        static func members(_ json: PluginJSONValue, _ id: String) throws -> FlareReadReceiptMembers {
            let ids = try XCTUnwrap(json["people"]?.arrayValue, id).compactMap(\.stringValue)
            return FlareReadReceiptMembers(people: ids.map { Contact(id: $0, name: "Member \($0)") },
                                           nextCursor: json["nextCursor"]?.stringValue)
        }

        struct Failure: Error {}
    }

    /// Lets the holder's reads that a step settled land: the main actor runs what is queued on it while the test waits.
    private func drain() async {
        for _ in 0..<5 {
            await Task.yield()
            try? await Task.sleep(nanoseconds: 2_000_000)
        }
    }

    private func column(_ raw: Substring, _ id: String) throws -> FlareReadReceiptColumn {
        try XCTUnwrap(FlareReadReceiptColumn(rawValue: String(raw)), "\(id): column \(raw)")
    }

    private func check(_ pages: FlareReadReceiptPages?, _ expect: PluginJSONValue?, _ id: String) {
        guard let expect, !expect.isNull else { return XCTAssertNil(pages, "\(id): no list") }
        guard let pages else { return XCTFail("\(id): the list is missing") }
        XCTAssertEqual(pages.state.rawValue, expect["state"]?.stringValue, "\(id) state")
        for column in FlareReadReceiptColumn.allCases {
            let want = expect[column.rawValue]
            XCTAssertEqual(pages.members(column).people.map(\.id),
                           want?["people"]?.arrayValue?.compactMap(\.stringValue) ?? [], "\(id) \(column) people")
            XCTAssertEqual(pages.members(column).nextCursor, want?["nextCursor"]?.stringValue,
                           "\(id) \(column) cursor")
            XCTAssertEqual(pages.members(column).hasMore, want?["nextCursor"]?.stringValue != nil,
                           "\(id) \(column) has more")
        }
        XCTAssertEqual(pages.loadingMore?.rawValue, expect["loadingMore"]?.stringValue, "\(id) loadingMore")
        XCTAssertEqual(pages.loadMoreFailed?.rawValue, expect["loadMoreFailed"]?.stringValue, "\(id) loadMoreFailed")
    }

    func testEveryCaseStepByStep() async throws {
        let cases = try XCTUnwrap(try SpecVectors.table("read-receipt-list-vectors.json")["cases"]?.arrayValue)
        XCTAssertGreaterThanOrEqual(cases.count, 8, "the shared table lost cases")
        var steps = 0
        for vector in cases {
            let caseId = vector["id"]?.stringValue ?? "?"
            let loader = Loader()
            let list = FlareReadReceiptListState { column, cursor in try await loader.page(column, cursor) }
            for (index, step) in (vector["steps"]?.arrayValue ?? []).enumerated() {
                steps += 1
                let action = try XCTUnwrap(step["do"]?.stringValue, caseId)
                let id = "\(caseId) step \(index + 1) (\(action))"
                let asked = loader.asks.count
                if action == "open" {
                    list.open(step["key"]?.stringValue ?? "m1")
                } else if action == "close" {
                    list.open(nil)
                } else if action == "retry" {
                    list.retry()
                } else if action.hasPrefix("loadMore:") {
                    list.loadMore(try column(action.dropFirst("loadMore:".count), id))
                } else if action.hasPrefix("settle:") {
                    try loader.settle(try column(action.dropFirst("settle:".count), id),
                                      try XCTUnwrap(step["answer"], id), id)
                } else {
                    XCTFail("\(id): unknown step")
                }
                await drain()
                let made = Array(loader.asks[asked...])
                if let asks = step["asks"]?.arrayValue {
                    XCTAssertEqual(made, asks.map { ($0.arrayValue ?? []).map(\.stringValue) }, "\(id) asks")
                }
                if !action.hasPrefix("settle:") {
                    // The answers settle the calls this step made.
                    for (offset, ask) in made.enumerated() {
                        let raw = try XCTUnwrap(ask.first ?? nil, id)
                        let answer = step["answers"]?[raw] ?? (made.count == 1 ? step["answer"] : nil)
                        if let answer { try loader.settle(call: asked + offset, answer, id) }
                    }
                    await drain()
                }
                check(list.pages, step["expect"], id)
            }
            loader.finish()
            await drain()
        }
        XCTAssertGreaterThanOrEqual(steps, 30)
    }

    /// The sheet the holder hands over: its columns, state and paging, and its keys ask the holder.
    func testTheSheetDrawsTheHolderAndAsksIt() async throws {
        let loader = Loader()
        let list = FlareReadReceiptListState { column, cursor in try await loader.page(column, cursor) }
        let zh = FlareStrings()

        XCTAssertNoThrow(try ReadReceiptSheetView(list: list).inspect().find(ViewType.ProgressView.self),
                         "before the holder reads, the sheet reads as loading")

        list.open("m1")
        await drain()
        try loader.settle(.read, .object(["people": .array([.string("r1")]), "nextCursor": .string("rc1")]), "open")
        try loader.settle(.unread, .object(["people": .array([])]), "open")
        await drain()
        let sheet = try ReadReceiptSheetView(list: list, readCount: 2, unreadCount: 0).inspect()
        XCTAssertNoThrow(try sheet.find(text: zh.readTab(2)), "the tab number is the summary's, not the page's")
        XCTAssertNoThrow(try sheet.find(text: "Member r1"))
        try sheet.find(viewWithAccessibilityIdentifier: ReadReceiptSheetView.tailKeyID).find(ViewType.Button.self).tap()
        await drain()
        XCTAssertEqual(loader.asks.last, ["read", "rc1"], "load more asks the holder for the column's next page")
        XCTAssertEqual(list.pages?.loadingMore, .read)
        try loader.settle(.read, .null, "load more")
        await drain()
        XCTAssertEqual(list.pages?.read.hasMore, false)

        list.retry()
        await drain()
        try loader.settle(.read, .string("throw"), "retry")
        await drain()
        XCTAssertEqual(list.pages?.state, .error)
        let failed = try ReadReceiptSheetView(list: list).inspect()
        try failed.find(viewWithAccessibilityIdentifier: ReadReceiptSheetView.retryKeyID).find(ViewType.Button.self).tap()
        await drain()
        XCTAssertEqual(loader.asks.suffix(2), [["read", nil], ["unread", nil]], "retry reads both first pages again")
        loader.finish()
        await drain()
    }

    /// An answer that comes after the key moved on lands nowhere, and the holder's newest loader is the one asked.
    func testANewLoaderIsTheOneAskedAndOldAnswersLandNowhere() async throws {
        let first = Loader()
        let second = Loader()
        let list = FlareReadReceiptListState { column, cursor in try await first.page(column, cursor) }
        list.open("m1")
        await drain()
        list.page = { column, cursor in try await second.page(column, cursor) }
        list.open("m2")
        await drain()
        XCTAssertEqual(second.asks, [["read", nil], ["unread", nil]])
        try first.settle(.read, .object(["people": .array([.string("old")])]), "m1")
        try first.settle(.unread, .object(["people": .array([])]), "m1")
        await drain()
        XCTAssertEqual(list.pages?.state, .loading, "m1's answers are dropped")
        try second.settle(.read, .object(["people": .array([.string("new")])]), "m2")
        try second.settle(.unread, .null, "m2")
        await drain()
        XCTAssertEqual(list.pages?.state, .unavailable)
        list.open("m2")
        await drain()
        XCTAssertEqual(second.asks.count, 2, "the same key again reads nothing")
        first.finish()
        second.finish()
        await drain()
    }

    #if os(macOS)
    /// Lets the hosted view lay out and run its appear and change handlers.
    private func spin() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
    }

    /// The view modifier opens the list on the view's key, reads with the view's newest loader and closes it with the
    /// key.
    func testTheViewKeyOpensAndClosesTheList() async throws {
        _ = NSApplication.shared
        let loader = Loader()
        let list = FlareReadReceiptListState()
        func root(_ key: String?) -> some View {
            Color.clear.frame(width: 100, height: 100)
                .flareReadReceiptList(list, key: key) { column, cursor in try await loader.page(column, cursor) }
        }
        let host = NSHostingView(rootView: AnyView(root("m1")))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100), styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.contentView = host
        window.orderFront(nil)
        defer { window.orderOut(nil) }
        host.layoutSubtreeIfNeeded()
        spin()
        await drain()
        XCTAssertEqual(loader.asks, [["read", nil], ["unread", nil]], "the key opened the list with the view's loader")
        XCTAssertEqual(list.pages?.state, .loading)

        host.rootView = AnyView(root(nil))
        host.layoutSubtreeIfNeeded()
        spin()
        await drain()
        XCTAssertNil(list.pages, "no key, no list")
        loader.finish()
        await drain()
    }
    #endif
}
