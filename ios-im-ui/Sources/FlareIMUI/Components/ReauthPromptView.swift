import SwiftUI

/// Why the current session can no longer be used. Supplied by the host session layer.
public enum FlareReauthReason: String, CaseIterable, Sendable {
    case sessionExpired, kicked, credentialInvalid, accountDisabled
}

/// Semantic tone of the reason glyph (never the only signal: the text always names the reason).
public enum FlareReauthTone: String, Sendable { case info, warning, danger }

public func reauthTone(_ reason: FlareReauthReason) -> FlareReauthTone {
    switch reason {
    case .sessionExpired: return .info
    case .kicked, .credentialInvalid: return .warning
    case .accountDisabled: return .danger
    }
}

/// Semantic icon name (shared `IconView` library) for each reason.
public func reauthIcon(_ reason: FlareReauthReason) -> String {
    switch reason {
    case .sessionExpired: return "clock"
    case .kicked: return "devices"
    case .credentialInvalid: return "lock"
    case .accountDisabled: return "block"
    }
}

public struct FlareReauthActionState: Equatable, Sendable {
    public let visible: Bool
    public let enabled: Bool
    public init(visible: Bool, enabled: Bool) { self.visible = visible; self.enabled = enabled }
}

public struct FlareReauthActions: Equatable, Sendable {
    public let reauthenticate: FlareReauthActionState
    public let logout: FlareReauthActionState
    /// True when Enter should trigger re-authentication; false when it is unavailable.
    public let primary: Bool
}

/// Which actions to show and whether they are enabled.
/// - reauthenticate needs a host handler and is never offered for a disabled account.
/// - logout needs a host handler.
/// - busy locks every action; the host sets it synchronously before dispatching.
public func reauthActions(_ reason: FlareReauthReason, hasReauth: Bool, hasLogout: Bool, busy: Bool = false) -> FlareReauthActions {
    let reauthVisible = hasReauth && reason != .accountDisabled
    return FlareReauthActions(
        reauthenticate: FlareReauthActionState(visible: reauthVisible, enabled: reauthVisible && !busy),
        logout: FlareReauthActionState(visible: hasLogout, enabled: hasLogout && !busy),
        primary: reauthVisible
    )
}

/// Re-authentication prompt shown when the session can no longer be used.
/// The host owns the login flow and the container (full-screen overlay or sheet);
/// this panel names the reason, locks repeat submits, keeps the last failure visible
/// and dispatches `onReauthenticate` / `onLogout`. Buttons whose callback is nil are
/// not rendered. Return triggers the primary action; interactive dismissal is disabled
/// because a broken session cannot be ignored. Spec: General/ReauthPrompt (`ReauthPromptView`).
public struct ReauthPromptView: View {
    private let reason: FlareReauthReason
    private let detail: String?
    private let busy: Bool
    private let error: String?
    private let accountLabel: String?
    private let title: String
    private let sessionExpiredText: String
    private let kickedText: String
    private let credentialInvalidText: String
    private let accountDisabledText: String
    private let reauthenticateText: String
    private let busyText: String
    private let logoutText: String
    private let accountCaption: String
    private let onReauthenticate: (() -> Void)?
    private let onLogout: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @ScaledMetric private var titleSize: CGFloat = FlareSizes.fontSize3xl
    @ScaledMetric private var bodySize: CGFloat = FlareSizes.fontSizeLg
    @ScaledMetric private var detailSize: CGFloat = FlareSizes.fontSizeMd
    @ScaledMetric private var captionSize: CGFloat = FlareSizes.fontSizeSm

    public init(reason: FlareReauthReason, detail: String? = nil, busy: Bool = false, error: String? = nil,
                accountLabel: String? = nil, title: String = "需要重新登录",
                sessionExpiredText: String = "登录状态已过期，请重新登录后继续。",
                kickedText: String = "你的账号已在其它设备登录，当前设备已下线。",
                credentialInvalidText: String = "登录凭证已失效，请重新登录。",
                accountDisabledText: String = "账号已被停用，暂时无法登录，请联系管理员。",
                reauthenticateText: String = "重新登录", busyText: String = "正在重新登录…",
                logoutText: String = "退出登录", accountCaption: String = "当前账号",
                onReauthenticate: (() -> Void)? = nil, onLogout: (() -> Void)? = nil) {
        self.reason = reason; self.detail = detail; self.busy = busy; self.error = error
        self.accountLabel = accountLabel; self.title = title
        self.sessionExpiredText = sessionExpiredText; self.kickedText = kickedText
        self.credentialInvalidText = credentialInvalidText; self.accountDisabledText = accountDisabledText
        self.reauthenticateText = reauthenticateText; self.busyText = busyText
        self.logoutText = logoutText; self.accountCaption = accountCaption
        self.onReauthenticate = onReauthenticate; self.onLogout = onLogout
    }

    private var reasonText: String {
        switch reason {
        case .sessionExpired: return sessionExpiredText
        case .kicked: return kickedText
        case .credentialInvalid: return credentialInvalidText
        case .accountDisabled: return accountDisabledText
        }
    }

    private func toneColor(_ colors: FlareColors) -> Color {
        switch reauthTone(reason) {
        case .info: return colors.info
        case .warning: return colors.warning
        case .danger: return colors.error
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let tint = toneColor(colors)
        let actions = reauthActions(reason, hasReauth: onReauthenticate != nil, hasLogout: onLogout != nil, busy: busy)
        VStack(spacing: FlareSizes.spacingSm) {
            ZStack {
                Circle().fill(tint.opacity(0.12)).frame(width: 56, height: 56)
                IconView(reauthIcon(reason), size: 28, color: tint)
            }
            .accessibilityHidden(true)
            .padding(.bottom, FlareSizes.spacingSm)
            Text(title)
                .font(.system(size: titleSize, weight: .semibold))
                .foregroundColor(colors.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(reasonText)
                .font(.system(size: bodySize))
                .foregroundColor(colors.textPrimary)
                .multilineTextAlignment(.center)
            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(.system(size: detailSize))
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let accountLabel, !accountLabel.isEmpty {
                HStack(spacing: 6) {
                    Text(accountCaption).foregroundColor(colors.textSecondary)
                    Text(accountLabel).fontWeight(.semibold).foregroundColor(colors.textPrimary).lineLimit(1).truncationMode(.middle)
                }
                .font(.system(size: captionSize))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(colors.bgSecondary))
                .padding(.top, FlareSizes.spacingXs)
                .accessibilityElement(children: .combine)
            }
            if let error, !error.isEmpty {
                StatusBannerView(text: error, tone: .danger)
                    .padding(.top, FlareSizes.spacingXs)
                    .accessibilityAddTraits(.updatesFrequently)
            }
            if actions.reauthenticate.visible || actions.logout.visible {
                VStack(spacing: FlareSizes.spacingSm) {
                    if actions.reauthenticate.visible {
                        PrimaryButtonView(reauthenticateText, loading: busy, loadingLabel: busyText,
                                          disabled: !actions.reauthenticate.enabled) {
                            if actions.reauthenticate.enabled { onReauthenticate?() }
                        }
                        .keyboardShortcut(.defaultAction)
                        .accessibilityLabel(busy ? busyText : reauthenticateText)
                    }
                    if actions.logout.visible {
                        ButtonView(label: logoutText, variant: .secondary, size: .lg,
                                   disabled: !actions.logout.enabled, block: true) {
                            if actions.logout.enabled { onLogout?() }
                        }
                    }
                }
                .padding(.top, FlareSizes.spacingMd)
            }
        }
        .padding(.horizontal, FlareSizes.spacingXl)
        .padding(.vertical, FlareSizes.spacing2xl)
        .frame(maxWidth: 400)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary))
        .interactiveDismissDisabled(true)
    }
}
