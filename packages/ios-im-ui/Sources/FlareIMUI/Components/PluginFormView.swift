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
/// [max(min, 1), max]; members through ``ContactPickerView`` over the host's `members` (one pick when max is 1); money
/// as an amount field with its currency (decimal keypad; submitted as `{amount, currency}`, the amount normalised and
/// checked against the scale and bounds); file and image through the upload slot (the host picks and uploads on
/// ``PluginFileAction``); documents as ``FlareDocumentSlot`` tiles, 16:10, two to a row on a phone and three elsewhere
/// (§6.3: the host captures the side), the submit held with "还差 n 张照片" until every required photo is in.
/// `busy` spins the submit key and freezes the fields; `disabled` only freezes them (R2.5).
public struct PluginFormView: View {
    private let embedded: Bool
    private let inputs: [PluginInput]
    private let values: [String: PluginJSONValue]?
    private let errors: [PluginFormError]
    private let submitLabel: String?
    private let busy: Bool
    /// R2.5 / R8: the form waits without a spinner (offline, another action running, a read-only view).
    private let disabled: Bool
    private let error: String?
    private let members: [PluginMember]
    private let membersLoading: Bool
    private let membersRevision: Int
    private let membersError: String?
    private let onMemberSearch: ((String) -> Void)?
    private let onMembersRetry: (() -> Void)?
    private let onSubmit: (([String: PluginJSONValue]) -> Void)?
    private let onCancel: (() -> Void)?
    private let fileStates: [String: PluginFileState]
    private let onFileAction: ((PluginFileAction) -> Void)?
    private let locationStates: [String: PluginLocationState]
    private let onLocationAction: ((PluginLocationAction) -> Void)?
    private let nativeRequest: PluginNativeIntoRequest?
    /// R6 / R2.2: a page's own form on touch — the submit key leaves the form for the page's bottom bar
    /// (``PluginFormSubmitKey``).
    private let pinSubmit: Bool
    /// A page form opened for a native request runs it as it appears, as a sheet form does.
    private var opensWithRequest = false
    /// R6: the field the form scrolls to and puts the keyboard in after a failed submit.
    @State private var wrongRequest: PluginFieldRequest?
    /// The wrong field to centre again once the keyboard the jump opened is up (cleared then, or when it hides).
    @State private var revealOnKeyboard: String?
    @State private var form: PluginFormState
    @State private var numberText: [String: String]
    @State private var picking: PluginInput?
    @State private var selectedMembers: [String: PluginMember] = [:]
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif
    /// R6: after a failed submit VoiceOver lands on the first wrong field (and the form scrolls to it).
    @AccessibilityFocusState private var wrongField: String?
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(inputs: [PluginInput], values: [String: PluginJSONValue]? = nil, errors: [PluginFormError] = [],
                submitLabel: String? = nil, busy: Bool = false, disabled: Bool = false, error: String? = nil, members: [PluginMember] = [], membersLoading: Bool = false, membersRevision: Int = 0, membersError: String? = nil,
                onMemberSearch: ((String) -> Void)? = nil, onMembersRetry: (() -> Void)? = nil,
                embedded: Bool = false, fileStates: [String: PluginFileState] = [:],
                onFileAction: ((PluginFileAction) -> Void)? = nil,
                locationStates: [String: PluginLocationState] = [:],
                onLocationAction: ((PluginLocationAction) -> Void)? = nil,
                nativeRequest: PluginNativeIntoRequest? = nil,
                pinSubmit: Bool = false,
                onSubmit: (([String: PluginJSONValue]) -> Void)? = nil, onCancel: (() -> Void)? = nil) {
        self.embedded = embedded
        self.pinSubmit = pinSubmit && embedded
        self.nativeRequest = nativeRequest
        self.locationStates = locationStates; self.onLocationAction = onLocationAction
        self.fileStates = fileStates; self.onFileAction = onFileAction
        self.inputs = inputs; self.values = values; self.errors = errors; self.submitLabel = submitLabel
        self.busy = busy; self.disabled = disabled; self.error = error; self.members = members
        self.membersLoading = membersLoading; self.membersRevision = membersRevision; self.membersError = membersError
        self.onMemberSearch = onMemberSearch; self.onMembersRetry = onMembersRetry; self.onSubmit = onSubmit; self.onCancel = onCancel
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

    /// Fields and keys wait: the form runs (with the spinner) or it is disabled (without).
    private var frozen: Bool { busy || disabled }

    /// R6: a select with no choices, an upload still running or a required photo not taken (§6.3) holds the submit
    /// key.
    private var submitHeld: Bool {
        form.filePending || photosMissing > 0 || PluginFormRules.visibleInputs(inputs, form.draft).contains {
            $0.kind == .select && ($0.choices ?? []).isEmpty
        }
    }

    /// §6.3: the required document photos not uploaded yet.
    private var photosMissing: Int {
        PluginFormRules.visibleInputs(inputs, form.draft).filter {
            $0.kind == .document && $0.required && form.files[$0.id]?.phase != .uploaded
        }.count
    }

    /// The caption under the submit key: the uploads running, else the photos still needed ("还差 1 张照片").
    private var submitCaption: String? {
        if let uploadCaption { return uploadCaption }
        let missing = photosMissing
        guard missing > 0 else { return nil }
        return (missing == 1 ? strings.realnamePhotosNeededOne : strings.realnamePhotosNeeded)
            .replacingOccurrences(of: "{count}", with: String(missing))
    }

    /// R6: phone fields are the large (48) controls, pointer ones the regular (40).
    private var fieldSize: FlareControlSize { FlarePluginPage.refreshKeyInHeader ? .md : .lg }

    /// §6.3: document slots two to a row on a phone (a compact width), three elsewhere.
    private var documentColumns: Int {
        #if os(iOS)
        return sizeClass == .compact ? 2 : 3
        #else
        return 3
        #endif
    }

    /// The visible inputs as drawn: each on its own, consecutive document inputs together as one slot grid.
    static func runs(_ inputs: [PluginInput]) -> [[PluginInput]] {
        var runs: [[PluginInput]] = []
        for input in inputs {
            if input.kind == .document, runs.last?.last?.kind == .document { runs[runs.count - 1].append(input) }
            else { runs.append([input]) }
        }
        return runs
    }

    /// R6: "正在上传 n/m" while an upload runs: m the uploads started, n those done.
    private var uploadCaption: String? {
        guard form.filePending else { return nil }
        let started = PluginFormRules.visibleInputs(inputs, form.draft).filter {
            $0.kind.isUpload && (form.files[$0.id]?.phase ?? .empty) != .empty
        }
        let done = started.filter { form.files[$0.id]?.phase == .uploaded }.count
        return strings.pluginViewUploading.replacingOccurrences(of: "{done}", with: String(done))
            .replacingOccurrences(of: "{total}", with: String(started.count))
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        ScrollViewReader { proxy in
        VStack(alignment: .leading, spacing: FlareSizes.spacingLg) {
            ForEach(Self.runs(PluginFormRules.visibleInputs(inputs, form.draft)), id: \.first?.id) { run in
                if run.first?.kind == .document {
                    documentGrid(run, colors)
                } else if let input = run.first {
                    field(input, colors).id(input.id).accessibilityFocused($wrongField, equals: input.id)
                }
            }
            if let error, !error.isEmpty { StatusBannerView(text: error, tone: .danger) }
            if !pinSubmit {
                // R6: a pointer page's own form ends in its submit key at its natural width (at least 120).
                let natural = embedded && FlarePluginPage.refreshKeyInHeader
                HStack(spacing: FlareSizes.spacingSm) {
                    if !embedded { ButtonView(label: strings.cancel, variant: .secondary, disabled: busy || onCancel == nil, block: true) {
                        invalidateFiles(); onCancel?()
                    } }
                    ButtonView(label: submitLabel ?? strings.pluginViewSubmit, loading: busy,
                               disabled: onSubmit == nil || submitHeld || disabled, block: !natural) { submitOrFocus() }
                        .frame(minWidth: natural ? FlareSizes.componentActionMinWidth : nil)
                }
                if let submitCaption { PluginCaption(text: submitCaption) }
            }
        }
        .onChange(of: wrongRequest) { request in
            guard let request else { return }
            withAnimation(nil) { proxy.scrollTo(request.id, anchor: .center) }
            revealOnKeyboard = request.id
        }
        #if os(iOS)
        // §6.2: the keyboard the jump opened shrinks the page after it scrolled, leaving the field under the keyboard
        // or the pinned submit bar; once the keyboard is up, centre the field again (as Compose after the IME).
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
            guard let id = revealOnKeyboard else { return }
            revealOnKeyboard = nil
            withAnimation(FlareMotion.fastAnimation) { proxy.scrollTo(id, anchor: .center) }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { _ in
            revealOnKeyboard = nil
        }
        #endif
        }
        .preference(key: PluginFormSubmitKey.self, value: pinSubmit
            ? PluginFormSubmit(label: submitLabel ?? strings.pluginViewSubmit, busy: busy,
                               disabled: onSubmit == nil || submitHeld || disabled, caption: submitCaption, submit: submitOrFocus)
            : nil)
        .onChange(of: errors) { next in
            if let first = PluginFormRules.visibleInputs(inputs, form.draft).first(where: { input in next.contains { $0.input == input.id } }) {
                focusWrong(first.id)
            }
        }
        .padding(.horizontal, embedded ? 0 : FlareSizes.spacingLg).padding(.vertical, embedded ? 0 : FlareSizes.spacingMd)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: Source(inputs: inputs, values: values)) { _ in
            invalidateFiles()
            selectedMembers = [:]
            form = PluginFormState(inputs: inputs, values: values)
            numberText = Self.numberTexts(inputs, form)
        }
        .onChange(of: membersRevision) { _ in
            selectedMembers = [:]; picking = nil
            for input in inputs where input.kind == .members { set(input.id, .array([])) }
        }
        .onChange(of: errors) { _ in form.hostErrorsChanged() }
        .onChange(of: fileStates) { updates in form.acceptFiles(updates) }
        .onChange(of: locationStates) { _ in applyLocations() }
        .onChange(of: nativeRequest) { request in if let request { _ = nativeInto(request.target) } }
        // A form sheet opened for a native request (its input sat in this closed form) runs it as it appears.
        .onAppear { applyLocations(); if !embedded || opensWithRequest, let nativeRequest { _ = nativeInto(nativeRequest.target) } }
        .onDisappear { invalidateFiles() }
        .flareBottomSheet(item: $picking, title: picking?.label, titleHidden: true, size: .large, fill: true) { input in
            ContactPickerView(
                groups: [FlareContactPickerGroup(
                    id: FlareContactPickerGroup.groupMembers, label: input.label,
                    entries: members.map { FlareContactPickerEntry(userId: $0.userId, name: $0.name, avatarUrl: $0.avatarUrl) })],
                multiple: PluginFormRules.maxItems(input) != 1, title: input.label,
                loading: membersLoading, error: membersError, onSearch: onMemberSearch, onRetry: onMembersRetry,
                onSelect: { entries in
                    guard picking?.id == input.id, !frozen, !membersLoading, membersError?.isEmpty != false else { return }
                    let current = Dictionary(members.map { ($0.userId, $0) }, uniquingKeysWith: { first, _ in first })
                    if onMemberSearch != nil {
                        for entry in entries {
                            selectedMembers[entry.userId] = PluginMember(userId: entry.userId, name: entry.name, avatarUrl: entry.avatarUrl)
                        }
                    }
                    let ids = entries.map(\.userId).filter { current[$0] != nil || (onMemberSearch != nil && selectedMembers[$0] != nil) }.prefix(PluginFormRules.maxItems(input))
                    for id in ids { if let member = current[id] { selectedMembers[id] = member } }
                    picking = nil
                    set(input.id, .array(ids.map(PluginJSONValue.string)))
                },
                onCancel: { picking = nil })
        }
    }

    /// This form as a page of its own (R6): it takes the native request it opens with, as a sheet does.
    func pageForm() -> PluginFormView {
        var copy = self
        copy.opensWithRequest = true
        return copy
    }

    /// Submits a clean form; returns the first wrong field when the check stops it.
    @discardableResult private func submit() -> String? {
        guard !frozen, !submitHeld else { return nil }
        guard let values = form.submit(inputs) else {
            return PluginFormRules.check(PluginFormRules.visibleInputs(inputs, form.draft), form.draft).first?.input
        }
        for input in inputs where input.kind == .password { form.draft[input.id] = .string("") }
        onSubmit?(values)
        return nil
    }

    /// The submit key: a form the check stops moves to its first wrong field.
    private func submitOrFocus() {
        if let first = submit() { focusWrong(first) }
    }

    /// R6: scroll to the field, give it the keyboard (a text field) and VoiceOver.
    private func focusWrong(_ id: String) {
        wrongRequest = PluginFieldRequest(id: id, token: (wrongRequest?.token ?? 0) + 1)
        wrongField = id
    }

    /// The keyboard request a text field takes (it changes on every failed submit that lands on it).
    private func focusToken(_ input: PluginInput) -> Int { wrongRequest?.id == input.id ? wrongRequest?.token ?? 0 : 0 }

    /// §5.10: a full PIN submits the form when no required field still waits after it.
    private func pinCompleted(_ input: PluginInput) {
        let visible = PluginFormRules.visibleInputs(inputs, form.draft)
        guard let at = visible.firstIndex(where: { $0.id == input.id }) else { return }
        let waiting = visible[(at + 1)...].contains { $0.required && PluginFormRules.check($0, form.draft[$0.id]) != nil }
        if !waiting { submitOrFocus() }
    }

    private func counter(_ input: PluginInput) -> String? { PluginFormRules.counter(input, form.draft[input.id]) }

    private func errorText(_ input: PluginInput) -> String? { form.errorText(input, hostErrors: errors, strings) }

    @ViewBuilder private func field(_ input: PluginInput, _ colors: FlareColors) -> some View {
        switch input.kind {
        case .password where input.maxLength == 6:
            // §5.10: a six-digit password is the kit PIN.
            FormFieldView(label: input.label, required: input.required, hint: input.help, error: errorText(input)) {
                PinInputView(value: text(input), label: input.label, error: errorText(input) != nil, disabled: frozen,
                             onComplete: { _ in pinCompleted(input) })
                    .accessibilityIdentifier("plugin.form.\(input.id)")
            }
        case .text, .password:
            FormFieldView(label: input.label, required: input.required, hint: input.help,
                          error: errorText(input), counter: counter(input)) {
                // R11: Return in a single-line field submits the form.
                InputView(text: text(input), placeholder: input.placeholder ?? "", disabled: frozen, secure: input.kind == .password,
                          size: fieldSize, focusRequest: focusToken(input), onSubmit: submitOrFocus)
                    .accessibilityLabel(input.label)
                    .accessibilityIdentifier("plugin.form.\(input.id)")
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    #endif
            }
        case .textarea:
            FormFieldView(label: input.label, required: input.required, hint: input.help,
                          error: errorText(input), counter: counter(input)) {
                TextareaView(text: text(input), placeholder: input.placeholder ?? "", rows: 3, maxRows: 6, disabled: frozen,
                             focusRequest: focusToken(input))
                    .accessibilityLabel(input.label)
                    .accessibilityIdentifier("plugin.form.\(input.id)")
            }
        case .number:
            FormFieldView(label: input.label, required: input.required, hint: input.help, error: errorText(input)) {
                InputView(text: number(input), placeholder: input.placeholder ?? "", disabled: frozen, size: fieldSize,
                          focusRequest: focusToken(input), onSubmit: submitOrFocus)
                    .accessibilityLabel(input.label)
                    .accessibilityIdentifier("plugin.form.\(input.id)")
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
            }
        case .toggle:
            FormFieldView(hint: input.help, error: errorText(input)) {
                HStack(spacing: FlareSizes.spacingMd) {
                    Text(input.label).font(.system(size: FlareSizes.fontSizeLg * textScale)).foregroundColor(colors.textPrimary)
                    Spacer(minLength: 0)
                    SwitchView(isOn: Binding(get: { form.draft[input.id]?.boolValue ?? false },
                                             set: { set(input.id, .bool($0)) }), disabled: frozen)
                }
                .accessibilityElement(children: .combine)
            }
        case .select:
            // R6: ≤ 4 choices as cards (stacked on a phone), more as the kit Select, none as a disabled Select.
            let choices = (input.choices ?? []).map { FlareSelectOption(value: $0.value, label: $0.label) }
            let control = PluginExperienceRules.selectControl(choices: choices.count)
            let selection = Binding(get: { form.draft[input.id]?.stringValue ?? "" }, set: { set(input.id, .string($0)) })
            FormFieldView(label: input.label, required: input.required,
                          hint: control.disabled ? strings.pluginViewNoOptionsHelp : input.help, error: errorText(input)) {
                if control.control == .cards {
                    RadioGroupView(options: choices, selection: selection, vertical: !FlarePluginPage.refreshKeyInHeader,
                                   optionLayout: .cards)
                        .disabled(frozen)
                } else {
                    SelectView(options: choices, selection: selection,
                               placeholder: control.disabled ? strings.pluginViewNoOptions : input.placeholder,
                               title: input.label, size: fieldSize, disabled: frozen || control.disabled)
                }
            }
        case .datetime:
            FormFieldView(label: input.label, required: input.required, hint: input.help, error: errorText(input)) {
                PluginDateTimeField(value: form.draft[input.id]?.numberValue, disabled: frozen) { next in
                    set(input.id, next.map(PluginJSONValue.number) ?? .null)
                }
            }
        case .options:
            FormFieldView(label: input.label, required: input.required, hint: input.help, error: errorText(input)) {
                optionRows(input, colors)
            }
        case .file, .image, .document:
            FormFieldView(label: input.label, required: input.required, hint: input.help, error: errorText(input)) {
                PluginFileUploadField(input: input, state: form.files[input.id], disabled: frozen || onFileAction == nil) {
                    sendFile($0, input: input)
                }
            }
        case .location:
            FormFieldView(label: input.label, required: input.required, hint: input.help,
                          error: locationStates[input.id]?.error ?? errorText(input)) {
                locationField(input, colors)
            }
        case .money:
            FormFieldView(label: input.label, required: input.required, hint: input.help ?? input.money?.currency,
                          error: errorText(input)) {
                InputView(text: money(input), placeholder: input.placeholder ?? "", disabled: frozen, size: fieldSize,
                          focusRequest: focusToken(input), onSubmit: submitOrFocus)
                    .accessibilityLabel([input.label, input.money?.currency].compactMap { $0 }.joined(separator: ", "))
                    .accessibilityIdentifier("plugin.form.\(input.id)")
                    #if os(iOS)
                    // Digits and one point; digits only when the amount has no fraction.
                    .keyboardType(input.money?.effectiveScale == 0 ? .numberPad : .decimalPad)
                    #endif
            }
        case .members:
            FormFieldView(label: input.label, required: input.required, hint: input.help, error: errorText(input)) {
                memberField(input, colors)
            }
        }
    }

    /// §6.3: consecutive document inputs as capture slots, 16:10 in a grid (two columns on a phone, three
    /// elsewhere); a slot runs its input's own file keys (the host captures), its error under it.
    private func documentGrid(_ run: [PluginInput], _ colors: FlareColors) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: FlareSizes.spacingMd, alignment: .top),
                            count: documentColumns)
        return LazyVGrid(columns: columns, alignment: .leading, spacing: FlareSizes.spacingMd) {
            ForEach(run) { input in
                let file = form.files[input.id]
                VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
                    FlareDocumentSlot(side: Self.documentSide(input.side), label: input.label,
                                      state: Self.slotState(file), imageUrl: file?.imageUrl,
                                      disabled: frozen || onFileAction == nil,
                                      onCapture: { sendFile((file?.phase ?? .empty) == .empty ? .choose : .replace, input: input) },
                                      // A failed upload of a kept file retries it; a failed capture takes the photo again.
                                      onRetry: { sendFile(file?.fileName != nil ? .retry : .replace, input: input) })
                    if let error = errorText(input) ?? file?.error.flatMap({ $0.isEmpty ? nil : $0 }) {
                        Text(error).font(.system(size: FlareTextRoles.caption.fontSize * textScale))
                            .foregroundColor(colors.errorText).fixedSize(horizontal: false, vertical: true)
                    }
                }
                .id(input.id)
                .accessibilityFocused($wrongField, equals: input.id)
            }
        }
    }

    /// A file state as a document slot's.
    static func slotState(_ file: PluginFileState?) -> FlareDocumentSlotState {
        switch file?.phase ?? .empty {
        case .empty: return .empty
        case .selected: return .uploading(0)
        case .uploading: return .uploading((file?.progress ?? 0) * 100)
        case .uploaded: return .captured
        case .failed: return .failed
        }
    }

    static func documentSide(_ side: PluginDocumentSide?) -> FlareDocumentSide {
        switch side {
        case .back: return .back
        case .holding: return .holding
        default: return .front
        }
    }

    /// The host's fix is the input's value; one of another precision is never taken.
    private func applyLocations() {
        for input in PluginFormRules.visibleInputs(inputs, form.draft) where input.kind == .location {
            guard let fix = PluginLocationValue.read(locationStates[input.id]?.value?.json, precision: input.precision),
                  PluginLocationValue.read(form.draft[input.id], precision: input.precision) != fix else { continue }
            set(input.id, fix.json)
        }
    }

    private func locationAction(_ input: PluginInput, _ kind: PluginLocationAction.Kind) {
        guard !frozen, PluginFormRules.visibleInputs(inputs, form.draft).contains(where: { $0.id == input.id }) else { return }
        if kind == .clear { set(input.id, .null) } else if locationStates[input.id]?.locating == true { return }
        onLocationAction?(PluginLocationAction(action: kind, inputId: input.id, input: input,
                                               formValues: PluginFormRules.values(inputs, form.draft)))
    }

    /// A location input: the fix (place, precision and accuracy) or "no location yet", and its locate and clear keys.
    @ViewBuilder private func locationField(_ input: PluginInput, _ colors: FlareColors) -> some View {
        let state = locationStates[input.id]
        let fix = PluginLocationValue.read(form.draft[input.id], precision: input.precision)
        let locating = state?.locating == true
        HStack(spacing: FlareSizes.spacingSm) {
            IconView("location")
            VStack(alignment: .leading, spacing: 2) {
                if locating {
                    Text(strings.pluginLocationLocating).foregroundColor(colors.textSecondary)
                        .font(.system(size: FlareSizes.fontSizeMd))
                } else if let fix {
                    Text(fix.text).font(.system(size: FlareSizes.fontSizeLg).monospacedDigit())
                        .foregroundColor(colors.textPrimary)
                        .accessibilityIdentifier("plugin.location.\(input.id).place")
                    Text("\(fix.precision == .fine ? strings.pluginLocationFine : strings.pluginLocationCoarse) · "
                         + strings.pluginLocationAccuracy.replacingOccurrences(of: "{m}", with: String(fix.accuracyM)))
                        .font(.system(size: FlareSizes.fontSizeSm)).foregroundColor(colors.textSecondary)
                } else {
                    Text(strings.pluginLocationEmpty).font(.system(size: FlareSizes.fontSizeMd))
                        .foregroundColor(colors.textSecondary)
                        .accessibilityIdentifier("plugin.location.\(input.id).empty")
                }
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: FlareSizes.spacingSm)
            if fix != nil, !locating {
                ButtonView(label: strings.pluginLocationClear, variant: .quiet, size: .sm, disabled: frozen) {
                    locationAction(input, .clear)
                }
            }
            ButtonView(label: fix == nil ? strings.pluginLocationLocate : strings.pluginLocationRelocate,
                       variant: .secondary, size: .sm, loading: locating,
                       disabled: frozen || onLocationAction == nil) { locationAction(input, .locate) }
                .accessibilityIdentifier("plugin.location.\(input.id).locate")
        }
        .frame(minHeight: FlareSizes.touchTarget)
    }

    private func set(_ id: String, _ value: PluginJSONValue) {
        if form.draft[id] != value {
            for dependent in inputs where dependent.showWhen?.field == id {
                numberText[dependent.id] = nil
                if picking?.id == dependent.id { picking = nil }
            }
        }
        for event in form.set(id, value) { onFileAction?(event) }
    }

    /// A page action's native `target` writing `into` one of this form's inputs: run it through that input's own
    /// key, so the host gets the form's scope with it and its answer lands in this form, even before the viewer
    /// touched the input. False when no visible input here takes it or the host has no handler for that key.
    @discardableResult private func nativeInto(_ target: PluginActionTarget) -> Bool {
        guard !frozen, let input = PluginFormRules.visibleInputs(inputs, form.draft)
            .first(where: { PluginFormRules.nativeIntoKey(target, $0) != nil }) else { return false }
        if PluginFormRules.nativeIntoKey(target, input) == "location" {
            guard onLocationAction != nil else { return false }
            locationAction(input, .locate)
            return true
        }
        guard onFileAction != nil else { return false }
        sendFile((form.files[input.id]?.phase ?? .empty) == .empty ? .choose : .replace, input: input)
        return true
    }

    private func sendFile(_ action: PluginFileActionKind, input: PluginInput) {
        guard !frozen, onFileAction != nil else { return }
        onFileAction?(form.fileAction(action, input: input))
    }

    private func invalidateFiles() {
        for input in inputs where input.kind.isUpload { onFileAction?(form.fileAction(.invalidate, input: input)) }
    }

    private func text(_ input: PluginInput) -> Binding<String> {
        Binding(get: { form.draft[input.id]?.stringValue ?? "" }, set: { set(input.id, .string($0)) })
    }

    /// A money field: the locale's decimal separator is kept as "." (spec moneyInput.typed).
    private func money(_ input: PluginInput) -> Binding<String> {
        Binding(get: { form.draft[input.id]?.stringValue ?? "" }, set: {
            set(input.id, .string(PluginMoneyRulesCheck.typed($0, decimalSeparator: Locale.current.decimalSeparator ?? ".")))
        })
    }

    private func number(_ input: PluginInput) -> Binding<String> {
        Binding(get: { numberText[input.id] ?? "" }, set: { raw in
            numberText[input.id] = raw
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            let value = trimmed.isEmpty ? nil : Double(trimmed)
            set(input.id, value.flatMap { $0.isFinite ? PluginJSONValue.number($0) : nil } ?? .null)
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
                              placeholder: strings.pollOptionHint(index + 1), disabled: frozen)
                    IconButtonView(icon: "remove", accessibilityLabel: strings.removeOption, size: .sm,
                                   disabled: frozen || !removable) { form.removeRow(input, index) }
                }
            }
            ButtonView(label: strings.addOption, variant: .ghost, size: .sm, disabled: frozen || !form.canAddRow(input),
                       icon: "add") { form.addRow(input) }
        }
    }

    private func memberField(_ input: PluginInput, _ colors: FlareColors) -> some View {
        let ids = (form.draft[input.id]?.arrayValue ?? []).compactMap(\.stringValue)
        return VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            if !ids.isEmpty {
                FlareFlowLayout(spacing: FlareSizes.spacingXs, lineSpacing: FlareSizes.spacingXs) {
                    ForEach(ids, id: \.self) { userId in
                        let member = members.first { $0.userId == userId } ?? selectedMembers[userId]
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
            ButtonView(label: strings.select, variant: .secondary, size: .sm, disabled: frozen,
                       icon: "person-add") { onMemberSearch?(""); picking = input }
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

/// A field a form asks to be scrolled to and focused; `token` changes on every ask.
struct PluginFieldRequest: Equatable {
    let id: String
    let token: Int
}

/// The submit key of a page's own form, pinned to the page's bottom bar on touch (R2.2, R6).
struct PluginFormSubmit: Equatable {
    let label: String
    let busy: Bool
    let disabled: Bool
    let caption: String?
    let submit: () -> Void

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.label == rhs.label && lhs.busy == rhs.busy && lhs.disabled == rhs.disabled && lhs.caption == rhs.caption
    }
}

struct PluginFormSubmitKey: PreferenceKey {
    static var defaultValue: PluginFormSubmit? { nil }
    static func reduce(value: inout PluginFormSubmit?, nextValue: () -> PluginFormSubmit?) {
        if value == nil { value = nextValue() }
    }
}
