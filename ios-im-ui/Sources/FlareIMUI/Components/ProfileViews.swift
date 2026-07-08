import SwiftUI

/// Personal center. Spec: Profile/ProfilePanel (`ProfilePanelView`).
public struct ProfilePanelView: View {
    private let user: UserProfile
    private let entries: [FlareSettingsItem]
    private let onEdit: (() -> Void)?
    private let onEntry: ((FlareSettingsItem) -> Void)?
    @Environment(\.colorScheme) private var scheme

    public static let defaultEntries: [FlareSettingsItem] = [
        FlareSettingsItem(key: "favorites", label: "Favorites", systemImage: "star"),
        FlareSettingsItem(key: "moments", label: "Moments", systemImage: "photo.on.rectangle"),
        FlareSettingsItem(key: "settings", label: "Settings", systemImage: "gearshape"),
    ]

    public init(user: UserProfile, entries: [FlareSettingsItem] = ProfilePanelView.defaultEntries,
                onEdit: (() -> Void)? = nil, onEntry: ((FlareSettingsItem) -> Void)? = nil) {
        self.user = user; self.entries = entries; self.onEdit = onEdit; self.onEntry = onEntry
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(spacing: 0) {
            Button { onEdit?() } label: {
                HStack(spacing: FlareSizes.spacingMd) {
                    AvatarView(userId: user.id, displayName: user.name, avatarURL: user.avatarURL, size: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name).font(.system(size: FlareSizes.fontSize3xl, weight: .semibold)).foregroundColor(colors.textPrimary)
                        if let f = user.flareId, !f.isEmpty {
                            Text("Flare ID: \(f)").font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                        }
                    }
                    Spacer()
                    Image(systemName: "qrcode").foregroundColor(colors.textTertiary)
                }
                .padding(FlareSizes.spacingLg)
                .background(colors.bgSelected)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { i, e in
                    if i > 0 { Divider() }
                    Button { onEntry?(e) } label: {
                        HStack(spacing: FlareSizes.spacingMd) {
                            if let ic = e.systemImage { Image(systemName: ic).foregroundColor(colors.textSecondary) }
                            Text(e.label).foregroundColor(colors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(colors.textTertiary)
                        }
                        .padding(FlareSizes.spacingMd)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, FlareSizes.spacingSm)
            Spacer()
        }
    }
}

/// Profile editor. Spec: Profile/ProfileEditor (`ProfileEditorView`).
public struct ProfileEditorView: View {
    private let user: UserProfile
    private let busy: Bool
    private let onSave: ((String, String) -> Void)?
    private let onCancel: (() -> Void)?
    private let onPickAvatar: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var name: String
    @State private var signature: String

    public init(user: UserProfile, busy: Bool = false,
                onSave: ((String, String) -> Void)? = nil, onCancel: (() -> Void)? = nil, onPickAvatar: (() -> Void)? = nil) {
        self.user = user; self.busy = busy; self.onSave = onSave; self.onCancel = onCancel; self.onPickAvatar = onPickAvatar
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

            Text("Nickname").font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.textSecondary)
            InputView(text: $name, placeholder: "Nickname", maxLength: 24, clearable: true)
            Text("Bio").font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.textSecondary)
            InputView(text: $signature, placeholder: "Tell us about yourself", multiline: true, maxLength: 60)

            HStack(spacing: FlareSizes.spacingMd) {
                Button("Cancel") { onCancel?() }.buttonStyle(.bordered).frame(maxWidth: .infinity)
                Button { onSave?(name, signature) } label: {
                    if busy { ProgressView().controlSize(.small) } else { Text("Save").frame(maxWidth: .infinity) }
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
                        HStack {
                            if let ic = item.systemImage { Image(systemName: ic).foregroundColor(colors.textSecondary) }
                            Text(item.label).foregroundColor(colors.textPrimary)
                            Spacer()
                            switch item.kind {
                            case .toggle:
                                Toggle("", isOn: Binding(get: { item.value }, set: { onToggle?(item, $0) })).labelsHidden().tint(colors.primary)
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
                } header: {
                    if let t = section.title { Text(t) }
                }
            }
        }
    }
}
