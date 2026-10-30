import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// `spec/read-receipt-vectors.json`: the read list's tabs, states, paging tail and the events a tap emits, as facts
/// and on the drawn sheet.
final class ReadReceiptSheetVectorsTests: XCTestCase {
    private let zh = FlareStrings()

    private struct Input {
        let state: FlareReadReceiptState
        let readers: [Contact]
        let unread: [Contact]
        let readCount: Int?
        let unreadCount: Int?
        let readHasMore: Bool
        let unreadHasMore: Bool
        let loadingMore: FlareReadReceiptColumn?
        let loadMoreFailed: FlareReadReceiptColumn?
        let initialTab: FlareReadReceiptColumn

        init(_ json: PluginJSONValue) throws {
            state = try XCTUnwrap(FlareReadReceiptState(rawValue: json["state"]?.stringValue ?? "ready"))
            readers = (0..<(json["readers"]?.intValue ?? 0)).map { Contact(id: "r\($0 + 1)", name: "Reader \($0 + 1)") }
            unread = (0..<(json["unread"]?.intValue ?? 0)).map { Contact(id: "u\($0 + 1)", name: "Unread \($0 + 1)") }
            readCount = json["readCount"]?.intValue
            unreadCount = json["unreadCount"]?.intValue
            readHasMore = json["readHasMore"]?.boolValue ?? false
            unreadHasMore = json["unreadHasMore"]?.boolValue ?? false
            loadingMore = json["loadingMore"]?.stringValue.flatMap(FlareReadReceiptColumn.init(rawValue:))
            loadMoreFailed = json["loadMoreFailed"]?.stringValue.flatMap(FlareReadReceiptColumn.init(rawValue:))
            initialTab = json["initialTab"]?.stringValue.flatMap(FlareReadReceiptColumn.init(rawValue:)) ?? .read
        }

        func layout(_ active: FlareReadReceiptColumn) -> FlareReadReceiptLayout {
            .of(state: state, active: active, readers: readers.count, unread: unread.count, readCount: readCount,
                unreadCount: unreadCount, readHasMore: readHasMore, unreadHasMore: unreadHasMore,
                loadingMore: loadingMore, loadMoreFailed: loadMoreFailed)
        }
    }

    /// The events a sheet emitted, in the vectors' shape: ["loadMore", "read"], ["retry"].
    private final class Events { var log: [[String]] = [] }

    private func sheet(_ input: Input, tab: FlareReadReceiptColumn, events: Events) -> ReadReceiptSheetView {
        ReadReceiptSheetView(readers: input.readers, unread: input.unread, readCount: input.readCount,
                             unreadCount: input.unreadCount, state: input.state, readHasMore: input.readHasMore,
                             unreadHasMore: input.unreadHasMore, loadingMore: input.loadingMore,
                             loadMoreFailed: input.loadMoreFailed, initialTab: tab, dismissible: true,
                             onSelect: { events.log.append(["select", $0]) }, onClose: { events.log.append(["close"]) },
                             onLoadMore: { events.log.append(["loadMore", $0.rawValue]) },
                             onRetry: { events.log.append(["retry"]) })
    }

    private func cases() throws -> [PluginJSONValue] {
        let cases = try XCTUnwrap(try SpecVectors.table("read-receipt-vectors.json")["cases"]?.arrayValue)
        XCTAssertGreaterThanOrEqual(cases.count, 13, "the shared table lost cases")
        return cases
    }

    /// Checks `layout` and the sheet drawn for it against `expect` (body, rows, tail and, when given, tabs).
    @MainActor
    private func check(_ input: Input, active: FlareReadReceiptColumn, _ expect: PluginJSONValue, id: String) throws {
        let layout = input.layout(active)
        XCTAssertEqual(layout.body.rawValue, expect["body"]?.stringValue, "\(id) body")
        XCTAssertEqual(layout.rows, expect["rows"]?.intValue, "\(id) rows")
        XCTAssertEqual(layout.tail.rawValue, expect["tail"]?.stringValue, "\(id) tail")
        if let empty = expect["empty"]?.stringValue { XCTAssertEqual(layout.empty?.rawValue, empty, "\(id) empty") }
        if let tabs = expect["tabs"] {
            if tabs.isNull {
                XCTAssertNil(layout.tabs, "\(id): no tabs")
            } else {
                let facts = try XCTUnwrap(tabs.arrayValue)
                XCTAssertEqual(layout.tabs?.map(\.column.rawValue), facts.compactMap { $0["value"]?.stringValue }, id)
                XCTAssertEqual(layout.tabs?.map(\.count), facts.map { $0["count"]?.intValue }, "\(id) tab numbers")
            }
        }

        // The sheet draws the same.
        let view = try sheet(input, tab: active, events: Events()).inspect()
        XCTAssertNoThrow(try view.find(text: zh.readReceipt), "\(id): the sheet carries its own title")
        for tab in layout.tabs ?? [] {
            XCTAssertNoThrow(try view.find(text: ReadReceiptSheetView.tabLabel(tab, zh)), "\(id) tab \(tab.column)")
        }
        if layout.tabs == nil {
            for column in FlareReadReceiptColumn.allCases {
                XCTAssertThrowsError(try view.find(viewWithAccessibilityIdentifier: ReadReceiptSheetView.tabID(column)),
                                     "\(id): no tabs")
            }
        }
        let prefix = active == .read ? "Reader " : "Unread "
        let rows = view.findAll(ViewType.Text.self, where: { (try? $0.string().hasPrefix(prefix)) == true })
        XCTAssertEqual(rows.count, layout.rows, "\(id) drawn rows")
        let tailKey = try? view.find(viewWithAccessibilityIdentifier: ReadReceiptSheetView.tailKeyID)
        XCTAssertEqual(tailKey != nil, layout.tail == .loadMore || layout.tail == .retry, "\(id) tail key")
        switch layout.tail {
        case .loadMore: XCTAssertNoThrow(try view.find(text: zh.readReceiptLoadMore), id)
        case .retry: XCTAssertNoThrow(try view.find(text: zh.readReceiptLoadMoreFailed), id)
        case .busy: XCTAssertNoThrow(try view.find(ViewType.ProgressView.self), "\(id): a spinner, not a control")
        case .none: break
        }
        switch layout.body {
        case .spinner: XCTAssertNoThrow(try view.find(ViewType.ProgressView.self), id)
        case .error:
            XCTAssertNoThrow(try view.find(text: zh.readReceiptLoadFailed), id)
            XCTAssertNoThrow(try view.find(viewWithAccessibilityIdentifier: ReadReceiptSheetView.retryKeyID), id)
        case .unavailable:
            XCTAssertNoThrow(try view.find(text: zh.readReceiptUnavailable), id)
            XCTAssertThrowsError(try view.find(viewWithAccessibilityIdentifier: ReadReceiptSheetView.retryKeyID),
                                 "\(id): no retry")
        case .empty:
            XCTAssertNoThrow(try view.find(text: layout.empty == .unread ? zh.everyoneHasRead : zh.noReadersYet), id)
        case .list:
            XCTAssertThrowsError(try view.find(text: zh.noReadersYet), "\(id): a column with a next page has no notice")
        }
    }

    @MainActor
    func testEveryCaseDrawsItsTabsBodyAndTail() throws {
        for vector in try cases() {
            let id = vector["id"]?.stringValue ?? "?"
            let input = try Input(try XCTUnwrap(vector["input"], id))
            try check(input, active: input.initialTab, try XCTUnwrap(vector["expect"], id), id: id)
        }
    }

    /// Each step taps the drawn control and compares what the sheet emitted. A tab switch is the sheet's own state:
    /// it emits nothing, and what follows is the sheet drawn with that tab active (`then`).
    @MainActor
    func testTapsEmitWhatTheTableSays() throws {
        var steps = 0
        for vector in try cases() {
            let id = vector["id"]?.stringValue ?? "?"
            let input = try Input(try XCTUnwrap(vector["input"], id))
            for step in vector["taps"]?.arrayValue ?? [] {
                steps += 1
                let tap = try XCTUnwrap(step["tap"]?.stringValue, id)
                let want = (step["emits"]?.arrayValue ?? []).map { ($0.arrayValue ?? []).compactMap(\.stringValue) }
                let events = Events()
                let view = try sheet(input, tab: input.initialTab, events: events).inspect()
                switch tap {
                case "tail":
                    if let key = try? view.find(viewWithAccessibilityIdentifier: ReadReceiptSheetView.tailKeyID) {
                        try key.find(ViewType.Button.self).tap()
                    }
                case "retry":
                    try view.find(viewWithAccessibilityIdentifier: ReadReceiptSheetView.retryKeyID)
                        .find(ViewType.Button.self).tap()
                default:
                    let column = try XCTUnwrap(FlareReadReceiptColumn(rawValue: String(tap.dropFirst("tab:".count))), id)
                    try view.find(viewWithAccessibilityIdentifier: ReadReceiptSheetView.tabID(column))
                        .find(ViewType.Button.self).tap()
                    if let then = step["then"] { try check(input, active: column, then, id: "\(id) then") }
                }
                XCTAssertEqual(events.log, want, "\(id): \(tap)")
            }
        }
        XCTAssertGreaterThanOrEqual(steps, 6)
    }

    func testTabNumbersAreTheSummaryNeverTheListLength() {
        let pageOne = FlareReadReceiptLayout.of(state: .ready, active: .read, readers: 20, unread: 20, readCount: nil,
                                                unreadCount: nil, readHasMore: true, unreadHasMore: true,
                                                loadingMore: nil, loadMoreFailed: nil)
        XCTAssertEqual(pageOne.tabs?.map(\.count), [nil, nil])
        XCTAssertEqual(ReadReceiptSheetView.tabLabel(pageOne.tabs![0], zh), zh.readReceiptRead)
        XCTAssertEqual(ReadReceiptSheetView.tabLabel(.init(column: .unread, count: 12), zh), zh.unreadTab(12))
        XCTAssertEqual(ReadReceiptSheetView.tabLabel(.init(column: .read, count: 0), FlareStrings.english),
                       FlareStrings.english.readTab(0), "zero is a number, not an absent count")
    }

    func testTheCopyIsTheSharedCopy() throws {
        let copy = try XCTUnwrap(try SpecVectors.table("read-receipt-vectors.json")["strings"])
        for (language, strings) in [("zh", zh), ("en", FlareStrings.english)] {
            let table = try XCTUnwrap(copy[language], language)
            XCTAssertEqual(strings.readReceiptLoadFailed, table["readReceiptLoadFailed"]?.stringValue, language)
            XCTAssertEqual(strings.readReceiptUnavailable, table["readReceiptUnavailable"]?.stringValue, language)
            XCTAssertEqual(strings.readReceiptLoadMore, table["readReceiptLoadMore"]?.stringValue, language)
            XCTAssertEqual(strings.readReceiptLoadMoreFailed, table["readReceiptLoadMoreFailed"]?.stringValue, language)
        }
    }

    #if os(macOS)
    private struct WidthKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
    }

    private final class Box { var width: CGFloat = 0 }

    /// The sheet's laid-out width in a container `container` wide.
    @MainActor
    private func laidOutWidth(inOverlay: Bool, container: CGFloat) -> CGFloat {
        _ = NSApplication.shared
        let box = Box()
        let readers = (1...3).map { Contact(id: "r\($0)", name: "Reader \($0)") }
        let root = ReadReceiptSheetView(readers: readers, unread: [])
            .background(GeometryReader { Color.clear.preference(key: WidthKey.self, value: $0.size.width) })
            .onPreferenceChange(WidthKey.self) { box.width = $0 }
            .environment(\.flareInOverlaySurface, inOverlay)
            .frame(width: container, height: 480)
        let host = NSHostingView(rootView: root)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: container, height: 480), styleMask: .borderless,
                              backing: .buffered, defer: false)
        window.contentView = host
        host.setFrameSize(NSSize(width: container, height: 480))
        host.layoutSubtreeIfNeeded()
        window.orderFront(nil)
        defer { window.orderOut(nil) }
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        return box.width
    }

    /// Standing alone the sheet is a card at most 320 wide that narrows with its container; in a kit sheet or modal
    /// it draws no shell and takes the surface's width.
    @MainActor
    func testTheWidthFollowsTheContainer() {
        XCTAssertEqual(laidOutWidth(inOverlay: false, container: 600), ReadReceiptSheetView.shellMaxWidth, accuracy: 0.5)
        XCTAssertEqual(laidOutWidth(inOverlay: false, container: 260), 260, accuracy: 0.5)
        XCTAssertEqual(laidOutWidth(inOverlay: true, container: 600), 600, accuracy: 0.5)
    }
    #endif
}
