import SwiftUI

/// What to show for a message this client cannot render. Spec: Message/UnknownMessage.
public struct FlareUnknownMessagePresentation: Equatable, Sendable {
    /// Human title: the host's label, else the generic "unsupported type" wording.
    public let title: String
    /// Human body: the sender's fallback text, else the generic hint.
    public let body: String
    /// Raw content type for the diagnostic row; empty means render no diagnostic.
    public let diagnostic: String
    /// True when `body` is the sender's real fallback rather than the generic hint.
    public let hasSummary: Bool
    public init(title: String, body: String, diagnostic: String, hasSummary: Bool) {
        self.title = title; self.body = body; self.diagnostic = diagnostic; self.hasSummary = hasSummary
    }
}

/// Deterministic and side-effect free, so the four platforms cannot drift on
/// which string wins. The raw type token is never promoted to the body: a reader
/// who sees only `[flare.poll.v2]` learns nothing and it reads as a rendering bug.
public func unknownMessagePresentation(contentType: String? = nil, label: String? = nil,
                                       summary: String? = nil, hint: String,
                                       unsupportedText: String) -> FlareUnknownMessagePresentation {
    func clean(_ value: String?) -> String {
        (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    let label = clean(label)
    let summary = clean(summary)
    return FlareUnknownMessagePresentation(
        title: label.isEmpty ? clean(unsupportedText) : label,
        body: summary.isEmpty ? clean(hint) : summary,
        diagnostic: clean(contentType),
        hasSummary: !summary.isEmpty
    )
}

/// Body for a message whose content type this client cannot render.
public struct UnknownMessageView: View {
    @Environment(\.colorScheme) private var scheme

    private let contentType: String?
    private let label: String?
    private let summary: String?
    private let isSelf: Bool
    private let actionText: String
    private let hint: String
    private let unsupportedText: String
    private let diagnosticLabel: String
    private let onAction: (() -> Void)?

    public init(contentType: String? = nil, label: String? = nil, summary: String? = nil,
                isSelf: Bool = false, actionText: String = "",
                hint: String = "当前版本无法显示这条消息",
                unsupportedText: String = "不支持的消息类型",
                diagnosticLabel: String = "消息类型",
                onAction: (() -> Void)? = nil) {
        self.contentType = contentType; self.label = label; self.summary = summary
        self.isSelf = isSelf; self.actionText = actionText; self.hint = hint
        self.unsupportedText = unsupportedText; self.diagnosticLabel = diagnosticLabel
        self.onAction = onAction
    }

    private var view: FlareUnknownMessagePresentation {
        unknownMessagePresentation(contentType: contentType, label: label, summary: summary,
                                   hint: hint, unsupportedText: unsupportedText)
    }

    /// No handler (or no label) means the host cannot act, so no button is offered.
    private var showsAction: Bool {
        onAction != nil && !actionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let p = view
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                IconView("info", size: 16, color: isSelf ? nil : colors.textSecondary)
                Text(p.title)
                    .font(.system(size: FlareSizes.fontSizeMd, weight: .semibold))
                    .foregroundColor(isSelf ? nil : colors.textSecondary)
            }
            Text(p.body)
                .font(.system(size: FlareSizes.fontSizeLg))
                .fixedSize(horizontal: false, vertical: true)
            if !p.diagnostic.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(diagnosticLabel)
                    Text(p.diagnostic)
                        .font(.system(size: FlareSizes.fontSizeSm, design: .monospaced))
                        .environment(\.layoutDirection, .leftToRight)
                }
                .font(.system(size: FlareSizes.fontSizeSm))
                .foregroundColor(isSelf ? nil : colors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
            }
            if showsAction {
                Button(action: { onAction?() }) {
                    Text(actionText)
                        .font(.system(size: FlareSizes.fontSizeMd))
                        .padding(.horizontal, FlareSizes.spacingMd)
                        .frame(minHeight: 48)
                }
                .buttonStyle(.plain)
                .overlay(
                    RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
                        .stroke(colors.borderPrimary, lineWidth: 1)
                )
                .padding(.top, 2)
            }
        }
        .accessibilityElement(children: .contain)
    }
}
