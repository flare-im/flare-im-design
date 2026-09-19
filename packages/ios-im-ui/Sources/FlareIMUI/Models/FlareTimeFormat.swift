import Foundation

/// Locale-aware time labels for message and conversation rows — the rule every platform shares.
///
/// `messageTime` is the clock in the locale's convention: a two-digit hour in 24-hour locales
/// ("09:05"), the numeric hour with the day period in 12-hour ones ("9:05 AM").
/// `conversationTime` is that clock on the same calendar day, `yesterday` on the previous one,
/// the numeric month and day within the same year, and the numeric year, month and day before
/// it — each in the locale's order. Days and years are counted in the local time zone.
public enum FlareTimeFormat {
    public static func messageTime(_ date: Date, locale: Locale = .current) -> String {
        formatter(clockPattern(locale), locale).string(from: date)
    }

    public static func conversationTime(_ date: Date, yesterday: String, locale: Locale = .current,
                                        now: Date = Date()) -> String {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: now) { return messageTime(date, locale: locale) }
        if let previousDay = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: previousDay) {
            return yesterday
        }
        let template = calendar.isDate(date, equalTo: now, toGranularity: .year) ? "Md" : "yMd"
        return formatter(pattern(template, locale), locale).string(from: date)
    }

    /// The label of a timeline date separator. Every bubble already shows its own time, so separators
    /// mark days only: `today` and `yesterday` (the host's words) for those days, then the locale's
    /// numeric month and day within the current year, and its year, month and day before it. Absolute,
    /// so a separator never goes stale while the conversation stays open.
    public static func timelineDateLabel(_ date: Date, today: String, yesterday: String,
                                         locale: Locale = .current, now: Date = Date()) -> String {
        let zone = TimeZone.current
        let day = localDay(date, zone)
        let currentDay = localDay(now, zone)
        if day == currentDay { return today }
        if day == currentDay - 1 { return yesterday }
        let calendar = Calendar.current
        let template = calendar.isDate(date, equalTo: now, toGranularity: .year) ? "Md" : "yMd"
        return formatter(pattern(template, locale), locale).string(from: date)
    }

    /// True when a timeline date separator belongs before a message sent at `currentMs`: the first
    /// dated message (`previousMs` is 0), or the first one on another local calendar day. Undated
    /// messages (0) never start a day. Decided on day numbers in `timeZone`, never on formatted text,
    /// so a timeline can ask for every row.
    public static func startsTimelineDay(previousMs: Int64, currentMs: Int64, timeZone: TimeZone = .current) -> Bool {
        guard currentMs > 0 else { return false }
        guard previousMs > 0 else { return true }
        return localDay(milliseconds: previousMs, timeZone) != localDay(milliseconds: currentMs, timeZone)
    }

    /// The local calendar day as a number: days since the epoch in `zone`, counted from local midnight.
    static func localDay(_ date: Date, _ zone: TimeZone) -> Int {
        let local = date.timeIntervalSince1970 + TimeInterval(zone.secondsFromGMT(for: date))
        return Int((local / 86_400).rounded(.down))
    }

    static func localDay(milliseconds: Int64, _ zone: TimeZone) -> Int {
        localDay(Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000), zone)
    }

    /// The locale's hour-and-minute pattern; in a 24-hour locale the hour is widened to two digits
    /// ("H:mm" → "HH:mm"). Quoted literals ("HH 'h' mm") are left as they are.
    static func clockPattern(_ locale: Locale) -> String {
        let pattern = DateFormatter.dateFormat(fromTemplate: "jm", options: 0, locale: locale) ?? "HH:mm"
        var fields = ""
        var quoted = false
        for character in pattern {
            if character == "'" { quoted.toggle() } else if !quoted { fields.append(character) }
        }
        // h / K count a 12-hour clock; a / b / B are its day periods.
        guard !fields.contains(where: { "hKabB".contains($0) }) else { return pattern }
        var widened = ""
        var previous: Character?
        quoted = false
        for character in pattern {
            if character == "'" { quoted.toggle() }
            let hourField = !quoted && (character == "H" || character == "k")
            if hourField {
                // Emit each run of the hour field once, two letters wide.
                if previous != character { widened.append(character); widened.append(character) }
            } else {
                widened.append(character)
            }
            previous = hourField ? character : nil
        }
        return widened
    }

    private static let cache = NSCache<NSString, DateFormatter>()
    private static let patterns = NSCache<NSString, NSString>()

    /// The locale's pattern for a date `template` ("Md", "yMd"), resolved once per locale.
    private static func pattern(_ template: String, _ locale: Locale) -> String {
        let key = "\(locale.identifier)|\(template)" as NSString
        if let cached = patterns.object(forKey: key) { return cached as String }
        let resolved = DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: locale) ?? template
        patterns.setObject(resolved as NSString, forKey: key)
        return resolved
    }

    private static func formatter(_ pattern: String, _ locale: Locale) -> DateFormatter {
        let key = "\(locale.identifier)|\(pattern)" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = pattern
        cache.setObject(formatter, forKey: key)
        return formatter
    }
}
