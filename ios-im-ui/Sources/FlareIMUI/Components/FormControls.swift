import SwiftUI

// MARK: - Size helpers
// Private, file-scoped (Swift `private` is per-file) so they don't collide with the
// identically-named helper in FormViews.swift.

private extension FlareControlSize {
    /// Control height. sm 32 / md 40 / lg 48.
    var height: CGFloat { self == .sm ? 32 : self == .md ? 40 : 48 }
    /// Square (icon-button) side used by the stepper +/- buttons. 30 / 38 / 46.
    var square: CGFloat { self == .sm ? 30 : self == .md ? 38 : 46 }
    /// Text/label font size. 13 / 14 / 15.
    var font: CGFloat { self == .sm ? 13 : self == .md ? 14 : 15 }
    /// Glyph size for the stepper +/- icons. 15 / 18 / 20 (mirrors the Vue font-size).
    var glyph: CGFloat { self == .sm ? 15 : self == .md ? 18 : 20 }
    /// Field content padding (horizontal, vertical) for the textarea.
    var pad: (h: CGFloat, v: CGFloat) { self == .sm ? (10, 8) : self == .md ? (12, 10) : (14, 12) }
    /// Horizontal padding for text triggers (matches the Select trigger). 12 / 16 / 20.
    var hPadding: CGFloat { self == .sm ? 12 : self == .md ? 16 : 20 }
}

// MARK: - Textarea

/// Multi-line text input with a token-styled container, focus ring, auto-grow feel and
/// an optional character counter. Spec: Form/Textarea (`TextareaView`).
/// Ref: vue-im-ui `FlareTextarea.vue`.
public struct TextareaView: View {
    @Binding private var text: String
    private let placeholder: String
    private let size: FlareControlSize
    private let rows: Int
    private let maxRows: Int
    private let showCount: Bool
    private let maxlength: Int?
    private let disabled: Bool
    @FocusState private var focused: Bool
    @Environment(\.colorScheme) private var scheme

    public init(text: Binding<String>, placeholder: String = "", size: FlareControlSize = .md,
                rows: Int = 3, maxRows: Int = 0, showCount: Bool = false, maxlength: Int? = nil,
                disabled: Bool = false) {
        self._text = text; self.placeholder = placeholder; self.size = size; self.rows = rows
        self.maxRows = maxRows; self.showCount = showCount; self.maxlength = maxlength
        self.disabled = disabled
    }

    private var lineHeight: CGFloat { size.font * 1.5 }
    private var minHeight: CGFloat { CGFloat(rows) * lineHeight + size.pad.v * 2 }
    private var maxHeight: CGFloat? { maxRows > 0 ? CGFloat(maxRows) * lineHeight + size.pad.v * 2 : nil }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        ZStack(alignment: .topLeading) {
            // Invisible mirror drives the auto-grow height between min and max.
            Text(text.isEmpty ? " " : text + " ")
                .font(.system(size: size.font))
                .lineSpacing(lineHeight - size.font)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, size.pad.h)
                .padding(.vertical, size.pad.v)
                .frame(minHeight: minHeight, alignment: .topLeading)
                .frame(maxHeight: maxHeight, alignment: .topLeading)
                .opacity(0)
                .accessibilityHidden(true)

            TextEditor(text: $text)
                .font(.system(size: size.font))
                .foregroundColor(colors.textPrimary)
                .tint(colors.primary)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, size.pad.h - 5) // TextEditor has ~5pt inset of its own
                .padding(.vertical, size.pad.v - 8)
                .frame(minHeight: minHeight, alignment: .topLeading)
                .frame(maxHeight: maxHeight, alignment: .topLeading)
                .focused($focused)
                .disabled(disabled)
                .onChange(of: text) { newValue in
                    if let maxlength, newValue.count > maxlength {
                        text = String(newValue.prefix(maxlength))
                    }
                }

            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: size.font))
                    .foregroundColor(colors.textTertiary)
                    .padding(.horizontal, size.pad.h)
                    .padding(.vertical, size.pad.v)
                    .allowsHitTesting(false)
            }

            if showCount {
                VStack {
                    Spacer(minLength: 0)
                    HStack {
                        Spacer(minLength: 0)
                        Text(maxlength != nil ? "\(text.count) / \(maxlength!)" : "\(text.count)")
                            .font(.system(size: FlareSizes.fontSizeSm))
                            .foregroundColor(colors.textTertiary)
                    }
                }
                .padding(.horizontal, size.pad.h)
                .padding(.bottom, 6)
                .allowsHitTesting(false)
            }
        }
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
            .fill(focused ? colors.bgPrimary : colors.bgSecondary))
        .overlay(
            RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                .stroke(focused ? colors.primary : colors.borderPrimary, lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                .stroke(colors.focusRing, lineWidth: focused ? 3 : 0)
        )
        .opacity(disabled ? 0.55 : 1)
        .animation(.easeOut(duration: 0.15), value: focused)
    }
}

// MARK: - Stepper

/// Custom −/+ stepper matching the kit look (not SwiftUI's `Stepper`).
/// Spec: Form/Stepper (`StepperView`). Ref: vue-im-ui `FlareStepper.vue`.
public struct StepperView: View {
    @Binding private var value: Double
    private let min: Double
    private let max: Double
    private let step: Double
    private let size: FlareControlSize
    private let readonly: Bool
    private let disabled: Bool
    @Environment(\.colorScheme) private var scheme

    public init(value: Binding<Double>, min: Double = 0, max: Double = .infinity, step: Double = 1,
                size: FlareControlSize = .md, readonly: Bool = false, disabled: Bool = false) {
        self._value = value; self.min = min; self.max = max; self.step = step
        self.size = size; self.readonly = readonly; self.disabled = disabled
    }

    private var canDec: Bool { !disabled && value > min }
    private var canInc: Bool { !disabled && value < max }
    private var fieldWidth: CGFloat { size == .lg ? 52 : 44 }

    private func clamp(_ n: Double) -> Double { Swift.min(max, Swift.max(min, n)) }
    private func set(_ n: Double) {
        let next = clamp(n)
        if next != value { value = next }
    }

    /// Trim a trailing ".0" so integer-valued steppers read cleanly.
    private var display: String {
        value == value.rounded() ? String(Int(value)) : String(value)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: 0) {
            button(colors, system: "minus", enabled: canDec) { set(value - step) }
            Text(display)
                .font(.system(size: size.font))
                .monospacedDigit()
                .foregroundColor(colors.textPrimary)
                .frame(width: fieldWidth, height: size.height)
            button(colors, system: "plus", enabled: canInc) { set(value + step) }
        }
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
        .overlay(
            RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                .stroke(colors.borderPrimary, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusLg))
        .opacity(disabled ? 0.55 : 1)
    }

    @ViewBuilder
    private func button(_ colors: FlareColors, system: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: size.glyph, weight: .medium))
                .foregroundColor(enabled ? colors.textSecondary : colors.textTertiary)
                .frame(width: size.square, height: size.height)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }
}

// MARK: - Slider

/// Range slider with a brand-gradient active track and an optional value bubble.
/// Spec: Form/Slider (`SliderView`). Ref: vue-im-ui `FlareSlider.vue`.
public struct SliderView: View {
    @Binding private var value: Double
    private let min: Double
    private let max: Double
    private let step: Double
    private let showValue: Bool
    private let disabled: Bool
    @State private var dragging = false
    @Environment(\.colorScheme) private var scheme

    private let thumb: CGFloat = 18
    private let trackH: CGFloat = 6

    public init(value: Binding<Double>, min: Double = 0, max: Double = 100, step: Double = 1,
                showValue: Bool = false, disabled: Bool = false) {
        self._value = value; self.min = min; self.max = max; self.step = step
        self.showValue = showValue; self.disabled = disabled
    }

    private var pct: Double {
        let span = max - min
        guard span > 0 else { return 0 }
        return Swift.min(1, Swift.max(0, (value - min) / span))
    }

    private func snap(_ raw: Double) -> Double {
        guard step > 0 else { return Swift.min(max, Swift.max(min, raw)) }
        let stepped = (raw / step).rounded() * step
        return Swift.min(max, Swift.max(min, stepped))
    }

    private var display: String {
        value == value.rounded() ? String(Int(value)) : String(value)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        GeometryReader { geo in
            let w = geo.size.width
            let travel = Swift.max(0, w - thumb)
            let thumbX = travel * CGFloat(pct)
            ZStack(alignment: .leading) {
                // Base track
                Capsule().fill(colors.borderHover)
                    .frame(height: trackH)
                // Active (brand-gradient) fill
                Capsule()
                    .fill(LinearGradient(colors: [colors.primary, colors.primary.opacity(0.82)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: thumbX + thumb / 2, height: trackH)
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: thumb, height: thumb)
                    .overlay(Circle().stroke(colors.primary, lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.24), radius: 2, y: 1)
                    .scaleEffect(dragging ? 1.14 : 1)
                    .offset(x: thumbX)
                    .overlay(alignment: .top) {
                        if showValue && dragging {
                            Text(display)
                                .font(.system(size: FlareSizes.fontSizeSm))
                                .monospacedDigit()
                                .foregroundColor(.white)
                                .padding(.horizontal, FlareSizes.spacingSm)
                                .padding(.vertical, 2)
                                .background(RoundedRectangle(cornerRadius: FlareSizes.radiusSm).fill(colors.primary))
                                .fixedSize()
                                .offset(x: thumbX, y: -(thumb + 6))
                                .allowsHitTesting(false)
                        }
                    }
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        guard !disabled, travel > 0 else { return }
                        dragging = true
                        let ratio = Swift.min(1, Swift.max(0, (g.location.x - thumb / 2) / travel))
                        value = snap(min + Double(ratio) * (max - min))
                    }
                    .onEnded { _ in dragging = false }
            )
            .animation(.easeOut(duration: 0.12), value: dragging)
        }
        .frame(height: 28)
        .opacity(disabled ? 0.5 : 1)
    }
}

// MARK: - Rating

/// Star rating row. Spec: Form/Rating (`RatingView`). Ref: vue-im-ui `FlareRating.vue`.
/// Uses SF Symbols `star.fill` / `star`; gold = `colors.warning`.
public struct RatingView: View {
    @Binding private var value: Int
    private let count: Int
    private let size: CGFloat
    private let readonly: Bool
    private let clearable: Bool
    private let disabled: Bool
    @Environment(\.colorScheme) private var scheme

    public init(value: Binding<Int>, count: Int = 5, size: CGFloat = 24, readonly: Bool = false,
                clearable: Bool = false, disabled: Bool = false) {
        self._value = value; self.count = count; self.size = size; self.readonly = readonly
        self.clearable = clearable; self.disabled = disabled
    }

    private var interactive: Bool { !disabled && !readonly }

    private func pick(_ n: Int) {
        guard interactive else { return }
        value = (clearable && value == n) ? 0 : n
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        HStack(spacing: FlareSizes.spacingXs) {
            ForEach(1...Swift.max(1, count), id: \.self) { n in
                Image(systemName: n <= value ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundColor(n <= value ? colors.warning : colors.borderHover)
                    .contentShape(Rectangle())
                    .onTapGesture { pick(n) }
            }
        }
        .opacity(disabled ? 0.5 : 1)
        .animation(.easeOut(duration: 0.12), value: value)
    }
}

// MARK: - TimePicker

/// Time picker with a token-styled trigger (clock icon + `HH:mm`) that presents a native
/// wheel picker inside a bottom sheet. Spec: Form/TimePicker (`TimePickerView`).
/// Ref: vue-im-ui `FlareTimePicker.vue`.
///
/// A native app is always mobile, so this uses the bottom-sheet presentation (the app form
/// of the Vue component's adaptive "H5 sheet" branch), not a popover. The Vue two-column
/// hour/minute list is replaced by iOS's native `DatePicker` wheel — expected on iOS.
/// `value` is the bound time as "HH:mm" (24-hour, zero-padded).
public struct TimePickerView: View {
    @Binding private var value: String
    private let placeholder: String?
    private let size: FlareControlSize
    private let minuteStep: Int
    private let title: String?
    private let disabled: Bool
    private let cancelLabel: String
    private let confirmLabel: String
    @State private var open = false
    @Environment(\.colorScheme) private var scheme

    public init(value: Binding<String>, placeholder: String? = nil, size: FlareControlSize = .md,
                minuteStep: Int = 5, title: String? = nil, disabled: Bool = false,
                cancelLabel: String = "取消", confirmLabel: String = "确定") {
        self._value = value; self.placeholder = placeholder; self.size = size
        self.minuteStep = minuteStep; self.title = title; self.disabled = disabled
        self.cancelLabel = cancelLabel; self.confirmLabel = confirmLabel
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let hasValue = !value.isEmpty
        Button {
            if !disabled { open = true }
        } label: {
            HStack(spacing: FlareSizes.spacingSm) {
                Image(systemName: "clock")
                    .font(.system(size: size.font, weight: .medium))
                    .foregroundColor(colors.textTertiary)
                Text(hasValue ? value : (placeholder ?? ""))
                    .font(.system(size: size.font))
                    .monospacedDigit()
                    .foregroundColor(hasValue ? colors.textPrimary : colors.textTertiary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .frame(height: size.height)
            .padding(.horizontal, size.hPadding)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
            .overlay(
                RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                    .stroke(open ? colors.primary : colors.borderPrimary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
        .animation(.easeOut(duration: 0.15), value: open)
        .sheet(isPresented: $open) {
            TimePickerSheet(value: $value, minuteStep: minuteStep,
                            title: title ?? placeholder ?? "选择时间",
                            cancelLabel: cancelLabel, confirmLabel: confirmLabel)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

/// Bottom-sheet body for `TimePickerView`: a titled header with 取消/确定 plus a native
/// 24-hour wheel `DatePicker`. Seeds a temp `Date` from the "HH:mm" value (minute snapped to
/// `minuteStep` where practical) and, on 确定, formats it back to "HH:mm".
private struct TimePickerSheet: View {
    @Binding var value: String
    let minuteStep: Int
    let title: String
    let cancelLabel: String
    let confirmLabel: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var temp = Date()

    var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Text(cancelLabel)
                        .font(.system(size: FlareSizes.fontSizeLg))
                        .foregroundColor(colors.textSecondary)
                }
                Spacer(minLength: 0)
                Text(title)
                    .font(.system(size: FlareSizes.fontSizeLg, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Button { commit() } label: {
                    Text(confirmLabel)
                        .font(.system(size: FlareSizes.fontSizeLg, weight: .semibold))
                        .foregroundColor(colors.primary)
                }
            }
            .padding(.horizontal, FlareSizes.spacingLg)
            .padding(.top, FlareSizes.spacingXl)
            .padding(.bottom, FlareSizes.spacingMd)
            Divider().overlay(colors.borderSecondary)
            // 24-hour wheel constrained to `minuteStep`.
            // iOS uses a UIDatePicker wrapper so `minuteInterval` snaps the minute wheel and
            // prevents off-step selection; macOS falls back to `.graphical` to stay buildable.
            wheel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(colors.bgPrimary.ignoresSafeArea())
        .onAppear { temp = seededDate() }
    }

    private var clampedStep: Int { Swift.max(1, Swift.min(30, minuteStep)) }

    @ViewBuilder
    private var wheel: some View {
        #if os(iOS)
        // 24-hour hour/minute wheel with the minute column locked to the step.
        SteppedTimeWheel(selection: $temp, minuteInterval: clampedStep)
        #else
        DatePicker("", selection: $temp, displayedComponents: .hourAndMinute)
            .datePickerStyle(.graphical)
            .labelsHidden()
            .environment(\.locale, Locale(identifier: "en_GB"))
        #endif
    }

    private func seededDate() -> Date {
        let cal = Calendar.current
        var h = 0, m = 0
        let parts = value.split(separator: ":")
        if parts.count == 2 { h = Int(parts[0]) ?? 0; m = Int(parts[1]) ?? 0 }
        let step = Swift.max(1, Swift.min(30, minuteStep))
        m = (Int((Double(m) / Double(step)).rounded()) * step) % 60
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = Swift.min(23, Swift.max(0, h))
        comps.minute = m
        return cal.date(from: comps) ?? Date()
    }

    private func commit() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: temp)
        value = String(format: "%02d:%02d", comps.hour ?? 0, comps.minute ?? 0)
        dismiss()
    }
}

#if os(iOS)
import UIKit

/// A `UIDatePicker` (`.wheels`, hour+minute, 24-hour) whose `minuteInterval` locks the minute
/// column to the step so a user can never land on an off-step minute — SwiftUI's native
/// `DatePicker(.wheel)` has no `minuteStep` knob, hence this thin UIKit bridge.
private struct SteppedTimeWheel: UIViewRepresentable {
    @Binding var selection: Date
    let minuteInterval: Int

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.minuteInterval = Swift.max(1, Swift.min(30, minuteInterval))
        // en_GB forces the 24-hour hour/minute layout (no AM/PM column).
        picker.locale = Locale(identifier: "en_GB")
        picker.setDate(selection, animated: false)
        picker.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        picker.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return picker
    }

    func updateUIView(_ picker: UIDatePicker, context: Context) {
        let step = Swift.max(1, Swift.min(30, minuteInterval))
        if picker.minuteInterval != step { picker.minuteInterval = step }
        if abs(picker.date.timeIntervalSince(selection)) > 1 {
            picker.setDate(selection, animated: false)
        }
    }

    final class Coordinator: NSObject {
        private let parent: SteppedTimeWheel
        init(_ parent: SteppedTimeWheel) { self.parent = parent }
        @objc func changed(_ picker: UIDatePicker) { parent.selection = picker.date }
    }
}
#endif

// MARK: - DatePicker

/// Date picker with a token-styled trigger (calendar icon + `YYYY-MM-DD`) that presents a
/// graphical month calendar inside a bottom sheet. Spec: Form/DatePicker (`DatePickerView`).
/// Ref: vue-im-ui `FlareDatePicker.vue`.
///
/// A native app is always mobile, so this uses the bottom-sheet presentation (the app form of
/// the Vue component's adaptive "H5 sheet" branch), not the desktop popover. `value` is the
/// bound date as "YYYY-MM-DD". `min`/`max` (same format) bound the selectable range. The
/// graphical picker commits live, so tapping a day (or 今天) sets `value` and dismisses.
public struct DatePickerView: View {
    @Binding private var value: String
    private let placeholder: String?
    private let size: FlareControlSize
    private let min: String?
    private let max: String?
    private let title: String?
    private let disabled: Bool
    private let cancelLabel: String
    private let todayLabel: String
    @State private var open = false
    @Environment(\.colorScheme) private var scheme

    public init(value: Binding<String>, placeholder: String? = nil, size: FlareControlSize = .md,
                min: String? = nil, max: String? = nil, title: String? = nil, disabled: Bool = false,
                cancelLabel: String = "取消", todayLabel: String = "今天") {
        self._value = value; self.placeholder = placeholder; self.size = size
        self.min = min; self.max = max; self.title = title; self.disabled = disabled
        self.cancelLabel = cancelLabel; self.todayLabel = todayLabel
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let hasValue = !value.isEmpty
        Button {
            if !disabled { open = true }
        } label: {
            HStack(spacing: FlareSizes.spacingSm) {
                Image(systemName: "calendar")
                    .font(.system(size: size.font, weight: .medium))
                    .foregroundColor(colors.textTertiary)
                Text(hasValue ? value : (placeholder ?? ""))
                    .font(.system(size: size.font))
                    .monospacedDigit()
                    .foregroundColor(hasValue ? colors.textPrimary : colors.textTertiary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .frame(height: size.height)
            .padding(.horizontal, size.hPadding)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
            .overlay(
                RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                    .stroke(open ? colors.primary : colors.borderPrimary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
        .animation(.easeOut(duration: 0.15), value: open)
        .sheet(isPresented: $open) {
            DatePickerSheet(value: $value, min: min, max: max,
                            title: title ?? placeholder ?? "选择日期",
                            cancelLabel: cancelLabel, todayLabel: todayLabel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

/// Bottom-sheet body for `DatePickerView`: a titled header with 取消/今天 plus a graphical
/// month calendar. Seeds a temp `Date` from the "YYYY-MM-DD" value and, on a day tap, formats
/// it back to "YYYY-MM-DD". `min`/`max` become a `ClosedRange`/`PartialRangeFrom`/
/// `PartialRangeThrough` bound on the picker.
private struct DatePickerSheet: View {
    @Binding var value: String
    let min: String?
    let max: String?
    let title: String
    let cancelLabel: String
    let todayLabel: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var temp: Date

    init(value: Binding<String>, min: String?, max: String?, title: String,
         cancelLabel: String, todayLabel: String) {
        self._value = value; self.min = min; self.max = max; self.title = title
        self.cancelLabel = cancelLabel; self.todayLabel = todayLabel
        // Seed from the bound value in init so the first render does NOT fire the onChange
        // that dismisses the sheet — only a real user tap should commit + dismiss.
        _temp = State(initialValue: Self.parse(value.wrappedValue) ?? Self.startOfToday())
    }

    var body: some View {
        let colors = FlareColors.of(scheme)
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Text(cancelLabel)
                        .font(.system(size: FlareSizes.fontSizeLg))
                        .foregroundColor(colors.textSecondary)
                }
                Spacer(minLength: 0)
                Text(title)
                    .font(.system(size: FlareSizes.fontSizeLg, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Button { goToday() } label: {
                    Text(todayLabel)
                        .font(.system(size: FlareSizes.fontSizeLg, weight: .semibold))
                        .foregroundColor(colors.primary)
                }
            }
            .padding(.horizontal, FlareSizes.spacingLg)
            .padding(.top, FlareSizes.spacingXl)
            .padding(.bottom, FlareSizes.spacingMd)
            Divider().overlay(colors.borderSecondary)
            calendar
                .tint(colors.primary)
                .padding(.horizontal, FlareSizes.spacingMd)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(colors.bgPrimary.ignoresSafeArea())
    }

    @ViewBuilder
    private var calendar: some View {
        let lower = Self.parse(min ?? "")
        let upper = Self.parse(max ?? "")
        Group {
            if let lower, let upper {
                styled(DatePicker("", selection: $temp, in: lower...upper, displayedComponents: .date))
            } else if let lower {
                styled(DatePicker("", selection: $temp, in: lower..., displayedComponents: .date))
            } else if let upper {
                styled(DatePicker("", selection: $temp, in: ...upper, displayedComponents: .date))
            } else {
                styled(DatePicker("", selection: $temp, displayedComponents: .date))
            }
        }
        .onChange(of: temp) { newValue in
            value = Self.format(newValue)
            dismiss()
        }
    }

    // `.graphical` is iOS-only; `.compact` keeps the SPM macOS host build green.
    @ViewBuilder
    private func styled<V: View>(_ picker: V) -> some View {
        #if os(iOS)
        picker.datePickerStyle(.graphical).labelsHidden()
        #else
        picker.datePickerStyle(.compact).labelsHidden()
        #endif
    }

    private func goToday() {
        var today = Self.startOfToday()
        if let lower = Self.parse(min ?? ""), today < lower { today = lower }
        if let upper = Self.parse(max ?? ""), today > upper { today = upper }
        value = Self.format(today)
        dismiss()
    }

    // MARK: "YYYY-MM-DD" <-> Date helpers (Gregorian / POSIX / current time zone)

    private static func formatter() -> DateFormatter {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }
    private static func parse(_ s: String) -> Date? {
        s.isEmpty ? nil : formatter().date(from: s)
    }
    private static func format(_ d: Date) -> String { formatter().string(from: d) }
    private static func startOfToday() -> Date { Calendar.current.startOfDay(for: Date()) }
}
