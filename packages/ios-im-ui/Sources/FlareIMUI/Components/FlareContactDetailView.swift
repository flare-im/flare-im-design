import SwiftUI

/// Localizable copy for ``FlareContactDetail``. Defaults are Chinese (Feishu-style).
public struct FlareContactDetailLabels: Sendable {
    public var info: String?
    public var flareId: String?
    public var remark: String?
    public var description: String?
    public var star: String?
    public var notSet: String?
    public var message: String?
    public var voice: String?
    public var video: String?
    public var block: String?
    public var remove: String?

    public init(info: String? = nil, flareId: String? = nil, remark: String? = nil,
                description: String? = nil, star: String? = nil, notSet: String? = nil,
                message: String? = nil, voice: String? = nil, video: String? = nil,
                block: String? = nil, remove: String? = nil) {
        self.info = info; self.flareId = flareId; self.remark = remark; self.description = description
        self.star = star; self.notSet = notSet; self.message = message; self.voice = voice
        self.video = video; self.block = block; self.remove = remove
    }
}

public extension FlareContactDetailLabels {
    /// Every label filled in: an explicit label wins, otherwise the `flareStrings` provider.
    struct Resolved: Sendable {
        public let info: String
        public let flareId: String
        public let remark: String
        public let description: String
        public let star: String
        public let notSet: String
        public let message: String
        public let voice: String
        public let video: String
        public let block: String
        public let remove: String
    }
    func resolve(_ strings: FlareStrings) -> Resolved {
        Resolved(
            info: info ?? strings.contactDetailInfo,
            flareId: flareId ?? strings.contactDetailFlareId,
            remark: remark ?? strings.contactDetailRemark,
            description: description ?? strings.contactDetailDescription,
            star: star ?? strings.contactDetailStar,
            notSet: notSet ?? strings.contactDetailNotSet,
            message: message ?? strings.sendMessage,
            voice: voice ?? strings.contactDetailVoice,
            video: video ?? strings.contactDetailVideo,
            block: block ?? strings.contactDetailBlock,
            remove: remove ?? strings.contactDetailRemove
        )
    }
}

/// Contact profile — hero (avatar / name / presence / star chip), an action row
/// (message / voice / video), a 资料 settings card (Flare ID / remark / description / favorite
/// toggle), and a danger zone (block / remove).
///
/// Purely presentational: it renders the ``Contact`` plus `starred` / `description`, and emits
/// intents through its closures; the host owns the edit sheets and persistence. Mirrors the
/// Vue kit's `FlareContactDetail`.
///
/// An intent appears only when the host handles it (X23, FR-089): a host without calls gets no voice
/// or video button, and no action row without any handler; remark and description are editable rows
/// only with their edit handlers, and otherwise read-only values shown only when set; the favorite
/// toggle needs `onToggleStar`; block and remove need their handlers, and without either there is no
/// danger zone. A stranger's profile — no friend-only handlers — shows none of those.
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
    /// Host actions the kit cannot know about, drawn with the kit's own footer buttons (FR-046).
    private let extraActions: [FlareDetailExtraAction]
    private let onExtraAction: ((String) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(contact: Contact, starred: Bool = false, description: String = "",
                labels: FlareContactDetailLabels = FlareContactDetailLabels(),
                onMessage: (() -> Void)? = nil, onCall: (() -> Void)? = nil, onVideo: (() -> Void)? = nil,
                onEditRemark: (() -> Void)? = nil, onEditDescription: (() -> Void)? = nil,
                onToggleStar: ((Bool) -> Void)? = nil, onBlock: (() -> Void)? = nil, onRemove: (() -> Void)? = nil,
                extraActions: [FlareDetailExtraAction] = [], onExtraAction: ((String) -> Void)? = nil) {
        self.contact = contact; self.starred = starred; self.description = description; self.labels = labels
        self.onMessage = onMessage; self.onCall = onCall; self.onVideo = onVideo
        self.onEditRemark = onEditRemark; self.onEditDescription = onEditDescription
        self.onToggleStar = onToggleStar; self.onBlock = onBlock; self.onRemove = onRemove
        self.extraActions = extraActions; self.onExtraAction = onExtraAction
    }

    private var copy: FlareContactDetailLabels.Resolved { labels.resolve(strings) }

    /// An action the row offers: message, voice or video.
    enum Intent: String, CaseIterable {
        case message, call, video
    }

    /// The actions the row draws, in order: only those with a handler.
    static func intents(message: Bool, call: Bool, video: Bool) -> [Intent] {
        Intent.allCases.filter { intent in
            switch intent {
            case .message: return message
            case .call: return call
            case .video: return video
            }
        }
    }

    /// The 资料 card's rows: the public Flare ID only when the contact has one (the account id is internal and
    /// never shown); remark and description as editable rows with their edit handlers, else as read-only
    /// values only when set; the favorite toggle only with its handler.
    static func infoItems(contact: Contact, description: String, starred: Bool, copy: FlareContactDetailLabels.Resolved,
                          editsRemark: Bool, editsDescription: Bool, togglesStar: Bool) -> [FlareSettingsItem] {
        var items: [FlareSettingsItem] = []
        if let flareId = contact.flareId, !flareId.isEmpty {
            items.append(FlareSettingsItem(key: "flareId", label: copy.flareId, icon: "id", kind: .value, detail: flareId))
        }
        let remark = contact.remark ?? ""
        if editsRemark || !remark.isEmpty {
            items.append(FlareSettingsItem(key: "remark", label: copy.remark, icon: "edit",
                                           kind: editsRemark ? .navigation : .value,
                                           detail: remark.isEmpty ? copy.notSet : remark))
        }
        if editsDescription || !description.isEmpty {
            items.append(FlareSettingsItem(key: "description", label: copy.description, icon: "comment",
                                           kind: editsDescription ? .navigation : .value,
                                           detail: description.isEmpty ? copy.notSet : description))
        }
        if togglesStar {
            items.append(FlareSettingsItem(key: "star", label: copy.star, icon: "star", kind: .toggle, value: starred))
        }
        return items
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let intents = Self.intents(message: onMessage != nil, call: onCall != nil, video: onVideo != nil)
        ScrollView {
            VStack(spacing: FlareSizes.spacingLg) {
                hero(colors)
                if !intents.isEmpty { actions(intents, colors) }
                infoCard(colors, items: Self.infoItems(contact: contact, description: description, starred: starred, copy: copy,
                                                       editsRemark: onEditRemark != nil,
                                                       editsDescription: onEditDescription != nil,
                                                       togglesStar: onToggleStar != nil))
                if onBlock != nil || onRemove != nil || !extraActions.isEmpty { danger(colors) }
            }
            .padding(.vertical, FlareSizes.spacingLg)
        }
        .background(colors.bgSecondary.ignoresSafeArea())
    }

    private func hero(_ colors: FlareColors) -> some View {
        VStack(spacing: FlareSizes.spacingSm) {
            AvatarView(userId: contact.id, displayName: contact.name, avatarURL: contact.avatarURL,
                       size: 76, presence: contact.presence)
            Text(contact.name)
                .font(.system(size: FlareSizes.fontSize4xl, weight: .bold)).foregroundColor(colors.textPrimary)
            if let s = contact.signature, !s.isEmpty {
                Text(s).font(.system(size: FlareSizes.fontSizeMd)).foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if starred {
                // The star is the kit icon, not a text character; the badge reads as its label.
                HStack(spacing: FlareSizes.spacingXs) {
                    Image(systemName: flareIconSymbol("star"))
                        .font(.system(size: FlareSizes.fontSizeSm, weight: .semibold))
                        .accessibilityHidden(true)
                    Text(copy.star)
                        .font(.system(size: FlareSizes.fontSizeSm, weight: .semibold))
                }
                .foregroundColor(colors.primaryText)
                .padding(.horizontal, FlareSizes.spacing2sm).padding(.vertical, 2)
                .background(Capsule().fill(colors.bgSelected))
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func actions(_ intents: [Intent], _ colors: FlareColors) -> some View {
        HStack(spacing: FlareSizes.spacingMd) {
            ForEach(intents, id: \.self) { intent in
                switch intent {
                case .message: actionButton(copy.message, "message", onMessage, colors, primary: true)
                case .call: actionButton(copy.voice, "phone", onCall, colors)
                case .video: actionButton(copy.video, "video", onVideo, colors)
                }
            }
        }
        .padding(.horizontal, FlareSizes.spacingLg)
    }

    private func actionButton(_ label: String, _ icon: String, _ action: (() -> Void)?, _ colors: FlareColors, primary: Bool = false) -> some View {
        Button { action?() } label: {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: FlareSizes.iconSizeMd))
                Text(label).font(.system(size: FlareSizes.fontSizeSm, weight: .medium))
            }
            .foregroundColor(primary ? .white : colors.textSecondary)
            .frame(maxWidth: .infinity, minHeight: FlareSizes.touchTargetMin).padding(.vertical, FlareSizes.spacingMd)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl)
                .fill(primary ? colors.primary : colors.bgElevated))
        }
        .buttonStyle(.plain)
    }

    /// The 资料 card; nothing at all when it has no rows.
    @ViewBuilder
    private func infoCard(_ colors: FlareColors, items: [FlareSettingsItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
                Text(copy.info).font(.system(size: FlareSizes.fontSizeSm, weight: .semibold))
                    .foregroundColor(colors.textTertiary).padding(.horizontal, FlareSizes.spacingLg)
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                        if i > 0 { Divider().padding(.leading, FlareSizes.spacingMd) }
                        // A value row is not a control: it gets no select handler.
                        FlareSettingsRow(item: item, onToggle: { it, on in if it.key == "star" { onToggleStar?(on) } },
                                         onSelect: item.kind == .navigation ? { it in
                            if it.key == "remark" { onEditRemark?() } else if it.key == "description" { onEditDescription?() }
                        } : nil)
                        .padding(.horizontal, FlareSizes.spacingMd)
                        .frame(minHeight: 48)
                    }
                }
                .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgElevated))
                .padding(.horizontal, FlareSizes.spacingMd)
            }
        }
    }

    private func danger(_ colors: FlareColors) -> some View {
        VStack(spacing: FlareSizes.spacingSm) {
            ForEach(extraActions) { action in
                ButtonView(label: action.label, variant: action.danger ? .danger : .secondary, block: true) {
                    onExtraAction?(action.id)
                }
            }
            if let onBlock { ButtonView(label: copy.block, variant: .secondary, block: true, action: onBlock) }
            if let onRemove { ButtonView(label: copy.remove, variant: .danger, block: true, action: onRemove) }
        }
        .padding(.horizontal, FlareSizes.spacingLg)
        .padding(.top, FlareSizes.spacingSm)
    }
}
