import SwiftUI

/// The recent-search list after `term` was used: trimmed, newest first, an exact repeat moves to the front instead of
/// appearing twice, and the oldest fall off past `max`. A blank term changes nothing. The host stores the list (per
/// signed-in user); the rule is here so every client keeps the same one (the Vue kit's `flareRememberSearch`).
public func flareRememberSearch(_ list: [String], _ term: String, max: Int = 8) -> [String] {
    let value = term.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty else { return list }
    return Array(([value] + list.filter { $0 != value }).prefix(Swift.max(0, max)))
}

/// Recent searches — what a search page shows before anything is typed: the terms the reader used last, one tap from
/// searching again, and one way to forget them all. The host owns the list (``flareRememberSearch(_:_:max:)``) and
/// reports `onPick` / `onClear`; with no items this draws nothing, so the page's idle line shows instead.
///
/// The terms are rows (clock icon + term, one line), not capsules: under a search page's scope row a second row of
/// capsules could not be told apart from it. Each row is a touch target tall. Spec: Search/RecentSearches (the Vue
/// kit's `FlareRecentSearches`, Flutter's `FlareRecentSearches`).
public struct RecentSearchesView: View {
    private let items: [String]
    private let onPick: ((String) -> Void)?
    private let onClear: (() -> Void)?
    private let gutter: CGFloat
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(items: [String], gutter: CGFloat = FlareSizes.spacingMd,
                onPick: ((String) -> Void)? = nil, onClear: (() -> Void)? = nil) {
        self.items = items; self.gutter = gutter; self.onPick = onPick; self.onClear = onClear
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    // The same rung as a result group's label: a caption over a list, not a page title.
                    Text(strings.recentSearchesTitle)
                        .font(.system(size: FlareSizes.fontSizeSm, weight: .semibold))
                        .foregroundColor(colors.textTertiary)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 0)
                    if let onClear {
                        ButtonView(label: strings.recentSearchesClear, variant: .quiet, size: .sm, action: onClear)
                            .accessibilityLabel(strings.recentSearchesClearLabel)
                    }
                }
                .frame(minHeight: FlareSizes.touchTarget)
                .padding(.horizontal, gutter)
                ForEach(Array(items.enumerated()), id: \.offset) { _, term in
                    Button { onPick?(term) } label: {
                        HStack(spacing: FlareSizes.spacingSm) {
                            IconView("clock", size: 16, color: colors.textTertiary)
                                .accessibilityHidden(true)
                            Text(term)
                                .font(.system(size: FlareSizes.fontSizeMd))
                                .foregroundColor(colors.textPrimary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: FlareSizes.touchTarget)
                        .padding(.horizontal, gutter)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(onPick == nil)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(strings.recentSearchesTitle)
        }
    }
}
