import SwiftUI

// MARK: - Size helpers

extension FlareControlSize {
    /// Control height. sm 32 / md 40 / lg 48.
    var height: CGFloat { self == .sm ? FlareSizes.controlHeightSm : self == .md ? FlareSizes.controlHeightMd : FlareSizes.controlHeightLg }
    /// Square (icon-button) side. 30 / 38 / 46.
    var square: CGFloat { self == .sm ? FlareSizes.componentIconButtonSideSm : self == .md ? FlareSizes.componentIconButtonSideMd : FlareSizes.componentIconButtonSideLg }
    /// Horizontal padding for text buttons. 12 / 18 / 24.
    var hPadding: CGFloat { self == .sm ? FlareSizes.controlPadXSm : self == .md ? FlareSizes.controlPadXMd : FlareSizes.controlPadXLg }
    /// Horizontal padding for select triggers. 10 / 12 / 14.
    var triggerPadding: CGFloat { self == .sm ? 10 : self == .md ? 12 : 14 }
    /// Label font size. 13 / 14 / 15.
    var font: CGFloat { self == .sm ? FlareSizes.fontSizeMd : self == .md ? FlareSizes.fontSizeLg : FlareSizes.fontSizeXl }
    /// Icon-button glyph size. 16 / 19 / 22.
    var glyph: CGFloat { self == .sm ? FlareSizes.componentIconButtonGlyphSm : self == .md ? FlareSizes.componentIconButtonGlyphMd : FlareSizes.componentIconButtonGlyphLg }
}

/// General-purpose button. Spec: Form/Button (`ButtonView`).
/// Five variants (`primary` brand fill, `secondary` outline, `ghost` tinted outline,
/// `danger` error fill, `text` link), three sizes, plus loading / disabled / block / icon.
public enum FlareButtonAppearance: Sendable { case standard, text }

public struct ButtonView: View {
    private let label: String?
    private let appearance: FlareButtonAppearance
    private let variant: FlareButtonVariant
    private let size: FlareControlSize
    private let loading: Bool
    private let disabled: Bool
    private let block: Bool
    private let maintainTouchTarget: Bool
    /// Semantic kit icon name (``flareIconNames``) before the label; nil draws none.
    private let icon: String?
    private let action: (() -> Void)?
    @FocusState private var focused: Bool
    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(label: String? = nil, variant: FlareButtonVariant = .primary,
                size: FlareControlSize = .md, loading: Bool = false, disabled: Bool = false,
                block: Bool = false, icon: String? = nil, appearance: FlareButtonAppearance = .standard,
                maintainTouchTarget: Bool = false, action: (() -> Void)? = nil) {
        self.appearance = appearance; self.label = label; self.variant = variant; self.size = size; self.loading = loading
        self.disabled = disabled; self.block = block; self.icon = icon; self.action = action
        self.maintainTouchTarget = maintainTouchTarget
    }

    private func fill(_ colors: FlareColors) -> Color {
        if appearance == .text {
            return focused && !disabled && !loading && action != nil ? fg(colors).opacity(0.1) : .clear
        }
        switch variant {
        case .primary: return colors.primary
        case .danger: return colors.error
        case .secondary: return colors.bgSecondary
        case .ghost, .text, .quiet: return .clear
        }
    }

    /// The fill under a pointer or a press (§7): primary takes `primaryHover` / `primaryActive` (a red packet key's
    /// tint maps them to `redPacketEndHover` / `redPacketEndActive`), danger `errorHover` / `errorActive`, the quiet
    /// variants `bgHover`, a text key a faint wash of its ink.
    static func feedbackFill(variant: FlareButtonVariant, appearance: FlareButtonAppearance, pressed: Bool,
                             base: Color, ink: Color, colors: FlareColors) -> Color {
        if appearance == .text { return ink.opacity(FlareOpacity.tintWeak) }
        switch variant {
        case .primary: return pressed ? colors.primaryActive : colors.primaryHover
        case .danger: return pressed ? colors.errorActive : colors.errorHover
        case .secondary, .ghost, .text, .quiet: return colors.bgHover
        }
    }

    private func stroke(_ colors: FlareColors) -> Color {
        if appearance == .text {
            return focused && contrast == .increased ? fg(colors) : .clear
        }
        switch variant {
        case .secondary: return colors.borderPrimary
        case .ghost: return colors.primary.opacity(0.4)
        default: return .clear
        }
    }

    private func fg(_ colors: FlareColors) -> Color {
        if appearance == .text {
            switch variant {
            case .primary, .text, .ghost: return colors.primaryText
            case .danger: return colors.errorText
            default: return colors.textSecondary
            }
        }
        // ghost / text 的**文字**要取 primaryText 而不是 primary。两者是一对的两半:
        // 浅色下同为 #7047D6 所以看不出来,暗色下 primary 不变(在 #20232B 上 2.66:1,
        // AA 正文要 4.5)而 primaryText 提亮成 #A78BFA(5.77:1)。描边仍用 primary —— 描边是填充。
        switch variant {
        case .primary, .danger: return .white
        case .secondary: return colors.textPrimary
        case .ghost, .text: return colors.primaryText
        case .quiet: return colors.textSecondary
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let solid = appearance != .text && (variant == .primary || variant == .danger)
        Button { action?() } label: {
            HStack(spacing: FlareSizes.spacingSm) {
                if loading {
                    ProgressView().controlSize(.small).tint(solid ? .white : colors.primaryText)
                } else if let icon {
                    FlareIconImage(name: icon, size: size.font + 4, weight: .semibold)
                }
                if let label {
                    Text(label).font(.system(size: size.font * textScale, weight: appearance == .text && focused ? .bold : .semibold))
                        .underline(false)
                }
            }
            .foregroundColor(fg(colors))
            .frame(maxWidth: block ? .infinity : nil)
            .padding(.vertical, FlareSizes.spacing2xs)
            .frame(minHeight: size.height)
            .padding(.horizontal, appearance == .text ? 0 : size.hPadding)
            .frame(minWidth: appearance == .text ? FlareSizes.touchTarget : nil,
                   minHeight: appearance == .text ? FlareSizes.touchTarget : nil)
            .background(FlareButtonFill(
                base: fill(colors),
                hover: Self.feedbackFill(variant: variant, appearance: appearance, pressed: false, base: fill(colors),
                                         ink: fg(colors), colors: colors),
                pressed: Self.feedbackFill(variant: variant, appearance: appearance, pressed: true, base: fill(colors),
                                           ink: fg(colors), colors: colors)))
            .overlay(
                RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                    .stroke(stroke(colors), lineWidth: 1)
            )
            .frame(minWidth: maintainTouchTarget ? FlareSizes.touchTarget : nil,
                   minHeight: maintainTouchTarget ? FlareSizes.touchTarget : nil)
            .contentShape(Rectangle())
        }
        .buttonStyle(FlareButtonFeedbackStyle())
        .focused($focused)
        .disabled(disabled || loading || action == nil)
        // The style dims a disabled button by half (web `--flare-opacity-disabled`), once.
    }
}

/// §7 button feedback: pressed scales to 0.98 and takes the pressed fill, a pointer over it the hover fill, both over
/// `FlareMotion.fast`; Reduce Motion keeps the colour and drops the scale; a disabled button gives none and is dimmed
/// by half. Sizes and hit areas are the label's own.
struct FlareButtonFeedbackStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Feedback(configuration: configuration) }

    /// The scale of a press (§7).
    static func scale(pressed: Bool, enabled: Bool, reduceMotion: Bool) -> CGFloat {
        enabled && pressed && !reduceMotion ? FlareSizes.componentPressScale : 1
    }

    private struct Feedback: View {
        let configuration: Configuration
        @State private var hovering = false
        @Environment(\.isEnabled) private var enabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            let pressed = enabled && configuration.isPressed
            configuration.label
                .environment(\.flareButtonFeedback, FlareButtonFeedback(pressed: pressed, hovering: enabled && hovering))
                .scaleEffect(FlareButtonFeedbackStyle.scale(pressed: configuration.isPressed, enabled: enabled,
                                                            reduceMotion: reduceMotion))
                .animation(FlareMotion.fastAnimation, value: pressed)
                .animation(FlareMotion.fastAnimation, value: hovering)
                .opacity(enabled ? 1 : FlareOpacity.disabled)
                .onHover { hovering = $0 }
        }
    }
}

/// What a kit button's fill shows now.
struct FlareButtonFeedback: Equatable {
    var pressed = false
    var hovering = false
}

private struct FlareButtonFeedbackKey: EnvironmentKey { static let defaultValue = FlareButtonFeedback() }

extension EnvironmentValues {
    var flareButtonFeedback: FlareButtonFeedback {
        get { self[FlareButtonFeedbackKey.self] }
        set { self[FlareButtonFeedbackKey.self] = newValue }
    }
}

/// A kit button's ground: its base fill, the hover fill under a pointer and the pressed fill while pressed.
struct FlareButtonFill: View {
    let base: Color
    let hover: Color
    let pressed: Color
    @Environment(\.flareButtonFeedback) private var feedback

    var body: some View {
        RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
            .fill(feedback.pressed ? pressed : feedback.hovering ? hover : base)
    }
}

/// Icon-only button. Spec: Form/IconButton (`IconButtonView`).
public enum IconButtonVariant: Sendable { case plain, tinted, solid }

private struct FlareHeaderIconScopeKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var flareHeaderIcons: Bool {
        get { self[FlareHeaderIconScopeKey.self] }
        set { self[FlareHeaderIconScopeKey.self] = newValue }
    }
}

public struct IconButtonView: View {
    /// Semantic kit icon name (``flareIconNames``); an unknown name draws the registry's fallback glyph.
    private let icon: String
    private let accessibilityLabel: String
    private let size: FlareControlSize
    private let variant: IconButtonVariant
    private let square: Bool
    private let disabled: Bool
    private let active: Bool
    private let tint: Color?
    private let background: Color?
    private let customSize: CGFloat?
    private let action: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareHeaderIcons) private var headerIcons
    @Environment(\.flareCompactOverlays) private var compactOverlays

    public init(icon: String, accessibilityLabel: String, size: FlareControlSize = .md,
                variant: IconButtonVariant = .plain, square: Bool = false, disabled: Bool = false,
                active: Bool = false, tint: Color? = nil, background: Color? = nil,
                customSize: CGFloat? = nil, action: (() -> Void)? = nil) {
        self.icon = icon; self.accessibilityLabel = accessibilityLabel; self.size = size
        self.variant = variant; self.square = square; self.disabled = disabled; self.active = active
        self.tint = tint; self.background = background; self.customSize = customSize
        self.action = action
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let largeHeader = headerIcons && compactOverlays
        let baseSide = customSize ?? size.square
        let side = largeHeader ? max(baseSide, FlareSizes.touchTarget) : baseSide
        let bg: Color = background ?? (active ? colors.bgSelected
            : variant == .solid ? colors.primary
            : variant == .tinted ? colors.bgSecondary
            : .clear)
        let fg: Color = tint ?? (variant == .solid ? .white
            : active ? colors.primary
            : colors.textSecondary)
        let baseGlyph = customSize.map { (($0 * 0.46).rounded()) } ?? size.glyph
        let glyphFloor = largeHeader ? FlareSizes.iconSizeLg : compactOverlays ? FlareSizes.iconSizeMd : 0
        let iconSize = max(baseGlyph, glyphFloor)
        // §12.10: hover and press change the ground (solid: primaryHover / primaryActive; others bgHover); a host's
        // own `background` keeps its colour and only scales.
        let hover: Color = background ?? (active ? colors.bgSelected : variant == .solid ? colors.primaryHover : colors.bgHover)
        let pressed: Color = background ?? (active ? colors.bgSelected : variant == .solid ? colors.primaryActive : colors.bgHover)
        Button { action?() } label: {
            FlareIconImage(name: icon, size: iconSize, weight: .medium)
                .foregroundColor(fg)
                .frame(width: side, height: side)
                // sm (30) and md (38) draw below the 44pt minimum; the target around them does not.
                .flareTouchTarget()
        }
        .buttonStyle(FlarePressStyle(fill: bg, pressed: pressed, size: side, hover: hover, shape: shape))
        .flareCompactLayout(width: side, height: side)
        .disabled(disabled || action == nil)
        .accessibilityLabel(accessibilityLabel)
        // `active` is the selected look, so it is also the selected state.
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    private var shape: AnyShape {
        square ? AnyShape(RoundedRectangle(cornerRadius: FlareSizes.radiusMd)) : AnyShape(Circle())
    }
}

// MARK: - Touch target

extension View {
    /// Applied to a button's label: the label grows to the 44pt minimum touch target
    /// (`FlareSizes.touchTargetMin`) on each axis, what it draws keeps its size and sits at `alignment`,
    /// and the whole frame takes the tap.
    ///
    /// SwiftUI hit-tests a button by the frame of its label, so this is the only way to a larger target:
    /// a background, overlay, inset content shape or negative padding reaching past the label is not
    /// hit, and neither is a frame set on the button from outside.
    func flareTouchTarget(alignment: Alignment = .center) -> some View {
        frame(minWidth: FlareSizes.touchTargetMin, minHeight: FlareSizes.touchTargetMin, alignment: alignment)
            .contentShape(Rectangle())
    }

    /// Applied to a button whose label is a ``flareTouchTarget(alignment:)``, where the design draws the
    /// control smaller than 44pt (a dock key, a stepper key, a thumbnail's remove badge): the layout
    /// gives the button `width` x `height` (nil leaves that axis at the target's size), so nothing around
    /// it moves, and the part of the 44pt target outside that box still takes taps, because the label
    /// keeps its own frame. Mind the neighbours: where two targets overlap, the later one wins.
    func flareCompactLayout(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        frame(width: width, height: height)
    }
}

/// Labelled form field wrapper. Spec: Form/FormField (`FormFieldView`).
/// Label (with optional required asterisk) + arbitrary control + hint / error footer.
public struct FormFieldView<Content: View>: View {
    private let label: String?
    private let required: Bool
    private let hint: String?
    private let error: String?
    private let counter: String?
    private let content: Content
    @ScaledMetric(relativeTo: .caption) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// - Parameter counter: R6: the "n/max" counter, under the control at the trailing end.
    public init(label: String? = nil, required: Bool = false, hint: String? = nil,
                error: String? = nil, counter: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label; self.required = required; self.hint = hint; self.error = error; self.counter = counter
        self.content = content()
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let caption = Font.system(size: FlareTextRoles.caption.fontSize * textScale)
        // R6: label 13/500 primary, `*` in the error colour read as "必填"; the error (icon 16 + caption) or the help
        // under the control, the counter at its end; the control draws the error outline and reads it as its hint.
        VStack(alignment: .leading, spacing: FlareSizes.spacing2xs) {
            if let label {
                HStack(spacing: FlareSizes.spacing3xs) {
                    Text(label).font(.system(size: FlareSizes.fontSizeMd * textScale, weight: .medium))
                        .foregroundColor(colors.textPrimary)
                    if required { Text("*").font(.system(size: FlareSizes.fontSizeMd * textScale, weight: .medium)).foregroundColor(colors.errorText) }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(required ? "\(label), \(strings.pluginFormRequired)" : label)
            }
            content.environment(\.flareFieldError, error)
            if error != nil || hint != nil || counter != nil {
                HStack(alignment: .firstTextBaseline, spacing: FlareSizes.spacingSm) {
                    if let error {
                        HStack(alignment: .firstTextBaseline, spacing: FlareSizes.spacingXs) {
                            FlareIconImage(name: "error", size: FlareSizes.iconSizeSm).accessibilityHidden(true)
                            Text(error).font(caption).fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundColor(colors.errorText)
                    } else if let hint {
                        Text(hint).font(caption).foregroundColor(colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    if let counter {
                        Text(counter).font(caption.monospacedDigit()).foregroundColor(colors.textSecondary)
                    }
                }
            }
        }
    }
}

private struct FlareFieldErrorKey: EnvironmentKey { static let defaultValue: String? = nil }

extension View {
    /// The kit focus ring: `component.focusRingWidth` of `color.border.selected` (§12.22), `component.focusRingOffset` outside the
    /// control's edge of `cornerRadius`; decoration only.
    func flareFocusRing(_ shown: Bool, cornerRadius: CGFloat, color: Color) -> some View {
        overlay(RoundedRectangle(cornerRadius: cornerRadius + FlareSizes.componentFocusRingOffset)
            .stroke(color, lineWidth: FlareSizes.componentFocusRingWidth)
            .padding(-FlareSizes.componentFocusRingOffset)
            .opacity(shown ? 1 : 0)
            .allowsHitTesting(false))
    }

    /// §12.22: an input's focus halo — `width` of `color.focusRing` just outside its edge (Vue `box-shadow: 0 0 0
    /// <width>px`), kept in error; decoration only, the 1px `border.selected` edge carries the contrast.
    func flareFocusHalo(_ shown: Bool, cornerRadius: CGFloat, color: Color,
                        width: CGFloat = FlareSizes.componentFocusRingWidth) -> some View {
        overlay(RoundedRectangle(cornerRadius: cornerRadius + width / 2)
            .stroke(color, lineWidth: width)
            .padding(-width / 2)
            .opacity(shown ? 1 : 0)
            .allowsHitTesting(false))
    }
}

extension EnvironmentValues {
    /// R6: the error of the field around a control — it draws the error outline and reads the text as its hint.
    var flareFieldError: String? {
        get { self[FlareFieldErrorKey.self] }
        set { self[FlareFieldErrorKey.self] = newValue }
    }
}

/// Custom on/off switch. Spec: Form/Switch (`SwitchView`).
public struct SwitchView: View {
    @Binding private var isOn: Bool
    private let disabled: Bool
    private let size: FlareControlSize

    public init(isOn: Binding<Bool>, disabled: Bool = false, size: FlareControlSize = .md) {
        self._isOn = isOn; self.disabled = disabled; self.size = size
    }

    public var body: some View {
        Toggle(isOn: $isOn) { EmptyView() }
            .toggleStyle(FlareSwitchStyle(size: size, fillsRow: false))
            .disabled(disabled)
            .opacity(disabled ? 0.5 : 1)
    }
}

/// The native Toggle owns state and accessibility. Its style draws the same track in both contexts.
struct FlareSwitchStyle: ToggleStyle {
    let size: FlareControlSize
    let fillsRow: Bool

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let geometry: (width: CGFloat, height: CGFloat, thumb: CGFloat)
        switch size {
        case .sm: geometry = (FlareSizes.componentSwitchWidthSm, FlareSizes.componentSwitchHeightSm, FlareSizes.componentSwitchThumbSm)
        case .md: geometry = (FlareSizes.componentSwitchWidthMd, FlareSizes.componentSwitchHeightMd, FlareSizes.componentSwitchThumbMd)
        case .lg: geometry = (FlareSizes.componentSwitchWidthLg, FlareSizes.componentSwitchHeightLg, FlareSizes.componentSwitchThumbLg)
        }

        return Button { configuration.isOn.toggle() } label: {
            HStack(spacing: 0) {
                if fillsRow {
                    configuration.label
                    Spacer(minLength: FlareSizes.spacingSm)
                }
                Capsule()
                    .fill(configuration.isOn ? colors.primary : colors.borderHover)
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: geometry.thumb, height: geometry.thumb)
                            .shadow(color: Color.black.opacity(0.28), radius: 3, y: 1)
                            .padding(.horizontal, (geometry.height - geometry.thumb) / 2)
                    }
                    .frame(width: geometry.width, height: geometry.height)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: configuration.isOn)
            }
            .frame(minWidth: FlareSizes.touchTarget, maxWidth: fillsRow ? .infinity : nil, minHeight: FlareSizes.touchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
        }
    }
}

/// Checkbox with optional label + indeterminate state. Spec: Form/Checkbox (`CheckboxView`).
public struct CheckboxView: View {
    @Binding private var isOn: Bool
    private let label: String?
    private let indeterminate: Bool
    private let disabled: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(isOn: Binding<Bool>, label: String? = nil, indeterminate: Bool = false, disabled: Bool = false) {
        self._isOn = isOn; self.label = label; self.indeterminate = indeterminate; self.disabled = disabled
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let filled = isOn || indeterminate
        Button { isOn.toggle() } label: {
          HStack(spacing: FlareSizes.spacingSm) {
            RoundedRectangle(cornerRadius: FlareSizes.radiusSm)
                .fill(filled ? colors.primary : colors.bgPrimary)
                .frame(width: FlareSizes.iconSizeMd, height: FlareSizes.iconSizeMd)
                .overlay(
                    RoundedRectangle(cornerRadius: FlareSizes.radiusSm)
                        .stroke(filled ? colors.primary : colors.borderHover, lineWidth: 1.5)
                )
                .overlay(
                    Group {
                        if indeterminate {
                            Image(systemName: "minus").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                        } else if isOn {
                            Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                        }
                    }
                )
            if let label {
                Text(label).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary)
            }
          }
          .frame(minWidth: FlareSizes.touchTarget, minHeight: FlareSizes.touchTarget)
          .contentShape(Rectangle())
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: filled)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : [.isButton])
    }
}

/// How a radio group lays its options: compact dots (the default), a list, or cards — one 48-high card per option,
/// the chosen one outlined `border.selected` with a check (R6, ≤ 4 options; vertical on a phone).
public enum FlareRadioOptionLayout: Sendable { case compact, list, cards }

/// Single-select radio group (horizontal or vertical). Spec: Form/RadioGroup (`RadioGroupView`).
public struct RadioGroupView: View {
    private let options: [FlareSelectOption]
    @Binding private var selection: String
    private let vertical: Bool
    private let optionLayout: FlareRadioOptionLayout
    private let grouped: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1

    public init(options: [FlareSelectOption], selection: Binding<String>, vertical: Bool = false,
                optionLayout: FlareRadioOptionLayout = .compact, grouped: Bool = false) {
        self.options = options; self._selection = selection; self.optionLayout = optionLayout
        self.vertical = vertical || optionLayout == .list
        self.grouped = grouped && optionLayout == .list
    }

    public var body: some View {
        if grouped { groupedRows } else if optionLayout == .cards { cards } else { dots }
    }

    private var groupedRows: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusLg, style: .continuous)
        return VStack(spacing: 0) {
            ForEach(options) { option in
                let selected = option.value == selection
                if option.id != options.first?.id { Rectangle().fill(colors.borderSecondary).frame(height: 1) }
                Button { selection = option.value } label: {
                    HStack(spacing: FlareSizes.spacingSm) {
                        VStack(alignment: .leading, spacing: FlareSizes.spacing3xs) {
                            Text(option.label)
                                .font(.system(size: FlareSizes.fontSizeLg * textScale, weight: .semibold))
                                .foregroundColor(selected ? colors.primaryText : colors.textPrimary)
                            if let description = option.description {
                                Text(description).font(.system(size: FlareSizes.fontSizeSm * textScale))
                                    .foregroundColor(colors.textSecondary)
                            }
                        }
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if selected {
                            FlareIconImage(name: "check", size: FlareSizes.iconSizeSm, weight: .semibold)
                                .foregroundColor(colors.primaryText).accessibilityHidden(true)
                        }
                    }
                    .padding(.horizontal, FlareSizes.spacingMd)
                    .padding(.vertical, FlareSizes.spacingSm)
                    .frame(minHeight: FlareSizes.touchTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(option.disabled)
                .opacity(option.disabled ? FlareOpacity.disabled : 1)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .background(shape.fill(colors.bgElevated))
        .clipShape(shape)
        .overlay(shape.strokeBorder(colors.borderPrimary).allowsHitTesting(false))
    }

    private var cards: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusLg, style: .continuous)
        let layout = vertical ? AnyLayout(VStackLayout(spacing: FlareSizes.spacingSm))
                              : AnyLayout(HStackLayout(spacing: FlareSizes.spacingSm))
        return layout {
            ForEach(options) { option in
                let selected = option.value == selection
                Button { selection = option.value } label: {
                    HStack(spacing: FlareSizes.spacingSm) {
                        Text(option.label).font(.system(size: FlareSizes.fontSizeLg * textScale, weight: selected ? .semibold : .regular))
                            .foregroundColor(colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if selected {
                            FlareIconImage(name: "check", size: FlareSizes.iconSizeSm, weight: .semibold)
                                .foregroundColor(colors.primaryText).accessibilityHidden(true)
                        }
                    }
                    .padding(.horizontal, FlareSizes.spacingMd)
                    .frame(maxWidth: .infinity, minHeight: FlareSizes.controlHeightLg)
                    .background(shape.fill(selected ? colors.bgSelected : colors.bgSecondary))
                    .overlay(shape.stroke(selected ? colors.borderSelected : colors.borderPrimary, lineWidth: selected ? 1.5 : 1)
                        .allowsHitTesting(false))
                    .contentShape(shape)
                }
                .buttonStyle(.plain)
                .disabled(option.disabled)
                .opacity(option.disabled ? FlareOpacity.disabled : 1)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: selection)
    }

    private var dots: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let layout = AnyLayout(vertical ? AnyLayout(VStackLayout(alignment: .leading, spacing: FlareSizes.spacingMd))
                                        : AnyLayout(HStackLayout(spacing: 18)))
        return layout {
            ForEach(options) { option in
                let selected = option.value == selection
                Button { selection = option.value } label: {
                  HStack(spacing: FlareSizes.spacingSm) {
                    ZStack {
                        Circle().stroke(selected ? colors.primary : colors.borderHover, lineWidth: 1.5)
                            .frame(width: FlareSizes.componentRadioIndicator, height: FlareSizes.componentRadioIndicator)
                        if selected {
                            Circle().fill(colors.primary).frame(width: FlareSizes.componentRadioDot, height: FlareSizes.componentRadioDot)
                        }
                    }
                    Text(option.label).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary)
                }
                  .frame(minWidth: FlareSizes.touchTarget, minHeight: FlareSizes.touchTarget)
                  .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(option.disabled)
                .opacity(option.disabled ? 0.5 : 1)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: selection)
    }
}

/// Select with a token-styled trigger that presents its options as a bottom sheet.
/// Spec: Form/Select (`SelectView`). A native app is always mobile, so the adaptive
/// contract resolves to the H5/native bottom-sheet presentation (not the desktop dropdown).
public struct SelectView: View {
    private let options: [FlareSelectOption]
    @Binding private var selection: String
    private let placeholder: String?
    private let title: String?
    private let size: FlareControlSize
    private let disabled: Bool
    @State private var open = false
    /// R6: the error of the ``FormFieldView`` around it: the error outline, read as the field's hint.
    @Environment(\.flareFieldError) private var fieldError
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1

    public init(options: [FlareSelectOption], selection: Binding<String>, placeholder: String? = nil,
                title: String? = nil, size: FlareControlSize = .md, disabled: Bool = false) {
        self.options = options; self._selection = selection; self.placeholder = placeholder
        self.title = title; self.size = size; self.disabled = disabled
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let selectedLabel = options.first { $0.value == selection }?.label
        Button {
            if !disabled { open = true }
        } label: {
            HStack(spacing: FlareSizes.spacingSm) {
                Text(selectedLabel ?? placeholder ?? "")
                    .font(.system(size: size.font * textScale))
                    .foregroundColor(selectedLabel == nil ? colors.textTertiary : colors.textPrimary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colors.textTertiary)
                    .rotationEffect(.degrees(open ? 180 : 0))
            }
            .frame(minHeight: max(44, size.height))
            .padding(.vertical, FlareSizes.spacingXs)
            .padding(.horizontal, size.triggerPadding)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
            .overlay(
                RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                    .stroke(fieldError != nil ? colors.error : open ? colors.borderSelected : colors.borderPrimary, lineWidth: 1)
            )
            // §12.22: open, the 1px border.selected edge plus a 3 focusRing halo (Vue Select).
            .flareFocusHalo(open, cornerRadius: FlareSizes.radiusLg, color: colors.focusRing, width: 3)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityHint(fieldError ?? "")
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: open)
        .sheet(isPresented: $open) {
            SelectSheet(options: options, selection: $selection, title: title ?? placeholder ?? strings.select)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

/// Bottom-sheet body for `SelectView`: a titled, scrollable option list.
private struct SelectSheet: View {
    let options: [FlareSelectOption]
    @Binding var selection: String
    let title: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(spacing: 0) {
            // Sheet heading is a quiet 13pt tertiary caption (Android / Flutter parity).
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(colors.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, FlareSizes.spacingXl)
                .padding(.bottom, FlareSizes.spacingMd)
                .padding(.horizontal, FlareSizes.spacingLg)
            Divider().overlay(colors.borderSecondary)
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(options) { option in
                        let selected = option.value == selection
                        Button {
                            selection = option.value
                            dismiss()
                        } label: {
                          HStack(spacing: FlareSizes.spacingSm) {
                            Text(option.label)
                                .font(.system(size: 16,
                                               weight: selected ? .semibold : .regular))
                                .foregroundColor(option.disabled ? colors.textTertiary
                                                 : selected ? colors.primary : colors.textPrimary)
                            Spacer(minLength: 0)
                            if selected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundColor(colors.primaryText)
                            }
                        }
                        .padding(.horizontal, FlareSizes.spacingLg)
                        .frame(minHeight: 52)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(option.disabled)
                        .opacity(option.disabled ? 0.5 : 1)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                        Divider().overlay(colors.borderSecondary).padding(.leading, FlareSizes.spacingLg)
                    }
                }
            }
        }
        .background(colors.bgPrimary.ignoresSafeArea())
    }
}
