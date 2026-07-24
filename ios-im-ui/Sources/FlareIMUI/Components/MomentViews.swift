import SwiftUI

// MARK: - TopicChip

/// A tappable topic tag rendered as "#topic" in the brand colour.
/// Spec: Moments/TopicChip (`TopicChipView`).
public struct TopicChipView: View {
    private let topic: String
    private let onTap: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(topic: String, onTap: (() -> Void)? = nil) {
        self.topic = topic; self.onTap = onTap
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        Button { onTap?() } label: {
            Text("#\(topic)")
                .font(.system(size: FlareSizes.fontSizeLg, weight: .medium))
                .foregroundColor(colors.primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - CommentThread

/// A vertical list of moment comments — each an inline "name[ replying to name]：text".
/// Spec: Moments/CommentThread (`CommentThreadView`).
public struct CommentThreadView: View {
    private let comments: [MomentComment]
    private let onSelect: ((MomentComment) -> Void)?
    private let onSelectAuthor: ((String) -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(comments: [MomentComment],
                onSelect: ((MomentComment) -> Void)? = nil,
                onSelectAuthor: ((String) -> Void)? = nil) {
        self.comments = comments; self.onSelect = onSelect; self.onSelectAuthor = onSelectAuthor
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(comments) { comment in
                line(colors, comment)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 3)
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect?(comment) }
            }
        }
    }

    private func line(_ colors: FlareColors, _ comment: MomentComment) -> Text {
        var text = Text(comment.author.name)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(colors.primary)
        if let replyTo = comment.replyToName {
            text = text
                + Text(" 回复 ").font(.system(size: 13)).foregroundColor(colors.textTertiary)
                + Text(replyTo).font(.system(size: 13, weight: .medium)).foregroundColor(colors.primary)
        }
        text = text
            + Text("：").font(.system(size: 13)).foregroundColor(colors.textTertiary)
            + Text(comment.text).font(.system(size: 13)).foregroundColor(colors.textPrimary)
        return text
    }
}

// MARK: - MomentActionPopover

/// Dark like / comment popover shown next to a moment's "…" button. When `canDelete`
/// is set (the moment is the current user's) a destructive Delete action is appended.
/// Spec: Moments/MomentActionPopover (`MomentActionPopoverView`).
public struct MomentActionPopoverView: View {
    private let liked: Bool
    private let canDelete: Bool
    private let onLike: (() -> Void)?
    private let onComment: (() -> Void)?
    private let onDelete: (() -> Void)?

    public init(liked: Bool = false, canDelete: Bool = false,
                onLike: (() -> Void)? = nil, onComment: (() -> Void)? = nil,
                onDelete: (() -> Void)? = nil) {
        self.liked = liked; self.canDelete = canDelete
        self.onLike = onLike; self.onComment = onComment; self.onDelete = onDelete
    }

    private static let danger = Color(.sRGB, red: 1.0, green: 0x8A / 255, blue: 0x80 / 255, opacity: 1)

    public var body: some View {
        HStack(spacing: 0) {
            Button { onLike?() } label: {
                item(icon: liked ? "heart.slash" : "heart", label: liked ? "取消赞" : "赞")
            }.buttonStyle(.plain)

            divider

            Button { onComment?() } label: {
                item(icon: "bubble.left", label: "评论")
            }.buttonStyle(.plain)

            if canDelete {
                divider
                Button { onDelete?() } label: {
                    item(icon: "trash", label: "删除", tint: Self.danger)
                }.buttonStyle(.plain)
            }
        }
        .frame(height: 34)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.sRGB, red: 0x2C / 255, green: 0x2B / 255, blue: 0x33 / 255, opacity: 1))
        )
        .shadow(color: Color(.sRGB, red: 21 / 255, green: 18 / 255, blue: 32 / 255, opacity: 0.28), radius: 9, y: 6)
    }

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.16)).frame(width: 1, height: 18)
    }

    private func item(icon: String, label: String, tint: Color? = nil) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 14))
            Text(label).font(.system(size: 13))
        }
        .foregroundColor(tint ?? Color(.sRGB, red: 0xF2 / 255, green: 0xF0 / 255, blue: 0xF7 / 255, opacity: 1))
        .padding(.horizontal, 14)
        .frame(maxHeight: .infinity)
    }
}

// MARK: - MomentsCoverHeader

/// Cover header for a user's moments — cover photo, name / signature and avatar.
/// Spec: Moments/MomentsCoverHeader (`MomentsCoverHeaderView`).
public struct MomentsCoverHeaderView: View {
    private let userId: String
    private let name: String
    private let coverURL: String?
    private let avatarURL: String?
    private let signature: String?
    private let onEditCover: (() -> Void)?
    private let onAvatar: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(userId: String, name: String, coverURL: String? = nil, avatarURL: String? = nil,
                signature: String? = nil, onEditCover: (() -> Void)? = nil, onAvatar: (() -> Void)? = nil) {
        self.userId = userId; self.name = name; self.coverURL = coverURL; self.avatarURL = avatarURL
        self.signature = signature; self.onEditCover = onEditCover; self.onAvatar = onAvatar
    }

    public var body: some View {
        VStack(spacing: 0) {
            cover
            identity
                .padding(.horizontal, 16)
                .offset(y: -30)
        }
        .padding(.bottom, 20 - 30)
    }

    private var cover: some View {
        ZStack(alignment: .topTrailing) {
            coverFill
                // Bottom scrim so the white name + signature stay legible over any cover.
                .overlay(
                    LinearGradient(
                        colors: [.clear, .clear, Color(.sRGB, red: 15 / 255, green: 12 / 255, blue: 25 / 255, opacity: 0.42)],
                        startPoint: .top, endPoint: .bottom))
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .clipped()

            // Change-cover affordance — a glass chip at the top-right, clear of the avatar.
            Button { onEditCover?() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "camera").font(.system(size: 11))
                    Text("更换封面").font(.system(size: 12))
                }
                .foregroundColor(Color.white.opacity(0.92))
                .padding(.horizontal, 11).padding(.vertical, 5)
                .background(Capsule().fill(Color(.sRGB, red: 15 / 255, green: 12 / 255, blue: 25 / 255, opacity: 0.32)))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 14).padding(.top, 14)
        }
    }

    @ViewBuilder
    private var coverFill: some View {
        if let coverURL, let url = URL(string: coverURL) {
            AsyncImage(url: url) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                gradient
            }
        } else {
            gradient
        }
    }

    private var gradient: some View {
        // Aurora — a deep violet light source rather than a flat two-stop gradient.
        LinearGradient(
            colors: [
                Color(.sRGB, red: 0x3B / 255, green: 0x1F / 255, blue: 0x7A / 255, opacity: 1),
                Color(.sRGB, red: 0x7C / 255, green: 0x3A / 255, blue: 0xED / 255, opacity: 1),
                Color(.sRGB, red: 0xA7 / 255, green: 0x8B / 255, blue: 0xFA / 255, opacity: 1),
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var identity: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 5) {
                Text(name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.45), radius: 6, y: 1)
                    .lineLimit(1)
                if let signature {
                    // Legible over the cover's dark scrim — white with a soft shadow.
                    Text(signature)
                        .font(.system(size: 12.5))
                        .foregroundColor(Color.white.opacity(0.88))
                        .shadow(color: Color.black.opacity(0.4), radius: 4, y: 1)
                        .lineLimit(1)
                }
            }
            .padding(.bottom, 20)

            // No white frame around the cover avatar — just a rounded-square with a soft shadow.
            Button { onAvatar?() } label: {
                AvatarView(userId: userId, displayName: name, avatarURL: avatarURL, size: 66)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(color: Color(.sRGB, red: 21 / 255, green: 18 / 255, blue: 32 / 255, opacity: 0.28),
                            radius: 9, y: 6)
            }.buttonStyle(.plain)
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
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 0) {
            header(colors)
            Rectangle().fill(colors.borderPrimary).frame(height: 1)

            TextField("这一刻的想法…", text: $text, axis: .vertical)
                .lineLimit(4...)
                .font(.system(size: 15))
                .foregroundColor(colors.textPrimary)
                .textFieldStyle(.plain)
                .padding(14)

            grid(colors)

            Rectangle().fill(colors.borderPrimary).frame(height: 1)
            row(colors, icon: "location", label: location ?? "所在位置", onTap: onPickLocation)
            Rectangle().fill(colors.borderPrimary).frame(height: 1)
            row(colors, icon: "globe", label: visibility ?? "谁可以看", onTap: onPickVisibility)
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
                Text("取消").font(.system(size: 14)).foregroundColor(colors.textSecondary)
            }.buttonStyle(.plain)
            Spacer(minLength: 0)
            Button { onSubmit?(text.trimmingCharacters(in: .whitespacesAndNewlines)) } label: {
                Text("发表").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
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
        .padding(.horizontal, 14).padding(.vertical, 12)
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
            .padding(.horizontal, 14).padding(.bottom, 12)
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
                    Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                }
                .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
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
                Image(systemName: "plus").font(.system(size: 26)).foregroundColor(colors.textTertiary)
            }
            .aspectRatio(1, contentMode: .fit)
        }.buttonStyle(.plain)
    }

    private func row(_ colors: FlareColors, icon: String, label: String, onTap: (() -> Void)?) -> some View {
        Button { onTap?() } label: {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 18)).foregroundColor(colors.textSecondary)
                Text(label).font(.system(size: 14)).foregroundColor(colors.textSecondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

// MARK: - MomentCard

/// A single moment in the feed — author, text, photos, location, meta actions,
/// and a likes / comments social panel. Spec: Moments/MomentCard (`MomentCardView`).
public struct MomentCardView: View {
    private let moment: Moment
    private let canDelete: Bool
    private let onLike: (() -> Void)?
    private let onComment: (() -> Void)?
    private let onDelete: (() -> Void)?
    private let onOpenImage: ((Int) -> Void)?
    private let onSelectAuthor: ((String) -> Void)?
    private let onSelectLiker: ((String) -> Void)?
    private let onSelectComment: ((MomentComment) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var menuOpen = false

    public init(moment: Moment, canDelete: Bool = false, onLike: (() -> Void)? = nil,
                onComment: (() -> Void)? = nil, onDelete: (() -> Void)? = nil,
                onOpenImage: ((Int) -> Void)? = nil, onSelectAuthor: ((String) -> Void)? = nil,
                onSelectLiker: ((String) -> Void)? = nil, onSelectComment: ((MomentComment) -> Void)? = nil) {
        self.moment = moment; self.canDelete = canDelete; self.onLike = onLike; self.onComment = onComment
        self.onDelete = onDelete; self.onOpenImage = onOpenImage; self.onSelectAuthor = onSelectAuthor
        self.onSelectLiker = onSelectLiker; self.onSelectComment = onSelectComment
    }

    private var hasSocial: Bool { !moment.likes.isEmpty || !moment.comments.isEmpty }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(alignment: .top, spacing: 12) {
            Button { onSelectAuthor?(moment.author.id) } label: {
                AvatarView(userId: moment.author.id, displayName: moment.author.name,
                           avatarURL: moment.author.avatarURL, size: 42)
            }.buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 0) {
                Button { onSelectAuthor?(moment.author.id) } label: {
                    Text(moment.author.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(colors.primary)
                }.buttonStyle(.plain)

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
                        .padding(.top, 10)
                }

                if let location = moment.location {
                    HStack(spacing: 3) {
                        Image(systemName: "location").font(.system(size: 13))
                        Text(location).font(.system(size: 12))
                    }
                    .foregroundColor(colors.primary.opacity(0.8))
                    .padding(.top, 8)
                }

                meta(colors).padding(.top, 10)

                if hasSocial {
                    social(colors).padding(.top, 10)
                }
            }
        }
        .padding(16)
        // Aurora — the card floats on an elevated surface + shadow (deeper in dark).
        .background(RoundedRectangle(cornerRadius: 18).fill(colors.bgElevated))
        .shadow(color: Color.black.opacity(scheme == .dark ? 0.5 : 0.1), radius: 20, y: 8)
    }

    private func meta(_ colors: FlareColors) -> some View {
        HStack {
            Text(moment.time ?? "")
                .font(.system(size: 12)).foregroundColor(colors.textTertiary)
            Spacer(minLength: 0)
            Button { menuOpen.toggle() } label: {
                Image(systemName: "ellipsis").font(.system(size: 16))
                    .foregroundColor(menuOpen ? colors.primary : colors.textSecondary)
                    .frame(width: 30, height: 24)
                    .background(RoundedRectangle(cornerRadius: 6)
                        .fill(menuOpen ? colors.bgSelected : colors.bgSecondary))
            }
            .buttonStyle(.plain)
            .overlay(alignment: .trailing) {
                if menuOpen {
                    MomentActionPopoverView(
                        liked: moment.likedBySelf,
                        canDelete: canDelete,
                        onLike: { menuOpen = false; onLike?() },
                        onComment: { menuOpen = false; onComment?() },
                        onDelete: { menuOpen = false; onDelete?() })
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
            Image(systemName: "heart").font(.system(size: 14)).foregroundColor(colors.error)
                .padding(.top, 2)
            MomentLikersFlow(spacing: 0, lineSpacing: 2) {
                ForEach(Array(moment.likes.enumerated()), id: \.element.id) { index, like in
                    Button { onSelectLiker?(like.id) } label: {
                        Text(index < moment.likes.count - 1 ? "\(like.name), " : like.name)
                            .font(.system(size: 13))
                            .foregroundColor(colors.primary)
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Flow layout (liker names)

/// Minimal wrapping flow layout for the moment likers row.
struct MomentLikersFlow: Layout {
    var spacing: CGFloat = 0
    var lineSpacing: CGFloat = 2

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxRowWidth: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                maxRowWidth = max(maxRowWidth, x - spacing)
                x = 0; y += rowHeight + lineSpacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        maxRowWidth = max(maxRowWidth, x - spacing)
        return CGSize(width: min(maxRowWidth, maxWidth), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let maxWidth = bounds.width
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0; y += rowHeight + lineSpacing; rowHeight = 0
            }
            view.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y),
                       anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
