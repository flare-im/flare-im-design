import SwiftUI

/// Which system permission the prompt explains. Spec: General/PermissionPrompt.
public enum FlarePermissionKind: String, CaseIterable, Sendable {
    case microphone, camera, notifications, storage, photos, contacts, location, screen
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
    case .screen: return "devices"
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
                                  featureLabel: String? = nil,
                                  strings: FlareStrings = FlareStrings()) -> FlarePermissionCopy {
    let trimmed = featureLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let feature = trimmed.isEmpty ? strings.permissionFeatureFallback : trimmed
    let verb = strings.permissionVerb(kind)
    let title = strings.permissionTitle(strings.permissionNoun(kind))
    switch state {
    case .undetermined:
        return FlarePermissionCopy(title: title, description: strings.permissionUndeterminedBody(feature, verb),
                                   primaryLabel: strings.permissionAllow)
    case .denied:
        return FlarePermissionCopy(title: title, description: strings.permissionDeniedBody(feature, verb),
                                   primaryLabel: strings.permissionOpenSettings)
    case .restricted:
        return FlarePermissionCopy(title: title, description: strings.permissionRestrictedBody(feature, verb), primaryLabel: "")
    case .unavailable:
        return FlarePermissionCopy(title: title, description: strings.permissionUnavailableBody(feature, verb), primaryLabel: "")
    }
}

public func defaultPermissionStateLabel(_ state: FlarePermissionState,
                                        strings: FlareStrings = FlareStrings()) -> String {
    strings.permissionStateLabel(state)
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
    private let dismissText: String?
    private let onRequest: (() -> Void)?
    private let onOpenSettings: (() -> Void)?
    private let onDismiss: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareStrings) private var strings
    @ScaledMetric private var titleSize: CGFloat = FlareSizes.fontSizeXl
    @ScaledMetric private var bodySize: CGFloat = FlareSizes.fontSizeMd

    public init(kind: FlarePermissionKind, state: FlarePermissionState, featureLabel: String? = nil,
                detail: String? = nil, busy: Bool = false, compact: Bool = false,
                title: String? = nil, description: String? = nil, stateText: String? = nil,
                requestText: String? = nil, openSettingsText: String? = nil, dismissText: String? = nil,
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
        let copy = defaultPermissionCopy(kind, state, featureLabel: featureLabel, strings: strings)
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
                    Text(stateText ?? defaultPermissionStateLabel(state, strings: strings))
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
                    Text(dismissText ?? strings.permissionDismiss)
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
