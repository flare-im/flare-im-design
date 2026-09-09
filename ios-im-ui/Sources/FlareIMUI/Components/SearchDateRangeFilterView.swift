import Foundation
import SwiftUI

/// Inclusive UTC epoch milliseconds; absent bounds mean unrestricted.
public struct FlareSearchTimeRange: Equatable, Sendable {
    public let fromTime: Int64?
    public let toTime: Int64?
    public init(fromTime: Int64? = nil, toTime: Int64? = nil) {
        self.fromTime = fromTime; self.toTime = toTime
    }
}

/// The two local date strings a pair of DatePickers is bound to; "" means unset.
public struct FlareSearchDateDraft: Equatable, Sendable {
    public let from: String
    public let to: String
    public init(from: String, to: String) { self.from = from; self.to = to }
}

public func sameSearchTimeRange(_ a: FlareSearchTimeRange, _ b: FlareSearchTimeRange) -> Bool {
    a.fromTime == b.fromTime && a.toTime == b.toTime
}

private let maxSafeInteger: Int64 = 9_007_199_254_740_991

private func searchDateParts(_ date: String) -> (year: Int, month: Int, day: Int)? {
    let trimmed = date.trimmingCharacters(in: .whitespacesAndNewlines)
    let parts = trimmed.split(separator: "-", omittingEmptySubsequences: false)
    guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
          parts.allSatisfy({ $0.allSatisfy { $0.isASCII && $0.isNumber } }),
          let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]),
          month >= 1, month <= 12, day >= 1, day <= 31 else { return nil }
    return (year, month, day)
}

private func searchCalendar(_ tzOffsetMinutes: Int?) -> Calendar? {
    var calendar = Calendar(identifier: .gregorian)
    if let tzOffsetMinutes {
        guard let zone = TimeZone(secondsFromGMT: tzOffsetMinutes * 60) else { return nil }
        calendar.timeZone = zone
    } else {
        calendar.timeZone = TimeZone.current
    }
    return calendar
}

private func atLocalTime(_ date: String, hour: Int, minute: Int, second: Int, millis: Int,
                         tzOffsetMinutes: Int?) -> Int64? {
    guard let parts = searchDateParts(date), let calendar = searchCalendar(tzOffsetMinutes) else { return nil }
    var components = DateComponents()
    components.year = parts.year; components.month = parts.month; components.day = parts.day
    components.hour = hour; components.minute = minute; components.second = second
    components.nanosecond = millis * 1_000_000
    guard let moment = calendar.date(from: components) else { return nil }
    // Rejects 2026-02-30 and friends, which the calendar would silently roll over.
    let check = calendar.dateComponents([.year, .month, .day], from: moment)
    guard check.year == parts.year, check.month == parts.month, check.day == parts.day else { return nil }
    return Int64((moment.timeIntervalSince1970 * 1000).rounded())
}

/// Inclusive lower bound: 00:00:00.000 of `date`; `nil` when the string is not a real date.
/// `tzOffsetMinutes` is minutes **east of UTC** (UTC+8 → 480); omitted, the device zone
/// for that calendar date is used.
public func dayStartMs(_ date: String, tzOffsetMinutes: Int? = nil) -> Int64? {
    atLocalTime(date, hour: 0, minute: 0, second: 0, millis: 0, tzOffsetMinutes: tzOffsetMinutes)
}

/// Inclusive upper bound: 23:59:59.999 of `date`; `nil` for a non-date.
public func dayEndMs(_ date: String, tzOffsetMinutes: Int? = nil) -> Int64? {
    atLocalTime(date, hour: 23, minute: 59, second: 59, millis: 999, tzOffsetMinutes: tzOffsetMinutes)
}

private func usableTime(_ time: Int64?) -> Bool {
    guard let time else { return false }
    return time >= 0 && time <= maxSafeInteger
}

/// Build the range two DatePickers describe. Both blank is *unrestricted* (an empty range),
/// not an error. `nil` means the host must not submit: an unparsable date, an instant before
/// the epoch, or `from` after `to`.
public func rangeFromDates(_ from: String, _ to: String,
                           tzOffsetMinutes: Int? = nil) -> FlareSearchTimeRange? {
    var fromTime: Int64?
    var toTime: Int64?
    if !from.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        let parsed = dayStartMs(from, tzOffsetMinutes: tzOffsetMinutes)
        guard usableTime(parsed) else { return nil }
        fromTime = parsed
    }
    if !to.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        let parsed = dayEndMs(to, tzOffsetMinutes: tzOffsetMinutes)
        guard usableTime(parsed) else { return nil }
        toTime = parsed
    }
    if let fromTime, let toTime, fromTime > toTime { return nil }
    return FlareSearchTimeRange(fromTime: fromTime, toTime: toTime)
}

private func dateString(_ time: Int64?, _ tzOffsetMinutes: Int?) -> String {
    guard let time, time >= 0, let calendar = searchCalendar(tzOffsetMinutes) else { return "" }
    let moment = Date(timeIntervalSince1970: Double(time) / 1000)
    let parts = calendar.dateComponents([.year, .month, .day], from: moment)
    guard let year = parts.year, let month = parts.month, let day = parts.day else { return "" }
    return String(format: "%04d-%02d-%02d", year, month, day)
}

/// Fill the DatePickers back from a range; an absent bound stays "".
public func datesFromRange(_ range: FlareSearchTimeRange,
                           tzOffsetMinutes: Int? = nil) -> FlareSearchDateDraft {
    FlareSearchDateDraft(from: dateString(range.fromTime, tzOffsetMinutes),
                         to: dateString(range.toTime, tzOffsetMinutes))
}

/// Neither bound set — the "no time limit" state.
public func unrestrictedRange(_ range: FlareSearchTimeRange) -> Bool {
    range.fromTime == nil && range.toTime == nil
}

/// Which preset chip is selected. Matching is by value, not by id, because a host may
/// rebuild its option objects on every render.
public func matchedOptionId(_ value: FlareSearchTimeRange,
                            _ options: [FlareSearchRangeOption]) -> String? {
    options.first { $0.fromTime == value.fromTime && $0.toTime == value.toTime }?.id
}

/// Whether the custom start/end area is expanded: never without `allowCustom`, always when
/// the host forces it, otherwise whenever the current value is a real range no preset covers.
public func shouldOpenCustomRange(_ value: FlareSearchTimeRange, _ options: [FlareSearchRangeOption],
                                  allowCustom: Bool, customActive: Bool = false) -> Bool {
    if !allowCustom { return false }
    if customActive { return true }
    return !unrestrictedRange(value) && matchedOptionId(value, options) == nil
}

/// Time-range filter for search. Host-supplied presets are chips; "custom" expands a start/end
/// pair built from `DatePickerView`. The view owns no clock — it never computes "today" itself —
/// and emits one `FlareSearchTimeRange` in inclusive UTC epoch milliseconds that the host folds
/// into its search criteria. Spec: General/SearchDateRangeFilter (`SearchDateRangeFilterView`).
public struct SearchDateRangeFilterView: View {
    let value: FlareSearchTimeRange
    let options: [FlareSearchRangeOption]
    let allowCustom: Bool
    let customActive: Bool
    let minDate: String?
    let maxDate: String?
    let tzOffsetMinutes: Int?
    let disabled: Bool
    let title: String
    let customText: String
    let fromLabel: String
    let toLabel: String
    let clearText: String
    let unlimitedText: String
    let invalidText: String
    let onChange: (FlareSearchTimeRange) -> Void
    let onClear: (() -> Void)?

    @Environment(\.colorScheme) private var scheme
    @ScaledMetric private var bodySize: CGFloat = FlareSizes.fontSizeMd
    @State private var draft: FlareSearchDateDraft
    @State private var customOpen: Bool

    public init(value: FlareSearchTimeRange, options: [FlareSearchRangeOption] = [],
                allowCustom: Bool = true, customActive: Bool = false,
                minDate: String? = nil, maxDate: String? = nil, tzOffsetMinutes: Int? = nil,
                disabled: Bool = false, title: String = "时间范围", customText: String = "自定义",
                fromLabel: String = "起始日期", toLabel: String = "结束日期",
                clearText: String = "清除", unlimitedText: String = "不限时间",
                invalidText: String = "起始日期不能晚于结束日期",
                onChange: @escaping (FlareSearchTimeRange) -> Void, onClear: (() -> Void)? = nil) {
        self.value = value; self.options = options; self.allowCustom = allowCustom
        self.customActive = customActive; self.minDate = minDate; self.maxDate = maxDate
        self.tzOffsetMinutes = tzOffsetMinutes; self.disabled = disabled; self.title = title
        self.customText = customText; self.fromLabel = fromLabel; self.toLabel = toLabel
        self.clearText = clearText; self.unlimitedText = unlimitedText; self.invalidText = invalidText
        self.onChange = onChange; self.onClear = onClear
        _draft = State(initialValue: datesFromRange(value, tzOffsetMinutes: tzOffsetMinutes))
        _customOpen = State(initialValue: shouldOpenCustomRange(value, options, allowCustom: allowCustom,
                                                                customActive: customActive))
    }

    private var draftRange: FlareSearchTimeRange? {
        rangeFromDates(draft.from, draft.to, tzOffsetMinutes: tzOffsetMinutes)
    }
    private var invalid: Bool { allowCustom && draftRange == nil }
    private var showCustom: Bool { allowCustom && customOpen }

    private var summary: String {
        if unrestrictedRange(value) { return unlimitedText }
        if let id = matchedOptionId(value, options), let preset = options.first(where: { $0.id == id }) {
            return preset.label
        }
        let dates = datesFromRange(value, tzOffsetMinutes: tzOffsetMinutes)
        var parts: [String] = []
        if !dates.from.isEmpty { parts.append("\(fromLabel) \(dates.from)") }
        if !dates.to.isEmpty { parts.append("\(toLabel) \(dates.to)") }
        return parts.isEmpty ? unlimitedText : parts.joined(separator: " · ")
    }

    private func choose(_ option: FlareSearchRangeOption) {
        guard !disabled, option.isValid else { return }
        let next = FlareSearchTimeRange(fromTime: option.fromTime, toTime: option.toTime)
        guard !sameSearchTimeRange(next, value) else { return }
        onChange(next)
    }

    private func commit() {
        // An illegal draft stays on screen and emits nothing.
        guard let range = draftRange, !sameSearchTimeRange(range, value) else { return }
        onChange(range)
    }

    private func pick(from: String? = nil, to: String? = nil) {
        guard !disabled else { return }
        draft = FlareSearchDateDraft(from: from ?? draft.from, to: to ?? draft.to)
        commit()
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        let selectedId = matchedOptionId(value, options)
        VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
            Text(title).font(.system(size: FlareSizes.fontSizeXl, weight: .semibold))
                .foregroundColor(colors.textPrimary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: FlareSizes.spacingSm)],
                      spacing: FlareSizes.spacingSm) {
                ForEach(options) { option in
                    chip(option.label, icon: nil, selected: selectedId == option.id,
                         disabled: disabled || !option.isValid, colors: colors) { choose(option) }
                }
                if allowCustom {
                    chip(customText, icon: "calendar", selected: showCustom,
                         disabled: disabled, colors: colors) { customOpen.toggle() }
                        .accessibilityHint(showCustom ? "collapse" : "expand")
                }
            }

            if showCustom {
                VStack(alignment: .leading, spacing: FlareSizes.spacingMd) {
                    field(fromLabel, value: draft.from, colors: colors) { pick(from: $0) }
                    field(toLabel, value: draft.to, colors: colors) { pick(to: $0) }
                }
                .padding(FlareSizes.spacingMd)
                .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgSecondary))
            }

            if invalid {
                HStack(alignment: .top, spacing: FlareSizes.spacingXs) {
                    IconView("warning", size: 16, color: colors.warning).accessibilityHidden(true)
                    Text(invalidText).font(.system(size: bodySize)).foregroundColor(colors.warning)
                }
                .accessibilityElement(children: .combine)
            }

            HStack(spacing: FlareSizes.spacingSm) {
                Text(summary).font(.system(size: bodySize)).foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.updatesFrequently)
                if let onClear, !unrestrictedRange(value) {
                    Button(action: onClear) {
                        Text(clearText).font(.system(size: bodySize))
                            .foregroundColor(disabled ? colors.textDisabled : colors.textPrimary)
                            .padding(.horizontal, FlareSizes.spacingMd)
                            .frame(minWidth: FlareSizes.touchTarget, minHeight: FlareSizes.touchTarget)
                            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
                                .fill(disabled ? colors.bgDisabled : colors.bgPrimary))
                            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
                                .stroke(colors.borderPrimary, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(disabled)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
        .onChange(of: value) { next in
            // Re-seed the pickers only when the host pushes a range the current draft does
            // not already describe — an illegal draft must survive until it is fixed.
            let current = rangeFromDates(draft.from, draft.to, tzOffsetMinutes: tzOffsetMinutes)
            if current == nil || !sameSearchTimeRange(current!, next) {
                draft = datesFromRange(next, tzOffsetMinutes: tzOffsetMinutes)
            }
            if shouldOpenCustomRange(next, options, allowCustom: allowCustom, customActive: customActive) {
                customOpen = true
            }
        }
    }

    @ViewBuilder
    private func chip(_ label: String, icon: String?, selected: Bool, disabled: Bool,
                      colors: FlareColors, action: @escaping () -> Void) -> some View {
        let foreground = disabled ? colors.textDisabled : (selected ? colors.primary : colors.textPrimary)
        Button(action: action) {
            HStack(spacing: FlareSizes.spacingXs) {
                if let icon { IconView(icon, size: 16, color: foreground).accessibilityHidden(true) }
                Text(label).font(.system(size: FlareSizes.fontSizeLg)).foregroundColor(foreground)
                    .lineLimit(2).multilineTextAlignment(.center)
            }
            .padding(.horizontal, FlareSizes.spacingMd)
            .frame(maxWidth: .infinity, minHeight: FlareSizes.touchTarget)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusFull)
                .fill(disabled ? colors.bgDisabled : (selected ? colors.bgSelected : colors.bgPrimary)))
            .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusFull)
                .stroke(selected && !disabled ? colors.primary : colors.borderPrimary, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : [.isButton])
    }

    @ViewBuilder
    private func field(_ label: String, value fieldValue: String, colors: FlareColors,
                       onPick: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: FlareSizes.spacingXs) {
            Text(label).font(.system(size: bodySize)).foregroundColor(colors.textSecondary)
            HStack(spacing: FlareSizes.spacingXs) {
                DatePickerView(
                    value: Binding(get: { fieldValue }, set: { onPick($0) }),
                    placeholder: label, size: .lg, min: minDate, max: maxDate,
                    title: label, disabled: disabled
                )
                if !fieldValue.isEmpty {
                    Button { onPick("") } label: {
                        IconView("close", size: 14, color: colors.textSecondary)
                            .frame(minWidth: FlareSizes.touchTarget, minHeight: FlareSizes.touchTarget)
                    }
                    .buttonStyle(.plain)
                    .disabled(disabled)
                    .accessibilityLabel("\(clearText) \(label)")
                }
            }
        }
    }
}
