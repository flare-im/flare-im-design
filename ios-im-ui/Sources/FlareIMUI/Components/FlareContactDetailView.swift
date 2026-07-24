import SwiftUI

/// Localizable copy for ``FlareContactDetail``. Defaults are Chinese (Feishu-style).
public struct FlareContactDetailLabels: Sendable {
    public var info: String
    public var flareId: String
    public var remark: String
    public var description: String
    public var star: String
    public var notSet: String
    public var message: String
    public var voice: String
    public var video: String
    public var block: String
    public var remove: String

    public init(info: String = "资料", flareId: String = "Flare ID", remark: String = "备注",
                description: String = "描述", star: String = "星标好友", notSet: String = "未设置",
                message: String = "发消息", voice: String = "语音通话", video: String = "视频通话",
                block: String = "加入黑名单", remove: String = "删除好友") {
        self.info = info; self.flareId = flareId; self.remark = remark; self.description = description
        self.star = star; self.notSet = notSet; self.message = message; self.voice = voice
        self.video = video; self.block = block; self.remove = remove
    }
}

/// Contact profile — hero (avatar / name / presence / star chip), a 3-up action row
/// (message / voice / video), a 资料 settings card (Flare ID / remark / description / favorite
/// toggle), and a danger zone (block / remove).
///
/// Purely presentational: it renders the ``Contact`` plus `starred` / `description`, and emits
/// intents through its closures; the host owns the edit sheets and the SDK writes. Mirrors the
/// Vue kit's `FlareContactDetail`.
public struct FlareContactDetail: View {
    private let contact: Contact
    private let starred: Bool
    private let description: String
    private let labels: FlareContactDetailLabels
    private let onMessage: (() -> Void)?
    private let onCall: (() -> Void)?
    private let onVideo: (() -> Void)?
    private let onEditRemark: (() -> Void)?
    private let onEditDescription: (() -> Void)?
    private let onToggleStar: ((Bool) -> Void)?
    private let onBlock: (() -> Void)?
    private let onRemove: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(contact: Contact, starred: Bool = false, description: String = "",
                labels: FlareContactDetailLabels = FlareContactDetailLabels(),
                onMessage: (() -> Void)? = nil, onCall: (() -> Void)? = nil, onVideo: (() -> Void)? = nil,
                onEditRemark: (() -> Void)? = nil, onEditDescription: (() -> Void)? = nil,
                onToggleStar: ((Bool) -> Void)? = nil, onBlock: (() -> Void)? = nil, onRemove: (() -> Void)? = nil) {
        self.contact = contact; self.starred = starred; self.description = description; self.labels = labels
        self.onMessage = onMessage; self.onCall = onCall; self.onVideo = onVideo
        self.onEditRemark = onEditRemark; self.onEditDescription = onEditDescription
        self.onToggleStar = onToggleStar; self.onBlock = onBlock; self.onRemove = onRemove
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        ScrollView {
            VStack(spacing: FlareSizes.spacingLg) {
                hero(colors)
                actions(colors)
                infoCard(colors)
                danger(colors)
            }
            .padding(.vertical, FlareSizes.spacingLg)
        }
        .background(colors.bgSecondary.ignoresSafeArea())
    }

    private func hero(_ colors: FlareColors) -> some View {
        VStack(spacing: FlareSizes.spacingSm) {
            AvatarView(userId: contact.id, displayName: contact.name, avatarURL: contact.avatarURL,
                       size: 84, presence: contact.presence)
            Text(contact.name)
                .font(.system(size: FlareSizes.fontSize4xl, weight: .bold)).foregroundColor(colors.textPrimary)
            if let s = contact.signature, !s.isEmpty {
                Text(s).font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if starred {
                Text("★ \(labels.star)")
                    .font(.system(size: FlareSizes.fontSizeSm, weight: .semibold))
                    .foregroundColor(colors.primary)
                    .padding(.horizontal, 10).padding(.vertical, 2)
                    .background(Capsule().fill(colors.bgSelected))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func actions(_ colors: FlareColors) -> some View {
        HStack(spacing: FlareSizes.spacingMd) {
            actionButton(labels.message, "message", onMessage, colors, primary: true)
            actionButton(labels.voice, "phone", onCall, colors)
            actionButton(labels.video, "video", onVideo, colors)
        }
        .padding(.horizontal, FlareSizes.spacingLg)
    }

    private func actionButton(_ label: String, _ icon: String, _ action: (() -> Void)?, _ colors: FlareColors, primary: Bool = false) -> some View {
        Button { action?() } label: {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 20))
                Text(label).font(.system(size: FlareSizes.fontSizeSm, weight: .medium))
            }
            .foregroundColor(primary ? .white : colors.textSecondary)
            .frame(maxWidth: .infinity).padding(.vertical, FlareSizes.spacingMd)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl)
                .fill(primary ? colors.primary : colors.bgElevated))
        }
        .buttonStyle(.plain)
    }

    private func infoCard(_ colors: FlareColors) -> some View {
        let items: [FlareSettingsItem] = [
            FlareSettingsItem(key: "flareId", label: labels.flareId, systemImage: "number",
                              kind: .value, detail: contact.id),
            FlareSettingsItem(key: "remark", label: labels.remark, systemImage: "pencil",
                              kind: .navigation, detail: contact.remark?.isEmpty == false ? contact.remark! : labels.notSet),
            FlareSettingsItem(key: "description", label: labels.description, systemImage: "text.alignleft",
                              kind: .navigation, detail: description.isEmpty ? labels.notSet : description),
            FlareSettingsItem(key: "star", label: labels.star, systemImage: "star",
                              kind: .toggle, value: starred),
        ]
        return VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            Text(labels.info).font(.system(size: FlareSizes.fontSizeSm, weight: .semibold))
                .foregroundColor(colors.textTertiary).padding(.horizontal, FlareSizes.spacingLg)
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                    if i > 0 { Divider().padding(.leading, FlareSizes.spacingMd) }
                    FlareSettingsRow(item: item, onToggle: { it, on in if it.key == "star" { onToggleStar?(on) } },
                                     onSelect: { it in
                        if it.key == "remark" { onEditRemark?() } else if it.key == "description" { onEditDescription?() }
                    })
                    .padding(.horizontal, FlareSizes.spacingMd)
                    .frame(minHeight: 48)
                }
            }
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgElevated))
            .padding(.horizontal, FlareSizes.spacingMd)
        }
    }

    private func danger(_ colors: FlareColors) -> some View {
        VStack(spacing: FlareSizes.spacingSm) {
            ButtonView(label: labels.block, variant: .secondary, block: true) { onBlock?() }
            ButtonView(label: labels.remove, variant: .danger, block: true) { onRemove?() }
        }
        .padding(.horizontal, FlareSizes.spacingLg)
        .padding(.top, FlareSizes.spacingSm)
    }
}
