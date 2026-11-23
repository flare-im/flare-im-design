import SwiftUI

// MARK: - SearchResults

/// Global search results — grouped contacts / groups / messages with query highlight.
/// Spec: Search/SearchResults (`SearchResultsView`).
public struct SearchResultsView: View {
    private let groups: [SearchResultGroup]
    private let query: String
    private let onOpen: ((SearchResultItem) -> Void)?
    private let onViewAll: ((SearchResultKind) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(groups: [SearchResultGroup], query: String,
                onOpen: ((SearchResultItem) -> Void)? = nil, onViewAll: ((SearchResultKind) -> Void)? = nil) {
        self.groups = groups; self.query = query; self.onOpen = onOpen; self.onViewAll = onViewAll
    }

    private var nonEmpty: [SearchResultGroup] { groups.filter { !$0.items.isEmpty } }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        if nonEmpty.isEmpty {
            EmptyStateView(title: strings.searchEmpty, description: strings.searchEmptyHint, icon: "search")
                .frame(maxWidth: .infinity).padding(.vertical, 32)
        } else {
            VStack(alignment: .leading, spacing: FlareSizes.spacingLg) {
                ForEach(nonEmpty) { g in section(colors, g) }
            }
            .padding(FlareSizes.spacingLg)
        }
    }

    private func section(_ colors: FlareColors, _ g: SearchResultGroup) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label as given (no uppercasing) — Android / Flutter parity.
            Text(g.label).font(.system(size: 12, weight: .semibold)).foregroundColor(colors.textTertiary)
                .padding(.bottom, 2)
            ForEach(g.items) { item in row(colors, item) }
            if let more = g.moreText(strings) {
                Button { onViewAll?(g.kind) } label: {
                    Text(more).font(.system(size: FlareSizes.fontSizeMd, weight: .medium))
                        .foregroundColor(colors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, FlareSizes.spacingSm)
                }.buttonStyle(.plain)
            }
        }
    }

    /// A message's words around its first hit: up to 24 characters before it and at least 128 in all, "…" on a cut
    /// side (the Vue kit's `excerpt`), so a hit near the end of a long message is still in view. Characters are
    /// grapheme clusters: an emoji is never cut in half. Text of 128 characters or fewer, or without a hit, is whole.
    static func excerpt(_ text: String, query: String) -> String {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty, text.count > 128, let hit = text.range(of: q, options: .caseInsensitive) else { return text }
        let chars = Array(text)
        let at = text.distance(from: text.startIndex, to: hit.lowerBound)
        let start = max(0, at - 24)
        let end = min(chars.count, max(start + 128, at + text.distance(from: hit.lowerBound, to: hit.upperBound) + 24))
        return (start > 0 ? "…" : "") + String(chars[start..<end]) + (end < chars.count ? "…" : "")
    }

    private func row(_ colors: FlareColors, _ item: SearchResultItem) -> some View {
        let message = item.kind == .message
        return Button { onOpen?(item) } label: {
            HStack(alignment: message ? .top : .center, spacing: FlareSizes.spacingMd) {
                AvatarView(userId: item.id, displayName: item.title, avatarURL: item.avatarURL, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    highlighted(item.title, colors).font(.system(size: FlareSizes.fontSizeLg))
                        .foregroundColor(colors.textPrimary).lineLimit(1)
                    if let sub = item.subtitle, !sub.isEmpty {
                        // A message shows the part around its hit, on up to two lines.
                        highlighted(message ? Self.excerpt(sub, query: query) : sub, colors)
                            .font(.system(size: FlareSizes.fontSizeSm))
                            .foregroundColor(message ? colors.textSecondary : colors.textTertiary)
                            .lineLimit(message ? 2 : 1)
                    }
                }
                Spacer(minLength: 0)
                if let meta = item.meta, !meta.isEmpty {
                    Text(meta).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                }
            }
            .padding(.vertical, FlareSizes.spacingSm)
        }
        .buttonStyle(.plain)
        // The full words, not the excerpt.
        .accessibilityLabel([item.title, item.subtitle, item.meta].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", "))
    }

    private func highlighted(_ s: String, _ colors: FlareColors) -> Text {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return Text(s) }
        var result = Text("")
        var remainder = Substring(s)
        while let range = remainder.range(of: q, options: .caseInsensitive) {
            let before = remainder[remainder.startIndex..<range.lowerBound]
            if !before.isEmpty { result = result + Text(String(before)) }
            result = result + Text(String(remainder[range])).foregroundColor(colors.primaryText).bold()
            remainder = remainder[range.upperBound...]
        }
        if !remainder.isEmpty { result = result + Text(String(remainder)) }
        return result
    }
}
