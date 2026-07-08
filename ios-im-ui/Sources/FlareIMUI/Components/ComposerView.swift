import SwiftUI

/// A lightweight reply target shown as a strip above the composer input.
public struct FlareReplyTarget {
    public let senderName: String
    public let summary: String
    public init(senderName: String, summary: String) {
        self.senderName = senderName; self.summary = summary
    }
}

/// The message input — plain or rich text, attach, emoji, send, optional reply
/// strip. Spec: Composer/Composer (`ComposerView`). Send is optimistic: `onSend`
/// fires immediately; the host does the local echo + core write.
public struct ComposerView: View {
    private let rich: Bool
    private let placeholder: String
    private let disabled: Bool
    private let replyTo: FlareReplyTarget?
    private let maxLength: Int?
    private let onSend: ((String) -> Void)?
    private let onAttach: (() -> Void)?
    private let onEmoji: (() -> Void)?
    private let onCancelReply: (() -> Void)?
    private let actions: [FlareComposerAction]?
    private let onAction: ((FlareComposerAction) -> Void)?
    private let enableVoice: Bool
    private let onVoiceStart: (() -> Void)?
    private let onVoiceEnd: (() -> Void)?

    @Environment(\.colorScheme) private var scheme
    @State private var text = ""
    @State private var voiceMode = false
    @State private var panelOpen = false

    public init(
        rich: Bool = false,
        placeholder: String = "Message",
        disabled: Bool = false,
        replyTo: FlareReplyTarget? = nil,
        maxLength: Int? = nil,
        onSend: ((String) -> Void)? = nil,
        onAttach: (() -> Void)? = nil,
        onEmoji: (() -> Void)? = nil,
        onCancelReply: (() -> Void)? = nil,
        actions: [FlareComposerAction]? = nil,
        onAction: ((FlareComposerAction) -> Void)? = nil,
        enableVoice: Bool = false,
        onVoiceStart: (() -> Void)? = nil,
        onVoiceEnd: (() -> Void)? = nil
    ) {
        self.rich = rich
        self.placeholder = placeholder
        self.disabled = disabled
        self.replyTo = replyTo
        self.maxLength = maxLength
        self.onSend = onSend
        self.onAttach = onAttach
        self.onEmoji = onEmoji
        self.onCancelReply = onCancelReply
        self.actions = actions
        self.onAction = onAction
        self.enableVoice = enableVoice
        self.onVoiceStart = onVoiceStart
        self.onVoiceEnd = onVoiceEnd
    }

    private var canSend: Bool { !text.trimmingCharacters(in: .whitespaces).isEmpty && !disabled }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(spacing: 0) {
            VStack(spacing: FlareSizes.spacingSm) {
                if let replyTo { replyStrip(replyTo, colors) }
                HStack(alignment: .bottom, spacing: FlareSizes.spacingSm) {
                    if enableVoice {
                        iconButton(voiceMode ? "keyboard" : "mic", { voiceMode.toggle() }, colors,
                                   active: voiceMode)
                    }
                    iconButton("plus.circle", {
                        if actions != nil { panelOpen.toggle() } else { onAttach?() }
                    }, colors, active: panelOpen)
                    if voiceMode {
                        FlareVoiceHoldButton(onStart: onVoiceStart, onEnd: onVoiceEnd)
                    } else {
                        inputField(colors)
                        iconButton("face.smiling", onEmoji, colors)
                        sendButton(colors)
                    }
                }
            }
            .padding(FlareSizes.spacingSm)

            if panelOpen, let actions {
                FlareComposerActionPanel(actions: actions) { a in
                    onAction?(a); panelOpen = false
                }
            }
        }
        .background(colors.bgPrimary)
        .overlay(Divider(), alignment: .top)
    }

    @ViewBuilder
    private func inputField(_ colors: FlareColors) -> some View {
        let field = Group {
            if rich {
                RichMarkdownInputView(text: $text, disabled: disabled,
                                      maxLength: maxLength, placeholder: placeholder)
            } else {
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder).foregroundColor(colors.textTertiary)
                            .font(.system(size: FlareSizes.fontSizeLg))
                    }
                    TextField("", text: $text, axis: .vertical)
                        .lineLimit(1...5).disabled(disabled)
                        .font(.system(size: FlareSizes.fontSizeLg))
                        .onSubmit(send)
                }
            }
        }
        field
            .padding(.horizontal, FlareSizes.spacingMd)
            .padding(.vertical, FlareSizes.spacingSm)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgSecondary))
    }

    private func replyStrip(_ r: FlareReplyTarget, _ colors: FlareColors) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Reply \(r.senderName)").font(.system(size: FlareSizes.fontSizeXs, weight: .semibold))
                    .foregroundColor(colors.primary)
                Text(r.summary).font(.system(size: FlareSizes.fontSizeSm))
                    .foregroundColor(colors.textSecondary).lineLimit(1)
            }
            Spacer()
            Button { onCancelReply?() } label: {
                Image(systemName: "xmark").font(.system(size: 14)).foregroundColor(colors.textTertiary)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, FlareSizes.spacingSm).padding(.vertical, FlareSizes.spacingXs)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(colors.bgSecondary))
        .overlay(Rectangle().fill(colors.primary).frame(width: 3), alignment: .leading)
    }

    private func iconButton(_ icon: String, _ action: (() -> Void)?, _ colors: FlareColors,
                            active: Bool = false) -> some View {
        Button { action?() } label: {
            Image(systemName: icon).font(.system(size: 24))
                .foregroundColor(active ? colors.primary : colors.textSecondary)
        }
        .buttonStyle(.plain).disabled(disabled)
    }

    private func sendButton(_ colors: FlareColors) -> some View {
        Button(action: send) {
            Image(systemName: "arrow.up").font(.system(size: 18, weight: .semibold))
                .foregroundColor(canSend ? .white : colors.textDisabled)
                .frame(width: 34, height: 34)
                .background(Circle().fill(canSend ? colors.primary : colors.bgDisabled))
        }
        .buttonStyle(.plain).disabled(!canSend)
    }

    private func send() {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        onSend?(t)
        text = ""
    }
}
