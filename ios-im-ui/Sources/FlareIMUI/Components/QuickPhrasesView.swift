import SwiftUI

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
                Text("快捷短语").font(.system(size: FlareSizes.fontSizeXl, weight: .semibold)).foregroundColor(colors.textPrimary)
                Spacer()
                if manageable {
                    Button { onManage?() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.pencil").font(.system(size: 13))
                            Text("管理").font(.system(size: FlareSizes.fontSizeMd, weight: .medium))
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
