import Foundation

/// The CLDR cardinal rule families the kit tells apart (spec/plural-vectors.json `rules`). The kit's copy has the
/// `one` and `other` forms only, so every other category (two, few, many, zero) reads as `other`.
public enum FlarePluralFamily: String, Sendable, CaseIterable {
    /// Never `one` (zh, ja, ko, th, vi, …).
    case none
    /// `one` when n = 1 (en, de, es, it, pl, ar, pt-PT, …).
    case is1
    /// `one` when n is 0 or 1 (fr, pt, hi, bn, fa, …).
    case is0or1
    /// `one` when n % 10 = 1 and n % 100 ≠ 11 (ru, uk, be, hr, sr, bs).
    case mod10is1

    /// Whether `count` (a non-negative integer) takes the `one` form in this family.
    public func isOne(_ count: Int) -> Bool {
        switch self {
        case .none: return false
        case .is1: return count == 1
        case .is0or1: return count == 0 || count == 1
        case .mod10is1: return count % 10 == 1 && count % 100 != 11
        }
    }
}

/// The rule table, by language subtag. A language not listed is `is1`.
private let flarePluralLanguages: [String: FlarePluralFamily] = {
    var table: [String: FlarePluralFamily] = [:]
    for language in ["zh", "ja", "ko", "th", "vi", "id", "ms", "yue", "lo", "my", "km"] { table[language] = FlarePluralFamily.none }
    for language in ["en", "de", "nl", "sv", "da", "nb", "nn", "no", "fi", "et", "it", "es", "ca", "el", "hu", "tr",
                     "pl", "cs", "sk", "he", "ar", "bg", "ro", "sw", "ur", "af", "eu", "gl", "sq", "az", "kk", "ka",
                     "ky", "mn", "uz", "ta", "te", "ml", "mr", "ne"] { table[language] = .is1 }
    for language in ["fr", "pt", "hi", "bn", "fa", "gu", "kn", "am", "zu"] { table[language] = .is0or1 }
    for language in ["ru", "uk", "be", "hr", "sr", "bs"] { table[language] = .mod10is1 }
    return table
}()

/// The plural family of a locale identifier (`en-US`, `pt_PT`, `zh-Hans-CN`): the language subtag picks the family,
/// except Portuguese in Portugal, which is `is1` where every other Portuguese is `is0or1`.
public func flarePluralFamily(localeIdentifier: String) -> FlarePluralFamily {
    let parts = localeIdentifier.split(whereSeparator: { $0 == "-" || $0 == "_" }).map(String.init)
    let language = parts.first?.lowercased() ?? ""
    if language == "pt" {
        let region = parts.dropFirst().first { $0.count == 2 && $0.allSatisfy(\.isLetter) }?.uppercased()
        return region == "PT" ? .is1 : .is0or1
    }
    return flarePluralLanguages[language] ?? .is1
}

/// Whether `count` takes the `one` form in `locale` (spec/plural-vectors.json). SwiftUI has no public plural rule
/// interface, so the kit reads its own table; the four kits agree on every case of the vectors.
public func flarePluralIsOne(_ count: Int, locale: Locale) -> Bool {
    flarePluralFamily(localeIdentifier: locale.identifier).isOne(count)
}

/// Picks the copy for `count`: `one` when the locale's rule says so, else `other`. The `{count}` placeholder is
/// left for the caller.
public func flarePlural(_ count: Int, one: String, other: String, locale: Locale) -> String {
    flarePluralIsOne(count, locale: locale) ? one : other
}

public extension FlareStrings {
    /// "N 票" / "1 vote" for a count (`pluginViewVotes` / `pluginViewVotesOne`).
    func pluginViewVotesText(_ count: Int, locale: Locale) -> String {
        flarePlural(count, one: pluginViewVotesOne, other: pluginViewVotes, locale: locale)
            .replacingOccurrences(of: "{count}", with: String(count))
    }

    /// "N 人" / "1 person" (`myInviteCountOnly` / `myInviteCountOnlyOne`).
    func myInviteCountOnlyText(_ count: Int, locale: Locale) -> String {
        flarePlural(count, one: myInviteCountOnlyOne, other: myInviteCountOnly, locale: locale)
            .replacingOccurrences(of: "{count}", with: String(count))
    }

    /// The merged-forward card's subtitle "共 N 条消息" (`forwardRecordTotal` / `forwardRecordTotalOne`).
    func forwardRecordTotalText(_ count: Int, locale: Locale) -> String {
        flarePlural(count, one: forwardRecordTotalOne, other: forwardRecordTotal, locale: locale)
            .replacingOccurrences(of: "{count}", with: String(count))
    }

    /// The merged-forward card's "还有 N 条消息…" (`forwardRecordMore` / `forwardRecordMoreOne`).
    func forwardRecordMoreText(_ count: Int, locale: Locale) -> String {
        flarePlural(count, one: forwardRecordMoreOne, other: forwardRecordMore, locale: locale)
            .replacingOccurrences(of: "{count}", with: String(count))
    }
}
