import SwiftUI

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

    @Environment(\.colorScheme) private var scheme

    public init(
        text: Binding<String>,
        disabled: Bool = false,
        formattingPreview: Bool = false,
        showFormatBar: Bool = true,
        maxLength: Int? = nil,
        placeholder: String = ""
    ) {
        self._text = text
        self.disabled = disabled
        self.formattingPreview = formattingPreview
        self.showFormatBar = showFormatBar
        self.maxLength = maxLength
        self.placeholder = placeholder
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
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
                        .foregroundColor(text.count >= maxLength ? colors.error : colors.textTertiary)
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
            fmt("bold", "bold") { wrap("**", "**") }
            fmt("italic", "italic") { wrap("*", "*") }
            fmt("code", "chevron.left.forwardslash.chevron.right") { wrap("`", "`") }
            fmt("list", "list.bullet") { text += "\n- " }
            fmt("link", "link") { wrap("[", "](url)") }
        }
    }

    private func fmt(_ id: String, _ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(id)
    }

    private func wrap(_ l: String, _ r: String) {
        text = text.isEmpty ? l + r : l + text + r
    }
}
