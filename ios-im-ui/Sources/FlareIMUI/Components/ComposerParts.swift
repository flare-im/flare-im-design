import SwiftUI

/// Hold-to-talk voice button (语音) — a composable composer part. Press and hold
/// to record, release to send. The host owns recording via the callbacks.
public struct FlareVoiceHoldButton: View {
    private let label: String
    private let recordingLabel: String
    private let onStart: (() -> Void)?
    private let onEnd: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var pressing = false

    public init(label: String = "按住 说话", recordingLabel: String = "松开 发送",
                onStart: (() -> Void)? = nil, onEnd: (() -> Void)? = nil) {
        self.label = label; self.recordingLabel = recordingLabel
        self.onStart = onStart; self.onEnd = onEnd
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        Text(pressing ? recordingLabel : label)
            .font(.system(size: FlareSizes.fontSizeLg, weight: .medium))
            .foregroundColor(pressing ? .white : colors.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl)
                .fill(pressing ? colors.primary : colors.bgSecondary))
            .onLongPressGesture(minimumDuration: 60, maximumDistance: 10000,
                                pressing: { p in
                                    pressing = p
                                    if p { onStart?() } else { onEnd?() }
                                }, perform: {})
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
    private let onCancel: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(senderName: String, summary: String, onCancel: (() -> Void)? = nil) {
        self.senderName = senderName
        self.summary = summary
        self.onCancel = onCancel
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text("回复 \(senderName)")
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
