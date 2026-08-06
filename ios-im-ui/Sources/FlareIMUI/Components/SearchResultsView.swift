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

    public init(groups: [SearchResultGroup], query: String,
                onOpen: ((SearchResultItem) -> Void)? = nil, onViewAll: ((SearchResultKind) -> Void)? = nil) {
        self.groups = groups; self.query = query; self.onOpen = onOpen; self.onViewAll = onViewAll
    }

    private var nonEmpty: [SearchResultGroup] { groups.filter { !$0.items.isEmpty } }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        if nonEmpty.isEmpty {
            Text("没有找到结果")
                .font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textTertiary)
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
            Text(g.label.uppercased()).font(.system(size: 12, weight: .semibold)).foregroundColor(colors.textTertiary)
                .padding(.leading, 4).padding(.bottom, 2)
            ForEach(g.items) { item in row(colors, item) }
            if let total = g.total, total > g.items.count {
                Button { onViewAll?(g.kind) } label: {
                    Text("查看全部 \(total)").font(.system(size: FlareSizes.fontSizeLg, weight: .medium))
                        .foregroundColor(colors.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4).padding(.vertical, FlareSizes.spacingSm)
                }.buttonStyle(.plain)
            }
        }
    }

    private func row(_ colors: FlareColors, _ item: SearchResultItem) -> some View {
        Button { onOpen?(item) } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                AvatarView(userId: item.id, displayName: item.title, avatarURL: item.avatarURL, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    highlighted(item.title, colors).font(.system(size: FlareSizes.fontSizeLg))
                        .foregroundColor(colors.textPrimary).lineLimit(1)
                    if let sub = item.subtitle, !sub.isEmpty {
                        highlighted(sub, colors).font(.system(size: FlareSizes.fontSizeSm))
                            .foregroundColor(colors.textTertiary).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if let meta = item.meta, !meta.isEmpty {
                    Text(meta).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                }
            }
            .padding(.horizontal, 4).padding(.vertical, FlareSizes.spacingSm)
        }
        .buttonStyle(.plain)
    }

    private func highlighted(_ s: String, _ colors: FlareColors) -> Text {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return Text(s) }
        var result = Text("")
        var remainder = Substring(s)
        while let range = remainder.range(of: q, options: .caseInsensitive) {
            let before = remainder[remainder.startIndex..<range.lowerBound]
            if !before.isEmpty { result = result + Text(String(before)) }
            result = result + Text(String(remainder[range])).foregroundColor(colors.primary).bold()
            remainder = remainder[range.upperBound...]
        }
        if !remainder.isEmpty { result = result + Text(String(remainder)) }
        return result
    }
}
