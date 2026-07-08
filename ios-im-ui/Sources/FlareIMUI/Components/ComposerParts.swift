import SwiftUI

/// Hold-to-talk voice button — a composable composer part. Press and hold to
/// record, release to send, slide up past the threshold to cancel. The host
/// owns the actual recording via the callbacks; all labels are host-provided.
public struct FlareVoiceHoldButton: View {
    private let label: String
    private let recordingLabel: String
    private let cancelLabel: String
    private let cancelThreshold: CGFloat
    private let onStart: (() -> Void)?
    private let onEnd: (() -> Void)?
    private let onCancel: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var pressing = false
    @State private var willCancel = false

    public init(label: String = "Hold to talk",
                recordingLabel: String = "Release to send · slide up to cancel",
                cancelLabel: String = "Release to cancel",
                cancelThreshold: CGFloat = 80,
                onStart: (() -> Void)? = nil, onEnd: (() -> Void)? = nil,
                onCancel: (() -> Void)? = nil) {
        self.label = label; self.recordingLabel = recordingLabel
        self.cancelLabel = cancelLabel; self.cancelThreshold = cancelThreshold
        self.onStart = onStart; self.onEnd = onEnd; self.onCancel = onCancel
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let bg = !pressing ? colors.bgSecondary : (willCancel ? colors.error : colors.primary)
        let fg = !pressing ? colors.textSecondary : Color.white
        Text(pressing ? (willCancel ? cancelLabel : recordingLabel) : label)
            .font(.system(size: FlareSizes.fontSizeLg, weight: .medium))
            .foregroundColor(fg)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(bg))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        if !pressing { pressing = true; willCancel = false; onStart?() }
                        let cancel = v.translation.height < -cancelThreshold
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

/// The composer's bottom function area (下方功能区) — an inline grid of attachment
/// actions. Composable part; reveal it under the input. Shares
/// ``FlareComposerAction`` with the action sheet.
public struct FlareComposerActionPanel: View {
    private let actions: [FlareComposerAction]
    private let columns: Int
    private let onAction: ((FlareComposerAction) -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(actions: [FlareComposerAction] = MessageActionSheetView.defaultActions,
                columns: Int = 4, onAction: ((FlareComposerAction) -> Void)? = nil) {
        self.actions = actions; self.columns = columns; self.onAction = onAction
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns),
                  spacing: FlareSizes.spacingLg) {
            ForEach(actions) { action in
                Button { onAction?(action) } label: {
                    VStack(spacing: FlareSizes.spacingXs) {
                        ZStack {
                            RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary)
                                .frame(width: 52, height: 52)
                            Image(systemName: action.systemImage).font(.system(size: 24))
                                .foregroundColor(colors.textPrimary)
                        }
                        Text(action.label).font(.system(size: FlareSizes.fontSizeXs))
                            .foregroundColor(colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(FlareSizes.spacingLg)
        .frame(maxWidth: .infinity)
        .background(colors.bgPrimary)
    }
}

/// Send button (发送) — a composable composer part. Brand-purple when active,
/// disabled otherwise; fires onSend only when active.
public struct FlareComposerSendButton: View {
    private let active: Bool
    private let onSend: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(active: Bool, onSend: (() -> Void)? = nil) {
        self.active = active
        self.onSend = onSend
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        Button { if active { onSend?() } } label: {
            Image(systemName: "arrow.up")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(active ? .white : colors.textDisabled)
                .frame(width: 34, height: 34)
                .background(Circle().fill(active ? colors.primary : colors.bgDisabled))
        }
        .buttonStyle(.plain)
        .disabled(!active)
    }
}

/// Reply strip (回复条) — a composable composer part shown above the input when
/// replying. Left brand rail + sender / summary + cancel.
public struct FlareComposerReplyStrip: View {
    private let senderName: String
    private let summary: String
    private let label: String
    private let onCancel: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(senderName: String, summary: String, label: String = "Reply",
                onCancel: (() -> Void)? = nil) {
        self.senderName = senderName
        self.summary = summary
        self.label = label
        self.onCancel = onCancel
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(label) \(senderName)")
                    .font(.system(size: FlareSizes.fontSizeXs, weight: .semibold))
                    .foregroundColor(colors.primary)
                Text(summary)
                    .font(.system(size: FlareSizes.fontSizeSm))
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Button { onCancel?() } label: {
                Image(systemName: "xmark").font(.system(size: 14)).foregroundColor(colors.textTertiary)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, FlareSizes.spacingSm).padding(.vertical, FlareSizes.spacingXs)
        .background(
            RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(colors.bgSecondary)
        )
        .overlay(
            HStack { Rectangle().fill(colors.primary).frame(width: 3); Spacer() }
                .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusMd))
        )
    }
}
