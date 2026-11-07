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
///
/// Paging (`spec/message-list-paging-vectors.json`): the older end above the timeline and, for a window detached from
/// the latest (`hasNewer`), the newer end below it draw a spinner while loading, else the error and the load or retry
/// button. The list asks for a page by itself (`onLoadOlder`, `onLoadNewer`) when the reader moves within 160 pt of
/// that edge. A detached window shows ``ScrollToLatestView`` without a count, which asks the host for the latest
/// window (`onJumpToLatest`); that window opens at its newest message. A newer page read into a detached window keeps
/// the reader on the rows they are reading. A window the host replaces as a whole (`windows`: `windowId` changed, the
/// latest window the reader asked for, or no row left in common) opens at its newest row, keeps nothing of the reader's
/// place in the old one, and asks for no page by itself until the reader moves it. A located row stays where the
/// locate put it until the reader moves: a page that lands meanwhile keeps it in the middle (`locateAfterReplace`).
public struct MessageListView: View {
    private let hasOlder: Bool
    private let olderError: String?
    private let loadOlderText: String?
    private let onLoadOlder: (() -> Void)?
    private let hasNewer: Bool
    private let loadingNewer: Bool
    private let newerError: String?
    private let onLoadNewer: (() -> Void)?
    private let onJumpToLatest: (() -> Void)?
    private let windowId: String?
    private let onAtBottomChange: ((Bool) -> Void)?
    private let conversationId: String?
    /// Whether the reader is at the bottom (`atBottom`), as last told to the host, for ``bottomConversationId``.
    @State private var bottom = FlareMessageListPaging.BottomReport()
    @State private var bottomConversationId: String?
    @State private var requested = false
    @State private var requestedNewer = false
    /// Whether the reader asked for the latest window, and whether the window was detached since the rows last changed.
    @State private var paging = TimelinePaging()
    /// How far the first row's top is above the viewport's top and the end below its bottom, as last reported;
    /// nil until the row is laid out.
    @State private var pagingFromTop: CGFloat?
    @State private var pagingFromBottom: CGFloat?
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
    private let onMediaReveal: ((FlareMessageData, FlareMessageContent) -> Void)?
    private let onOpenFile: ((FlareMessageData, FlareFileContent) -> Void)?
    private let onOpenLink: ((FlareMessageData, String) -> Void)?
    private let onVote: ((FlareMessageData, Int) -> Void)?
    private let onTaskToggle: ((FlareMessageData, Bool) -> Void)?
    private let onCardOpen: ((FlareMessageData, String) -> Void)?
    private let onLocationOpen: ((FlareMessageData, FlareLocationContent) -> Void)?
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
    private let onReadReceiptOpen: ((FlareMessageData) -> Void)?
    private let onAvatarTap: ((FlareMessageData) -> Void)?
    private let menu: FlareMessageMenuSource?
    /// The timeline's media defaults: the full-screen viewer and one voice message at a time.
    @StateObject private var mediaSession = FlareMediaSession()
    /// Rows without a menu snapshot that came on screen, asked for in one call per turn of the run loop.
    @StateObject private var menuPrefetcher = FlareMessageMenuPrefetcher()
    /// The message the long-press sheet is open for.
    @State private var menuTarget: FlareMessageMenuTarget?
    /// A long-pressed message whose snapshot the host is still reading: its sheet opens once the snapshot is there.
    @State private var pendingMenuId: String?

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale
    @Environment(\.flareContentSurfaces) private var contentSurfaces

    /// - Parameters:
    ///   - onMediaAction: Takes every media tap. Without it the list opens images and videos in the
    ///     kit's full-screen viewer and plays voice messages in their bubbles, one at a time, stopping
    ///     when the list goes away. Files, locations and links always go to the host.
    ///   - mediaDownloadStates: The host's media download states by message id
    ///     (``FlareMediaDownloadState``). A file card's key, and the key of the image preview and the video
    ///     player, show a download, the save's progress, or once the media is saved a folder. A viewer that
    ///     is open follows the states as they change.
    ///   - onMediaDownload: Offered as the download key of the kit's image preview and video player, and as
    ///     the key at the trailing edge of every file card; without it none of them has a key. A tapped
    ///     picture opens the conversation's gallery, every picture of `messages` in timeline order, and each
    ///     one's key downloads that picture with the message it belongs to; a video's key downloads that video.
    ///   - onMediaReveal: The folder key of a saved file, picture or video (message, the content): the host
    ///     shows it where it was saved — or, finding it gone, passes `idle` for it again, and the key is a
    ///     download once more. An album's pictures keep the download key.
    ///   - onOpenFile: A file tap when there is no `onMediaAction`: the host opens the file (after
    ///     ``safeExternalURL(_:)`` for a remote one), and images, videos and voice keep the kit defaults.
    ///   - onOpenLink: A tapped link, in a text body or on a link card, with its raw URL. Without it the
    ///     timeline opens a web address after ``safeExternalURL(_:)`` and opens nothing else.
    ///   - onVote: A tapped poll option (message, option index). Without it polls are read-only.
    ///   - onTaskToggle: A tapped task checkbox (message, the done state asked for). Without it tasks
    ///     are read-only.
    ///   - onCardOpen: A tapped contact card (message, the user id it shares), for the host to open the profile;
    ///     before `onMediaAction`.
    ///   - onLocationOpen: A tapped location (message, the location); before `onMediaAction`. Without either the
    ///     card opens Apple Maps at the point.
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
    ///   - hasNewer: The window is detached from the latest messages (it was opened around a message): there is newer
    ///     history past its last row. The list draws its newer end below the timeline, asks for newer pages as the
    ///     reader nears the bottom (`onLoadNewer`) and offers the way back to the latest (`onJumpToLatest`). Left at
    ///     the defaults the list draws no newer end, never asks for newer and keeps only the new-messages key.
    ///   - loadingNewer: A newer page is being read: the newer end shows a spinner.
    ///   - newerError: The last newer page failed: the newer end shows it with a retry.
    ///   - onLoadNewer: Reads the next newer page.
    ///   - onJumpToLatest: The back-to-latest key of a detached window: the host replaces the window with the latest
    ///     messages.
    ///   - windowId: The host's name for the window it hands the list (the core timeline view's `viewId`). When it
    ///     changes from one name to another the window was replaced as a whole, even where the two share rows. Without
    ///     it a window is replaced when no row is left in common.
    ///   - onAtBottomChange: Whether the reader is at the bottom of the window (`spec/message-list-paging-vectors.json`
    ///     `atBottom`): the end of the timeline at most 80 pt below the viewport. Called when the answer changes and once
    ///     after the first layout of each conversation. A window replaced without the reader asking for it and a locate
    ///     answer false until the reader moves the list, goes to the newest row (the new-messages key, a message of
    ///     their own) or gets the latest window they asked for. It is the bottom of the window shown, attached to the
    ///     latest or not (Vue `atBottomChange`).
    ///   - onAvatarTap: The host handles a visible sender avatar outside multi-select mode.
    ///   - onReadReceiptOpen: A tap on the read summary of the viewer's own group message ("N 人未读"); the host
    ///     fills its read receipt list from the SDK. Without it the summary is plain text.
    ///   - menu: One source for the message menu (``FlareMessageMenuSource``): the kit opens the long-press sheet
    ///     (``MessageActionSheetView``, reactions to `onReact`) and, on a pointer, draws the context menu — a secondary
    ///     click on macOS, and on iPad, where it also takes the long press — from the same entries, and both send
    ///     the chosen action to `perform`. Rows coming on screen without a snapshot are prefetched, and so is the
    ///     message of an open pointer menu once the host drops its snapshot. With a `menu`, `onMessageLongPress` is
    ///     not called; without one the long press calls it as before.
    ///
    /// Each row is one VoiceOver element — sender, content summary, time and status — with the actions reply
    /// (`onSwipeReply`), the message menu (`onMessageLongPress`) and, while failed, retry (`onResend`).
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
        onMediaReveal: ((FlareMessageData, FlareMessageContent) -> Void)? = nil,
        onOpenFile: ((FlareMessageData, FlareFileContent) -> Void)? = nil,
        onOpenLink: ((FlareMessageData, String) -> Void)? = nil,
        onVote: ((FlareMessageData, Int) -> Void)? = nil,
        onTaskToggle: ((FlareMessageData, Bool) -> Void)? = nil,
        onCardOpen: ((FlareMessageData, String) -> Void)? = nil,
        onLocationOpen: ((FlareMessageData, FlareLocationContent) -> Void)? = nil,
        onResend: ((FlareMessageData) -> Void)? = nil,
        hasOlder: Bool = false, olderError: String? = nil, loadOlderText: String? = nil,
        onLoadOlder: (() -> Void)? = nil,
        hasNewer: Bool = false, loadingNewer: Bool = false, newerError: String? = nil,
        onLoadNewer: (() -> Void)? = nil, onJumpToLatest: (() -> Void)? = nil,
        windowId: String? = nil,
        onAtBottomChange: ((Bool) -> Void)? = nil,
        conversationId: String? = nil,
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
        footer: AnyView? = nil,
        onAvatarTap: ((FlareMessageData) -> Void)? = nil,
        onReadReceiptOpen: ((FlareMessageData) -> Void)? = nil,
        menu: FlareMessageMenuSource? = nil
    ) {
        self.hasOlder = hasOlder; self.olderError = olderError; self.loadOlderText = loadOlderText
        self.onLoadOlder = onLoadOlder; self.conversationId = conversationId
        self.hasNewer = hasNewer; self.loadingNewer = loadingNewer; self.newerError = newerError
        self.onLoadNewer = onLoadNewer; self.onJumpToLatest = onJumpToLatest
        self.windowId = windowId
        self.onAtBottomChange = onAtBottomChange
        self._paging = State(initialValue: TimelinePaging(detachedSinceRows: hasNewer, windowId: windowId))
        self._bottomConversationId = State(initialValue: conversationId)
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
        self.onMediaReveal = onMediaReveal
        self.onOpenFile = onOpenFile
        self.onOpenLink = onOpenLink
        self.onVote = onVote
        self.onTaskToggle = onTaskToggle
        self.onCardOpen = onCardOpen
        self.onLocationOpen = onLocationOpen
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
        self.onReadReceiptOpen = onReadReceiptOpen
        self.onAvatarTap = onAvatarTap
        self.menu = menu
    }

    /// Long-press opens the message action sheet only outside multi-select mode
    /// (Flutter parity: `onLongPress: multiSelectMode ? null : ...`).
    static func longPressEnabled(multiSelectMode: Bool, onMessageLongPress: ((FlareMessageData) -> Void)?,
                                 menu: FlareMessageMenuSource? = nil) -> Bool {
        !multiSelectMode && (onMessageLongPress != nil || menu != nil)
    }

    /// A long press or the menu accessibility action on `message`: with a menu source the kit's sheet (now, or once
    /// the host has read the snapshot), else the host's `onMessageLongPress`.
    private func openMenu(_ message: FlareMessageData) {
        guard let menu else { onMessageLongPress?(message); return }
        if menu.availability(message) != nil {
            pendingMenuId = nil
            menuTarget = FlareMessageMenuTarget(message: message)
            return
        }
        pendingMenuId = message.id
        menuPrefetcher.ask(message.id, menu.prefetch)
        // A snapshot that never comes does not open a sheet much later.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if pendingMenuId == message.id { pendingMenuId = nil }
        }
    }

    /// Settles the rows whose snapshot has arrived since they were asked for (and the ones no longer in the list).
    private func settleArrivedMenuSnapshots() {
        guard let menu else { return }
        menuPrefetcher.settleArrived { id in
            guard let message = messages.first(where: { $0.id == id }) else { return true }
            return menu.availability(message) != nil
        }
    }

    /// The long-pressed message waiting for its snapshot, once the snapshot is there.
    private var pendingMenuReady: String? {
        guard let id = pendingMenuId, let menu, let message = messages.first(where: { $0.id == id }),
              menu.availability(message) != nil else { return nil }
        return id
    }

    /// The long-press sheet for `target`, from the menu source.
    @ViewBuilder private func menuSheet(_ target: FlareMessageMenuTarget) -> some View {
        if let menu {
            Self.menuSheet(messages.first(where: { $0.id == target.id }) ?? target.message, menu: menu,
                           onReact: onReact, done: { menuTarget = nil })
        }
    }

    /// The long-press sheet of `message`: the menu source's entries (the pointer menu's too), the chosen action to
    /// `perform` and a reaction to `onReact`, each after `done` closes the sheet.
    static func menuSheet(_ message: FlareMessageData, menu: FlareMessageMenuSource,
                          onReact: ((FlareMessageData, String) -> Void)?, done: @escaping () -> Void) -> MessageActionSheetView {
        MessageActionSheetView(
            availability: menu.availability(message) ?? FlareMessageActionAvailability(), content: message.content,
            hiddenActions: menu.hiddenActions, actions: menu.extraActions(message),
            onAction: { id in done(); menu.perform(message, id) },
            onReact: onReact.map { react in { emoji in done(); react(message, emoji) } })
    }

    /// Notices (system lines, recalled and deleted messages) carry no message actions:
    /// no long-press menu, no swipe-to-reply.
    static func isActionable(_ message: FlareMessageData) -> Bool {
        !message.isSystem && !message.isRecalled && !message.isDeleted
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

    /// Every row of the timeline, as the list draws them (``flareTimelineRows(_:currentUserId:conversationKind:unreadFromId:options:nowMs:timeZone:utcOffsetMinutes:)``
    /// over the rows' surfaces): before a message, the date separator when it starts a local day, then the unread
    /// divider when it is the first unread message.
    static func timelineEntries(_ messages: [FlareMessageData], unreadFromId: String?, currentUserId: String,
                                timeZone: TimeZone = .current,
                                surfaces: [String: FlareMessageRegisteredSurface] = [:]) -> [TimelineEntry] {
        let items = messages.map { $0.groupingItem(surface: $0.surface(registry: surfaces)) }
        return flareTimelineRows(items, currentUserId: currentUserId, conversationKind: .single,
                                 unreadFromId: unreadFromId, timeZone: timeZone).map { row in
            switch row {
            case .date(let atMs, _): return .date(sentAtMs: atMs)
            case .unread(let count): return .unread(count: count)
            case .message(let index, let position, _): return .message(id: messages[index].id, position: position)
            }
        }
    }

    /// What a message row draws above and of itself: its date pill, the unread divider, its run position and
    /// presentation, and its surface.
    struct RowLayout {
        var date: FlareTimelineDateLabel?
        var unread: Int?
        var position: MessageGroupPosition = .single
        var presentation = MessageRowPresentation()
        var surface: FlareMessageSurface = .bubble
    }

    /// The layout of every message row, by index.
    static func rowLayouts(_ messages: [FlareMessageData], currentUserId: String, conversationKind: FlareConversationKind,
                           unreadFromId: String?, options: FlareMessageGroupingOptions,
                           surfaces registry: [String: FlareMessageRegisteredSurface],
                           timeZone: TimeZone = .current) -> [RowLayout] {
        let surfaces = messages.map { $0.surface(registry: registry) }
        let items = zip(messages, surfaces).map { $0.groupingItem(surface: $1) }
        var layouts = surfaces.map { RowLayout(surface: $0) }
        var pendingDate: FlareTimelineDateLabel?
        var pendingUnread: Int?
        for row in flareTimelineRows(items, currentUserId: currentUserId, conversationKind: conversationKind,
                                     unreadFromId: unreadFromId, options: options, timeZone: timeZone) {
            switch row {
            case .date(_, let label): pendingDate = label
            case .unread(let count): pendingUnread = count
            case .message(let index, let position, let presentation):
                layouts[index].date = pendingDate
                layouts[index].unread = pendingUnread
                layouts[index].position = position
                layouts[index].presentation = presentation
                pendingDate = nil
                pendingUnread = nil
            }
        }
        return layouts
    }

    /// A date pill's words: the strings table's today and yesterday, else the locale's month and day (with the year
    /// outside this one).
    static func dateLabel(_ label: FlareTimelineDateLabel, atMs: Int64, strings: FlareStrings, locale: Locale,
                          now: Date) -> String {
        switch label {
        case .today: return strings.today
        case .yesterday: return strings.yesterday
        case .monthDay, .yearMonthDay:
            return FlareTimeFormat.timelineDateLabel(Date(timeIntervalSince1970: TimeInterval(atMs) / 1000),
                                                     today: strings.today, yesterday: strings.yesterday,
                                                     locale: locale, now: now)
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        // The host's handle learns the rows this pass draws before the pass draws them, so
        // `scrollToMessage` never answers from the previous set of messages.
        let _ = attachController()
        // The rows asked for whose snapshot has arrived are settled, so a snapshot that lapses later is asked for
        // again rather than swallowed as a repeat of the request it answered.
        let _ = settleArrivedMenuSnapshots()
        // 量一次窗格宽,经环境值下发给每一行 —— 气泡最大宽 = 可用宽 × 比例,再被
        // layout.bubbleMaxWidth 封顶,与另外三端同一条规则。
        GeometryReader { proxy in
            timelineBody(colors)
                .environment(\.flareBubbleMaxWidth, flareBubbleMaxWidth(paneWidth: proxy.size.width))
        }
        #if os(iOS)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded { FlareLayerPlatform.endEditing() })
        #endif
        // The menu source's long-press sheet, outside the timeline's own layout.
        .modifier(MenuSheetHost(enabled: menu != nil, target: $menuTarget, title: strings.messageActionSheetLabel,
                                pendingReady: pendingMenuReady, sheet: menuSheet) { id in
            guard let message = messages.first(where: { $0.id == id }) else { return }
            pendingMenuId = nil
            menuTarget = FlareMessageMenuTarget(message: message)
        })
    }

    /// The two ends of the window (`spec/message-list-paging-vectors.json`): one rule above and below the timeline.
    private var olderEnd: FlareMessageListPaging.End {
        .init(has: hasOlder, loading: loadingOlder, error: olderError, handled: onLoadOlder != nil)
    }
    private var newerEnd: FlareMessageListPaging.End {
        .init(has: hasNewer, loading: loadingNewer, error: newerError, handled: onLoadNewer != nil)
    }

    private func askOlder(retry: Bool) {
        guard !requested, !loadingOlder, hasOlder, let onLoadOlder, retry || !olderEnd.failed else { return }
        requested = true
        onLoadOlder()
    }

    private func askNewer(retry: Bool) {
        guard !requestedNewer, !loadingNewer, hasNewer, let onLoadNewer, retry || !newerEnd.failed else { return }
        requestedNewer = true
        // The row at the bottom holds the reading position while the page grows under it, rather than the end
        // of the timeline, which would carry the reader down with the new rows.
        if visibleId == Self.timelineEndId { visibleId = messages.last?.id }
        onLoadNewer()
    }

    /// One end of the window: the spinner while a page loads, else the error and the load or retry button.
    @ViewBuilder
    private func endBand(_ edge: FlareMessageListPaging.Edge, error: String?, label: String, disabled: Bool,
                         colors: FlareColors, load: @escaping () -> Void) -> some View {
        if edge.error, let error { Text(error).foregroundColor(colors.textPrimary).padding(.horizontal, 12) }
        if edge.spinner { ProgressView().frame(minHeight: 48) }
        else if edge.button {
            Button(action: load) { Text(label).frame(minWidth: 48, minHeight: 48) }.disabled(disabled)
        }
    }

    /// The reader moved: an edge row reported a new position. Pages are asked for within the shared distance of
    /// either edge; the first report of a window only records where it is, and so does every report of a replaced
    /// window until the reader moves it.
    private func pagingMoved(fromTop: CGFloat?? = .none, fromBottom: CGFloat?? = .none) {
        var moved = false
        if case .some(let top) = fromTop, top != pagingFromTop { moved = pagingFromTop != nil; pagingFromTop = top }
        if case .some(let bottom) = fromBottom, bottom != pagingFromBottom { moved = moved || pagingFromBottom != nil; pagingFromBottom = bottom }
        // In a replaced window the reader's first move lets the list ask again; its own moves never do.
        guard moved, paging.mayAsk else { return }
        let wanted = FlareMessageListPaging.requests(fromTop: pagingFromTop ?? .infinity, fromBottom: pagingFromBottom ?? .infinity,
                                                     older: olderEnd, newer: newerEnd)
        if wanted.older { askOlder(retry: false) }
        if wanted.newer { askNewer(retry: false) }
    }

    @ViewBuilder
    private func timelineBody(_ colors: FlareColors) -> some View {
        VStack(spacing: 0) {
            endBand(FlareMessageListPaging.edge(olderEnd), error: olderError, label: loadOlderText ?? strings.messageListLoadOlder,
                    disabled: requested, colors: colors) { askOlder(retry: true) }
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
            endBand(FlareMessageListPaging.edge(newerEnd), error: newerError, label: strings.messageListLoadNewer,
                    disabled: requestedNewer, colors: colors) { askNewer(retry: true) }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(colors.bgSecondary)
            .onChange(of: loadingOlder) { if !$0 { requested = false } }
            .onChange(of: messages.first?.id) { _ in requested = false }
            .onChange(of: olderError) { _ in requested = false }
            .onChange(of: loadingNewer) { if !$0 { requestedNewer = false } }
            .onChange(of: messages.last?.id) { _ in requestedNewer = false }
            .onChange(of: newerError) { _ in requestedNewer = false }
            .onChange(of: conversationId) { _ in
                requested = false; visibleId = nil; rowFrames = [:]; restorationGeneration += 1; locatedId = nil
                requestedNewer = false; paging = TimelinePaging(detachedSinceRows: hasNewer, windowId: windowId)
                pagingFromTop = nil; pagingFromBottom = nil
                follow = TimelineFollow()
                bottomForConversation()
                mediaSession.voice.stop()
            }
            // An empty list is at its bottom (`atBottom`): the first layout of one answers that, and so does a window
            // that loses all its rows.
            .onAppear { if messages.isEmpty { tellBottom { $0.emptied() } } }
            .onChange(of: messages.isEmpty) { empty in if empty { tellBottom { $0.emptied() } } }
            // A list that comes back without its body being evaluated again takes the handle back;
            // a list that goes away lets go of it, so the handle answers false instead of writing to
            // a view that is no longer there.
            .onAppear { attachController() }
            .onDisappear { controller?.detach(controllerToken) }
            // The viewer is presented over the list and follows the host's states from here.
            .onAppear { mediaSession.downloads.update(mediaDownloadStates) }
            .onChange(of: mediaDownloadStates) { mediaSession.downloads.update($0) }
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
        let pagingRows = TimelinePagingRows(rows: followRows, detached: hasNewer, windowId: windowId)
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
                        .onChange(of: pagingRows) { value in
                            let previousLast = timelineIds.last
                            switch rowsChanged(value) {
                            case .latest: goToLatest(tailId: value.rows.last?.id)
                            case .newerPage:
                                // The row at the bottom holds the place rather than the end, which the new rows moved.
                                if visibleId == Self.timelineEndId { visibleId = previousLast }
                                keepLocatedRow(proxy, in: value)
                            case .keep: keepLocatedRow(proxy, in: value)
                            }
                        }
                        .onPreferenceChange(TimelineStart.self) { pagingMoved(fromTop: .some($0.map { max(0, -$0) })) }
                        .onPreferenceChange(TimelineEnd.self) {
                            pagingMoved(fromBottom: .some($0.map { max(0, $0.distanceToBottom) }))
                            measureBottomFromEndRow($0)
                        }
                        .modifier(ScrollBottomDistance { measureBottom($0) })
                        .onChange(of: jumpGeneration) { _ in goToLatest(tailId: timelineIds.last) }
                        .onChange(of: viewport.size.height) { _ in
                            // A located row stays where the locate put it: a band that changes the height is not the
                            // reader asking for the bottom.
                            if paging.locatedId == nil, follow.followTail || follow.atBottom {
                                goToLatest(tailId: timelineIds.last)
                            }
                        }
                        .onChange(of: locateGeneration) { _ in
                            // A row scrolled to by the proxy is not the bound position; a stale one would pull the
                            // list back to it when the content next changes.
                            visibleId = nil
                            if let locatedId { paging.located(locatedId); tellBottom { $0.located() } }
                            DispatchQueue.main.async { scrollToLocated(proxy) }
                        }
                        .modifier(ReaderScrollWatch { readerMoved() })
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
                            // Match the modern path: a row scrolled to by the proxy is not the bound
                            // position. Where the system keeps one (BottomVisibleRow), it still names
                            // the end this list was sent to, and the located row's mark changing the
                            // content would pull the reader back there.
                            legacyVisibleId = nil
                            if let locatedId { paging.located(locatedId); tellBottom { $0.located() } }
                            // Let this update finish before asking the proxy to move. In the legacy
                            // path an onAppear/end-restoration scroll can otherwise run later in the
                            // same pass and pull the reader back.
                            DispatchQueue.main.async { scrollToLocated(proxy) }
                        }
                        .modifier(ReaderScrollWatch { readerMoved() })
                        .onPreferenceChange(TimelineRowFrames.self) { rowFrames = $0 }
                        .onPreferenceChange(TimelineEnd.self) {
                            syncPosition($0)
                            pagingMoved(fromBottom: .some($0.map { max(0, $0.distanceToBottom) }))
                            measureBottomFromEndRow($0)
                        }
                        .modifier(ScrollBottomDistance { measureBottom($0) })
                        .onPreferenceChange(TimelineStart.self) { pagingMoved(fromTop: .some($0.map { max(0, -$0) })) }
                        .onChange(of: jumpGeneration) { _ in scrollToEnd(proxy, tailId: timelineIds.last) }
                        .onChange(of: viewport.size.height) { _ in
                            if paging.locatedId == nil, follow.followTail || follow.atBottom {
                                scrollToEnd(proxy, tailId: timelineIds.last)
                            }
                        }
                        .onChange(of: pagingRows) { value in
                            let rows = value.rows
                            if rowsChanged(value) == .latest {
                                scrollToEnd(proxy, tailId: rows.last?.id)
                                return
                            }
                            if keepLocatedRow(proxy, in: value) { return }
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

    /// The floating key (``FlareMessageListPaging/latestEntry(hasNewer:handled:belowCount:)``): back to the latest
    /// messages for a detached window, else the count of the messages that arrived below a reader who scrolled up.
    @ViewBuilder private var scrollToLatestKey: some View {
        let entry = FlareMessageListPaging.latestEntry(hasNewer: hasNewer, handled: onJumpToLatest != nil,
                                                       belowCount: follow.pendingBelowCount(messages))
        if entry.shown {
            ScrollToLatestView(count: entry.count) {
                if entry.action == .jumpToLatest {
                    paging.jumpRequested = true
                    onJumpToLatest?()
                } else {
                    tellBottom { $0.wentToLatest() }
                    jumpGeneration += 1
                }
            }
            .padding(FlareSizes.spacingLg)
        }
    }

    /// The rows or the detached state changed: records the ids and says what the reading position does
    /// (``TimelinePaging/rowsChanged(from:to:follow:)``).
    private func rowsChanged(_ value: TimelinePagingRows) -> TimelinePaging.RowsChange {
        let previous = timelineIds
        timelineIds = value.rows.map(\.id)
        let change = paging.rowsChanged(from: previous, to: value, follow: &follow)
        switch paging.bottomStep {
        case .replaced: tellBottom { $0.replaced() }
        case .jumpedToLatest: tellBottom { $0.jumpedToLatest() }
        case .ownArrived: tellBottom { $0.wentToLatest() }
        case .none: break
        }
        return change
    }

    /// Another conversation starts the bottom report over: it answers once more after the first layout.
    private func bottomForConversation() {
        guard bottomConversationId != conversationId else { return }
        bottomConversationId = conversationId
        bottom.anotherConversation()
    }

    /// Takes one step of the bottom report (``FlareMessageListPaging/BottomReport``) and tells the host what it
    /// changed about the reader being at the bottom, if anything.
    private func tellBottom(_ step: (inout FlareMessageListPaging.BottomReport) -> Bool?) {
        bottomForConversation()
        var report = bottom
        let answer = step(&report)
        if report != bottom { bottom = report }
        if let answer { onAtBottomChange?(answer) }
    }

    /// One layout or scroll, as the bottom report reads it: how far the end of the timeline is below the viewport.
    private func measureBottom(_ fromBottom: CGFloat) {
        tellBottom { $0.layout(fromBottom: max(0, fromBottom)) }
    }

    /// Where the scroll view does not report its geometry (before iOS 18 and macOS 15), the end row's position is the
    /// layout the bottom report reads.
    private func measureBottomFromEndRow(_ end: TimelineEnd.Position?) {
        guard let end else { return }
        if #unavailable(iOS 18.0, macOS 15.0) { measureBottom(end.distanceToBottom) }
    }

    /// Under a locate the located row is what stays (`locateAfterReplace`): once this update is laid out it is put back
    /// in the middle, where the locate puts it, whatever rows landed around it — the scroll that was taking the reader
    /// there aimed at an offset measured before. False when there is no located row, or it is gone.
    @discardableResult
    private func keepLocatedRow(_ proxy: ScrollViewProxy, in value: TimelinePagingRows) -> Bool {
        let ids = Set(value.rows.map(\.id))
        guard let id = paging.prependAnchor(readerRow: nil, loaded: ids.contains) else { return false }
        DispatchQueue.main.async {
            guard paging.locatedId == id else { return }
            proxy.scrollTo(id, anchor: .center)
        }
        return true
    }

    /// The reader moved the list themselves: written only when there is a hold to let go of.
    private func readerMoved() {
        if !paging.mayAsk || paging.locatedId != nil { paging.readerMoved() }
        tellBottom { $0.readerMoved() }
    }

    /// The reader's position from the end of the timeline, written only when what it decides changes.
    private func syncPosition(_ end: TimelineEnd.Position?) {
        var next = follow
        next.sync(distanceToBottom: end?.distanceToBottom ?? .infinity, tailId: end?.tailId)
        if hasNewer { next.detach() }
        if next != follow { follow = next }
    }

    /// The reader's position from the bottom-most visible row. Nil is the position the list was put in
    /// and nobody has scrolled away from — it opens at the newest message — so nil decides nothing.
    private func syncAnchor(_ id: String?) {
        guard let id else { return }
        var next = follow
        next.sync(atEnd: id == Self.timelineEndId || id == messages.last?.id, tailId: messages.last?.id)
        if hasNewer { next.detach() }
        if next != follow { follow = next }
    }

    /// Goes to the newest message through the bound position (iOS 17 and later).
    private func goToLatest(tailId: String?) {
        if visibleId != Self.timelineEndId { visibleId = Self.timelineEndId }
        follow.reachedBottom(tailId: tailId)
        // Going to the newest message leaves the located row.
        if paging.locatedId != nil { paging.locatedId = nil }
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
        // Going to the newest message leaves the located row.
        if paging.locatedId != nil { paging.locatedId = nil }
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
        // One pass over the timeline: each row's date pill, unread divider, run position, presentation and surface.
        let layouts = Self.rowLayouts(
            messages, currentUserId: currentUserId, conversationKind: conversationKind, unreadFromId: unreadFromId,
            options: FlareMessageGroupingOptions(showIncomingAvatar: showIncomingAvatar, showSelfAvatar: showSelfAvatar,
                                                 showGroupSenderName: showGroupSenderName),
            surfaces: contentSurfaces)
        let now = Date()
        let pointerMenu = menu != nil && FlareMessageMenuSource.pointerIdiom
        return LazyVStack(spacing: 0) {
            ForEach(Array(messages.enumerated()), id: \.element.id) { index, msg in
                let layout = layouts[index]
                let actionable = Self.isActionable(msg)
                VStack(spacing: 0) {
                    // The day comes first, then where the unread messages start inside it.
                    if let date = layout.date {
                        DatePillView(label: Self.dateLabel(date, atMs: msg.sentAtMs, strings: strings, locale: locale,
                                                           now: now))
                            .padding(.vertical, FlareSizes.spacingSm)
                            .accessibilityAddTraits(.isHeader)
                    }
                    if let unread = layout.unread {
                        UnreadDividerView(count: unread)
                    }
                    MessageBubbleView(message: msg, currentUserId: currentUserId, conversationKind: conversationKind,
                        groupPosition: layout.position, rowPresentation: layout.presentation, surface: layout.surface,
                        mediaState: mediaDownloadStates[msg.id],
                        onMediaAction: onMediaAction, onMediaDownload: onMediaDownload, onMediaReveal: onMediaReveal,
                        onOpenFile: onOpenFile,
                        onOpenLink: onOpenLink, onResend: onResend,
                        multiSelectMode: multiSelectMode,
                        selected: Self.isSelected(msg.id, multiSelectMode: multiSelectMode, selectedIds: selectedIds),
                        onToggleSelect: onToggleSelect,
                        onReact: onReact,
                        onLocateMessage: locateCallback(msg, rows: rowIndex),
                        onVote: onVote, onTaskToggle: onTaskToggle,
                        onCardOpen: onCardOpen, onLocationOpen: onLocationOpen,
                        onAvatarTap: onAvatarTap, onReadReceiptOpen: onReadReceiptOpen)
                        .mediaDefaults(mediaSession, gallery: FlareImageGallerySource(messages: messages, download: onMediaDownload,
                                                                                      reveal: onMediaReveal))
                        .environment(\.flareMessageConversationId, conversationId)
                        .accessibilityFocused($readingCursor, equals: msg.id)
                        .contentShape(Rectangle())
                        .modifier(RowLongPress(enabled: actionable && FlareMessageMenuSource.longPressOpensSheet(pointerMenu: pointerMenu)
                                               && Self.longPressEnabled(multiSelectMode: multiSelectMode,
                                                                        onMessageLongPress: onMessageLongPress, menu: menu)) {
                            openMenu(msg)
                        })
                        .modifier(RowPointerMenu(message: msg, menu: actionable && !multiSelectMode && pointerMenu ? menu : nil,
                                                 prefetcher: menuPrefetcher))
                        .onAppear {
                            // A row coming on screen without a snapshot is read ahead of its menu.
                            guard actionable, let menu else { return }
                            if menu.availability(msg) == nil { menuPrefetcher.request(msg.id, menu.prefetch) }
                            else { menuPrefetcher.settle(msg.id) }
                        }
                        .modifier(RowSwipeReply(enabled: actionable && !multiSelectMode && onSwipeReply != nil) {
                            onSwipeReply?(msg)
                        })
                        .modifier(RowAccessibilityActions(
                            actions: actionable && !multiSelectMode
                                ? Self.accessibilityActions(msg, currentUserId: currentUserId, strings: strings,
                                                            reply: onSwipeReply,
                                                            menu: menu != nil || onMessageLongPress != nil ? openMenu : nil,
                                                            resend: onResend)
                                : []))
                }
                .id(msg.id)
                .background {
                    // The first row says how far the top of the timeline is above the viewport, for paging.
                    if index == 0 {
                        GeometryReader { proxy in
                            Color.clear.preference(key: TimelineStart.self, value: proxy.frame(in: .named(coordinateSpace)).minY)
                        }
                    }
                }
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

    /// One custom accessibility action of a message row.
    struct RowAction: Identifiable {
        enum Kind: String { case reply, menu, retry }
        let kind: Kind
        let name: String
        let perform: () -> Void
        var id: String { kind.rawValue }
    }

    /// The row's custom accessibility actions (`spec/message-receipt-vectors.json` rules.accessibilityLabel): reply,
    /// open the menu, and retry while the viewer's message has failed — each only when the host handles it.
    static func accessibilityActions(_ message: FlareMessageData, currentUserId: String, strings: FlareStrings,
                                     reply: ((FlareMessageData) -> Void)?, menu: ((FlareMessageData) -> Void)?,
                                     resend: ((FlareMessageData) -> Void)?) -> [RowAction] {
        var actions: [RowAction] = []
        if let reply { actions.append(RowAction(kind: .reply, name: strings.messageActionReply) { reply(message) }) }
        if let menu { actions.append(RowAction(kind: .menu, name: strings.more) { menu(message) }) }
        if let resend, message.senderId == currentUserId, message.receiptStatus == .failed {
            actions.append(RowAction(kind: .retry, name: strings.messageSendFailedRetry) { resend(message) })
        }
        return actions
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

/// Where the first row's top is, relative to the top of the viewport (negative once it scrolled above it); nil while
/// that row is not laid out.
private struct TimelineStart: PreferenceKey {
    static let defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) { value = nextValue() ?? value }
}

/// The rows the follow rules read, with whether the window is detached from the latest: one change value, so a
/// handler sees both as they are now.
struct TimelinePagingRows: Equatable {
    let rows: [TimelineFollow.Row]
    let detached: Bool
    /// The host's name for the window (`windowId`), nil when it names none.
    var windowId: String? = nil
}

/// What a change of the rows does to the reading position of a window that may be detached from the latest.
struct TimelinePaging: Equatable {
    /// The window has been detached since the rows last changed: rows appended now are a newer page. Sticky, so a
    /// host that clears `hasNewer` an update before it hands over the page that attached the window still has that
    /// page kept in place.
    var detachedSinceRows = false
    /// The reader asked for the latest messages: the window the host replaces this one with opens at its newest.
    var jumpRequested = false
    /// The host's name for the window the rows last came with.
    var windowId: String?
    /// The window was replaced and the reader has not moved since: the list asks for no page by itself. Neither the
    /// list placing the new window nor a locate landing near an end is the reader moving (`locateAfterReplace`).
    var requestsHeld = false
    /// The row a locate took the reader to, until the reader moves: a page that lands meanwhile keeps it in the middle,
    /// where the locate put it.
    var locatedId: String?
    /// What the last change of the rows was to the bottom report (``FlareMessageListPaging/BottomReport``).
    private(set) var bottomStep: BottomStep = .none

    /// A change of the rows as the bottom report reads it.
    enum BottomStep: Equatable {
        case none
        /// A window that replaces the one shown, without the reader asking for it.
        case replaced
        /// The latest window the reader asked for.
        case jumpedToLatest
        /// A message of the reader's own, added at the end.
        case ownArrived
    }

    enum RowsChange: Equatable {
        /// Go to the newest message.
        case latest
        /// A newer page grew under a detached window's reader, who stays where they are.
        case newerPage
        /// Keep the reading position.
        case keep
    }

    /// The latest window the reader asked for opens at its newest message; rows appended to a window that was
    /// detached are a newer page; everything else follows ``TimelineFollow/rowsChanged(from:to:)``.
    mutating func rowsChanged(from previous: [String], to value: TimelinePagingRows, follow: inout TimelineFollow) -> RowsChange {
        bottomStep = .none
        if value.detached { detachedSinceRows = true }
        let previousWindowId = windowId
        windowId = value.windowId
        if FlareMessageListPaging.windowReplaced(previous: previous, next: value.rows.map(\.id), jumpRequested: jumpRequested,
                                                 hasNewer: value.detached, previousWindowId: previousWindowId,
                                                 windowId: value.windowId) {
            // A new window (`windows`), and the latest one the reader asked for is one: it opens at its newest row,
            // nothing of the reader's place in the old one applies, and the list asks for nothing by itself until the
            // reader moves it. The reader is not at the bottom of a window they did not ask for until they move it.
            bottomStep = jumpRequested && !value.detached ? .jumpedToLatest : .replaced
            jumpRequested = false
            detachedSinceRows = value.detached
            requestsHeld = true
            locatedId = nil
            follow.reachedBottom(tailId: value.rows.last?.id)
            // The bottom of a detached window is not the latest message: nothing arrives there to follow.
            if value.detached { follow.detach() }
            return .latest
        }
        if jumpRequested && !value.detached {
            bottomStep = .jumpedToLatest
            jumpRequested = false
            detachedSinceRows = false
            follow.reachedBottom(tailId: value.rows.last?.id)
            return .latest
        }
        let ids = value.rows.map(\.id)
        guard previous != ids else { return .keep }
        let wasDetached = detachedSinceRows
        detachedSinceRows = value.detached
        if FlareMessageListPaging.isNewerPage(from: previous, to: ids, wasDetached: wasDetached) {
            follow.readNewerPage(tailId: ids.last)
            return .newerPage
        }
        // A message of the reader's own added at the end takes them to the newest row: the reader arriving there.
        if let window = TimelineFollow.window(from: previous, to: ids), window.appended > 0,
           value.rows.suffix(window.appended).contains(where: \.own) {
            bottomStep = .ownArrived
        }
        return follow.rowsChanged(from: previous, to: value.rows) ? .latest : .keep
    }

    /// A move of the list may ask for pages: always, except in a replaced window the reader has not moved yet.
    var mayAsk: Bool { !requestsHeld }

    /// The reader moved the list themselves: their place is theirs again, not the located row's, and so is paging.
    mutating func readerMoved() {
        requestsHeld = false
        locatedId = nil
    }

    /// The list scrolled to a located row.
    mutating func located(_ id: String) {
        locatedId = id
    }

    /// The row to keep in place while older rows land above: the located row while a locate holds the reader there,
    /// else `readerRow`, the row the reader sees. Nil when neither is still loaded.
    func prependAnchor(readerRow: String?, loaded: (String) -> Bool) -> String? {
        if let locatedId, loaded(locatedId) { return locatedId }
        if let readerRow, loaded(readerRow) { return readerRow }
        return nil
    }
}

/// Tells the list when the reader moves it themselves: the scroll phase where the system reports one (iOS 18,
/// macOS 15), else a drag on the timeline. The list's own scrolls (the proxy, the bound position) are neither.
private struct ReaderScrollWatch: ViewModifier {
    let moved: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            content.onScrollPhaseChange { _, phase in
                if phase == .interacting { moved() }
            }
        } else {
            content.simultaneousGesture(DragGesture(minimumDistance: 10).onChanged { _ in moved() })
        }
    }
}

/// How far the end of the content is below the bottom of the scroll view, from the scroll view's own geometry where the
/// system reports it (iOS 18, macOS 15): it follows every scroll, which a geometry preference inside the content does
/// not on a Mac. Older systems read the end row's position instead.
private struct ScrollBottomDistance: ViewModifier {
    let measured: (CGFloat) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            content.onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentSize.height + geometry.contentInsets.bottom - geometry.contentOffset.y - geometry.containerSize.height
            } action: { _, distance in
                measured(distance)
            }
        } else {
            content
        }
    }
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

/// The list's long-press sheet, only for a list with a menu source: a list without one presents nothing of its own.
private struct MenuSheetHost<Sheet: View>: ViewModifier {
    let enabled: Bool
    @Binding var target: FlareMessageMenuTarget?
    let title: String
    let pendingReady: String?
    let sheet: (FlareMessageMenuTarget) -> Sheet
    let opened: (String) -> Void

    func body(content: Content) -> some View {
        if enabled {
            content
                .flareBottomSheet(item: $target, title: title, titleHidden: true) { sheet($0) }
                .onChange(of: pendingReady) { id in if let id { opened(id) } }
        } else {
            content
        }
    }
}

/// The row's custom accessibility actions (reply, the menu, retry).
private struct RowAccessibilityActions: ViewModifier {
    let actions: [MessageListView.RowAction]

    func body(content: Content) -> some View {
        if actions.isEmpty {
            content
        } else {
            content.accessibilityActions {
                ForEach(actions) { action in Button(action.name, action: action.perform) }
            }
        }
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
