import SwiftUI

/// Screen-share state reported by the host / RTC plugin.
/// `idle` — nothing is being shared, the local user may start. `requesting` — a share was requested
/// and the system / plugin has not answered yet. `sharing` — the local user is sharing.
/// `viewing` — someone else is sharing and the local user is watching.
/// `unavailable` — the runtime or plugin does not support screen sharing at all.
public enum FlareScreenShareState: String, CaseIterable, Sendable {
    case idle, requesting, sharing, viewing, unavailable
}

public enum FlareScreenShareAction: String, CaseIterable, Sendable {
    case start, stop, cancel
}

/// Semantic tone per state; every state also carries an icon and text, never colour alone.
public func screenShareTone(_ state: FlareScreenShareState) -> FlareStatusTone {
    switch state {
    case .idle: return .neutral
    case .requesting: return .warning
    case .sharing: return .success
    case .viewing: return .info
    case .unavailable: return .neutral
    }
}

/// Kit icon per state; the same semantic names resolve on Vue / Flutter / Compose.
public func screenShareIconName(_ state: FlareScreenShareState) -> String {
    switch state {
    case .idle: return "devices"
    case .requesting: return "refresh"
    case .sharing: return "video"
    case .viewing: return "eye"
    case .unavailable: return "block"
    }
}

/// Which actions are visible, and whether they may be pressed.
public struct FlareScreenShareActions: Equatable, Sendable {
    /// Visible only while idle and the host supplied a handler.
    public let start: Bool
    /// Visible only while sharing — a viewer can never stop someone else's share.
    public let stop: Bool
    /// Visible only while requesting.
    public let cancel: Bool
    /// false while busy: visible actions keep their place but cannot be pressed.
    public let enabled: Bool

    public func contains(_ action: FlareScreenShareAction) -> Bool {
        switch action {
        case .start: return start
        case .stop: return stop
        case .cancel: return cancel
        }
    }

    public var isEmpty: Bool { !start && !stop && !cancel }
}

/// Actions the host may currently trigger. `viewing` and `unavailable` never expose one — an
/// unsupported runtime shows the reason instead of a button that would do nothing. Visibility
/// ignores `busy` on purpose so buttons do not disappear mid-command.
public func screenShareActions(_ state: FlareScreenShareState, hasStart: Bool, hasStop: Bool,
                               hasCancel: Bool, busy: Bool = false) -> FlareScreenShareActions {
    FlareScreenShareActions(
        start: state == .idle && hasStart,
        stop: state == .sharing && hasStop,
        cancel: state == .requesting && hasCancel,
        enabled: !busy
    )
}

/// Screen-share control and status panel for an ongoing call. Capture, source enumeration and
/// encoding belong to the host / RTC plugin; this view only presents the reported state and
/// dispatches start / stop / cancel intents. Permission denial is NOT handled here: the host renders
/// `PermissionPromptView(kind: .screen, state: .denied)` instead, so one intent keeps one path.
/// Spec: Call/ScreenShare (`ScreenShareView`).
public struct ScreenShareView: View {
    let state: FlareScreenShareState
    let sourceLabel: String?
    let presenterName: String?
    let detail: String?
    let busy: Bool
    let title: String
    let idleText: String
    let requestingText: String
    let sharingText: String
    let viewingText: String
    let unavailableText: String
    let sourceRowLabel: String
    let presenterRowLabel: String
    let startText: String
    let stopText: String
    let cancelText: String
    let onStart: (() -> Void)?
    let onStop: (() -> Void)?
    let onCancel: (() -> Void)?

    @Environment(\.colorScheme) private var scheme
    @ScaledMetric private var bodySize: CGFloat = FlareSizes.fontSizeMd

    public init(state: FlareScreenShareState, sourceLabel: String? = nil, presenterName: String? = nil,
                detail: String? = nil, busy: Bool = false, title: String = "屏幕共享",
                idleText: String = "未在共享", requestingText: String = "正在请求共享",
                sharingText: String = "正在共享屏幕", viewingText: String = "正在观看共享",
                unavailableText: String = "当前环境不支持屏幕共享", sourceRowLabel: String = "共享内容",
                presenterRowLabel: String = "共享者", startText: String = "共享屏幕",
                stopText: String = "停止共享", cancelText: String = "取消请求",
                onStart: (() -> Void)? = nil, onStop: (() -> Void)? = nil, onCancel: (() -> Void)? = nil) {
        self.state = state; self.sourceLabel = sourceLabel; self.presenterName = presenterName
        self.detail = detail; self.busy = busy; self.title = title
        self.idleText = idleText; self.requestingText = requestingText; self.sharingText = sharingText
        self.viewingText = viewingText; self.unavailableText = unavailableText
        self.sourceRowLabel = sourceRowLabel; self.presenterRowLabel = presenterRowLabel
        self.startText = startText; self.stopText = stopText; self.cancelText = cancelText
        self.onStart = onStart; self.onStop = onStop; self.onCancel = onCancel
    }

    private var stateText: String {
        switch state {
        case .idle: return idleText
        case .requesting: return requestingText
        case .sharing: return sharingText
        case .viewing: return viewingText
        case .unavailable: return unavailableText
        }
    }

    private func toneColor(_ colors: FlareColors) -> Color {
        switch screenShareTone(state) {
        case .success: return colors.success
        case .warning: return colors.warning
        case .danger: return colors.error
        case .info: return colors.info
        case .neutral: return colors.textSecondary
        }
    }

    private var trimmedSource: String {
        state == .sharing ? (sourceLabel ?? "").trimmingCharacters(in: .whitespacesAndNewlines) : ""
    }
    private var trimmedPresenter: String {
        state == .viewing ? (presenterName ?? "").trimmingCharacters(in: .whitespacesAndNewlines) : ""
    }
    private var trimmedDetail: String {
        (detail ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let tint = toneColor(colors)
        let active = state == .sharing
        // Visibility ignores busy (buttons stay in place); busy only disables them.
        let actions = screenShareActions(state, hasStart: onStart != nil, hasStop: onStop != nil,
                                         hasCancel: onCancel != nil, busy: false)
        VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
            Text(title).font(.system(size: FlareSizes.fontSize2xl, weight: .semibold)).foregroundColor(colors.textPrimary)

            HStack(alignment: .top, spacing: FlareSizes.spacingMd) {
                IconView(screenShareIconName(state), size: 20, color: tint).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                    Text(stateText).font(.system(size: FlareSizes.fontSizeLg, weight: .semibold)).foregroundColor(colors.textPrimary)
                    if !trimmedDetail.isEmpty {
                        Text(trimmedDetail).font(.system(size: bodySize)).foregroundColor(colors.textSecondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(FlareSizes.spacingMd)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(tint.opacity(active ? 0.16 : 0.10)))
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(tint.opacity(active ? 0.44 : 0.24), lineWidth: 1))
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.updatesFrequently)

            if state == .requesting {
                ProgressView().progressViewStyle(.linear).tint(tint).accessibilityLabel(requestingText)
            }

            if !trimmedSource.isEmpty || !trimmedPresenter.isEmpty {
                VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
                    if !trimmedSource.isEmpty { metaRow(sourceRowLabel, trimmedSource, colors: colors) }
                    if !trimmedPresenter.isEmpty { metaRow(presenterRowLabel, trimmedPresenter, colors: colors) }
                }
            }

            if !actions.isEmpty {
                HStack(spacing: FlareSizes.spacingSm) {
                    if actions.start {
                        primaryButton(startText, icon: "devices", colors: colors) { onStart?() }
                    }
                    if actions.stop {
                        outlinedButton(stopText, icon: "block", tint: colors.error, colors: colors) { onStop?() }
                    }
                    if actions.cancel {
                        outlinedButton(cancelText, icon: nil, tint: colors.textPrimary, colors: colors) { onCancel?() }
                    }
                }
            }
        }
        .padding(FlareSizes.spacingLg)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary))
        .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private func metaRow(_ label: String, _ value: String, colors: FlareColors) -> some View {
        HStack(alignment: .top, spacing: FlareSizes.spacingLg) {
            Text(label).font(.system(size: bodySize)).foregroundColor(colors.textSecondary)
                .frame(width: 88, alignment: .leading)
            Text(value).font(.system(size: bodySize)).foregroundColor(colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func primaryButton(_ text: String, icon: String, colors: FlareColors,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: FlareSizes.spacingXs) {
                IconView(icon, size: 16, color: busy ? colors.textDisabled : .white).accessibilityHidden(true)
                Text(text).font(.system(size: FlareSizes.fontSizeLg, weight: .semibold))
            }
            .foregroundColor(busy ? colors.textDisabled : .white)
            .padding(.horizontal, FlareSizes.spacingMd)
            .frame(minWidth: FlareSizes.touchTarget, minHeight: FlareSizes.touchTarget)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(busy ? colors.bgDisabled : colors.primary))
        }
        .buttonStyle(.plain)
        .disabled(busy)
    }

    private func outlinedButton(_ text: String, icon: String?, tint: Color, colors: FlareColors,
                                action: @escaping () -> Void) -> some View {
        let content = busy ? colors.textDisabled : tint
        return Button(action: action) {
            HStack(spacing: FlareSizes.spacingXs) {
                if let icon { IconView(icon, size: 16, color: content).accessibilityHidden(true) }
                Text(text).font(.system(size: FlareSizes.fontSizeLg))
            }
            .foregroundColor(content)
            .padding(.horizontal, FlareSizes.spacingMd)
            .frame(minWidth: FlareSizes.touchTarget, minHeight: FlareSizes.touchTarget)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(busy ? colors.bgDisabled : colors.bgPrimary))
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).stroke(busy ? colors.borderPrimary : content, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(busy)
    }
}
