import SwiftUI

/// One row of an ``ActivityListView``: a notification about the viewer (a like, a comment, a reply). Everything is the
/// host's — the words, the time already formatted, the avatar, and whether it is unread.
public struct FlareActivityItem: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let description: String?
    public let time: String?
    public let avatarURL: String?
    public let unread: Bool

    public init(id: String, title: String, description: String? = nil, time: String? = nil, avatarURL: String? = nil,
                unread: Bool = false) {
        self.id = id; self.title = title; self.description = description; self.time = time
        self.avatarURL = avatarURL; self.unread = unread
    }
}

/// Activity list — presentational notification rows (the Vue / Flutter `FlareActivityList` contract): avatar, title
/// (heavier while unread), up to two lines of description, the time, and a dot at the end of an unread row. The host
/// owns recipients, read state and counts; the list keeps none. A row is a button only with `onSelect`; with no items
/// it shows the empty state (its action only with `onEmptyAction`). `footer` follows the rows (load more, an end line).
/// Spec: General/ActivityList (`ActivityListView`).
public struct ActivityListView<Footer: View>: View {
    private let items: [FlareActivityItem]
    private let emptyText: String
    private let emptyDescription: String?
    private let emptyActionText: String?
    private let compact: Bool
    private let disabled: Bool
    private let onSelect: ((String) -> Void)?
    private let onEmptyAction: (() -> Void)?
    private let footer: Footer
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(items: [FlareActivityItem], emptyText: String, emptyDescription: String? = nil,
                emptyActionText: String? = nil, compact: Bool = false, disabled: Bool = false,
                onSelect: ((String) -> Void)? = nil, onEmptyAction: (() -> Void)? = nil,
                @ViewBuilder footer: () -> Footer = { EmptyView() }) {
        self.items = items; self.emptyText = emptyText; self.emptyDescription = emptyDescription
        self.emptyActionText = emptyActionText; self.compact = compact; self.disabled = disabled
        self.onSelect = onSelect; self.onEmptyAction = onEmptyAction; self.footer = footer()
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        if items.isEmpty {
            EmptyStateView(title: emptyText, description: emptyDescription,
                           actionText: onEmptyAction == nil ? nil : emptyActionText, icon: "notification",
                           onAction: onEmptyAction)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Divider().overlay(colors.borderSecondary)
                            .padding(.leading, FlareSizes.spacingLg + avatarSize + FlareSizes.spacingMd)
                    }
                    if let onSelect {
                        Button { onSelect(item.id) } label: { row(item, colors) }
                            .buttonStyle(.plain)
                            .disabled(disabled)
                    } else {
                        row(item, colors).accessibilityElement(children: .combine)
                    }
                }
                footer
            }
        }
    }

    private var avatarSize: CGFloat { compact ? 32 : 40 }

    private func row(_ item: FlareActivityItem, _ colors: FlareColors) -> some View {
        HStack(alignment: .top, spacing: FlareSizes.spacingMd) {
            AvatarView(userId: item.id, displayName: item.title, avatarURL: item.avatarURL, size: avatarSize)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: FlareSizes.fontSizeLg, weight: item.unread ? .semibold : .regular))
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(2)
                if let description = item.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: FlareSizes.fontSizeMd))
                        .foregroundColor(colors.textSecondary)
                        .lineLimit(2)
                }
                if let time = item.time, !time.isEmpty {
                    Text(time)
                        .font(.system(size: FlareSizes.fontSizeSm))
                        .foregroundColor(colors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if item.unread {
                Circle().fill(colors.error).frame(width: 8, height: 8).padding(.top, 6).accessibilityHidden(true)
            }
        }
        .padding(.horizontal, FlareSizes.spacingLg)
        .padding(.vertical, compact ? FlareSizes.spacingSm : FlareSizes.spacingMd)
        .contentShape(Rectangle())
        .accessibilityLabel(Self.spokenLabel(item, unreadSuffix: strings.activityListUnreadSuffix))
    }

    /// Title (with the unread suffix), description and time, as VoiceOver reads the row.
    static func spokenLabel(_ item: FlareActivityItem, unreadSuffix: String) -> String {
        [item.title + (item.unread ? unreadSuffix : ""), item.description, item.time]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    }
}
