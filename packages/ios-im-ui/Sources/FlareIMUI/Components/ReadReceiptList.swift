import SwiftUI

// The group read list's paging, without UI (spec/read-receipt-list-vectors.json): what a host keeps for
// ``ReadReceiptSheetView``. The host gives one loader that reads a page of one column; the kit owns the rest — both
// first pages on opening, a column's next page on `loadMore`, the whole-list state, the per-column busy and failed
// marks. The kit calls no SDK: the loader maps the SDK's answer (names the user ids, turns "not offered" into nil).

/// A column as far as it is read: its people in order, and the next page's cursor while there is one.
public struct FlareReadReceiptMembers: Sendable {
    public let people: [Contact]
    /// The next page's cursor; nil (an empty cursor too) once the column has no next page.
    public let nextCursor: String?

    public init(people: [Contact] = [], nextCursor: String? = nil) {
        self.people = people
        self.nextCursor = nextCursor.flatMap { $0.isEmpty ? nil : $0 }
    }

    /// The column has a next page: the sheet's `readHasMore` / `unreadHasMore`.
    public var hasMore: Bool { nextCursor != nil }
}

/// The list: its state, both columns, and the column reading (or last failing to read) its next page. The tab numbers
/// are not here: the host passes the message's current `receipt.readSummary`, which follows the read receipts as they
/// arrive.
public struct FlareReadReceiptPages: Sendable {
    public let state: FlareReadReceiptState
    public let read: FlareReadReceiptMembers
    public let unread: FlareReadReceiptMembers
    public let loadingMore: FlareReadReceiptColumn?
    public let loadMoreFailed: FlareReadReceiptColumn?

    public init(state: FlareReadReceiptState, read: FlareReadReceiptMembers = FlareReadReceiptMembers(),
                unread: FlareReadReceiptMembers = FlareReadReceiptMembers(),
                loadingMore: FlareReadReceiptColumn? = nil, loadMoreFailed: FlareReadReceiptColumn? = nil) {
        self.state = state; self.read = read; self.unread = unread
        self.loadingMore = loadingMore; self.loadMoreFailed = loadMoreFailed
    }

    public func members(_ column: FlareReadReceiptColumn) -> FlareReadReceiptMembers {
        column == .read ? read : unread
    }

    /// `column` starts reading its next page: it is the busy column, and its own failure mark clears.
    func reading(_ column: FlareReadReceiptColumn) -> Self {
        Self(state: state, read: read, unread: unread, loadingMore: column,
             loadMoreFailed: loadMoreFailed == column ? nil : loadMoreFailed)
    }

    /// `column`'s next page arrived (`page`; nil: the column ends): its people after the column's, someone listed
    /// already kept once, and the page's cursor.
    func appended(_ column: FlareReadReceiptColumn, _ page: FlareReadReceiptMembers?) -> Self {
        let shown = members(column)
        let next: FlareReadReceiptMembers
        if let page {
            var listed = Set(shown.people.map(\.id))
            next = FlareReadReceiptMembers(people: shown.people + page.people.filter { listed.insert($0.id).inserted },
                                           nextCursor: page.nextCursor)
        } else {
            next = FlareReadReceiptMembers(people: shown.people)
        }
        return Self(state: state, read: column == .read ? next : read, unread: column == .unread ? next : unread,
                    loadingMore: loadingMore == column ? nil : loadingMore, loadMoreFailed: loadMoreFailed)
    }

    /// `column`'s next page failed: the sheet offers to read it again.
    func failed(_ column: FlareReadReceiptColumn) -> Self {
        Self(state: state, read: read, unread: unread, loadingMore: loadingMore == column ? nil : loadingMore,
             loadMoreFailed: column)
    }
}

/// One page of `column` after `cursor` (the first page when nil), its user ids named as the host names people.
/// Returns nil when the message's list is not offered (the SDK's `NOT_FOUND`, `available: false`); throws on any
/// other failure.
public typealias FlareReadReceiptPageLoader =
    @MainActor (_ column: FlareReadReceiptColumn, _ cursor: String?) async throws -> FlareReadReceiptMembers?

/// The read list of the message a key names: ``pages`` is nil while no message is open. ``loadMore(_:)`` and
/// ``retry()`` are the sheet's `onLoadMore` and `onRetry`.
///
/// The host owns one (`@StateObject private var readList = FlareReadReceiptListState()`), keeps it on the open
/// message with ``SwiftUI/View/flareReadReceiptList(_:key:page:)`` and draws it with
/// ``ReadReceiptSheetView/init(list:readCount:unreadCount:initialTab:dismissible:onSelect:onClose:)``.
@MainActor
public final class FlareReadReceiptListState: ObservableObject {
    /// The open list; nil while the key is empty.
    @Published public private(set) var pages: FlareReadReceiptPages?
    /// The loader every read from now on uses (the latest one a host gave).
    public var page: FlareReadReceiptPageLoader

    private var key: String?
    private var generation = 0
    private var tasks: [Task<Void, Never>] = []
    /// Columns whose next page is being read: the sheet shows one busy column, but neither asks twice.
    private var reading: Set<FlareReadReceiptColumn> = []
    /// The first pages answered so far for the current read.
    private var firstPages: [FlareReadReceiptColumn: FlareReadReceiptMembers?] = [:]

    public init(page: @escaping FlareReadReceiptPageLoader = { _, _ in nil }) {
        self.page = page
    }

    /// Open the list of the message `key` names (nil or empty: close it). A new key reads both first pages again and
    /// drops whatever the previous one still had in flight; the same key again does nothing.
    public func open(_ key: String?) {
        let opened = key.flatMap { $0.isEmpty ? nil : $0 }
        guard opened != self.key else { return }
        self.key = opened
        if opened == nil {
            drop()
            pages = nil
        } else {
            read()
        }
    }

    /// Read the list again from both first pages (the sheet's retry), whatever its state; nothing while no message is
    /// open.
    public func retry() {
        if key != nil { read() }
    }

    /// The next page of `column` (the sheet's loadMore). Nothing happens unless the list is ready, the column has a
    /// next page and is not reading it already; the other column pages on its own meanwhile.
    public func loadMore(_ column: FlareReadReceiptColumn) {
        guard let current = pages, current.state == .ready, let cursor = current.members(column).nextCursor,
              !reading.contains(column) else { return }
        let mine = generation
        let loader = page
        reading.insert(column)
        pages = current.reading(column)
        tasks.append(Task { [weak self] in
            let settle: (FlareReadReceiptPages) -> FlareReadReceiptPages
            do {
                let next = try await loader(column, cursor)
                settle = { $0.appended(column, next) }
            } catch {
                settle = { $0.failed(column) }
            }
            guard let self, mine == self.generation else { return }
            self.reading.remove(column)
            if let latest = self.pages { self.pages = settle(latest) }
        })
    }

    /// Both first pages at once. Either failing fails the list at once; either not offered makes it unavailable once
    /// both have answered.
    private func read() {
        drop()
        let mine = generation
        let loader = page
        pages = FlareReadReceiptPages(state: .loading)
        for column in FlareReadReceiptColumn.allCases {
            tasks.append(Task { [weak self] in
                let answer: Result<FlareReadReceiptMembers?, Error>
                do { answer = .success(try await loader(column, nil)) } catch { answer = .failure(error) }
                guard let self, mine == self.generation else { return }
                self.firstPage(column, answer)
            })
        }
    }

    private func firstPage(_ column: FlareReadReceiptColumn, _ answer: Result<FlareReadReceiptMembers?, Error>) {
        guard pages?.state == .loading else { return }
        switch answer {
        case .failure:
            pages = FlareReadReceiptPages(state: .error)
        case .success(let members):
            firstPages[column] = .some(members)
            guard let readAnswer = firstPages[.read], let unreadAnswer = firstPages[.unread] else { return }
            if let read = readAnswer, let unread = unreadAnswer {
                pages = FlareReadReceiptPages(state: .ready, read: read, unread: unread)
            } else {
                pages = FlareReadReceiptPages(state: .unavailable)
            }
        }
    }

    /// Forget what is in flight: its answers land nowhere.
    private func drop() {
        generation += 1
        reading.removeAll()
        firstPages.removeAll()
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
    }
}

public extension View {
    /// Keeps `list` on the read list of the message `key` names (nil or empty: no list), read with `page`: a new key
    /// reads both first pages again, and the latest `page` is the one every read uses.
    func flareReadReceiptList(_ list: FlareReadReceiptListState, key: String?,
                              page: @escaping FlareReadReceiptPageLoader) -> some View {
        modifier(FlareReadReceiptListBinding(list: list, key: key, page: page))
    }
}

/// The host's key and loader, handed to the holder.
private struct FlareReadReceiptListBinding: ViewModifier {
    let list: FlareReadReceiptListState
    let key: String?
    let page: FlareReadReceiptPageLoader

    func body(content: Content) -> some View {
        // The loader is not drawn: holding the newest one changes nothing on screen.
        list.page = page
        return content
            .onAppear { list.open(key) }
            .onChange(of: key) { list.open($0) }
    }
}

public extension ReadReceiptSheetView {
    /// The sheet for a list ``FlareReadReceiptListState`` keeps: its columns, state and paging come from `list`;
    /// `readCount` / `unreadCount` are the message's summary counts. The view that owns the holder (its
    /// `@StateObject`) redraws the sheet as the pages move. Until the holder has started reading the open message's
    /// list it reads as loading.
    @MainActor
    init(list: FlareReadReceiptListState, readCount: Int? = nil, unreadCount: Int? = nil,
         initialTab: FlareReadReceiptColumn = .read, dismissible: Bool = false,
         onSelect: ((String) -> Void)? = nil, onClose: (() -> Void)? = nil) {
        let pages = list.pages ?? FlareReadReceiptPages(state: .loading)
        self.init(readers: pages.read.people, unread: pages.unread.people, readCount: readCount,
                  unreadCount: unreadCount, state: pages.state, readHasMore: pages.read.hasMore,
                  unreadHasMore: pages.unread.hasMore, loadingMore: pages.loadingMore,
                  loadMoreFailed: pages.loadMoreFailed, initialTab: initialTab, dismissible: dismissible,
                  onSelect: onSelect, onClose: onClose,
                  onLoadMore: { [weak list] column in list?.loadMore(column) },
                  onRetry: { [weak list] in list?.retry() })
    }
}
