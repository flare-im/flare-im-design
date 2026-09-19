import SwiftUI

/// Personal center. Spec: Profile/ProfilePanel (`ProfilePanelView`).
///
/// The header is a single tappable-to-edit target (trailing chevron signals it), with the QR
/// key as its own control beside it (`onQr`). Rows render as one or more grouped section
/// cards (iOS style): pass `sections` for grouping, or `entries` for a single flat card.
public struct ProfilePanelView: View {
    private let user: UserProfile
    private let entries: [FlareSettingsItem]?
    private let sections: [FlareSettingsSection]?
    private let signaturePlaceholder: String?
    private let onEdit: (() -> Void)?
    private let onQr: (() -> Void)?
    private let onEntry: ((FlareSettingsItem) -> Void)?
    private let onToggle: ((FlareSettingsItem, Bool) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// Panel entries built from host-overridable copy.
    public static func entries(for strings: FlareStrings) -> [FlareSettingsItem] {
        [
            FlareSettingsItem(key: "favorites", label: strings.favorites, icon: "star"),
            FlareSettingsItem(key: "moments", label: strings.moments, icon: "moments"),
            FlareSettingsItem(key: "settings", label: strings.settings, icon: "settings"),
        ]
    }

    /// Entries with the kit's built-in copy. Prefer leaving `entries` unset so the view
    /// resolves them from the environment instead.
    public static let defaultEntries: [FlareSettingsItem] = entries(for: FlareStrings())

    public init(user: UserProfile,
                entries: [FlareSettingsItem]? = nil,
                sections: [FlareSettingsSection]? = nil,
                signaturePlaceholder: String? = nil,
                onEdit: (() -> Void)? = nil, onQr: (() -> Void)? = nil,
                onEntry: ((FlareSettingsItem) -> Void)? = nil,
                onToggle: ((FlareSettingsItem, Bool) -> Void)? = nil) {
        self.user = user
        self.entries = entries
        self.sections = sections
        self.signaturePlaceholder = signaturePlaceholder
        self.onEdit = onEdit; self.onQr = onQr; self.onEntry = onEntry; self.onToggle = onToggle
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let dark = scheme == .dark
        // Normalize to grouped sections so the body has one render path (mirrors the Vue panel).
        let sections = self.sections ?? [FlareSettingsSection(items: entries ?? Self.entries(for: strings))]
        VStack(spacing: 0) {
            header

            ForEach(Array(sections.enumerated()), id: \.element.id) { i, section in
                // Shared row → `kind` (toggle/value/navigation) and `detail` are honoured here too.
                VStack(spacing: 0) {
                    ForEach(Array(section.items.enumerated()), id: \.element.id) { j, e in
                        if j > 0 {
                            Divider().overlay(colors.borderSecondary)
                                .padding(.leading, FlareSizes.spacingMd)
                        }
                        FlareSettingsRow(item: e, onToggle: onToggle, onSelect: { onEntry?($0) })
                            .padding(.horizontal, FlareSizes.spacingMd)
                    }
                }
                .flareGroupedCard(colors, dark: dark)
                .padding(.horizontal, FlareSizes.spacingMd)
                .padding(.top, i == 0 ? FlareSizes.spacingMd : FlareSizes.spacingSm)
            }
            Spacer()
        }
    }

    /// The QR key's trailing inset over the identity row, so it sits on the room the row leaves for it: the
    /// row's trailing padding, plus the chevron column and the row's spacing when the row opens the editor.
    static func qrTrailingInset(opensEditor: Bool) -> CGFloat {
        FlareSizes.spacingMd + (opensEditor ? FlareSizes.iconSizeSm + FlareSizes.spacingMd : 0)
    }

    /// A quiet identity card on the same surface as the groups below it (G18): the profile is content, not
    /// a banner. The identity row and the QR key are sibling controls, so each is reached and named on its own.
    private var header: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        return ZStack(alignment: .trailing) {
            identityRow(colors)
            if let onQr {
                Button(action: onQr) {
                    Image(systemName: flareIconSymbol("qr"))
                        .font(.system(size: FlareSizes.iconSizeMd))
                        .foregroundColor(colors.textSecondary)
                        .flareTouchTarget()
                }
                .buttonStyle(.plain)
                .accessibilityLabel(strings.myQrCode)
                .padding(.trailing, Self.qrTrailingInset(opensEditor: onEdit != nil))
            }
        }
        .flareGroupedCard(colors, dark: scheme == .dark)
        .padding(.horizontal, FlareSizes.spacingMd)
        .padding(.top, FlareSizes.spacingMd)
    }

    /// Avatar, name, signature and Flare ID, with a chevron: one control named "{name}，编辑资料" that opens the
    /// editor; plain content without `onEdit`. It leaves room at its end for the QR key laid over it.
    @ViewBuilder
    private func identityRow(_ colors: FlareColors) -> some View {
        let content = HStack(spacing: FlareSizes.spacingMd) {
            AvatarView(userId: user.id, displayName: user.name, avatarURL: user.avatarURL, size: 56)
            VStack(alignment: .leading, spacing: 3) {
                Text(user.name).font(.system(size: FlareSizes.fontSize3xl, weight: .bold)).foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                if let s = user.signature, !s.isEmpty {
                    Text(s).font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.textSecondary)
                        .lineLimit(1)
                } else if let placeholder = signaturePlaceholder, !placeholder.isEmpty {
                    // What to write when the user has no signature yet.
                    Text(placeholder).font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.textTertiary)
                        .lineLimit(1)
                }
                if let f = user.flareId, !f.isEmpty {
                    // The label is the strings table's, so a host that renames or translates the
                    // public handle is followed here too (``ProfileCardView`` already reads it).
                    Text("\(strings.contactDetailFlareId): \(f)")
                        .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                }
            }
            Spacer(minLength: 0)
            // Room for the QR key, which is its own control laid over this row.
            if onQr != nil { Color.clear.frame(width: FlareSizes.touchTargetMin, height: 1) }
            if onEdit != nil {
                Image(systemName: "chevron.right").font(.system(size: FlareSizes.fontSizeLg, weight: .semibold))
                    .foregroundColor(colors.textTertiary)
                    .frame(width: FlareSizes.iconSizeSm)
                    .accessibilityHidden(true)
            }
        }
        .padding(.leading, FlareSizes.spacingLg)
        .padding(.trailing, FlareSizes.spacingMd)
        .padding(.vertical, FlareSizes.spacingLg)
        .frame(maxWidth: .infinity, minHeight: Self.identityMinHeight, alignment: .leading)
        .contentShape(Rectangle())
        if let onEdit {
            Button(action: onEdit) { content }
                .buttonStyle(.plain)
                .accessibilityLabel(strings.profilePanelEditProfile(user.name))
        } else {
            content.accessibilityElement(children: .combine)
        }
    }

    /// The identity row's height (Vue `min-height: 88px`), well above the 44pt target.
    static let identityMinHeight: CGFloat = 88
}

/// Profile editor. Spec: Profile/ProfileEditor (`ProfileEditorView`).
public struct ProfileEditorView: View {
    private let user: UserProfile
    private let labels: FlareProfileEditorLabels
    private let busy: Bool
    private let onSave: ((String, String) -> Void)?
    private let onCancel: (() -> Void)?
    private let onPickAvatar: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @State private var name: String
    @State private var signature: String

    public init(user: UserProfile, labels: FlareProfileEditorLabels = FlareProfileEditorLabels(), busy: Bool = false,
                onSave: ((String, String) -> Void)? = nil, onCancel: (() -> Void)? = nil, onPickAvatar: (() -> Void)? = nil) {
        self.user = user; self.labels = labels; self.busy = busy; self.onSave = onSave; self.onCancel = onCancel; self.onPickAvatar = onPickAvatar
        _name = State(initialValue: user.name)
        _signature = State(initialValue: user.signature ?? "")
    }

    private var copy: FlareProfileEditorLabels.Resolved { labels.resolve(strings) }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            Button { onPickAvatar?() } label: {
                AvatarView(userId: user.id, displayName: name.isEmpty ? user.name : name, avatarURL: user.avatarURL, size: 80)
                    .overlay(alignment: .bottomTrailing) {
                        if onPickAvatar != nil { Image(systemName: "camera").font(.system(size: 12)).foregroundColor(.white)
                            .padding(6).background(Circle().fill(colors.primary)) }
                    }
            }
            .buttonStyle(.plain)
            .disabled(busy || onPickAvatar == nil)
            .frame(maxWidth: .infinity)

            Text(copy.nickname).font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.textSecondary)
            InputView(text: $name, placeholder: copy.nicknamePlaceholder, maxLength: 24, disabled: busy, clearable: true)
            Text(copy.bio).font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.textSecondary)
            InputView(text: $signature, placeholder: copy.bioPlaceholder, multiline: true, maxLength: 60, disabled: busy)

            HStack(spacing: FlareSizes.spacingMd) {
                ButtonView(label: copy.cancel, variant: .secondary, size: .lg,
                           disabled: busy || onCancel == nil, block: true, action: onCancel)
                ButtonView(label: copy.save, size: .lg, loading: busy,
                           disabled: name.trimmingCharacters(in: .whitespaces).isEmpty || onSave == nil,
                           block: true) { onSave?(name, signature) }
            }
            .padding(.top, FlareSizes.spacingMd)
        }
        .padding(FlareSizes.spacingLg)
    }
}

/// Grouped card: a section's rows float together on one elevated
/// surface (bgElevated, radiusXl, soft theme-tinted lift in dark). Shared by
/// ``SettingsListView`` and ``ProfilePanelView``; matches Android / Flutter.
struct FlareGroupedCard: ViewModifier {
    let colors: FlareColors
    let dark: Bool
    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl, style: .continuous).fill(colors.bgElevated))
            .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusXl, style: .continuous))
            .shadow(color: dark ? Color.black.opacity(0.5) : Color(.sRGB, red: 0x15 / 255, green: 0x13 / 255, blue: 0x20 / 255, opacity: 0.08),
                    radius: dark ? 12 : 11, y: 8)
            .shadow(color: dark ? colors.primary.opacity(0.14) : Color.clear,
                    radius: dark ? 6 : 0, y: dark ? 2 : 0)
    }
}

extension View {
    func flareGroupedCard(_ colors: FlareColors, dark: Bool) -> some View {
        modifier(FlareGroupedCard(colors: colors, dark: dark))
    }
}

/// Settings list. Spec: Profile/SettingsList (`SettingsListView`).
///
/// Self-drawn grouped cards (not a native `List`) so the surface matches the
/// Android / Flutter settings list: section title in tertiary 12pt, rows on an
/// elevated radius-14 card with indented hairline dividers.
public struct SettingsListView: View {
    private let sections: [FlareSettingsSection]
    private let onToggle: ((FlareSettingsItem, Bool) -> Void)?
    private let onSelect: ((FlareSettingsItem) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(sections: [FlareSettingsSection], onToggle: ((FlareSettingsItem, Bool) -> Void)? = nil, onSelect: ((FlareSettingsItem) -> Void)? = nil) {
        self.sections = sections; self.onToggle = onToggle; self.onSelect = onSelect
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let dark = scheme == .dark
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(sections) { section in
                    if let t = section.title, !t.isEmpty {
                        Text(t)
                            .font(.system(size: FlareSizes.fontSizeSm))
                            .foregroundColor(colors.textTertiary)
                            .padding(.horizontal, FlareSizes.spacingLg)
                            .padding(.top, FlareSizes.spacingMd)
                            .padding(.bottom, FlareSizes.spacingSm)
                    } else {
                        Spacer().frame(height: FlareSizes.spacingSm)
                    }
                    VStack(spacing: 0) {
                        ForEach(Array(section.items.enumerated()), id: \.element.id) { i, item in
                            if i > 0 {
                                Divider().overlay(colors.borderSecondary)
                                    .padding(.leading, FlareSizes.spacingMd)
                            }
                            FlareSettingsRow(item: item, onToggle: onToggle, onSelect: onSelect)
                                .padding(.horizontal, FlareSizes.spacingMd)
                        }
                    }
                    .flareGroupedCard(colors, dark: dark)
                    .padding(.horizontal, FlareSizes.spacingMd)
                    .padding(.bottom, FlareSizes.spacingSm)
                }
            }
            .padding(.vertical, FlareSizes.spacingSm)
        }
        .background(colors.bgSecondary)
    }
}

/// One settings/profile entry row — icon, label, then the trailing affordance for its
/// ``FlareSettingKind``: a switch (toggle), detail + chevron (navigation), a button with no chevron
/// (action, red when `danger`), or plain information that ignores taps (value).
///
/// Shared by ``SettingsListView`` and ``ProfilePanelView`` so the two can't drift — previously
/// `ProfilePanelView` re-implemented this row and silently dropped `kind` and `detail`, rendering
/// every entry as a bare label + chevron.
public struct FlareSettingsRow: View {
    private let item: FlareSettingsItem
    private let onToggle: ((FlareSettingsItem, Bool) -> Void)?
    private let onSelect: ((FlareSettingsItem) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(item: FlareSettingsItem,
                onToggle: ((FlareSettingsItem, Bool) -> Void)? = nil,
                onSelect: ((FlareSettingsItem) -> Void)? = nil) {
        self.item = item; self.onToggle = onToggle; self.onSelect = onSelect
    }

    /// A value longer than this many characters goes under the label (Vue `STACK_AFTER_CHARACTERS`).
    static let stackAfterCharacters = 16

    /// Whether the row's value goes under its label, on up to three lines (FR-084): a value longer than
    /// 16 characters, counted as Unicode code points as Vue counts them. A toggle never stacks; a shorter
    /// value stays at the end of the row on one line.
    static func stacksValue(_ item: FlareSettingsItem) -> Bool {
        item.kind != .toggle && (item.detail?.unicodeScalars.count ?? 0) > stackAfterCharacters
    }

    /// Whether the row is a control the viewer can operate: everything but `value`, which is
    /// information and ignores taps even when the list has a select handler.
    static func isControl(_ item: FlareSettingsItem) -> Bool { item.kind != .value }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        Group {
            if item.kind == .toggle {
                Toggle(isOn: Binding(get: { item.value }, set: { onToggle?(item, $0) })) {
                    rowLabel(colors)
                }
                .tint(colors.primaryText)
                .disabled(item.disabled || onToggle == nil)
            } else if item.kind != .value, let onSelect {
                SwiftUI.Button { onSelect(item) } label: { rowContent(colors) }
                    .buttonStyle(.plain)
                    .disabled(item.disabled)
            } else {
                // A `value` row is information, not a control: no button trait, no pressed state, and a
                // tap does nothing — it is read as one element, "label, detail". A row of any other kind
                // with nothing to run reads the same way.
                rowContent(colors)
                    .accessibilityElement(children: .combine)
            }
        }
        .frame(minHeight: 48)
        .opacity(item.disabled ? 0.45 : 1)
    }

    /// The row's label, value and chevron (stacked or on one line).
    private func rowContent(_ colors: FlareColors) -> some View {
        Group {
            if Self.stacksValue(item), let detail = item.detail {
                // The value under the label, beside the icon column; the chevron stays on the label's line.
                HStack(alignment: .top, spacing: FlareSizes.spacingMd) {
                    rowIcon(colors)
                    VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                        HStack(spacing: FlareSizes.spacingMd) {
                            rowTitle(colors)
                            Spacer(minLength: 0)
                            chevron(colors)
                        }
                        Text(detail).font(.system(size: FlareSizes.fontSizeMd))
                            .foregroundColor(colors.textSecondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.vertical, FlareSizes.spacingSm)
            } else {
                HStack(spacing: FlareSizes.spacingMd) {
                    rowLabel(colors)
                    Spacer()
                    if let detail = item.detail {
                        Text(detail).font(.system(size: FlareSizes.fontSizeMd))
                            .foregroundColor(colors.textTertiary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    chevron(colors)
                }
            }
        }
        .contentShape(Rectangle())
    }

    private func rowLabel(_ colors: FlareColors) -> some View {
        HStack(spacing: FlareSizes.spacingMd) {
            rowIcon(colors)
            rowTitle(colors)
        }
    }

    @ViewBuilder private func rowIcon(_ colors: FlareColors) -> some View {
        if let icon = item.icon {
            IconView(icon, size: FlareSizes.iconSizeSm, color: colors.textSecondary)
        }
    }

    private func rowTitle(_ colors: FlareColors) -> some View {
        Text(item.label).font(.system(size: FlareSizes.fontSizeLg))
            .foregroundColor(item.danger ? colors.errorText : colors.textPrimary)
    }

    @ViewBuilder private func chevron(_ colors: FlareColors) -> some View {
        if item.kind == .navigation {
            Image(systemName: "chevron.right").font(.system(size: 12))
                .foregroundColor(colors.textTertiary)
        }
    }
}

/// Localizable labels for ``ProfileEditorView``. Defaults keep today's English copy.
public struct FlareProfileEditorLabels: Sendable {
    public var nickname: String?
    public var nicknamePlaceholder: String?
    public var bio: String?
    public var bioPlaceholder: String?
    public var cancel: String?
    public var save: String?

    public init(
        nickname: String? = nil,
        nicknamePlaceholder: String? = nil,
        bio: String? = nil,
        bioPlaceholder: String? = nil,
        cancel: String? = nil,
        save: String? = nil
    ) {
        self.nickname = nickname
        self.nicknamePlaceholder = nicknamePlaceholder
        self.bio = bio
        self.bioPlaceholder = bioPlaceholder
        self.cancel = cancel
        self.save = save
    }
}

public extension FlareProfileEditorLabels {
    /// Every label filled in: an explicit label wins, otherwise the `flareStrings` provider.
    struct Resolved: Sendable {
        public let nickname: String
        public let nicknamePlaceholder: String
        public let bio: String
        public let bioPlaceholder: String
        public let cancel: String
        public let save: String
    }
    func resolve(_ strings: FlareStrings) -> Resolved {
        Resolved(
            nickname: nickname ?? strings.profileEditorNickname,
            nicknamePlaceholder: nicknamePlaceholder ?? strings.profileEditorNicknamePlaceholder,
            bio: bio ?? strings.profileEditorBio,
            bioPlaceholder: bioPlaceholder ?? strings.profileEditorBioPlaceholder,
            cancel: cancel ?? strings.cancel,
            save: save ?? strings.profileEditorSave
        )
    }
}
