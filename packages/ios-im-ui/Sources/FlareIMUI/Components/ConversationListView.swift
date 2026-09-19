import SwiftUI

/// The inbox — a list of ``ConversationRowView``s. Spec:
/// Conversation/ConversationList (`ConversationListView`). SwiftUI `List` is
/// natively virtualised (O(visible)).
///
/// Rows render in the order the host gives (FR-037): the core already lists pinned
/// conversations first, and a filtered or searched list keeps its own order. A pinned
/// row keeps its pin mark.
public struct ConversationListView: View {
    private let items: [ConversationRowData]
    private let activeId: String?
    private let loading: Bool
    private let emptyText: String?
    private let onSelect: ((ConversationRowData) -> Void)?
    private let onLongPress: ((ConversationRowData) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(
        items: [ConversationRowData],
        activeId: String? = nil,
        loading: Bool = false,
        emptyText: String? = nil,
        onSelect: ((ConversationRowData) -> Void)? = nil,
        onLongPress: ((ConversationRowData) -> Void)? = nil
    ) {
        self.items = items
        self.activeId = activeId
        self.loading = loading
        self.emptyText = emptyText
        self.onSelect = onSelect
        self.onLongPress = onLongPress
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        if items.isEmpty {
            if loading {
                ProgressView()
            } else {
                Text(emptyText ?? strings.noConversations)
                    .font(.system(size: FlareSizes.fontSizeLg))
                    .foregroundColor(colors.textTertiary)
            }
        } else {
            List(items) { item in
                ConversationRowView(item: item, active: item.id == activeId, onSelect: onSelect, onLongPress: onLongPress)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
        }
    }
}
