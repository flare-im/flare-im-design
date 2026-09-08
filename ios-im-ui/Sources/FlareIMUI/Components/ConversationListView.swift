import SwiftUI

/// The inbox — a list of ``ConversationRowView``s. Spec:
/// Conversation/ConversationList (`ConversationListView`). SwiftUI `List` is
/// natively virtualised (O(visible)).
public struct ConversationListView: View {
    private let items: [ConversationRowData]
    private let activeId: String?
    private let loading: Bool
    private let emptyText: String
    private let onSelect: ((ConversationRowData) -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(
        items: [ConversationRowData],
        activeId: String? = nil,
        loading: Bool = false,
        emptyText: String = "暂无会话",
        onSelect: ((ConversationRowData) -> Void)? = nil
    ) {
        self.items = items
        self.activeId = activeId
        self.loading = loading
        self.emptyText = emptyText
        self.onSelect = onSelect
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        if items.isEmpty {
            if loading {
                ProgressView()
            } else {
                Text(emptyText)
                    .font(.system(size: FlareSizes.fontSizeLg))
                    .foregroundColor(colors.textTertiary)
            }
        } else {
            List(items) { item in
                Button { onSelect?(item) } label: {
                    ConversationRowView(item: item, active: item.id == activeId)
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
        }
    }
}

/// Host-rows variant of ``ConversationListView`` — for screens that build each
/// row themselves (to keep per-row context menus, swipe actions, or a store
/// subscription) while still getting the kit's standardised empty / loading
/// treatment and lazy scroll wrapper. Bring your own `Item` collection and a
/// `row` builder; supply an `empty` view for the no-items state.
///
/// Complements ``ConversationListView`` (the self-contained `List` variant):
/// reach for this when the host owns the row visuals/affordances and only wants
/// the kit to standardise the container.
public struct ConversationListContainer<Item: Identifiable, Row: View, Empty: View>: View {
    private let items: [Item]
    private let loading: Bool
    private let rowSpacing: CGFloat
    private let contentInsets: EdgeInsets
    private let empty: Empty
    private let row: (Item) -> Row

    public init(
        items: [Item],
        loading: Bool = false,
        rowSpacing: CGFloat = 0,
        contentInsets: EdgeInsets = EdgeInsets(),
        @ViewBuilder empty: () -> Empty,
        @ViewBuilder row: @escaping (Item) -> Row
    ) {
        self.items = items
        self.loading = loading
        self.rowSpacing = rowSpacing
        self.contentInsets = contentInsets
        self.empty = empty()
        self.row = row
    }

    public var body: some View {
        if items.isEmpty {
            if loading {
                ProgressView()
            } else {
                empty
            }
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: rowSpacing) {
                    ForEach(items) { item in
                        row(item)
                    }
                }
                .padding(contentInsets)
            }
        }
    }
}
