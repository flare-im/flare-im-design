import SwiftUI

// MARK: - AnnouncementBanner

/// Announcement banner — group notice with expand / collapse + dismiss.
/// Spec: Chat/AnnouncementBanner (`AnnouncementBannerView`).
public struct AnnouncementBannerView: View {
    private let text: String
    private let author: String?
    private let collapsible: Bool
    private let dismissible: Bool
    private let onClose: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @State private var expanded = false

    public init(text: String, author: String? = nil, collapsible: Bool = true,
                dismissible: Bool = false, onClose: (() -> Void)? = nil) {
        self.text = text; self.author = author; self.collapsible = collapsible
        self.dismissible = dismissible; self.onClose = onClose
    }

    private var canToggle: Bool { collapsible && text.count > 40 }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(alignment: .top, spacing: FlareSizes.spacingMd) {
            Image(systemName: "megaphone.fill").font(.system(size: 13)).foregroundColor(.white)
                .frame(width: 26, height: 26)
                .background(RoundedRectangle(cornerRadius: 8).fill(
                    LinearGradient(colors: [colors.primary, colors.primary.opacity(0.82)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 0) {
                    Text("群公告").font(.system(size: 12, weight: .semibold)).foregroundColor(colors.primary)
                    if let a = author, !a.isEmpty {
                        Text(" · \(a)").font(.system(size: 12)).foregroundColor(colors.textTertiary)
                    }
                }
                Text(text).font(.system(size: 13)).foregroundColor(colors.textPrimary)
                    .lineLimit(canToggle && !expanded ? 1 : nil)
                if canToggle {
                    Button { expanded.toggle() } label: {
                        HStack(spacing: 3) {
                            Text(expanded ? "收起" : "展开").font(.system(size: FlareSizes.fontSizeMd, weight: .medium))
                            Image(systemName: "chevron.down").font(.system(size: 10))
                                .rotationEffect(.degrees(expanded ? 180 : 0))
                        }.foregroundColor(colors.primary)
                    }.buttonStyle(.plain)
                }
            }

            if dismissible {
                Button { onClose?() } label: {
                    Image(systemName: "xmark").font(.system(size: 13)).foregroundColor(colors.textTertiary)
                }.buttonStyle(.plain)
            }
        }
        .padding(.vertical, 11).padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSelected)
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.primary.opacity(0.22), lineWidth: 1)))
    }
}
