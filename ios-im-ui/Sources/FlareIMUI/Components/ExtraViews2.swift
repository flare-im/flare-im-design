import SwiftUI

// MARK: - ReactionSummary

/// Reaction summary — wrapping row of emoji pills + add button.
/// Spec: Message/ReactionSummary (`ReactionSummaryView`).
public struct ReactionSummaryView: View {
    private let reactions: [ReactionGroup]
    private let hideAdd: Bool
    private let onToggle: ((String) -> Void)?
    private let onAdd: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(reactions: [ReactionGroup], hideAdd: Bool = false,
                onToggle: ((String) -> Void)? = nil, onAdd: (() -> Void)? = nil) {
        self.reactions = reactions; self.hideAdd = hideAdd; self.onToggle = onToggle; self.onAdd = onAdd
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(reactions) { r in pill(colors, r) }
                if !hideAdd { addPill(colors) }
            }
        }
    }

    private func pill(_ colors: FlareColors, _ r: ReactionGroup) -> some View {
        let selected = r.reactedBySelf
        return Button { onToggle?(r.emoji) } label: {
            HStack(spacing: 4) {
                Text(r.emoji).font(.system(size: FlareSizes.fontSizeLg))
                Text("\(r.count)").font(.system(size: FlareSizes.fontSizeSm, weight: .medium))
            }
            .foregroundColor(selected ? colors.primary : colors.textSecondary)
            .padding(.horizontal, 9)
            .frame(height: 26)
            .background(Capsule().fill(selected ? colors.bgSelected : colors.bgSecondary))
            .overlay(Capsule().stroke(selected ? colors.primary : colors.borderPrimary, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func addPill(_ colors: FlareColors) -> some View {
        Button { onAdd?() } label: {
            Image(systemName: "face.smiling").font(.system(size: 15)).foregroundColor(colors.textTertiary)
                .padding(.horizontal, 9)
                .frame(height: 26)
                .background(Capsule().fill(colors.bgSecondary))
                .overlay(Capsule().stroke(colors.borderPrimary, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ReadReceiptSheet

/// Read receipt sheet — read / unread tabs with member lists.
/// Spec: Message/ReadReceiptSheet (`ReadReceiptSheetView`).
public struct ReadReceiptSheetView: View {
    private let readers: [Contact]
    private let unread: [Contact]
    private let dismissible: Bool
    private let onSelect: ((String) -> Void)?
    private let onClose: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var activeTab: Int = 0

    public init(readers: [Contact], unread: [Contact], dismissible: Bool = false,
                onSelect: ((String) -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self.readers = readers; self.unread = unread; self.dismissible = dismissible
        self.onSelect = onSelect; self.onClose = onClose
    }

    private var activeList: [Contact] { activeTab == 0 ? readers : unread }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: FlareSizes.spacingSm) {
                Image(systemName: "checkmark.circle").font(.system(size: 16)).foregroundColor(colors.primary)
                Text("Read receipt").font(.system(size: FlareSizes.fontSizeXl, weight: .semibold)).foregroundColor(colors.textPrimary)
                Spacer()
                if dismissible {
                    Button { onClose?() } label: {
                        Image(systemName: "xmark").font(.system(size: 14)).foregroundColor(colors.textTertiary)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.top, FlareSizes.spacingLg).padding(.bottom, FlareSizes.spacingMd)

            HStack(spacing: 0) {
                tab(colors, 0, "Read (\(readers.count))")
                tab(colors, 1, "Unread (\(unread.count))")
            }
            .padding(.horizontal, FlareSizes.spacingLg)

            Divider().overlay(colors.borderPrimary)

            if activeList.isEmpty {
                Text(activeTab == 0 ? "No one has read this yet" : "Everyone has read this")
                    .font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textTertiary)
                    .frame(maxWidth: .infinity).padding(.vertical, 28)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(activeList) { c in row(colors, c) }
                    }
                }
                .frame(maxHeight: 320)
            }
        }
        .frame(width: 320)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
    }

    private func tab(_ colors: FlareColors, _ index: Int, _ label: String) -> some View {
        let active = activeTab == index
        return Button { activeTab = index } label: {
            VStack(spacing: 6) {
                Text(label).font(.system(size: FlareSizes.fontSizeLg, weight: active ? .semibold : .regular))
                    .foregroundColor(active ? colors.primary : colors.textSecondary)
                Rectangle().fill(active ? colors.primary : Color.clear).frame(height: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, FlareSizes.spacingSm)
        }
        .buttonStyle(.plain)
    }

    private func row(_ colors: FlareColors, _ c: Contact) -> some View {
        Button { onSelect?(c.id) } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                AvatarView(userId: c.id, displayName: c.name, avatarURL: c.avatarURL, size: 36, presence: c.presence)
                Text(c.name).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary).lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingSm)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MessageBatchToolbar

/// Multi-select batch toolbar — select-all / forward / delete / exit.
/// Spec: Message/MessageBatchToolbar (`MessageBatchToolbarView`).
public struct MessageBatchToolbarView: View {
    private let count: Int
    private let total: Int
    private let busy: Bool
    private let onSelectAll: (() -> Void)?
    private let onForwardEach: (() -> Void)?
    private let onForwardMerged: (() -> Void)?
    private let onDelete: (() -> Void)?
    private let onExit: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(count: Int, total: Int, busy: Bool = false,
                onSelectAll: (() -> Void)? = nil, onForwardEach: (() -> Void)? = nil,
                onForwardMerged: (() -> Void)? = nil, onDelete: (() -> Void)? = nil,
                onExit: (() -> Void)? = nil) {
        self.count = count; self.total = total; self.busy = busy
        self.onSelectAll = onSelectAll; self.onForwardEach = onForwardEach
        self.onForwardMerged = onForwardMerged; self.onDelete = onDelete; self.onExit = onExit
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: FlareSizes.spacingSm) {
            HStack(spacing: 4) {
                Text("\(count)").font(.system(size: FlareSizes.fontSizeLg, weight: .bold)).foregroundColor(colors.primary)
                Text("/ \(total) · selected").font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
            }
            Spacer(minLength: FlareSizes.spacingMd)
            button(colors, "checkmark.circle", "Select all", onSelectAll, disabled: total == 0 || busy)
            button(colors, "arrowshape.turn.up.right", "Forward each", onForwardEach, disabled: count == 0 || busy)
            button(colors, "square.stack", "Forward merged", onForwardMerged, disabled: count < 2 || busy)
            button(colors, "trash", "Delete", onDelete, disabled: count == 0 || busy, tint: colors.error)
            iconButton(colors, "xmark", onExit)
        }
        .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingMd)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.12), radius: 16, y: 6)
    }

    private func button(_ colors: FlareColors, _ icon: String, _ label: String, _ onTap: (() -> Void)?,
                        disabled: Bool, tint: Color? = nil) -> some View {
        Button { onTap?() } label: {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 14))
                Text(label).font(.system(size: FlareSizes.fontSizeMd, weight: .medium))
            }
            .foregroundColor(tint ?? colors.textPrimary)
            .padding(.horizontal, FlareSizes.spacingMd)
            .frame(height: 32)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(colors.bgSecondary))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
    }

    private func iconButton(_ colors: FlareColors, _ icon: String, _ onTap: (() -> Void)?) -> some View {
        Button { onTap?() } label: {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(colors.textSecondary)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(colors.bgSecondary))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MentionPicker

/// @mention picker — search field + optional "Everyone" + member list.
/// Spec: Composer/MentionPicker (`MentionPickerView`).
public struct MentionPickerView: View {
    private let candidates: [MentionCandidate]
    private let allowEveryone: Bool
    private let onSelect: ((MentionCandidate) -> Void)?
    private let onClose: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var query: String = ""

    public init(candidates: [MentionCandidate], allowEveryone: Bool = false,
                onSelect: ((MentionCandidate) -> Void)? = nil, onClose: (() -> Void)? = nil) {
        self.candidates = candidates; self.allowEveryone = allowEveryone
        self.onSelect = onSelect; self.onClose = onClose
    }

    private var filtered: [MentionCandidate] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return candidates }
        return candidates.filter {
            $0.name.lowercased().contains(q) || ($0.detail?.lowercased().contains(q) ?? false)
        }
    }

    private var showEveryone: Bool {
        guard allowEveryone else { return false }
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return q.isEmpty || "everyone".contains(q)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: FlareSizes.spacingSm) {
                Image(systemName: "magnifyingglass").font(.system(size: 14)).foregroundColor(colors.textTertiary)
                TextField("Search members", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary)
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingMd)

            Divider().overlay(colors.borderPrimary)

            if !showEveryone && filtered.isEmpty {
                Text("No matching members")
                    .font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textTertiary)
                    .frame(maxWidth: .infinity).padding(.vertical, 24)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        if showEveryone { everyoneRow(colors) }
                        ForEach(filtered) { c in personRow(colors, c) }
                    }
                }
                .frame(maxHeight: 264)
            }
        }
        .frame(width: 280)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
    }

    private func everyoneRow(_ colors: FlareColors) -> some View {
        Button {
            onSelect?(MentionCandidate(id: "__all__", name: "Everyone", isEveryone: true))
        } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                Image(systemName: "person.2").font(.system(size: 15)).foregroundColor(.white)
                    .frame(width: 32, height: 32).background(Circle().fill(colors.primary))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Everyone").font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary)
                    Text("Notify all members").font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingSm)
        }
        .buttonStyle(.plain)
    }

    private func personRow(_ colors: FlareColors, _ c: MentionCandidate) -> some View {
        Button { onSelect?(c) } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                AvatarView(userId: c.id, displayName: c.name, avatarURL: c.avatarURL, size: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text(c.name).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary).lineLimit(1)
                    if let d = c.detail, !d.isEmpty {
                        Text(d).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingSm)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - QuickPhrases

/// Quick phrases — grouped canned-reply picker.
/// Spec: Composer/QuickPhrases (`QuickPhrasesView`).
public struct QuickPhrasesView: View {
    private let groups: [QuickPhraseGroup]
    private let manageable: Bool
    private let onSelect: ((String) -> Void)?
    private let onManage: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var activeKey: String

    public init(groups: [QuickPhraseGroup], manageable: Bool = false,
                onSelect: ((String) -> Void)? = nil, onManage: (() -> Void)? = nil) {
        self.groups = groups; self.manageable = manageable; self.onSelect = onSelect; self.onManage = onManage
        _activeKey = State(initialValue: groups.first?.key ?? "")
    }

    private var activeGroup: QuickPhraseGroup? {
        groups.first { $0.key == activeKey } ?? groups.first
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
            HStack(spacing: FlareSizes.spacingSm) {
                Image(systemName: "bolt").font(.system(size: 15)).foregroundColor(colors.primary)
                Text("Quick phrases").font(.system(size: FlareSizes.fontSizeXl, weight: .semibold)).foregroundColor(colors.textPrimary)
                Spacer()
                if manageable {
                    Button { onManage?() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.pencil").font(.system(size: 13))
                            Text("Manage").font(.system(size: FlareSizes.fontSizeMd, weight: .medium))
                        }.foregroundColor(colors.textSecondary)
                    }.buttonStyle(.plain)
                }
            }

            if groups.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(groups) { g in tabPill(colors, g) }
                    }
                }
            }

            VStack(spacing: 6) {
                ForEach(activeGroup?.phrases ?? []) { p in phraseRow(colors, p) }
            }
        }
        .padding(FlareSizes.spacingLg)
        .frame(width: 320)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(colors.bgPrimary)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).stroke(colors.borderPrimary, lineWidth: 1)))
        .shadow(color: Color.black.opacity(0.16), radius: 28, y: 12)
    }

    private func tabPill(_ colors: FlareColors, _ g: QuickPhraseGroup) -> some View {
        let active = g.key == activeKey
        return Button { activeKey = g.key } label: {
            Text(g.title).font(.system(size: FlareSizes.fontSizeMd, weight: .medium))
                .foregroundColor(active ? colors.primary : colors.textSecondary)
                .padding(.horizontal, 12).frame(height: 28)
                .background(Capsule().fill(active ? colors.bgSelected : colors.bgSecondary))
        }
        .buttonStyle(.plain)
    }

    private func phraseRow(_ colors: FlareColors, _ p: QuickPhrase) -> some View {
        Button { onSelect?(p.text) } label: {
            Text(p.text).font(.system(size: 14)).foregroundColor(colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SearchResults

/// Global search results — grouped contacts / groups / messages with query highlight.
/// Spec: Search/SearchResults (`SearchResultsView`).
public struct SearchResultsView: View {
    private let groups: [SearchResultGroup]
    private let query: String
    private let onOpen: ((SearchResultItem) -> Void)?
    private let onViewAll: ((SearchResultKind) -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(groups: [SearchResultGroup], query: String,
                onOpen: ((SearchResultItem) -> Void)? = nil, onViewAll: ((SearchResultKind) -> Void)? = nil) {
        self.groups = groups; self.query = query; self.onOpen = onOpen; self.onViewAll = onViewAll
    }

    private var nonEmpty: [SearchResultGroup] { groups.filter { !$0.items.isEmpty } }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        if nonEmpty.isEmpty {
            Text("No results found")
                .font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textTertiary)
                .frame(maxWidth: .infinity).padding(.vertical, 32)
        } else {
            VStack(alignment: .leading, spacing: FlareSizes.spacingLg) {
                ForEach(nonEmpty) { g in section(colors, g) }
            }
            .padding(FlareSizes.spacingLg)
        }
    }

    private func section(_ colors: FlareColors, _ g: SearchResultGroup) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(g.label.uppercased()).font(.system(size: 12, weight: .semibold)).foregroundColor(colors.textTertiary)
                .padding(.leading, 4).padding(.bottom, 2)
            ForEach(g.items) { item in row(colors, item) }
            if let total = g.total, total > g.items.count {
                Button { onViewAll?(g.kind) } label: {
                    Text("View all \(total)").font(.system(size: FlareSizes.fontSizeLg, weight: .medium))
                        .foregroundColor(colors.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4).padding(.vertical, FlareSizes.spacingSm)
                }.buttonStyle(.plain)
            }
        }
    }

    private func row(_ colors: FlareColors, _ item: SearchResultItem) -> some View {
        Button { onOpen?(item) } label: {
            HStack(spacing: FlareSizes.spacingMd) {
                AvatarView(userId: item.id, displayName: item.title, avatarURL: item.avatarURL, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    highlighted(item.title, colors).font(.system(size: FlareSizes.fontSizeLg))
                        .foregroundColor(colors.textPrimary).lineLimit(1)
                    if let sub = item.subtitle, !sub.isEmpty {
                        highlighted(sub, colors).font(.system(size: FlareSizes.fontSizeSm))
                            .foregroundColor(colors.textTertiary).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if let meta = item.meta, !meta.isEmpty {
                    Text(meta).font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textTertiary)
                }
            }
            .padding(.horizontal, 4).padding(.vertical, FlareSizes.spacingSm)
        }
        .buttonStyle(.plain)
    }

    private func highlighted(_ s: String, _ colors: FlareColors) -> Text {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return Text(s) }
        var result = Text("")
        var remainder = Substring(s)
        while let range = remainder.range(of: q, options: .caseInsensitive) {
            let before = remainder[remainder.startIndex..<range.lowerBound]
            if !before.isEmpty { result = result + Text(String(before)) }
            result = result + Text(String(remainder[range])).foregroundColor(colors.primary).bold()
            remainder = remainder[range.upperBound...]
        }
        if !remainder.isEmpty { result = result + Text(String(remainder)) }
        return result
    }
}

// MARK: - Skeleton

/// Skeleton placeholder — shimmering loading blocks for common layouts.
/// Spec: General/Skeleton (`SkeletonView`).
public enum SkeletonVariant: Sendable { case conversation, message, profile, text }

public struct SkeletonView: View {
    private let variant: SkeletonVariant
    private let rows: Int
    private let still: Bool
    @Environment(\.colorScheme) private var scheme
    @State private var animating = false

    public init(variant: SkeletonVariant = .conversation, rows: Int = 4, still: Bool = false) {
        self.variant = variant; self.rows = rows; self.still = still
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        Group {
            switch variant {
            case .conversation: conversation(colors)
            case .message: message(colors)
            case .profile: profile(colors)
            case .text: text(colors)
            }
        }
        .onAppear { if !still { animating = true } }
    }

    private func block(_ colors: FlareColors, width: CGFloat? = nil, height: CGFloat, radius: CGFloat = 6) -> some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(colors.bgSecondary)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
            .overlay(shimmer(radius: radius))
            .clipShape(RoundedRectangle(cornerRadius: radius))
    }

    @ViewBuilder
    private func shimmer(radius: CGFloat) -> some View {
        if still {
            EmptyView()
        } else {
            GeometryReader { geo in
                LinearGradient(colors: [.clear, Color.white.opacity(0.18), .clear],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: animating ? geo.size.width : -geo.size.width * 0.6)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false), value: animating)
            }
        }
    }

    private func circle(_ colors: FlareColors, _ size: CGFloat) -> some View {
        Circle().fill(colors.bgSecondary).frame(width: size, height: size)
            .overlay(shimmer(radius: size / 2)).clipShape(Circle())
    }

    private func conversation(_ colors: FlareColors) -> some View {
        VStack(spacing: 14) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: FlareSizes.spacingMd) {
                    circle(colors, 44)
                    VStack(alignment: .leading, spacing: 8) {
                        block(colors, width: 120, height: 11)
                        block(colors, width: 190, height: 11)
                    }
                    Spacer()
                    block(colors, width: 34, height: 11)
                }
            }
        }
        .padding(FlareSizes.spacingLg)
    }

    private func message(_ colors: FlareColors) -> some View {
        VStack(spacing: 16) {
            ForEach(0..<rows, id: \.self) { i in
                let isSelf = i % 2 == 1
                HStack(alignment: .bottom, spacing: FlareSizes.spacingSm) {
                    if isSelf { Spacer() }
                    if !isSelf { circle(colors, 32) }
                    block(colors, width: isSelf ? 160 : 200, height: 40, radius: FlareSizes.radiusLg)
                    if !isSelf { Spacer() }
                }
            }
        }
        .padding(FlareSizes.spacingLg)
    }

    private func profile(_ colors: FlareColors) -> some View {
        VStack(spacing: 12) {
            circle(colors, 72)
            block(colors, width: 120, height: 15)
            block(colors, width: 180, height: 11)
        }
        .frame(maxWidth: .infinity)
        .padding(FlareSizes.spacingLg)
    }

    private func text(_ colors: FlareColors) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<rows, id: \.self) { i in
                block(colors, width: i == rows - 1 ? 160 : nil, height: 11)
            }
        }
        .padding(FlareSizes.spacingLg)
    }
}
