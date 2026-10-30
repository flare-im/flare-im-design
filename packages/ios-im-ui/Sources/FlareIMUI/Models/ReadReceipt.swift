import Foundation

/// The state of a whole read list. Spec: ReadReceiptSheet `state` (spec/read-receipt-vectors.json).
///
/// `ready` draws the tabs and the active column; `loading` the tabs (with the summary counts when given) over a
/// spinner; `error` a notice with a retry key and no tabs; `unavailable` a notice with no tabs and no retry — for a
/// message whose list the SDK does not have (`NOT_FOUND`, `available: false`).
public enum FlareReadReceiptState: String, Sendable, CaseIterable {
    case ready, loading, error, unavailable
}

/// A column of the read list.
public enum FlareReadReceiptColumn: String, Sendable, CaseIterable {
    case read, unread
}

/// What ``ReadReceiptSheetView`` draws for its inputs: the same facts on every kit.
public struct FlareReadReceiptLayout: Equatable, Sendable {
    /// The sheet's body under the title row (and the tabs, when drawn).
    public enum Body: String, Sendable { case spinner, error, unavailable, list, empty }
    /// The last row of a list: nothing, a spinner (not a control), the load-more key or the load-more-failed key.
    public enum Tail: String, Sendable { case none, busy, loadMore, retry }
    /// A tab and the number it shows (nil: no number).
    public struct Tab: Equatable, Sendable {
        public let column: FlareReadReceiptColumn
        public let count: Int?
    }

    /// The two tabs in order, or nil when they are not drawn.
    public let tabs: [Tab]?
    public let body: Body
    /// The member rows drawn.
    public let rows: Int
    public let tail: Tail
    /// The column whose empty notice shows (body `empty`).
    public let empty: FlareReadReceiptColumn?

    /// The layout for `state` with `active` shown and `readers` / `unread` members loaded.
    ///
    /// - The tab numbers are the summary counts (`readCount` / `unreadCount`, from `receipt.readSummary`); without one
    ///   a tab has no number — never the length of the loaded list, which may be one page.
    /// - After the active column's rows: `loadingMore` on it → busy; else `loadMoreFailed` on it → retry; else its
    ///   `hasMore` → loadMore; else nothing. A column with no rows and no next page shows its empty notice; with a
    ///   next page it shows only the key.
    public static func of(state: FlareReadReceiptState, active: FlareReadReceiptColumn,
                          readers: Int, unread: Int, readCount: Int?, unreadCount: Int?,
                          readHasMore: Bool, unreadHasMore: Bool,
                          loadingMore: FlareReadReceiptColumn?, loadMoreFailed: FlareReadReceiptColumn?) -> Self {
        let tabs = [Tab(column: .read, count: readCount), Tab(column: .unread, count: unreadCount)]
        switch state {
        case .loading: return Self(tabs: tabs, body: .spinner, rows: 0, tail: .none, empty: nil)
        case .error: return Self(tabs: nil, body: .error, rows: 0, tail: .none, empty: nil)
        case .unavailable: return Self(tabs: nil, body: .unavailable, rows: 0, tail: .none, empty: nil)
        case .ready: break
        }
        let rows = active == .read ? readers : unread
        let hasMore = active == .read ? readHasMore : unreadHasMore
        let tail: Tail = loadingMore == active ? .busy
            : loadMoreFailed == active ? .retry
            : hasMore ? .loadMore
            : .none
        if rows == 0 && tail == .none {
            return Self(tabs: tabs, body: .empty, rows: 0, tail: .none, empty: active)
        }
        return Self(tabs: tabs, body: .list, rows: rows, tail: tail, empty: nil)
    }

    /// The column a tap on the tail asks the next page of: the active one for the load-more and retry keys, none for
    /// a spinner (a column never asks twice while it is loading more).
    public func tailRequest(_ active: FlareReadReceiptColumn) -> FlareReadReceiptColumn? {
        tail == .loadMore || tail == .retry ? active : nil
    }
}
