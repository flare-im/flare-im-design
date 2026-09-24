import SwiftUI

// MARK: - TopicChip

/// A tappable topic tag rendered as "#topic" in the brand colour.
/// Spec: Moments/TopicChip (`TopicChipView`).
public struct TopicChipView: View {
    private let topic: String
    private let onTap: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(topic: String, onTap: (() -> Void)? = nil) {
        self.topic = topic; self.onTap = onTap
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        // Inherits the surrounding text size (no hard-coded 14) — Android / Flutter parity.
        Button { onTap?() } label: {
            Text("#\(topic)")
                .fontWeight(.medium)
                .foregroundColor(colors.primaryText)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - CommentThread

/// A vertical list of moment comments — each an inline "name[ replying to name]：text".
/// Spec: Moments/CommentThread (`CommentThreadView`).
///
/// A comment is a control only when the host handles it (G18): with `onSelect` each row is one button named
/// "回复 {name}：{text}". The author's name opens the author only with `onSelectAuthor`: inside a selectable
/// row it is a pointer shortcut (VoiceOver reaches the row, which names the author), in a plain row it is
/// the control. Names read in the accessible primary text colour.
public struct CommentThreadView: View {
    private let comments: [MomentComment]
    private let onSelect: ((MomentComment) -> Void)?
    private let onSelectAuthor: ((String) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(comments: [MomentComment],
                onSelect: ((MomentComment) -> Void)? = nil,
                onSelectAuthor: ((String) -> Void)? = nil) {
        self.comments = comments; self.onSelect = onSelect; self.onSelectAuthor = onSelectAuthor
    }

    /// The vertical room around each comment line.
    static let rowInset: CGFloat = 3
    private static let nameFont = Font.system(size: FlareSizes.fontSizeMd, weight: .medium)
    private static let bodyFont = Font.system(size: FlareSizes.fontSizeMd)

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(comments) { comment in
                row(colors, comment)
            }
        }
    }

    @ViewBuilder
    private func row(_ colors: FlareColors, _ comment: MomentComment) -> some View {
        let line = Self.line(colors, comment, strings: strings)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Self.rowInset)
            .contentShape(Rectangle())
        if let onSelect {
            Button { onSelect(comment) } label: { line }
                .buttonStyle(.plain)
                .accessibilityLabel(strings.momentReplyToComment(comment.author.name, comment.text))
                .overlay(alignment: .topLeading) { authorShortcut(comment, inControl: true) }
        } else {
            line.overlay(alignment: .topLeading) { authorShortcut(comment, inControl: false) }
        }
    }

    /// The author's name as its own hit area, laid exactly over the name that starts the line: an
    /// invisible copy of the name in the same font, so the line keeps drawing it.
    @ViewBuilder
    private func authorShortcut(_ comment: MomentComment, inControl: Bool) -> some View {
        if let onSelectAuthor {
            Button { onSelectAuthor(comment.author.id) } label: {
                Text(comment.author.name).font(Self.nameFont).foregroundColor(.clear)
                    .padding(.top, Self.rowInset)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(comment.author.name)
            .accessibilityHidden(inControl)
        }
    }

    static func line(_ colors: FlareColors, _ comment: MomentComment, strings: FlareStrings) -> Text {
        var text = Text(comment.author.name).font(nameFont).foregroundColor(colors.primaryText)
        if let replyTo = comment.replyToName {
            text = text
                + Text(" \(strings.momentReplyTo) ").font(bodyFont).foregroundColor(colors.textTertiary)
                + Text(replyTo).font(nameFont).foregroundColor(colors.primaryText)
        }
        return text
            + Text("：").font(bodyFont).foregroundColor(colors.textTertiary)
            + Text(comment.text).font(bodyFont).foregroundColor(colors.textPrimary)
    }
}

// MARK: - MomentActionPopover

/// Dark like / comment popover shown next to a moment's "…" button. When `canDelete`
/// is set (the moment is the current user's) a destructive Delete action is appended;
/// when `canReport` is set (someone else's moment) a Report action is appended instead.
///
/// The two are the same shape on purpose: 删除 and 举报 are both "act on this one post",
/// they are mutually exclusive (you cannot report your own post, and you do not delete
/// someone else's), and they are both low-frequency. Hosts used to have nowhere to put
/// 举报 and hung a text button in a strip *below* the card — a per-post action rendered
/// outside the post, which also broke the feed's vertical rhythm because only some cards
/// had one. It belongs in the same popover as the rest of the post's actions.
/// Spec: Moments/MomentActionPopover (`MomentActionPopoverView`).
public struct MomentActionPopoverView: View {
    private let liked: Bool
    private let canDelete: Bool
    private let canReport: Bool
    private let onLike: (() -> Void)?
    private let onComment: (() -> Void)?
    private let onDelete: (() -> Void)?
    private let onReport: (() -> Void)?
    @Environment(\.flareStrings) private var strings
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    private var colors: FlareColors { FlareColors.of(scheme, brand: flareBrandTheme) }

    public init(liked: Bool = false, canDelete: Bool = false, canReport: Bool = false,
                onLike: (() -> Void)? = nil, onComment: (() -> Void)? = nil,
                onDelete: (() -> Void)? = nil, onReport: (() -> Void)? = nil) {
        self.liked = liked; self.canDelete = canDelete; self.canReport = canReport
        self.onLike = onLike; self.onComment = onComment; self.onDelete = onDelete
        self.onReport = onReport
    }

    public var body: some View {
        HStack(spacing: 0) {
            Button { onLike?() } label: {
                item(icon: liked ? "heart.slash" : "heart", label: liked ? strings.unlike : strings.like)
            }.buttonStyle(.plain)

            divider

            Button { onComment?() } label: {
                item(icon: "bubble.left", label: strings.comment)
            }.buttonStyle(.plain)

            if canDelete {
                divider
                Button { onDelete?() } label: {
                    item(icon: "trash", label: strings.delete, tint: colors.error)
                }.buttonStyle(.plain)
            } else if canReport {
                // 举报 is not destructive to my own data, so it keeps the normal tint —
                // the danger colour is reserved for "this deletes something of yours".
                divider
                Button { onReport?() } label: {
                    item(icon: flareIconSymbol("report"), label: strings.report)
                }.buttonStyle(.plain)
            }
        }
        .frame(height: 34)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colors.bgPrimary)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(colors.borderSecondary, lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }

    private var divider: some View {
        Rectangle().fill(colors.borderSecondary).frame(width: 1, height: 18)
    }

    private func item(icon: String, label: String, tint: Color? = nil) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 16))
            Text(label).font(.system(size: 13))
        }
        .foregroundColor(tint ?? colors.textPrimary)
        .padding(.horizontal, FlareSizes.spacing2md)
        .frame(maxHeight: .infinity)
    }
}

// MARK: - MomentsCoverHeader

/// Cover header for a user's moments — cover photo, name / signature and avatar.
/// Spec: Moments/MomentsCoverHeader (`MomentsCoverHeaderView`).
///
/// With a cover image the photo is tall, with a scrim under white text, and the avatar overhangs the photo's
/// bottom edge.
///
/// Without one the header is a **compact identity row** on the tertiary surface, read left to right: avatar,
/// then name and signature. It used to keep the photo geometry — a 140pt band with the name right-aligned and
/// pulled up onto where the scrim would be — but right alignment, the overlap and the overhang only mean
/// something when there is a photo under them. With no photo they left ~110pt of empty band above a name glued
/// to its bottom-right corner, which read as floating text rather than as this person's header. The band is now
/// sized by its content.
///
/// The change-cover chip and the avatar are controls only with their handlers.
public struct MomentsCoverHeaderView: View {
    private let userId: String
    private let name: String
    private let coverURL: String?
    private let avatarURL: String?
    private let signature: String?
    private let onEditCover: (() -> Void)?
    private let onAvatar: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(userId: String, name: String, coverURL: String? = nil, avatarURL: String? = nil,
                signature: String? = nil, onEditCover: (() -> Void)? = nil, onAvatar: (() -> Void)? = nil) {
        self.userId = userId; self.name = name; self.coverURL = coverURL; self.avatarURL = avatarURL
        self.signature = signature; self.onEditCover = onEditCover; self.onAvatar = onAvatar
    }

    /// The cover photo's height. Without a photo there is no band to reserve: the header is the identity
    /// row itself, so the height is whatever that row needs.
    static func coverHeight(hasImage: Bool) -> CGFloat { hasImage ? 240 : 0 }

    /// The cover image's address, when there is one to load.
    private var coverImageURL: URL? {
        guard let coverURL, !coverURL.isEmpty else { return nil }
        return URL(string: coverURL)
    }

    private static let scrimColor = Color(.sRGB, red: 15 / 255, green: 12 / 255, blue: 25 / 255, opacity: 0.42)

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let image = coverImageURL
        if image == nil {
            // No photo: the header IS the identity row. No reserved band, no negative offsets, no right
            // alignment — nothing here is positioned relative to a picture that does not exist.
            compactIdentity(colors)
        } else {
            VStack(spacing: 0) {
                cover(colors, image: image)
                identity(colors, onImage: true)
                    .padding(.horizontal, FlareSizes.spacingLg)
                    .offset(y: -30)
            }
            .padding(.bottom, 20 - 30)
        }
    }

    /// The no-cover header: avatar, then name and signature, in reading order on the tertiary surface.
    private func compactIdentity(_ colors: FlareColors) -> some View {
        HStack(spacing: FlareSizes.spacingMd) {
            avatar
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: FlareSizes.fontSize3xl, weight: .bold))
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                if let signature {
                    Text(signature)
                        .font(.system(size: 12.5))
                        .foregroundColor(colors.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: FlareSizes.spacingSm)
            if let onEditCover {
                Button(action: onEditCover) {
                    HStack(spacing: FlareSizes.spacingXs) {
                        Image(systemName: flareIconSymbol("image")).font(.system(size: FlareSizes.fontSizeXs))
                        Text(strings.changeCover).font(.system(size: FlareSizes.fontSizeSm))
                    }
                    .foregroundColor(colors.textSecondary)
                    .padding(.horizontal, 11).padding(.vertical, 5)
                    .background(Capsule().fill(colors.bgElevated))
                    .overlay(Capsule().stroke(colors.borderSecondary, lineWidth: 1))
                    .flareTouchTarget()
                }
                .buttonStyle(.plain)
                .flareCompactLayout(height: 30)
            }
        }
        .padding(.horizontal, FlareSizes.spacingMd)
        .padding(.vertical, FlareSizes.spacingMd)
        .frame(maxWidth: .infinity)
        .background(colors.bgTertiary)
    }

    private func cover(_ colors: FlareColors, image: URL?) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image {
                    AsyncImage(url: image) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        colors.bgTertiary
                    }
                    // Bottom scrim so the white name + signature stay legible over any cover.
                    .overlay(LinearGradient(colors: [.clear, .clear, Self.scrimColor], startPoint: .top, endPoint: .bottom))
                } else {
                    colors.bgTertiary
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Self.coverHeight(hasImage: image != nil))
            .clipped()

            if let onEditCover {
                // Change-cover affordance at the top-right, clear of the avatar: glass over a photo, a quiet chip
                // on the band.
                Button(action: onEditCover) {
                    HStack(spacing: FlareSizes.spacingXs) {
                        Image(systemName: flareIconSymbol("image")).font(.system(size: FlareSizes.fontSizeXs))
                        Text(strings.changeCover).font(.system(size: FlareSizes.fontSizeSm))
                    }
                    .foregroundColor(image != nil ? Color.white.opacity(0.92) : colors.textSecondary)
                    .padding(.horizontal, 11).padding(.vertical, 5)
                    .background(Capsule().fill(image != nil
                        ? Color(.sRGB, red: 15 / 255, green: 12 / 255, blue: 25 / 255, opacity: 0.32)
                        : colors.bgElevated))
                    .overlay(Capsule().stroke(image != nil ? Color.clear : colors.borderSecondary, lineWidth: 1))
                    // A 44pt target around the chip; the smaller top inset keeps the chip where it was drawn.
                    .flareTouchTarget()
                }
                .buttonStyle(.plain)
                .padding(.trailing, FlareSizes.spacing2md).padding(.top, FlareSizes.spacingXs)
            }
        }
    }

    private func identity(_ colors: FlareColors, onImage: Bool) -> some View {
        HStack(alignment: .bottom, spacing: FlareSizes.spacingMd) {
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 5) {
                if onImage {
                    // Legible over the cover's dark scrim — white with a soft shadow.
                    Text(name)
                        .font(.system(size: FlareSizes.fontSize3xl, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.45), radius: 6, y: 1)
                        .lineLimit(1)
                    if let signature {
                        Text(signature)
                            .font(.system(size: 12.5))
                            .foregroundColor(Color.white.opacity(0.88))
                            .shadow(color: Color.black.opacity(0.4), radius: 4, y: 1)
                            .lineLimit(1)
                    }
                } else {
                    // No image to lift the text off: the normal text colours, no shadow.
                    Text(name)
                        .font(.system(size: FlareSizes.fontSize3xl, weight: .bold))
                        .foregroundColor(colors.textPrimary)
                        .lineLimit(1)
                    if let signature {
                        Text(signature)
                            .font(.system(size: 12.5))
                            .foregroundColor(colors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.bottom, 20)
            .offset(y: -24)

            avatar
        }
    }

    /// No white frame around the cover avatar — a rounded square with a soft shadow; a control only with
    /// `onAvatar`.
    @ViewBuilder
    private var avatar: some View {
        let picture = AvatarView(userId: userId, displayName: name, avatarURL: avatarURL, size: 66)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: Color(.sRGB, red: 21 / 255, green: 18 / 255, blue: 32 / 255, opacity: 0.28),
                    radius: 9, y: 6)
        if let onAvatar {
            Button(action: onAvatar) { picture }.buttonStyle(.plain)
        } else {
            picture
        }
    }
}

// MARK: - MomentComposer

/// Moment composer card — text, an image grid with add / remove, and location /
/// visibility rows. Spec: Moments/MomentComposer (`MomentComposerView`).
public struct MomentComposerView: View {
    private let images: [String]
    private let maxImages: Int
    private let location: String?
    private let visibility: String?
    private let busy: Bool
    private let onSubmit: ((String) -> Void)?
    private let onCancel: (() -> Void)?
    private let onAddImage: (() -> Void)?
    private let onRemoveImage: ((Int) -> Void)?
    private let onPickLocation: (() -> Void)?
    private let onPickVisibility: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @State private var text = ""

    public init(images: [String] = [], maxImages: Int = 9, location: String? = nil,
                visibility: String? = nil, busy: Bool = false,
                onSubmit: ((String) -> Void)? = nil, onCancel: (() -> Void)? = nil,
                onAddImage: (() -> Void)? = nil, onRemoveImage: ((Int) -> Void)? = nil,
                onPickLocation: (() -> Void)? = nil, onPickVisibility: (() -> Void)? = nil) {
        self.images = images; self.maxImages = maxImages; self.location = location
        self.visibility = visibility; self.busy = busy
        self.onSubmit = onSubmit; self.onCancel = onCancel; self.onAddImage = onAddImage
        self.onRemoveImage = onRemoveImage; self.onPickLocation = onPickLocation
        self.onPickVisibility = onPickVisibility
    }

    private var canPost: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !images.isEmpty
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(alignment: .leading, spacing: 0) {
            header(colors)
            Rectangle().fill(colors.borderPrimary).frame(height: 1)

            TextField(strings.momentTextHint, text: $text, axis: .vertical)
                .lineLimit(4...)
                .font(.system(size: 15))
                .foregroundColor(colors.textPrimary)
                .textFieldStyle(.plain)
                .padding(FlareSizes.spacing2md)

            grid(colors)

            Rectangle().fill(colors.borderPrimary).frame(height: 1)
            row(colors, icon: "location", label: location ?? strings.pickLocation, onTap: onPickLocation)
            Rectangle().fill(colors.borderPrimary).frame(height: 1)
            row(colors, icon: "globe", label: visibility ?? strings.pickVisibility, onTap: onPickVisibility)
        }
        .frame(width: 360)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusXl))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
    }

    private func header(_ colors: FlareColors) -> some View {
        HStack {
            Button { onCancel?() } label: {
                Text(strings.cancel).font(.system(size: 14)).foregroundColor(colors.textSecondary)
            }.buttonStyle(.plain)
            Spacer(minLength: 0)
            Button { onSubmit?(text.trimmingCharacters(in: .whitespacesAndNewlines)) } label: {
                Text(strings.post).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    .padding(.horizontal, 18).padding(.vertical, 6)
                    .background(
                        Capsule().fill(
                            LinearGradient(colors: [colors.primary, colors.primary.opacity(0.82)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)))
            }
            .buttonStyle(.plain)
            .disabled(!canPost || busy)
            .opacity(canPost && !busy ? 1 : 0.45)
        }
        .padding(.horizontal, FlareSizes.spacing2md).padding(.vertical, 12)
    }

    @ViewBuilder
    private func grid(_ colors: FlareColors) -> some View {
        if !images.isEmpty || images.count < maxImages {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, urlStr in
                    thumb(colors, urlStr, index)
                }
                if images.count < maxImages {
                    addTile(colors)
                }
            }
            .padding(.horizontal, FlareSizes.spacing2md).padding(.bottom, 12)
        }
    }

    private func thumb(_ colors: FlareColors, _ urlStr: String, _ index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let url = URL(string: urlStr) {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        colors.bgSecondary
                    }
                } else {
                    colors.bgSecondary
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button { onRemoveImage?(index) } label: {
                ZStack {
                    Circle().fill(Color(.sRGB, red: 17 / 255, green: 19 / 255, blue: 24 / 255, opacity: 0.55))
                    Image(systemName: flareIconSymbol("close")).font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                }
                .frame(width: 18, height: 18)
                // The badge keeps its corner; its 44pt target reaches over the thumbnail.
                .flareTouchTarget()
            }
            .buttonStyle(.plain)
            .flareCompactLayout(width: 18, height: 18)
            .accessibilityLabel(strings.removeImage)
            .padding(2)
        }
    }

    private func addTile(_ colors: FlareColors) -> some View {
        Button { onAddImage?() } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(colors.bgSecondary)
                RoundedRectangle(cornerRadius: 8)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundColor(colors.borderHover)
                Image(systemName: flareIconSymbol("add")).font(.system(size: 26)).foregroundColor(colors.textTertiary)
            }
            .aspectRatio(1, contentMode: .fit)
            // A grid cell is wider than 44pt; the minimum holds when the composer is narrow too.
            .flareTouchTarget()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(strings.addImage)
    }

    private func row(_ colors: FlareColors, icon: String, label: String, onTap: (() -> Void)?) -> some View {
        Button { onTap?() } label: {
            HStack(spacing: FlareSizes.spacing2sm) {
                Image(systemName: icon).font(.system(size: 18)).foregroundColor(colors.textSecondary)
                Text(label).font(.system(size: 14)).foregroundColor(colors.textSecondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, FlareSizes.spacing2md).padding(.vertical, 13)
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

// MARK: - MomentCard

/// A single moment in the feed — author, text, photos, location, meta actions,
/// and a likes / comments social panel. Spec: Moments/MomentCard (`MomentCardView`).
///
/// People and comments are controls only when the host handles them (G18): the author's name with
/// `onSelectAuthor` (the avatar then repeats it for pointers and stays out of VoiceOver), each liker with
/// `onSelectLiker`, each comment with `onSelectComment` (see ``CommentThreadView``); otherwise they are text.
/// Names read in the accessible primary text colour.
public struct MomentCardView: View {
    private let moment: Moment
    private let canDelete: Bool
    private let canReport: Bool
    private let onLike: (() -> Void)?
    private let onComment: (() -> Void)?
    private let onDelete: (() -> Void)?
    private let onReport: (() -> Void)?
    private let onOpenImage: ((Int) -> Void)?
    private let onSelectAuthor: ((String) -> Void)?
    private let onSelectLiker: ((String) -> Void)?
    private let onSelectComment: ((MomentComment) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @State private var menuOpen = false

    public init(moment: Moment, canDelete: Bool = false, canReport: Bool = false,
                onLike: (() -> Void)? = nil,
                onComment: (() -> Void)? = nil, onDelete: (() -> Void)? = nil,
                onReport: (() -> Void)? = nil,
                onOpenImage: ((Int) -> Void)? = nil, onSelectAuthor: ((String) -> Void)? = nil,
                onSelectLiker: ((String) -> Void)? = nil, onSelectComment: ((MomentComment) -> Void)? = nil) {
        self.moment = moment; self.canDelete = canDelete; self.canReport = canReport
        self.onLike = onLike; self.onComment = onComment
        self.onDelete = onDelete; self.onReport = onReport
        self.onOpenImage = onOpenImage; self.onSelectAuthor = onSelectAuthor
        self.onSelectLiker = onSelectLiker; self.onSelectComment = onSelectComment
    }

    private var hasSocial: Bool { !moment.likes.isEmpty || !moment.comments.isEmpty }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        HStack(alignment: .top, spacing: FlareSizes.spacingMd) {
            authorAvatar

            VStack(alignment: .leading, spacing: 0) {
                authorName(colors)

                if let text = moment.text, !text.isEmpty {
                    Text(text)
                        .font(.system(size: 15))
                        .foregroundColor(colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }

                if !moment.images.isEmpty {
                    ImageGridView(images: moment.images, onOpen: onOpenImage)
                        .padding(.top, FlareSizes.spacing2sm)
                }

                if let location = moment.location {
                    HStack(spacing: 3) {
                        Image(systemName: "location").font(.system(size: 13))
                        Text(location).font(.system(size: 12))
                    }
                    .foregroundColor(colors.primaryText.opacity(0.8))
                    .padding(.top, 8)
                }

                meta(colors).padding(.top, FlareSizes.spacing2sm)

                if hasSocial {
                    social(colors).padding(.top, FlareSizes.spacing2sm)
                }
            }
        }
        .padding(16)
        // The card floats on an elevated surface with a deeper dark-mode shadow.
        .background(RoundedRectangle(cornerRadius: 18).fill(colors.bgElevated))
        .shadow(color: Color.black.opacity(scheme == .dark ? 0.5 : 0.1), radius: 20, y: 8)
    }

    @ViewBuilder
    private var authorAvatar: some View {
        let avatar = AvatarView(userId: moment.author.id, displayName: moment.author.name,
                                avatarURL: moment.author.avatarURL, size: 42)
        if let onSelectAuthor {
            // The avatar repeats the name control: a pointer shortcut kept out of VoiceOver.
            Button { onSelectAuthor(moment.author.id) } label: { avatar }
                .buttonStyle(.plain)
                .accessibilityHidden(true)
        } else {
            avatar
        }
    }

    /// A person's name as the card draws it: in the accessible primary text colour, never the raw brand
    /// primary, which is too dark to read on the dark theme.
    static func personName(_ name: String, colors: FlareColors, size: CGFloat, weight: Font.Weight = .regular) -> Text {
        Text(name).font(.system(size: size, weight: weight)).foregroundColor(colors.primaryText)
    }

    @ViewBuilder
    private func authorName(_ colors: FlareColors) -> some View {
        let name = Self.personName(moment.author.name, colors: colors, size: FlareSizes.fontSizeXl, weight: .semibold)
        if let onSelectAuthor {
            Button { onSelectAuthor(moment.author.id) } label: { name }.buttonStyle(.plain)
        } else {
            name
        }
    }

    private func meta(_ colors: FlareColors) -> some View {
        HStack {
            Text(moment.time ?? "")
                .font(.system(size: 12)).foregroundColor(colors.textTertiary)
            Spacer(minLength: 0)
            Button { menuOpen.toggle() } label: {
                Image(systemName: flareIconSymbol("more")).font(.system(size: 16))
                    .foregroundColor(menuOpen ? colors.primaryText : colors.textSecondary)
                    .frame(width: 30, height: 24)
                    .background(RoundedRectangle(cornerRadius: 6)
                        .fill(menuOpen ? colors.bgSelected : colors.bgSecondary))
                    .flareTouchTarget()
            }
            .buttonStyle(.plain)
            .flareCompactLayout(width: 30, height: 24)
            .accessibilityLabel(strings.momentActions)
            .accessibilityAddTraits(menuOpen ? .isSelected : [])
            .overlay(alignment: .trailing) {
                if menuOpen {
                    MomentActionPopoverView(
                        liked: moment.likedBySelf,
                        canDelete: canDelete,
                        canReport: canReport,
                        onLike: { menuOpen = false; onLike?() },
                        onComment: { menuOpen = false; onComment?() },
                        onDelete: { menuOpen = false; onDelete?() },
                        onReport: { menuOpen = false; onReport?() })
                    .fixedSize()
                    .offset(x: -36)
                }
            }
        }
    }

    private func social(_ colors: FlareColors) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if !moment.likes.isEmpty {
                likesRow(colors)
            }
            if !moment.likes.isEmpty && !moment.comments.isEmpty {
                Rectangle()
                    .fill(colors.textTertiary.opacity(0.22))
                    .frame(height: 1)
                    .padding(.vertical, 7)
            }
            if !moment.comments.isEmpty {
                CommentThreadView(comments: moment.comments,
                                  onSelect: onSelectComment,
                                  onSelectAuthor: onSelectAuthor)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
    }

    private func likesRow(_ colors: FlareColors) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "heart").font(.system(size: 14)).foregroundColor(colors.errorText)
                .padding(.top, 2)
            FlareFlowLayout(spacing: 0, lineSpacing: 2) {
                ForEach(Array(moment.likes.enumerated()), id: \.element.id) { index, like in
                    let name = Self.personName(index < moment.likes.count - 1 ? "\(like.name), " : like.name,
                                               colors: colors, size: FlareSizes.fontSizeMd)
                    if let onSelectLiker {
                        // Named by the person, without the separator drawn after the name.
                        Button { onSelectLiker(like.id) } label: { name }
                            .buttonStyle(.plain)
                            .accessibilityLabel(like.name)
                    } else {
                        name
                    }
                }
            }
        }
    }
}

