import SwiftUI

/// A person's notification preferences as settings sections.
/// Spec: Profile/NotificationAlertSettings (`NotificationAlertSettingsView`).
///
/// Do not disturb: the Quiet hours switch and, while it is on, Starts, Ends (read as the next day when it is not after
/// the start), Repeat and Alert me when mentioned. Notification content: Preview. Multiple devices: While active
/// elsewhere. Each section has its footer. Starts and Ends open the ``TimePickerView`` sheet, Repeat a kit bottom sheet
/// of seven day switches that never empties, Preview and While active elsewhere a kit bottom sheet with a vertical
/// ``RadioGroupView`` that applies the pick and closes. Every row reports the whole next value through `onChange`; the
/// host saves it. The value is the protocol's shape (spec/notification-alert-vectors.json). `disabled` stops the rows
/// (while the host saves or cannot write); a picker already open stays open and its pick still goes through `onChange`.
///
/// Without `sectionContent` it draws a list of its own. A settings page that is already one ``SettingsListView``
/// passes `sectionContent` and places the sections among its own:
///
/// ```swift
/// NotificationAlertSettingsView(value: prefs, onChange: { notifications.update($0) }) { alerts, select, toggle in
///     SettingsListView(sections: [general] + alerts + [about],
///                      onToggle: { if !toggle($0, $1) { setOwn($0, $1) } },
///                      onSelect: { if !select($0) { openPage($0) } })
/// }
/// ```
public struct NotificationAlertSettingsView<SectionContent: View>: View {
    private let value: FlareNotificationAlertPreferences
    private let disabled: Bool
    private let onChange: ((FlareNotificationAlertPreferences) -> Void)?
    private let sectionContent: ([FlareSettingsSection], @escaping (FlareSettingsItem) -> Bool,
                                 @escaping (FlareSettingsItem, Bool) -> Bool) -> SectionContent
    @Environment(\.flareStrings) private var strings
    @State private var picker: RowSheet?
    @State private var time: TimeRow?

    static var quietHoursRow: String { "quietHours" }
    static var startRow: String { "quietHoursStart" }
    static var endRow: String { "quietHoursEnd" }
    static var repeatRow: String { "quietHoursRepeat" }
    static var allowMentionsRow: String { "quietHoursAllowMentions" }
    static var previewRow: String { "notificationPreview" }
    static var multiDeviceRow: String { "multiDevice" }
    private static var weekdayPrefix: String { "weekday:" }

    /// The sheet a row opens.
    enum RowSheet: String, Identifiable {
        case days, preview, multiDevice
        var id: String { rawValue }
    }

    /// The time a row picks.
    enum TimeRow: String, Identifiable {
        case start, end
        var id: String { rawValue }
    }

    /// The section form: the host draws the list in `sectionContent` and gets the three sections with `select` and
    /// `toggle`, which run a row of the group (a picker, a switch) and return whether the row was one; the host
    /// handles the rows they return false for. Rows are keyed quietHours, quietHoursStart, quietHoursEnd,
    /// quietHoursRepeat, quietHoursAllowMentions, notificationPreview and multiDevice.
    public init(value: FlareNotificationAlertPreferences, disabled: Bool = false,
                onChange: ((FlareNotificationAlertPreferences) -> Void)? = nil,
                @ViewBuilder sectionContent: @escaping (_ sections: [FlareSettingsSection],
                                                        _ select: @escaping (FlareSettingsItem) -> Bool,
                                                        _ toggle: @escaping (FlareSettingsItem, Bool) -> Bool) -> SectionContent) {
        self.value = value; self.disabled = disabled; self.onChange = onChange
        self.sectionContent = sectionContent
    }

    /// The three sections: quiet hours, preview, and the other-device behaviour, each with its footer.
    var sections: [FlareSettingsSection] {
        let quiet = value.quietHours
        var quietRows = [FlareSettingsItem(key: Self.quietHoursRow, label: strings.quietHoursLabel, kind: .toggle,
                                           value: quiet.enabled, disabled: disabled)]
        if quiet.enabled {
            quietRows += [
                FlareSettingsItem(key: Self.startRow, label: strings.quietHoursStart,
                                  detail: formatMinuteOfDay(quiet.startMinute), disabled: disabled),
                FlareSettingsItem(key: Self.endRow, label: strings.quietHoursEnd,
                                  detail: quietHoursEndText(quiet, strings: strings), disabled: disabled),
                FlareSettingsItem(key: Self.repeatRow, label: strings.quietHoursRepeat,
                                  detail: weekdaySummaryText(quiet.weekdays, strings: strings), disabled: disabled),
                FlareSettingsItem(key: Self.allowMentionsRow, label: strings.quietHoursAllowMentions, kind: .toggle,
                                  value: quiet.allowMentions, disabled: disabled),
            ]
        }
        return [
            FlareSettingsSection(title: strings.quietHoursTitle, items: quietRows, footer: strings.quietHoursFooter),
            FlareSettingsSection(
                title: strings.notificationPreviewTitle,
                items: [FlareSettingsItem(key: Self.previewRow, label: strings.notificationPreviewLabel,
                                          detail: notificationPreviewText(value.preview, strings: strings),
                                          disabled: disabled)],
                footer: strings.notificationPreviewFooter
            ),
            FlareSettingsSection(
                title: strings.multiDeviceTitle,
                items: [FlareSettingsItem(key: Self.multiDeviceRow, label: strings.multiDeviceLabel,
                                          detail: multiDeviceAlertText(value.multiDevice, strings: strings),
                                          disabled: disabled)],
                footer: strings.multiDeviceFooter
            ),
        ]
    }

    public var body: some View {
        sectionContent(sections, select, toggle)
            .flareBottomSheet(item: $picker, title: picker.map(title(of:))) { picker in
                sheet(picker)
            }
            // A second presentation needs its own anchor view.
            .background(Color.clear.sheet(item: $time) { row in
                TimePickerSheet(
                    value: Binding(
                        get: { formatMinuteOfDay(row == .end ? value.quietHours.endMinute : value.quietHours.startMinute) },
                        set: { picked in pickTime(row, picked) }
                    ),
                    minuteStep: quietHoursMinuteStep,
                    title: row == .end ? strings.quietHoursEnd : strings.quietHoursStart,
                    cancelLabel: strings.cancel,
                    confirmLabel: strings.confirm
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            })
            .onChange(of: value.quietHours.enabled) { enabled in
                // The time and day rows belong to quiet hours: when they go, so do their pickers.
                if !enabled { time = nil; if picker == .days { picker = nil } }
            }
    }

    private func changeQuietHours(_ update: (inout FlareQuietHours) -> Void) {
        var next = value
        update(&next.quietHours)
        onChange?(next)
    }

    /// Runs a picker row of the group and says whether `item` was one.
    func select(_ item: FlareSettingsItem) -> Bool {
        switch item.key {
        case Self.startRow: whenEnabled { time = .start }
        case Self.endRow: whenEnabled { time = .end }
        case Self.repeatRow: whenEnabled { picker = .days }
        case Self.previewRow: whenEnabled { picker = .preview }
        case Self.multiDeviceRow: whenEnabled { picker = .multiDevice }
        default: return false
        }
        return true
    }

    /// Runs a switch row of the group and says whether `item` was one.
    func toggle(_ item: FlareSettingsItem, _ on: Bool) -> Bool {
        switch item.key {
        case Self.quietHoursRow: whenEnabled { changeQuietHours { $0.enabled = on } }
        case Self.allowMentionsRow: whenEnabled { changeQuietHours { $0.allowMentions = on } }
        default: return false
        }
        return true
    }

    /// Rows take no input while disabled; a sheet already open keeps working.
    private func whenEnabled(_ run: () -> Void) {
        if !disabled { run() }
    }

    func pickTime(_ row: TimeRow, _ picked: String) {
        let minute = parseMinuteOfDay(picked)
        changeQuietHours { quiet in
            if row == .end { quiet.endMinute = minute } else { quiet.startMinute = minute }
        }
    }

    private func title(of picker: RowSheet) -> String {
        switch picker {
        case .days: return strings.quietHoursRepeat
        case .preview: return strings.notificationPreviewLabel
        case .multiDevice: return strings.multiDeviceLabel
        }
    }

    @ViewBuilder
    private func sheet(_ picker: RowSheet) -> some View {
        switch picker {
        case .days:
            ScrollView {
                SettingsListView(sections: [weekdaySection], onToggle: toggleDay, scrollable: false)
                    .padding(.bottom, FlareSizes.spacingLg)
            }
        case .preview:
            choices(FlareNotificationPreview.allCases.map {
                FlareSelectOption(value: $0.rawValue, label: notificationPreviewText($0, strings: strings))
            }, selected: value.preview.rawValue) { pickChoice(.preview, $0) }
        case .multiDevice:
            choices(FlareMultiDeviceAlert.allCases.map {
                FlareSelectOption(value: $0.rawValue, label: multiDeviceAlertText($0, strings: strings))
            }, selected: value.multiDevice.rawValue) { pickChoice(.multiDevice, $0) }
        }
    }

    /// Applies the pick of a choice sheet.
    func pickChoice(_ sheet: RowSheet, _ picked: String) {
        var next = value
        switch sheet {
        case .preview:
            guard let preview = FlareNotificationPreview(rawValue: picked) else { return }
            next.preview = preview
        case .multiDevice:
            guard let policy = FlareMultiDeviceAlert(rawValue: picked) else { return }
            next.multiDevice = policy
        case .days:
            return
        }
        onChange?(next)
    }

    /// A vertical radio group; a pick applies and closes the sheet.
    private func choices(_ options: [FlareSelectOption], selected: String,
                         pick: @escaping (String) -> Void) -> some View {
        RadioGroupView(options: options, selection: Binding(
            get: { selected },
            set: { picked in
                picker = nil
                pick(picked)
            }
        ), vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, FlareSizes.spacingLg)
        .padding(.bottom, FlareSizes.spacingLg)
    }

    /// Seven day switches; the last day left cannot be turned off.
    private var weekdaySection: FlareSettingsSection {
        let mask = value.quietHours.weekdays
        let onCount = (0..<7).filter { weekdayIsOn(mask, day: $0) }.count
        return FlareSettingsSection(items: (0..<7).map { day in
            let on = weekdayIsOn(mask, day: day)
            return FlareSettingsItem(key: "\(Self.weekdayPrefix)\(day)", label: weekdayName(day, strings: strings),
                                     kind: .toggle, value: on, disabled: on && onCount == 1)
        })
    }

    func toggleDay(_ item: FlareSettingsItem, _ on: Bool) {
        guard item.key.hasPrefix(Self.weekdayPrefix),
              let day = Int(item.key.dropFirst(Self.weekdayPrefix.count)) else { return }
        let mask = value.quietHours.weekdays
        let next = weekdayToggle(mask, day: day, on: on)
        if next != mask { changeQuietHours { $0.weekdays = next } }
    }
}

public extension NotificationAlertSettingsView where SectionContent == SettingsListView {
    /// The sections as a list of their own that sizes to its content.
    init(value: FlareNotificationAlertPreferences, disabled: Bool = false,
         onChange: ((FlareNotificationAlertPreferences) -> Void)? = nil) {
        self.init(value: value, disabled: disabled, onChange: onChange) { sections, select, toggle in
            SettingsListView(sections: sections, onToggle: { _ = toggle($0, $1) }, onSelect: { _ = select($0) },
                             scrollable: false)
        }
    }
}
