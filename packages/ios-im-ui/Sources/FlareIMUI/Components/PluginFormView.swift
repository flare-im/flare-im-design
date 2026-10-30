import SwiftUI

/// The inputs of a plugin action. Spec: Form/PluginForm (`PluginFormView`). The host puts it in the kit bottom sheet
/// (``PluginView`` does so for a card action whose `form` lists inputs).
///
/// The kit checks only required and length (Unicode code points, trimmed): an input's issue shows once it was edited,
/// and every issue after a submit attempt; the core SDK's `validate_form` decides, and its `errors` show under their
/// inputs until that input is edited (the first one per input). `onSubmit` receives the cleaned values: text trimmed
/// (omitted when blank), number and datetime when set, toggle always, select when chosen, option rows trimmed without
/// the empty ones, members when any (`spec/plugin-view-vectors.json` → form).
///
/// Controls: text and textarea with "n/max"; number; toggle (``SwitchView``); select as a single-choice list
/// (``RadioGroupView``); datetime with the platform's date and time picker; options as rows with add and remove within
/// [max(min, 1), max]; members through ``ContactPickerView`` over the host's `members` (one pick when max is 1).
public struct PluginFormView: View {
    private let inputs: [PluginInput]
    private let values: [String: PluginJSONValue]?
    private let errors: [PluginFormError]
    private let submitLabel: String?
    private let busy: Bool
    private let error: String?
    private let members: [PluginMember]
    private let onSubmit: (([String: PluginJSONValue]) -> Void)?
    private let onCancel: (() -> Void)?
    @State private var form: PluginFormState
    @State private var numberText: [String: String]
    @State private var picking: PluginInput?
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(inputs: [PluginInput], values: [String: PluginJSONValue]? = nil, errors: [PluginFormError] = [],
                submitLabel: String? = nil, busy: Bool = false, error: String? = nil, members: [PluginMember] = [],
                onSubmit: (([String: PluginJSONValue]) -> Void)? = nil, onCancel: (() -> Void)? = nil) {
        self.inputs = inputs; self.values = values; self.errors = errors; self.submitLabel = submitLabel
        self.busy = busy; self.error = error; self.members = members; self.onSubmit = onSubmit; self.onCancel = onCancel
        let state = PluginFormState(inputs: inputs, values: values)
        self._form = State(initialValue: state)
        self._numberText = State(initialValue: Self.numberTexts(inputs, state))
    }

    private static func numberTexts(_ inputs: [PluginInput], _ state: PluginFormState) -> [String: String] {
        var out: [String: String] = [:]
        for input in inputs where input.kind == .number {
            out[input.id] = state.draft[input.id]?.numberValue.map(PluginViewFormat.number) ?? ""
        }
        return out
    }

    /// The form a host hands over: other inputs or other initial values start it over.
    private struct Source: Equatable { let inputs: [PluginInput]; let values: [String: PluginJSONValue]? }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(alignment: .leading, spacing: FlareSizes.spacingLg) {
            ForEach(inputs) { input in field(input, colors) }
            if let error, !error.isEmpty { StatusBannerView(text: error, tone: .danger) }
            HStack(spacing: FlareSizes.spacingSm) {
                ButtonView(label: strings.cancel, variant: .secondary, disabled: busy || onCancel == nil, block: true) {
                    onCancel?()
                }
                ButtonView(label: submitLabel ?? strings.pluginViewSubmit, loading: busy,
                           disabled: onSubmit == nil, block: true) { submit() }
            }
        }
        .padding(.horizontal, FlareSizes.spacingLg).padding(.vertical, FlareSizes.spacingMd)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: Source(inputs: inputs, values: values)) { _ in
            form = PluginFormState(inputs: inputs, values: values)
            numberText = Self.numberTexts(inputs, form)
        }
        .onChange(of: errors) { _ in form.hostErrorsChanged() }
        .flareBottomSheet(item: $picking, title: picking?.label, titleHidden: true, size: .large) { input in
            ContactPickerView(
                groups: [FlareContactPickerGroup(
                    id: FlareContactPickerGroup.groupMembers, label: input.label,
                    entries: members.map { FlareContactPickerEntry(userId: $0.userId, name: $0.name, avatarUrl: $0.avatarUrl) })],
                multiple: PluginFormRules.maxItems(input) != 1, title: input.label,
                onSelect: { entries in
                    picking = nil
                    let ids = entries.map(\.userId).prefix(PluginFormRules.maxItems(input))
                    form.set(input.id, .array(ids.map(PluginJSONValue.string)))
                },
                onCancel: { picking = nil })
        }
    }

    private func submit() {
        guard !busy, let values = form.submit(inputs) else { return }
        onSubmit?(values)
    }

    private func errorText(_ input: PluginInput) -> String? { form.errorText(input, hostErrors: errors, strings) }

    @ViewBuilder private func field(_ input: PluginInput, _ colors: FlareColors) -> some View {
        switch input.kind {
        case .text:
            FormFieldView(label: input.label, required: input.required,
                          hint: PluginFormRules.counter(input, form.draft[input.id]), error: errorText(input)) {
                InputView(text: text(input), placeholder: input.placeholder ?? "", disabled: busy)
                    .accessibilityLabel(input.label)
                    .accessibilityIdentifier("plugin.form.\(input.id)")
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    #endif
            }
        case .textarea:
            FormFieldView(label: input.label, required: input.required,
                          hint: PluginFormRules.counter(input, form.draft[input.id]), error: errorText(input)) {
                TextareaView(text: text(input), placeholder: input.placeholder ?? "", rows: 3, maxRows: 6, disabled: busy)
                    .accessibilityLabel(input.label)
                    .accessibilityIdentifier("plugin.form.\(input.id)")
            }
        case .number:
            FormFieldView(label: input.label, required: input.required, error: errorText(input)) {
                InputView(text: number(input), placeholder: input.placeholder ?? "", disabled: busy)
                    .accessibilityLabel(input.label)
                    .accessibilityIdentifier("plugin.form.\(input.id)")
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
            }
        case .toggle:
            FormFieldView(error: errorText(input)) {
                HStack(spacing: FlareSizes.spacingMd) {
                    Text(input.label).font(.system(size: FlareSizes.fontSizeLg * textScale)).foregroundColor(colors.textPrimary)
                    Spacer(minLength: 0)
                    SwitchView(isOn: Binding(get: { form.draft[input.id]?.boolValue ?? false },
                                             set: { form.set(input.id, .bool($0)) }), disabled: busy)
                }
                .accessibilityElement(children: .combine)
            }
        case .select:
            FormFieldView(label: input.label, required: input.required, error: errorText(input)) {
                RadioGroupView(options: (input.choices ?? []).map { FlareSelectOption(value: $0.value, label: $0.label) },
                               selection: Binding(get: { form.draft[input.id]?.stringValue ?? "" },
                                                  set: { form.set(input.id, .string($0)) }),
                               vertical: true)
                    .disabled(busy)
            }
        case .datetime:
            FormFieldView(label: input.label, required: input.required, error: errorText(input)) {
                PluginDateTimeField(value: form.draft[input.id]?.numberValue, disabled: busy) { next in
                    form.set(input.id, next.map(PluginJSONValue.number) ?? .null)
                }
            }
        case .options:
            FormFieldView(label: input.label, required: input.required, error: errorText(input)) {
                optionRows(input, colors)
            }
        case .members:
            FormFieldView(label: input.label, required: input.required, error: errorText(input)) {
                memberField(input, colors)
            }
        }
    }

    private func text(_ input: PluginInput) -> Binding<String> {
        Binding(get: { form.draft[input.id]?.stringValue ?? "" }, set: { form.set(input.id, .string($0)) })
    }

    private func number(_ input: PluginInput) -> Binding<String> {
        Binding(get: { numberText[input.id] ?? "" }, set: { raw in
            numberText[input.id] = raw
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            let value = trimmed.isEmpty ? nil : Double(trimmed)
            form.set(input.id, value.flatMap { $0.isFinite ? PluginJSONValue.number($0) : nil } ?? .null)
        })
    }

    private func optionRows(_ input: PluginInput, _ colors: FlareColors) -> some View {
        let rows = form.rows(input.id)
        let removable = form.canRemoveRow(input)
        return VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            ForEach(Array(rows.indices), id: \.self) { index in
                HStack(spacing: FlareSizes.spacingXs) {
                    InputView(text: Binding(get: { form.rows(input.id).indices.contains(index) ? form.rows(input.id)[index] : "" },
                                            set: { form.setRow(input, index, $0) }),
                              placeholder: strings.pollOptionHint(index + 1), disabled: busy)
                    IconButtonView(icon: "remove", accessibilityLabel: strings.removeOption, size: .sm,
                                   disabled: busy || !removable) { form.removeRow(input, index) }
                }
            }
            ButtonView(label: strings.addOption, variant: .ghost, size: .sm, disabled: busy || !form.canAddRow(input),
                       icon: "add") { form.addRow(input) }
        }
    }

    private func memberField(_ input: PluginInput, _ colors: FlareColors) -> some View {
        let ids = (form.draft[input.id]?.arrayValue ?? []).compactMap(\.stringValue)
        return VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            if !ids.isEmpty {
                FlareFlowLayout(spacing: FlareSizes.spacingXs, lineSpacing: FlareSizes.spacingXs) {
                    ForEach(ids, id: \.self) { userId in
                        let member = members.first { $0.userId == userId }
                        let name = member?.name ?? PluginViewFormat.fallbackName(userId)
                        HStack(spacing: FlareSizes.spacing2xs) {
                            AvatarView(userId: userId, displayName: name, avatarURL: member?.avatarUrl, size: 20 * textScale)
                            Text(name).font(.system(size: FlareSizes.fontSizeMd * textScale)).foregroundColor(colors.textPrimary)
                                .lineLimit(1)
                        }
                        .padding(.leading, FlareSizes.spacing3xs).padding(.trailing, FlareSizes.spacingSm)
                        .padding(.vertical, FlareSizes.spacing3xs)
                        .background(Capsule().fill(colors.bgSecondary))
                    }
                }
                .accessibilityElement(children: .combine)
            }
            ButtonView(label: strings.select, variant: .secondary, size: .sm, disabled: busy || members.isEmpty,
                       icon: "person-add") { picking = input }
        }
    }
}

/// A datetime input: the platform's date and time picker once a value is set, a key that sets one before.
struct PluginDateTimeField: View {
    let value: Double?
    let disabled: Bool
    let onChange: (Double?) -> Void
    @Environment(\.flareStrings) private var strings

    var body: some View {
        if let value {
            HStack(spacing: FlareSizes.spacingSm) {
                DatePicker("", selection: Binding(
                    get: { Date(timeIntervalSince1970: value / 1000) },
                    set: { onChange(Self.minute($0)) }
                ), displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .disabled(disabled)
                Spacer(minLength: 0)
                IconButtonView(icon: "close", accessibilityLabel: strings.clear, size: .sm, disabled: disabled) {
                    onChange(nil)
                }
            }
        } else {
            ButtonView(label: strings.selectDate, variant: .secondary, size: .sm, disabled: disabled, icon: "calendar") {
                onChange(Self.nextHour(Date()))
            }
        }
    }

    /// Milliseconds at the minute the picker shows.
    static func minute(_ date: Date) -> Double {
        (date.timeIntervalSince1970 / 60).rounded(.down) * 60_000
    }

    /// The next whole hour from `date`: where a new value starts.
    static func nextHour(_ date: Date) -> Double {
        ((date.timeIntervalSince1970 / 3600).rounded(.down) + 1) * 3_600_000
    }
}
