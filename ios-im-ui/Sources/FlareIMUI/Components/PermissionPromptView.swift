import SwiftUI

/// Which system permission the prompt explains. Spec: General/PermissionPrompt.
public enum FlarePermissionKind: String, CaseIterable, Sendable {
    case microphone, camera, notifications, storage, photos, contacts, location
}

/// Host-reported permission state; the view never queries the platform.
public enum FlarePermissionState: String, CaseIterable, Sendable {
    case undetermined, denied, restricted, unavailable
}

/// Action visibility computed from state + which callbacks the host supplied.
public struct FlarePermissionActions: Equatable, Sendable {
    /// Visible only while undetermined and the host supplied a handler.
    public let request: Bool
    /// Visible only while denied and the host supplied a handler.
    public let openSettings: Bool
    /// Visible whenever the host supplied a handler (any state).
    public let dismiss: Bool
    /// false while busy: visible actions stay rendered but disabled.
    public let enabled: Bool
    public init(request: Bool, openSettings: Bool, dismiss: Bool, enabled: Bool) {
        self.request = request; self.openSettings = openSettings; self.dismiss = dismiss; self.enabled = enabled
    }
}

public func permissionActions(_ state: FlarePermissionState, hasRequest: Bool, hasOpenSettings: Bool,
                              hasDismiss: Bool, busy: Bool = false) -> FlarePermissionActions {
    FlarePermissionActions(
        request: state == .undetermined && hasRequest,
        openSettings: state == .denied && hasOpenSettings,
        dismiss: hasDismiss,
        enabled: !busy
    )
}

/// Default copy for a kind + state pair.
public struct FlarePermissionCopy: Equatable, Sendable {
    public let title: String
    public let description: String
    public let primaryLabel: String
    public init(title: String, description: String, primaryLabel: String) {
        self.title = title; self.description = description; self.primaryLabel = primaryLabel
    }
}

private func kindNoun(_ kind: FlarePermissionKind) -> String {
    switch kind {
    case .microphone: return "麦克风"
    case .camera: return "摄像头"
    case .notifications: return "通知"
    case .storage: return "存储空间"
    case .photos: return "相册"
    case .contacts: return "通讯录"
    case .location: return "位置信息"
    }
}

private func kindVerb(_ kind: FlarePermissionKind) -> String {
    switch kind {
    case .microphone: return "使用麦克风"
    case .camera: return "使用摄像头"
    case .notifications: return "发送通知"
    case .storage: return "访问存储空间"
    case .photos: return "访问相册"
    case .contacts: return "访问通讯录"
    case .location: return "获取位置信息"
    }
}

/// Kit icon name per kind (resolved through `IconView`, same names on every platform).
public func permissionIconName(_ kind: FlarePermissionKind) -> String {
    switch kind {
    case .microphone: return "mic"
    case .camera: return "camera"
    case .notifications: return "notification"
    case .storage: return "folder"
    case .photos: return "image"
    case .contacts: return "people"
    case .location: return "location"
    }
}

/// State glyph so status never relies on colour alone.
public func permissionStateIconName(_ state: FlarePermissionState) -> String {
    switch state {
    case .undetermined: return "info"
    case .denied: return "block"
    case .restricted: return "lock"
    case .unavailable: return "warning"
    }
}

/// `featureLabel` (e.g. "发送语音消息") is embedded in the description.
public func defaultPermissionCopy(_ kind: FlarePermissionKind, _ state: FlarePermissionState,
                                  featureLabel: String? = nil) -> FlarePermissionCopy {
    let trimmed = featureLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let feature = trimmed.isEmpty ? "此功能" : trimmed
    let verb = kindVerb(kind)
    let title = "需要\(kindNoun(kind))权限"
    switch state {
    case .undetermined:
        return FlarePermissionCopy(title: title, description: "\(feature)需要\(verb)，请允许后继续。", primaryLabel: "允许")
    case .denied:
        return FlarePermissionCopy(title: title, description: "\(verb)的权限已被拒绝，\(feature)无法使用。请前往系统设置开启。", primaryLabel: "前往设置")
    case .restricted:
        return FlarePermissionCopy(title: title, description: "\(verb)的权限受设备或组织策略限制，\(feature)暂不可用。", primaryLabel: "")
    case .unavailable:
        return FlarePermissionCopy(title: title, description: "当前设备或运行环境不支持\(verb)，\(feature)暂不可用。", primaryLabel: "")
    }
}

public func defaultPermissionStateLabel(_ state: FlarePermissionState) -> String {
    switch state {
    case .undetermined: return "未授权"
    case .denied: return "已拒绝"
    case .restricted: return "受限制"
    case .unavailable: return "不可用"
    }
}

/// Unified "permission missing / denied" panel. The host owns the real permission
/// state and the request / openSettings side effects; this view only explains and
/// dispatches. Spec: General/PermissionPrompt (`PermissionPromptView`).
public struct PermissionPromptView: View {
    private let kind: FlarePermissionKind
    private let state: FlarePermissionState
    private let featureLabel: String?
    private let detail: String?
    private let busy: Bool
    private let compact: Bool
    private let title: String?
    private let description: String?
    private let stateText: String?
    private let requestText: String?
    private let openSettingsText: String?
    private let dismissText: String
    private let onRequest: (() -> Void)?
    private let onOpenSettings: (() -> Void)?
    private let onDismiss: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @ScaledMetric private var titleSize: CGFloat = FlareSizes.fontSizeXl
    @ScaledMetric private var bodySize: CGFloat = FlareSizes.fontSizeMd

    public init(kind: FlarePermissionKind, state: FlarePermissionState, featureLabel: String? = nil,
                detail: String? = nil, busy: Bool = false, compact: Bool = false,
                title: String? = nil, description: String? = nil, stateText: String? = nil,
                requestText: String? = nil, openSettingsText: String? = nil, dismissText: String = "知道了",
                onRequest: (() -> Void)? = nil, onOpenSettings: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.kind = kind; self.state = state; self.featureLabel = featureLabel; self.detail = detail
        self.busy = busy; self.compact = compact; self.title = title; self.description = description
        self.stateText = stateText; self.requestText = requestText; self.openSettingsText = openSettingsText
        self.dismissText = dismissText; self.onRequest = onRequest; self.onOpenSettings = onOpenSettings; self.onDismiss = onDismiss
    }

    private func tone(_ colors: FlareColors) -> Color {
        switch state {
        case .undetermined: return colors.info
        case .denied: return colors.error
        case .restricted: return colors.warning
        case .unavailable: return colors.textSecondary
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let copy = defaultPermissionCopy(kind, state, featureLabel: featureLabel)
        let actions = permissionActions(state, hasRequest: onRequest != nil, hasOpenSettings: onOpenSettings != nil,
                                        hasDismiss: onDismiss != nil, busy: busy)
        let resolvedTitle = title ?? copy.title
        let hasActions = actions.request || actions.openSettings || actions.dismiss
        Group {
            if compact {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: FlareSizes.spacingMd) {
                        icon(colors)
                        textBlock(colors, copy: copy, title: resolvedTitle)
                        if hasActions { actionRow(colors, copy: copy, actions: actions) }
                    }
                    VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
                        HStack(alignment: .center, spacing: FlareSizes.spacingMd) {
                            icon(colors)
                            textBlock(colors, copy: copy, title: resolvedTitle)
                        }
                        if hasActions { actionRow(colors, copy: copy, actions: actions) }
                    }
                }
            } else {
                HStack(alignment: .top, spacing: FlareSizes.spacingMd) {
                    icon(colors)
                    VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
                        textBlock(colors, copy: copy, title: resolvedTitle)
                        if hasActions { actionRow(colors, copy: copy, actions: actions) }
                    }
                }
            }
        }
        .padding(.horizontal, compact ? FlareSizes.spacingMd : FlareSizes.spacingLg)
        .padding(.vertical, compact ? FlareSizes.spacingSm : FlareSizes.spacingLg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: compact ? FlareSizes.radiusMd : FlareSizes.radiusLg).fill(colors.bgSecondary))
        .overlay(
            RoundedRectangle(cornerRadius: compact ? FlareSizes.radiusMd : FlareSizes.radiusLg)
                .stroke(compact ? colors.borderSecondary : .clear, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(resolvedTitle)
    }

    private func icon(_ colors: FlareColors) -> some View {
        let side: CGFloat = compact ? 32 : 44
        return ZStack {
            Circle().fill(colors.primary.opacity(0.12))
            IconView(permissionIconName(kind), size: compact ? 20 : 26, color: colors.primary)
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }

    private func textBlock(_ colors: FlareColors, copy: FlarePermissionCopy, title: String) -> some View {
        let tint = tone(colors)
        return VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            HStack(alignment: .center, spacing: FlareSizes.spacingSm) {
                Text(title)
                    .font(.system(size: compact ? FlareSizes.fontSizeLg : titleSize, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: FlareSizes.spacingXs) {
                    IconView(permissionStateIconName(state), size: 12, color: tint)
                    Text(stateText ?? defaultPermissionStateLabel(state))
                        .font(.system(size: FlareSizes.fontSizeXs, weight: .semibold))
                        .foregroundColor(tint)
                }
                .padding(.horizontal, FlareSizes.spacingSm)
                .padding(.vertical, 2)
                .background(Capsule().fill(tint.opacity(0.12)))
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.updatesFrequently)
            }
            Text(description ?? copy.description)
                .font(.system(size: compact ? FlareSizes.fontSizeSm : bodySize))
                .foregroundColor(colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(.system(size: FlareSizes.fontSizeSm))
                    .foregroundColor(colors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionRow(_ colors: FlareColors, copy: FlarePermissionCopy, actions: FlarePermissionActions) -> some View {
        HStack(spacing: FlareSizes.spacingSm) {
            if actions.request, let onRequest {
                PrimaryButtonView(requestText ?? copy.primaryLabel, loading: busy, action: onRequest)
                    .frame(maxWidth: 240)
            }
            if actions.openSettings, let onOpenSettings {
                PrimaryButtonView(openSettingsText ?? copy.primaryLabel, loading: busy, action: onOpenSettings)
                    .frame(maxWidth: 240)
            }
            if actions.dismiss, let onDismiss {
                Button(action: onDismiss) {
                    Text(dismissText)
                        .font(.system(size: FlareSizes.fontSizeXl, weight: .semibold))
                        .foregroundColor(colors.textPrimary)
                        .padding(.horizontal, FlareSizes.spacingLg)
                        .frame(minWidth: 48, minHeight: 48)
                        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.borderPrimary, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(!actions.enabled)
                .opacity(actions.enabled ? 1 : 0.55)
            }
        }
    }
}
