import Foundation

/// Where the IM connection stands: the core SDK's `connection://status` phase (Vue `FlareConnectionPhase`).
public enum FlareConnectionPhase: String, Sendable, CaseIterable {
    case idle, connecting, syncing, online, switching, reconnecting, waitingForNetwork, serviceUnavailable,
         actionRequired
}

/// The line's quality while online. Neither value shows a banner.
public enum FlareConnectionQuality: String, Sendable {
    case good, poor
}

/// Why the core stopped and waits for the user (actionRequired): the reasons the notice explains.
public enum FlareConnectionActionReason: String, Sendable, CaseIterable {
    case kicked, expired, upgradeRequired, tenantUnavailable
}

/// The core SDK's connection status as the host receives it from `connection://status`.
public struct FlareConnectionStatus: Equatable, Sendable {
    public var phase: FlareConnectionPhase
    /// online: the line's quality.
    public var quality: FlareConnectionQuality?
    /// syncing: how far the catch-up has come, 0 to 1.
    public var progress: Double?
    /// reconnecting: when the next attempt starts, epoch milliseconds on the device clock.
    public var nextRetryAt: Int64?
    /// reconnecting: which attempt this is. Not shown.
    public var attempt: Int?
    /// Why, as the SDK says it: actionRequired gives kicked, expired, upgradeRequired or tenantUnavailable;
    /// switching gives failure, drain, failback, manual or manifest. Any text is accepted. The notice explains
    /// only the actionRequired reasons (``actionReason``); an actionRequired without one of them reads as expired.
    public var reason: String?
    /// The SDK runs on development endpoints: the notice wears a 开发模式 badge in every phase.
    public var developmentMode: Bool

    public init(phase: FlareConnectionPhase, quality: FlareConnectionQuality? = nil, progress: Double? = nil,
                nextRetryAt: Int64? = nil, attempt: Int? = nil, reason: String? = nil,
                developmentMode: Bool = false) {
        self.phase = phase; self.quality = quality; self.progress = progress; self.nextRetryAt = nextRetryAt
        self.attempt = attempt; self.reason = reason; self.developmentMode = developmentMode
    }

    /// The reason when it is one the notice explains (kicked, expired, upgradeRequired, tenantUnavailable);
    /// nil for any other text or none.
    public var actionReason: FlareConnectionActionReason? {
        reason.flatMap(FlareConnectionActionReason.init(rawValue:))
    }
}

/// The message a visible connection notice says.
public enum FlareConnectionNoticeText: String, Sendable {
    case connecting, syncing, switching, reconnecting, waitingForNetwork, serviceUnavailable
    case kicked, expired, upgradeRequired, tenantUnavailable
}

/// The action a visible connection notice offers; the host performs it.
public enum FlareConnectionNoticeAction: String, Sendable {
    case retry, signIn, update, diagnose
}

/// What the connection notice shows at one moment.
public struct FlareConnectionNoticeModel: Equatable, Sendable {
    public var visible: Bool
    public var text: FlareConnectionNoticeText?
    public var tone: FlareStatusTone?
    /// An attempt or a recovery is under way.
    public var pulse: Bool
    /// reconnecting: whole seconds to the next attempt, rounded up.
    public var countdown: Int?
    /// syncing: 0 to 1.
    public var progress: Double?
    public var action: FlareConnectionNoticeAction?
    /// Draw the development mode badge.
    public var badge: Bool

    public init(visible: Bool, text: FlareConnectionNoticeText? = nil, tone: FlareStatusTone? = nil, pulse: Bool = false,
                countdown: Int? = nil, progress: Double? = nil, action: FlareConnectionNoticeAction? = nil,
                badge: Bool = false) {
        self.visible = visible; self.text = text; self.tone = tone; self.pulse = pulse
        self.countdown = countdown; self.progress = progress; self.action = action; self.badge = badge
    }

    static let hidden = FlareConnectionNoticeModel(visible: false)
}

/// Tracks the connection status over time and answers what the notice shows, the same as the Vue, Flutter
/// and Compose kits (`spec/connection-notice-vectors.json`):
///
/// - idle and online show nothing; connecting, reconnecting, waitingForNetwork, serviceUnavailable and
///   actionRequired show at once;
/// - syncing shows once it has lasted 1 s and switching once it has lasted 2 s; until then a banner that
///   was already up keeps what it showed;
/// - a reconnecting banner stays up at least 1.5 s;
/// - reconnecting counts down and offers retry, serviceUnavailable offers diagnose, actionRequired offers
///   sign in (kicked, expired) or update (upgradeRequired); a reason it does not explain reads as expired.
public final class FlareConnectionNoticeTracker {
    public static let syncingDelayMs: Int64 = 1000
    public static let switchingDelayMs: Int64 = 2000
    public static let reconnectingMinShownMs: Int64 = 1500

    private struct Shown: Equatable {
        let text: FlareConnectionNoticeText?
        let tone: FlareStatusTone?
        let pulse: Bool
    }

    private var status: FlareConnectionStatus?
    private var phaseSince: Int64 = 0
    private var lastShown: Shown?
    private var holdUntil: Int64?

    public init() {}

    /// A status arrived at `nowMs`. The same phase again replaces its fields without restarting its clock.
    public func observe(_ status: FlareConnectionStatus, nowMs: Int64) {
        if self.status?.phase != status.phase {
            let outgoing = present(nowMs: nowMs)
            lastShown = outgoing.visible ? Shown(text: outgoing.text, tone: outgoing.tone, pulse: outgoing.pulse) : nil
            phaseSince = nowMs
            switch status.phase {
            case .reconnecting: holdUntil = nowMs + Self.reconnectingMinShownMs
            case .idle, .actionRequired: holdUntil = nil
            default: break
            }
        }
        self.status = status
    }

    /// What the notice shows at `nowMs`.
    public func present(nowMs: Int64) -> FlareConnectionNoticeModel {
        guard let status else { return .hidden }
        var model = FlareConnectionNoticeModel.hidden
        if status.phase != .idle {
            let base = base(status, nowMs: nowMs)
            if base.visible {
                model = base
            } else if let lastShown, belowDelay(status, nowMs: nowMs) || held(nowMs: nowMs) {
                model = FlareConnectionNoticeModel(visible: true, text: lastShown.text, tone: lastShown.tone,
                                                   pulse: lastShown.pulse)
            }
        }
        model.badge = status.developmentMode
        return model
    }

    /// The next moment the presentation can change without a new status; nil when it cannot.
    public func nextChangeAt(nowMs: Int64) -> Int64? {
        guard let status, status.phase != .idle else { return nil }
        var candidates: [Int64] = []
        if let delay = Self.delay(status.phase), nowMs < phaseSince + delay { candidates.append(phaseSince + delay) }
        if status.phase == .reconnecting, let at = status.nextRetryAt,
           let countdown = flareConnectionCountdown(nextRetryAt: at, nowMs: nowMs) {
            candidates.append(at - Int64(countdown - 1) * 1000)
        }
        if lastShown != nil, held(nowMs: nowMs), let holdUntil, !base(status, nowMs: nowMs).visible {
            candidates.append(holdUntil)
        }
        return candidates.min()
    }

    private static func delay(_ phase: FlareConnectionPhase) -> Int64? {
        switch phase {
        case .syncing: return syncingDelayMs
        case .switching: return switchingDelayMs
        default: return nil
        }
    }

    private func belowDelay(_ status: FlareConnectionStatus, nowMs: Int64) -> Bool {
        guard let delay = Self.delay(status.phase) else { return false }
        return nowMs - phaseSince < delay
    }

    private func held(nowMs: Int64) -> Bool {
        guard let holdUntil else { return false }
        return nowMs < holdUntil
    }

    private func base(_ status: FlareConnectionStatus, nowMs: Int64) -> FlareConnectionNoticeModel {
        switch status.phase {
        case .idle, .online:
            return .hidden
        case .connecting:
            return FlareConnectionNoticeModel(visible: true, text: .connecting, tone: .info, pulse: true)
        case .syncing:
            if belowDelay(status, nowMs: nowMs) { return .hidden }
            return FlareConnectionNoticeModel(visible: true, text: .syncing, tone: .info, pulse: true,
                                              progress: status.progress.map { min(1, max(0, $0)) })
        case .switching:
            if belowDelay(status, nowMs: nowMs) { return .hidden }
            return FlareConnectionNoticeModel(visible: true, text: .switching, tone: .info, pulse: true)
        case .reconnecting:
            return FlareConnectionNoticeModel(
                visible: true, text: .reconnecting, tone: .warning, pulse: true,
                countdown: status.nextRetryAt.flatMap { flareConnectionCountdown(nextRetryAt: $0, nowMs: nowMs) },
                action: .retry)
        case .waitingForNetwork:
            return FlareConnectionNoticeModel(visible: true, text: .waitingForNetwork, tone: .warning, pulse: false)
        case .serviceUnavailable:
            return FlareConnectionNoticeModel(visible: true, text: .serviceUnavailable, tone: .warning, pulse: true,
                                              action: .diagnose)
        case .actionRequired:
            let reason = status.actionReason ?? .expired
            let action: FlareConnectionNoticeAction?
            switch reason {
            case .kicked, .expired: action = .signIn
            case .upgradeRequired: action = .update
            case .tenantUnavailable: action = nil
            }
            return FlareConnectionNoticeModel(visible: true, text: FlareConnectionNoticeText(rawValue: reason.rawValue),
                                              tone: .danger, pulse: false, action: action)
        }
    }
}

/// Whole seconds to `nextRetryAt`, rounded up; nil once it has passed.
public func flareConnectionCountdown(nextRetryAt: Int64, nowMs: Int64) -> Int? {
    let remaining = nextRetryAt - nowMs
    guard remaining > 0 else { return nil }
    return Int((remaining + 999) / 1000)
}

public extension FlareConnectionNoticeModel {
    /// The banner's words in `strings`: the message, then the countdown or the sync progress.
    func bannerText(_ strings: FlareStrings) -> String {
        guard let message = message(strings) else { return "" }
        if let countdown { return "\(message) \(strings.connectionRetryIn(countdown))" }
        if let progress { return "\(message) \(Int((progress * 100).rounded()))%" }
        return message
    }

    /// The message alone, as a screen reader is told it (the countdown is not re-announced every second).
    func message(_ strings: FlareStrings) -> String? {
        switch text {
        case .connecting: return strings.connectionConnecting
        case .syncing: return strings.connectionSyncing
        case .switching: return strings.connectionSwitching
        case .reconnecting: return strings.connectionReconnecting
        case .waitingForNetwork: return strings.connectionWaitingForNetwork
        case .serviceUnavailable: return strings.connectionServiceUnavailable
        case .kicked: return strings.connectionKicked
        case .expired: return strings.connectionExpired
        case .upgradeRequired: return strings.connectionUpgradeRequired
        case .tenantUnavailable: return strings.connectionTenantUnavailable
        case nil: return nil
        }
    }
}

public extension FlareConnectionNoticeAction {
    /// The action's label in `strings`.
    func label(_ strings: FlareStrings) -> String {
        switch self {
        case .retry: return strings.connectionRetry
        case .signIn: return strings.connectionSignIn
        case .update: return strings.connectionUpdate
        case .diagnose: return strings.connectionDiagnose
        }
    }
}
