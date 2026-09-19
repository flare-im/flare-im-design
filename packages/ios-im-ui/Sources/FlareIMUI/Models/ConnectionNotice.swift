import Foundation

/// The IM connection phases an app shell reports (Vue `FlareConnectionPhase`).
public enum FlareConnectionPhase: String, Sendable, CaseIterable {
    case connected, connecting, reconnecting, offline, disconnected, kicked, expired
}

/// The way back a connection notice offers.
public enum FlareConnectionRecovery: String, Sendable {
    /// Ask the connection to try again.
    case reconnect
    /// Sign in again: the core does not reconnect after being kicked or after the sign-in expired.
    case signIn
}

/// What an app shell tells the user about its IM connection (FR-096, Vue `connectionNotice`). The kit
/// owns the wording, the tone and the way back, so every app says the same thing for the same state:
/// connecting and reconnecting say so (the core retries on its own), offline waits for the network,
/// disconnected may offer 重新连接 when the host can reconnect, and kicked and expired always offer
/// 重新登录. Connected shows nothing. The host renders it with ``StatusBannerView``: the notice's text,
/// tone and pulse, and its `recoveryText` as the action that runs the recovery.
public struct FlareConnectionNotice: Equatable, Sendable {
    public let phase: FlareConnectionPhase
    public let text: String
    /// `.warning`, or `.danger` once the user must sign in again.
    public let tone: FlareStatusTone
    /// A connection attempt is under way.
    public let pulse: Bool
    public let recovery: FlareConnectionRecovery?
    public let recoveryText: String?

    public init(phase: FlareConnectionPhase, text: String, tone: FlareStatusTone, pulse: Bool,
                recovery: FlareConnectionRecovery? = nil, recoveryText: String? = nil) {
        self.phase = phase; self.text = text; self.tone = tone; self.pulse = pulse
        self.recovery = recovery; self.recoveryText = recoveryText
    }

    /// The notice for `phase`; nil when connected. `reason` (trimmed) names why a disconnection or a kick
    /// happened and replaces the kicked default text; `canReconnect` offers 重新连接 on a disconnection.
    public static func resolve(_ phase: FlareConnectionPhase, reason: String? = nil, canReconnect: Bool = false,
                               strings: FlareStrings = FlareStrings()) -> FlareConnectionNotice? {
        let reason = reason?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        switch phase {
        case .connected:
            return nil
        case .connecting:
            return FlareConnectionNotice(phase: phase, text: strings.connectionConnecting, tone: .warning, pulse: true)
        case .reconnecting:
            return FlareConnectionNotice(phase: phase, text: strings.connectionReconnecting, tone: .warning, pulse: true)
        case .offline:
            return FlareConnectionNotice(phase: phase, text: strings.connectionOffline, tone: .warning, pulse: false)
        case .disconnected:
            return FlareConnectionNotice(
                phase: phase,
                text: reason.isEmpty ? strings.connectionDisconnected : strings.connectionDisconnectedReason(reason),
                tone: .warning, pulse: false,
                recovery: canReconnect ? .reconnect : nil,
                recoveryText: canReconnect ? strings.connectionReconnect : nil)
        case .kicked:
            return FlareConnectionNotice(phase: phase, text: reason.isEmpty ? strings.connectionKicked : reason,
                                         tone: .danger, pulse: false, recovery: .signIn, recoveryText: strings.connectionSignIn)
        case .expired:
            return FlareConnectionNotice(phase: phase, text: strings.connectionExpired, tone: .danger, pulse: false,
                                         recovery: .signIn, recoveryText: strings.connectionSignIn)
        }
    }
}
