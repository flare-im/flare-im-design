import SwiftUI

/// Connection / session state supplied by the host; the UI never opens or closes a connection.
public enum FlareConnectionState: String, CaseIterable, Sendable {
    case connected, connecting, reconnecting, offline, sessionExpired, kicked, sdkUnready
}

public enum FlareConnectionAction: String, CaseIterable, Sendable {
    case reconnect, reauth, copyDiagnostics
}

/// Semantic tone per state; every state also carries an icon and text, never colour alone.
public func connectionTone(_ state: FlareConnectionState) -> FlareStatusTone {
    switch state {
    case .connected: return .success
    case .connecting, .reconnecting: return .warning
    case .offline, .sessionExpired, .kicked: return .danger
    case .sdkUnready: return .neutral
    }
}

/// States that show an indeterminate progress indicator.
public func connectionInProgress(_ state: FlareConnectionState) -> Bool {
    state == .connecting || state == .reconnecting
}

/// Actions the host may currently trigger. `reconnect` only while offline/reconnecting, `reauth` only
/// after sessionExpired/kicked, `copyDiagnostics` only with non-blank diagnostics. `sdkUnready` never
/// exposes an action; `busy` disables everything.
public func availableConnectionActions(_ state: FlareConnectionState, hasReconnect: Bool, hasReauth: Bool,
                                       hasDiagnostics: Bool, busy: Bool) -> [FlareConnectionAction] {
    if busy || state == .sdkUnready { return [] }
    var actions: [FlareConnectionAction] = []
    if hasReconnect, state == .offline || state == .reconnecting { actions.append(.reconnect) }
    if hasReauth, state == .sessionExpired || state == .kicked { actions.append(.reauth) }
    if hasDiagnostics { actions.append(.copyDiagnostics) }
    return actions
}

/// Connection / session details panel — opened from a StatusBanner or shown on the "network & connection"
/// settings page. The host owns the state; this view only presents it and dispatches
/// reconnect / reauth / copyDiagnostics. Spec: General/ConnectionDetails (`ConnectionDetailsView`).
public struct ConnectionDetailsView: View {
    let state: FlareConnectionState
    let transport: String?
    let endpoint: String?
    let lastSyncAt: String?
    let reason: String?
    let diagnostics: String?
    let busy: Bool
    let title: String
    let connectedText: String
    let connectingText: String
    let reconnectingText: String
    let offlineText: String
    let sessionExpiredText: String
    let kickedText: String
    let sdkUnreadyText: String
    let transportLabel: String
    let endpointLabel: String
    let lastSyncLabel: String
    let diagnosticsLabel: String
    let reconnectText: String
    let reauthText: String
    let copyDiagnosticsText: String
    let onReconnect: (() -> Void)?
    let onReauth: (() -> Void)?
    let onCopyDiagnostics: (() -> Void)?

    @Environment(\.colorScheme) private var scheme
    @ScaledMetric private var bodySize: CGFloat = FlareSizes.fontSizeMd
    @State private var diagnosticsOpen = false

    public init(state: FlareConnectionState, transport: String? = nil, endpoint: String? = nil,
                lastSyncAt: String? = nil, reason: String? = nil, diagnostics: String? = nil, busy: Bool = false,
                title: String = "连接详情", connectedText: String = "已连接", connectingText: String = "正在连接",
                reconnectingText: String = "正在重新连接", offlineText: String = "离线",
                sessionExpiredText: String = "登录已过期", kickedText: String = "已在其他设备登录",
                sdkUnreadyText: String = "客户端尚未就绪", transportLabel: String = "传输协议",
                endpointLabel: String = "服务地址", lastSyncLabel: String = "上次同步",
                diagnosticsLabel: String = "诊断信息", reconnectText: String = "重新连接",
                reauthText: String = "重新登录", copyDiagnosticsText: String = "复制诊断信息",
                onReconnect: (() -> Void)? = nil, onReauth: (() -> Void)? = nil,
                onCopyDiagnostics: (() -> Void)? = nil) {
        self.state = state; self.transport = transport; self.endpoint = endpoint; self.lastSyncAt = lastSyncAt
        self.reason = reason; self.diagnostics = diagnostics; self.busy = busy; self.title = title
        self.connectedText = connectedText; self.connectingText = connectingText
        self.reconnectingText = reconnectingText; self.offlineText = offlineText
        self.sessionExpiredText = sessionExpiredText; self.kickedText = kickedText
        self.sdkUnreadyText = sdkUnreadyText; self.transportLabel = transportLabel
        self.endpointLabel = endpointLabel; self.lastSyncLabel = lastSyncLabel
        self.diagnosticsLabel = diagnosticsLabel; self.reconnectText = reconnectText
        self.reauthText = reauthText; self.copyDiagnosticsText = copyDiagnosticsText
        self.onReconnect = onReconnect; self.onReauth = onReauth; self.onCopyDiagnostics = onCopyDiagnostics
    }

    private var stateText: String {
        switch state {
        case .connected: return connectedText
        case .connecting: return connectingText
        case .reconnecting: return reconnectingText
        case .offline: return offlineText
        case .sessionExpired: return sessionExpiredText
        case .kicked: return kickedText
        case .sdkUnready: return sdkUnreadyText
        }
    }

    private var stateIcon: String {
        switch state {
        case .connected: return "success"
        case .connecting, .reconnecting: return "refresh"
        case .offline: return "error"
        case .sessionExpired: return "lock"
        case .kicked: return "devices"
        case .sdkUnready: return "info"
        }
    }

    private func toneColor(_ colors: FlareColors) -> Color {
        switch connectionTone(state) {
        case .success: return colors.success
        case .warning: return colors.warning
        case .danger: return colors.error
        case .info: return colors.info
        case .neutral: return colors.textSecondary
        }
    }

    private var hasDiagnostics: Bool {
        !(diagnostics ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let tint = toneColor(colors)
        // Visibility ignores busy (buttons stay in place); busy only disables them.
        let visible = availableConnectionActions(state, hasReconnect: onReconnect != nil, hasReauth: onReauth != nil,
                                                 hasDiagnostics: hasDiagnostics && onCopyDiagnostics != nil, busy: false)
        VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
            Text(title).font(.system(size: FlareSizes.fontSize2xl, weight: .semibold)).foregroundColor(colors.textPrimary)

            HStack(alignment: .top, spacing: FlareSizes.spacingMd) {
                IconView(stateIcon, size: 20, color: tint).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                    Text(stateText).font(.system(size: FlareSizes.fontSizeLg, weight: .semibold)).foregroundColor(colors.textPrimary)
                    if let reason, !reason.isEmpty {
                        Text(reason).font(.system(size: bodySize)).foregroundColor(colors.textSecondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(FlareSizes.spacingMd)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(tint.opacity(0.10)))
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(tint.opacity(0.24), lineWidth: 1))
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.updatesFrequently)

            if connectionInProgress(state) {
                ProgressView().progressViewStyle(.linear).tint(tint).accessibilityLabel(stateText)
            }

            if transport != nil || endpoint != nil || lastSyncAt != nil {
                VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
                    if let transport { metaRow(transportLabel, transport, colors: colors) }
                    if let endpoint { metaRow(endpointLabel, endpoint, colors: colors, ellipsis: true) }
                    if let lastSyncAt { metaRow(lastSyncLabel, lastSyncAt, colors: colors) }
                }
            }

            if !visible.isEmpty {
                HStack(spacing: FlareSizes.spacingSm) {
                    if visible.contains(.reconnect) { primaryButton(reconnectText, colors: colors) { onReconnect?() } }
                    if visible.contains(.reauth) { primaryButton(reauthText, colors: colors) { onReauth?() } }
                    if visible.contains(.copyDiagnostics) {
                        Button { onCopyDiagnostics?() } label: {
                            HStack(spacing: FlareSizes.spacingXs) {
                                IconView("copy", size: 16, color: colors.textPrimary).accessibilityHidden(true)
                                Text(copyDiagnosticsText).font(.system(size: FlareSizes.fontSizeLg))
                            }
                            .foregroundColor(busy ? colors.textDisabled : colors.textPrimary)
                            .padding(.horizontal, FlareSizes.spacingMd)
                            .frame(minWidth: FlareSizes.touchTarget, minHeight: FlareSizes.touchTarget)
                            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(busy ? colors.bgDisabled : colors.bgPrimary))
                            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).stroke(colors.borderPrimary, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .disabled(busy)
                    }
                }
            }

            if hasDiagnostics, let diagnostics {
                Button { diagnosticsOpen.toggle() } label: {
                    HStack(spacing: FlareSizes.spacingXs) {
                        IconView("forward", size: 14, color: colors.textSecondary)
                            .rotationEffect(.degrees(diagnosticsOpen ? 90 : 0))
                            .accessibilityHidden(true)
                        Text(diagnosticsLabel).font(.system(size: bodySize)).foregroundColor(colors.textSecondary)
                    }
                    .frame(minHeight: FlareSizes.touchTarget)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(diagnosticsOpen ? [.isButton, .isSelected] : [.isButton])
                .accessibilityHint(diagnosticsOpen ? "collapse" : "expand")
                if diagnosticsOpen {
                    ScrollView {
                        Text(diagnostics)
                            .font(.system(size: FlareSizes.fontSizeSm, design: .monospaced))
                            .foregroundColor(colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .environment(\.layoutDirection, .leftToRight)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 240)
                    .padding(FlareSizes.spacingMd)
                    .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(colors.bgSecondary))
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
    private func metaRow(_ label: String, _ value: String, colors: FlareColors, ellipsis: Bool = false) -> some View {
        HStack(alignment: .top, spacing: FlareSizes.spacingLg) {
            Text(label).font(.system(size: bodySize)).foregroundColor(colors.textSecondary).frame(width: 88, alignment: .leading)
            if ellipsis {
                Text(value).font(.system(size: bodySize)).foregroundColor(colors.textPrimary)
                    .lineLimit(1).truncationMode(.middle)
                    .environment(\.layoutDirection, .leftToRight)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(value)
            } else {
                Text(value).font(.system(size: bodySize)).foregroundColor(colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func primaryButton(_ text: String, colors: FlareColors, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text).font(.system(size: FlareSizes.fontSizeLg, weight: .semibold))
                .foregroundColor(busy ? colors.textDisabled : .white)
                .padding(.horizontal, FlareSizes.spacingMd)
                .frame(minWidth: FlareSizes.touchTarget, minHeight: FlareSizes.touchTarget)
                .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(busy ? colors.bgDisabled : colors.primary))
        }
        .buttonStyle(.plain)
        .disabled(busy)
    }
}
