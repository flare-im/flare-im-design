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
