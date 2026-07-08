import SwiftUI

/// The inbox — a list of ``ConversationRowView``s. Spec:
/// Conversation/ConversationList (`ConversationListView`). SwiftUI `List` is
/// natively virtualised (O(visible)).
public struct ConversationListView: View {
    private let items: [ConversationRowData]
    private let activeId: String?
    private let loading: Bool
    private let onSelect: ((ConversationRowData) -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(
        items: [ConversationRowData],
        activeId: String? = nil,
        loading: Bool = false,
        onSelect: ((ConversationRowData) -> Void)? = nil
    ) {
        self.items = items
        self.activeId = activeId
        self.loading = loading
        self.onSelect = onSelect
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        if items.isEmpty {
            if loading {
                ProgressView()
            } else {
                Text("No conversations")
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
