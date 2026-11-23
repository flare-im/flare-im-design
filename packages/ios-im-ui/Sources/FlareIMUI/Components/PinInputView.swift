import SwiftUI

/// The six-cell PIN (payment password). Spec: PinInput (`PinInputView`), docs/plugin-experience.md §5.10: a plugin
/// form's six-digit password input renders as this. One field takes the typing and the cells only draw it — a dot
/// per digit, the next cell marked while focused — so typing fills the cells in turn and backspace clears the last.
///
/// - Digits only, six at most; `autoFocus` focuses it (and opens the number pad) when it appears; the sixth digit
///   (or Return when full) calls `onComplete`. Every change also goes to `onChange`.
/// - `error` turning on clears the value and shakes the cells once (not under Reduce Motion); the cells keep the
///   error border until the host turns it off.
/// - VoiceOver reads one field: `label` and how many digits are in (`pinInputProgress`), never the digits.
public struct PinInputView: View {
    /// The PIN's length.
    public static let length = 6

    @Binding private var value: String
    private let label: String
    private let error: Bool
    private let disabled: Bool
    private let autoFocus: Bool
    private let onChange: ((String) -> Void)?
    private let onComplete: ((String) -> Void)?
    @FocusState private var focused: Bool
    @State private var shakes: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(value: Binding<String>, label: String, error: Bool = false, disabled: Bool = false,
                autoFocus: Bool = true, onChange: ((String) -> Void)? = nil, onComplete: ((String) -> Void)? = nil) {
        _value = value; self.label = label; self.error = error; self.disabled = disabled; self.autoFocus = autoFocus
        self.onChange = onChange; self.onComplete = onComplete
    }

    /// What the field keeps of `text`: ASCII digits, six at most.
    static func clean(_ text: String) -> String {
        String(text.filter { $0.isASCII && $0.isNumber }.prefix(length))
    }

    /// VoiceOver's name for the field: the label and how many digits are in.
    static func progress(label: String, count: Int, strings: FlareStrings) -> String {
        strings.pinInputProgress.replacingOccurrences(of: "{label}", with: label)
            .replacingOccurrences(of: "{count}", with: String(count))
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        ZStack {
            // The field under the cells: there for typing, paste and VoiceOver; its text and caret are invisible.
            TextField("", text: $value)
                .textFieldStyle(.plain)
                .foregroundColor(.clear)
                .tint(.clear)
                .autocorrectionDisabled()
                #if os(iOS)
                .keyboardType(.numberPad)
                .textInputAutocapitalization(.never)
                #endif
                .focused($focused)
                .disabled(disabled)
                .onSubmit { if value.count == Self.length { onComplete?(value) } }
                .accessibilityLabel(label)
                // How many digits are in, never the digits.
                .accessibilityValue(Self.progress(label: label, count: value.count, strings: strings))
            HStack(spacing: FlareSizes.spacingSm) {
                ForEach(0..<Self.length, id: \.self) { index in cell(index, colors) }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .modifier(PinShake(shakes: shakes))
        }
        .frame(maxWidth: .infinity, minHeight: FlareSizes.componentPinCellHeight)
        .contentShape(Rectangle())
        .onTapGesture { if !disabled { focused = true } }
        .opacity(disabled ? FlareOpacity.disabled : 1)
        .onAppear { if autoFocus, !disabled { focused = true } }
        .onChange(of: value) { next in
            let clean = Self.clean(next)
            if clean != next { value = clean; return }
            onChange?(clean)
            if clean.count == Self.length { onComplete?(clean) }
        }
        .onChange(of: error) { failed in
            guard failed else { return }
            value = ""
            if !reduceMotion { withAnimation(.linear(duration: 0.4)) { shakes += 1 } }
        }
    }

    private func cell(_ index: Int, _ colors: FlareColors) -> some View {
        let current = focused && index == value.count
        let edge = error ? colors.error : current ? colors.borderSelected : colors.borderPrimary
        let shape = RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
        // §12.22: the current cell wears an input's focus — the 1px selected edge and the focusRing halo (Vue is-active).
        return shape.fill(disabled ? colors.bgPrimary : colors.bgSecondary)
            .overlay(shape.strokeBorder(edge, lineWidth: 1))
            .flareFocusHalo(current, cornerRadius: FlareSizes.radiusMd, color: colors.focusRing)
            .overlay {
                if index < value.count {
                    Circle().fill(colors.textPrimary).frame(width: FlareSizes.spacing2sm, height: FlareSizes.spacing2sm)
                }
            }
            // §12.19: in a 320 panel the cells shrink with the width, never under 36.
            .frame(minWidth: FlareSizes.componentPinCellMinWidth,
                   maxWidth: FlareSizes.componentPinCellWidth)
            .frame(height: FlareSizes.componentPinCellHeight)
    }
}

/// Three side-to-side swings per whole step of `shakes`.
private struct PinShake: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: FlareSizes.spacingSm * sin(shakes * .pi * 6), y: 0))
    }
}
