import SwiftUI

/// One person ``ContactPickerView`` offers. `isSelf` marks the user themselves, whose name carries
/// `contactPickerSelfSuffix`.
public struct FlareContactPickerEntry: Identifiable, Sendable, Equatable {
    public let userId: String
    public let name: String
    public let avatarUrl: String?
    public let subtitle: String?
    public let isSelf: Bool
    public var id: String { userId }
    public init(userId: String, name: String, avatarUrl: String? = nil, subtitle: String? = nil, isSelf: Bool = false) {
        self.userId = userId; self.name = name; self.avatarUrl = avatarUrl; self.subtitle = subtitle; self.isSelf = isSelf
    }
}

/// One tab of ``ContactPickerView``. The ids ``friends`` and ``groupMembers`` take the kit's tab names when `label`
/// is nil; any other id needs its `label`.
public struct FlareContactPickerGroup: Identifiable, Sendable, Equatable {
    public static let friends = "friends"
    public static let groupMembers = "groupMembers"

    public let id: String
    public let label: String?
    public let entries: [FlareContactPickerEntry]
    public init(id: String, label: String? = nil, entries: [FlareContactPickerEntry]) {
        self.id = id; self.label = label; self.entries = entries
    }

    /// The tab's name: the host's label, else the kit's for a known id, else the id.
    public func resolvedLabel(_ strings: FlareStrings) -> String {
        if let label, !label.isEmpty { return label }
        switch id {
        case Self.friends: return strings.contactPickerFriends
        case Self.groupMembers: return strings.contactPickerGroupMembers
        default: return id
        }
    }
}

/// Contact picker — choose the person a contact card shares. Spec: Contacts/ContactPicker (`ContactPickerView`).
///
/// A title with a cancel key, tabs for the groups when there is more than one (friends, group members), a search
/// field (`searchable`) over the open tab's names and subtitles, and a lazily built list; a tab with no one, or a
/// search that matches no one, shows `contactPickerEmpty`. The user's own row reads "name（我）".
///
/// One person (`multiple` off): a tap on a row calls `onSelect` with that entry. Several: rows are checkboxes and
/// the confirm key calls `onSelect` with the entries in the order they were picked.
///
/// It draws its own header (Cancel, the title) and declares it (``SwiftUI/View/flareSheetOwnHeader(_:)``): present it
/// with `flareBottomSheet(…, fill: true)` and the sheet keeps its title as the accessible name only.
public struct ContactPickerView: View {
    private let groups: [FlareContactPickerGroup]
    private let searchable: Bool
    private let multiple: Bool
    private let title: String?
    private let onSelect: (([FlareContactPickerEntry]) -> Void)?
    private let onCancel: (() -> Void)?
    @State private var activeGroup: String
    @State private var query = ""
    @State private var picked: [String] = []
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(groups: [FlareContactPickerGroup], searchable: Bool = true, multiple: Bool = false,
                title: String? = nil, onSelect: (([FlareContactPickerEntry]) -> Void)? = nil,
                onCancel: (() -> Void)? = nil) {
        self.groups = groups; self.searchable = searchable; self.multiple = multiple; self.title = title
        self.onSelect = onSelect; self.onCancel = onCancel
        self._activeGroup = State(initialValue: groups.first?.id ?? "")
    }

    // MARK: Rules

    /// The name a row shows: the user's own carries `contactPickerSelfSuffix`.
    static func displayName(_ entry: FlareContactPickerEntry, _ strings: FlareStrings) -> String {
        entry.isSelf ? entry.name + strings.contactPickerSelfSuffix : entry.name
    }

    /// The entries matching `query` (case-insensitive, in the name or the subtitle); all of them for a blank query.
    static func filter(_ entries: [FlareContactPickerEntry], query: String) -> [FlareContactPickerEntry] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return entries }
        return entries.filter {
            $0.name.lowercased().contains(needle) || ($0.subtitle?.lowercased().contains(needle) ?? false)
        }
    }

    /// The picked entries in the order they were picked, each once, found in whichever group holds them.
    static func pickedEntries(_ ids: [String], in groups: [FlareContactPickerGroup]) -> [FlareContactPickerEntry] {
        var byId: [String: FlareContactPickerEntry] = [:]
        for group in groups { for entry in group.entries where byId[entry.userId] == nil { byId[entry.userId] = entry } }
        return ids.compactMap { byId[$0] }
    }

    /// `ids` with `userId` added at the end, or taken out.
    static func toggled(_ ids: [String], _ userId: String) -> [String] {
        ids.contains(userId) ? ids.filter { $0 != userId } : ids + [userId]
    }

    private var openGroup: FlareContactPickerGroup? {
        groups.first { $0.id == activeGroup } ?? groups.first
    }

    // MARK: View

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let entries = Self.filter(openGroup?.entries ?? [], query: searchable ? query : "")
        VStack(spacing: 0) {
            ZStack {
                Text(title ?? strings.contactPickerTitle)
                    .font(.system(size: FlareSizes.fontSize2xl, weight: .semibold)).foregroundColor(colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                HStack {
                    ButtonView(label: strings.cancel, variant: .text, size: .sm) { onCancel?() }
                    Spacer()
                }
            }
            .padding(.horizontal, FlareSizes.spacingSm).padding(.vertical, FlareSizes.spacingSm)

            if groups.count > 1 {
                FilterTabsView(options: groups.map { FlareFilterTabOption(value: $0.id, label: $0.resolvedLabel(strings)) },
                               selection: $activeGroup)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, FlareSizes.spacingLg).padding(.bottom, FlareSizes.spacingSm)
            }
            if searchable {
                SearchBarView(text: $query, placeholder: strings.contactPickerSearch)
                    .padding(.horizontal, FlareSizes.spacingLg).padding(.bottom, FlareSizes.spacingSm)
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    if entries.isEmpty {
                        EmptyStateView(title: strings.contactPickerEmpty, icon: "people")
                    } else {
                        ForEach(entries) { entry in row(entry) }
                    }
                }
            }
            .frame(maxHeight: .infinity)

            if multiple {
                Divider().overlay(colors.borderPrimary)
                HStack(spacing: FlareSizes.spacingMd) {
                    Text(strings.selectedCount(picked.count))
                        .font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.textSecondary)
                    Spacer()
                    ButtonView(label: strings.confirm, disabled: picked.isEmpty) {
                        onSelect?(Self.pickedEntries(picked, in: groups))
                    }
                }
                .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingMd)
            }
        }
        .frame(maxWidth: .infinity)
        .background(colors.bgPrimary)
        .flareSheetOwnHeader()
    }

    private func row(_ entry: FlareContactPickerEntry) -> some View {
        let contact = Contact(id: entry.userId, name: Self.displayName(entry, strings), avatarURL: entry.avatarUrl,
                              signature: entry.subtitle)
        return ContactItemView(
            item: contact, showPresence: false,
            selectable: multiple, selected: picked.contains(entry.userId),
            onSelect: multiple ? nil : { onSelect?([entry]) },
            onToggleSelect: multiple ? { picked = Self.toggled(picked, entry.userId) } : nil
        )
        .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingSm)
    }
}
