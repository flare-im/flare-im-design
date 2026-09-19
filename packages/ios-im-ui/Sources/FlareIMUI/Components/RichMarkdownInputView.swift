import SwiftUI

public struct FlareRichMarkdownLabels: Sendable {
    public let bold: String
    public let italic: String
    public let code: String
    public let list: String
    public let link: String

    public init(bold: String = "加粗", italic: String = "斜体", code: String = "代码", list: String = "列表", link: String = "链接") {
        self.bold = bold; self.italic = italic; self.code = code; self.list = list; self.link = link
    }
}

/// The rich (RichDoc/Markdown) text field with a formatting bar, optional live
/// preview, and length limit. Spec: Composer/RichMarkdownInput
/// (`RichMarkdownInputView`). Used inside ``ComposerView``.
public struct RichMarkdownInputView: View {
    @Binding private var text: String
    private let disabled: Bool
    private let formattingPreview: Bool
    private let showFormatBar: Bool
    private let maxLength: Int?
    private let placeholder: String
    private let labels: FlareRichMarkdownLabels

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(
        text: Binding<String>,
        disabled: Bool = false,
        formattingPreview: Bool = false,
        showFormatBar: Bool = true,
        maxLength: Int? = nil,
        placeholder: String = "",
        labels: FlareRichMarkdownLabels = FlareRichMarkdownLabels()
    ) {
        self._text = text
        self.disabled = disabled
        self.formattingPreview = formattingPreview
        self.showFormatBar = showFormatBar
        self.maxLength = maxLength
        self.placeholder = placeholder
        self.labels = labels
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            if showFormatBar && !disabled { formatBar(colors) }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder).foregroundColor(colors.textTertiary)
                        .font(.system(size: FlareSizes.fontSizeLg)).padding(.top, 2)
                }
                TextField("", text: $text, axis: .vertical)
                    .lineLimit(1...6)
                    .disabled(disabled)
                    .font(.system(size: FlareSizes.fontSizeLg))
                    .foregroundColor(colors.textPrimary)
            }

            if let maxLength {
                HStack {
                    Spacer()
                    Text("\(text.count)/\(maxLength)")
                        .font(.system(size: FlareSizes.fontSizeXs))
                        .foregroundColor(text.count >= maxLength ? colors.errorText : colors.textTertiary)
                }
            }

            if formattingPreview && !text.trimmingCharacters(in: .whitespaces).isEmpty {
                Divider()
                MarkdownPreviewView(content: text)
            }
        }
    }

    private func formatBar(_ colors: FlareColors) -> some View {
        HStack(spacing: FlareSizes.spacingSm) {
            fmt(labels.bold, "bold") { wrap("**", "**") }
            fmt(labels.italic, "italic") { wrap("*", "*") }
            fmt(labels.code, "chevron.left.forwardslash.chevron.right") { wrap("`", "`") }
            fmt(labels.list, "list.bullet") { text += "\n- " }
            fmt(labels.link, "link") { wrap("[", "](url)") }
        }
    }

    private func fmt(_ label: String, _ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func wrap(_ l: String, _ r: String) {
        text = text.isEmpty ? l + r : l + text + r
    }
}
