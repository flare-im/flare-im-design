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

/// Composes input, filters and recovery. Hosts own SDK queries and latest-request arbitration.
public struct SearchPanelView: View {
    private let snapshot: FlareSearchSnapshot
    private let filters: [String: String]
    private let onSearch: (FlareSearchCriteria) -> Void
    private let onOpen: ((SearchResultItem) -> Void)?
    private let onViewAll: ((SearchResultKind) -> Void)?
    private let searchText: String
    private let idleText: String
    private let timeRanges: [FlareSearchRangeOption]
    private let timeRangeText: String
    @State private var fromTime: Int64?
    @State private var toTime: Int64?
    @State private var query: String
    @State private var filter: String
    @State private var submitted: FlareSearchCriteria
    @Environment(\.colorScheme) private var scheme

    public init(snapshot: FlareSearchSnapshot, filters: [String: String],
                onSearch: @escaping (FlareSearchCriteria) -> Void,
                onOpen: ((SearchResultItem) -> Void)? = nil,
                onViewAll: ((SearchResultKind) -> Void)? = nil,
                searchText: String = "搜索", idleText: String = "输入关键词或选择类型",
                timeRanges: [FlareSearchRangeOption] = [], timeRangeText: String = "时间范围") {
        self.timeRanges = timeRanges; self.timeRangeText = timeRangeText
        _fromTime = State(initialValue: snapshot.criteria.fromTime); _toTime = State(initialValue: snapshot.criteria.toTime)
        self.snapshot = snapshot; self.filters = filters; self.onSearch = onSearch
        self.onOpen = onOpen; self.onViewAll = onViewAll
        self.searchText = searchText; self.idleText = idleText
        _query = State(initialValue: snapshot.criteria.query)
        _filter = State(initialValue: snapshot.criteria.filterId)
        _submitted = State(initialValue: snapshot.criteria)
    }
    private func submit() {
        submitted = FlareSearchCriteria(query: query.trimmingCharacters(in: .whitespacesAndNewlines), filterId: filter, fromTime: fromTime, toTime: toTime)
        onSearch(submitted)
    }
    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 12) {
            SearchBarView(text: $query, placeholder: searchText, onSubmit: submit)
            Button(action: submit) { Text(searchText).frame(minWidth: 48, minHeight: 48) }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88))], spacing: 8) {
                ForEach(filters.keys.sorted(), id: \.self) { id in
                    Button { filter = id; submit() } label: {
                        Text(filters[id] ?? id).frame(maxWidth: .infinity, minHeight: 48)
                            .padding(.horizontal, 8)
                            .foregroundColor(colors.textPrimary)
                            .background(filter == id ? colors.bgSelected : colors.bgPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }.buttonStyle(.plain)
                        .accessibilityAddTraits(filter == id ? [.isSelected] : [])
                }
            }
            if !timeRanges.isEmpty {
                Text(timeRangeText).foregroundColor(colors.textSecondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 88))], spacing: 8) {
                    ForEach(timeRanges) { range in
                        let active = range.fromTime == fromTime && range.toTime == toTime
                        Button { fromTime = range.fromTime; toTime = range.toTime; submit() } label: {
                            Text(range.label).frame(maxWidth: .infinity, minHeight: 48).padding(.horizontal, 8)
                                .background(active ? colors.bgSelected : colors.bgPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }.disabled(!range.isValid).accessibilityAddTraits(active ? [.isSelected] : [])
                    }
                }
            }
            if snapshot.criteria != submitted || snapshot.state == .loading {
                ProgressView().accessibilityLabel(searchText)
            } else if snapshot.state == .failure {
                StatusBannerView(text: snapshot.error ?? idleText, tone: .danger, actionText: searchText, onAction: { onSearch(submitted) })
            } else if snapshot.state == .success {
                SearchResultsView(groups: snapshot.groups, query: submitted.query, onOpen: onOpen, onViewAll: onViewAll)
            } else {
                Text(idleText).foregroundColor(colors.textSecondary)
            }
        }
    }
}
