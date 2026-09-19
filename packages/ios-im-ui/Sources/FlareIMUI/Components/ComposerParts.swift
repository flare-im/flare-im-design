import SwiftUI

/// Hold-to-talk voice button — a composable composer part. Press and hold to
/// record, release to send, slide up past the threshold to cancel. The host
/// owns the actual recording via the callbacks; all labels are host-provided.
public struct FlareVoiceHoldButton: View {
    private let label: String?
    private let recordingLabel: String?
    private let cancelLabel: String?
    private let cancelThreshold: CGFloat
    private let onStart: (() -> Void)?
    private let onEnd: (() -> Void)?
    private let onCancel: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @State private var pressing = false
    @State private var willCancel = false

    public init(label: String? = nil,
                recordingLabel: String? = nil,
                cancelLabel: String? = nil,
                cancelThreshold: CGFloat = 80,
                onStart: (() -> Void)? = nil, onEnd: (() -> Void)? = nil,
                onCancel: (() -> Void)? = nil) {
        self.label = label; self.recordingLabel = recordingLabel
        self.cancelLabel = cancelLabel; self.cancelThreshold = cancelThreshold
        self.onStart = onStart; self.onEnd = onEnd; self.onCancel = onCancel
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let bg = !pressing ? colors.bgSecondary : (willCancel ? colors.error : colors.primary)
        let fg = !pressing ? colors.textSecondary : Color.white
        Text(pressing ? (willCancel ? cancelLabel ?? strings.releaseToCancel : recordingLabel ?? strings.voiceHoldButtonRecording) : label ?? strings.voiceHoldButtonLabel)
            .font(.system(size: FlareSizes.fontSizeLg, weight: .medium))
            .foregroundColor(fg)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(bg))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        if !pressing { pressing = true; willCancel = false; onStart?() }
                        let cancel = v.translation.height < -cancelThreshold
                        // Sliding past the line changes what letting go means, so it is felt as well as seen.
                        if flareHapticCrossed(was: willCancel, now: cancel) { flareHapticTick() }
                        if cancel != willCancel { willCancel = cancel }
                    }
                    .onEnded { _ in
                        let cancel = willCancel
                        pressing = false; willCancel = false
                        cancel ? onCancel?() : onEnd?()
                    }
            )
    }
}

/// One attachment/action tile in ``FlareComposerActionPanel``.
public struct FlareComposerAction: Identifiable {
    public let id: String
    public let label: String
    /// Semantic kit icon name (``flareIconNames``) on the tile.
    public let icon: String
    public let group: String?
    public let order: Int?
    public let visible: Bool
    public let enabled: Bool
    public let badge: String?
    public let intent: String?
    public let accessibilityLabel: String?
    public let disabledReason: String?
    public init(
        id: String,
        label: String,
        icon: String,
        group: String? = nil,
        order: Int? = nil,
        visible: Bool = true,
        enabled: Bool = true,
        badge: String? = nil,
        intent: String? = nil,
        accessibilityLabel: String? = nil,
        disabledReason: String? = nil
    ) {
        self.id = id; self.label = label; self.icon = icon
        self.group = group; self.order = order; self.visible = visible; self.enabled = enabled
        self.badge = badge; self.intent = intent; self.accessibilityLabel = accessibilityLabel
        self.disabledReason = disabledReason
    }
}

public struct FlareComposerCapabilities: Sendable, Equatable {
    public let availableActionIDs: Set<String>?
    public init(availableActionIDs: Set<String>? = nil) { self.availableActionIDs = availableActionIDs }
}

/// Defaults -> capabilities -> host list. A host list is a full replacement.
public func resolveComposerActions(
    defaults: [FlareComposerAction],
    capabilities: FlareComposerCapabilities = FlareComposerCapabilities(),
    actions: [FlareComposerAction]? = nil
) -> [FlareComposerAction] {
    var seen = Set<String>()
    return (actions ?? defaults).enumerated()
        .filter { _, action in
            action.visible && !action.id.isEmpty && seen.insert(action.id).inserted &&
                (capabilities.availableActionIDs?.contains(action.id) ?? true)
        }
        .sorted { left, right in
            let leftOrder = left.element.order ?? left.offset
            let rightOrder = right.element.order ?? right.offset
            return leftOrder == rightOrder ? left.offset < right.offset : leftOrder < rightOrder
        }
        .map(\.element)
}

/// The composer's bottom function area (下方功能区) — an inline grid of attachment
/// actions. Composable part; reveal it under the input. This is the one
/// attachment grid; the message long-press sheet is ``MessageActionSheetView``.
public struct FlareComposerActionPanel: View {
    private let actions: [FlareComposerAction]?
    private let capabilities: FlareComposerCapabilities
    private let columns: Int
    private let onAction: ((FlareComposerAction) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(actions: [FlareComposerAction]? = nil,
                capabilities: FlareComposerCapabilities = FlareComposerCapabilities(),
                columns: Int = 4, onAction: ((FlareComposerAction) -> Void)? = nil) {
        self.actions = actions; self.capabilities = capabilities
        self.columns = columns; self.onAction = onAction
    }

    /// Attachment tiles built from host-overridable copy. Pass a different
    /// ``FlareStrings`` (or the environment value) to relabel them.
    public static func actions(for strings: FlareStrings) -> [FlareComposerAction] {
        [
            .init(id: "image", label: strings.actionImage, icon: "image"),
            .init(id: "file", label: strings.actionFile, icon: "folder"),
            .init(id: "voice", label: strings.voiceHoldButtonLabel, icon: "mic"),
            .init(id: "location", label: strings.actionLocation, icon: "location"),
            .init(id: "contact", label: strings.actionCard, icon: "card"),
        ]
    }

    /// Default tiles with the kit's built-in copy. Prefer leaving `actions` unset so the
    /// view resolves them from the environment instead.
    public static let defaultActions: [FlareComposerAction] = actions(for: FlareStrings())

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let actions = resolveComposerActions(
            defaults: Self.actions(for: strings),
            capabilities: capabilities,
            actions: self.actions
        )
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns),
                  spacing: FlareSizes.spacingLg) {
            ForEach(actions) { action in
                Button { onAction?(action) } label: {
                    VStack(spacing: FlareSizes.spacingXs) {
                        ZStack {
                            Color.clear.frame(width: 44, height: 44)
                            Image(systemName: flareIconSymbol(action.icon)).font(.system(size: FlareSizes.iconSizeMd))
                                .foregroundColor(colors.textPrimary)
                        }
                        Text(action.label).font(.system(size: FlareSizes.fontSizeXs))
                            .foregroundColor(colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!action.enabled)
                .opacity(action.enabled ? 1 : FlareOpacity.disabled)
                .accessibilityLabel(action.accessibilityLabel ?? action.label)
                .accessibilityHint(action.enabled ? "" : (action.disabledReason ?? ""))
            }
        }
        .padding(FlareSizes.spacingLg)
        .frame(maxWidth: .infinity)
        .background(colors.bgPrimary)
    }
}

/// Send button (发送) — a composable composer part. Theme primary when active,
/// disabled otherwise; fires onSend only when active.
///
/// Same footprint as the send key inside ``ComposerView`` (36pt circle, 18pt
/// glyph) so a host composing its own bar gets an identical key.
/// Send — a paper plane, and nothing else.
///
/// It used to be a filled brand disc with a white arrow inside. Sending is the
/// same kind of act as every other key in the tool row — one tap, one outcome —
/// so it is drawn the same way, and only colour says which one sends: the brand
/// at rest against the row, faded while there is nothing to send. That is also
/// what `ComposerView`'s own send key does, and the two must not drift.
public struct FlareComposerSendButton: View {
    /// Shared with `ComposerView` so the two send keys can't drift.
    static let side: CGFloat = 44
    static let glyph: CGFloat = 20
    /// The plane at rest: present, but plainly not ready to be pressed.
    static let idleOpacity: Double = 0.38

    private let active: Bool
    private let onSend: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(active: Bool, onSend: (() -> Void)? = nil) {
        self.active = active
        self.onSend = onSend
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        Button { if active { onSend?() } } label: {
            Image(systemName: "paperplane")
                .font(.system(size: Self.glyph))
                .frame(width: Self.side, height: Self.side)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(colors.primaryText.opacity(active ? 1 : Self.idleOpacity))
        .disabled(!active)
        .accessibilityLabel(Text(strings.send))
    }
}

/// Reply strip (回复条) — a composable composer part shown above the input when
/// replying. Left brand rail + sender / summary + cancel.
public struct FlareComposerReplyStrip: View {
    private let senderName: String
    private let summary: String
    private let label: String?
    private let onCancel: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(senderName: String, summary: String, label: String? = nil,
                onCancel: (() -> Void)? = nil) {
        self.senderName = senderName
        self.summary = summary
        self.label = label
        self.onCancel = onCancel
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(label ?? strings.composerReply) \(senderName)")
                    .font(.system(size: FlareSizes.fontSizeXs, weight: .semibold))
                    .foregroundColor(colors.primaryText)
                Text(summary)
                    .font(.system(size: FlareSizes.fontSizeSm))
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Button { onCancel?() } label: {
                Image(systemName: flareIconSymbol("close")).font(.system(size: 18)).foregroundColor(colors.textTertiary)
                    .flareTouchTarget()
            }
            .buttonStyle(.plain)
            .flareCompactLayout(width: 18, height: 18)
            .accessibilityLabel(strings.cancelReply)
        }
        .padding(.horizontal, FlareSizes.spacingSm).padding(.vertical, FlareSizes.spacingXs)
        .background(
            RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(colors.messageReplyBackground)
        )
        .overlay(
            HStack { Rectangle().fill(colors.messageReplyBorder).frame(width: 3); Spacer() }
                .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusMd))
        )
    }
}
