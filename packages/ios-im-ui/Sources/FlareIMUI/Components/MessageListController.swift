import SwiftUI

/// The rows a list is drawing, looked up by either of the two ids a row answers to.
///
/// A row has two: the id the list draws it under (``FlareMessageData/id``) and the id the core names
/// it by (``FlareMessageData/serverId``). They differ for a message this device sent — the row keeps
/// its client id as the list's key after the server names it — and a quote points at its original by
/// the core's id. So a locate that compared row ids alone would report a message that is on screen as
/// missing. Both ids answer here, and the answer is always the row id: the only one a scroll can be
/// asked with.
///
/// This is the one place that rule is written. The bubble's quote
/// (``MessageListView/quoteLocateTarget(_:rows:hostLocates:)``) and the host's handle
/// (``FlareMessageListController/scrollToMessage(_:)``) both ask it, so they can never disagree about
/// whether the list has a message.
struct MessageRowIndex {
    private let rowIds: [String: String]

    init(_ messages: [FlareMessageData] = []) {
        var ids: [String: String] = [:]
        ids.reserveCapacity(messages.count * 2)
        // Core ids first, then row ids: a row is always reachable under its own key, even where another
        // row carries that string as its core id.
        for message in messages {
            guard let serverId = message.serverId?.flareTrimmed, !serverId.isEmpty else { continue }
            ids[serverId] = message.id
        }
        for message in messages where !message.id.isEmpty { ids[message.id] = message.id }
        rowIds = ids
    }

    /// The id the list draws the message `id` names under, or nil when no drawn row is that message.
    /// A blank id names nothing.
    func rowId(for id: String) -> String? {
        let wanted = id.flareTrimmed
        guard !wanted.isEmpty else { return nil }
        return rowIds[wanted]
    }
}

private extension String {
    /// Ids come from a host's own data: a blank one, or one padded by a copy-paste, names nothing.
    var flareTrimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

/// The handle a host keeps to ask ``MessageListView`` to show a message.
///
/// The host owns one (`@StateObject private var listController = FlareMessageListController()`) and hands
/// it to the list (`MessageListView(… controller: listController)`). ``scrollToMessage(_:)`` answers
/// whether the list had that message, so a host that paged history in for a quoted message can tell
/// "it is on screen now" from "it is not in this conversation's history" without asking the user to tap
/// again. Vue exposes the same method on the component instance; Flutter and Compose take the same
/// handle (Compose spells it `state`).
///
/// It is an entrance to the list's own locate path, not a second scroll: the row is centred, Reduce
/// Motion is honoured, and the list stops following the newest message — exactly as a tap on a quote
/// whose message is loaded already does.
public final class FlareMessageListController: ObservableObject {
    /// The rows the attached list last drew, by both ids each of them answers to, refreshed every time
    /// the list's body is evaluated. Deliberately not `@Published`: the handle carries what the list
    /// drew, it draws nothing itself, so recording rows must never invalidate a view.
    private var rows = MessageRowIndex()
    /// The attached list's way into its own locate path, and which list attached it. Nil before any
    /// list takes this controller, and again once that list goes away.
    private var scroll: ((String) -> Void)?
    private var attachment: UUID?

    public init() {}

    /// Asks the list to show the message with `id`, and says whether the list had it.
    ///
    /// `id` may be either of the ids that message answers to — the id the list draws it under, or the
    /// id the core names it by (``FlareMessageData/serverId``) — so a host hands over what it has,
    /// ``FlareReplyTarget/messageId`` included, without translating anything.
    ///
    /// True: the list is drawing that message, and scrolled it into view (centred).
    /// False: nothing moved — the list is not drawing that message, or no list is attached, which is
    /// what a host sees when it calls this before the list is mounted or after it went away. A blank
    /// id is always false.
    @discardableResult
    public func scrollToMessage(_ id: String) -> Bool {
        guard let rowId = rows.rowId(for: id), let scroll else { return false }
        scroll(rowId)
        return true
    }

    /// The list records the rows it is drawing and its way in. Called on every body evaluation, so the
    /// answer is never stale by a frame; the token is the list's identity, so a list that goes away
    /// after another one took the handle cannot clear the live attachment.
    func attach(_ token: UUID, rows: MessageRowIndex, scroll: @escaping (String) -> Void) {
        attachment = token
        self.rows = rows
        self.scroll = scroll
    }

    /// The list went away: the handle answers false until a list attaches again.
    func detach(_ token: UUID) {
        guard attachment == token else { return }
        attachment = nil
        rows = MessageRowIndex()
        scroll = nil
    }
}
