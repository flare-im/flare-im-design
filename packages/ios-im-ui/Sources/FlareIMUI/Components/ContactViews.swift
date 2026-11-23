import SwiftUI

/// Directory row. Spec: Contacts/ContactItem (`ContactItemView`).
public struct ContactItemView: View {
    private let item: Contact
    private let showPresence: Bool
    private let selectable: Bool
    private let selected: Bool
    private let current: Bool
    private let trailing: AnyView?
    private let onSelect: (() -> Void)?
    private let onToggleSelect: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    /// - Parameters:
    ///   - selectable: A leading checkbox shows `selected`; tapping the row calls `onToggleSelect`
    ///     (not `onSelect`), and the row is one checkbox for assistive technology, named by the contact.
    ///   - current: The person the detail pane beside the list shows (Vue `current`; not `selected`, the checkbox):
    ///     the name in the primary colour and semibold, read as selected. The list draws the row's ground.
    ///   - trailing: Content at the row end (a button, a status). Its controls keep their own taps
    ///     and focus; they do not select the row.
    ///   - onSelect: Tapping the row outside selection mode. Without a handler for the current mode
    ///     the row is not a control.
    public init(item: Contact, showPresence: Bool = true, selectable: Bool = false, selected: Bool = false,
                current: Bool = false,
                trailing: AnyView? = nil, onSelect: (() -> Void)? = nil, onToggleSelect: (() -> Void)? = nil) {
        self.item = item; self.showPresence = showPresence
        self.selectable = selectable; self.selected = selected; self.current = current; self.trailing = trailing
        self.onSelect = onSelect; self.onToggleSelect = onToggleSelect
    }

    /// The row's tap: `onToggleSelect` in selection mode, `onSelect` otherwise; nil keeps the row
    /// a plain element.
    static func rowAction(selectable: Bool, onSelect: (() -> Void)?, onToggleSelect: (() -> Void)?) -> (() -> Void)? {
        selectable ? onToggleSelect : onSelect
    }

    public var body: some View {
        HStack(spacing: FlareSizes.spacingMd) {
            if let action = Self.rowAction(selectable: selectable, onSelect: onSelect, onToggleSelect: onToggleSelect) {
                Button(action: action) { row }
                    .buttonStyle(.plain)
                    .modifier(RowSemantics(name: item.name, selectable: selectable, selected: selected, current: current,
                                           control: true))
            } else {
                row.modifier(RowSemantics(name: item.name, selectable: selectable, selected: selected, current: current,
                                          control: false))
            }
            if let trailing { trailing }
        }
    }

    /// One element per row. A selectable row reads as a checkbox named by the contact, with its
    /// checked state as the selected trait (the kit ``CheckboxView`` convention); the current row is selected too.
    private struct RowSemantics: ViewModifier {
        let name: String
        let selectable: Bool
        let selected: Bool
        let current: Bool
        let control: Bool

        func body(content: Content) -> some View {
            let button: AccessibilityTraits = control ? .isButton : []
            let checked: AccessibilityTraits = (selectable && selected) || current ? .isSelected : []
            return Group {
                if selectable {
                    content.accessibilityElement(children: .ignore).accessibilityLabel(name)
                } else {
                    content.accessibilityElement(children: .combine)
                }
            }
            .accessibilityAddTraits(button.union(checked))
        }
    }

    private var row: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        return HStack(spacing: FlareSizes.spacingMd) {
            if selectable {
                // The row is the control: the kit checkbox only shows the state.
                CheckboxView(isOn: .constant(selected)).allowsHitTesting(false).accessibilityHidden(true)
            }
            AvatarView(userId: item.id, displayName: item.name, avatarURL: item.avatarURL,
                       size: 40, presence: showPresence ? item.presence : nil)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.system(size: FlareSizes.fontSizeLg, weight: current ? .semibold : .medium))
                    .foregroundColor(current ? colors.primaryText : colors.textPrimary)
                if let s = item.signature, !s.isEmpty {
                    Text(s).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary).lineLimit(1)
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

/// Directory grouped A-Z with a side index. Spec: Contacts/ContactList (`ContactListView`).
public struct ContactListView: View {
    private let items: [Contact]
    private let indexed: Bool
    private let loading: Bool
    private let selectable: Bool
    private let selectedIds: Set<String>
    private let trailing: ((Contact) -> AnyView)?
    private let empty: AnyView?
    private let onSelect: ((Contact) -> Void)?
    private let onToggleSelect: ((Contact) -> Void)?
    private let selection: [Contact]
    private let selectionLabel: String?
    private let removeSelectionLabel: ((String) -> String)?
    private let activeId: String?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// - Parameters:
    ///   - activeId: The contact the detail pane beside the list shows (Vue `activeId`): that row on the selected
    ///     ground, its name in the primary colour and semibold, read as selected. Ignored in a selectable list.
    ///   - selection: In a selectable list, the picked contacts as a strip of removable chips above the rows (Vue
    ///     `FlareContactList` selectable): 24-point avatar, name, ✕; tapping one toggles it off through
    ///     `onToggleSelect`. The host passes everyone picked, so a filter that hides a row keeps its chip.
    ///   - selectionLabel: The strip's name for assistive technology ("3 selected"); `removeSelectionLabel` names a
    ///     chip from the contact's name ("Remove Ann from selection").
    ///   - selectable: Rows show a checkbox checked for `selectedIds` and toggle through
    ///     `onToggleSelect` (see ``ContactItemView``); `onSelect` is not called.
    ///   - selectedIds: The host-owned selection, by contact id.
    ///   - trailing: Row-end content per contact; its controls keep their own taps.
    ///   - empty: Replaces the kit's own empty state, for a directory that is empty for a reason
    ///     only the host knows — a filter, a permission, an invitation to add someone.
    public init(items: [Contact], indexed: Bool = true, loading: Bool = false,
                selectable: Bool = false, selectedIds: Set<String> = [],
                trailing: ((Contact) -> AnyView)? = nil,
                empty: AnyView? = nil,
                onSelect: ((Contact) -> Void)? = nil, onToggleSelect: ((Contact) -> Void)? = nil,
                selection: [Contact] = [], selectionLabel: String? = nil,
                removeSelectionLabel: ((String) -> String)? = nil, activeId: String? = nil) {
        self.items = items; self.indexed = indexed; self.loading = loading
        self.selectable = selectable; self.selectedIds = selectedIds; self.trailing = trailing
        self.empty = empty
        self.onSelect = onSelect; self.onToggleSelect = onToggleSelect
        self.selection = selection; self.selectionLabel = selectionLabel; self.removeSelectionLabel = removeSelectionLabel
        self.activeId = activeId
    }

    /// The index group for names that start with neither a Latin letter nor a Chinese character.
    static let otherIndex = "#"

    /// A contact's index letter (FR-044, Vue `contactIndexLetter`): a Latin name (accented or full-width
    /// included) by its first letter, a Chinese name by the pinyin initial of its first character through
    /// the platform transliteration, anything else "#". A host `indexKey` is used as given: its first
    /// Latin letter, else "#".
    static func indexLetter(name: String, indexKey: String? = nil) -> String {
        guard let first = (indexKey ?? name).trimmingCharacters(in: .whitespacesAndNewlines).first else { return otherIndex }
        if let latin = latinLetter(String(first)) { return latin }
        guard indexKey == nil, first.unicodeScalars.first?.properties.isIdeographic == true,
              let reading = latinReading(String(first))?.trimmingCharacters(in: .whitespaces).first else { return otherIndex }
        return latinLetter(String(reading)) ?? otherIndex
    }

    /// The order of names inside a group: their Latin reading (pinyin for Chinese, without tones), so 阿强
    /// ("a qiang") comes before Amy; equal readings fall back to the name.
    static func sortKey(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return (latinReading(trimmed) ?? trimmed).folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                                                          locale: nil)
    }

    /// The groups the list draws: A to Z, then "#", each ordered by ``sortKey(_:)``.
    static func indexGroups(_ items: [Contact]) -> [(letter: String, people: [Contact])] {
        Dictionary(grouping: items, by: { indexLetter(name: $0.name, indexKey: $0.indexKey) })
            .map { letter, people in
                (letter: letter, people: people.sorted { left, right in
                    let l = sortKey(left.name), r = sortKey(right.name)
                    return l == r ? left.name < right.name : l < r
                })
            }
            .sorted { left, right in
                if left.letter == otherIndex { return false }
                if right.letter == otherIndex { return true }
                return left.letter < right.letter
            }
    }

    /// "A"…"Z" for a Latin letter once width, case and accents are folded away; nil otherwise.
    private static func latinLetter(_ text: String) -> String? {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
            .uppercased()
        guard let letter = folded.unicodeScalars.first, folded.unicodeScalars.count == 1,
              ("A"..."Z").contains(letter) else { return nil }
        return String(letter)
    }

    private static let readings = NSCache<NSString, NSString>()

    /// The platform's Latin transliteration without accents ("张伟" → "zhang wei"), cached per text:
    /// transliteration is too slow to repeat for every row on every render.
    private static func latinReading(_ text: String) -> String? {
        if let cached = readings.object(forKey: text as NSString) { return cached as String }
        guard let latin = text.applyingTransform(.toLatin, reverse: false)?
            .applyingTransform(.stripDiacritics, reverse: false) else { return nil }
        readings.setObject(latin as NSString, forKey: text as NSString)
        return latin
    }

    private var groups: [(letter: String, people: [Contact])] {
        Self.indexGroups(items)
    }

    public var body: some View {
        VStack(spacing: 0) {
            if selectable && !selection.isEmpty { selectionStrip }
            rows
        }
    }

    private var selectionStrip: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FlareSizes.spacingSm) {
                ForEach(selection) { c in
                    Button { onToggleSelect?(c) } label: {
                        HStack(spacing: FlareSizes.spacingXs) {
                            AvatarView(userId: c.id, displayName: c.name, avatarURL: c.avatarURL, size: 24)
                            Text(c.name).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textPrimary)
                                .lineLimit(1)
                            Image(systemName: flareIconSymbol("close"))
                                .font(.system(size: FlareSizes.fontSize2xs, weight: .semibold))
                                .foregroundColor(colors.textTertiary)
                        }
                        .padding(.vertical, 2).padding(.leading, 2).padding(.trailing, FlareSizes.spacingSm)
                        .frame(maxWidth: 180)
                        .background(Capsule().fill(colors.bgSecondary))
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(removeSelectionLabel?(c.name) ?? c.name)
                }
            }
            .padding(.horizontal, FlareSizes.spacingMd).padding(.vertical, FlareSizes.spacingSm)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(selectionLabel ?? "")
    }

    @ViewBuilder
    private var rows: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        if items.isEmpty {
            if loading {
                ProgressView()
            } else if let empty {
                empty
            } else {
                EmptyStateView(title: strings.noContacts, icon: "people")
            }
        } else {
            ScrollViewReader { proxy in
                ZStack(alignment: .trailing) {
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            ForEach(groups, id: \.letter) { g in
                                Section {
                                    ForEach(g.people) { c in
                                        let current = !selectable && activeId != nil && c.id == activeId
                                        ContactItemView(item: c, selectable: selectable, selected: selectedIds.contains(c.id),
                                                        current: current,
                                                        trailing: trailing?(c),
                                                        onSelect: onSelect.map { select in { select(c) } },
                                                        onToggleSelect: onToggleSelect.map { toggle in { toggle(c) } })
                                            .padding(.horizontal, FlareSizes.spacingMd)
                                            .padding(.vertical, FlareSizes.spacingSm)
                                            .background(current ? colors.bgSelected : Color.clear)
                                    }
                                } header: {
                                    Text(g.letter)
                                        .font(.system(size: FlareSizes.fontSizeSm, weight: .semibold))
                                        .foregroundColor(colors.textTertiary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, FlareSizes.spacingMd).padding(.vertical, 4)
                                        .background(colors.bgSecondary)
                                        .id(g.letter)
                                }
                            }
                        }
                    }
                    if indexed && groups.count > 1 {
                        VStack(spacing: 2) {
                            ForEach(groups, id: \.letter) { g in
                                Text(g.letter)
                                    .font(.system(size: FlareSizes.fontSize2xs, weight: .semibold))
                                    .foregroundColor(colors.primaryText)
                                    .onTapGesture { withAnimation { proxy.scrollTo(g.letter, anchor: .top) } }
                                    .accessibilityLabel(strings.contactJumpTo.replacingOccurrences(of: "{letter}", with: g.letter))
                                    .accessibilityAddTraits(.isButton)
                            }
                        }
                        .padding(.trailing, 2)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel(strings.contactIndex)
                    }
                }
            }
        }
    }
}

/// New friends — requests to the user and requests the user sent. Spec: Contacts/NewFriendRequests
/// (`NewFriendRequestsView`). A request's `source` is its own line under the message (one line, truncated).
public struct NewFriendRequestsView: View {
    private let items: [FriendRequest]
    private let onAccept: ((FriendRequest) -> Void)?
    private let onReject: ((FriendRequest) -> Void)?
    private let onView: ((String) -> Void)?
    private let onWithdraw: ((FriendRequest) -> Void)?
    private let emptyText: String?
    private let acceptLabel: String?
    private let declineLabel: String?
    private let withdrawLabel: String?
    private let pending: [String: FlareFriendRequestAnswer]
    private let errors: [String: String]
    private let retryLabel: String?
    private let onRetry: ((FriendRequest) -> Void)?
    private let empty: AnyView?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// - Parameters:
    ///   - onView: Tapping the row (outside its buttons) opens the request's detail; called with
    ///     the request id. Without a handler the row is inert (Flutter/Compose `onView` parity).
    ///   - onWithdraw: Withdraws an outgoing request. Outgoing rows show a pending status instead
    ///     of accept/decline, and a withdraw button only with this handler.
    ///   - pending: Answers under way, by request id (Vue `pending`): the answer being sent spins, and both of
    ///     that row's buttons take no taps; other rows stay usable.
    ///   - errors: A failed answer's text, by request id: a danger banner under that row, with `retryLabel` /
    ///     `onRetry` while the row is not pending.
    ///   - empty: Replaces the whole empty state (a search with no match, an invitation to add someone).
    public init(items: [FriendRequest], emptyText: String? = nil,
                acceptLabel: String? = nil, declineLabel: String? = nil, withdrawLabel: String? = nil,
                onAccept: ((FriendRequest) -> Void)? = nil, onReject: ((FriendRequest) -> Void)? = nil,
                onView: ((String) -> Void)? = nil, onWithdraw: ((FriendRequest) -> Void)? = nil,
                pending: [String: FlareFriendRequestAnswer] = [:], errors: [String: String] = [:],
                retryLabel: String? = nil, onRetry: ((FriendRequest) -> Void)? = nil, empty: AnyView? = nil) {
        self.items = items; self.emptyText = emptyText
        self.acceptLabel = acceptLabel; self.declineLabel = declineLabel; self.withdrawLabel = withdrawLabel
        self.onAccept = onAccept; self.onReject = onReject; self.onView = onView; self.onWithdraw = onWithdraw
        self.pending = pending; self.errors = errors; self.retryLabel = retryLabel; self.onRetry = onRetry
        self.empty = empty
    }

    /// The row's tap action, or nil when the host did not opt in.
    static func rowTap(id: String, onView: ((String) -> Void)?) -> (() -> Void)? {
        guard let onView else { return nil }
        return { onView(id) }
    }

    /// A row's buttons, in order: decline and accept on an incoming request, withdraw on an
    /// outgoing one — each only when its handler exists.
    enum RowControl: Equatable { case decline, accept, withdraw }

    static func rowControls(_ direction: FriendRequestDirection, hasAccept: Bool, hasReject: Bool,
                            hasWithdraw: Bool) -> [RowControl] {
        switch direction {
        case .incoming: return (hasReject ? [.decline] : []) + (hasAccept ? [.accept] : [])
        case .outgoing: return hasWithdraw ? [.withdraw] : []
        }
    }

    /// Conditionally make the row tappable (only with an `onView` handler).
    private struct RowTap: ViewModifier {
        let action: (() -> Void)?
        func body(content: Content) -> some View {
            if let action {
                content.contentShape(Rectangle()).onTapGesture(perform: action)
                    .accessibilityAddTraits(.isButton)
            } else { content }
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        if items.isEmpty {
            if let empty { empty } else { EmptyStateView(title: emptyText ?? strings.newFriendRequestsEmpty, icon: "person-add") }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { req in
                        let answering = pending[req.id]
                        VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                            HStack(spacing: FlareSizes.spacingMd) {
                                AvatarView(userId: req.userId ?? req.id, displayName: req.name, avatarURL: req.avatarURL, size: 40)
                                VStack(alignment: .leading) {
                                    Text(req.name).font(.system(size: FlareSizes.fontSizeLg, weight: .medium)).foregroundColor(colors.textPrimary)
                                    if let m = req.message, !m.isEmpty {
                                        Text(m).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary).lineLimit(1)
                                    }
                                    // The source is a line of its own, in the same quiet style, never beside the message.
                                    if let source = req.source, !source.isEmpty {
                                        Text(source).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                                            .lineLimit(1).truncationMode(.tail)
                                    }
                                }
                                Spacer()
                                if req.direction == .outgoing {
                                    Text(strings.newFriendRequestsPending)
                                        .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
                                }
                                ForEach(Self.rowControls(req.direction, hasAccept: onAccept != nil, hasReject: onReject != nil,
                                                         hasWithdraw: onWithdraw != nil), id: \.self) { control in
                                    switch control {
                                    // 出口用 .quiet 而不是 .secondary:secondary 是填充+描边,
                                    // 分量和旁边的接受按钮相当,一行里两颗都想被点。
                                    case .decline:
                                        ButtonView(label: declineLabel ?? strings.reject, variant: .quiet, size: .sm,
                                                   loading: answering == .reject, disabled: answering != nil) { onReject?(req) }
                                    case .accept:
                                        ButtonView(label: acceptLabel ?? strings.newFriendRequestsAccept, size: .sm,
                                                   loading: answering == .accept, disabled: answering != nil) { onAccept?(req) }
                                    case .withdraw:
                                        ButtonView(label: withdrawLabel ?? strings.newFriendRequestsWithdraw, variant: .quiet, size: .sm) { onWithdraw?(req) }
                                    }
                                }
                            }
                            .modifier(RowTap(action: Self.rowTap(id: req.id, onView: onView)))
                            if let error = errors[req.id] {
                                StatusBannerView(text: error, tone: .danger,
                                                 actionText: answering == nil ? (retryLabel ?? strings.retry) : nil,
                                                 onAction: answering == nil ? { onRetry?(req) } : nil)
                            }
                        }
                        .padding(.horizontal, FlareSizes.spacingMd).padding(.vertical, FlareSizes.spacingSm)
                    }
                }
            }
        }
    }
}

/// The answer a friend-request row is sending (``NewFriendRequestsView`` `pending`).
public enum FlareFriendRequestAnswer: Sendable, Equatable { case accept, reject }

/// My groups. Spec: Contacts/GroupList (`GroupListView`).
public struct GroupListView: View {
    private let items: [GroupSummary]
    private let onSelect: ((GroupSummary) -> Void)?
    private let emptyText: String?
    private let empty: AnyView?
    private let activeId: String?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// - Parameters:
    ///   - emptyText: Replaces the line the kit writes when there is no group.
    ///   - empty: Replaces the whole empty state, so it can say what to do about it.
    ///   - activeId: The group the detail pane beside the list shows (Vue `activeId`): that row on the selected ground
    ///     with a primary bar at its start, its name in the primary colour and semibold, read as selected.
    public init(items: [GroupSummary], emptyText: String? = nil, empty: AnyView? = nil,
                onSelect: ((GroupSummary) -> Void)? = nil, activeId: String? = nil) {
        self.items = items; self.emptyText = emptyText; self.empty = empty; self.onSelect = onSelect
        self.activeId = activeId
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        if items.isEmpty {
            if let empty { empty } else { EmptyStateView(title: emptyText ?? strings.noGroups, icon: "group") }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { g in
                        let current = activeId != nil && g.id == activeId
                        Button { onSelect?(g) } label: {
                            HStack(spacing: FlareSizes.spacingMd) {
                                AvatarView(userId: g.id, displayName: g.name, avatarURL: g.avatarURL, size: 40)
                                VStack(alignment: .leading) {
                                    Text(g.name).font(.system(size: FlareSizes.fontSizeLg, weight: current ? .semibold : .medium))
                                        .foregroundColor(current ? colors.primaryText : colors.textPrimary)
                                    Text(strings.memberCount(g.memberCount)).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .padding(.horizontal, FlareSizes.spacingMd).padding(.vertical, FlareSizes.spacingSm)
                            .background(current ? colors.bgSelected : Color.clear)
                            .overlay(alignment: .leading) { if current { Rectangle().fill(colors.primary).frame(width: 3) } }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(current ? .isSelected : [])
                    }
                }
            }
        }
    }
}
