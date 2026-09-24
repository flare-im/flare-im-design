import SwiftUI

/// The message input — plain or rich text, attach, emoji, send, optional reply
/// strip. Spec: Composer/Composer (`ComposerView`). Send is optimistic: `onSend`
/// fires immediately; the host owns local echo and persistence.

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

/// The composer's mention flow as values, so the rules hold without a screen: whether the picker is
/// open and where the typed "@" that opened it is. A pick writes "@label " into the text; the core finds
/// the mentions in the text when the message is built, so a send carries only the text (as on Vue).
struct ComposerMentionFlow {
    private(set) var open = false
    /// Character offset of the typed "@" that opened the picker; nil when the mention key opened it.
    private(set) var trigger: Int?

    /// The mention key toggles the picker; a picked name then goes at the end of the text.
    mutating func toggleFromKey() {
        trigger = nil
        open.toggle()
    }

    /// Opens the picker when the edit typed an "@" at the start of a word; true when it opened.
    mutating func textChanged(previous: String, next: String) -> Bool {
        guard !open, let index = ComposerView.typedMentionTrigger(previous: previous, next: next) else { return false }
        trigger = index
        open = true
        return true
    }

    /// Puts "@label " into `text` (over the typed "@"), closes the picker and returns the new text. The
    /// label is the candidate's name — the roster display name the core matches — and the everyone
    /// candidate is written with `everyoneLabel`.
    mutating func pick(_ candidate: MentionCandidate, into text: String, everyoneLabel: String) -> String {
        let name = candidate.isEveryone ? everyoneLabel : candidate.name
        let updated = ComposerView.insertingMention(name, into: text, at: trigger)
        close()
        return updated
    }

    mutating func close() {
        open = false
        trigger = nil
    }
}

public struct ComposerView: View {
    private let rich: Bool
    private let placeholder: String?
    private let disabled: Bool
    private let replyTo: FlareReplyTarget?
    private let replyLabel: String?
    private let maxLength: Int?
    private let onSend: ((String) -> Void)?
    private let onAttach: (() -> Void)?
    private let onEmoji: (() -> Void)?
    /// A sticker the person picked in the composer's own panel (FR-097): the host sends it.
    private let onSendSticker: ((_ packageId: String, _ stickerId: String) -> Void)?
    private let onCancelReply: (() -> Void)?
    private let actions: [FlareComposerAction]?
    private let capabilities: FlareComposerCapabilities
    private let onAction: ((FlareComposerAction) -> Void)?
    private let onVoiceSend: ((URL, Int) async -> Bool)?
    private let enableVoice: Bool
    private let onVoiceStart: (() -> Void)?
    private let onVoiceEnd: (() -> Void)?
    private let onVoiceCancel: (() -> Void)?
    private let voiceLabel: String?
    private let voiceRecordingLabel: String?
    private let voiceCancelLabel: String?
    private let sendAccent: AnyShapeStyle?
    private let mentionCandidates: [MentionCandidate]

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @State private var localText = ""
    private let draft: Binding<String>?
    private let onImage: (() -> Void)?
    private let onSendRich: ((String) -> Void)?
    private let onUserInput: ((String) -> Void)?
    @State private var expanded = false
    @State private var formatMode = false
    @State private var formats: Set<String> = []
    @State private var width: CGFloat = 0
    private var text: String {
        get { draft?.wrappedValue ?? localText }
        nonmutating set { if let draft { draft.wrappedValue = newValue } else { localText = newValue } }
    }
    private var textBinding: Binding<String> {
        Binding(get: { text }, set: { value in
            let previous = text
            text = maxLength.map { String(value.prefix(max(0, $0))) } ?? value
            openMentionPickerIfTyped(previous: previous, next: text)
            // Only what the person did: the clear after a send writes `text` directly, so a host driving
            // a typing signal from here never reports its own edits as the user's.
            onUserInput?(text)
        })
    }
    @State private var voiceMode = false
    @State private var panelOpen = false
    /// The composer's own emoji and sticker panel, for hosts that do not mount one (FR-097).
    @State private var emojiOpen = false
    /// The mention picker's state: open or not, and the typed "@" that opened it.
    @State private var mentionFlow = ComposerMentionFlow()

    public init(
        text: Binding<String>? = nil,
        rich: Bool = false,
        placeholder: String? = nil,
        disabled: Bool = false,
        replyTo: FlareReplyTarget? = nil,
        /// Prefix on the reply strip above the input, e.g. "Reply Ivy".
        replyLabel: String? = nil,
        maxLength: Int? = nil,
        /// Optional brand accent for the active send button (e.g. a gradient). Defaults to `primary`.
        sendAccent: AnyShapeStyle? = nil,
        onSend: ((String) -> Void)? = nil,
        /// Every edit the person makes to the text — not the clear after a send, and not a text the host
        /// sets. Hosts drive the typing signal (``FlareTypingSignal``) from this.
        onUserInput: ((String) -> Void)? = nil,
        onAttach: (() -> Void)? = nil,
        onImage: (() -> Void)? = nil,
        onSendRich: ((String) -> Void)? = nil,
        onEmoji: (() -> Void)? = nil,
        onSendSticker: ((_ packageId: String, _ stickerId: String) -> Void)? = nil,
        onCancelReply: (() -> Void)? = nil,
        actions: [FlareComposerAction]? = nil,
        capabilities: FlareComposerCapabilities = FlareComposerCapabilities(),
        onAction: ((FlareComposerAction) -> Void)? = nil,
        enableVoice: Bool = false,
        onVoiceSend: ((URL, Int) async -> Bool)? = nil,
        /// Hold-to-talk labels — forwarded to `FlareVoiceHoldButton` so hosts can localize them.
        voiceLabel: String? = nil,
        voiceRecordingLabel: String? = nil,
        voiceCancelLabel: String? = nil,
        onVoiceStart: (() -> Void)? = nil,
        onVoiceEnd: (() -> Void)? = nil,
        onVoiceCancel: (() -> Void)? = nil,
        /// The people the mention key offers (a group's members, without the current user), each named by
        /// the roster display name the core matches mentions against. With any, the mention key and an "@"
        /// typed at the start of a word open the kit ``MentionPickerView`` above the input (everyone first),
        /// and picking someone puts "@name " into the text; `onSend` still sends the text, and the core
        /// finds the mentions in it. Empty keeps the key typing "@".
        mentionCandidates: [MentionCandidate] = []
    ) {
        self.draft = text; self.onImage = onImage; self.onSendRich = onSendRich
        self.onUserInput = onUserInput
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
        self.onSendSticker = onSendSticker
        self.onCancelReply = onCancelReply
        self.actions = actions
        self.capabilities = capabilities
        self.onAction = onAction
        self.enableVoice = enableVoice
        self.onVoiceSend = onVoiceSend
        self.voiceLabel = voiceLabel
        self.voiceRecordingLabel = voiceRecordingLabel
        self.voiceCancelLabel = voiceCancelLabel
        self.onVoiceStart = onVoiceStart
        self.onVoiceEnd = onVoiceEnd
        self.onVoiceCancel = onVoiceCancel
        self.mentionCandidates = mentionCandidates
    }

    private var canSend: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !disabled }
    private var resolvedActions: [FlareComposerAction] {
        resolveComposerActions(
            defaults: FlareComposerActionPanel.actions(for: strings),
            capabilities: capabilities,
            actions: actions
        )
    }
    private var hasActionPanel: Bool { onAction != nil && !resolvedActions.isEmpty }
    private var hasMentionPicker: Bool { !mentionCandidates.isEmpty }

    /// Copy in effect: an explicit parameter wins, otherwise the `flareStrings` provider.
    struct Copy {
        let placeholder, replyLabel, voiceLabel, voiceRecordingLabel: String
        let voiceCancelLabel: String
    }
    func resolveCopy(_ strings: FlareStrings) -> Copy {
        Copy(
            placeholder: placeholder ?? strings.composerPlaceholder,
            replyLabel: replyLabel ?? strings.composerReply,
            voiceLabel: voiceLabel ?? strings.voiceHoldButtonLabel,
            voiceRecordingLabel: voiceRecordingLabel ?? strings.voiceHoldButtonRecording,
            voiceCancelLabel: voiceCancelLabel ?? strings.releaseToCancel
        )
    }
    private var copy: Copy { resolveCopy(strings) }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let m = ComposerMetrics.of(width: width, keys: 6 + ((enableVoice && onVoiceSend != nil) ? 1 : 0))
        VStack(spacing: 0) {
            if let replyTo { replyStrip(replyTo, colors, m) }
            if mentionFlow.open, hasMentionPicker, !voiceMode {
                MentionPickerView(candidates: mentionCandidates, allowEveryone: true,
                                  onSelect: pickMention, onClose: closeMentionPicker)
                    .padding(.horizontal, m.band ? FlareSizes.spacingSm : 0)
                    .padding(.vertical, FlareSizes.spacingXs)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if voiceMode, let onVoiceSend {
                InlineVoiceComposerView(disabled: disabled, onKeyboard: { voiceMode = false }, onSend: onVoiceSend)
            } else {
                VStack(spacing: 0) {
                    if !panelOpen {
                        if rich || formatMode { formatStrip(colors, m) }
                        HStack(alignment: .top, spacing: 0) {
                            Group {
                                FlareComposerEmojiTextEditor(
                                    text: textBinding,
                                    placeholder: copy.placeholder,
                                    disabled: disabled,
                                    expanded: expanded,
                                    fontSize: formats.contains("heading") ? 17 : 15,
                                    bold: formats.contains("bold"),
                                    italic: formats.contains("italic"),
                                    strike: formats.contains("strike"),
                                    underline: formats.contains("link"),
                                    textColor: formats.contains("link") ? colors.primaryText : colors.textPrimary,
                                    hintColor: colors.textTertiary
                                )
                            }.padding(m.text)
                            iconButton(expanded ? "collapse" : "expand",
                                       label: expanded ? strings.composerCollapseInput : strings.composerExpandInput,
                                       { expanded.toggle() }, colors)
                        }
                    }
                    if !m.band { toolbar(colors, distributed: false) }
                }
                .background(colors.bgPrimary)
                .overlay { if !m.band { RoundedRectangle(cornerRadius: FlareSizes.radiusCard).strokeBorder(colors.borderPrimary, lineWidth: 1) } }
                // The tools leave the band and rest on the ground, taking back
                // the inset the band gave up.
                if m.band { toolbar(colors, distributed: true).padding(.horizontal, m.toolInset) }
                if emojiOpen, onEmoji == nil {
                    FlareEmojiStickerPicker(emojiLabel: strings.composerEmoji, height: 240,
                                            onInsertEmoji: { key in text = (maxLength.map { String((text + "[\(key)]").prefix(max(0, $0))) } ?? text + "[\(key)]") },
                                            onSendSticker: { package, sticker in emojiOpen = false; onSendSticker?(package, sticker) })
                }
                if panelOpen, hasActionPanel {
                    ScrollView(showsIndicators: false) { FlareComposerActionPanel(actions: resolvedActions) { a in onAction?(a); panelOpen = false } }
                        .frame(height: min(240, CGFloat((resolvedActions.count + 3) / 4) * 84 + 24))
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
            // A host that handles the key keeps its own panel; otherwise the composer opens its own.
            iconButton("emoji", label: strings.composerEmoji,
                       onEmoji ?? { emojiOpen.toggle(); panelOpen = false }, colors, active: emojiOpen)
            if distributed { Spacer(minLength: 0) }
            iconButton("mention", label: strings.composerMention, mentionKey, colors, active: mentionFlow.open)
            if distributed { Spacer(minLength: 0) }
            if enableVoice && onVoiceSend != nil {
                iconButton("mic", label: strings.composerVoice, { voiceMode = true; panelOpen = false }, colors)
                if distributed { Spacer(minLength: 0) }
            }
            iconButton("image", label: strings.composerImage, onImage ?? onAttach, colors)
            if distributed { Spacer(minLength: 0) }
            iconButton("rich-text", label: strings.composerRichText,
                       { formatMode.toggle(); if !formatMode { formats = [] }; panelOpen = false }, colors,
                       active: rich || formatMode)
            if distributed { Spacer(minLength: 0) }
            iconButton(
                panelOpen ? "close" : "add",
                label: strings.composerMore,
                hasActionPanel ? { panelOpen.toggle() } : onAttach,
                colors,
                active: panelOpen
            )
            if distributed { Spacer(minLength: 0) }
            FlareComposerSendButton(active: canSend, onSend: send)
        }
    }

    /// The format keys in strip order: format id, SF Symbol (a kit icon where the registry has the
    /// concept) and the key's name.
    static func formatKeys(_ strings: FlareStrings) -> [(id: String, symbol: String, label: String)] {
        [("bold", "bold", strings.composerFormatBold),
         ("italic", "italic", strings.composerFormatItalic),
         ("strike", "strikethrough", strings.composerFormatStrike),
         ("code", "chevron.left.forwardslash.chevron.right", strings.composerFormatCode),
         ("link", flareIconSymbol("link"), strings.composerFormatLink),
         ("heading", "textformat.size", strings.composerFormatHeading),
         ("quote", flareIconSymbol("quote"), strings.composerFormatQuote),
         ("bullet", "list.bullet", strings.composerFormatBullet),
         ("ordered", "list.number", strings.composerFormatOrdered)]
    }

    private func formatStrip(_ colors: FlareColors, _ m: ComposerMetrics) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Self.formatKeys(strings), id: \.id) { key in
                    let on = formats.contains(key.id)
                    Button { toggleFormat(key.id) } label: {
                        Image(systemName: key.symbol).font(.system(size: 14))
                            .frame(width: m.stripKey.width, height: m.stripKey.height).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain).foregroundColor(on ? colors.primaryText : colors.textSecondary)
                    .accessibilityLabel(key.label)
                    .accessibilityAddTraits(on ? .isSelected : [])
                    .disabled(disabled)
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
                Text("\(copy.replyLabel) \(r.senderName)").font(.system(size: FlareSizes.fontSizeXs, weight: .semibold))
                    .foregroundColor(colors.primaryText)
                Text(r.summary).font(.system(size: FlareSizes.fontSizeSm))
                    .foregroundColor(colors.textSecondary).lineLimit(1)
            }
            Spacer()
            Button { onCancelReply?() } label: {
                Image(systemName: flareIconSymbol("close")).font(.system(size: 14)).foregroundColor(colors.textTertiary)
                    .flareTouchTarget()
            }
            .buttonStyle(.plain)
            .flareCompactLayout(width: 14, height: 14)
            .accessibilityLabel(strings.cancelReply)
        }
        .padding(.horizontal, m.band ? 16 : FlareSizes.spacingSm).padding(.vertical, FlareSizes.spacingXs)
        .background(
            RoundedRectangle(cornerRadius: m.band ? 0 : FlareSizes.radiusMd)
                .fill(m.band ? colors.bgPrimary : colors.bgSecondary)
        )
        .overlay(Rectangle().fill(colors.primary).frame(width: 3), alignment: .leading)
        .overlay(alignment: .bottom) { if m.band { Rectangle().fill(colors.borderPrimary).frame(height: 1) } }
    }

    /// A composer tool key: the kit icon `icon`, named `label`; `active` is its on state (the rich-text
    /// mode, the open action panel), shown in the brand colour and exposed as selected.
    private func iconButton(_ icon: String, label: String, _ action: (() -> Void)?, _ colors: FlareColors,
                            active: Bool = false) -> some View {
        Button { action?() } label: {
            Image(systemName: flareIconSymbol(icon)).font(.system(size: 20))
                .frame(width: FlareSizes.touchTargetMin, height: FlareSizes.touchTargetMin).contentShape(Rectangle())
                .foregroundColor(active ? colors.primaryText : colors.textSecondary)
        }
        .buttonStyle(.plain).disabled(disabled || action == nil)
        .accessibilityLabel(label)
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    private func send() {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !disabled, !t.isEmpty, onSend != nil || onSendRich != nil else { return }
        if (rich || formatMode), let onSendRich { onSendRich(formatted(t)) } else { onSend?(t) }
        text = ""
        mentionFlow.close()
    }

    // MARK: Mentions

    /// The mention key: the picker when there is someone to mention, else a typed "@".
    private func mentionKey() {
        panelOpen = false
        guard hasMentionPicker else { text += "@"; return }
        mentionFlow.toggleFromKey()
    }

    private func closeMentionPicker() {
        mentionFlow.close()
    }

    private func openMentionPickerIfTyped(previous: String, next: String) {
        guard hasMentionPicker, !(rich || formatMode) else { return }
        if mentionFlow.textChanged(previous: previous, next: next) { panelOpen = false }
    }

    private func pickMention(_ candidate: MentionCandidate) {
        textBinding.wrappedValue = mentionFlow.pick(candidate, into: text, everyoneLabel: strings.everyone)
    }

    /// Where a typed "@" opens the picker: a pure insertion (a keystroke, an IME commit or a paste) that
    /// ends in "@" at the start of a word. An "@" inside a word, such as an email address, stays text.
    static func typedMentionTrigger(previous: String, next: String) -> Int? {
        let old = Array(previous), new = Array(next)
        let inserted = new.count - old.count
        guard inserted >= 1 else { return nil }
        var start = 0
        while start < old.count, new[start] == old[start] { start += 1 }
        guard Array(new[(start + inserted)...]) == Array(old[start...]) else { return nil }
        let index = start + inserted - 1
        guard new[index] == "@", index == 0 || new[index - 1].isWhitespace else { return nil }
        return index
    }

    /// `text` with "@name " put in: over the typed "@" at `trigger` when it is still there, else at the
    /// end on a word boundary.
    static func insertingMention(_ name: String, into text: String, at trigger: Int?) -> String {
        let token = "@\(name) "
        var characters = Array(text)
        if let trigger, trigger < characters.count, characters[trigger] == "@" {
            characters.replaceSubrange(trigger...trigger, with: Array(token))
            return String(characters)
        }
        let separator = text.isEmpty || text.last?.isWhitespace == true ? "" : " "
        return text + separator + token
    }
}
