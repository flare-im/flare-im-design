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

/// The two shapes a composer takes, resolved once so the layout below reads as
/// one composer with values in it rather than two layouts interleaved.
///
/// `band` is a phone: the field runs the full width of the screen with the
/// rounding taken off, and the tools rest on the app ground below it. Anything
/// wider keeps the bordered card the desktop layout is built around.
private struct ComposerMetrics {
    let band: Bool
    let text: EdgeInsets
    let stripKey: CGSize
    let stripInset: CGFloat
    let toolInset: CGFloat

    static func of(width: CGFloat, keys: Int) -> ComposerMetrics {
        guard width < 600 else {
            return .init(band: false, text: .init(top: 12, leading: 12, bottom: 8, trailing: 0),
                         stripKey: CGSize(width: 36, height: 32), stripInset: 0, toolInset: 0)
        }
        // 11 above and below a 24pt line is a 46pt band: the text sits in the
        // middle of it without the field growing into a panel of its own. The
        // tool inset is whatever the keys do not need, up to 10 — seven 44pt
        // targets already fill a 320pt screen, and the targets are the part
        // that must not shrink.
        return .init(band: true, text: .init(top: 11, leading: 16, bottom: 11, trailing: 0),
                     stripKey: CGSize(width: 44, height: 44), stripInset: 6,
                     toolInset: min(10, max(0, (width - CGFloat(keys) * 44) / 2)))
    }
}

public struct ComposerView: View {
    private let rich: Bool
    private let placeholder: String
    private let disabled: Bool
    private let replyTo: FlareReplyTarget?
    private let replyLabel: String
    private let maxLength: Int?
    private let onSend: ((String) -> Void)?
    private let onAttach: (() -> Void)?
    private let onEmoji: (() -> Void)?
    private let onCancelReply: (() -> Void)?
    private let actions: [FlareComposerAction]?
    private let onAction: ((FlareComposerAction) -> Void)?
    private let onVoiceSend: ((URL, Int) async -> Bool)?
    private let enableVoice: Bool
    private let onVoiceStart: (() -> Void)?
    private let onVoiceEnd: (() -> Void)?
    private let onVoiceCancel: (() -> Void)?
    private let voiceLabel: String
    private let voiceRecordingLabel: String
    private let voiceCancelLabel: String
    private let sendAccent: AnyShapeStyle?

    @Environment(\.colorScheme) private var scheme
    @State private var localText = ""
    private let draft: Binding<String>?
    private let onImage: (() -> Void)?
    private let onSendRich: ((String) -> Void)?
    @State private var expanded = false
    @State private var formatMode = false
    @State private var formats: Set<String> = []
    @State private var width: CGFloat = 0
    private var text: String {
        get { draft?.wrappedValue ?? localText }
        nonmutating set { if let draft { draft.wrappedValue = newValue } else { localText = newValue } }
    }
    private var textBinding: Binding<String> { Binding(get: { text }, set: { value in text = maxLength.map { String(value.prefix(max(0, $0))) } ?? value }) }
    @State private var voiceMode = false
    @State private var panelOpen = false

    public init(
        text: Binding<String>? = nil,
        rich: Bool = false,
        placeholder: String = "输入消息",
        disabled: Bool = false,
        replyTo: FlareReplyTarget? = nil,
        /// Prefix on the reply strip above the input, e.g. "Reply Ivy".
        replyLabel: String = "回复",
        maxLength: Int? = nil,
        /// Optional brand accent for the active send button (e.g. a gradient). Defaults to `primary`.
        sendAccent: AnyShapeStyle? = nil,
        onSend: ((String) -> Void)? = nil,
        onAttach: (() -> Void)? = nil,
        onImage: (() -> Void)? = nil,
        onSendRich: ((String) -> Void)? = nil,
        onEmoji: (() -> Void)? = nil,
        onCancelReply: (() -> Void)? = nil,
        actions: [FlareComposerAction]? = nil,
        onAction: ((FlareComposerAction) -> Void)? = nil,
        enableVoice: Bool = false,
        onVoiceSend: ((URL, Int) async -> Bool)? = nil,
        /// Hold-to-talk labels — forwarded to `FlareVoiceHoldButton` so hosts can localize them.
        voiceLabel: String = "按住 说话",
        voiceRecordingLabel: String = "松开发送 · 上滑取消",
        voiceCancelLabel: String = "松开取消",
        onVoiceStart: (() -> Void)? = nil,
        onVoiceEnd: (() -> Void)? = nil,
        onVoiceCancel: (() -> Void)? = nil
    ) {
        self.draft = text; self.onImage = onImage; self.onSendRich = onSendRich
        self.rich = rich
        self.placeholder = placeholder
        self.disabled = disabled
        self.replyTo = replyTo
        self.replyLabel = replyLabel
        self.maxLength = maxLength
        self.sendAccent = sendAccent
        self.onSend = onSend
        self.onAttach = onAttach
        self.onEmoji = onEmoji
        self.onCancelReply = onCancelReply
        self.actions = actions
        self.onAction = onAction
        self.enableVoice = enableVoice
        self.onVoiceSend = onVoiceSend
        self.voiceLabel = voiceLabel
        self.voiceRecordingLabel = voiceRecordingLabel
        self.voiceCancelLabel = voiceCancelLabel
        self.onVoiceStart = onVoiceStart
        self.onVoiceEnd = onVoiceEnd
        self.onVoiceCancel = onVoiceCancel
    }

    private var canSend: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !disabled }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let m = ComposerMetrics.of(width: width, keys: 6 + ((enableVoice && onVoiceSend != nil) ? 1 : 0))
        VStack(spacing: 0) {
            if let replyTo { replyStrip(replyTo, colors, m) }
            if voiceMode, let onVoiceSend {
                InlineVoiceComposerView(disabled: disabled, onKeyboard: { voiceMode = false }, onSend: onVoiceSend)
            } else {
                VStack(spacing: 0) {
                    if !panelOpen {
                        if rich || formatMode { formatStrip(colors, m) }
                        HStack(alignment: .top, spacing: 0) {
                            Group {
                                TextField(placeholder, text: textBinding, axis: .vertical)
                                    .lineLimit(expanded ? 9...14 : 1...5)
                                    .font(.system(size: formats.contains("heading") ? 17 : 15, weight: formats.contains("bold") ? .bold : .regular))
                                    .italic(formats.contains("italic"))
                                    .strikethrough(formats.contains("strike"))
                                    .underline(formats.contains("link"))
                                    .disabled(disabled)
                            }.padding(m.text)
                            iconButton(expanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right", { expanded.toggle() }, colors)
                        }
                    }
                    if !m.band { toolbar(colors, distributed: false) }
                }
                .background(colors.bgPrimary)
                .overlay { if !m.band { RoundedRectangle(cornerRadius: 12).strokeBorder(colors.borderPrimary, lineWidth: 1) } }
                // The tools leave the band and rest on the ground, taking back
                // the inset the band gave up.
                if m.band { toolbar(colors, distributed: true).padding(.horizontal, m.toolInset) }
                if panelOpen, let actions {
                    ScrollView(showsIndicators: false) { FlareComposerActionPanel(actions: actions) { a in onAction?(a); panelOpen = false } }
                        .frame(height: min(240, CGFloat((actions.count + 3) / 4) * 84 + 24))
                        .background(colors.bgPrimary)
                }
            }
        }.padding(.horizontal, m.band ? 0 : 4).padding(.top, m.band ? 0 : 8).padding(.bottom, m.band ? 4 : 8)
        .background(m.band ? colors.bgSecondary : colors.bgPrimary)
        .background(GeometryReader { proxy in Color.clear.onAppear { width = proxy.size.width }.onChange(of: proxy.size.width) { width = $0 } })
    }

    private func toolbar(_ colors: FlareColors, distributed: Bool) -> some View {
        HStack(spacing: 0) {
            if !distributed { Spacer(minLength: 0) }
            iconButton("face.smiling", onEmoji, colors)
            if distributed { Spacer(minLength: 0) }
            iconButton("at", { text += "@"; panelOpen = false }, colors)
            if distributed { Spacer(minLength: 0) }
            if enableVoice && onVoiceSend != nil { iconButton("mic", { voiceMode = true; panelOpen = false }, colors); if distributed { Spacer(minLength: 0) } }
            iconButton("photo", onImage ?? onAttach, colors)
            if distributed { Spacer(minLength: 0) }
            iconButton("textformat", { formatMode.toggle(); if !formatMode { formats = [] }; panelOpen = false }, colors, active: rich || formatMode)
            if distributed { Spacer(minLength: 0) }
            iconButton(panelOpen ? "xmark" : "plus", { if actions != nil { panelOpen.toggle() } else { onAttach?() } }, colors, active: panelOpen)
            if distributed { Spacer(minLength: 0) }
            FlareComposerSendButton(active: canSend, onSend: send)
        }
    }

    private func formatStrip(_ colors: FlareColors, _ m: ComposerMetrics) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach([("bold", "bold"), ("italic", "italic"), ("strike", "strikethrough"), ("code", "chevron.left.forwardslash.chevron.right"), ("link", "link"), ("heading", "textformat.size"), ("quote", "text.quote"), ("bullet", "list.bullet"), ("ordered", "list.number")], id: \.0) { item in
                    Button { toggleFormat(item.0) } label: {
                        Image(systemName: item.1).font(.system(size: 14)).frame(width: m.stripKey.width, height: m.stripKey.height).contentShape(Rectangle())
                    }.buttonStyle(.plain).foregroundColor(formats.contains(item.0) ? colors.primary : colors.textSecondary).accessibilityLabel(item.0).disabled(disabled)
                }
            }.padding(.horizontal, m.stripInset)
        }
        .frame(height: m.stripKey.height)
        .background(colors.bgPrimary)
        // The row is the top of the same band; a hairline is all that separates
        // it from the text it formats.
        .overlay(alignment: .bottom) { Rectangle().fill(colors.borderPrimary).frame(height: 1) }
    }
    private func toggleFormat(_ id: String) {
        if formats.contains(id) { formats.remove(id); return }
        let blocks: Set<String> = ["heading", "quote", "bullet", "ordered"]
        if blocks.contains(id) { formats.subtract(blocks) }
        formats.insert(id)
    }

    private func formatted(_ source: String) -> String {
        var orderedIndex = 0
        return source.components(separatedBy: "\n").enumerated().map { _, line in
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { return "" }
            orderedIndex += 1
            var value = line
            if formats.contains("link") { value = "[\(value)](\((value.hasPrefix("http://") || value.hasPrefix("https://")) ? value : "https://"))" }
            if formats.contains("code") { value = "`\(value)`" }
            if formats.contains("bold") { value = "**\(value)**" }
            if formats.contains("italic") { value = "*\(value)*" }
            if formats.contains("strike") { value = "~~\(value)~~" }
            if formats.contains("heading") { return "## " + value }
            if formats.contains("quote") { return "> " + value }
            if formats.contains("bullet") { return "- " + value }
            if formats.contains("ordered") { return "\(orderedIndex). " + value }
            return value
        }.joined(separator: "\n")
    }

    private func replyStrip(_ r: FlareReplyTarget, _ colors: FlareColors, _ m: ComposerMetrics) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(replyLabel) \(r.senderName)").font(.system(size: FlareSizes.fontSizeXs, weight: .semibold))
                    .foregroundColor(colors.primary)
                Text(r.summary).font(.system(size: FlareSizes.fontSizeSm))
                    .foregroundColor(colors.textSecondary).lineLimit(1)
            }
            Spacer()
            Button { onCancelReply?() } label: {
                Image(systemName: "xmark").font(.system(size: 14)).foregroundColor(colors.textTertiary)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, m.band ? 16 : FlareSizes.spacingSm).padding(.vertical, FlareSizes.spacingXs)
        .background(
            RoundedRectangle(cornerRadius: m.band ? 0 : FlareSizes.radiusMd)
                .fill(m.band ? colors.bgPrimary : colors.bgSecondary)
        )
        .overlay(Rectangle().fill(colors.primary).frame(width: 3), alignment: .leading)
        .overlay(alignment: .bottom) { if m.band { Rectangle().fill(colors.borderPrimary).frame(height: 1) } }
    }

    private func iconButton(_ icon: String, _ action: (() -> Void)?, _ colors: FlareColors,
                            active: Bool = false) -> some View {
        Button { action?() } label: {
            Image(systemName: icon).font(.system(size: 20)).frame(width: 44, height: 44).contentShape(Rectangle())
                .foregroundColor(active ? colors.primary : colors.textSecondary)
        }
        .buttonStyle(.plain).disabled(disabled || action == nil)
    }

    private func send() {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !disabled, !t.isEmpty, onSend != nil || onSendRich != nil else { return }
        if (rich || formatMode), let onSendRich { onSendRich(formatted(t)) } else { onSend?(t) }
        text = ""
    }
}
