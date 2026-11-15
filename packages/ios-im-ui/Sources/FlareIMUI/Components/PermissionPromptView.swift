import SwiftUI

/// Which system permission the prompt explains. Spec: General/PermissionPrompt.
public enum FlarePermissionKind: String, CaseIterable, Sendable {
    case microphone, camera, notifications, storage, photos, contacts, location, screen
}

/// Host-reported permission state; the view never queries the platform. `granted` lets a host bind the
/// platform's permission status directly: the prompt renders nothing for it.
public enum FlarePermissionState: String, CaseIterable, Sendable {
    case undetermined, denied, restricted, unavailable, granted
}

/// Whether the prompt draws anything. Nothing for `granted`. A soft-ask is an invitation the person can act on,
/// so it shows only while the permission can be asked for (`undetermined`) or turned on in settings (`denied`).
public func permissionPromptShows(_ state: FlarePermissionState, softAsk: Bool = false) -> Bool {
    switch state {
    case .granted: return false
    case .undetermined, .denied: return true
    case .restricted, .unavailable: return !softAsk
    }
}

/// Action visibility computed from state + which callbacks the host supplied.
public struct FlarePermissionActions: Equatable, Sendable {
    /// Visible only while undetermined and the host supplied a handler.
    public let request: Bool
    /// Visible only while denied and the host supplied a handler.
    public let openSettings: Bool
    /// Visible whenever the host supplied a handler and the prompt shows.
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
        dismiss: state != .granted && hasDismiss,
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
    case .storage: return "storage"
    case .photos: return "image"
    case .contacts: return "people"
    case .location: return "location"
    case .screen: return "screen-share"
    }
}

/// State glyph so status never relies on colour alone.
public func permissionStateIconName(_ state: FlarePermissionState) -> String {
    switch state {
    case .undetermined: return "info"
    case .denied: return "error"
    case .restricted: return "lock"
    case .unavailable: return "warning"
    case .granted: return "success"
    }
}

/// `featureLabel` (e.g. "发送语音消息") is embedded in the description. `granted` has nothing to explain: an empty
/// description and no primary action.
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
    case .granted:
        return FlarePermissionCopy(title: title, description: "", primaryLabel: "")
    }
}

/// The copy of a soft-ask (`PermissionPromptView(softAsk: true)`). The notifications kind has its own: an
/// invitation titled for new messages, "Turn on notifications" while the system can still ask and, once
/// notifications were turned off, "Open Settings" with where to turn them back on. Any other kind keeps
/// ``defaultPermissionCopy(_:_:featureLabel:strings:)``.
public func defaultPermissionSoftAskCopy(_ kind: FlarePermissionKind, _ state: FlarePermissionState,
                                         featureLabel: String? = nil,
                                         strings: FlareStrings = FlareStrings()) -> FlarePermissionCopy {
    guard kind == .notifications else {
        return defaultPermissionCopy(kind, state, featureLabel: featureLabel, strings: strings)
    }
    let title = strings.permissionSoftAskNotificationsTitle
    switch state {
    case .undetermined:
        return FlarePermissionCopy(title: title, description: strings.permissionSoftAskNotificationsBody,
                                   primaryLabel: strings.permissionSoftAskNotificationsAction)
    case .denied:
        return FlarePermissionCopy(title: title, description: strings.permissionSoftAskNotificationsDeniedBody,
                                   primaryLabel: strings.permissionOpenSettings)
    case .restricted, .unavailable, .granted:
        return defaultPermissionCopy(kind, state, featureLabel: featureLabel, strings: strings)
    }
}

public func defaultPermissionStateLabel(_ state: FlarePermissionState,
                                        strings: FlareStrings = FlareStrings()) -> String {
    strings.permissionStateLabel(state)
}

/// Unified "permission missing / denied" panel. The host owns the real permission
/// state and the request / openSettings side effects; this view only explains and
/// dispatches. Spec: General/PermissionPrompt (`PermissionPromptView`).
///
/// `softAsk` is the non-blocking invitation a host shows at a moment it picks (the first visit to the
/// conversation list, say): no state chip, a "Not now" dismiss and, for the notifications kind, copy of its own
/// (``defaultPermissionSoftAskCopy(_:_:featureLabel:strings:)``). It shows only while the person can act on it
/// (``permissionPromptShows(_:softAsk:)``); `granted` renders nothing in any form, so a host binds the platform's
/// status as it is. To ask in a kit bottom sheet, present it with
/// ``SwiftUI/View/flarePermissionPrompt(isPresented:kind:state:softAsk:featureLabel:detail:title:description:requestText:openSettingsText:dismissText:onRequest:onOpenSettings:onDismiss:)``.
public struct PermissionPromptView: View {
    private let kind: FlarePermissionKind
    private let state: FlarePermissionState
    private let featureLabel: String?
    private let detail: String?
    private let busy: Bool
    private let compact: Bool
    private let softAsk: Bool
    /// Laid out as the body of a kit sheet (the presenter's form): one centered column, full-width keys.
    private let sheet: Bool
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
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @ScaledMetric private var titleSize: CGFloat = FlareSizes.fontSizeXl
    @ScaledMetric private var bodySize: CGFloat = FlareSizes.fontSizeMd

    public init(kind: FlarePermissionKind, state: FlarePermissionState, featureLabel: String? = nil,
                detail: String? = nil, busy: Bool = false, compact: Bool = false, softAsk: Bool = false,
                title: String? = nil, description: String? = nil, stateText: String? = nil,
                requestText: String? = nil, openSettingsText: String? = nil, dismissText: String? = nil,
                onRequest: (() -> Void)? = nil, onOpenSettings: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.init(kind: kind, state: state, featureLabel: featureLabel, detail: detail, busy: busy, compact: compact,
                  softAsk: softAsk, sheet: false, title: title, description: description, stateText: stateText,
                  requestText: requestText, openSettingsText: openSettingsText, dismissText: dismissText,
                  onRequest: onRequest, onOpenSettings: onOpenSettings, onDismiss: onDismiss)
    }

    /// The presenter's form: `sheet` lays the prompt out as the body of a kit sheet.
    init(kind: FlarePermissionKind, state: FlarePermissionState, featureLabel: String?, detail: String?, busy: Bool,
         compact: Bool, softAsk: Bool, sheet: Bool, title: String?, description: String?, stateText: String?,
         requestText: String?, openSettingsText: String?, dismissText: String?,
         onRequest: (() -> Void)?, onOpenSettings: (() -> Void)?, onDismiss: (() -> Void)?) {
        self.kind = kind; self.state = state; self.featureLabel = featureLabel; self.detail = detail
        self.busy = busy; self.compact = compact && !sheet; self.softAsk = softAsk; self.sheet = sheet
        self.title = title; self.description = description
        self.stateText = stateText; self.requestText = requestText; self.openSettingsText = openSettingsText
        self.dismissText = dismissText; self.onRequest = onRequest; self.onOpenSettings = onOpenSettings; self.onDismiss = onDismiss
    }

    private func tone(_ colors: FlareColors) -> Color {
        switch state {
        case .undetermined, .granted: return colors.info
        case .denied: return colors.error
        case .restricted: return colors.warning
        case .unavailable: return colors.textSecondary
        }
    }

    private var copy: FlarePermissionCopy {
        softAsk
            ? defaultPermissionSoftAskCopy(kind, state, featureLabel: featureLabel, strings: strings)
            : defaultPermissionCopy(kind, state, featureLabel: featureLabel, strings: strings)
    }

    public var body: some View {
        if permissionPromptShows(state, softAsk: softAsk) {
            if sheet { sheetBody } else { panel }
        }
    }

    /// The body of a kit sheet: icon, heading and explanation in one centered column, then full-width keys with
    /// the action first and "Not now" under it.
    private var sheetBody: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let copy = self.copy
        let actions = permissionActions(state, hasRequest: onRequest != nil, hasOpenSettings: onOpenSettings != nil,
                                        hasDismiss: onDismiss != nil, busy: busy)
        let resolvedTitle = title ?? copy.title
        return ScrollView {
            VStack(spacing: FlareSizes.spacingSm) {
                icon(colors)
                Text(resolvedTitle)
                    .font(.system(size: titleSize, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(description ?? copy.description)
                    .font(.system(size: bodySize))
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: FlareSizes.fontSizeSm))
                        .foregroundColor(colors.textTertiary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                VStack(spacing: FlareSizes.spacingSm) {
                    if actions.request, let onRequest {
                        ButtonView(label: requestText ?? copy.primaryLabel, size: .lg, loading: busy,
                                   disabled: !actions.enabled, block: true, action: onRequest)
                    }
                    if actions.openSettings, let onOpenSettings {
                        ButtonView(label: openSettingsText ?? copy.primaryLabel, size: .lg, loading: busy,
                                   disabled: !actions.enabled, block: true, action: onOpenSettings)
                    }
                    if actions.dismiss, let onDismiss {
                        ButtonView(label: resolvedDismissText, variant: .secondary, size: .lg,
                                   disabled: !actions.enabled, block: true, action: onDismiss)
                    }
                }
                .padding(.top, FlareSizes.spacingSm)
            }
            // The whole width of the sheet: a ScrollView centres content narrower than itself.
            .frame(maxWidth: .infinity)
            .padding(EdgeInsets(top: FlareSizes.spacingMd, leading: FlareSizes.spacingLg, bottom: FlareSizes.spacingXl,
                                trailing: FlareSizes.spacingLg))
        }
        .flareLayerDismissDisabled(busy)
    }

    private var resolvedDismissText: String {
        dismissText ?? (softAsk ? strings.permissionNotNow : strings.permissionDismiss)
    }

    private var panel: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let copy = self.copy
        let actions = permissionActions(state, hasRequest: onRequest != nil, hasOpenSettings: onOpenSettings != nil,
                                        hasDismiss: onDismiss != nil, busy: busy)
        let resolvedTitle = title ?? copy.title
        let hasActions = actions.request || actions.openSettings || actions.dismiss
        return Group {
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
                // A soft-ask is an invitation, not a status report: it carries no state chip.
                if !softAsk {
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
                ButtonView(label: requestText ?? copy.primaryLabel, size: .lg, loading: busy, block: true, action: onRequest)
                    .frame(maxWidth: 240)
            }
            if actions.openSettings, let onOpenSettings {
                ButtonView(label: openSettingsText ?? copy.primaryLabel, size: .lg, loading: busy, block: true, action: onOpenSettings)
                    .frame(maxWidth: 240)
            }
            if actions.dismiss, let onDismiss {
                Button(action: onDismiss) {
                    Text(resolvedDismissText)
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

public extension View {
    /// Asks for a permission in a kit bottom sheet while `isPresented` — the sheet form of
    /// ``PermissionPromptView``, usually a soft-ask (`softAsk: true`) at a moment the host picks. Spec:
    /// General/PermissionPrompt.
    ///
    /// The sheet follows ``SwiftUI/View/flareBottomSheet(isPresented:title:titleHidden:presentation:dismissible:size:fill:maxHeight:onDismiss:content:)``
    /// `auto`: a bottom sheet on the phone form factor, a ``ModalView`` elsewhere. It shows only while the prompt
    /// would (``permissionPromptShows(_:softAsk:)``), so a host can bind the platform's status as it is. A choice
    /// closes the sheet and its callback runs once the sheet is gone (the system's own permission alert then has
    /// the screen to itself); closing it by a swipe, the scrim or Escape is `onDismiss`. A host leaves a callback
    /// out to leave that key out.
    func flarePermissionPrompt(
        isPresented: Binding<Bool>,
        kind: FlarePermissionKind,
        state: FlarePermissionState,
        softAsk: Bool = false,
        featureLabel: String? = nil,
        detail: String? = nil,
        title: String? = nil,
        description: String? = nil,
        requestText: String? = nil,
        openSettingsText: String? = nil,
        dismissText: String? = nil,
        onRequest: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        modifier(FlarePermissionPromptPresenter(
            isPresented: isPresented, kind: kind, state: state, softAsk: softAsk, featureLabel: featureLabel,
            detail: detail, title: title, description: description, requestText: requestText,
            openSettingsText: openSettingsText, dismissText: dismissText,
            onRequest: onRequest, onOpenSettings: onOpenSettings, onDismiss: onDismiss
        ))
    }
}

/// Presents ``PermissionPromptView`` in its sheet form and hands the choice back once the sheet is gone.
private struct FlarePermissionPromptPresenter: ViewModifier {
    @Binding var isPresented: Bool
    let kind: FlarePermissionKind
    let state: FlarePermissionState
    let softAsk: Bool
    let featureLabel: String?
    let detail: String?
    let title: String?
    let description: String?
    let requestText: String?
    let openSettingsText: String?
    let dismissText: String?
    let onRequest: (() -> Void)?
    let onOpenSettings: (() -> Void)?
    let onDismiss: (() -> Void)?
    @Environment(\.flareStrings) private var strings
    @State private var choice: Choice?

    private enum Choice { case request, openSettings, dismiss }

    func body(content: Content) -> some View {
        let shows = permissionPromptShows(state, softAsk: softAsk)
        let copy = softAsk
            ? defaultPermissionSoftAskCopy(kind, state, featureLabel: featureLabel, strings: strings)
            : defaultPermissionCopy(kind, state, featureLabel: featureLabel, strings: strings)
        // The prompt draws its own heading, so the sheet keeps the title as its accessible name only.
        content.flareBottomSheet(
            isPresented: Binding(get: { isPresented && shows }, set: { isPresented = $0 }),
            title: title ?? copy.title,
            titleHidden: true,
            onDismiss: finish
        ) {
            PermissionPromptView(
                kind: kind, state: state, featureLabel: featureLabel, detail: detail, busy: false, compact: false,
                softAsk: softAsk, sheet: true, title: title, description: description, stateText: nil,
                requestText: requestText, openSettingsText: openSettingsText, dismissText: dismissText,
                onRequest: onRequest == nil ? nil : { choose(.request) },
                onOpenSettings: onOpenSettings == nil ? nil : { choose(.openSettings) },
                onDismiss: onDismiss == nil ? nil : { choose(.dismiss) }
            )
        }
    }

    private func choose(_ made: Choice) {
        choice = made
        isPresented = false
    }

    /// Runs once the sheet is gone. Closed without a key is a dismiss, unless the prompt stopped showing (the
    /// permission was granted meanwhile): then there is nothing to answer.
    private func finish() {
        let made: Choice
        if let choice {
            made = choice
        } else if permissionPromptShows(state, softAsk: softAsk) {
            made = .dismiss
        } else {
            return
        }
        choice = nil
        switch made {
        case .request: onRequest?()
        case .openSettings: onOpenSettings?()
        case .dismiss: onDismiss?()
        }
    }
}
