import SwiftUI

/// Personal center. Spec: Profile/ProfilePanel (`ProfilePanelView`).
///
/// The header is a single tappable-to-edit target (trailing chevron signals it), with the QR
/// badge carved out as its own tap target (`onQr`). Rows render as one or more grouped section
/// cards (iOS style): pass `sections` for grouping, or `entries` for a single flat card.
public struct ProfilePanelView: View {
    private let user: UserProfile
    private let sections: [FlareSettingsSection]
    private let signaturePlaceholder: String?
    private let onEdit: (() -> Void)?
    private let onQr: (() -> Void)?
    private let onEntry: ((FlareSettingsItem) -> Void)?
    private let onToggle: ((FlareSettingsItem, Bool) -> Void)?
    @Environment(\.colorScheme) private var scheme

    public static let defaultEntries: [FlareSettingsItem] = [
        FlareSettingsItem(key: "favorites", label: "Favorites", systemImage: "star"),
        FlareSettingsItem(key: "moments", label: "Moments", systemImage: "photo.on.rectangle"),
        FlareSettingsItem(key: "settings", label: "Settings", systemImage: "gearshape"),
    ]

    public init(user: UserProfile,
                entries: [FlareSettingsItem] = ProfilePanelView.defaultEntries,
                sections: [FlareSettingsSection]? = nil,
                signaturePlaceholder: String? = nil,
                onEdit: (() -> Void)? = nil, onQr: (() -> Void)? = nil,
                onEntry: ((FlareSettingsItem) -> Void)? = nil,
                onToggle: ((FlareSettingsItem, Bool) -> Void)? = nil) {
        self.user = user
        // Normalize to grouped sections so the body has one render path (mirrors the Vue panel).
        self.sections = sections ?? [FlareSettingsSection(items: entries)]
        self.signaturePlaceholder = signaturePlaceholder
        self.onEdit = onEdit; self.onQr = onQr; self.onEntry = onEntry; self.onToggle = onToggle
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(spacing: 0) {
            header

            ForEach(Array(sections.enumerated()), id: \.element.id) { i, section in
                // Shared row → `kind` (toggle/value/navigation) and `detail` are honoured here too.
                VStack(spacing: 0) {
                    ForEach(Array(section.items.enumerated()), id: \.element.id) { j, e in
                        if j > 0 { Divider() }
                        FlareSettingsRow(item: e, onToggle: onToggle, onSelect: { onEntry?($0) })
                            .padding(FlareSizes.spacingMd)
                    }
                }
                .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgElevated))
                .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusXl))
                .padding(.horizontal, FlareSizes.spacingMd)
                .padding(.top, i == 0 ? FlareSizes.spacingMd : FlareSizes.spacingSm)
            }
            Spacer()
        }
    }

    private var header: some View {
        // The whole row is tap-to-edit; the QR badge is carved out as its own tap target.
        Button { onEdit?() } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                AvatarView(userId: user.id, displayName: user.name, avatarURL: user.avatarURL, size: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name).font(.system(size: FlareSizes.fontSize3xl, weight: .bold)).foregroundColor(.white)
                    if let s = user.signature, !s.isEmpty {
                        Text(s).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(.white.opacity(0.82))
                            .lineLimit(1)
                    } else if let placeholder = signaturePlaceholder, !placeholder.isEmpty {
                        // Placeholder when the user hasn't set a signature yet.
                        Text(placeholder).font(.system(size: FlareSizes.fontSizeSm)).italic()
                            .foregroundColor(.white.opacity(0.62)).lineLimit(1)
                    }
                    if let f = user.flareId, !f.isEmpty {
                        Text("Flare ID: \(f)").font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(.white.opacity(0.62))
                    }
                }
                Spacer()
                // Its own tap target — distinct from the header's edit tap.
                Button { onQr?() } label: {
                    Image(systemName: "qrcode").font(.system(size: 20)).foregroundColor(.white.opacity(0.92))
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.14)))
                }
                .buttonStyle(.plain)
                // Trailing chevron — signals the header itself is tappable-to-edit.
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(FlareSizes.spacingLg)
            // Aurora glow header — a violet light source, white text over it.
            .background(
                LinearGradient(
                    colors: [
                        Color(.sRGB, red: 0x3B / 255, green: 0x1F / 255, blue: 0x7A / 255, opacity: 1),
                        Color(.sRGB, red: 0x7C / 255, green: 0x3A / 255, blue: 0xED / 255, opacity: 1),
                        Color(.sRGB, red: 0x8B / 255, green: 0x5C / 255, blue: 0xF6 / 255, opacity: 1),
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
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
    @State private var name: String
    @State private var signature: String

    public init(user: UserProfile, labels: FlareProfileEditorLabels = FlareProfileEditorLabels(), busy: Bool = false,
                onSave: ((String, String) -> Void)? = nil, onCancel: (() -> Void)? = nil, onPickAvatar: (() -> Void)? = nil) {
        self.user = user; self.labels = labels; self.busy = busy; self.onSave = onSave; self.onCancel = onCancel; self.onPickAvatar = onPickAvatar
        _name = State(initialValue: user.name)
        _signature = State(initialValue: user.signature ?? "")
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            Button { onPickAvatar?() } label: {
                AvatarView(userId: user.id, displayName: name.isEmpty ? user.name : name, avatarURL: user.avatarURL, size: 80)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "camera").font(.system(size: 12)).foregroundColor(.white)
                            .padding(6).background(Circle().fill(colors.primary))
                    }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)

            Text(labels.nickname).font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.textSecondary)
            InputView(text: $name, placeholder: labels.nicknamePlaceholder, maxLength: 24, clearable: true)
            Text(labels.bio).font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.textSecondary)
            InputView(text: $signature, placeholder: labels.bioPlaceholder, multiline: true, maxLength: 60)

            HStack(spacing: FlareSizes.spacingMd) {
                Button(labels.cancel) { onCancel?() }.buttonStyle(.bordered).frame(maxWidth: .infinity)
                Button { onSave?(name, signature) } label: {
                    if busy { ProgressView().controlSize(.small) } else { Text(labels.save).frame(maxWidth: .infinity) }
                }
                .buttonStyle(.borderedProminent).tint(colors.primary).frame(maxWidth: .infinity)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || busy)
            }
            .padding(.top, FlareSizes.spacingMd)
        }
        .padding(FlareSizes.spacingLg)
    }
}

/// Settings list. Spec: Profile/SettingsList (`SettingsListView`).
public struct SettingsListView: View {
    private let sections: [FlareSettingsSection]
    private let onToggle: ((FlareSettingsItem, Bool) -> Void)?
    private let onSelect: ((FlareSettingsItem) -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(sections: [FlareSettingsSection], onToggle: ((FlareSettingsItem, Bool) -> Void)? = nil, onSelect: ((FlareSettingsItem) -> Void)? = nil) {
        self.sections = sections; self.onToggle = onToggle; self.onSelect = onSelect
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        List {
            ForEach(sections) { section in
                Section {
                    ForEach(section.items) { item in
                        FlareSettingsRow(item: item, onToggle: onToggle, onSelect: onSelect)
                    }
                } header: {
                    if let t = section.title { Text(t) }
                }
            }
        }
        .background(colors.bgSecondary)
    }
}

/// One settings/profile entry row — icon, label, then the trailing affordance for its
/// `FlareSettingKind`: a switch (toggle), a value (value), or detail + chevron (navigation).
///
/// Shared by ``SettingsListView`` and ``ProfilePanelView`` so the two can't drift — previously
/// `ProfilePanelView` re-implemented this row and silently dropped `kind` and `detail`, rendering
/// every entry as a bare label + chevron.
public struct FlareSettingsRow: View {
    private let item: FlareSettingsItem
    private let onToggle: ((FlareSettingsItem, Bool) -> Void)?
    private let onSelect: ((FlareSettingsItem) -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(item: FlareSettingsItem,
                onToggle: ((FlareSettingsItem, Bool) -> Void)? = nil,
                onSelect: ((FlareSettingsItem) -> Void)? = nil) {
        self.item = item; self.onToggle = onToggle; self.onSelect = onSelect
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: FlareSizes.spacingMd) {
            if let ic = item.systemImage { Image(systemName: ic).foregroundColor(colors.textSecondary) }
            Text(item.label).foregroundColor(colors.textPrimary)
            Spacer()
            switch item.kind {
            case .toggle:
                Toggle("", isOn: Binding(get: { item.value }, set: { onToggle?(item, $0) }))
                    .labelsHidden().tint(colors.primary)
            case .value:
                Text(item.detail ?? "").foregroundColor(colors.textTertiary)
            case .navigation:
                if let d = item.detail { Text(d).foregroundColor(colors.textTertiary) }
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(colors.textTertiary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { if item.kind != .toggle { onSelect?(item) } }
    }
}

/// Localizable labels for ``ProfileEditorView``. Defaults keep today's English copy.
public struct FlareProfileEditorLabels: Sendable {
    public var nickname: String
    public var nicknamePlaceholder: String
    public var bio: String
    public var bioPlaceholder: String
    public var cancel: String
    public var save: String

    public init(
        nickname: String = "Nickname",
        nicknamePlaceholder: String = "Nickname",
        bio: String = "Bio",
        bioPlaceholder: String = "Tell us about yourself",
        cancel: String = "Cancel",
        save: String = "Save"
    ) {
        self.nickname = nickname
        self.nicknamePlaceholder = nicknamePlaceholder
        self.bio = bio
        self.bioPlaceholder = bioPlaceholder
        self.cancel = cancel
        self.save = save
    }
}
