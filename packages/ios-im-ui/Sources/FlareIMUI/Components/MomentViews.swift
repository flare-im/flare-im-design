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
///
/// A comment longer than `maxLines` lines (3 in the feed; a detail view passes 5) folds behind 展开 / 收起 (the Vue
/// `MomentCommentRow` rule; 0 never folds). The comment `focusCommentId` names is the located one: it starts open,
/// sits on the selected surface with a bar at its leading edge and `focusLabel` (已定位评论) over it, and the label
/// is announced. The row carries the comment's id, so a host's `ScrollViewReader` can scroll to it.
public struct CommentThreadView: View {
    private let comments: [MomentComment]
    private let onSelect: ((MomentComment) -> Void)?
    private let onSelectAuthor: ((String) -> Void)?
    private let maxLines: Int
    private let focusCommentId: String?
    private let focusLabel: String?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    /// Comments open past `maxLines`.
    @State private var expanded: Set<String>
    /// Comments measured to run past `maxLines` at the drawn width.
    @State private var overflowing: Set<String> = []

    public init(comments: [MomentComment],
                onSelect: ((MomentComment) -> Void)? = nil,
                onSelectAuthor: ((String) -> Void)? = nil,
                maxLines: Int = 3, focusCommentId: String? = nil, focusLabel: String? = nil) {
        self.comments = comments; self.onSelect = onSelect; self.onSelectAuthor = onSelectAuthor
        self.maxLines = maxLines; self.focusCommentId = focusCommentId; self.focusLabel = focusLabel
        _expanded = State(initialValue: focusCommentId.map { Set([$0]) } ?? [])
    }

    /// The vertical room around each comment line.
    static let rowInset: CGFloat = 3
    private static let nameFont = Font.system(size: FlareSizes.fontSizeMd, weight: .medium)
    private static let bodyFont = Font.system(size: FlareSizes.fontSizeMd)

    /// Whether a comment gets 展开 / 收起: it was measured past `maxLines`, or — before it is measured — its own line
    /// breaks already make more lines than that.
    static func folds(_ comment: MomentComment, maxLines: Int, measured: Bool) -> Bool {
        maxLines > 0 && (measured || comment.text.split(separator: "\n", omittingEmptySubsequences: false).count > maxLines)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(comments) { comment in
                row(colors, comment)
            }
        }
    }

    private func row(_ colors: FlareColors, _ comment: MomentComment) -> some View {
        let focused = comment.id == focusCommentId
        let open = expanded.contains(comment.id)
        return VStack(alignment: .leading, spacing: 0) {
            if focused, let focusLabel {
                Text(focusLabel).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.primaryText)
                    .padding(.top, Self.rowInset)
            }
            commentLine(colors, comment, lines: maxLines > 0 && !open ? maxLines : nil)
            if Self.folds(comment, maxLines: maxLines, measured: overflowing.contains(comment.id)) {
                Button { expanded.formSymmetricDifference([comment.id]) } label: {
                    Text(open ? strings.collapse : strings.expand)
                        .font(.system(size: FlareSizes.fontSizeMd))
                        .foregroundColor(colors.primaryText)
                        .flareTouchTarget(alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, focused ? FlareSizes.spacingSm : 0)
        .background(focused ? colors.bgSelected : Color.clear)
        .overlay(alignment: .leading) {
            if focused { Rectangle().fill(colors.borderSelected).frame(width: 2) }
        }
        .id(comment.id)
        .onAppear { if focused, let focusLabel { flareAnnounce(focusLabel) } }
    }

    @ViewBuilder
    private func commentLine(_ colors: FlareColors, _ comment: MomentComment, lines: Int?) -> some View {
        let line = Self.line(colors, comment, strings: strings)
            .lineLimit(lines)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .topLeading) {
                if lines != nil { overflowProbe(colors, comment) }
            }
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

    /// The whole comment at the drawn width, never shown: taller than the clamped line means it runs past `maxLines`.
    private func overflowProbe(_ colors: FlareColors, _ comment: MomentComment) -> some View {
        GeometryReader { shown in
            Self.line(colors, comment, strings: strings)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: shown.size.width, alignment: .leading)
                .background(GeometryReader { full in
                    let runsOver = full.size.height > shown.size.height + 1
                    Color.clear
                        .onAppear { measured(comment.id, runsOver) }
                        .onChange(of: runsOver) { measured(comment.id, $0) }
                })
                .hidden()
        }
        .accessibilityHidden(true)
    }

    private func measured(_ id: String, _ runsOver: Bool) {
        guard runsOver != overflowing.contains(id) else { return }
        overflowing.formSymmetricDifference([id])
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

    /// The items the popover draws, in order (DM-00.1: an action is drawn only when the host handles it): like or
    /// unlike, comment, then delete (my moment) or report (someone else's).
    static func items(liked: Bool, canDelete: Bool, canReport: Bool, like: Bool, comment: Bool, delete: Bool,
                      report: Bool) -> [String] {
        var items: [String] = []
        if like { items.append(liked ? "unlike" : "like") }
        if comment { items.append("comment") }
        if canDelete, delete { items.append("delete") } else if canReport, report { items.append("report") }
        return items
    }

    public var body: some View {
        let shown = Self.items(liked: liked, canDelete: canDelete, canReport: canReport, like: onLike != nil,
                               comment: onComment != nil, delete: onDelete != nil, report: onReport != nil)
        HStack(spacing: 0) {
            ForEach(Array(shown.enumerated()), id: \.element) { index, id in
                if index > 0 { divider }
                switch id {
                case "like", "unlike":
                    Button { onLike?() } label: {
                        item(icon: liked ? "heart.slash" : "heart", label: liked ? strings.unlike : strings.like)
                    }.buttonStyle(.plain)
                case "comment":
                    Button { onComment?() } label: { item(icon: "bubble.left", label: strings.comment) }.buttonStyle(.plain)
                case "delete":
                    Button { onDelete?() } label: {
                        item(icon: "trash", label: strings.delete, tint: colors.error)
                    }.buttonStyle(.plain)
                default:
                    // 举报 is not destructive to my own data, so it keeps the normal tint —
                    // the danger colour is reserved for "this deletes something of yours".
                    Button { onReport?() } label: {
                        item(icon: flareIconSymbol("report"), label: strings.report)
                    }.buttonStyle(.plain)
                }
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

    /// The no-cover header (Vue `--empty`): a 48pt avatar, then name and signature, in reading order on the primary
    /// surface with a hairline under it; 换封面 is a quiet text key at the end of the row.
    private func compactIdentity(_ colors: FlareColors) -> some View {
        HStack(spacing: FlareSizes.spacingMd) {
            compactAvatar
            VStack(alignment: .leading, spacing: 5) {
                Text(name)
                    .font(.system(size: FlareSizes.fontSizeLg, weight: .bold))
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
                    Text(strings.changeCover).font(.system(size: FlareSizes.fontSizeSm))
                        .foregroundColor(colors.textSecondary)
                        .padding(.horizontal, FlareSizes.spacingSm).padding(.vertical, FlareSizes.spacingXs)
                        .flareTouchTarget()
                }
                .buttonStyle(.plain)
                .flareCompactLayout(height: 26)
            }
        }
        .padding(FlareSizes.spacingLg)
        .frame(maxWidth: .infinity)
        .background(colors.bgPrimary)
        .overlay(alignment: .bottom) { Rectangle().fill(colors.borderSecondary).frame(height: 1) }
    }

    @ViewBuilder private var compactAvatar: some View {
        let picture = AvatarView(userId: userId, displayName: name, avatarURL: avatarURL, size: 48)
        if let onAvatar {
            Button(action: onAvatar) { picture }.buttonStyle(.plain)
        } else {
            picture
        }
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
/// visibility rows. Spec: Moments/MomentComposer (`MomentComposerView`). `imageUpload` (Vue's `images` slot) takes the
/// grid's place, typically a ``MediaUploadView`` with each picture's upload state; `images` still counts for 发表.
/// Where a ``MomentComposerView`` sits (Vue `layout`): `card` is a 360pt floating card; `page` fills the drawer or
/// page holding it, edge to edge, with no frame of its own.
public enum MomentComposerLayout: Sendable { case card, page }

public struct MomentComposerView: View {
    private let layout: MomentComposerLayout
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
    private let imageUpload: AnyView?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @State private var text = ""

    public init(images: [String] = [], maxImages: Int = 9, location: String? = nil,
                visibility: String? = nil, busy: Bool = false,
                onSubmit: ((String) -> Void)? = nil, onCancel: (() -> Void)? = nil,
                onAddImage: (() -> Void)? = nil, onRemoveImage: ((Int) -> Void)? = nil,
                onPickLocation: (() -> Void)? = nil, onPickVisibility: (() -> Void)? = nil,
                imageUpload: AnyView? = nil, layout: MomentComposerLayout = .card) {
        self.layout = layout
        self.images = images; self.maxImages = maxImages; self.location = location
        self.visibility = visibility; self.busy = busy
        self.onSubmit = onSubmit; self.onCancel = onCancel; self.onAddImage = onAddImage
        self.onRemoveImage = onRemoveImage; self.onPickLocation = onPickLocation
        self.onPickVisibility = onPickVisibility; self.imageUpload = imageUpload
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

            if let imageUpload {
                imageUpload.padding(.horizontal, FlareSizes.spacing2md).padding(.bottom, 12)
            } else {
                grid(colors)
            }

            Rectangle().fill(colors.borderPrimary).frame(height: 1)
            row(colors, icon: flareIconSymbol("location"), label: location ?? strings.pickLocation, onTap: onPickLocation)
            Rectangle().fill(colors.borderPrimary).frame(height: 1)
            row(colors, icon: "globe", label: visibility ?? strings.pickVisibility, onTap: onPickVisibility)
            if layout == .page { Rectangle().fill(colors.borderPrimary).frame(height: 1) }
        }
        .modifier(MomentComposerFrame(layout: layout, colors: colors))
    }

    /// 取消 (ghost) and 发表 (primary), the kit's small buttons (Vue `__head`).
    private func header(_ colors: FlareColors) -> some View {
        HStack {
            ButtonView(label: strings.cancel, variant: .ghost, size: .sm, disabled: busy, maintainTouchTarget: true,
                       action: onCancel)
            Spacer(minLength: 0)
            ButtonView(label: strings.post, size: .sm, disabled: !canPost || busy, maintainTouchTarget: true) {
                onSubmit?(text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        .padding(.horizontal, FlareSizes.spacing2md).padding(.vertical, FlareSizes.spacingSm)
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
/// Names read in the accessible primary text colour. Comments fold past `commentMaxLines` (3; a detail view passes
/// 5), and `focusCommentId` / `focusCommentLabel` mark the located comment (``CommentThreadView``).
/// How a ``MomentCardView`` sits (Vue `appearance`): `card` floats on its own rounded, shadowed surface; `feed` is a
/// flat full-width item with a hairline under it, for a feed of moments.
public enum MomentCardAppearance: Sendable { case card, feed }

public struct MomentCardView: View {
    private let moment: Moment
    private let appearance: MomentCardAppearance
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
    private let commentMaxLines: Int
    private let focusCommentId: String?
    private let focusCommentLabel: String?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @State private var menuOpen = false
    @State private var expanded = false

    /// A body longer than this, or than ``foldLines`` lines, folds behind 展开 / 收起 (the Vue card's rule).
    static let foldCharacters = 280
    static let foldLines = 6

    static func folds(_ text: String) -> Bool {
        text.count > foldCharacters || text.split(separator: "\n", omittingEmptySubsequences: false).count > foldLines
    }

    public init(moment: Moment, canDelete: Bool = false, canReport: Bool = false,
                onLike: (() -> Void)? = nil,
                onComment: (() -> Void)? = nil, onDelete: (() -> Void)? = nil,
                onReport: (() -> Void)? = nil,
                onOpenImage: ((Int) -> Void)? = nil, onSelectAuthor: ((String) -> Void)? = nil,
                onSelectLiker: ((String) -> Void)? = nil, onSelectComment: ((MomentComment) -> Void)? = nil,
                commentMaxLines: Int = 3, focusCommentId: String? = nil, focusCommentLabel: String? = nil,
                appearance: MomentCardAppearance = .card) {
        self.moment = moment; self.appearance = appearance; self.canDelete = canDelete; self.canReport = canReport
        self.onLike = onLike; self.onComment = onComment
        self.onDelete = onDelete; self.onReport = onReport
        self.onOpenImage = onOpenImage; self.onSelectAuthor = onSelectAuthor
        self.onSelectLiker = onSelectLiker; self.onSelectComment = onSelectComment
        self.commentMaxLines = commentMaxLines; self.focusCommentId = focusCommentId
        self.focusCommentLabel = focusCommentLabel
    }

    private var hasSocial: Bool { !moment.likes.isEmpty || !moment.comments.isEmpty }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        HStack(alignment: .top, spacing: FlareSizes.spacingMd) {
            authorAvatar

            VStack(alignment: .leading, spacing: 0) {
                authorName(colors)

                if let text = moment.text, !text.isEmpty {
                    let folds = Self.folds(text)
                    Text(text)
                        .font(.system(size: 15))
                        .foregroundColor(colors.textPrimary)
                        .lineLimit(folds && !expanded ? Self.foldLines : nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                    if folds {
                        Button { expanded.toggle() } label: {
                            Text(expanded ? strings.collapse : strings.expand)
                                .font(.system(size: FlareSizes.fontSizeMd))
                                .foregroundColor(colors.primaryText)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
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

                meta(colors).padding(.top, FlareSizes.spacingXs)

                if hasSocial {
                    social(colors).padding(.top, FlareSizes.spacing2xs)
                }
            }
        }
        .padding(16)
        .modifier(MomentCardSurface(appearance: appearance, colors: colors, dark: scheme == .dark))
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

    /// Whether the popover has anything to offer: without a single action there is no 「···」 key.
    private var hasActions: Bool {
        !MomentActionPopoverView.items(liked: moment.likedBySelf, canDelete: canDelete, canReport: canReport,
                                       like: onLike != nil, comment: onComment != nil, delete: onDelete != nil,
                                       report: onReport != nil).isEmpty
    }

    private func closing(_ action: (() -> Void)?) -> (() -> Void)? {
        action.map { run in { menuOpen = false; run() } }
    }

    private func meta(_ colors: FlareColors) -> some View {
        HStack {
            Text(moment.time ?? "")
                .font(.system(size: 12)).foregroundColor(colors.textTertiary)
            Spacer(minLength: 0)
            if hasActions { actionsKey(colors) }
        }
    }

    private func actionsKey(_ colors: FlareColors) -> some View {
        Group {
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
                        onLike: closing(onLike),
                        onComment: closing(onComment),
                        onDelete: closing(onDelete),
                        onReport: closing(onReport))
                    .fixedSize()
                    .offset(x: -36)
                }
            }
        }
    }

    /// Likes and comments under one hairline, inside the card (Vue `__social`): no second surface.
    private func social(_ colors: FlareColors) -> some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            if !moment.likes.isEmpty {
                likesRow(colors)
            }
            if !moment.comments.isEmpty {
                CommentThreadView(comments: moment.comments,
                                  onSelect: onSelectComment,
                                  onSelectAuthor: onSelectAuthor,
                                  maxLines: commentMaxLines, focusCommentId: focusCommentId,
                                  focusLabel: focusCommentLabel)
            }
        }
        .padding(.top, FlareSizes.spacingXs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { Rectangle().fill(colors.borderSecondary).frame(height: 1) }
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

/// The ground of a ``MomentCardView`` for its appearance.
private struct MomentCardSurface: ViewModifier {
    let appearance: MomentCardAppearance
    let colors: FlareColors
    let dark: Bool

    func body(content: Content) -> some View {
        switch appearance {
        case .card:
            // The card floats on an elevated surface with a deeper dark-mode shadow.
            content
                .background(RoundedRectangle(cornerRadius: 18).fill(colors.bgElevated))
                .shadow(color: Color.black.opacity(dark ? 0.5 : 0.1), radius: 20, y: 8)
        case .feed:
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(colors.bgElevated)
                .overlay(alignment: .bottom) { Rectangle().fill(colors.borderSecondary).frame(height: 1) }
        }
    }
}

/// The composer's own frame for its layout: the floating card, or none on a page.
private struct MomentComposerFrame: ViewModifier {
    let layout: MomentComposerLayout
    let colors: FlareColors

    func body(content: Content) -> some View {
        switch layout {
        case .card:
            content
                .frame(width: 360)
                .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
                    .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
                .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusXl))
                .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
        case .page:
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(colors.bgPrimary)
        }
    }
}
