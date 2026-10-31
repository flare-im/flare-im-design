import CoreGraphics
import Foundation

/// The two ends of the message list and its back-to-latest key (`spec/message-list-paging-vectors.json`, read by the
/// Vue, Flutter and Compose kits too). A window is the run of messages the host hands the list; its older end (above
/// the timeline) and its newer end (below it) follow one rule.
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
}
