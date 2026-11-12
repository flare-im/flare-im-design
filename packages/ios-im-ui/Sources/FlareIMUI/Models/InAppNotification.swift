import Foundation

/// How strongly a new message asks for attention: the engine's notification channel.
public enum FlareInAppNotificationChannel: String, CaseIterable, Sendable {
    case messages, quiet, mentions, urgent
}

/// A message that arrived while the app is open on another screen, as the host maps it from the engine's
/// `notification.present` (surface `inApp`). Spec: InAppNotificationBanner / InAppNotificationHost.
///
/// `collapseId`: one banner per collapse id, a newer item replaces the shown or waiting one in place. `count` above 1
/// puts the kit's "[3条]" before the body; `channel` mentions and urgent carry a tag and an accent; without
/// `avatarURL` the avatar shows the initials of `title`.
public struct FlareInAppNotification: Equatable, Sendable {
    public let collapseId: String
    public let conversationId: String
    public let messageId: String?
    public let title: String
    public let body: String
    public let count: Int
    public let channel: FlareInAppNotificationChannel
    public let avatarURL: String?

    public init(collapseId: String, conversationId: String, messageId: String? = nil, title: String, body: String,
                count: Int = 1, channel: FlareInAppNotificationChannel = .messages, avatarURL: String? = nil) {
        self.collapseId = collapseId; self.conversationId = conversationId; self.messageId = messageId
        self.title = title; self.body = body; self.count = count; self.channel = channel; self.avatarURL = avatarURL
    }

    /// Whether the count goes before the body: only above one message.
    public var showsCount: Bool { count > 1 }

    /// The tag before the body in `strings`, or nil for the plain channels.
    public func tag(_ strings: FlareStrings = FlareStrings()) -> String? {
        switch channel {
        case .mentions: return strings.inAppNotificationMention
        case .urgent: return strings.inAppNotificationUrgent
        case .messages, .quiet: return nil
        }
    }

    /// What a reader hears: New message, the title, the tag, the count and the body.
    public func spoken(_ strings: FlareStrings = FlareStrings()) -> String {
        [strings.inAppNotificationLabel, title, tag(strings), showsCount ? strings.inAppNotificationCount(count) : nil, body]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

/// How long a banner stays after it shows or is replaced, and again after a touch on it ends, in seconds.
public let inAppNotificationDuration: TimeInterval = 4

/// Banners waiting behind the visible one; beyond this the oldest waiting one is dropped, so the newest win.
public let inAppNotificationPendingLimit = 3

/// The presenter of the in-app new-message banner: the app feeds it and ``InAppNotificationHost`` draws it.
///
/// The app forwards the engine's `notification.present` events whose surface is `inApp` to ``present(_:)`` and its
/// `notification.clear` events to ``clear(_:)`` / ``clearAll()``. What shows and what waits follows
/// spec/in-app-notification-vectors.json; the host owns the time on screen and starts it over whenever ``revision``
/// moves. Own one at the app root.
@MainActor
public final class FlareInAppNotifications: ObservableObject {
    /// The visible banner.
    @Published public private(set) var current: FlareInAppNotification?
    /// Banners waiting, oldest first, at most ``inAppNotificationPendingLimit``.
    @Published public private(set) var pending: [FlareInAppNotification] = []
    /// Moves whenever a banner shows or the visible one is replaced.
    @Published public private(set) var revision = 0

    public init() {}

    /// Shows, replaces or queues `notification`.
    public func present(_ notification: FlareInAppNotification) {
        if current == nil || current?.collapseId == notification.collapseId {
            current = notification
            revision += 1
            return
        }
        if let waiting = pending.firstIndex(where: { $0.collapseId == notification.collapseId }) {
            pending[waiting] = notification
            return
        }
        pending = Array((pending + [notification]).suffix(inAppNotificationPendingLimit))
    }

    /// The visible banner goes and the first waiting one shows.
    public func dismiss() {
        guard current != nil || !pending.isEmpty else { return }
        let next = pending.first
        current = next
        pending = Array(pending.dropFirst())
        if next != nil { revision += 1 }
    }

    /// Takes away the banners of `collapseIds`; the visible one goes as ``dismiss()`` says.
    public func clear(_ collapseIds: [String]) {
        guard !collapseIds.isEmpty else { return }
        let ids = Set(collapseIds)
        pending.removeAll { ids.contains($0.collapseId) }
        if let shown = current, ids.contains(shown.collapseId) { dismiss() }
    }

    /// Takes every banner away.
    public func clearAll() {
        current = nil
        pending = []
    }
}
