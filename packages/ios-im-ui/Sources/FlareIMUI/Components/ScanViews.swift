import SwiftUI

public struct FlareScanMarker: Identifiable, Sendable {
    public let id: String
    public let corners: [FlareScanPoint]
    public let label: String?
    public init(id: String, corners: [FlareScanPoint], label: String? = nil) { self.id = id; self.corners = corners; self.label = label }
}
public struct FlareScanCapabilities: Sendable {
    public var live: Bool; public var album: Bool; public var paste: Bool; public var myCode: Bool; public var torch: Bool
    public init(live: Bool = true, album: Bool = true, paste: Bool = true, myCode: Bool = true, torch: Bool = false) { self.live = live; self.album = album; self.paste = paste; self.myCode = myCode; self.torch = torch }
}
public struct FlareScanHeader: Sendable {
    public let title: String; public let subtitle: String?; public let avatarURL: String?
    public init(title: String, subtitle: String? = nil, avatarURL: String? = nil) { self.title = title; self.subtitle = subtitle; self.avatarURL = avatarURL }
}
public struct FlareScanFact: Sendable {
    public let label: String; public let value: String
    public init(label: String, value: String) { self.label = label; self.value = value }
}
public struct FlareScanInput: Identifiable, Sendable {
    public let id: String; public let kind: String; public let label: String; public let maxLen: Int
    public init(id: String, kind: String = "text", label: String, maxLen: Int) { self.id = id; self.kind = kind; self.label = label; self.maxLen = maxLen }
}
public struct FlareScanAction: Identifiable, Sendable {
    public let id: String; public let label: String; public let primary: Bool; public let inputs: [FlareScanInput]
    public init(id: String, label: String, primary: Bool = false, inputs: [FlareScanInput] = []) { self.id = id; self.label = label; self.primary = primary; self.inputs = inputs }
}

/// The host supplies a camera preview, already transformed to this view's coordinate space.
public struct ScanViewfinderView<Preview: View>: View {
    private let state: String
    private let capabilities: FlareScanCapabilities
    private let markers: [FlareScanMarker]
    private let hint: String?
    private let torch: Bool
    private let onClose: () -> Void
    private let onToggleTorch: (() -> Void)?
    private let onPickImage: (() -> Void)?
    private let onPaste: (() -> Void)?
    private let onOpenMyCode: (() -> Void)?
    private let onSelectMarker: ((String) -> Void)?
    private let onRetry: (() -> Void)?
    private let onRequestPermission: (() -> Void)?
    private let onOpenSettings: (() -> Void)?
    private let preview: Preview
    @Environment(\.flareStrings) private var strings
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var brand
    public init(state: String, capabilities: FlareScanCapabilities, markers: [FlareScanMarker] = [], hint: String? = nil, torch: Bool = false,
                onClose: @escaping () -> Void, onToggleTorch: (() -> Void)? = nil, onPickImage: (() -> Void)? = nil, onPaste: (() -> Void)? = nil,
                onOpenMyCode: (() -> Void)? = nil, onSelectMarker: ((String) -> Void)? = nil, onRetry: (() -> Void)? = nil,
                onRequestPermission: (() -> Void)? = nil, onOpenSettings: (() -> Void)? = nil, @ViewBuilder preview: () -> Preview) {
        self.state = state; self.capabilities = capabilities; self.markers = markers; self.hint = hint; self.torch = torch
        self.onClose = onClose; self.onToggleTorch = onToggleTorch; self.onPickImage = onPickImage; self.onPaste = onPaste
        self.onOpenMyCode = onOpenMyCode; self.onSelectMarker = onSelectMarker; self.onRetry = onRetry
        self.onRequestPermission = onRequestPermission; self.onOpenSettings = onOpenSettings; self.preview = preview()
    }
    private var status: String {
        if let hint { return hint }
        switch state {
        case "preparing": return strings.scanPreparing
        case "live": return strings.scanLive
        case "lowLight": return strings.scanLowLight
        case "locked": return strings.scanLocked
        case "choosing": return strings.scanChoosing
        case "paused": return strings.scanPaused
        case "imageDecoding": return strings.scanImageDecoding
        case "imageError": return strings.scanImageError
        case "noCodeInImage": return strings.scanNoCodeInImage
        case "noCamera": return strings.scanNoCamera
        case "insecureContext": return strings.scanInsecureContext
        case "cameraBusy": return strings.scanCameraBusy
        default: return strings.scanCameraError
        }
    }
    private var permission: FlarePermissionState? {
        switch state { case "permissionUndetermined": return .undetermined; case "denied": return .denied; case "restricted": return .restricted; default: return nil }
    }
    public var body: some View {
        let colors = FlareColors.of(scheme, brand: brand)
        VStack(spacing: 0) {
            HStack { ButtonView(label: strings.close, variant: .quiet, action: onClose); Spacer(); Text(strings.scanTitle); Spacer(); if capabilities.torch { ButtonView(label: torch ? strings.scanTorchOff : strings.scanTorchOn, variant: .quiet, action: onToggleTorch) } }.padding(FlareSizes.spacingMd)
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    preview.frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
                    ForEach(Array(markers.enumerated()), id: \.element.id) { index, marker in
                        let bounds = flareScanMarkerBounds(marker.corners)
                        ButtonView(label: marker.label ?? "\(strings.scanChooseCode) \(index + 1)", disabled: state != "choosing", action: { onSelectMarker?(marker.id) })
                            .frame(width: max(48, geometry.size.width * bounds.width), height: max(48, geometry.size.height * bounds.height))
                            .overlay(Rectangle().stroke(colors.primary, lineWidth: 2))
                            .position(x: geometry.size.width * (bounds.left + bounds.width / 2), y: geometry.size.height * (bounds.top + bounds.height / 2))
                    }
                    if let permission { PermissionPromptView(kind: .camera, state: permission, onRequest: onRequestPermission, onOpenSettings: onOpenSettings).padding(FlareSizes.spacingLg).frame(maxHeight: .infinity) }
                    Text(status).foregroundColor(colors.textPrimary).padding(FlareSizes.spacingMd).background(colors.bgPrimary).accessibilityAddTraits(.updatesFrequently)
                }.background(colors.bgSecondary)
            }
            ViewThatFits(in: .horizontal) {
                HStack { controls }
                VStack { controls }
            }.padding(FlareSizes.spacingMd)
        }.background(colors.bgPrimary)
    }
    @ViewBuilder private var controls: some View {
        if capabilities.album { ButtonView(label: strings.scanAlbum, variant: .secondary, action: onPickImage) }
        if capabilities.paste { ButtonView(label: strings.scanPaste, variant: .secondary, action: onPaste) }
        if capabilities.myCode { ButtonView(label: strings.myQrCode, variant: .secondary, action: onOpenMyCode) }
        if ["paused", "cameraError", "imageError", "noCodeInImage", "noCamera"].contains(state) { ButtonView(label: strings.retry, action: onRetry) }
    }
}

/// Content for the kit's adaptive flareBottomSheet presenter; no SDK or modal navigation policy.
public struct ScanResultSheetView: View {
    private let phase: String; private let header: FlareScanHeader; private let facts: [FlareScanFact]
    private let notice: String?; private let actions: [FlareScanAction]; private let busy: Bool
    private let onAction: (String, [String: String]) -> Void; private let onRetry: (() -> Void)?; private let onDismiss: (() -> Void)?
    @State private var values: [String: String] = [:]
    @Environment(\.flareStrings) private var strings
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var brand
    public init(phase: String, header: FlareScanHeader, facts: [FlareScanFact] = [], notice: String? = nil, actions: [FlareScanAction] = [], busy: Bool = false,
                onAction: @escaping (String, [String: String]) -> Void, onRetry: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.phase = phase; self.header = header; self.facts = facts; self.notice = notice; self.actions = actions; self.busy = busy; self.onAction = onAction; self.onRetry = onRetry; self.onDismiss = onDismiss
    }
    public var body: some View {
        let colors = FlareColors.of(scheme, brand: brand)
        ScrollView {
            VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
                HStack { AvatarView(userId: header.title, displayName: header.title, avatarURL: header.avatarURL, size: 48); VStack(alignment: .leading) { Text(header.title).font(.headline); if let subtitle = header.subtitle { Text(subtitle).foregroundColor(colors.textSecondary) } } }
                ForEach(Array(facts.enumerated()), id: \.offset) { _, fact in VStack(alignment: .leading) { Text(fact.label).foregroundColor(colors.textTertiary); Text(fact.value).textSelection(.enabled) } }
                if let notice, !notice.isEmpty { Text(notice).foregroundColor(colors.textSecondary) }
                if ["loading", "slow", "acting"].contains(phase) { ProgressView(strings.scanPreparing) }
                ForEach(actions) { action in
                    let supported = action.inputs.allSatisfy { $0.kind == "text" && $0.maxLen > 0 }
                    ForEach(action.inputs.filter { $0.kind == "text" }) { input in
                        Text(input.label).foregroundColor(colors.textSecondary)
                        InputView(text: Binding(get: { values["\(action.id)/\(input.id)"] ?? "" }, set: { values["\(action.id)/\(input.id)"] = $0 }), maxLength: input.maxLen, disabled: busy).accessibilityLabel(input.label)
                    }
                    if !supported { Text(strings.scanUpgradeRequired) }
                    ButtonView(label: action.label, variant: action.primary ? .primary : .secondary, loading: busy, disabled: phase != "ready" || !supported, block: true) {
                        onAction(action.id, Dictionary(uniqueKeysWithValues: action.inputs.map { ($0.id, String((values["\(action.id)/\($0.id)"] ?? "").prefix($0.maxLen))) }))
                    }
                }
                if ["failed", "offlineWaiting", "unknown"].contains(phase) { ButtonView(label: strings.retry, disabled: busy, block: true, action: onRetry) }
                if let onDismiss { ButtonView(label: strings.close, variant: .quiet, disabled: busy, block: true, action: onDismiss) }
            }.padding(FlareSizes.spacingLg).foregroundColor(colors.textPrimary)
        }.onChange(of: actions.map(\.id)) { _ in values = [:] }
    }
}

public struct FlareScanSurfaceHints: Equatable, Sendable {
    public let secure: Bool
    public let maxBrightness: Bool
    public init(secure: Bool, maxBrightness: Bool) { self.secure = secure; self.maxBrightness = maxBrightness }
}
/// A plugin supplies only an opaque token; the trusted host binds its plugin id to encoding.
public struct FlarePluginQrView: View {
    private let token: String?
    private let ttlMs: Double?
    private let caption: String?
    private let encodeQr: (@Sendable (String) async throws -> String)?
    @State private var payload: String?
    @State private var expired = false
    @State private var failed = false
    @State private var expiresAt: Double?
    @Environment(\.flareStrings) private var strings
    @Environment(\.scenePhase) private var scenePhase
    public init(token: String?, ttlMs: Double? = nil, caption: String? = nil, encodeQr: (@Sendable (String) async throws -> String)? = nil) { self.token = token; self.ttlMs = ttlMs; self.caption = caption; self.encodeQr = encodeQr }
    public var body: some View {
        VStack {
            if token?.isEmpty == false {
                if let payload, scenePhase == .active, expiresAt == nil || ProcessInfo.processInfo.systemUptime < expiresAt! { FlareQrMatrix(payload: payload, label: caption ?? strings.qrCode) }
                else if expired || (expiresAt.map { ProcessInfo.processInfo.systemUptime >= $0 } ?? false) { Text(strings.scanCodeExpired) }
                else if failed { Text(strings.qrCardUnavailable) }
                else { ProgressView(strings.scanPreparing) }
                if let caption { Text(caption) }
            }
        }.task(id: "\(token ?? "")/\(ttlMs ?? -1)") {
            payload = nil; expired = false; failed = false; expiresAt = nil
            guard let token, !token.isEmpty else { return }
            let receivedAt = ProcessInfo.processInfo.systemUptime
            guard ttlMs == nil || (ttlMs!.isFinite && ttlMs! > 0) else { expired = true; return }
            expiresAt = ttlMs.map { receivedAt + $0 / 1000 }
            do {
                guard let encodeQr else { failed = true; return }
                let url = try await encodeQr(token)
                guard !Task.isCancelled else { return }
                let remaining = ttlMs.map { $0 - (ProcessInfo.processInfo.systemUptime - receivedAt) * 1000 }
                guard remaining == nil || remaining! > 0 else { expired = true; return }
                payload = url
                if let remaining {
                    try await Task.sleep(nanoseconds: UInt64(min(remaining, 86_400_000) * 1_000_000))
                    guard !Task.isCancelled else { return }
                    payload = nil; expired = true
                }
            } catch { if !Task.isCancelled { failed = true } }
        }.onChange(of: scenePhase) { phase in
            if phase == .active, let expiresAt, ProcessInfo.processInfo.systemUptime >= expiresAt {
                payload = nil; expired = true
            }
        }
    }
}
