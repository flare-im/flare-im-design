import SwiftUI

/// How an action ended (R7 of docs/plugin-experience.md). Spec: Plugin/ResultView (`FlareResultView`), also the
/// renderer of a plugin view's `result` block.
///
/// A tone icon (success → success, info → clock, warning → warning, danger → error, neutral → info) in a
/// `component.resultIconSize` circle of the tone at `opacity.tintWeak`, the title (title role, centred), the amount
/// (`component.amountHeroFontSize`, tabular), up to three lines of description, the details as label/value rows, then
/// the done key (primary) and an optional secondary key. The column is at most `component.formColumnWidth`, centred.
/// The title and description are announced politely when they change.
public struct FlareResultView: View {
    private let title: String
    private let tone: PluginTone
    private let amount: String?
    private let description: String?
    private let details: [PluginViewField]
    private let doneLabel: String?
    private let secondaryLabel: String?
    private let busy: Bool
    private let onDone: (() -> Void)?
    private let onSecondary: (() -> Void)?
    private let actions: AnyView?
    @State private var shown = false
    @ScaledMetric(relativeTo: .title) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - actions: Keys after the done key (a plugin view's own actions as secondary keys); the contract's slot.
    public init(title: String, tone: PluginTone = .neutral, amount: String? = nil, description: String? = nil,
                details: [PluginViewField] = [], doneLabel: String? = nil, secondaryLabel: String? = nil,
                busy: Bool = false, onDone: (() -> Void)? = nil, onSecondary: (() -> Void)? = nil,
                actions: AnyView? = nil) {
        self.title = title; self.tone = tone; self.amount = amount; self.description = description
        self.details = details; self.doneLabel = doneLabel; self.secondaryLabel = secondaryLabel; self.busy = busy
        self.onDone = onDone; self.onSecondary = onSecondary; self.actions = actions
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let ink = pluginToneText(tone, colors)
        let announce = [title, description ?? ""].filter { !$0.isEmpty }.joined(separator: " ")
        VStack(spacing: FlareSizes.spacingLg) {
            VStack(spacing: FlareSizes.spacingSm) {
                FlareIconImage(name: PluginExperienceRules.resultIcon(tone), size: FlareSizes.iconSizeXl, weight: .semibold)
                    .foregroundColor(ink)
                    .frame(width: FlareSizes.componentResultIconSize, height: FlareSizes.componentResultIconSize)
                    .background(Circle().fill(pluginToneFill(tone, colors).opacity(FlareOpacity.tintWeak)))
                    .scaleEffect(shown || reduceMotion ? 1 : 0.6)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.system(size: FlareTextRoles.title.fontSize * textScale, weight: .bold))
                    .foregroundColor(colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                if let amount, !amount.isEmpty {
                    Text(amount)
                        .font(.system(size: FlareSizes.componentAmountHeroFontSize * textScale, weight: .bold).monospacedDigit())
                        .foregroundColor(colors.textPrimary)
                        .lineLimit(1).minimumScaleFactor(0.5)
                }
                if let description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: FlareSizes.fontSizeLg * textScale))
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            // R3: reference fields leave the details for the folded "单号与凭据" with copy keys.
            let split = PluginExperienceRules.splitReferences(details)
            if !split.main.isEmpty {
                PluginDescriptionRows(fields: split.main)
                    .padding(FlareSizes.spacingLg)
                    .background(RoundedRectangle(cornerRadius: FlareSizes.radiusCard, style: .continuous).fill(colors.bgSecondary))
            }
            if !split.references.isEmpty { PluginReferenceRows(fields: split.references) }
            VStack(spacing: FlareSizes.spacingSm) {
                if let onDone {
                    // R7: full width on touch; on a pointer centred at the result action width.
                    let pointer = FlarePluginPage.refreshKeyInHeader
                    ButtonView(label: doneLabel ?? strings.pluginViewDone, size: .lg, disabled: busy, block: true, action: onDone)
                        .frame(maxWidth: pointer ? FlareSizes.componentResultActionWidth : .infinity)
                }
                if let secondaryLabel, let onSecondary {
                    ButtonView(label: secondaryLabel, variant: .secondary, size: .lg, disabled: busy, block: true,
                               action: onSecondary)
                }
                if let actions { actions }
            }
        }
        .frame(maxWidth: FlareSizes.componentFormColumnWidth)
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring()) { shown = true }
            flareAnnounce(announce)
        }
        .onChange(of: announce) { flareAnnounce($0) }
    }
}

/// The fill colour of a tone (its tint is drawn at an opacity over it).
func pluginToneFill(_ tone: PluginTone, _ colors: FlareColors) -> Color {
    switch tone {
    case .neutral: return colors.textSecondary
    case .info: return colors.info
    case .success: return colors.success
    case .warning: return colors.warning
    case .danger: return colors.error
    }
}

/// Label left, value right (the kit description list), a toned value as its Tag.
struct PluginDescriptionRows: View {
    let fields: [PluginViewField]
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(spacing: FlareSizes.spacingSm) {
            ForEach(Array(fields.enumerated()), id: \.offset) { _, field in
                HStack(alignment: .firstTextBaseline, spacing: FlareSizes.spacingMd) {
                    Text(field.label).font(.system(size: FlareSizes.fontSizeMd * textScale))
                        .foregroundColor(colors.textSecondary)
                    Spacer(minLength: FlareSizes.spacingSm)
                    PluginFieldValue(field: field, alignment: .trailing)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
