import SwiftUI

/// The connection notice an app shell places once, above every tab. Spec: IM/ConnectionNotice
/// (`ConnectionNoticeView`).
///
/// The host hands in the core SDK's connection status (`connection://status`) as it arrives; what shows
/// when is ``FlareConnectionNoticeTracker``'s call (`spec/connection-notice-vectors.json`, the same in
/// every kit). The view feeds it the status, wakes when the presentation can next change (a delay ends,
/// the countdown turns over, a hold ends) and draws the banner with ``StatusBannerView``. An action is
/// drawn only when the host passes its handler. The message is announced when it changes; the countdown
/// is not re-announced every second.
public struct ConnectionNoticeView: View {
    private let status: FlareConnectionStatus?
    private let floating: Bool
    private let onRetry: (() -> Void)?
    private let onSignIn: (() -> Void)?
    private let onUpdate: (() -> Void)?
    private let onDiagnose: (() -> Void)?
    @Environment(\.flareStrings) private var strings
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @State private var tracker = FlareConnectionNoticeTracker()
    @State private var model = FlareConnectionNoticeModel.hidden

    /// - Parameters:
    ///   - status: the latest `connection://status`; nil before the SDK has reported one.
    ///   - floating: hang the banner over the content (``StatusBannerView`` `floating`).
    ///   - onRetry: reconnect now (the SDK's `connection.reconnectNow`), offered while reconnecting.
    ///   - onSignIn: sign in again, offered when the session was kicked or expired.
    ///   - onUpdate: open the app update, offered when the server requires a newer app.
    ///   - onDiagnose: open the network diagnostics, offered while the service is unavailable.
    public init(status: FlareConnectionStatus?, floating: Bool = false, onRetry: (() -> Void)? = nil,
                onSignIn: (() -> Void)? = nil, onUpdate: (() -> Void)? = nil, onDiagnose: (() -> Void)? = nil) {
        self.status = status; self.floating = floating
        self.onRetry = onRetry; self.onSignIn = onSignIn; self.onUpdate = onUpdate; self.onDiagnose = onDiagnose
    }

    private func handler(_ action: FlareConnectionNoticeAction?) -> (() -> Void)? {
        switch action {
        case .retry: return onRetry
        case .signIn: return onSignIn
        case .update: return onUpdate
        case .diagnose: return onDiagnose
        case nil: return nil
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let perform = handler(model.action)
        VStack(alignment: .trailing, spacing: FlareSizes.spacingXs) {
            if model.badge {
                Text(strings.connectionDevelopmentMode)
                    .font(.system(size: FlareSizes.fontSizeXs, weight: .medium))
                    .foregroundColor(colors.warningText)
                    .padding(.horizontal, FlareSizes.spacingSm)
                    .padding(.vertical, FlareSizes.spacing3xs)
                    .background(Capsule().fill(colors.warning.opacity(0.10)))
            }
            if model.visible {
                StatusBannerView(text: model.bannerText(strings), tone: model.tone ?? .info, pulse: model.pulse,
                                 actionText: perform == nil ? nil : model.action?.label(strings),
                                 onAction: perform, floating: floating)
            }
        }
        .task(id: status) { await follow(status) }
        .onChange(of: model.visible ? model.message(strings) : nil) { message in
            if let message { flareAnnounce(message) }
        }
    }

    /// Observes `status`, then redraws whenever the presentation turns over until the next status arrives.
    private func follow(_ status: FlareConnectionStatus?) async {
        tracker.observe(status ?? FlareConnectionStatus(phase: .idle), nowMs: Self.nowMs())
        while !Task.isCancelled {
            let now = Self.nowMs()
            let next = tracker.present(nowMs: now)
            if next != model { model = next }
            guard let wake = tracker.nextChangeAt(nowMs: now) else { return }
            try? await Task.sleep(nanoseconds: UInt64(max(0, wake - now)) * 1_000_000)
        }
    }

    private static func nowMs() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000) }
}
