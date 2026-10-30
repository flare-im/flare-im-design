import SwiftUI

// MARK: - ReadReceiptSheet

/// The read list of one of the viewer's group messages: read / unread tabs whose columns page on their own.
/// Spec: Message/ReadReceiptSheet (`ReadReceiptSheetView`), spec/read-receipt-vectors.json.
///
/// - `readers` / `unread` are the members loaded so far (one page or more); the host holds both columns, so switching
///   tabs emits nothing. `initialTab` picks the column shown first.
/// - A tab's number is the summary count the host passes (`readCount` / `unreadCount`, from `receipt.readSummary`);
///   without one the tab has no number. It is never the length of a list, which may be one page.
/// - `state`: `loading` draws the tabs over a spinner; `error` a notice with a retry key (`onRetry`) and no tabs;
///   `unavailable` a notice with no tabs and no retry (the SDK's `NOT_FOUND` or `available: false`).
/// - Paging: a column with a next page (`readHasMore` / `unreadHasMore`) ends with the load-more key, which calls
///   `onLoadMore(column)`; while `loadingMore` names it, a spinner that asks for nothing; after a failed page
///   (`loadMoreFailed`), a retry key that asks again. The other column pages on its own.
/// - Width follows the container. Outside a kit overlay the sheet draws its own card shell (radius xl, hairline, lg
///   shadow) at most 320 wide and its rows scroll within 320. In a kit bottom sheet or modal
///   (``SwiftUI/EnvironmentValues/flareInOverlaySurface``) it draws no shell, fills the surface and declares its own
///   header (``SwiftUI/View/flareSheetOwnHeader(_:)``): open it with the sheet's `fill` so the sheet's title is the
///   accessible name only, and the rows take the remaining height.
public struct ReadReceiptSheetView: View {
    private let readers: [Contact]
    private let unread: [Contact]
    private let readCount: Int?
    private let unreadCount: Int?
    private let state: FlareReadReceiptState
    private let readHasMore: Bool
    private let unreadHasMore: Bool
    private let loadingMore: FlareReadReceiptColumn?
    private let loadMoreFailed: FlareReadReceiptColumn?
    private let dismissible: Bool
    private let onSelect: ((String) -> Void)?
    private let onClose: (() -> Void)?
    private let onLoadMore: ((FlareReadReceiptColumn) -> Void)?
    private let onRetry: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.flareInOverlaySurface) private var inOverlay
    @State private var active: FlareReadReceiptColumn

    /// The widest the card shell is, and the tallest its rows are, outside a kit overlay.
    static let shellMaxWidth: CGFloat = 320
    static let shellMaxListHeight: CGFloat = 320

    public init(readers: [Contact], unread: [Contact], readCount: Int? = nil, unreadCount: Int? = nil,
                state: FlareReadReceiptState = .ready, readHasMore: Bool = false, unreadHasMore: Bool = false,
                loadingMore: FlareReadReceiptColumn? = nil, loadMoreFailed: FlareReadReceiptColumn? = nil,
                initialTab: FlareReadReceiptColumn = .read, dismissible: Bool = false,
                onSelect: ((String) -> Void)? = nil, onClose: (() -> Void)? = nil,
                onLoadMore: ((FlareReadReceiptColumn) -> Void)? = nil, onRetry: (() -> Void)? = nil) {
        self.readers = readers; self.unread = unread; self.readCount = readCount; self.unreadCount = unreadCount
        self.state = state; self.readHasMore = readHasMore; self.unreadHasMore = unreadHasMore
        self.loadingMore = loadingMore; self.loadMoreFailed = loadMoreFailed; self.dismissible = dismissible
        self.onSelect = onSelect; self.onClose = onClose; self.onLoadMore = onLoadMore; self.onRetry = onRetry
        _active = State(initialValue: initialTab)
    }

    /// The layout of the current inputs with `column` shown.
    func layout(_ column: FlareReadReceiptColumn) -> FlareReadReceiptLayout {
        FlareReadReceiptLayout.of(state: state, active: column, readers: readers.count, unread: unread.count,
                                  readCount: readCount, unreadCount: unreadCount,
                                  readHasMore: readHasMore, unreadHasMore: unreadHasMore,
                                  loadingMore: loadingMore, loadMoreFailed: loadMoreFailed)
    }

    /// A tab's label: the counted copy with a summary count, the plain one without.
    static func tabLabel(_ tab: FlareReadReceiptLayout.Tab, _ strings: FlareStrings) -> String {
        switch tab.column {
        case .read: return tab.count.map { strings.readTab($0) } ?? strings.readReceiptRead
        case .unread: return tab.count.map { strings.unreadTab($0) } ?? strings.readReceiptUnread
        }
    }

    /// Test hooks: the keys a test finds by identifier.
    static let tailKeyID = "flare-read-receipt-tail"
    static let retryKeyID = "flare-read-receipt-retry"
    static func tabID(_ column: FlareReadReceiptColumn) -> String { "flare-read-receipt-tab-\(column.rawValue)" }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let layout = layout(active)
        let content = VStack(alignment: .leading, spacing: 0) {
            header(colors)
            if let tabs = layout.tabs {
                HStack(spacing: 0) {
                    ForEach(tabs, id: \.column) { tab in self.tab(colors, tab) }
                }
                .padding(.horizontal, FlareSizes.spacingLg)
                Divider().overlay(colors.borderPrimary)
            }
            bodyView(colors, layout)
        }
        if inOverlay {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .flareSheetOwnHeader()
        } else {
            content
                .frame(maxWidth: Self.shellMaxWidth)
                .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary))
                // Decoration only: the hairline must not take the taps meant for the rows and keys.
                .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)
                    .allowsHitTesting(false))
                .flareShadow(FlareShadows.of(scheme).lg)
        }
    }

    private func header(_ colors: FlareColors) -> some View {
        HStack(spacing: FlareSizes.spacingSm) {
            IconView("read", size: FlareSizes.iconSizeSm, color: colors.primaryText)
            Text(strings.readReceipt).font(.system(size: FlareSizes.fontSizeXl, weight: .semibold))
                .foregroundColor(colors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            if dismissible {
                Button { onClose?() } label: {
                    IconView("close", size: 14, color: colors.textTertiary)
                        .flareTouchTarget()
                }
                .buttonStyle(.plain)
                .flareCompactLayout(width: 14, height: 14)
                .accessibilityLabel(strings.close)
            }
        }
        .padding(.horizontal, FlareSizes.spacingLg).padding(.top, FlareSizes.spacingLg).padding(.bottom, FlareSizes.spacingMd)
    }

    private func tab(_ colors: FlareColors, _ tab: FlareReadReceiptLayout.Tab) -> some View {
        let selected = active == tab.column
        return Button { active = tab.column } label: {
            VStack(spacing: 6) {
                Text(Self.tabLabel(tab, strings))
                    .font(.system(size: FlareSizes.fontSizeLg, weight: selected ? .semibold : .regular))
                    .foregroundColor(selected ? colors.primaryText : colors.textSecondary)
                Rectangle().fill(selected ? colors.primary : Color.clear).frame(height: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, FlareSizes.spacingSm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(Self.tabID(tab.column))
    }

    @ViewBuilder private func bodyView(_ colors: FlareColors, _ layout: FlareReadReceiptLayout) -> some View {
        switch layout.body {
        case .spinner:
            ProgressView()
                .tint(colors.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
        case .error:
            notice(colors, strings.readReceiptLoadFailed) {
                ButtonView(label: strings.retry, variant: .secondary, size: .sm) { onRetry?() }
                    .accessibilityIdentifier(Self.retryKeyID)
            }
        case .unavailable:
            notice(colors, strings.readReceiptUnavailable) { EmptyView() }
        case .empty:
            notice(colors, layout.empty == .unread ? strings.everyoneHasRead : strings.noReadersYet) { EmptyView() }
        case .list:
            let members = active == .read ? readers : unread
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(members) { c in row(colors, c) }
                    tail(colors, layout)
                }
            }
            .frame(maxHeight: inOverlay ? .infinity : Self.shellMaxListHeight)
        }
    }

    private func notice<Action: View>(_ colors: FlareColors, _ text: String,
                                      @ViewBuilder action: () -> Action) -> some View {
        VStack(spacing: FlareSizes.spacingMd) {
            Text(text)
                .font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            action()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28).padding(.horizontal, FlareSizes.spacingLg)
    }

    @ViewBuilder private func tail(_ colors: FlareColors, _ layout: FlareReadReceiptLayout) -> some View {
        switch layout.tail {
        case .none:
            EmptyView()
        case .busy:
            ProgressView()
                .tint(colors.primaryText)
                .frame(maxWidth: .infinity, minHeight: FlareSizes.touchTarget)
                .accessibilityLabel(strings.readReceiptLoadMore)
        case .loadMore, .retry:
            let column = active
            ButtonView(label: layout.tail == .retry ? strings.readReceiptLoadMoreFailed : strings.readReceiptLoadMore,
                       variant: .text, size: .sm, block: true) {
                // The same column never asks twice while it is loading more.
                guard loadingMore != column, let request = self.layout(column).tailRequest(column) else { return }
                onLoadMore?(request)
            }
            .frame(minHeight: FlareSizes.touchTarget)
            .padding(.horizontal, FlareSizes.spacingLg)
            .accessibilityIdentifier(Self.tailKeyID)
        }
    }

    private func row(_ colors: FlareColors, _ c: Contact) -> some View {
        Button { onSelect?(c.id) } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                AvatarView(userId: c.id, displayName: c.name, avatarURL: c.avatarURL, size: 36, presence: c.presence)
                Text(c.name).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary).lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingSm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
