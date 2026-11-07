import SwiftUI

/// The version block of an About page, in the settings list's rows: the version, the build, the channel and the row
/// that checks for an update. Spec: Profile/VersionPanel (`VersionPanelView`).
///
/// What that row says and does is ``flareVersionPanel(_:)``'s call (`spec/update-prompt-vectors.json`, the same in every
/// kit). The view holds no SDK: it reports intent, and the row is disabled while work is under way or while the host
/// passes no handler for what it would do. It sizes to its content, so it goes inside the host's scrolling page.
public struct VersionPanelView: View {
    private static let rowKey = "update"
    private let version: String
    private let build: Int64?
    private let channel: String?
    private let updateState: String?
    private let onCheck: (() -> Void)?
    private let onUpdate: (() -> Void)?
    @Environment(\.flareStrings) private var strings

    /// - Parameters:
    ///   - version: `UpdateStatus.current.version`.
    ///   - build: `UpdateStatus.current.build`.
    ///   - channel: `UpdateStatus.current.channel`.
    ///   - updateState: `UpdateStatus.state`.
    ///   - onCheck: check for an update (`update.check` with `manual`).
    ///   - onUpdate: start or finish the update.
    public init(version: String, build: Int64? = nil, channel: String? = nil, updateState: String? = nil,
                onCheck: (() -> Void)? = nil, onUpdate: (() -> Void)? = nil) {
        self.version = version; self.build = build; self.channel = channel; self.updateState = updateState
        self.onCheck = onCheck; self.onUpdate = onUpdate
    }

    private var model: FlareVersionPanelModel { flareVersionPanel(updateState) }

    private var handler: (() -> Void)? {
        switch model.action {
        case .check: return onCheck
        case .update: return onUpdate
        case nil: return nil
        }
    }

    private var items: [FlareSettingsItem] {
        var items = [FlareSettingsItem(key: "version", label: strings.versionPanelVersion, kind: .value, detail: version)]
        if let build {
            items.append(FlareSettingsItem(key: "build", label: strings.versionPanelBuild, kind: .value, detail: String(build)))
        }
        if let channel, !channel.isEmpty {
            items.append(FlareSettingsItem(key: "channel", label: strings.versionPanelChannel, kind: .value,
                                           detail: flareVersionChannelLabel(channel, strings: strings)))
        }
        items.append(FlareSettingsItem(key: Self.rowKey, label: model.row.label(strings), kind: .action,
                                       detail: model.detail?.label(strings), disabled: handler == nil))
        return items
    }

    public var body: some View {
        SettingsListView(sections: [FlareSettingsSection(title: strings.versionPanelTitle, items: items)],
                         onSelect: { item in if item.key == Self.rowKey { handler?() } },
                         scrollable: false)
            .onChange(of: model.detail?.label(strings)) { detail in
                if let detail { flareAnnounce(detail) }
            }
    }
}
