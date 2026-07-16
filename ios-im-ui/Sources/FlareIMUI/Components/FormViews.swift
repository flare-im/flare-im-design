import SwiftUI

// MARK: - Size helpers

private extension FlareControlSize {
    /// Control height. sm 32 / md 40 / lg 48.
    var height: CGFloat { self == .sm ? 32 : self == .md ? 40 : 48 }
    /// Square (icon-button) side. 30 / 38 / 46.
    var square: CGFloat { self == .sm ? 30 : self == .md ? 38 : 46 }
    /// Horizontal padding for text buttons / triggers.
    var hPadding: CGFloat { self == .sm ? 12 : self == .md ? 16 : 20 }
    /// Label font size. 13 / 14 / 15.
    var font: CGFloat { self == .sm ? 13 : self == .md ? 14 : 15 }
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
    private let systemImage: String?
    private let action: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(label: String? = nil, variant: FlareButtonVariant = .primary,
                size: FlareControlSize = .md, loading: Bool = false, disabled: Bool = false,
                block: Bool = false, systemImage: String? = nil, action: (() -> Void)? = nil) {
        self.label = label; self.variant = variant; self.size = size; self.loading = loading
        self.disabled = disabled; self.block = block; self.systemImage = systemImage; self.action = action
    }

    private func fill(_ colors: FlareColors) -> Color {
        switch variant {
        case .primary: return colors.primary
        case .danger: return colors.error
        case .secondary: return colors.bgSecondary
        case .ghost, .text: return .clear
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
        switch variant {
        case .primary, .danger: return .white
        case .secondary: return colors.textPrimary
        case .ghost, .text: return colors.primary
        }
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let solid = variant == .primary || variant == .danger
        Button { action?() } label: {
            HStack(spacing: FlareSizes.spacingSm) {
                if loading {
                    ProgressView().controlSize(.small).tint(solid ? .white : colors.primary)
                } else if let systemImage {
                    Image(systemName: systemImage).font(.system(size: size.font, weight: .semibold))
                }
                if let label {
                    Text(label).font(.system(size: size.font, weight: .semibold))
                }
            }
            .foregroundColor(fg(colors))
            .frame(maxWidth: block ? .infinity : nil)
            .frame(height: size.height)
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
    private let systemImage: String
    private let accessibilityLabel: String
    private let size: FlareControlSize
    private let variant: IconButtonVariant
    private let square: Bool
    private let disabled: Bool
    private let active: Bool
    private let action: (() -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(systemImage: String, accessibilityLabel: String, size: FlareControlSize = .md,
                variant: IconButtonVariant = .plain, square: Bool = false, disabled: Bool = false,
                active: Bool = false, action: (() -> Void)? = nil) {
        self.systemImage = systemImage; self.accessibilityLabel = accessibilityLabel; self.size = size
        self.variant = variant; self.square = square; self.disabled = disabled; self.active = active
        self.action = action
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let side = size.square
        let bg: Color = active ? colors.bgSelected
            : variant == .solid ? colors.primary
            : variant == .tinted ? colors.bgSecondary
            : .clear
        let fg: Color = variant == .solid ? .white
            : active ? colors.primary
            : colors.textSecondary
        let iconSize = size == .sm ? 15.0 : size == .md ? 17.0 : 19.0
        Button { action?() } label: {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(fg)
                .frame(width: side, height: side)
                .background(shape.fill(bg))
        }
        .buttonStyle(.plain)
        .disabled(disabled || action == nil)
        .opacity(disabled ? 0.5 : 1)
        .accessibilityLabel(accessibilityLabel)
    }

    private var shape: AnyShape {
        square ? AnyShape(RoundedRectangle(cornerRadius: FlareSizes.radiusMd)) : AnyShape(Circle())
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

    public init(label: String? = nil, required: Bool = false, hint: String? = nil,
                error: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label; self.required = required; self.hint = hint; self.error = error
        self.content = content()
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(alignment: .leading, spacing: FlareSizes.spacingXs + 2) {
            if let label {
                HStack(spacing: 2) {
                    Text(label).font(.system(size: 13, weight: .medium)).foregroundColor(colors.textSecondary)
                    if required { Text("*").font(.system(size: 13, weight: .medium)).foregroundColor(colors.error) }
                }
            }
            content
            if let error {
                Text(error).font(.system(size: 12)).foregroundColor(colors.error)
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

    public init(isOn: Binding<Bool>, disabled: Bool = false) {
        self._isOn = isOn; self.disabled = disabled
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        Capsule()
            .fill(isOn ? colors.primary : colors.borderHover)
            .frame(width: 44, height: 26)
            .overlay(
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: Color.black.opacity(0.15), radius: 1, y: 1)
                    .offset(x: isOn ? 9 : -9)
            )
            .animation(.easeOut(duration: 0.18), value: isOn)
            .opacity(disabled ? 0.5 : 1)
            .contentShape(Capsule())
            .onTapGesture { if !disabled { isOn.toggle() } }
    }
}

/// Checkbox with optional label + indeterminate state. Spec: Form/Checkbox (`CheckboxView`).
public struct CheckboxView: View {
    @Binding private var isOn: Bool
    private let label: String?
    private let indeterminate: Bool
    private let disabled: Bool
    @Environment(\.colorScheme) private var scheme

    public init(isOn: Binding<Bool>, label: String? = nil, indeterminate: Bool = false, disabled: Bool = false) {
        self._isOn = isOn; self.label = label; self.indeterminate = indeterminate; self.disabled = disabled
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let filled = isOn || indeterminate
        HStack(spacing: FlareSizes.spacingSm) {
            RoundedRectangle(cornerRadius: FlareSizes.radiusSm)
                .fill(filled ? colors.primary : Color.clear)
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
                            Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                        }
                    }
                )
            if let label {
                Text(label).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(colors.textPrimary)
            }
        }
        .opacity(disabled ? 0.5 : 1)
        .contentShape(Rectangle())
        .onTapGesture { if !disabled { isOn.toggle() } }
        .animation(.easeOut(duration: 0.12), value: filled)
    }
}

/// Single-select radio group (horizontal or vertical). Spec: Form/RadioGroup (`RadioGroupView`).
public struct RadioGroupView: View {
    private let options: [FlareSelectOption]
    @Binding private var selection: String
    private let vertical: Bool
    @Environment(\.colorScheme) private var scheme

    public init(options: [FlareSelectOption], selection: Binding<String>, vertical: Bool = false) {
        self.options = options; self._selection = selection; self.vertical = vertical
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let layout = AnyLayout(vertical ? AnyLayout(VStackLayout(alignment: .leading, spacing: FlareSizes.spacingMd))
                                        : AnyLayout(HStackLayout(spacing: FlareSizes.spacingLg)))
        layout {
            ForEach(options) { option in
                let selected = option.value == selection
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
                .opacity(option.disabled ? 0.5 : 1)
                .contentShape(Rectangle())
                .onTapGesture { if !option.disabled { selection = option.value } }
            }
        }
        .animation(.easeOut(duration: 0.12), value: selection)
    }
}

/// Dropdown select with a custom-styled trigger. Spec: Form/Select (`SelectView`).
public struct SelectView: View {
    private let options: [FlareSelectOption]
    @Binding private var selection: String
    private let placeholder: String?
    private let size: FlareControlSize
    private let disabled: Bool
    @State private var open = false
    @Environment(\.colorScheme) private var scheme

    public init(options: [FlareSelectOption], selection: Binding<String>, placeholder: String? = nil,
                size: FlareControlSize = .md, disabled: Bool = false) {
        self.options = options; self._selection = selection; self.placeholder = placeholder
        self.size = size; self.disabled = disabled
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let selectedLabel = options.first { $0.value == selection }?.label
        Menu {
            ForEach(options) { option in
                Button {
                    selection = option.value
                } label: {
                    if option.value == selection {
                        Label(option.label, systemImage: "checkmark")
                    } else {
                        Text(option.label)
                    }
                }
                .disabled(option.disabled)
            }
        } label: {
            HStack(spacing: FlareSizes.spacingSm) {
                Text(selectedLabel ?? placeholder ?? "")
                    .font(.system(size: size.font))
                    .foregroundColor(selectedLabel == nil ? colors.textTertiary : colors.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: size.font - 2, weight: .semibold))
                    .foregroundColor(colors.textTertiary)
                    .rotationEffect(.degrees(open ? 180 : 0))
            }
            .frame(height: size.height)
            .padding(.horizontal, size.hPadding)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
            .overlay(
                RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                    .stroke(open ? colors.primary : colors.borderPrimary, lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
        .onTapGesture { if !disabled { open.toggle() } }
        .animation(.easeOut(duration: 0.15), value: open)
    }
}
