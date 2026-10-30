import SwiftUI

/// A forward record (chat history card), drawn as Vue's ForwardView draws it. Spec: spec/message-forward-vectors.json.
///
/// - No items: one line, "暂无转发内容". One item that was not sent merged: that item's content as it is (its plain
///   text when it carries no content). Otherwise the card: the title (the record's, else "合并转发"), "共 N 条消息"
///   past one item, the first three items as "sender: summary" lines, "还有 N 条消息…" past three, and the hint
///   "点击查看详情".
/// - The whole card is one button, named "{title}，{subtitle}". It opens the kit side drawer
///   (``SwiftUI/View/flareDrawer(isPresented:title:titleHidden:label:placement:width:dismissible:showClose:showBack:navigable:compactFallback:actions:footer:onBack:onDismiss:content:)``)
///   titled "{title}（N 条）" that lists every item: the sender's initial, the sender, the time (the clock on the same
///   day, else the month and day with the clock, in the environment locale), the summary line and, for content other
///   than text, the content drawn under it.
/// - In multi-select (`selectionMode`) the card does not respond. `shell` draws the kit card shell around it; a
///   ``MessageContentView`` on the card surface draws the shell itself and passes false.
public struct FlareForwardMessageView: View {
    private let content: FlareForwardContent
    private let isSelf: Bool
    private let selectionMode: Bool
    private let shell: Bool
    @State private var showsDetails = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.locale) private var locale

    public init(content: FlareForwardContent, isSelf: Bool = false, selectionMode: Bool = false, shell: Bool = true) {
        self.content = content; self.isSelf = isSelf; self.selectionMode = selectionMode; self.shell = shell
    }

    /// Test hook: the card's button.
    static let cardID = "flare-forward-record-card"

    public var body: some View {
        let record = flareForwardRecordView(content, strings: strings, locale: locale)
        if shell {
            FlareMessageCardShell(padded: Self.padded(content, record.layout)) { recordBody(record) }
        } else {
            recordBody(record)
        }
    }

    /// The shell pads everything but a single forwarded picture or video, which runs to its edges.
    static func padded(_ content: FlareForwardContent, _ layout: FlareForwardRecordView.Layout) -> Bool {
        guard layout == .single, let body = content.items.first?.content else { return true }
        return !(body is FlareImageContent || body is FlareVideoContent || body is FlareImageGroupContent
            || body is FlareStickerContent)
    }

    @ViewBuilder private func recordBody(_ record: FlareForwardRecordView) -> some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        switch record.layout {
        case .empty:
            Text(strings.forwardRecordEmpty)
                .font(.system(size: FlareSizes.fontSizeMd))
                .foregroundColor(colors.textTertiary)
        case .single:
            let item = content.items[0]
            // Drawn in the record's shell, as someone else's message whoever forwarded it: the neutral palette, never
            // the forwarder's bubble colours.
            MessageContentView(content: item.content ?? FlareTextContent(item.plainText), isSelf: false,
                               senderName: item.senderName, selectionMode: selectionMode)
                .onSurface(.bareMedia)
                .environment(\.flareMessageBodyForeground, colors.textPrimary)
        case .card:
            card(record, colors)
        }
    }

    private func card(_ record: FlareForwardRecordView, _ colors: FlareColors) -> some View {
        Button { showsDetails = true } label: {
            VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                Text(record.title)
                    .font(.system(size: FlareSizes.fontSizeLg, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                if let subtitle = record.subtitle {
                    Text(subtitle).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(record.previews.enumerated()), id: \.offset) { _, preview in
                        Text("\(preview.sender): \(preview.text)")
                            .font(.system(size: FlareSizes.fontSizeMd))
                            .foregroundColor(colors.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    if let more = record.more {
                        Text(more).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                    }
                }
                .padding(.top, FlareSizes.spacingXs)
                Divider().overlay(colors.borderSecondary).padding(.top, FlareSizes.spacingXs)
                Text(record.hint).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(selectionMode)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(record.label)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(Self.cardID)
        .flareDrawer(isPresented: $showsDetails, title: record.drawerTitle) {
            ForwardRecordDetails(content: content)
        }
    }
}

/// The drawer's list: every forwarded item, each drawn as someone else's message whoever forwarded the record — the
/// drawer's neutral palette, never the forwarder's bubble colours (`spec/message-forward-vectors.json` rules.palette).
struct ForwardRecordDetails: View {
    let content: FlareForwardContent
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.locale) private var locale

    /// The initial drawn for a sender (``flareForwardSenderInitial(_:)``).
    static func initial(_ item: FlareForwardItem) -> String { flareForwardSenderInitial(item) }

    /// Whether the item's content is drawn under its summary: any content but text.
    static func drawsContent(_ item: FlareForwardItem) -> Bool {
        guard let content = item.content else { return false }
        return !(content is FlareTextContent)
    }

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(content.items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: FlareSizes.spacingMd) {
                        Text(Self.initial(item))
                            .font(.system(size: FlareSizes.fontSizeMd, weight: .semibold))
                            .foregroundColor(colors.primaryText)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(colors.bgTertiary))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                            HStack(spacing: FlareSizes.spacingSm) {
                                Text(flareForwardSender(item, strings: strings))
                                    .font(.system(size: FlareSizes.fontSizeMd, weight: .medium))
                                    .foregroundColor(colors.textPrimary)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                                if item.sentAtMs > 0 {
                                    Text(FlareTimeFormat.dateTime(Date(timeIntervalSince1970: TimeInterval(item.sentAtMs) / 1000),
                                                                  locale: locale))
                                        .font(.system(size: FlareSizes.fontSizeSm))
                                        .foregroundColor(colors.textTertiary)
                                }
                            }
                            Text(flareForwardSummary(item, strings: strings, locale: locale))
                                .font(.system(size: FlareSizes.fontSizeMd))
                                .foregroundColor(colors.textSecondary)
                                .lineLimit(1)
                            if Self.drawsContent(item), let body = item.content {
                                MessageContentView(content: body, isSelf: false, senderName: item.senderName)
                                    .onSurface(.bareMedia)
                                    .environment(\.flareMessageBodyForeground, colors.textPrimary)
                                    .padding(.top, FlareSizes.spacingXs)
                            }
                        }
                    }
                    .padding(.horizontal, FlareSizes.spacingLg)
                    .padding(.vertical, FlareSizes.spacingMd)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}
