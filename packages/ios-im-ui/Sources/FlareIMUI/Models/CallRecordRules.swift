import Foundation

/// A call record's conversation kind. Spec: dataTypes `FlareCallRecordScope`.
public enum FlareCallRecordScope: String, Sendable, CaseIterable { case single, group }

/// Where the recorded call is. Spec: dataTypes `FlareCallRecordState`.
public enum FlareCallRecordState: String, Sendable, CaseIterable { case ringing, ongoing, ended }

/// Why an ended call ended. Spec: dataTypes `FlareCallEndReason`.
public enum FlareCallEndReason: String, Sendable, CaseIterable {
    case completed, cancelled, declined, missed, busy, unavailable, failed
}

/// The status line a call record shows, viewer-relative (`spec/call-record-vectors.json` → rules.status).
public enum FlareCallRecordStatus: String, Sendable, CaseIterable {
    case waitingAnswer, incoming, groupRinging, inCall, groupOngoing, groupInProgress, duration, groupEndedDuration
    case groupEnded, cancelledByYou, cancelledByCaller, declinedByPeer, declinedByYou, noAnswer, missed, peerBusy
    case missedBusy, unavailable, failed
}

/// The status line's tone: `danger` for a call the viewer did not pick up.
public enum FlareCallRecordTone: String, Sendable { case neutral, danger }

/// The one action a call record offers.
public enum FlareCallRecordAction: String, Sendable { case join, callBack }

/// The call record rules every kit runs against `spec/call-record-vectors.json`.
public enum FlareCallRecordRules {
    /// The status line for the viewer. A missing `endReason` reads completed.
    public static func status(scope: FlareCallRecordScope, state: FlareCallRecordState, viewerIsInitiator: Bool,
                              endReason: FlareCallEndReason? = nil, durationSeconds: Int? = nil,
                              joinedCount: Int? = nil) -> FlareCallRecordStatus {
        let group = scope == .group
        switch state {
        case .ringing:
            if group { return .groupRinging }
            return viewerIsInitiator ? .waitingAnswer : .incoming
        case .ongoing:
            if !group { return .inCall }
            return (joinedCount ?? 0) >= 1 ? .groupOngoing : .groupInProgress
        case .ended:
            break
        }
        let reason = endReason ?? .completed
        if group {
            switch reason {
            case .completed: return durationSeconds == nil ? .groupEnded : .groupEndedDuration
            case .unavailable: return .unavailable
            case .failed: return .failed
            default: return .groupEnded
            }
        }
        switch reason {
        case .completed: return .duration
        case .cancelled: return viewerIsInitiator ? .cancelledByYou : .cancelledByCaller
        case .declined: return viewerIsInitiator ? .declinedByPeer : .declinedByYou
        case .missed: return viewerIsInitiator ? .noAnswer : .missed
        case .busy: return viewerIsInitiator ? .peerBusy : .missedBusy
        case .unavailable: return .unavailable
        case .failed: return .failed
        }
    }

    /// A call the viewer did not pick up reads in the danger tone.
    public static func tone(_ status: FlareCallRecordStatus) -> FlareCallRecordTone {
        status == .missed ? .danger : .neutral
    }

    /// The one action the card offers, or nil: join a group call in progress, call back after a 1:1 call;
    /// nothing while the plugin is unavailable.
    public static func action(scope: FlareCallRecordScope, state: FlareCallRecordState, canJoin: Bool,
                              canCallBack: Bool, disabled: Bool = false) -> FlareCallRecordAction? {
        if disabled { return nil }
        if scope == .group && state != .ended && canJoin { return .join }
        if scope == .single && state == .ended && canCallBack { return .callBack }
        return nil
    }

    /// A call's length: mm:ss under an hour, h:mm:ss from an hour. Negative reads 0.
    public static func durationLabel(_ seconds: Int) -> String {
        let total = max(0, seconds)
        let hours = total / 3600, minutes = (total % 3600) / 60, rest = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, rest)
            : String(format: "%02d:%02d", minutes, rest)
    }

    /// The status line's copy in `strings`.
    public static func text(_ status: FlareCallRecordStatus, strings: FlareStrings, joinedCount: Int? = nil,
                            durationSeconds: Int? = nil) -> String {
        let duration = durationLabel(durationSeconds ?? 0)
        switch status {
        case .waitingAnswer: return strings.callRecordWaitingAnswer
        case .incoming: return strings.callRecordIncoming
        case .groupRinging: return strings.callRecordGroupRinging
        case .inCall: return strings.callRecordInCall
        case .groupOngoing: return strings.callRecordGroupOngoing.replacingOccurrences(of: "{n}", with: "\(joinedCount ?? 0)")
        case .groupInProgress: return strings.callRecordGroupInProgress
        case .duration: return strings.callRecordDuration.replacingOccurrences(of: "{duration}", with: duration)
        case .groupEndedDuration:
            return strings.callRecordGroupEndedDuration.replacingOccurrences(of: "{duration}", with: duration)
        case .groupEnded: return strings.callRecordGroupEnded
        case .cancelledByYou: return strings.callRecordCancelledByYou
        case .cancelledByCaller: return strings.callRecordCancelledByCaller
        case .declinedByPeer: return strings.callRecordDeclinedByPeer
        case .declinedByYou: return strings.callRecordDeclinedByYou
        case .noAnswer: return strings.callRecordNoAnswer
        case .missed: return strings.callRecordMissed
        case .peerBusy: return strings.callRecordPeerBusy
        case .missedBusy: return strings.callRecordMissedBusy
        case .unavailable: return strings.callRecordUnavailable
        case .failed: return strings.callRecordFailed
        }
    }
}
