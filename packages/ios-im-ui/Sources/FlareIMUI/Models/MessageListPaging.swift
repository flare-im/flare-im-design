import CoreGraphics
import Foundation

/// The two ends of the message list and its back-to-latest key (`spec/message-list-paging-vectors.json`, read by the
/// Vue, Flutter and Compose kits too). A window is the run of messages the host hands the list; its older end (above
/// the timeline) and its newer end (below it) follow one rule. Whether the reader is at the bottom of the window, as the
/// list tells the host, is `atBottom`.
enum FlareMessageListPaging {
    /// How close to an edge the reader must scroll before the list asks for the next page there, in points.
    static let olderWithin: CGFloat = 160
    static let newerWithin: CGFloat = 160

    /// One end of the window, as the host describes it.
    struct End: Equatable {
        /// There is more to read past this end.
        var has: Bool
        /// A page past this end is being read.
        var loading: Bool
        /// The last page past this end failed; nil, empty or blank is no error.
        var error: String?
        /// The host takes this end's load intent.
        var handled: Bool

        var failed: Bool { !(error?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) }
    }

    /// What one end draws.
    struct Edge: Equatable {
        var spinner: Bool
        var error: Bool
        var button: Bool
    }

    /// While loading, a spinner and nothing else (the last error is not repeated while it is being retried); otherwise
    /// the error when there is one, and the load or retry button while there is more and the host takes the intent.
    static func edge(_ end: End) -> Edge {
        if end.loading { return Edge(spinner: true, error: false, button: false) }
        return Edge(spinner: false, error: end.failed, button: end.has && end.handled)
    }

    /// The pages the list asks for by itself.
    struct Requests: Equatable {
        var older: Bool
        var newer: Bool
    }

    /// The pages the list asks for as the reader scrolls: an end asks within its distance of its edge (inclusive),
    /// while there is more, nothing is loading, the last page did not fail (after a failure only the retry button
    /// asks) and the host takes the intent. `fromTop` is how far the first row's top is above the viewport's top,
    /// `fromBottom` how far the end of the timeline is below the viewport's bottom.
    static func requests(fromTop: CGFloat, fromBottom: CGFloat, older: End, newer: End) -> Requests {
        func asks(_ end: End, _ distance: CGFloat, _ within: CGFloat) -> Bool {
            end.handled && end.has && !end.loading && !end.failed && distance <= within
        }
        return Requests(older: asks(older, fromTop, olderWithin), newer: asks(newer, fromBottom, newerWithin))
    }

    /// The floating key at the bottom: whether it shows, the count it carries, and what a tap does.
    struct LatestEntry: Equatable {
        enum Action: Equatable { case jumpToLatest, scrollToBottom }
        var shown: Bool
        var count: Int
        var action: Action?
    }

    /// A window detached from the latest (`hasNewer`) offers the way back to the latest messages, without a count —
    /// rows below a detached reader are history read in, not news — when the host takes the jump. Otherwise it is the
    /// new-messages key: shown while messages arrived below a reader who scrolled up, counting them, and it scrolls to
    /// the bottom.
    static func latestEntry(hasNewer: Bool, handled: Bool, belowCount: Int) -> LatestEntry {
        if hasNewer {
            return handled ? LatestEntry(shown: true, count: 0, action: .jumpToLatest) : LatestEntry(shown: false, count: 0, action: nil)
        }
        return belowCount > 0
            ? LatestEntry(shown: true, count: belowCount, action: .scrollToBottom)
            : LatestEntry(shown: false, count: 0, action: nil)
    }

    /// Rows appended to a window that was detached are a newer page read in, not messages that arrived: the core
    /// appends nothing to a detached window, and a message sent from one comes back as a new latest window.
    static func isNewerPage(from previous: [String], to next: [String], wasDetached: Bool) -> Bool {
        guard wasDetached, let window = TimelineFollow.window(from: previous, to: next) else { return false }
        return window.prepended == 0 && window.appended > 0
    }

    /// Whether the host replaced the window as a whole rather than grew or edited the one the reader is in (`windows`).
    /// `previous` and `next` are row keys in timeline order. Both must have rows, and then any of: the host's name for
    /// the window (`previousWindowId` to `windowId`, the core timeline view's `viewId`; nil or empty is none) changed
    /// from one name to another; the latest window the reader asked for arrived (`jumpRequested`, attached: not
    /// `hasNewer`); no row of the new window was in the old one.
    static func windowReplaced(previous: [String], next: [String], jumpRequested: Bool = false, hasNewer: Bool = false,
                               previousWindowId: String? = nil, windowId: String? = nil) -> Bool {
        guard !previous.isEmpty, !next.isEmpty else { return false }
        let before = previousWindowId ?? "", after = windowId ?? ""
        if !before.isEmpty, !after.isEmpty, before != after { return true }
        if jumpRequested && !hasNewer { return true }
        let kept = Set(previous)
        return !next.contains(where: kept.contains)
    }

    /// How far the end of the timeline may be below the viewport's bottom with the reader still at the bottom, in points.
    static let bottomWithin: CGFloat = 80

    /// The reader is at the bottom: the end of the timeline is at most ``bottomWithin`` below the viewport.
    static func atBottom(fromBottom: CGFloat) -> Bool { fromBottom <= bottomWithin }

    /// What the list tells the host about the reader being at the bottom of the window (`atBottom`). Each method is one
    /// step and answers what to tell the host after it: true, false, or nil for nothing. The list tells the host only
    /// when the answer changes, and once after its first layout. A window replaced without the reader asking for it and
    /// a locate hold the answer at not at the bottom until the reader moves the list, the list goes to its newest row
    /// for the reader, the latest window the reader asked for arrives or the window empties; ending a hold answers from
    /// the last layout.
    struct BottomReport: Equatable {
        /// The answer last told to the host; nil before the first one.
        private(set) var reported: Bool?
        private var held = false
        private var last: CGFloat?

        /// A layout or a scroll the list measured: `fromBottom` is how far the end of the timeline is below the viewport.
        mutating func layout(fromBottom: CGFloat) -> Bool? {
            last = fromBottom
            return tell(!held && FlareMessageListPaging.atBottom(fromBottom: fromBottom))
        }

        /// The host handed a window that replaces the one shown, without the reader asking for it.
        mutating func replaced() -> Bool? { hold() }

        /// The latest window the reader asked for (the back-to-latest key) arrived.
        mutating func jumpedToLatest() -> Bool? { release() }

        /// A locate took the reading position.
        mutating func located() -> Bool? { hold() }

        /// The reader moved the list themselves.
        mutating func readerMoved() -> Bool? { release() }

        /// The list went to its newest row for the reader: the new-messages key, or a message of the reader's own.
        mutating func wentToLatest() -> Bool? { release() }

        /// The window lost all its rows: an empty list is at its bottom.
        mutating func emptied() -> Bool? {
            held = false
            return layout(fromBottom: 0)
        }

        /// Another conversation: the list starts over and answers once more after its first layout.
        mutating func anotherConversation() { self = BottomReport() }

        private mutating func hold() -> Bool? {
            held = true
            return reported == true ? tell(false) : nil
        }

        private mutating func release() -> Bool? {
            held = false
            guard let last else { return nil }
            return layout(fromBottom: last)
        }

        private mutating func tell(_ atBottom: Bool) -> Bool? {
            guard reported != atBottom else { return nil }
            reported = atBottom
            return atBottom
        }
    }
}
