import SwiftUI

/// Directory row. Spec: Contacts/ContactItem (`ContactItemView`).
public struct ContactItemView: View {
    private let item: Contact
    private let showPresence: Bool
    private let selectable: Bool
    private let selected: Bool
    private let trailing: AnyView?
    private let onSelect: (() -> Void)?
    private let onToggleSelect: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    /// - Parameters:
    ///   - selectable: A leading checkbox shows `selected`; tapping the row calls `onToggleSelect`
    ///     (not `onSelect`), and the row is one checkbox for assistive technology, named by the contact.
    ///   - trailing: Content at the row end (a button, a status). Its controls keep their own taps
    ///     and focus; they do not select the row.
    ///   - onSelect: Tapping the row outside selection mode. Without a handler for the current mode
    ///     the row is not a control.
    public init(item: Contact, showPresence: Bool = true, selectable: Bool = false, selected: Bool = false,
                trailing: AnyView? = nil, onSelect: (() -> Void)? = nil, onToggleSelect: (() -> Void)? = nil) {
        self.item = item; self.showPresence = showPresence
        self.selectable = selectable; self.selected = selected; self.trailing = trailing
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
                    .modifier(RowSemantics(name: item.name, selectable: selectable, selected: selected, control: true))
            } else {
                row.modifier(RowSemantics(name: item.name, selectable: selectable, selected: selected, control: false))
            }
            if let trailing { trailing }
        }
    }

    /// One element per row. A selectable row reads as a checkbox named by the contact, with its
    /// checked state as the selected trait (the kit ``CheckboxView`` convention).
    private struct RowSemantics: ViewModifier {
        let name: String
        let selectable: Bool
        let selected: Bool
        let control: Bool

        func body(content: Content) -> some View {
            let button: AccessibilityTraits = control ? .isButton : []
            let checked: AccessibilityTraits = selectable && selected ? .isSelected : []
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
                Text(item.name).font(.system(size: FlareSizes.fontSizeLg, weight: .medium)).foregroundColor(colors.textPrimary)
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
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// - Parameters:
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
                onSelect: ((Contact) -> Void)? = nil, onToggleSelect: ((Contact) -> Void)? = nil) {
        self.items = items; self.indexed = indexed; self.loading = loading
        self.selectable = selectable; self.selectedIds = selectedIds; self.trailing = trailing
        self.empty = empty
        self.onSelect = onSelect; self.onToggleSelect = onToggleSelect
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
                                        ContactItemView(item: c, selectable: selectable, selected: selectedIds.contains(c.id),
                                                        trailing: trailing?(c),
                                                        onSelect: onSelect.map { select in { select(c) } },
                                                        onToggleSelect: onToggleSelect.map { toggle in { toggle(c) } })
                                            .padding(.horizontal, FlareSizes.spacingMd)
                                            .padding(.vertical, FlareSizes.spacingSm)
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
                            }
                        }
                        .padding(.trailing, 2)
                    }
                }
            }
        }
    }
}

/// New friends — requests to the user and requests the user sent. Spec: Contacts/NewFriendRequests
/// (`NewFriendRequestsView`).
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
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// - Parameters:
    ///   - onView: Tapping the row (outside its buttons) opens the request's detail; called with
    ///     the request id. Without a handler the row is inert (Flutter/Compose `onView` parity).
    ///   - onWithdraw: Withdraws an outgoing request. Outgoing rows show a pending status instead
    ///     of accept/decline, and a withdraw button only with this handler.
    public init(items: [FriendRequest], emptyText: String? = nil,
                acceptLabel: String? = nil, declineLabel: String? = nil, withdrawLabel: String? = nil,
                onAccept: ((FriendRequest) -> Void)? = nil, onReject: ((FriendRequest) -> Void)? = nil,
                onView: ((String) -> Void)? = nil, onWithdraw: ((FriendRequest) -> Void)? = nil) {
        self.items = items; self.emptyText = emptyText
        self.acceptLabel = acceptLabel; self.declineLabel = declineLabel; self.withdrawLabel = withdrawLabel
        self.onAccept = onAccept; self.onReject = onReject; self.onView = onView; self.onWithdraw = onWithdraw
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
            EmptyStateView(title: emptyText ?? strings.newFriendRequestsEmpty, icon: "person-add")
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { req in
                        HStack(spacing: FlareSizes.spacingMd) {
                            AvatarView(userId: req.id, displayName: req.name, avatarURL: req.avatarURL, size: 44)
                            VStack(alignment: .leading) {
                                Text(req.name).font(.system(size: FlareSizes.fontSizeLg, weight: .medium)).foregroundColor(colors.textPrimary)
                                if let m = req.message, !m.isEmpty {
                                    Text(m).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary).lineLimit(1)
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
                                    ButtonView(label: declineLabel ?? strings.reject, variant: .quiet, size: .sm) { onReject?(req) }
                                case .accept:
                                    ButtonView(label: acceptLabel ?? strings.newFriendRequestsAccept, size: .sm) { onAccept?(req) }
                                case .withdraw:
                                    ButtonView(label: withdrawLabel ?? strings.newFriendRequestsWithdraw, variant: .quiet, size: .sm) { onWithdraw?(req) }
                                }
                            }
                        }
                        .padding(.horizontal, FlareSizes.spacingMd).padding(.vertical, FlareSizes.spacingSm)
                        .modifier(RowTap(action: Self.rowTap(id: req.id, onView: onView)))
                    }
                }
            }
        }
    }
}

/// My groups. Spec: Contacts/GroupList (`GroupListView`).
public struct GroupListView: View {
    private let items: [GroupSummary]
    private let onSelect: ((GroupSummary) -> Void)?
    private let emptyText: String?
    private let empty: AnyView?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// - Parameters:
    ///   - emptyText: Replaces the line the kit writes when there is no group.
    ///   - empty: Replaces the whole empty state, so it can say what to do about it.
    public init(items: [GroupSummary], emptyText: String? = nil, empty: AnyView? = nil,
                onSelect: ((GroupSummary) -> Void)? = nil) {
        self.items = items; self.emptyText = emptyText; self.empty = empty; self.onSelect = onSelect
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        if items.isEmpty {
            if let empty { empty } else { EmptyStateView(title: emptyText ?? strings.noGroups, icon: "group") }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { g in
                        Button { onSelect?(g) } label: {
                            HStack(spacing: FlareSizes.spacingMd) {
                                AvatarView(userId: g.id, displayName: g.name, avatarURL: g.avatarURL, size: 44)
                                VStack(alignment: .leading) {
                                    Text(g.name).font(.system(size: FlareSizes.fontSizeLg, weight: .medium)).foregroundColor(colors.textPrimary)
                                    Text(strings.memberCount(g.memberCount)).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .padding(.horizontal, FlareSizes.spacingMd).padding(.vertical, FlareSizes.spacingSm)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
