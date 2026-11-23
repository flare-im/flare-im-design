import SwiftUI

/// Personal center. Spec: Profile/ProfilePanel (`ProfilePanelView`).
///
/// The header is a single tappable-to-edit target (trailing chevron signals it), with the QR
/// key as its own control beside it (`onQr`). Rows render as one or more grouped section
/// cards (iOS style): pass `sections` for grouping, or `entries` for a single flat card. A row's
/// `current` draws it selected. `layout: .sidebar` (a two-pane left column) keeps the card at the top
/// and scrolls the groups under it, so the host must not wrap the panel in a scroll view.
public struct ProfilePanelView: View {
    private let user: UserProfile
    private let entries: [FlareSettingsItem]?
    private let sections: [FlareSettingsSection]?
    private let signaturePlaceholder: String?
    private let identityActionLabel: String?
    private let onEdit: (() -> Void)?
    private let onQr: (() -> Void)?
    private let onEntry: ((FlareSettingsItem) -> Void)?
    private let onToggle: ((FlareSettingsItem, Bool) -> Void)?
    private let layout: FlareProfilePanelLayout
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
                identityActionLabel: String? = nil,
                onEdit: (() -> Void)? = nil, onQr: (() -> Void)? = nil,
                onEntry: ((FlareSettingsItem) -> Void)? = nil,
                onToggle: ((FlareSettingsItem, Bool) -> Void)? = nil,
                layout: FlareProfilePanelLayout = .page) {
        self.user = user
        self.entries = entries
        self.sections = sections
        self.signaturePlaceholder = signaturePlaceholder
        self.identityActionLabel = identityActionLabel
        self.onEdit = onEdit; self.onQr = onQr; self.onEntry = onEntry; self.onToggle = onToggle
        self.layout = layout
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            if layout == .sidebar {
                // The card stays put; the groups scroll in the height left under it.
                ScrollView { groups.padding(.bottom, FlareSizes.spacingMd) }
            } else {
                groups
                Spacer()
            }
        }
    }

    private var groups: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let dark = scheme == .dark
        // Normalize to grouped sections so the body has one render path (mirrors the Vue panel).
        let sections = self.sections ?? [FlareSettingsSection(items: entries ?? Self.entries(for: strings))]
        return VStack(spacing: 0) {
            ForEach(Array(sections.enumerated()), id: \.element.id) { i, section in
                // A titled group (常用功能 / 应用服务) names itself above its card, as in ``SettingsListView``.
                if let title = section.title, !title.isEmpty {
                    Text(title)
                        .font(.system(size: FlareSizes.fontSizeSm, weight: .medium))
                        .foregroundColor(colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, FlareSizes.spacingLg)
                        .padding(.top, FlareSizes.spacingMd)
                        .accessibilityAddTraits(.isHeader)
                }
                // Shared row → `kind` (toggle/value/navigation) and `detail` are honoured here too.
                VStack(spacing: 0) {
                    ForEach(Array(section.items.enumerated()), id: \.element.id) { j, e in
                        if j > 0 { Divider().overlay(colors.borderSecondary) }
                        FlareSettingsRow(item: e, onToggle: onToggle, onSelect: { onEntry?($0) })
                            .padding(.horizontal, FlareSizes.spacingLg)
                            .background(e.current ? colors.bgSelected : Color.clear)
                    }
                }
                .flareGroupedCard(colors, dark: dark)
                .padding(.horizontal, FlareSizes.spacingMd)
                .padding(.top, i == 0 ? FlareSizes.spacingMd : FlareSizes.spacingSm)
            }
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
        let signature = user.signature.flatMap { $0.isEmpty ? nil : $0 }
        let bio = signature ?? signaturePlaceholder
        let sidebar = layout == .sidebar
        let content = HStack(spacing: FlareSizes.spacingMd) {
            AvatarView(userId: user.id, displayName: user.name, avatarURL: user.avatarURL, size: Self.avatarSize)
            VStack(alignment: .leading, spacing: FlareSizes.spacing3xs) {
                Text(user.name)
                    .font(.system(size: sidebar ? FlareSizes.fontSizeLg : FlareSizes.fontSize3xl, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(2)
                if let f = user.flareId, !f.isEmpty {
                    Text("\(strings.contactDetailFlareId): \(f)")
                        .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
                        .lineLimit(1)
                }
                if let bio, !bio.isEmpty {
                    Text(bio).font(.system(size: sidebar ? FlareSizes.fontSizeSm : FlareSizes.fontSizeMd))
                        .foregroundColor(signature == nil ? colors.textTertiary : colors.textSecondary)
                        .lineLimit(sidebar ? 1 : 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if onQr != nil { Color.clear.frame(width: FlareSizes.touchTargetMin, height: 1) }
            if onEdit != nil {
                Image(systemName: "chevron.right").font(.system(size: FlareSizes.fontSizeLg, weight: .semibold))
                    .foregroundColor(colors.textTertiary)
                    .frame(width: FlareSizes.iconSizeSm)
                    .accessibilityHidden(true)
            }
        }
        .padding(FlareSizes.spacingMd)
        .frame(maxWidth: .infinity, minHeight: Self.identityMinHeight, alignment: .leading)
        .contentShape(Rectangle())
        if let onEdit {
            Button(action: onEdit) { content }
                .buttonStyle(.plain)
                .accessibilityLabel(identityActionLabel ?? strings.profilePanelEditProfile(user.name))
        } else {
            content.accessibilityElement(children: .combine)
        }
    }

    static let identityMinHeight: CGFloat = avatarSize + 2 * FlareSizes.spacingMd
    static let avatarSize: CGFloat = 48
}

/// How ``ProfilePanelView`` sits (Vue `layout`): `page` flows in the host's scroll view; `sidebar` fills the height
/// it is given, the identity card fixed and the groups scrolling under it.
public enum FlareProfilePanelLayout: Sendable { case page, sidebar }

/// The edit ``ProfileEditorView`` holds (Vue `FlareProfileDraft`), for a host that keeps it across pages.
public struct FlareProfileDraft: Equatable, Sendable {
    public var name: String
    public var signature: String
    public init(name: String, signature: String) { self.name = name; self.signature = signature }
}

/// Profile editor. Spec: Profile/ProfileEditor (`ProfileEditorView`).
///
/// An edit that differs from `user` says 「未保存修改」 beside the buttons, and only then can be saved. `draft` (Vue
/// `v-model:draft`) starts the fields from a kept edit and is written on every change, so a host can keep it while
/// the viewer moves around and drop it on cancel or a save that landed.
public struct ProfileEditorView: View {
    private let user: UserProfile
    private let labels: FlareProfileEditorLabels
    private let busy: Bool
    private let draft: Binding<FlareProfileDraft?>?
    private let onSave: ((String, String) -> Void)?
    private let onCancel: (() -> Void)?
    private let onPickAvatar: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @State private var name: String
    @State private var signature: String

    public init(user: UserProfile, labels: FlareProfileEditorLabels = FlareProfileEditorLabels(), busy: Bool = false,
                draft: Binding<FlareProfileDraft?>? = nil,
                onSave: ((String, String) -> Void)? = nil, onCancel: (() -> Void)? = nil, onPickAvatar: (() -> Void)? = nil) {
        self.user = user; self.labels = labels; self.busy = busy; self.draft = draft
        self.onSave = onSave; self.onCancel = onCancel; self.onPickAvatar = onPickAvatar
        let kept = draft?.wrappedValue
        _name = State(initialValue: kept?.name ?? user.name)
        _signature = State(initialValue: kept?.signature ?? user.signature ?? "")
    }

    private var copy: FlareProfileEditorLabels.Resolved { labels.resolve(strings) }

    /// The fields differ from the profile as saved (Vue `dirty`).
    static func isDirty(name: String, signature: String, user: UserProfile) -> Bool {
        name != user.name || signature != (user.signature ?? "")
    }

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
                if dirty {
                    Text(strings.profileEditorUnsaved).font(.system(size: FlareSizes.fontSizeSm))
                        .foregroundColor(colors.textSecondary).fixedSize()
                }
                ButtonView(label: copy.cancel, variant: .secondary, size: .lg,
                           disabled: busy || onCancel == nil, block: true, action: onCancel)
                ButtonView(label: copy.save, size: .lg, loading: busy,
                           disabled: name.trimmingCharacters(in: .whitespaces).isEmpty || !dirty || onSave == nil,
                           block: true) { onSave?(name, signature) }
            }
            .padding(.top, FlareSizes.spacingMd)
        }
        .padding(FlareSizes.spacingLg)
        .onChange(of: FlareProfileDraft(name: name, signature: signature)) { draft?.wrappedValue = $0 }
    }

    private var dirty: Bool { Self.isDirty(name: name, signature: signature, user: user) }
}

/// Grouped card: a section's rows together on one elevated surface (bgElevated, radiusLg, a borderSecondary
/// hairline, as Vue `.flare-settings__group`). Shared by ``SettingsListView`` and ``ProfilePanelView``.
struct FlareGroupedCard: ViewModifier {
    let colors: FlareColors
    let dark: Bool
    func body(content: Content) -> some View {
        // Vue `.flare-settings__group`: a quiet group with one shared hairline edge, no lift.
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusLg, style: .continuous)
        content
            .background(shape.fill(colors.bgElevated))
            .clipShape(shape)
            .overlay(shape.stroke(colors.borderSecondary, lineWidth: 1))
    }
}

extension View {
    func flareGroupedCard(_ colors: FlareColors, dark: Bool) -> some View {
        modifier(FlareGroupedCard(colors: colors, dark: dark))
    }

    /// R2.1 / §5.1: a plugin page's card (list card, overview card, wallet card) — `radius.card` on `bg.primary` with
    /// the shared hairline edge.
    func flarePluginCard(_ colors: FlareColors) -> some View {
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusCard, style: .continuous)
        return background(shape.fill(colors.bgPrimary))
            .clipShape(shape)
            .overlay(shape.stroke(colors.borderSecondary, lineWidth: 1).allowsHitTesting(false))
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
    private let scrollable: Bool
    private let flush: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    /// - Parameters:
    ///   - scrollable: false when the host already owns vertical scrolling: the list sizes to its content.
    ///   - flush: rows edge to edge on the primary surface, no card, inset or section gap (Vue `surface="flush"`),
    ///     for entries that are part of a list page, such as 通讯录's 群聊 / 新的好友 / 黑名单.
    public init(sections: [FlareSettingsSection], onToggle: ((FlareSettingsItem, Bool) -> Void)? = nil, onSelect: ((FlareSettingsItem) -> Void)? = nil,
                scrollable: Bool = true, flush: Bool = false) {
        self.sections = sections; self.onToggle = onToggle; self.onSelect = onSelect; self.scrollable = scrollable
        self.flush = flush
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        if scrollable {
            ScrollView { rows(colors) }
                .background(colors.bgSecondary)
        } else {
            rows(colors)
        }
    }

    private func rows(_ colors: FlareColors) -> some View {
        let dark = scheme == .dark
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(sections) { section in
                if let t = section.title, !t.isEmpty {
                    Text(t)
                        .font(.system(size: FlareSizes.fontSizeSm, weight: .medium))
                        .foregroundColor(colors.textSecondary)
                        .padding(.horizontal, FlareSizes.spacingLg)
                        .padding(.top, FlareSizes.spacingMd)
                        .padding(.bottom, FlareSizes.spacingSm)
                } else if !flush {
                    Spacer().frame(height: FlareSizes.spacingSm)
                }
                let group = VStack(spacing: 0) {
                    ForEach(Array(section.items.enumerated()), id: \.element.id) { i, item in
                        if i > 0 { Divider().overlay(colors.borderSecondary) }
                        FlareSettingsRow(item: item, onToggle: onToggle, onSelect: onSelect)
                            .padding(.horizontal, FlareSizes.spacingLg)
                            .background(item.current ? colors.bgSelected : Color.clear)
                    }
                }
                if flush {
                    group.background(colors.bgPrimary)
                } else {
                    group
                        .flareGroupedCard(colors, dark: dark)
                        .padding(.horizontal, FlareSizes.spacingMd)
                        .padding(.bottom, FlareSizes.spacingSm)
                }
                if let footer = section.footer, !footer.isEmpty {
                    FlareSettingsSectionFooter(text: footer, colors: colors)
                }
            }
        }
        .padding(.vertical, flush ? 0 : FlareSizes.spacingSm)
    }
}

/// The note under a section's card, in the section title's quiet colour.
struct FlareSettingsSectionFooter: View {
    let text: String
    let colors: FlareColors

    var body: some View {
        Text(text)
            .font(.system(size: FlareSizes.fontSizeSm))
            .foregroundColor(colors.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, FlareSizes.spacingLg)
            .padding(.bottom, FlareSizes.spacingSm)
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
    @Environment(\.flareStrings) private var strings

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

    /// Whether the row draws its red dot: every kind but a toggle, whose end is the switch.
    static func drawsBadge(_ item: FlareSettingsItem) -> Bool { item.badge && item.kind != .toggle }

    /// The row's tag, when it draws one: every kind but a toggle, and only non-blank words.
    static func tagText(_ item: FlareSettingsItem) -> String? {
        guard item.kind != .toggle, let tag = item.tag?.trimmingCharacters(in: .whitespacesAndNewlines), !tag.isEmpty
        else { return nil }
        return tag
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        Group {
            if item.kind == .toggle {
                Toggle(isOn: Binding(get: { item.value }, set: { onToggle?(item, $0) })) {
                    if let detail = item.detail, !detail.isEmpty {
                        // A switch's detail is its explanation, under the label (Vue settings row subtitle).
                        HStack(alignment: .top, spacing: FlareSizes.spacingMd) {
                            rowIcon(colors)
                            VStack(alignment: .leading, spacing: FlareSizes.spacing2xs) {
                                rowTitle(colors)
                                Text(detail).font(.system(size: FlareSizes.fontSizeSm))
                                    .foregroundColor(colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.vertical, FlareSizes.spacingSm)
                    } else {
                        rowLabel(colors)
                    }
                }
                .toggleStyle(FlareSwitchStyle(size: .sm, fillsRow: true))
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
        .frame(minHeight: FlareSizes.touchTarget)
        .opacity(item.disabled ? FlareOpacity.disabled : 1)
        .modifier(FlareSettingsRowBadgeValue(text: Self.drawsBadge(item) ? strings.settingsRowBadge : nil))
        .accessibilityAddTraits(item.current ? .isSelected : [])
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
                            tag()
                            dot(colors)
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
                    tag()
                    dot(colors)
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
        // A name outside the registry draws the plugin glyph; an empty one draws no icon.
        // One 20pt column in the row's colour (Vue `.flare-settings__ico`), so every label starts at the same x.
        if let icon = flareIconNameOrFallback(item.icon) {
            IconView(icon, size: FlareSizes.iconSizeMd, color: item.danger ? colors.errorText : colors.textPrimary)
                .frame(width: FlareSizes.iconSizeMd, height: FlareSizes.iconSizeMd)
        }
    }

    private func rowTitle(_ colors: FlareColors) -> some View {
        // The current row is marked by weight as well as colour (the ground is drawn by the list around the row).
        Text(item.label).font(.system(size: FlareSizes.fontSizeLg, weight: item.current ? .semibold : .regular))
            .foregroundColor(item.danger ? colors.errorText : item.current ? colors.primaryText : colors.textPrimary)
    }

    /// The warning tag, drawn like a plugin badge (the kit's tinted capsule).
    @ViewBuilder private func tag() -> some View {
        if let text = Self.tagText(item) {
            PluginBadgeView(badge: PluginBadge(text: text, tone: .warning))
                .fixedSize()
                .accessibilityIdentifier("settings.row.tag")
        }
    }

    @ViewBuilder private func dot(_ colors: FlareColors) -> some View {
        if Self.drawsBadge(item) {
            Circle().fill(colors.error)
                .frame(width: FlareSizes.spacingSm, height: FlareSizes.spacingSm)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder private func chevron(_ colors: FlareColors) -> some View {
        if item.kind == .navigation {
            // §12.3: every list row ends in chevron-right 16.
            FlareIconImage(name: "chevron-right", size: FlareSizes.iconSizeSm)
                .foregroundColor(colors.textTertiary)
                .accessibilityHidden(true)
        }
    }
}

/// Speaks a row's red dot as the row's value: a shape inside a button's label is not read reliably. A row without a
/// dot keeps its own value, so a toggle goes on reading on or off.
private struct FlareSettingsRowBadgeValue: ViewModifier {
    let text: String?

    func body(content: Content) -> some View {
        if let text {
            content.accessibilityValue(text)
        } else {
            content
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
