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
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(reactions: [ReactionGroup], hideAdd: Bool = false,
                onToggle: ((String) -> Void)? = nil, onAdd: (() -> Void)? = nil) {
        self.reactions = reactions; self.hideAdd = hideAdd; self.onToggle = onToggle; self.onAdd = onAdd
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        // Wrapping flow (6pt gaps both axes), not a horizontal scroller — Android / Flutter parity.
        if !(reactions.isEmpty && hideAdd) {
            FlareFlowLayout(spacing: 6, lineSpacing: 6) {
                ForEach(reactions) { r in pill(colors, r) }
                if !hideAdd { addPill(colors) }
            }
        }
    }

    @ViewBuilder
    private func pill(_ colors: FlareColors, _ r: ReactionGroup) -> some View {
        // A pill is a button only when the host toggles reactions; otherwise it is a label,
        // so assistive technology does not announce a control that does nothing.
        if let onToggle {
            Button { onToggle(r.emoji) } label: { pillLabel(colors, r) }
                .buttonStyle(.plain)
                .accessibilityAddTraits(r.reactedBySelf ? .isSelected : [])
        } else {
            pillLabel(colors, r).accessibilityElement(children: .combine)
        }
    }

    private func pillLabel(_ colors: FlareColors, _ r: ReactionGroup) -> some View {
        let selected = r.reactedBySelf
        return HStack(spacing: 4) {
            Text(r.emoji).font(.system(size: FlareSizes.fontSizeLg))
            Text("\(r.count)").font(.system(size: FlareSizes.fontSizeSm, weight: .medium))
        }
        .foregroundColor(selected ? colors.primaryText : colors.textSecondary)
        .padding(.horizontal, 9)
        .frame(height: 26)
        .background(Capsule().fill(selected ? colors.messageReactionSelected : colors.messageReactionBackground))
        .overlay(Capsule().stroke(selected ? colors.primary : colors.borderPrimary, lineWidth: 1))
    }

    private func addPill(_ colors: FlareColors) -> some View {
        Button { onAdd?() } label: {
            Image(systemName: flareIconSymbol("reaction")).font(.system(size: 15)).foregroundColor(colors.textTertiary)
                .padding(.horizontal, 9)
                .frame(height: 26)
                .background(Capsule().fill(colors.messageReactionBackground))
                .overlay(Capsule().stroke(colors.borderPrimary, lineWidth: 1))
                // The pill keeps the 26pt row of reactions and its place at the start of its slot; the
                // 44pt target reaches above and below the row.
                .flareTouchTarget(alignment: .leading)
        }
        .buttonStyle(.plain)
        .flareCompactLayout(height: 26)
        .accessibilityLabel(strings.addReaction)
    }
}
