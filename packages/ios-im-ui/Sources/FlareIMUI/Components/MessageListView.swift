#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

/// The message thread — grouping, media state, load-older. Spec:
/// Message/MessageList (`MessageListView`). Uses a lazy stack (O(visible));
/// order is oldest→newest. The host feeds `messages` from the timeline view.
///
/// The list opens at the newest message, at the bottom. Messages added at the end keep a reader who is at the
/// bottom there, and bring the reader down when one of them is the reader's own; a reader who scrolled up stays
/// where they are and gets ``ScrollToLatestView`` with the count of the messages below. Older messages added
/// above keep the visible message in place, and a viewport that resizes keeps a reader at the bottom there
/// (``TimelineFollow``, the Vue list's rules). Jumps are not animated.
public struct MessageListView: View {
    private let hasOlder: Bool
    private let olderError: String?
    private let loadOlderText: String?
    private let onLoadOlder: (() -> Void)?
    private let conversationId: String?
    @State private var requested = false
    /// The bottom-most visible row (iOS 17 and later): the reading position the scroll view keeps when rows are
    /// added above it.
    @State private var visibleId: String?
    @State private var rowFrames: [String: CGRect] = [:]
    @State private var restorationGeneration = 0
    @State private var coordinateSpace = UUID()
    /// The quoted row a quote tap asked for; each tap bumps the generation, so a repeated
    /// tap on the same quote scrolls again.
    @State private var locatedId: String?
    @State private var locateMark: FlareLocateMark = .none
    /// Where VoiceOver is reading. Moving it is accessibility-only on this platform — it changes
    /// nothing about keyboard focus — so a jump can take the reader to the row it landed on.
    @AccessibilityFocusState private var readingCursor: String?
    @State private var locateGeneration = 0
    /// This list's identity on the host's handle: a list that goes away only lets go of an attachment
    /// it still owns.
    @State private var controllerToken = UUID()
    /// Where the reader is, and whether new messages bring the list down.
    @State private var follow = TimelineFollow()
    /// The message ids the timeline last drew, to tell messages added at the end from older ones added above.
    @State private var timelineIds: [String] = []
    /// Bumped to go to the newest message.
    @State private var jumpGeneration = 0
    /// The bottom-most visible row on the iOS 16 path, where the system reports one: read, never written.
    @State private var legacyVisibleId: String?
    @Environment(\.flareLegacyTimelineScrolling) private var legacyTimelineScrolling
    @Environment(\.flareTimelineBelowCountObserver) private var timelineBelowCountObserver
    private let messages: [FlareMessageData]
    private let currentUserId: String
    private let conversationKind: FlareConversationKind
    private let loading: Bool
    private let loadingOlder: Bool
    private let emptyText: String?
    /// Replaces the whole empty state, for a timeline that is empty for a reason only the host
    /// knows — a filter, a first conversation, a chat nobody has written in yet. `emptyText`
    /// stays the shorthand for changing only the line.
    private let empty: AnyView?
    private let mediaDownloadStates: [String: FlareMediaDownloadState]
    private let onMessageLongPress: ((FlareMessageData) -> Void)?
    private let onMediaAction: ((FlareMessageData, FlareMessageContent) -> Void)?
    private let onMediaDownload: ((FlareMessageData, FlareMessageContent) -> Void)?
    private let onOpenFile: ((FlareMessageData, FlareFileContent) -> Void)?
    private let onOpenLink: ((FlareMessageData, String) -> Void)?
    private let onVote: ((FlareMessageData, Int) -> Void)?
    private let onTaskToggle: ((FlareMessageData, Bool) -> Void)?
    private let onResend: ((FlareMessageData) -> Void)?
    private let multiSelectMode: Bool
    private let selectedIds: Set<String>
    private let onToggleSelect: ((String) -> Void)?
    private let onSwipeReply: ((FlareMessageData) -> Void)?
    private let showIncomingAvatar: Bool
    private let showSelfAvatar: Bool
    private let showGroupSenderName: Bool
    private let onReact: ((FlareMessageData, String) -> Void)?
    private let onLocateMessage: ((String) -> Void)?
    private let unreadFromId: String?
    private let footer: AnyView?
    private let controller: FlareMessageListController?
    /// The timeline's media defaults: the full-screen viewer and one voice message at a time.
    @StateObject private var mediaSession = FlareMediaSession()

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale

    /// - Parameters:
    ///   - onMediaAction: Takes every media tap. Without it the list opens images and videos in the
    ///     kit's full-screen viewer and plays voice messages in their bubbles, one at a time, stopping
    ///     when the list goes away. Files, locations and links always go to the host.
    ///   - onMediaDownload: Offered as the download key of the kit's image preview; without it the
    ///     preview has no download key. A tapped picture opens the conversation's gallery, every picture of
    ///     `messages` in timeline order, and each one's key downloads that picture.
    ///   - onOpenFile: A file tap when there is no `onMediaAction`: the host opens the file (after
    ///     ``safeExternalURL(_:)`` for a remote one), and images, videos and voice keep the kit defaults.
    ///   - onOpenLink: A tapped link, in a text body or on a link card, with its raw URL. Without it the
    ///     timeline opens a web address after ``safeExternalURL(_:)`` and opens nothing else.
    ///   - onVote: A tapped poll option (message, option index). Without it polls are read-only.
    ///   - onTaskToggle: A tapped task checkbox (message, the done state asked for). Without it tasks
    ///     are read-only.
    ///   - multiSelectMode: Batch-selection mode (same name as Flutter/Compose).
    ///     Rows show a check control, row taps toggle, long-press is suspended.
    ///   - selectedIds: The host-owned selection; rows whose id is contained render selected.
    ///   - onToggleSelect: Called with the tapped message id in multi-select mode.
    ///   - onReact: Reaction pill tap (toggle the current user's reaction); without it
    ///     the pills are display-only.
    ///   - onLocateMessage: A reply quote whose message is not in `messages` asks the host
    ///     for it with this id (the host may load older messages). A quoted message the list
    ///     holds is scrolled into view without asking.
    ///   - unreadFromId: Id of the first unread message. The list draws ``UnreadDividerView`` above
    ///     it (below that day's date separator), counting the messages from others from there on, and
    ///     starts a new sender run at it (as at every date separator). Keep it fixed while the
    ///     conversation stays open.
    ///   - controller: A handle the host keeps to ask this list to show a message —
    ///     ``FlareMessageListController/scrollToMessage(_:)``, which answers whether the list had it.
    ///     It is the same locate path a quote tap takes, so the host that paged a quoted message in
    ///     can finish the jump instead of asking for a second tap.
    public init(
        messages: [FlareMessageData],
        currentUserId: String,
        conversationKind: FlareConversationKind = .single,
        loading: Bool = false,
        loadingOlder: Bool = false,
        emptyText: String? = nil,
        empty: AnyView? = nil,
        mediaDownloadStates: [String: FlareMediaDownloadState] = [:],
        onMessageLongPress: ((FlareMessageData) -> Void)? = nil,
        onMediaAction: ((FlareMessageData, FlareMessageContent) -> Void)? = nil,
        onMediaDownload: ((FlareMessageData, FlareMessageContent) -> Void)? = nil,
        onOpenFile: ((FlareMessageData, FlareFileContent) -> Void)? = nil,
        onOpenLink: ((FlareMessageData, String) -> Void)? = nil,
        onVote: ((FlareMessageData, Int) -> Void)? = nil,
        onTaskToggle: ((FlareMessageData, Bool) -> Void)? = nil,
        onResend: ((FlareMessageData) -> Void)? = nil,
        hasOlder: Bool = false, olderError: String? = nil, loadOlderText: String? = nil,
        onLoadOlder: (() -> Void)? = nil, conversationId: String? = nil,
        multiSelectMode: Bool = false,
        selectedIds: Set<String> = [],
        onToggleSelect: ((String) -> Void)? = nil,
        onSwipeReply: ((FlareMessageData) -> Void)? = nil,
        showIncomingAvatar: Bool = true,
        showSelfAvatar: Bool = false,
        showGroupSenderName: Bool = true,
        onReact: ((FlareMessageData, String) -> Void)? = nil,
        onLocateMessage: ((String) -> Void)? = nil,
        unreadFromId: String? = nil,
        controller: FlareMessageListController? = nil,
        /// Host content under the newest message, scrolling with the timeline — the contract's `footer`
        /// slot, as on Vue (`AnyView`, as the kit's other slots take: `ContactItemView.trailing`). The
        /// typing indicator lives here: it belongs to the conversation, not to the composer, and a reader
        /// scrolled up must not be told someone is typing at a row they are not looking at.
        footer: AnyView? = nil
    ) {
        self.hasOlder = hasOlder; self.olderError = olderError; self.loadOlderText = loadOlderText
        self.onLoadOlder = onLoadOlder; self.conversationId = conversationId
        self.messages = messages
        self.currentUserId = currentUserId
        self.conversationKind = conversationKind
        self.loading = loading
        self.loadingOlder = loadingOlder
        self.emptyText = emptyText
        self.empty = empty
        self.mediaDownloadStates = mediaDownloadStates
        self.onMessageLongPress = onMessageLongPress
        self.onMediaAction = onMediaAction
        self.onMediaDownload = onMediaDownload
        self.onOpenFile = onOpenFile
        self.onOpenLink = onOpenLink
        self.onVote = onVote
        self.onTaskToggle = onTaskToggle
        self.onResend = onResend
        self.multiSelectMode = multiSelectMode
        self.selectedIds = selectedIds
        self.onToggleSelect = onToggleSelect
        self.onSwipeReply = onSwipeReply
        self.showIncomingAvatar = showIncomingAvatar
        self.showSelfAvatar = showSelfAvatar
        self.showGroupSenderName = showGroupSenderName
        self.onReact = onReact
        self.onLocateMessage = onLocateMessage
        self.unreadFromId = unreadFromId
        self.controller = controller
        self.footer = footer
    }

    /// Long-press opens the message action sheet only outside multi-select mode
    /// (Flutter parity: `onLongPress: multiSelectMode ? null : ...`).
    static func longPressEnabled(multiSelectMode: Bool, onMessageLongPress: ((FlareMessageData) -> Void)?) -> Bool {
        !multiSelectMode && onMessageLongPress != nil
    }

    /// Notices (system lines, recalled messages) carry no message actions:
    /// no long-press menu, no swipe-to-reply.
    static func isActionable(_ message: FlareMessageData) -> Bool {
        !message.isSystem && !message.isRecalled
    }

    /// Per-row selected flag derived from the host's id set.
    static func isSelected(_ id: String, multiSelectMode: Bool, selectedIds: Set<String>) -> Bool {
        multiSelectMode && selectedIds.contains(id)
    }

    /// Where a row's quote tap goes.
    enum QuoteLocateTarget: Equatable {
        /// The quoted message is loaded: scroll its row into view; the host is not asked.
        case row(String)
        /// The quoted message is not loaded: ask the host's `onLocateMessage`.
        case host(String)
    }

    /// The quote tap for `message`: nil — a plain quote — when it quotes no message id, or
    /// when that message is not loaded and the host cannot locate it.
    ///
    /// The quote names its original by the core's id (``FlareReplyTarget/messageId``), which is the
    /// row's own id for most messages and not for one this device sent: ``MessageRowIndex`` answers
    /// for both, and answers with the row id, so `.row` is always a row the list can scroll to and
    /// `.host` is only ever a message the list really does not have.
    static func quoteLocateTarget(_ message: FlareMessageData, rows: MessageRowIndex,
                                  hostLocates: Bool) -> QuoteLocateTarget? {
        guard let id = MessageBubbleView.quote(message)?.messageId,
              !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        if let rowId = rows.rowId(for: id) { return .row(rowId) }
        return hostLocates ? .host(id) : nil
    }

    /// A timeline row, in the order the list draws them (Vue `timelineRows`).
    enum TimelineEntry: Equatable {
        /// A date separator for the day of the message sent at this time.
        case date(sentAtMs: Int64)
        /// The unread divider with the count of messages from others from there on.
        case unread(count: Int)
        case message(id: String, position: MessageGroupPosition)
    }

    /// Every row of the timeline, as the list draws them: before a message, the date separator when it
    /// starts a local day, then the unread divider when it is the first unread message.
    static func timelineEntries(_ messages: [FlareMessageData], unreadFromId: String?, currentUserId: String,
                                timeZone: TimeZone = .current) -> [TimelineEntry] {
        let unread = unreadIndex(messages, unreadFromId: unreadFromId)
        var entries: [TimelineEntry] = []
        for index in messages.indices {
            if startsTimelineDay(messages, at: index, timeZone: timeZone) {
                entries.append(.date(sentAtMs: messages[index].sentAtMs))
            }
            if index == unread {
                entries.append(.unread(count: unreadCount(messages, from: index, currentUserId: currentUserId)))
            }
            entries.append(.message(id: messages[index].id,
                                    position: groupPosition(messages, at: index, unreadIndex: unread, timeZone: timeZone)))
        }
        return entries
    }

    /// Whether the message at `index` starts a local day: the first dated message, or the first one on
    /// another day than the dated message before it (undated rows are skipped, as on Vue).
    static func startsTimelineDay(_ messages: [FlareMessageData], at index: Int, timeZone: TimeZone) -> Bool {
        var previous = index - 1
        while previous >= 0, messages[previous].sentAtMs <= 0 { previous -= 1 }
        return FlareTimeFormat.startsTimelineDay(previousMs: previous >= 0 ? messages[previous].sentAtMs : 0,
                                                 currentMs: messages[index].sentAtMs, timeZone: timeZone)
    }

    /// Index of the first unread message; nil without an id or when the list does not hold it.
    static func unreadIndex(_ messages: [FlareMessageData], unreadFromId: String?) -> Int? {
        guard let unreadFromId, !unreadFromId.isEmpty else { return nil }
        return messages.firstIndex { $0.id == unreadFromId }
    }

    /// The unread divider's count: messages from others from `index` on.
    static func unreadCount(_ messages: [FlareMessageData], from index: Int, currentUserId: String) -> Int {
        messages[index...].reduce(0) { $0 + ($1.senderId == currentUserId ? 0 : 1) }
    }

    /// The sender-run position, with every divider ending a run (Vue `breakRunAtDividers`): a date
    /// separator or the unread divider right above a row opens a new run there, and one right above the
    /// next row closes the run. A run never continues across a date separator.
    static func groupPosition(_ messages: [FlareMessageData], at index: Int, unreadIndex: Int?,
                              timeZone: TimeZone) -> MessageGroupPosition {
        var position = messageGroupPosition(messages, index: index)
        if dividerAbove(messages, at: index, unreadIndex: unreadIndex, timeZone: timeZone) {
            position = position == .middle ? .first : position == .last ? .single : position
        }
        if index + 1 < messages.count, dividerAbove(messages, at: index + 1, unreadIndex: unreadIndex, timeZone: timeZone) {
            position = position == .middle ? .last : position == .first ? .single : position
        }
        return position
    }

    /// Whether a divider sits right above the message at `index`: the unread divider, or a date separator
    /// on any row but the first (the first row's separator opens the timeline, not a new run).
    static func dividerAbove(_ messages: [FlareMessageData], at index: Int, unreadIndex: Int?, timeZone: TimeZone) -> Bool {
        index == unreadIndex || (index > 0 && startsTimelineDay(messages, at: index, timeZone: timeZone))
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        // The host's handle learns the rows this pass draws before the pass draws them, so
        // `scrollToMessage` never answers from the previous set of messages.
        let _ = attachController()
        // 量一次窗格宽,经环境值下发给每一行 —— 气泡最大宽 = 可用宽 × 比例,再被
        // layout.bubbleMaxWidth 封顶,与另外三端同一条规则。
        GeometryReader { proxy in
            timelineBody(colors)
                .environment(\.flareBubbleMaxWidth, flareBubbleMaxWidth(paneWidth: proxy.size.width))
        }
    }

    @ViewBuilder
    private func timelineBody(_ colors: FlareColors) -> some View {
        VStack(spacing: 0) {
            if let olderError { Text(olderError).foregroundColor(colors.textPrimary).padding(.horizontal, 12) }
            if loadingOlder { ProgressView().frame(minHeight: 48) }
            else if hasOlder, let onLoadOlder {
                Button { if !requested { requested = true; onLoadOlder() } } label: {
                    Text(loadOlderText ?? strings.messageListLoadOlder).frame(minWidth: 48, minHeight: 48)
                }.disabled(requested)
            }
            if messages.isEmpty {
                Group {
                    if loading { ProgressView() }
                    else if let empty { empty }
                    else { Text(emptyText ?? strings.messageListEmpty).font(.body).foregroundColor(colors.textTertiary) }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                timeline.id(conversationId)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(colors.bgSecondary)
            .onChange(of: loadingOlder) { if !$0 { requested = false } }
            .onChange(of: messages.first?.id) { _ in requested = false }
            .onChange(of: olderError) { _ in requested = false }
            .onChange(of: conversationId) { _ in
                requested = false; visibleId = nil; rowFrames = [:]; restorationGeneration += 1; locatedId = nil
                follow = TimelineFollow()
                mediaSession.voice.stop()
            }
            // A list that comes back without its body being evaluated again takes the handle back;
            // a list that goes away lets go of it, so the handle answers false instead of writing to
            // a view that is no longer there.
            .onAppear { attachController() }
            .onDisappear { controller?.detach(controllerToken) }
            // The mark the located row wears (`spec/locate-highlight-vectors.json`). Keyed on the locate
            // generation, so a second jump inside the window cancels the first window instead of adding a
            // second marked row — and the row that was marked stops being marked the moment the new one is.
            .task(id: locateGeneration) {
                guard locateGeneration > 0, let id = locatedId else { return }
                announceLocated(id)
                // And take the reader there: the ring is for the people who can see it, this is the same
                // fact for the people who cannot. A row the list is not drawing takes no cursor, and the
                // announcement is then the whole answer.
                readingCursor = messages.first(where: { $0.id == id || $0.serverId == id })?.id
                locateMark = FlareLocateMark(messageId: id, startedAt: Date())
                try? await Task.sleep(nanoseconds: UInt64(FlareLocateHighlight.durationMs) * 1_000_000)
                guard !Task.isCancelled else { return }
                locateMark = .none
            }
            .environment(\.flareLocateMark, locateMark)
            .flareMediaDefaults(mediaSession)
    }

    /// Hands the host's handle the rows this list is drawing and its way into the locate path — the
    /// one a tap on a loaded quote takes. The two state wrappers are captured rather than the view,
    /// so a handle the host holds does not hold the host back.
    private func attachController() {
        guard let controller else { return }
        let located = _locatedId
        let generation = _locateGeneration
        controller.attach(controllerToken, rows: MessageRowIndex(messages)) { id in
            located.wrappedValue = id
            generation.wrappedValue += 1
        }
    }

    /// The id of the empty row after the newest message: the end of the timeline.
    static let timelineEndId = "flare-timeline-end"

    @ViewBuilder private var timeline: some View {
        // What the follow rules read from the messages; the change handlers get it as their new value, because
        // their closures still see the previous messages.
        let followRows = messages.map { TimelineFollow.Row(id: $0.id, own: $0.senderId == currentUserId) }
        GeometryReader { viewport in
            if #available(iOS 17.0, macOS 14.0, *), !legacyTimelineScrolling {
                ScrollViewReader { proxy in
                    ScrollView { rows(reportsRowFrames: false, viewportHeight: viewport.size.height) }
                        // The bottom-most visible row is the reading position: rows added above keep it in place.
                        .scrollPosition(id: $visibleId, anchor: .bottom)
                        // Opens at the newest message, and keeps a reader at the bottom there while the content or
                        // the viewport grows.
                        .defaultScrollAnchor(.bottom)
                        .coordinateSpace(name: coordinateSpace)
                        .onAppear { timelineIds = followRows.map(\.id) }
                        // Where the reader is, from the scroll view's own position: the bottom-most
                        // visible row. A geometry preference inside the content only tells the list
                        // where the end was when the content was last laid out, which is not where the
                        // reader went (a macOS scroll never lays the content out again).
                        .onChange(of: visibleId) { id in syncAnchor(id) }
                        .onChange(of: followRows) { rows in
                            if rowsChanged(rows) { goToLatest(tailId: rows.last?.id) }
                        }
                        .onChange(of: jumpGeneration) { _ in goToLatest(tailId: timelineIds.last) }
                        .onChange(of: viewport.size.height) { _ in
                            if follow.followTail || follow.atBottom { goToLatest(tailId: timelineIds.last) }
                        }
                        .onChange(of: locateGeneration) { _ in
                            // A row scrolled to by the proxy is not the bound position; a stale one would pull the
                            // list back to it when the content next changes.
                            visibleId = nil
                            DispatchQueue.main.async { scrollToLocated(proxy) }
                        }
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView { rows(reportsRowFrames: true, viewportHeight: viewport.size.height) }
                        .coordinateSpace(name: coordinateSpace)
                        // The position this path scrolls with is the proxy (iOS 16 has no bound
                        // position), but where the reader *is* comes from the scroll view itself
                        // wherever the system reports it — the row frames below are recomputed only
                        // when the content is laid out again, which scrolling does not do.
                        .modifier(BottomVisibleRow(id: $legacyVisibleId))
                        .onChange(of: legacyVisibleId) { id in syncAnchor(id) }
                        .onAppear {
                            timelineIds = followRows.map(\.id)
                            scrollToEnd(proxy, tailId: followRows.last?.id)
                        }
                        .onChange(of: locateGeneration) { _ in
                            // Match the modern path: let this update finish before asking the
                            // proxy to move. In the legacy path an onAppear/end-restoration scroll
                            // can otherwise run later in the same pass and pull the reader back.
                            DispatchQueue.main.async { scrollToLocated(proxy) }
                        }
                        .onPreferenceChange(TimelineRowFrames.self) { rowFrames = $0 }
                        .onPreferenceChange(TimelineEnd.self) { syncPosition($0) }
                        .onChange(of: jumpGeneration) { _ in scrollToEnd(proxy, tailId: timelineIds.last) }
                        .onChange(of: viewport.size.height) { _ in
                            if follow.followTail || follow.atBottom { scrollToEnd(proxy, tailId: timelineIds.last) }
                        }
                        .onChange(of: followRows) { rows in
                            if rowsChanged(rows) {
                                scrollToEnd(proxy, tailId: rows.last?.id)
                                return
                            }
                            let surviving = Set(rows.map(\.id))
                            let anchor = rowFrames.filter { surviving.contains($0.key) && $0.value.maxY > 0 && $0.value.minY < viewport.size.height }
                                .min { $0.value.minY < $1.value.minY }
                            guard let anchor else { return }
                            restorationGeneration += 1
                            let generation = restorationGeneration
                            DispatchQueue.main.async {
                                guard generation == restorationGeneration else { return }
                                let height = rowFrames[anchor.key]?.height ?? anchor.value.height
                                let travel = viewport.size.height - height
                                let fraction = abs(travel) > 1 ? anchor.value.minY / travel : 0
                                proxy.scrollTo(anchor.key, anchor: UnitPoint(x: 0, y: fraction))
                            }
                        }
                }
            }
        }
        .overlay(alignment: .bottomTrailing) { scrollToLatestKey }
        .onChange(of: follow.pendingBelowCount(messages)) { count in timelineBelowCountObserver?(count) }
    }

    /// The scroll-to-latest key while messages arrived below a reader who scrolled up.
    @ViewBuilder private var scrollToLatestKey: some View {
        let below = follow.pendingBelowCount(messages)
        if below > 0 {
            ScrollToLatestView(count: below) { jumpGeneration += 1 }
                .padding(FlareSizes.spacingLg)
        }
    }

    /// The rows changed: records their ids and says whether the list goes to the newest message
    /// (``TimelineFollow/rowsChanged(from:to:)``).
    private func rowsChanged(_ rows: [TimelineFollow.Row]) -> Bool {
        let previous = timelineIds
        timelineIds = rows.map(\.id)
        return follow.rowsChanged(from: previous, to: rows)
    }

    /// The reader's position from the end of the timeline, written only when what it decides changes.
    private func syncPosition(_ end: TimelineEnd.Position?) {
        var next = follow
        next.sync(distanceToBottom: end?.distanceToBottom ?? .infinity, tailId: end?.tailId)
        if next != follow { follow = next }
    }

    /// The reader's position from the bottom-most visible row. Nil is the position the list was put in
    /// and nobody has scrolled away from — it opens at the newest message — so nil decides nothing.
    private func syncAnchor(_ id: String?) {
        guard let id else { return }
        var next = follow
        next.sync(atEnd: id == Self.timelineEndId || id == messages.last?.id, tailId: messages.last?.id)
        if next != follow { follow = next }
    }

    /// Goes to the newest message through the bound position (iOS 17 and later).
    private func goToLatest(tailId: String?) {
        if visibleId != Self.timelineEndId { visibleId = Self.timelineEndId }
        follow.reachedBottom(tailId: tailId)
    }

    /// Goes to the newest message through the proxy (iOS 16), again once the rows have been laid out.
    ///
    /// Twice after this update, not once: a row appended in the same update is laid out after the
    /// first scroll, which then lands a row short of the end, and the row the reader is sent to is the
    /// end of the timeline, so it must be measured before the list can reach it.
    private func scrollToEnd(_ proxy: ScrollViewProxy, tailId: String?) {
        // Where the system keeps a bound position, it restores the row that binding names whenever the
        // content changes — the row before the one just added — and would pull the list back off the
        // end it was just sent to. The two say the same thing here.
        legacyVisibleId = Self.timelineEndId
        proxy.scrollTo(Self.timelineEndId, anchor: .bottom)
        follow.reachedBottom(tailId: tailId)
        let locateAtRequest = locateGeneration
        DispatchQueue.main.async {
            guard locateAtRequest == locateGeneration else { return }
            proxy.scrollTo(Self.timelineEndId, anchor: .bottom)
            DispatchQueue.main.async {
                guard locateAtRequest == locateGeneration else { return }
                proxy.scrollTo(Self.timelineEndId, anchor: .bottom)
            }
        }
    }

    /// What a screen reader is told when a jump lands. The ring tells everyone else; a reader who cannot
    /// see it gets the same fact in words — which row, and what it says — from the one summary a reply
    /// strip would show. A Mac posts nothing: this notification is UIKit's.
    @MainActor
    private func announceLocated(_ id: String) {
        guard let message = messages.first(where: { $0.id == id || $0.serverId == id }) else { return }
        #if canImport(UIKit)
        UIAccessibility.post(
            notification: .announcement,
            argument: flareLocatedAnnouncement(message, strings: strings))
        #endif
    }

    /// Scrolls the located row into view: animated, or at once under Reduce Motion.
    private func scrollToLocated(_ proxy: ScrollViewProxy) {
        guard let locatedId else { return }
        if reduceMotion {
            proxy.scrollTo(locatedId, anchor: .center)
        } else {
            withAnimation(FlareMotion.normalAnimation) { proxy.scrollTo(locatedId, anchor: .center) }
        }
    }

    /// The bubble's quote callback for `message`, routed by ``quoteLocateTarget(_:rows:hostLocates:)``.
    private func locateCallback(_ message: FlareMessageData, rows: MessageRowIndex) -> ((String) -> Void)? {
        switch Self.quoteLocateTarget(message, rows: rows, hostLocates: onLocateMessage != nil) {
        case .row(let id)?:
            return { _ in locatedId = id; locateGeneration += 1 }
        case .host(let id)?:
            return { _ in onLocateMessage?(id) }
        case nil:
            return nil
        }
    }

    private func rows(reportsRowFrames: Bool, viewportHeight: CGFloat) -> some View {
        let rowIndex = MessageRowIndex(messages)
        // One zone, clock and unread position per pass: each row decides its day on numbers, and only a
        // row that starts a day formats a label (with the cached formatter).
        let zone = TimeZone.current
        let now = Date()
        let unread = Self.unreadIndex(messages, unreadFromId: unreadFromId)
        return LazyVStack(spacing: 0) {
            ForEach(Array(messages.enumerated()), id: \.element.id) { index, msg in
                let groupPosition = Self.groupPosition(messages, at: index, unreadIndex: unread, timeZone: zone)
                let presentation = messageRowPresentation(
                    message: msg,
                    position: groupPosition,
                    currentUserId: currentUserId,
                    groupConversation: conversationKind == .group,
                    showIncomingAvatar: showIncomingAvatar,
                    showSelfAvatar: showSelfAvatar,
                    showGroupSenderName: showGroupSenderName)
                let actionable = Self.isActionable(msg)
                VStack(spacing: 0) {
                    // The day comes first, then where the unread messages start inside it.
                    if Self.startsTimelineDay(messages, at: index, timeZone: zone) {
                        DatePillView(label: FlareTimeFormat.timelineDateLabel(
                            Date(timeIntervalSince1970: TimeInterval(msg.sentAtMs) / 1000),
                            today: strings.today, yesterday: strings.yesterday, locale: locale, now: now))
                            .padding(.vertical, FlareSizes.spacingSm)
                            .accessibilityAddTraits(.isHeader)
                    }
                    if index == unread {
                        UnreadDividerView(count: Self.unreadCount(messages, from: index, currentUserId: currentUserId))
                    }
                    MessageBubbleView(message: msg, currentUserId: currentUserId, conversationKind: conversationKind,
                        groupPosition: groupPosition, rowPresentation: presentation, mediaState: mediaDownloadStates[msg.id],
                        onMediaAction: onMediaAction, onMediaDownload: onMediaDownload, onOpenFile: onOpenFile,
                        onOpenLink: onOpenLink, onResend: onResend,
                        multiSelectMode: multiSelectMode,
                        selected: Self.isSelected(msg.id, multiSelectMode: multiSelectMode, selectedIds: selectedIds),
                        onToggleSelect: onToggleSelect,
                        onReact: onReact,
                        onLocateMessage: locateCallback(msg, rows: rowIndex),
                        onVote: onVote, onTaskToggle: onTaskToggle)
                        .mediaDefaults(mediaSession, gallery: FlareImageGallerySource(messages: messages, download: onMediaDownload))
                        .accessibilityFocused($readingCursor, equals: msg.id)
                        .contentShape(Rectangle())
                        .modifier(RowLongPress(enabled: actionable && Self.longPressEnabled(multiSelectMode: multiSelectMode, onMessageLongPress: onMessageLongPress)) {
                            onMessageLongPress?(msg)
                        })
                        .modifier(RowSwipeReply(enabled: actionable && !multiSelectMode && onSwipeReply != nil) {
                            onSwipeReply?(msg)
                        })
                }
                .id(msg.id)
                .background {
                    // Row frames restore the reading position on iOS 16; later systems keep it themselves.
                    if reportsRowFrames {
                        GeometryReader { proxy in
                            Color.clear.preference(key: TimelineRowFrames.self, value: [msg.id: proxy.frame(in: .named(coordinateSpace))])
                        }
                    }
                }
            }
            if let footer { footer }
            // The end of the timeline: how far it is below the viewport says whether the reader is at the newest message.
            Color.clear.frame(height: 1)
                .id(Self.timelineEndId)
                .background(GeometryReader { proxy in
                    Color.clear.preference(key: TimelineEnd.self, value: TimelineEnd.Position(
                        distanceToBottom: proxy.frame(in: .named(coordinateSpace)).minY - viewportHeight,
                        tailId: messages.last?.id))
                })
                .accessibilityHidden(true)
        }
        // Marks the rows as the scroll position's targets, so the scroll view can say which row the
        // reader has at the bottom (``BottomVisibleRow``). Both paths need it: the iOS 16 path scrolls
        // with the proxy but still reads its position from the system where the system has one.
        .modifier(ScrollTargets())
        .frame(maxWidth: FlareSizes.messageTimelineContentMaxWidth)
        .frame(maxWidth: .infinity)
    }
}

/// `scrollTargetLayout()` where the system has it (iOS 17, macOS 14).
private struct ScrollTargets: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            content.scrollTargetLayout()
        } else {
            content
        }
    }
}

/// Where the timeline's end row is: how far below the bottom of the viewport, with the newest message it follows;
/// nil while that row is not laid out.
private struct TimelineEnd: PreferenceKey {
    struct Position: Equatable {
        let distanceToBottom: CGFloat
        let tailId: String?
    }
    static let defaultValue: Position? = nil
    static func reduce(value: inout Position?, nextValue: () -> Position?) { value = nextValue() ?? value }
}

/// Reads the bottom-most visible row from the scroll view, where the system offers it (iOS 17,
/// macOS 14). Older systems keep the row frames the list collects itself.
private struct BottomVisibleRow: ViewModifier {
    @Binding var id: String?
    func body(content: Content) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            content.scrollPosition(id: $id, anchor: .bottom)
        } else {
            content
        }
    }
}

private struct LegacyTimelineScrollingKey: EnvironmentKey {
    static let defaultValue = false
}

/// The width a bubble may take, measured once on the timeline instead of per row.
private struct FlareBubbleMaxWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = FlareSizes.bubbleMaxWidth
}

private struct TimelineBelowCountObserverKey: EnvironmentKey {
    static let defaultValue: ((Int) -> Void)? = nil
}

extension EnvironmentValues {
    /// The widest a message bubble may be: the pane's width times the kit's ratio, capped by
    /// ``FlareSizes/bubbleMaxWidth``. Measured once on the timeline and read by every row —
    /// a `GeometryReader` per row would measure the same number hundreds of times.
    ///
    /// Bubbles had no width limit at all on this platform: a long message ran the full width of
    /// the pane, so on an iPad (or any wide column) it reached edge to edge while the same message
    /// stopped at 62–88% on the other three kits.
    var flareBubbleMaxWidth: CGFloat {
        get { self[FlareBubbleMaxWidthKey.self] }
        set { self[FlareBubbleMaxWidthKey.self] = newValue }
    }

    /// Draws the timeline with the iOS 16 scrolling on a later system, so tests on a current host cover that path.
    var flareLegacyTimelineScrolling: Bool {
        get { self[LegacyTimelineScrollingKey.self] }
        set { self[LegacyTimelineScrollingKey.self] = newValue }
    }

    /// Told the count on the scroll-to-latest key whenever it changes (zero: no key), for tests on a host whose
    /// accessibility tree is not built.
    var flareTimelineBelowCountObserver: ((Int) -> Void)? {
        get { self[TimelineBelowCountObserverKey.self] }
        set { self[TimelineBelowCountObserverKey.self] = newValue }
    }
}

/// A message row that starts a reply when it is dragged towards the trailing edge and let go. The rule
/// lives in ``FlareSwipeReply`` so this kit, Flutter and Compose all arm at the same distance and give way
/// to a vertical scroll in the same place; this modifier only draws it. The gesture is never the only way
/// to reply — the message menu carries the same intent — so it adds no accessibility element of its own.
private struct RowSwipeReply: ViewModifier {
    let enabled: Bool
    let action: () -> Void
    @Environment(\.layoutDirection) private var direction
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var gesture = FlareSwipeReplyGesture.none

    func body(content: Content) -> some View {
        if enabled {
            let colors = FlareColors.of(scheme, brand: flareBrandTheme)
            ZStack(alignment: .leading) {
                Image(systemName: flareIconSymbol("reply"))
                    .font(.system(size: FlareSizes.iconSizeMd))
                    .foregroundColor(colors.textTertiary)
                    // Full strength exactly at the arming distance: the reader sees that one more
                    // millimetre replies before letting go.
                    .opacity(min(1, gesture.travel / FlareSwipeReply.armDistance))
                    .padding(.leading, FlareSizes.spacingMd)
                    .accessibilityHidden(true)
                content
                    .offset(x: direction == .rightToLeft ? -gesture.travel : gesture.travel)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 12)
                    // Following a finger is direct manipulation, not an animation; only the spring back
                    // to rest is animated, and not under Reduce Motion.
                    .onChanged { value in
                        let next = Self.resolve(value, rtl: direction == .rightToLeft)
                        // Crossing the arming distance changes what letting go means, so it is felt as
                        // well as seen.
                        if flareHapticCrossed(was: gesture.armed, now: next.armed) { flareHapticTick() }
                        gesture = next
                    }
                    .onEnded { value in
                        let armed = Self.resolve(value, rtl: direction == .rightToLeft).armed
                        withAnimation(reduceMotion ? nil : FlareMotion.fastAnimation) { gesture = .none }
                        if armed { action() }
                    }
            )
        } else { content }
    }

    private static func resolve(_ value: DragGesture.Value, rtl: Bool) -> FlareSwipeReplyGesture {
        FlareSwipeReply.resolve(dx: value.translation.width, dy: value.translation.height, rtl: rtl)
    }
}

/// Long-press only when the row can act on it; in multi-select mode the tap
/// gesture owns the row and a long-press must not open the action sheet.
private struct RowLongPress: ViewModifier {
    let enabled: Bool
    let action: () -> Void
    func body(content: Content) -> some View {
        if enabled { content.onLongPressGesture(perform: action) } else { content }
    }
}

private struct TimelineRowFrames: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) { value.merge(nextValue(), uniquingKeysWith: { _, new in new }) }
}


/// 气泡最大宽 = 可用宽 × 比例，再被 ``FlareSizes/bubbleMaxWidth`` 封顶 —— 四端同一条规则。
///
/// 抽成纯函数是为了能直接断言这条规则本身：SwiftUI 的环境传播在单测里很难验，
/// 而真正要钉住的是「窄栏给得更满、宽栏按比例并封顶」这个算式。
///
/// 改前这条规则四端各写各的：这一端**完全不设上限**（宽栏/iPad 上一条长消息贴满整栏）、
/// Android 固定 320dp、Flutter 取屏宽而非窗格宽的 72%、web 是 `min(62%, 640)`。
public func flareBubbleMaxWidth(paneWidth: CGFloat) -> CGFloat {
    let ratio = paneWidth < FlareSizes.navigationRailMinWidth
        ? FlareSizes.componentBubbleMaxWidthRatioCompact
        : FlareSizes.componentBubbleMaxWidthRatioRegular
    return min(paneWidth * ratio, FlareSizes.bubbleMaxWidth)
}
