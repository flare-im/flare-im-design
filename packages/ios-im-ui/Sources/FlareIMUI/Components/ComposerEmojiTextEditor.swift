import Foundation
import SwiftUI

struct ComposerEmojiTokenRun: Equatable {
    let range: NSRange
    let key: String
}

/// Known protocol emoji tokens in UTF-16 coordinates, ready for native text
/// storage. Unknown bracket text stays ordinary editable text.
func composerEmojiTokenRuns(
    _ text: String,
    isKnown: (String) -> Bool = FlareEmojiStickerCatalog.shared.hasEmojiKey
) -> [ComposerEmojiTokenRun] {
    guard let expression = try? NSRegularExpression(pattern: "\\[([a-z][a-z0-9_]*)\\]") else { return [] }
    let source = text as NSString
    return expression.matches(in: text, range: NSRange(location: 0, length: source.length)).compactMap { match in
        let key = source.substring(with: match.range(at: 1))
        return isKnown(key) ? ComposerEmojiTokenRun(range: match.range, key: key) : nil
    }
}

/// Editable composer input that displays bundled emoji-pack images while the
/// binding remains the raw `[key]` protocol text used by drafts and sending.
struct FlareComposerEmojiTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let disabled: Bool
    let expanded: Bool
    let fontSize: CGFloat
    let bold: Bool
    let italic: Bool
    let strike: Bool
    let underline: Bool
    let textColor: Color
    let hintColor: Color
    @ObservedObject private var catalog = FlareEmojiStickerCatalog.shared

    var body: some View {
        #if canImport(UIKit)
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: fontSize))
                    .foregroundStyle(hintColor)
                    .allowsHitTesting(false)
            }
            FlareComposerEmojiUIKitEditor(
                text: $text,
                disabled: disabled,
                expanded: expanded,
                fontSize: fontSize,
                bold: bold,
                italic: italic,
                strike: strike,
                underline: underline,
                textColor: textColor
            )
        }
        #else
        TextField(placeholder, text: $text, axis: .vertical)
            .lineLimit(expanded ? 9...14 : 1...5)
            .font(.system(size: fontSize, weight: bold ? .bold : .regular))
            .italic(italic)
            .strikethrough(strike)
            .underline(underline)
            .foregroundStyle(textColor)
            .disabled(disabled)
        #endif
    }
}

#if canImport(UIKit)
import UIKit

private final class FlareComposerEmojiAttachment: NSTextAttachment {
    let token: String

    init(token: String, image: UIImage) {
        self.token = token
        super.init(data: nil, ofType: nil)
        self.image = image
        bounds = CGRect(x: 0, y: -4, width: 26, height: 26)
    }

    required init?(coder: NSCoder) {
        token = coder.decodeObject(forKey: "flareToken") as? String ?? ""
        super.init(coder: coder)
    }

    override func encode(with coder: NSCoder) {
        coder.encode(token, forKey: "flareToken")
        super.encode(with: coder)
    }
}

private struct FlareComposerEmojiUIKitEditor: UIViewRepresentable {
    @Binding var text: String
    let disabled: Bool
    let expanded: Bool
    let fontSize: CGFloat
    let bold: Bool
    let italic: Bool
    let strike: Bool
    let underline: Bool
    let textColor: Color

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.isScrollEnabled = false
        view.isEditable = !disabled
        view.isSelectable = true
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        context.coordinator.render(text, in: view, moveCaretToEnd: true)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.parent = self
        view.isEditable = !disabled
        let serialized = context.coordinator.rawText(from: view.attributedText)
        if serialized != text || context.coordinator.presentationChanged {
            context.coordinator.render(text, in: view, moveCaretToEnd: serialized != text)
        } else {
            context.coordinator.applyTypingAttributes(to: view)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0 else { return nil }
        let measured = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let maximum = expanded ? CGFloat(294) : CGFloat(112)
        return CGSize(width: width, height: min(max(24, measured.height), maximum))
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: FlareComposerEmojiUIKitEditor
        private var rendering = false
        private var lastPresentationKey = ""

        init(_ parent: FlareComposerEmojiUIKitEditor) { self.parent = parent }

        var presentationChanged: Bool { lastPresentationKey != presentationKey }

        private var presentationKey: String {
            "\(parent.fontSize)|\(parent.bold)|\(parent.italic)|\(parent.strike)|\(parent.underline)|\(UIColor(parent.textColor).description)"
        }

        func textViewDidChange(_ textView: UITextView) {
            guard !rendering else { return }
            let raw = rawText(from: textView.attributedText)
            if parent.text != raw { parent.text = raw }
        }

        func render(_ raw: String, in view: UITextView, moveCaretToEnd: Bool) {
            rendering = true
            let result = NSMutableAttributedString()
            let source = raw as NSString
            var cursor = 0
            for run in composerEmojiTokenRuns(raw) {
                if run.range.location > cursor {
                    result.append(NSAttributedString(string: source.substring(with: NSRange(
                        location: cursor,
                        length: run.range.location - cursor
                    ))))
                }
                if let image = FlareEmojiStickerCatalog.shared.emojiStaticImage(run.key) {
                    result.append(NSAttributedString(attachment: FlareComposerEmojiAttachment(
                        token: source.substring(with: run.range),
                        image: image
                    )))
                } else {
                    result.append(NSAttributedString(string: source.substring(with: run.range)))
                }
                cursor = run.range.location + run.range.length
            }
            if cursor < source.length {
                result.append(NSAttributedString(string: source.substring(from: cursor)))
            }
            result.addAttributes(textAttributes, range: NSRange(location: 0, length: result.length))
            let oldSelection = view.selectedRange
            view.attributedText = result
            let requested = moveCaretToEnd ? result.length : min(oldSelection.location, result.length)
            view.selectedRange = NSRange(location: requested, length: 0)
            applyTypingAttributes(to: view)
            lastPresentationKey = presentationKey
            rendering = false
        }

        func rawText(from value: NSAttributedString?) -> String {
            guard let value, value.length > 0 else { return "" }
            var raw = ""
            value.enumerateAttributes(in: NSRange(location: 0, length: value.length)) { attributes, range, _ in
                if let attachment = attributes[.attachment] as? FlareComposerEmojiAttachment {
                    raw += attachment.token
                } else {
                    raw += value.attributedSubstring(from: range).string
                }
            }
            return raw
        }

        func applyTypingAttributes(to view: UITextView) {
            view.typingAttributes = textAttributes
            view.tintColor = UIColor(parent.textColor)
        }

        private var textAttributes: [NSAttributedString.Key: Any] {
            var traits: UIFontDescriptor.SymbolicTraits = []
            if parent.bold { traits.insert(.traitBold) }
            if parent.italic { traits.insert(.traitItalic) }
            let base = UIFont.systemFont(ofSize: parent.fontSize)
            let descriptor = base.fontDescriptor.withSymbolicTraits(traits) ?? base.fontDescriptor
            var attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(descriptor: descriptor, size: parent.fontSize),
                .foregroundColor: UIColor(parent.textColor),
            ]
            if parent.strike { attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue }
            if parent.underline { attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue }
            return attributes
        }
    }
}
#endif
