import CoreGraphics

/// Where the reader is in a timeline, and what new messages do to that place (Vue `MessageList.vue` tail
/// follow): the list opens at the newest message; messages added at the end keep a reader who is at the
/// bottom there, and bring the reader down when one of them is the reader's own; a reader who scrolled up
/// stays where they are and is told how many messages arrived below; older messages added above never move
/// what the reader is looking at.
struct TimelineFollow: Equatable {
    /// How far above the end of the timeline still counts as being at the newest message (Vue `BOTTOM_STICKY_PX`).
    static let stickyDistance: CGFloat = 80

    /// The reader is at the newest message.
    private(set) var atBottom = true
    /// The list follows the newest message: true at the bottom and after a jump to it, false once the reader
    /// scrolls away.
    private(set) var followTail = true
    /// The newest message when the reader left the bottom; the messages after it are the ones below.
    private(set) var anchorTailId: String?
    /// The newest message the last position update saw, to tell content growing under a following reader
    /// from the reader scrolling away.
    private var syncedTailId: String?

    /// How `next` holds `previous`: the previous ids as one contiguous window of the next ones, with the counts
    /// added before and after it (Vue `locatePreviousWindow`). Nil when the previous ids are empty, when nothing
    /// was added, or when the lists are not one window of each other (a replaced message, a new page).
    static func window(from previous: [String], to next: [String]) -> (prepended: Int, appended: Int)? {
        guard !previous.isEmpty, next.count > previous.count, let first = previous.first else { return nil }
        var start = next.startIndex
        while let found = next[start...].firstIndex(of: first), found + previous.count <= next.count {
            if next[found..<(found + previous.count)].elementsEqual(previous) {
                return (prepended: found, appended: next.count - found - previous.count)
            }
            start = found + 1
        }
        return nil
    }

    /// One message of the timeline as these rules see it: its id, and whether the reader sent it.
    struct Row: Equatable {
        let id: String
        let own: Bool
    }

    /// The position changed (the reader scrolled, the viewport or the content resized). `distanceToBottom` is how
    /// far the end of the timeline is below the bottom of the viewport; `tailId` is the newest message. At the
    /// bottom the list follows again; away from it the reader browses, and the newest message then is remembered.
    /// When the newest message changed since the last update while the list was following, the content grew under
    /// the reader: the list keeps following and the added messages decide (``followsAppended(includingOwn:)``).
    mutating func sync(distanceToBottom: CGFloat, tailId: String?) {
        defer { syncedTailId = tailId }
        if distanceToBottom <= Self.stickyDistance {
            atBottom = true
            followTail = true
            anchorTailId = nil
            return
        }
        atBottom = false
        // Content that grew since the last update, under a reader the list was still following: the
        // list keeps following. Without a previous update nothing has "changed since", so a position
        // away from the end is the reader browsing — the first thing the list hears must not be read
        // as growth, or a reader who scrolls up before anything arrives never stops being followed.
        if followTail, let syncedTailId, tailId != syncedTailId { return }
        followTail = false
        if anchorTailId == nil { anchorTailId = tailId }
    }

    /// The position as the bottom-most visible row reports it: `atEnd` is whether that row is the end of
    /// the timeline. This is what a scroll view's own position binding gives, and on macOS it is the only
    /// mechanism that follows a scroll — a geometry preference inside the content is recomputed when the
    /// content is laid out again, which scrolling does not do.
    mutating func sync(atEnd: Bool, tailId: String?) {
        sync(distanceToBottom: atEnd ? 0 : .infinity, tailId: tailId)
    }

    /// Messages added at the end: whether the list goes to the newest message. It does when it is following, when
    /// the reader is at the bottom, or when one of the added messages is the reader's own.
    func followsAppended(includingOwn: Bool) -> Bool {
        followTail || atBottom || includingOwn
    }

    /// The rows changed from `previous` to `rows`: whether the list goes to the newest message. The first rows open
    /// at the newest one; rows added at the end follow ``followsAppended(includingOwn:)``; older rows added above keep
    /// the reading position; a replaced newest row counts as one added. No rows start over.
    mutating func rowsChanged(from previous: [String], to rows: [Row]) -> Bool {
        guard !rows.isEmpty else {
            self = TimelineFollow()
            return false
        }
        guard !previous.isEmpty else { return true }
        let ids = rows.map(\.id)
        if let window = Self.window(from: previous, to: ids) {
            return window.appended > 0 && followsAppended(includingOwn: rows.suffix(window.appended).contains { $0.own })
        }
        guard previous.last != ids.last, let last = rows.last else { return false }
        return followsAppended(includingOwn: last.own)
    }

    /// The list went to the newest message.
    mutating func reachedBottom(tailId: String?) {
        atBottom = true
        followTail = true
        anchorTailId = nil
        syncedTailId = tailId
    }

    /// The count on the scroll-to-latest key: the messages after the one that was newest when the reader left
    /// the bottom. Zero at the bottom, or when that message is no longer loaded.
    func pendingBelowCount(_ messages: [FlareMessageData]) -> Int {
        guard !atBottom, let anchorTailId, let index = messages.lastIndex(where: { $0.id == anchorTailId }) else { return 0 }
        return messages.count - 1 - index
    }
}
