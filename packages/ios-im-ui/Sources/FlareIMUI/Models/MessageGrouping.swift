import Foundation

// Message runs, row presentation and date pills (docs/design/message-surface-and-meta.md C4). Pure rules, run
// against spec/message-grouping-vectors.json by all four kits. A run is one sender within five minutes; centred rows
// (system, recall, delete), a switch between card and the other surfaces, date pills and the unread divider break it.

public enum MessageGroupPosition: String, Sendable { case single, first, middle, last }
public enum MessageAvatarPlacement: String, Sendable { case leading, trailing }

public struct MessageRowPresentation: Equatable, Sendable {
    public let showAvatar: Bool
    public let reserveAvatarSpace: Bool
    public let showSenderName: Bool
    public let avatarPlacement: MessageAvatarPlacement
    /// Draw the bubble tail: a bubble surface ending its run. Bare media and cards never draw one.
    public let tail: Bool

    public init(
        showAvatar: Bool = false,
        reserveAvatarSpace: Bool = false,
        showSenderName: Bool = false,
        avatarPlacement: MessageAvatarPlacement = .leading,
        tail: Bool = true
    ) {
        self.showAvatar = showAvatar; self.reserveAvatarSpace = reserveAvatarSpace
        self.showSenderName = showSenderName; self.avatarPlacement = avatarPlacement; self.tail = tail
    }
}

/// The gap that still keeps two messages of one sender in one run.
public let flareMessageGroupGapMs: Int64 = 300_000

/// What grouping reads of a message. A missing time (0) joins its neighbours, as an unsent draft does.
public struct FlareMessageGroupingItem: Equatable, Sendable {
    public let id: String
    public let senderId: String
    public let atMs: Int64
    public let surface: FlareMessageSurface
    public init(id: String, senderId: String, atMs: Int64, surface: FlareMessageSurface) {
        self.id = id; self.senderId = senderId; self.atMs = atMs; self.surface = surface
    }
}

/// The presentation options a timeline passes down (the list's `show*` parameters).
public struct FlareMessageGroupingOptions: Equatable, Sendable {
    public var timeGapMs: Int64
    public var showIncomingAvatar: Bool
    public var showSelfAvatar: Bool
    public var showGroupSenderName: Bool
    public init(timeGapMs: Int64 = flareMessageGroupGapMs, showIncomingAvatar: Bool = true,
                showSelfAvatar: Bool = false, showGroupSenderName: Bool = true) {
        self.timeGapMs = timeGapMs; self.showIncomingAvatar = showIncomingAvatar
        self.showSelfAvatar = showSelfAvatar; self.showGroupSenderName = showGroupSenderName
    }
}

public extension FlareMessageData {
    /// This row as grouping reads it, on `surface`.
    func groupingItem(surface: FlareMessageSurface) -> FlareMessageGroupingItem {
        FlareMessageGroupingItem(id: id, senderId: senderId, atMs: sentAtMs, surface: surface)
    }
}

/// Whether two neighbouring messages share a run (vectors rules.shareGroup): the same non-empty sender, at most
/// `timeGapMs` apart, neither centred, and both cards or neither.
public func messagesShareGroup(_ previous: FlareMessageGroupingItem?, _ current: FlareMessageGroupingItem?,
                               timeGapMs: Int64 = flareMessageGroupGapMs) -> Bool {
    guard let previous, let current else { return false }
    if previous.surface == .centered || current.surface == .centered { return false }
    if (previous.surface == .card) != (current.surface == .card) { return false }
    let sender = previous.senderId.trimmingCharacters(in: .whitespaces)
    guard !sender.isEmpty, sender == current.senderId.trimmingCharacters(in: .whitespaces) else { return false }
    guard previous.atMs > 0, current.atMs > 0 else { return true }
    return abs(current.atMs - previous.atMs) <= timeGapMs
}

/// The position of `items[index]` in its sender run; centred rows are always single.
public func messageGroupPosition(_ items: [FlareMessageGroupingItem], index: Int,
                                 timeGapMs: Int64 = flareMessageGroupGapMs) -> MessageGroupPosition {
    let current = items[index]
    if current.surface == .centered { return .single }
    let previous = index > 0 ? items[index - 1] : nil
    let next = index + 1 < items.count ? items[index + 1] : nil
    let joinsPrevious = messagesShareGroup(previous, current, timeGapMs: timeGapMs)
    let joinsNext = messagesShareGroup(current, next, timeGapMs: timeGapMs)
    if !joinsPrevious && !joinsNext { return .single }
    if !joinsPrevious { return .first }
    if !joinsNext { return .last }
    return .middle
}

/// The same over messages, each on the surface the kit gives it without host registrations.
public func messageGroupPosition(_ messages: [FlareMessageData], index: Int,
                                 timeGapMs: Int64 = flareMessageGroupGapMs) -> MessageGroupPosition {
    messageGroupPosition(messages.map { $0.groupingItem(surface: $0.surface()) }, index: index, timeGapMs: timeGapMs)
}

/// A row's avatar, name and tail (vectors rules.presentation / tail). Incoming rows show the avatar and, in groups,
/// the name on the first of a run; the viewer's rows sit trailing without either unless `showSelfAvatar`. Centred
/// rows have no avatar, name, gutter or tail; only a bubble ending its run draws a tail.
public func messageRowPresentation(senderId: String, surface: FlareMessageSurface, position: MessageGroupPosition,
                                   currentUserId: String, groupConversation: Bool,
                                   options: FlareMessageGroupingOptions = FlareMessageGroupingOptions()) -> MessageRowPresentation {
    let own = senderId == currentUserId
    let placement: MessageAvatarPlacement = own ? .trailing : .leading
    if surface == .centered {
        return MessageRowPresentation(showAvatar: false, reserveAvatarSpace: false, showSenderName: false,
                                      avatarPlacement: placement, tail: false)
    }
    let edge = position == .single || position == .first
    let avatarOn = own ? options.showSelfAvatar : options.showIncomingAvatar
    return MessageRowPresentation(
        showAvatar: avatarOn && edge,
        reserveAvatarSpace: avatarOn,
        showSenderName: !own && groupConversation && options.showGroupSenderName && edge,
        avatarPlacement: placement,
        tail: surface == .bubble && (position == .single || position == .last)
    )
}

public func messageRowPresentation(
    message: FlareMessageData,
    position: MessageGroupPosition,
    currentUserId: String,
    groupConversation: Bool,
    showIncomingAvatar: Bool = true,
    showSelfAvatar: Bool = false,
    showGroupSenderName: Bool = true,
    surface: FlareMessageSurface? = nil
) -> MessageRowPresentation {
    messageRowPresentation(
        senderId: message.senderId, surface: surface ?? message.surface(), position: position,
        currentUserId: currentUserId, groupConversation: groupConversation,
        options: FlareMessageGroupingOptions(showIncomingAvatar: showIncomingAvatar, showSelfAvatar: showSelfAvatar,
                                             showGroupSenderName: showGroupSenderName))
}

// MARK: - Timeline rows

/// Which tier a date pill reads (vectors rules.datePill).
public enum FlareTimelineDateLabel: String, Sendable {
    case today, yesterday, monthDay, yearMonthDay
}

/// One row of the timeline, in the order the list draws them.
public enum FlareTimelineRow: Equatable, Sendable {
    /// A date pill for the local day of the message at `atMs`.
    case date(atMs: Int64, label: FlareTimelineDateLabel)
    /// The unread divider with the count of the others' messages from it on.
    case unread(count: Int)
    case message(index: Int, position: MessageGroupPosition, presentation: MessageRowPresentation)
}

/// The local calendar day of an instant, as a day number: the zone's, or a fixed offset (tests pin one).
func flareLocalDay(_ ms: Int64, timeZone: TimeZone, utcOffsetMinutes: Int? = nil) -> Int {
    let seconds = TimeInterval(ms) / 1000
    let offset = utcOffsetMinutes.map { TimeInterval($0 * 60) }
        ?? TimeInterval(timeZone.secondsFromGMT(for: Date(timeIntervalSince1970: seconds)))
    return Int(((seconds + offset) / 86_400).rounded(.down))
}

private func flareLocalYear(_ ms: Int64, timeZone: TimeZone, utcOffsetMinutes: Int?) -> Int {
    var calendar = Calendar(identifier: .gregorian)
    let date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000)
    calendar.timeZone = utcOffsetMinutes.flatMap { TimeZone(secondsFromGMT: $0 * 60) } ?? timeZone
    return calendar.component(.year, from: date)
}

/// The date pill tier of `atMs` against `nowMs`: today, yesterday, then month and day within now's year, and the
/// year with them before it.
public func flareTimelineDateLabel(atMs: Int64, nowMs: Int64, timeZone: TimeZone = .current,
                                   utcOffsetMinutes: Int? = nil) -> FlareTimelineDateLabel {
    let day = flareLocalDay(atMs, timeZone: timeZone, utcOffsetMinutes: utcOffsetMinutes)
    let today = flareLocalDay(nowMs, timeZone: timeZone, utcOffsetMinutes: utcOffsetMinutes)
    if day == today { return .today }
    if day == today - 1 { return .yesterday }
    return flareLocalYear(atMs, timeZone: timeZone, utcOffsetMinutes: utcOffsetMinutes)
        == flareLocalYear(nowMs, timeZone: timeZone, utcOffsetMinutes: utcOffsetMinutes) ? .monthDay : .yearMonthDay
}

/// The timeline's rows: a date pill before the first dated message and at each new local day (undated rows neither
/// start nor reset a day), the unread divider right before `unreadFromId` (after that day's pill) counting the
/// others' messages from it on, and each message with its run position and presentation — a pill or the divider
/// ends the run before it and opens a new one after it.
public func flareTimelineRows(_ items: [FlareMessageGroupingItem], currentUserId: String,
                              conversationKind: FlareConversationKind, unreadFromId: String? = nil,
                              options: FlareMessageGroupingOptions = FlareMessageGroupingOptions(),
                              nowMs: Int64? = nil, timeZone: TimeZone = .current,
                              utcOffsetMinutes: Int? = nil) -> [FlareTimelineRow] {
    let now = nowMs ?? Int64((Date().timeIntervalSince1970 * 1000).rounded(.down))
    let unreadIndex = unreadFromId.flatMap { id in id.isEmpty ? nil : items.firstIndex { $0.id == id } }
    var startsDay: [Bool] = []
    var previousDay: Int?
    for item in items {
        guard item.atMs > 0 else { startsDay.append(false); continue }
        let day = flareLocalDay(item.atMs, timeZone: timeZone, utcOffsetMinutes: utcOffsetMinutes)
        startsDay.append(previousDay != day)
        previousDay = day
    }
    func dividerBefore(_ index: Int) -> Bool { index == unreadIndex || startsDay[index] }
    var rows: [FlareTimelineRow] = []
    for (index, item) in items.enumerated() {
        if startsDay[index] {
            rows.append(.date(atMs: item.atMs, label: flareTimelineDateLabel(
                atMs: item.atMs, nowMs: now, timeZone: timeZone, utcOffsetMinutes: utcOffsetMinutes)))
        }
        if index == unreadIndex {
            rows.append(.unread(count: items[index...].filter { $0.senderId != currentUserId }.count))
        }
        var position = messageGroupPosition(items, index: index, timeGapMs: options.timeGapMs)
        if index > 0, dividerBefore(index) {
            position = position == .middle ? .first : position == .last ? .single : position
        }
        if index + 1 < items.count, dividerBefore(index + 1) {
            position = position == .middle ? .last : position == .first ? .single : position
        }
        rows.append(.message(index: index, position: position, presentation: messageRowPresentation(
            senderId: item.senderId, surface: item.surface, position: position, currentUserId: currentUserId,
            groupConversation: conversationKind == .group, options: options)))
    }
    return rows
}
