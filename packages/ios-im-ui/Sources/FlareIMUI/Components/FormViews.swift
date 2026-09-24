import SwiftUI

// MARK: - Size helpers

private extension FlareControlSize {
    /// Control height. sm 32 / md 40 / lg 48.
    var height: CGFloat { self == .sm ? 32 : self == .md ? 40 : 48 }
    /// Square (icon-button) side. 30 / 38 / 46.
    var square: CGFloat { self == .sm ? 30 : self == .md ? 38 : 46 }
    /// Horizontal padding for text buttons. 12 / 18 / 24.
    var hPadding: CGFloat { self == .sm ? 12 : self == .md ? 18 : 24 }
    /// Horizontal padding for select triggers. 10 / 12 / 14.
    var triggerPadding: CGFloat { self == .sm ? 10 : self == .md ? 12 : 14 }
    /// Label font size. 13 / 14 / 15.
    var font: CGFloat { self == .sm ? 13 : self == .md ? 14 : 15 }
    /// Icon-button glyph size. 16 / 19 / 22.
    var glyph: CGFloat { self == .sm ? 16 : self == .md ? 19 : 22 }
}

/// General-purpose button. Spec: Form/Button (`ButtonView`).
/// Five variants (`primary` brand fill, `secondary` outline, `ghost` tinted outline,
/// `danger` error fill, `text` link), three sizes, plus loading / disabled / block / icon.
public struct ButtonView: View {
    private let label: String?
    private let variant: FlareButtonVariant
    private let size: FlareControlSize
    private let loading: Bool
    private let disabled: Bool
    private let block: Bool
    /// Semantic kit icon name (``flareIconNames``) before the label; nil draws none.
    private let icon: String?
    private let action: (() -> Void)?
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(label: String? = nil, variant: FlareButtonVariant = .primary,
                size: FlareControlSize = .md, loading: Bool = false, disabled: Bool = false,
                block: Bool = false, icon: String? = nil, action: (() -> Void)? = nil) {
        self.label = label; self.variant = variant; self.size = size; self.loading = loading
        self.disabled = disabled; self.block = block; self.icon = icon; self.action = action
    }

    private func fill(_ colors: FlareColors) -> Color {
        switch variant {
        case .primary: return colors.primary
        case .danger: return colors.error
        case .secondary: return colors.bgSecondary
        case .ghost, .text, .quiet: return .clear
        }
    }

    private func stroke(_ colors: FlareColors) -> Color {
        switch variant {
        case .secondary: return colors.borderPrimary
        case .ghost: return colors.primary.opacity(0.4)
        default: return .clear
        }
    }

    private func fg(_ colors: FlareColors) -> Color {
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
        let solid = variant == .primary || variant == .danger
        Button { action?() } label: {
            HStack(spacing: FlareSizes.spacingSm) {
                if loading {
                    ProgressView().controlSize(.small).tint(solid ? .white : colors.primaryText)
                } else if let icon {
                    Image(systemName: flareIconSymbol(icon)).font(.system(size: size.font + 4, weight: .semibold))
                }
                if let label {
                    Text(label).font(.system(size: size.font * textScale, weight: .semibold))
                }
            }
            .foregroundColor(fg(colors))
            .frame(maxWidth: block ? .infinity : nil)
            .frame(minHeight: size.height)
            .padding(.vertical, FlareSizes.spacing2xs)
            .padding(.horizontal, size.hPadding)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(fill(colors)))
            .overlay(
                RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                    .stroke(stroke(colors), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled || loading || action == nil)
        .opacity(disabled ? 0.5 : 1)
    }
}

/// Icon-only button. Spec: Form/IconButton (`IconButtonView`).
public enum IconButtonVariant: Sendable { case plain, tinted, solid }

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
        let side = customSize ?? size.square
        let bg: Color = background ?? (active ? colors.bgSelected
            : variant == .solid ? colors.primary
            : variant == .tinted ? colors.bgSecondary
            : .clear)
        let fg: Color = tint ?? (variant == .solid ? .white
            : active ? colors.primary
            : colors.textSecondary)
        let iconSize = customSize.map { (($0 * 0.46).rounded()) } ?? size.glyph
        Button { action?() } label: {
            Image(systemName: flareIconSymbol(icon))
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(fg)
                .frame(width: side, height: side)
                .background(shape.fill(bg))
                // sm (30) and md (38) draw below the 44pt minimum; the target around them does not.
                .flareTouchTarget()
        }
        .buttonStyle(.plain)
        .flareCompactLayout(width: side, height: side)
        .disabled(disabled || action == nil)
        .opacity(disabled ? 0.45 : 1)
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
    private let content: Content
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(label: String? = nil, required: Bool = false, hint: String? = nil,
                error: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label; self.required = required; self.hint = hint; self.error = error
        self.content = content()
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(alignment: .leading, spacing: FlareSizes.spacingXs + 2) {
            if let label {
                HStack(spacing: 2) {
                    Text(label).font(.system(size: 13, weight: .medium)).foregroundColor(colors.textSecondary)
                    if required { Text("*").font(.system(size: 13, weight: .medium)).foregroundColor(colors.errorText) }
                }
            }
            content
            if let error {
                Text(error).font(.system(size: 12)).foregroundColor(colors.errorText)
            } else if let hint {
                Text(hint).font(.system(size: 12)).foregroundColor(colors.textTertiary)
            }
        }
    }
}

/// Custom on/off switch. Spec: Form/Switch (`SwitchView`).
/// Hand-built track + knob (not SwiftUI `Toggle`) to match the kit look.
public struct SwitchView: View {
    @Binding private var isOn: Bool
    private let disabled: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.flareStrings) private var strings

    public init(isOn: Binding<Bool>, disabled: Bool = false) {
        self._isOn = isOn; self.disabled = disabled
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        Button { isOn.toggle() } label: {
          Capsule()
            .fill(isOn ? colors.primary : colors.borderHover)
            .frame(width: 44, height: 26)
            .overlay(
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: Color.black.opacity(0.28), radius: 3, y: 1)
                    .offset(x: isOn ? 9 : -9)
            )
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: isOn)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
        .accessibilityValue(isOn ? strings.on : strings.off)
        .accessibilityAddTraits(isOn ? .isSelected : [])
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
                .frame(width: 20, height: 20)
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
          .frame(minWidth: 44, minHeight: 44)
          .contentShape(Rectangle())
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: filled)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : [.isButton])
    }
}

/// Single-select radio group (horizontal or vertical). Spec: Form/RadioGroup (`RadioGroupView`).
public struct RadioGroupView: View {
    private let options: [FlareSelectOption]
    @Binding private var selection: String
    private let vertical: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(options: [FlareSelectOption], selection: Binding<String>, vertical: Bool = false) {
        self.options = options; self._selection = selection; self.vertical = vertical
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let layout = AnyLayout(vertical ? AnyLayout(VStackLayout(alignment: .leading, spacing: FlareSizes.spacingMd))
                                        : AnyLayout(HStackLayout(spacing: 18)))
        layout {
            ForEach(options) { option in
                let selected = option.value == selection
                Button { selection = option.value } label: {
                  HStack(spacing: FlareSizes.spacingSm) {
                    ZStack {
                        Circle().stroke(selected ? colors.primary : colors.borderHover, lineWidth: 1.5)
                            .frame(width: 18, height: 18)
                        if selected {
                            Circle().fill(colors.primary).frame(width: 9, height: 9)
                        }
                    }
                    Text(option.label).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary)
                }
                  .frame(minWidth: 44, minHeight: 44)
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
                    .stroke(open ? colors.primary : colors.borderPrimary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
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
