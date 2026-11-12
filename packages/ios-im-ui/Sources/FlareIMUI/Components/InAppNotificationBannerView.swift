import SwiftUI

/// The banner for a message that arrived while the app is open on another screen.
/// Spec: Feedback/InAppNotificationBanner (`InAppNotificationBannerView`).
///
/// Avatar (the host's `avatarURL`, else the title's initials coloured by the conversation), the title and one line of
/// preview, both truncated; above one message the kit's "[3条]" goes before the body, and mentions / urgent put their
/// tag before it with an accent. A tap opens: `onOpen(conversationId, messageId)`. A swipe up past a short distance or
/// the close key dismisses (`onDismiss`); VoiceOver reads the banner as one button with a Close action and the escape
/// gesture. ``InAppNotificationHost`` places the banner, queues the next ones and runs its time.
public struct InAppNotificationBannerView: View {
    private let notification: FlareInAppNotification
    private let onOpen: ((_ conversationId: String, _ messageId: String?) -> Void)?
    private let onDismiss: (() -> Void)?
    @Environment(\.flareStrings) private var strings
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var offset: CGFloat = 0

    /// How far up a swipe has to travel before it dismisses the banner.
    static let swipeDismissDistance: CGFloat = 24
    /// The avatar, the same on the four kits.
    static let avatarSize: CGFloat = 40

    public init(notification: FlareInAppNotification,
                onOpen: ((_ conversationId: String, _ messageId: String?) -> Void)? = nil,
                onDismiss: (() -> Void)? = nil) {
        self.notification = notification; self.onOpen = onOpen; self.onDismiss = onDismiss
    }

    private func open() {
        onOpen?(notification.conversationId, notification.messageId)
    }

    /// The tag, the count and the preview on one line.
    private func bodyLine(_ colors: FlareColors) -> Text {
        var line = Text("")
        if let tag = notification.tag(strings) {
            line = line + Text(tag + " ")
                .fontWeight(.semibold)
                .foregroundColor(notification.channel == .urgent ? colors.errorText : colors.primaryText)
        }
        if notification.showsCount {
            line = line + Text(strings.inAppNotificationCount(notification.count) + " ")
        }
        return line + Text(notification.body)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusXl, style: .continuous)
        HStack(spacing: FlareSizes.spacingMd) {
            AvatarView(userId: notification.conversationId, displayName: notification.title,
                       avatarURL: notification.avatarURL, size: Self.avatarSize)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: FlareSizes.spacing3xs) {
                Text(notification.title)
                    .font(.system(size: FlareSizes.fontSizeLg, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                bodyLine(colors)
                    .font(.system(size: FlareSizes.fontSizeMd))
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            SwiftUI.Button { onDismiss?() } label: {
                IconView("close", size: FlareSizes.iconSizeSm, color: colors.textTertiary)
                    .frame(minWidth: FlareSizes.touchTarget, minHeight: FlareSizes.touchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(strings.close)
        }
        .padding(FlareSizes.spacingSm)
        .background(shape.fill(colors.bgElevated))
        .overlay(shape.stroke(notification.channel == .urgent ? colors.error : colors.borderSecondary, lineWidth: 1))
        .flareShadow(FlareShadows.of(scheme).lg)
        .contentShape(Rectangle())
        .offset(y: offset)
        .onTapGesture(perform: open)
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { offset = min(0, $0.translation.height) }
                .onEnded { _ in
                    let dismissed = offset <= -Self.swipeDismissDistance
                    withAnimation(reduceMotion ? nil : FlareMotion.fastAnimation) { offset = 0 }
                    if dismissed { onDismiss?() }
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(notification.spoken(strings))
        .accessibilityHint(strings.inAppNotificationOpenHint)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { open() }
        .accessibilityAction(.escape) { onDismiss?() }
        .accessibilityAction(named: strings.close) { onDismiss?() }
    }
}

/// Puts the in-app new-message banner on screen. Spec: Feedback/InAppNotificationHost (`InAppNotificationHost`).
///
/// Wrap the app content and feed `notifications` from the engine's `notification.present` (surface `inApp`) and
/// `notification.clear` events:
///
/// ```swift
/// @StateObject private var inApp = FlareInAppNotifications()
///
/// InAppNotificationHost(notifications: inApp, onOpen: { conversationId, _ in router.openChat(conversationId) }) {
///     RootView()
/// }
/// ```
///
/// The presenter decides what shows and what waits (spec/in-app-notification-vectors.json); the host owns the time:
/// each banner stays ``inAppNotificationDuration`` after it shows or is replaced, the time stops while a finger is on
/// it and starts over when it lifts, and while VoiceOver runs the banner stays until it is dismissed, replaced or
/// cleared. Opening dismisses the banner and calls `onOpen`. Each banner that shows is announced once. The banner sits
/// at the top centre under the safe area, at most the kit's auth form width wide; with Reduce Motion it fades instead
/// of sliding.
public struct InAppNotificationHost<Content: View>: View {
    @ObservedObject private var notifications: FlareInAppNotifications
    private let onOpen: ((_ conversationId: String, _ messageId: String?) -> Void)?
    private let content: Content
    @Environment(\.flareStrings) private var strings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    /// The banner a finger is on, by collapse id: a different banner that takes its place runs its own time.
    @State private var pressed: String?

    public init(notifications: FlareInAppNotifications,
                onOpen: ((_ conversationId: String, _ messageId: String?) -> Void)? = nil,
                @ViewBuilder content: () -> Content) {
        self._notifications = ObservedObject(wrappedValue: notifications); self.onOpen = onOpen; self.content = content()
    }

    private var held: Bool {
        guard let shown = notifications.current else { return false }
        return pressed == shown.collapseId
    }

    /// What the visible banner's time depends on: it starts over whenever this changes.
    private struct Clock: Equatable {
        let revision: Int
        let showing: Bool
        let held: Bool
        let voiceOver: Bool
    }

    private var clock: Clock {
        Clock(revision: notifications.revision, showing: notifications.current != nil, held: held, voiceOver: voiceOver)
    }

    /// The visible banner's time: it goes once the time is up, unless it is held or VoiceOver runs.
    @MainActor private func run(_ clock: Clock) async {
        guard clock.showing, !clock.held, !clock.voiceOver else { return }
        try? await Task.sleep(nanoseconds: UInt64(inAppNotificationDuration * 1_000_000_000))
        guard !Task.isCancelled else { return }
        notifications.dismiss()
    }

    public var body: some View {
        let clock = self.clock
        return content
            .overlay(alignment: .top) {
                ZStack {
                    if let shown = notifications.current {
                        InAppNotificationBannerView(
                            notification: shown,
                            onOpen: { conversationId, messageId in
                                notifications.dismiss()
                                onOpen?(conversationId, messageId)
                            },
                            onDismiss: { notifications.dismiss() }
                        )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in pressed = shown.collapseId }
                                .onEnded { _ in pressed = nil }
                        )
                        .id(shown.collapseId)
                        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: FlareSizes.authFormMaxWidth)
                .padding(.horizontal, FlareSizes.spacingMd)
                .padding(.top, FlareSizes.spacingSm)
                .animation(reduceMotion ? nil : FlareMotion.normalAnimation, value: notifications.current?.collapseId)
            }
            .task(id: clock) { await run(clock) }
            .onChange(of: notifications.revision) { _ in
                if let shown = notifications.current { flareAnnounce(shown.spoken(strings)) }
            }
    }
}
