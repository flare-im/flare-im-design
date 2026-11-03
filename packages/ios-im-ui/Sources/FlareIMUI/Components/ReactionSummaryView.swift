import SwiftUI

// MARK: - ReactionSummary

/// Reaction summary — wrapping row of emoji pills + add button.
/// Spec: Message/ReactionSummary (`ReactionSummaryView`).
public struct ReactionSummaryView: View {
    private let reactions: [ReactionGroup]
    private let hideAdd: Bool
    private let onToggle: ((String) -> Void)?
    private let onAdd: (() -> Void)?
    var messageSurface: AnyView?
    var messageMeta: MessageMetaView?
    var isOutgoing = false
    static let visualHeight: CGFloat = 22
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(reactions: [ReactionGroup], hideAdd: Bool = false,
                onToggle: ((String) -> Void)? = nil, onAdd: (() -> Void)? = nil) {
        self.reactions = reactions; self.hideAdd = hideAdd; self.onToggle = onToggle; self.onAdd = onAdd
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        if !reactions.isEmpty || !hideAdd {
            FlareFlowLayout(
                spacing: FlareSizes.spacingXs,
                lineSpacing: FlareSizes.spacingXs,
                alignment: isOutgoing ? .trailing : .leading,
                trailingLast: messageMeta != nil,
                constrainSubviews: true,
                surfaceSpacing: messageSurface == nil ? nil : FlareSizes.spacingXs,
                topAligned: true
            ) {
                if let messageSurface { messageSurface }
                ForEach(reactions) { r in pill(colors, r) }
                if !hideAdd { addPill(colors) }
                if let messageMeta { messageMeta }
            }
        }
    }

    @ViewBuilder
    private func pill(_ colors: FlareColors, _ r: ReactionGroup) -> some View {
        // A pill is a button only when the host toggles reactions; otherwise it is a label,
        // so assistive technology does not announce a control that does nothing.
        if let onToggle {
            Button { onToggle(r.emoji) } label: {
                pillLabel(colors, r)
                    .flareTouchTarget(alignment: isOutgoing ? .topTrailing : .topLeading)
            }
                .buttonStyle(.plain)
                .accessibilityAddTraits(r.reactedBySelf ? .isSelected : [])
        } else {
            pillLabel(colors, r)
                .frame(minHeight: FlareSizes.touchTargetMin, alignment: .top)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(r.reactedBySelf ? .isSelected : [])
        }
    }

    private func pillLabel(_ colors: FlareColors, _ r: ReactionGroup) -> some View {
        let selected = r.reactedBySelf
        return HStack(spacing: FlareSizes.spacingXs) {
            Text(r.emoji).font(.system(size: FlareSizes.fontSizeLg))
            Text("\(r.count)").font(.system(size: FlareSizes.fontSizeSm, weight: .medium))
        }
        .foregroundColor(selected ? colors.primaryText : colors.textSecondary)
        .padding(.horizontal, FlareSizes.spacingSm)
        .frame(minWidth: FlareSizes.touchTargetMin, minHeight: Self.visualHeight)
        .background(Capsule().fill(selected ? colors.messageReactionSelected : colors.messageReactionBackground))
        .overlay(Capsule().stroke(selected ? colors.primary : colors.borderPrimary, lineWidth: 1))
    }

    private func addPill(_ colors: FlareColors) -> some View {
        Button { onAdd?() } label: {
            Image(systemName: flareIconSymbol("reaction")).font(.system(size: 15)).foregroundColor(colors.textTertiary)
                .padding(.horizontal, FlareSizes.spacingSm)
                .frame(minWidth: FlareSizes.touchTargetMin, minHeight: Self.visualHeight)
                .background(Capsule().fill(colors.messageReactionBackground))
                .overlay(Capsule().stroke(colors.borderPrimary, lineWidth: 1))
                .flareTouchTarget(alignment: .topLeading)
        }
        .buttonStyle(.plain)
        .disabled(onAdd == nil)
        .accessibilityLabel(strings.addReaction)
    }
}
