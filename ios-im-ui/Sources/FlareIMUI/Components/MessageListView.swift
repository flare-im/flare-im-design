import SwiftUI

/// The message thread — grouping, media state, load-older. Spec:
/// Message/MessageList (`MessageListView`). Uses a lazy stack (O(visible));
/// order is oldest→newest. The host feeds `messages` from the timeline view.
public struct MessageListView: View {
    private let hasOlder: Bool
    private let olderError: String?
    private let loadOlderText: String
    private let onLoadOlder: (() -> Void)?
    private let conversationId: String?
    @State private var requested = false
    @State private var visibleId: String?
    @State private var rowFrames: [String: CGRect] = [:]
    @State private var restorationGeneration = 0
    @State private var coordinateSpace = UUID()
    private let messages: [FlareMessageData]
    private let currentUserId: String
    private let conversationKind: FlareConversationKind
    private let loading: Bool
    private let loadingOlder: Bool
    private let emptyText: String
    private let mediaDownloadStates: [String: FlareMediaDownloadState]
    private let onMessageLongPress: ((FlareMessageData) -> Void)?
    private let onMediaAction: ((FlareMessageData, FlareMessageContent) -> Void)?
    private let onResend: ((FlareMessageData) -> Void)?

    @Environment(\.colorScheme) private var scheme

    public init(
        messages: [FlareMessageData],
        currentUserId: String,
        conversationKind: FlareConversationKind = .single,
        loading: Bool = false,
        loadingOlder: Bool = false,
        emptyText: String = "还没有消息",
        mediaDownloadStates: [String: FlareMediaDownloadState] = [:],
        onMessageLongPress: ((FlareMessageData) -> Void)? = nil,
        onMediaAction: ((FlareMessageData, FlareMessageContent) -> Void)? = nil,
        onResend: ((FlareMessageData) -> Void)? = nil,
        hasOlder: Bool = false, olderError: String? = nil, loadOlderText: String = "加载更早消息",
        onLoadOlder: (() -> Void)? = nil, conversationId: String? = nil
    ) {
        self.hasOlder = hasOlder; self.olderError = olderError; self.loadOlderText = loadOlderText
        self.onLoadOlder = onLoadOlder; self.conversationId = conversationId
        self.messages = messages
        self.currentUserId = currentUserId
        self.conversationKind = conversationKind
        self.loading = loading
        self.loadingOlder = loadingOlder
        self.emptyText = emptyText
        self.mediaDownloadStates = mediaDownloadStates
        self.onMessageLongPress = onMessageLongPress
        self.onMediaAction = onMediaAction
        self.onResend = onResend
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(spacing: 0) {
            if let olderError { Text(olderError).foregroundColor(colors.textPrimary).padding(.horizontal, 12) }
            if loadingOlder { ProgressView().frame(minHeight: 48) }
            else if hasOlder, let onLoadOlder {
                Button { if !requested { requested = true; onLoadOlder() } } label: {
                    Text(loadOlderText).frame(minWidth: 48, minHeight: 48)
                }.disabled(requested)
            }
            if messages.isEmpty {
                if loading { ProgressView() }
                else { Text(emptyText).font(.body).foregroundColor(colors.textTertiary) }
            } else {
                timeline.id(conversationId)
            }
        }.background(colors.bgSecondary)
            .onChange(of: loadingOlder) { if !$0 { requested = false } }
            .onChange(of: messages.first?.id) { _ in requested = false }
            .onChange(of: olderError) { _ in requested = false }
            .onChange(of: conversationId) { _ in requested = false; visibleId = nil; rowFrames = [:]; restorationGeneration += 1 }
    }

    @ViewBuilder private var timeline: some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            ScrollView { rows.scrollTargetLayout() }
                .scrollPosition(id: $visibleId, anchor: .top)
        } else {
            GeometryReader { viewport in
                ScrollViewReader { proxy in
                    ScrollView { rows }.coordinateSpace(name: coordinateSpace)
                        .onPreferenceChange(TimelineRowFrames.self) { rowFrames = $0 }
                        .onChange(of: messages.map(\.id)) { ids in
                            let surviving = Set(ids)
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
    }

    private var rows: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(messages.enumerated()), id: \.element.id) { index, msg in
                MessageBubbleView(message: msg, currentUserId: currentUserId, conversationKind: conversationKind,
                    groupStart: isGroupStart(index), groupEnd: isGroupEnd(index), mediaState: mediaDownloadStates[msg.id],
                    onMediaAction: onMediaAction, onResend: onResend)
                    .id(msg.id)
                    .background(GeometryReader { proxy in
                        Color.clear.preference(key: TimelineRowFrames.self, value: [msg.id: proxy.frame(in: .named(coordinateSpace))])
                    })
                    .contentShape(Rectangle())
                    .onLongPressGesture { onMessageLongPress?(msg) }
            }
        }
    }

    private func isGroupStart(_ i: Int) -> Bool {
        guard i > 0 else { return true }
        let prev = messages[i - 1], cur = messages[i]
        return prev.senderId != cur.senderId || prev.isSystem || cur.isSystem
    }

    private func isGroupEnd(_ i: Int) -> Bool {
        guard i < messages.count - 1 else { return true }
        let next = messages[i + 1], cur = messages[i]
        return next.senderId != cur.senderId || next.isSystem || cur.isSystem
    }
}

private struct TimelineRowFrames: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) { value.merge(nextValue(), uniquingKeysWith: { _, new in new }) }
}
