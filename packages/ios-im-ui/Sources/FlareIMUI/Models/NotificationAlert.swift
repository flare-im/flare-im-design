import Foundation

/// What a notification shows: the sender and the message, the sender only, or neither.
public enum FlareNotificationPreview: String, CaseIterable, Sendable {
    case full, senderOnly, hidden
}

/// How the phone alerts while the person is using another device.
public enum FlareMultiDeviceAlert: String, CaseIterable, Sendable {
    case delay, immediate, badgeOnly
}

/// When new messages arrive silently, in device local time. The protocol's shape: minutes after midnight, `weekdays`
/// as bits (bit 0 Monday … bit 6 Sunday, 0 every day); an `endMinute` not after `startMinute` is on the next day.
public struct FlareQuietHours: Equatable, Sendable {
    public var enabled: Bool
    public var startMinute: Int
    public var endMinute: Int
    public var weekdays: Int
    public var allowMentions: Bool

    public init(enabled: Bool = false, startMinute: Int = 22 * 60, endMinute: Int = 8 * 60, weekdays: Int = 0,
                allowMentions: Bool = true) {
        self.enabled = enabled; self.startMinute = startMinute; self.endMinute = endMinute
        self.weekdays = weekdays; self.allowMentions = allowMentions
    }
}

/// A person's notification preferences as ``NotificationAlertSettingsView`` edits them. The default is what a person
/// who never chose has: quiet hours off (22:00 to 08:00 every day, mentions allowed), full preview, delay.
public struct FlareNotificationAlertPreferences: Equatable, Sendable {
    public var quietHours: FlareQuietHours
    public var preview: FlareNotificationPreview
    public var multiDevice: FlareMultiDeviceAlert

    public init(quietHours: FlareQuietHours = FlareQuietHours(), preview: FlareNotificationPreview = .full,
                multiDevice: FlareMultiDeviceAlert = .delay) {
        self.quietHours = quietHours; self.preview = preview; self.multiDevice = multiDevice
    }
}

/// Every day, as bits. 0 means the same.
public let allWeekdays = 0x7f

/// The minute step of the start and end pickers.
public let quietHoursMinuteStep = 5

private let minutesPerDay = 24 * 60

/// A minute of the day as HH:mm, 24-hour; minutes are taken modulo a day.
public func formatMinuteOfDay(_ minute: Int) -> String {
    let m = ((minute % minutesPerDay) + minutesPerDay) % minutesPerDay
    let hours = String(m / 60), minutes = String(m % 60)
    return (hours.count < 2 ? "0" + hours : hours) + ":" + (minutes.count < 2 ? "0" + minutes : minutes)
}

/// HH:mm as a minute of the day; anything else reads as midnight.
public func parseMinuteOfDay(_ text: String) -> Int {
    let parts = text.split(separator: ":")
    guard parts.count >= 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return 0 }
    return min(23, max(0, h)) * 60 + min(59, max(0, m))
}

/// Whether the end is on the next day: it is not after the start.
public func quietHoursEndsNextDay(_ quietHours: FlareQuietHours) -> Bool {
    quietHours.endMinute <= quietHours.startMinute
}

/// Whether `day` (0 Monday … 6 Sunday) is in `mask`; 0 is every day.
public func weekdayIsOn(_ mask: Int, day: Int) -> Bool {
    let days = mask & allWeekdays
    return days == 0 || days & (1 << day) != 0
}

/// `mask` with `day` turned on or off. 0 starts from all seven; all seven is written 0; no day left changes nothing.
public func weekdayToggle(_ mask: Int, day: Int, on: Bool) -> Int {
    let days = mask & allWeekdays == 0 ? allWeekdays : mask & allWeekdays
    let next = on ? days | (1 << day) : days & ~(1 << day)
    if next == 0 { return mask }
    return next == allWeekdays ? 0 : next
}

/// How a weekday mask reads: every day, Monday to Friday, the weekend, or the days in week order.
public enum FlareWeekdaySummary: Equatable, Sendable {
    case everyDay, weekdays, weekends
    case days([Int])
}

public func weekdaySummary(_ mask: Int) -> FlareWeekdaySummary {
    let days = mask & allWeekdays
    switch days {
    case 0, allWeekdays: return .everyDay
    case 0x1f: return .weekdays
    case 0x60: return .weekends
    default: return .days((0..<7).filter { days & (1 << $0) != 0 })
    }
}

/// The name of `day` (0 Monday … 6 Sunday) in `strings`.
public func weekdayName(_ day: Int, strings: FlareStrings = FlareStrings()) -> String {
    switch day {
    case 0: return strings.weekdayMonday
    case 1: return strings.weekdayTuesday
    case 2: return strings.weekdayWednesday
    case 3: return strings.weekdayThursday
    case 4: return strings.weekdayFriday
    case 5: return strings.weekdaySaturday
    default: return strings.weekdaySunday
    }
}

/// The words of the Repeat row for `mask`.
public func weekdaySummaryText(_ mask: Int, strings: FlareStrings = FlareStrings()) -> String {
    switch weekdaySummary(mask) {
    case .everyDay: return strings.weekdayEveryDay
    case .weekdays: return strings.weekdayWeekdays
    case .weekends: return strings.weekdayWeekends
    case .days(let days): return days.map { weekdayName($0, strings: strings) }.joined(separator: strings.displayNameSeparator)
    }
}

/// The words of the Ends row: the time, on the next day when it is not after the start.
public func quietHoursEndText(_ quietHours: FlareQuietHours, strings: FlareStrings = FlareStrings()) -> String {
    let time = formatMinuteOfDay(quietHours.endMinute)
    return quietHoursEndsNextDay(quietHours) ? strings.quietHoursNextDay(time) : time
}

/// The words of `preview` in a settings row.
public func notificationPreviewText(_ preview: FlareNotificationPreview, strings: FlareStrings = FlareStrings()) -> String {
    switch preview {
    case .full: return strings.notificationPreviewFull
    case .senderOnly: return strings.notificationPreviewSenderOnly
    case .hidden: return strings.notificationPreviewHidden
    }
}

/// The words of `policy` in a settings row.
public func multiDeviceAlertText(_ policy: FlareMultiDeviceAlert, strings: FlareStrings = FlareStrings()) -> String {
    switch policy {
    case .delay: return strings.multiDeviceDelay
    case .immediate: return strings.multiDeviceImmediate
    case .badgeOnly: return strings.multiDeviceBadgeOnly
    }
}
