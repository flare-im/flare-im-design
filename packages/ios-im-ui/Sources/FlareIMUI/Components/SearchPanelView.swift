import SwiftUI

public struct FlareSearchCriteria: Equatable, Sendable {
    public let query: String
    public let filterId: String
    public let fromTime: Int64?
    public let toTime: Int64?
    public init(query: String, filterId: String, fromTime: Int64? = nil, toTime: Int64? = nil) {
        self.query = query; self.filterId = filterId; self.fromTime = fromTime; self.toTime = toTime
    }
}
public struct FlareSearchRangeOption: Identifiable, Sendable {
    public let id: String
    public let label: String
    public let fromTime: Int64?
    public let toTime: Int64?
    public init(id: String, label: String, fromTime: Int64? = nil, toTime: Int64? = nil) {
        self.id = id; self.label = label; self.fromTime = fromTime; self.toTime = toTime
    }
    public var isValid: Bool {
        let valid = { (value: Int64?) in value.map { $0 >= 0 && $0 <= 9007199254740991 } ?? true }
        return valid(fromTime) && valid(toTime) && (fromTime == nil || toTime == nil || fromTime! <= toTime!)
    }
}
public enum FlareSearchState: Sendable { case idle, loading, success, failure }
public struct FlareSearchSnapshot {
    public let criteria: FlareSearchCriteria
    public let state: FlareSearchState
    public let groups: [SearchResultGroup]
    public let error: String?
    public init(criteria: FlareSearchCriteria, state: FlareSearchState, groups: [SearchResultGroup] = [], error: String? = nil) {
        self.criteria = criteria; self.state = state; self.groups = groups; self.error = error
    }
}

/// Composes input, filters and recovery. Hosts own queries and latest-request arbitration.
///
/// The Vue kit's `FlareSearchPanel`: the field, then ONE row — the types as ``FilterTabsView`` tabs (scrolling, never
/// wrapping) and the time range as a trailing capsule that opens an ``ActionMenuView`` — then the results. Typing
/// searches after a 300 ms pause; Return, clearing, a type or a time range at once. Nothing typed, the first type and
/// no time range is idle: the idle line and no search. `layout: .page` is the panel as a whole screen: the field and
/// the row stay put over a hairline and only the results scroll.
public struct SearchPanelView: View {
    public enum Layout: Sendable { case inline, page }
    private let snapshot: FlareSearchSnapshot
    private let filters: [String: String]
    private let onSearch: (FlareSearchCriteria) -> Void
    private let onOpen: ((SearchResultItem) -> Void)?
    private let onViewAll: ((SearchResultKind) -> Void)?
    private let searchTextValue: String?
    private let idleTextValue: String?
    private let timeRanges: [FlareSearchRangeOption]
    private let timeRangeTextValue: String?
    /// The filters' order; without it they are sorted by id.
    private let filterOrder: [String]?
    private let layout: Layout
    /// Puts the caret in the field when the panel opens.
    private let autofocus: Bool
    @State private var fromTime: Int64?
    @State private var toTime: Int64?
    @State private var query: String
    @State private var filter: String
    @State private var submitted: FlareSearchCriteria
    @FocusState private var fieldFocused: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(snapshot: FlareSearchSnapshot, filters: [String: String],
                onSearch: @escaping (FlareSearchCriteria) -> Void,
                onOpen: ((SearchResultItem) -> Void)? = nil,
                onViewAll: ((SearchResultKind) -> Void)? = nil,
                searchText: String? = nil, idleText: String? = nil,
                timeRanges: [FlareSearchRangeOption] = [], timeRangeText: String? = nil,
                filterOrder: [String]? = nil, layout: Layout = .inline, autofocus: Bool = false) {
        self.timeRanges = timeRanges; self.timeRangeTextValue = timeRangeText; self.filterOrder = filterOrder
        self.layout = layout; self.autofocus = autofocus
        _fromTime = State(initialValue: snapshot.criteria.fromTime); _toTime = State(initialValue: snapshot.criteria.toTime)
        self.snapshot = snapshot; self.filters = filters; self.onSearch = onSearch
        self.onOpen = onOpen; self.onViewAll = onViewAll
        self.searchTextValue = searchText; self.idleTextValue = idleText
        _query = State(initialValue: snapshot.criteria.query)
        _filter = State(initialValue: snapshot.criteria.filterId)
        _submitted = State(initialValue: snapshot.criteria)
    }
    private var searchText: String { searchTextValue ?? strings.search }
    private var idleText: String { idleTextValue ?? strings.searchIdleHint }
    private var timeRangeText: String { timeRangeTextValue ?? strings.timeRange }
    private var filterIds: [String] { filterOrder?.filter { filters[$0] != nil } ?? filters.keys.sorted() }
    private var ranges: [FlareSearchRangeOption] { timeRanges.filter(\.isValid) }

    private var draft: FlareSearchCriteria {
        FlareSearchCriteria(query: query.trimmingCharacters(in: .whitespacesAndNewlines), filterId: filter,
                            fromTime: fromTime, toTime: toTime)
    }
    private func isIdle(_ criteria: FlareSearchCriteria) -> Bool {
        criteria.query.isEmpty && (criteria.filterId.isEmpty || criteria.filterId == filterIds.first)
            && criteria.fromTime == nil && criteria.toTime == nil
    }
    private var waiting: Bool { !isIdle(submitted) && (snapshot.criteria != submitted || snapshot.state == .loading) }

    private func submit() {
        let next = draft
        // The same search again is no new search, unless it failed (Return retries).
        if next == submitted && !isIdle(next) && snapshot.state != .failure { return }
        submitted = next
        if !isIdle(next) { onSearch(next) }
    }
    private func chooseRange(_ id: String) {
        guard let range = ranges.first(where: { $0.id == id }) else { return }
        fromTime = range.fromTime; toTime = range.toTime
        submit()
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        Group {
            if layout == .page {
                VStack(spacing: 0) {
                    head(colors)
                        .padding(.horizontal, FlareSizes.spacingLg)
                        .padding(.vertical, FlareSizes.spacingSm)
                    Rectangle().fill(colors.borderSecondary).frame(height: 1)
                    ScrollView { content(colors, gutter: FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingSm) }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
                    head(colors)
                    content(colors, gutter: 0)
                }
            }
        }
        .onAppear { if autofocus { fieldFocused = true } }
        // Typing searches after a pause; an emptied field at once.
        .task(id: query) {
            guard draft != submitted else { return }
            if !draft.query.isEmpty { try? await Task.sleep(nanoseconds: 300_000_000) }
            guard !Task.isCancelled, draft != submitted else { return }
            submit()
        }
    }

    private func head(_ colors: FlareColors) -> some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            SearchBarView(text: $query, placeholder: searchText, loading: waiting, onSubmit: submit)
                .focused($fieldFocused)
            if filterIds.count > 1 || !ranges.isEmpty {
                HStack(spacing: FlareSizes.spacingSm) {
                    if filterIds.count > 1 {
                        FilterTabsView(options: filterIds.map { FlareFilterTabOption(value: $0, label: filters[$0] ?? $0) },
                                       selection: $filter, onChange: { _ in submit() })
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Spacer(minLength: 0)
                    }
                    if !ranges.isEmpty { rangeMenu(colors) }
                }
            }
        }
    }

    /// The time range capsule: it names the chosen range, or — none chosen, or the first (不限) — the filter itself,
    /// and takes the brand tint while a range narrows the search.
    private func rangeMenu(_ colors: FlareColors) -> some View {
        let chosen = ranges.first { $0.fromTime == fromTime && $0.toTime == toTime }
            .flatMap { $0.id == ranges.first?.id ? nil : $0.label }
        let narrowed = chosen != nil
        return ActionMenuView(items: ranges.map { FlareActionItem(id: $0.id, label: $0.label) },
                              accessibilityLabel: timeRangeText, onSelect: chooseRange) {
            HStack(spacing: FlareSizes.spacingXs) {
                Text(chosen ?? timeRangeText)
                    .font(.system(size: FlareSizes.fontSizeSm, weight: narrowed ? .semibold : .medium))
                    .lineLimit(1)
                Image(systemName: flareIconSymbol("chevron-down")).font(.system(size: FlareSizes.fontSizeXs, weight: .semibold))
                    .accessibilityHidden(true)
            }
            .foregroundColor(narrowed ? colors.primaryText : colors.textSecondary)
            .padding(.horizontal, FlareSizes.spacingSm)
            .frame(minHeight: 30)
            .background(Capsule().fill(narrowed ? colors.primary.opacity(0.12) : colors.bgSecondary))
            .overlay(Capsule().stroke(narrowed ? colors.primary.opacity(0.26) : Color.clear, lineWidth: 1))
            .flareTouchTarget()
        }
        .fixedSize()
        .accessibilityValue(chosen ?? timeRangeText)
    }

    @ViewBuilder
    private func content(_ colors: FlareColors, gutter: CGFloat) -> some View {
        if isIdle(submitted) {
            status(idleText, colors, gutter: gutter)
        } else if snapshot.criteria != submitted || snapshot.state == .loading {
            status(strings.searchSearching, colors, gutter: gutter)
        } else if snapshot.state == .failure {
            StatusBannerView(text: snapshot.error ?? idleText, tone: .danger, actionText: strings.retry,
                             onAction: { onSearch(submitted) })
                .padding(.horizontal, gutter)
        } else if snapshot.state == .success {
            SearchResultsView(groups: snapshot.groups, query: submitted.query, onOpen: onOpen, onViewAll: onViewAll)
        } else {
            status(idleText, colors, gutter: gutter)
        }
    }

    private func status(_ text: String, _ colors: FlareColors, gutter: CGFloat) -> some View {
        Text(text)
            .font(.system(size: FlareSizes.fontSizeMd))
            .foregroundColor(colors.textTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, FlareSizes.spacingLg)
            .padding(.horizontal, gutter)
    }
}
