import Foundation

// Red packet v5 presentation rules (docs/design/red-packet-v5-roles-and-wallet.md §1–§3). Pure, so
// spec/red-packet-vectors.json runs against them directly; the card, the open sheet and the details page only draw
// what these return. The server decides every claim, role and amount: the kit never computes eligibility, and an
// amount the server did not return is never drawn.

extension FlareRedPacketKind: Codable {}

/// The plugin's packet status (public layer).
public enum FlareRedPacketStatus: String, Sendable, CaseIterable, Codable {
    case open, completed, expired, refunded
}

/// Where a tap on the card goes, from the viewer's personal layer (`flare.redpacket.view`).
public enum FlareRedPacketTapAction: String, Sendable, CaseIterable, Codable {
    /// The open sheet with 開.
    case open
    /// The details page.
    case details
    /// The open sheet saying "仅 某某 可领取".
    case notEligible
}

/// Who is looking at the details, as the server decided.
public enum FlareRedPacketViewerRole: String, Sendable, CaseIterable, Codable {
    case sender, claimer, eligible, ineligible
}

/// What a red packet card shows (`spec/red-packet-vectors.json` cardState). Never an amount.
public enum FlareRedPacketCardState: String, Sendable, CaseIterable {
    /// Open, and the viewer may open it (or the personal layer has not answered yet).
    case unopened
    /// Open, and the viewer looks rather than opens: the sender, or a viewer the packet is not for.
    case viewable
    /// The viewer took a share.
    case claimed
    /// Every share is taken.
    case finished
    case expired
    case refunded
}

/// The card state from the public layer (`status`) and the viewer's personal layer (`claimedByMe`, `tapAction`):
/// a share the viewer took wins; then completed, expired and refunded; an open packet is viewable when the viewer's
/// tap goes to the details or the not-eligible notice, else unopened.
public func flareRedPacketCardState(status: FlareRedPacketStatus, claimedByMe: Bool = false,
                                    tapAction: FlareRedPacketTapAction? = nil) -> FlareRedPacketCardState {
    if claimedByMe { return .claimed }
    switch status {
    case .completed: return .finished
    case .expired: return .expired
    case .refunded: return .refunded
    case .open: return tapAction == .details || tapAction == .notEligible ? .viewable : .unopened
    }
}

/// The card's status line (`spec/red-packet-vectors.json` card): its copy, in precedence order.
public enum FlareRedPacketCardStatus: Equatable, Sendable {
    case busy
    /// The host's text, as given.
    case statusLabel(String)
    case tapToOpen, view, claimed, finished, expired, refunded, unavailable

    public func text(_ strings: FlareStrings) -> String {
        switch self {
        case .busy: return strings.packetBusy
        case .statusLabel(let label): return label
        case .tapToOpen: return strings.packetTapToClaim
        case .view: return strings.packetView
        case .claimed: return strings.packetStateClaimed
        case .finished: return strings.packetFinished
        case .expired: return strings.packetStateExpired
        case .refunded: return strings.packetRefunded
        case .unavailable: return strings.packetUnavailable
        }
    }
}

public enum FlareRedPacketCardRules {
    /// The status line: busy, the host's label, then the state; an unopened card that is disabled is unavailable.
    public static func status(state: FlareRedPacketCardState, statusLabel: String?, busy: Bool,
                              disabled: Bool) -> FlareRedPacketCardStatus {
        if busy { return .busy }
        if let statusLabel { return .statusLabel(statusLabel) }
        switch state {
        case .unopened: return disabled ? .unavailable : .tapToOpen
        case .viewable: return .view
        case .claimed: return .claimed
        case .finished: return .finished
        case .expired: return .expired
        case .refunded: return .refunded
        }
    }

    /// Spent states recede (`faded`); busy and disabled keep the face of their state.
    public static func faded(_ state: FlareRedPacketCardState) -> Bool {
        state == .claimed || state == .finished || state == .expired || state == .refunded
    }

    /// Every state taps through (the host routes by `tapAction`); busy and disabled do not.
    public static func tappable(busy: Bool, disabled: Bool) -> Bool { !busy && !disabled }

    /// The kind badge on the brand line: lucky and exclusive have one, normal none.
    public static func badge(_ kind: FlareRedPacketKind?, strings: FlareStrings) -> String? {
        switch kind {
        case .lucky?: return strings.packetBadgeLucky
        case .exclusive?: return strings.packetBadgeExclusive
        default: return nil
        }
    }

    /// "给 某某" on an exclusive packet whose designated member the host named.
    public static func recipient(_ kind: FlareRedPacketKind?, name: String?, strings: FlareStrings) -> String? {
        guard kind == .exclusive, let name = name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return nil
        }
        return strings.packetForRecipient.replacingOccurrences(of: "{name}", with: name)
    }
}

// MARK: - Money

/// Amounts from minor units (`spec/red-packet-vectors.json` amount): integer string arithmetic, never floating point.
public enum FlareRedPacketMoney {
    /// The currency symbols the kit knows; any other currency is written "{CODE} {text}".
    public static let symbols: [String: String] = ["CNY": "¥", "JPY": "¥", "USD": "$", "EUR": "€", "GBP": "£", "HKD": "HK$"]

    /// `minor` (ASCII digits) as a decimal with exactly `exponent` fraction digits, leading zeros folded, no
    /// grouping; nil for an empty or non-digit string.
    public static func text(minor: String, exponent: Int) -> String? {
        guard !minor.isEmpty, minor.unicodeScalars.allSatisfy({ $0.value >= 48 && $0.value <= 57 }) else { return nil }
        let digits = max(0, exponent)
        var raw = String(minor.drop { $0 == "0" })
        if raw.count <= digits { raw = String(repeating: "0", count: digits - raw.count + 1) + raw }
        guard digits > 0 else { return raw }
        let split = raw.index(raw.endIndex, offsetBy: -digits)
        return "\(raw[..<split]).\(raw[split...])"
    }

    /// The amount with its currency: the symbol before the text, or "{CODE} {text}".
    public static func money(minor: String?, exponent: Int, currency: String) -> String? {
        guard let minor, let text = text(minor: minor, exponent: exponent) else { return nil }
        if let symbol = symbols[currency.uppercased()] { return symbol + text }
        return "\(currency) \(text)"
    }
}

// MARK: - Details

/// The plugin's details result for one viewer (`FlareRedPacketDetailsView`). Amounts the viewer may not see are
/// absent — the server leaves them out — and the page draws only what is here.
public struct FlareRedPacketDetailsView: Equatable, Sendable, Codable {
    public let viewerRole: FlareRedPacketViewerRole
    public let status: FlareRedPacketStatus
    public let kind: FlareRedPacketKind
    public let greeting: String
    public let currency: String
    public let currencyExponent: Int
    public let totalMinor: String?
    public let claimedMinor: String?
    public let refundedMinor: String?
    public let myAmountMinor: String?
    public let claimedCount: Int
    public let shareCount: Int
    public let createdAtMs: Int64
    public let completedAtMs: Int64?
    public let expiresAtMs: Int64
    public let refundedAtMs: Int64?
    public let claimsListed: Bool

    public init(viewerRole: FlareRedPacketViewerRole, status: FlareRedPacketStatus, kind: FlareRedPacketKind,
                greeting: String, currency: String, currencyExponent: Int, totalMinor: String? = nil,
                claimedMinor: String? = nil, refundedMinor: String? = nil, myAmountMinor: String? = nil,
                claimedCount: Int, shareCount: Int, createdAtMs: Int64, completedAtMs: Int64? = nil,
                expiresAtMs: Int64, refundedAtMs: Int64? = nil, claimsListed: Bool) {
        self.viewerRole = viewerRole; self.status = status; self.kind = kind; self.greeting = greeting
        self.currency = currency; self.currencyExponent = currencyExponent; self.totalMinor = totalMinor
        self.claimedMinor = claimedMinor; self.refundedMinor = refundedMinor; self.myAmountMinor = myAmountMinor
        self.claimedCount = claimedCount; self.shareCount = shareCount; self.createdAtMs = createdAtMs
        self.completedAtMs = completedAtMs; self.expiresAtMs = expiresAtMs; self.refundedAtMs = refundedAtMs
        self.claimsListed = claimsListed
    }
}

/// One row of the claim list: the host resolves name and avatar, the kit formats amount and time. `best` is the
/// server's best-luck mark.
public struct FlareRedPacketClaim: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let avatar: String?
    public let amountMinor: String
    public let claimedAtMs: Int64
    public let best: Bool

    public init(id: String, name: String, avatar: String? = nil, amountMinor: String, claimedAtMs: Int64,
                best: Bool = false) {
        self.id = id; self.name = name; self.avatar = avatar; self.amountMinor = amountMinor
        self.claimedAtMs = claimedAtMs; self.best = best
    }
}

/// What the details page draws for a viewer (`spec/red-packet-vectors.json` detail).
public struct FlareRedPacketDetailPresentation: Equatable, Sendable {
    /// The viewer's own amount, large, when the server returned it.
    public let amount: String?
    /// "已存入钱包" under that amount.
    public let deposited: Bool
    /// Why there is nothing for this viewer: too late, expired, or not for them.
    public let headline: String?
    public let summary: String?
    /// The claim list shows (the server said this viewer may see it).
    public let claims: Bool
    /// The sender's refund line.
    public let note: String?
}

public enum FlareRedPacketDetailRules {
    /// A time on the details page: HH:mm on today, else the plugin view's date-time pattern (with the year outside
    /// now's year).
    public static func time(_ ms: Int64, nowMs: Int64, strings: FlareStrings, utcOffsetMinutes: Int? = nil) -> String {
        let at = PluginViewFormat.wallClock(ms, utcOffsetMinutes: utcOffsetMinutes)
        let now = PluginViewFormat.wallClock(nowMs, utcOffsetMinutes: utcOffsetMinutes)
        if at.year == now.year, at.month == now.month, at.day == now.day {
            return PluginViewFormat.render("HH:mm", at)
        }
        return PluginViewFormat.dateTime(ms, nowMs: nowMs, strings, utcOffsetMinutes: utcOffsetMinutes)
    }

    /// How long something took: seconds below a minute, whole minutes below an hour, whole hours below a day, else
    /// whole days.
    public static func duration(ms: Int64, strings: FlareStrings) -> String {
        let seconds = max(0, ms / 1000)
        func unit(_ template: String, _ n: Int64) -> String { template.replacingOccurrences(of: "{n}", with: String(n)) }
        if seconds < 60 { return unit(strings.packetDurationSeconds, seconds) }
        if seconds < 3600 { return unit(strings.packetDurationMinutes, seconds / 60) }
        if seconds < 86_400 { return unit(strings.packetDurationHours, seconds / 3600) }
        return unit(strings.packetDurationDays, seconds / 86_400)
    }

    private static func fill(_ template: String, _ values: [String: String]) -> String {
        values.reduce(template) { $0.replacingOccurrences(of: "{\($1.key)}", with: $1.value) }
    }

    public static func presentation(_ d: FlareRedPacketDetailsView, designatedName: String?, nowMs: Int64,
                                    strings: FlareStrings, utcOffsetMinutes: Int? = nil) -> FlareRedPacketDetailPresentation {
        func money(_ minor: String?) -> String? {
            FlareRedPacketMoney.money(minor: minor, exponent: d.currencyExponent, currency: d.currency)
        }
        let amount = money(d.myAmountMinor)
        let ended = d.status == .expired || d.status == .refunded

        let headline: String?
        switch d.viewerRole {
        case .ineligible:
            let name = designatedName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            headline = name.isEmpty ? strings.packetNotEligible
                : strings.packetNotEligibleName.replacingOccurrences(of: "{name}", with: name)
        case .eligible where d.status == .completed: headline = strings.packetMissed
        case .eligible where ended: headline = strings.packetExpiredNotice
        default: headline = nil
        }

        var summary: String?
        if !(d.viewerRole == .ineligible || (d.viewerRole == .eligible && ended)) {
            let shares = String(d.shareCount)
            if d.status == .completed, let total = money(d.totalMinor), let completed = d.completedAtMs {
                summary = fill(strings.packetSummaryCompleted, [
                    "shares": shares, "totalMoney": total,
                    "duration": duration(ms: completed - d.createdAtMs, strings: strings)])
            } else if let total = money(d.totalMinor), let claimed = money(d.claimedMinor) {
                summary = fill(strings.packetSummarySender, [
                    "claimed": String(d.claimedCount), "shares": shares, "claimedMoney": claimed, "totalMoney": total])
            } else {
                summary = fill(strings.packetSummaryCount, ["claimed": String(d.claimedCount), "shares": shares])
            }
        }

        var note: String?
        if d.viewerRole == .sender {
            if d.status == .open {
                note = strings.packetRefundAt.replacingOccurrences(
                    of: "{time}", with: time(d.expiresAtMs, nowMs: nowMs, strings: strings, utcOffsetMinutes: utcOffsetMinutes))
            } else if ended, let refunded = d.refundedMinor, refunded.contains(where: { $0 != "0" }),
                      let text = money(refunded) {
                if let at = d.refundedAtMs {
                    note = fill(strings.packetRefundedNote, [
                        "money": text, "time": time(at, nowMs: nowMs, strings: strings, utcOffsetMinutes: utcOffsetMinutes)])
                } else {
                    note = strings.packetRefundedNote.replacingOccurrences(of: " · {time}", with: "")
                        .replacingOccurrences(of: "{time}", with: "").replacingOccurrences(of: "{money}", with: text)
                }
            }
        }

        return FlareRedPacketDetailPresentation(amount: amount, deposited: amount != nil, headline: headline,
                                                summary: summary, claims: d.claimsListed, note: note)
    }

    /// One claim row's amount and time.
    public static func claimRow(_ claim: FlareRedPacketClaim, currency: String, exponent: Int, nowMs: Int64,
                                strings: FlareStrings, utcOffsetMinutes: Int? = nil) -> (amount: String?, time: String) {
        (FlareRedPacketMoney.money(minor: claim.amountMinor, exponent: exponent, currency: currency),
         time(claim.claimedAtMs, nowMs: nowMs, strings: strings, utcOffsetMinutes: utcOffsetMinutes))
    }
}

// MARK: - Open sheet

public enum FlareRedPacketOpenRules {
    /// The open button is there while there is something to open.
    public static func showsCoin(_ state: FlareRedPacketOpenState) -> Bool {
        state == .ready || state == .opening || state == .error
    }

    /// The details key: a finished or expired packet the viewer may look into (`canViewDetails`, from the personal
    /// layer); never for a viewer it is not for.
    public static func showsDetails(_ state: FlareRedPacketOpenState, canViewDetails: Bool) -> Bool {
        (state == .finished || state == .expired) && canViewDetails
    }
}
