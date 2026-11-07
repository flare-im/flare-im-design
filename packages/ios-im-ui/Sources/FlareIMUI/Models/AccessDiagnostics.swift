import Foundation

/// The connection diagnostics of `access.getStatus`: only what the page reads.
public struct FlareAccessConnectAck: Equatable, Sendable {
    /// The access point the server reports for the connection.
    public let accessPointId: String?
    /// The server reports a different access point than the client chose.
    public let accessPointMismatch: Bool

    public init(accessPointId: String? = nil, accessPointMismatch: Bool = false) {
        self.accessPointId = accessPointId; self.accessPointMismatch = accessPointMismatch
    }
}

/// `access.getStatus.recovering`: there only while every line has failed.
public struct FlareAccessRecovering: Equatable, Sendable {
    /// Bootstrap rounds so far.
    public let rounds: Int
    /// When the next round starts; nil while the device has no network.
    public let nextRoundAtMs: Int64?

    public init(rounds: Int, nextRoundAtMs: Int64? = nil) {
        self.rounds = rounds; self.nextRoundAtMs = nextRoundAtMs
    }
}

/// What `access.getStatus` returns, as far as the page reads it (Vue `FlareAccessStatus`).
public struct FlareAccessStatus: Equatable, Sendable {
    /// The directory holds a usable manifest.
    public let loaded: Bool
    public let serial: Int64?
    /// seed, https:<mirror base>, wellKnown:<apId>, recovery, development or none.
    public let source: String?
    /// Past its expiry: still connectable.
    public let stale: Bool
    public let developmentMode: Bool
    public let regionId: String?
    /// The access point of the current connection.
    public let accessPointId: String?
    public let `protocol`: String?
    public let connectAck: FlareAccessConnectAck?
    public let recovering: FlareAccessRecovering?

    public init(loaded: Bool, serial: Int64? = nil, source: String? = nil, stale: Bool = false,
                developmentMode: Bool = false, regionId: String? = nil, accessPointId: String? = nil,
                protocol: String? = nil, connectAck: FlareAccessConnectAck? = nil,
                recovering: FlareAccessRecovering? = nil) {
        self.loaded = loaded; self.serial = serial; self.source = source; self.stale = stale
        self.developmentMode = developmentMode; self.regionId = regionId; self.accessPointId = accessPointId
        self.protocol = `protocol`; self.connectAck = connectAck; self.recovering = recovering
    }
}

/// One line of `access.listAccessPoints`.
public struct FlareAccessPoint: Identifiable, Equatable, Sendable {
    public var id: String { accessPointId }
    public let accessPointId: String
    public let regionId: String?
    public let host: String?
    /// active, draining, disabled or unknown; any other string reads unknown.
    public let status: String
    public let rttMs: Double?
    /// closed, open or halfOpen.
    public let breaker: String
    public let pinned: Bool
    public let current: Bool

    public init(accessPointId: String, regionId: String? = nil, host: String? = nil, status: String,
                rttMs: Double? = nil, breaker: String, pinned: Bool = false, current: Bool = false) {
        self.accessPointId = accessPointId; self.regionId = regionId; self.host = host; self.status = status
        self.rttMs = rttMs; self.breaker = breaker; self.pinned = pinned; self.current = current
    }
}

/// How the page stands as a whole.
public enum FlareAccessDiagnosticsState: String, Sendable { case normal, recovering, warning }
public enum FlareAccessManifestState: String, Sendable { case valid, stale, none }
public enum FlareAccessRttGrade: String, Sendable { case good, fair, poor }
public enum FlareAccessPointState: String, Sendable { case active, draining, disabled, unknown }
public enum FlareAccessBreakerState: String, Sendable { case open, halfOpen }
public enum FlareAccessPinAction: String, Sendable { case pin, unpin }
public enum FlareAccessSourceKind: String, Sendable { case seed, mirror, wellKnown, recovery, development, none, unknown }

/// A line at the top of the page.
public enum FlareAccessNoticeText: String, Sendable {
    case healthy, notConnected, serviceUnavailable, waitingForNetwork, accessPointMismatch, manifestStale
}
public enum FlareAccessRefreshText: String, Sendable { case adopted, upToDate, failed, skipped }
public enum FlareAccessImportText: String, Sendable {
    case adopted, unchanged, rollback, expired, wrongApp, developmentMode, untrusted, malformed, rejected
}
public enum FlareAccessExportText: String, Sendable { case copied, failed }

public struct FlareAccessNotice: Equatable, Sendable {
    public let text: FlareAccessNoticeText
    public let tone: FlareStatusTone
    public let pulse: Bool

    public init(text: FlareAccessNoticeText, tone: FlareStatusTone, pulse: Bool = false) {
        self.text = text; self.tone = tone; self.pulse = pulse
    }
}

/// The latency to show and its grade; unknown has neither.
public struct FlareAccessRtt: Equatable, Sendable {
    /// Whole milliseconds to show; nil when unknown.
    public let shownMs: Int?
    public let grade: FlareAccessRttGrade?

    public init(shownMs: Int? = nil, grade: FlareAccessRttGrade? = nil) {
        self.shownMs = shownMs; self.grade = grade
    }
}

public struct FlareAccessSource: Equatable, Sendable {
    public let kind: FlareAccessSourceKind
    /// A mirror's host, a well-known access point, or an unknown source as it arrived.
    public let detail: String?

    public init(kind: FlareAccessSourceKind, detail: String? = nil) {
        self.kind = kind; self.detail = detail
    }
}

/// One row of the line list.
public struct FlareAccessPointRow: Identifiable, Equatable, Sendable {
    public var id: String { accessPointId }
    public let accessPointId: String
    public let host: String?
    public let current: Bool
    public let pinned: Bool
    public let status: FlareAccessPointState
    public let statusTone: FlareStatusTone
    public let breaker: FlareAccessBreakerState?
    public let breakerTone: FlareStatusTone?
    public let rtt: FlareAccessRtt
    public let pin: FlareAccessPinAction?
}

public struct FlareAccessRegion: Equatable, Sendable {
    /// Nil for lines without a region: no heading.
    public let regionId: String?
    public var accessPoints: [FlareAccessPointRow]
}

/// What the page shows for one status and list.
public struct FlareAccessDiagnosticsModel: Equatable, Sendable {
    public let state: FlareAccessDiagnosticsState
    public let notices: [FlareAccessNotice]
    public let manifest: FlareAccessManifestState
    /// The current line's latency, from its row.
    public let rtt: FlareAccessRtt
    /// What the server reports while it disagrees with the client.
    public let reportedAccessPointId: String?
    public let recoveryRounds: Int?
    public let regions: [FlareAccessRegion]
}

/// A one-line answer to one of the page's actions.
public struct FlareAccessFeedback<Text: Equatable & Sendable>: Equatable, Sendable {
    public let text: Text
    public let tone: FlareStatusTone
}

/// Where the latency grades change, in whole milliseconds (the shared table's `thresholds`).
public enum FlareAccessRttThresholds {
    public static let goodBelowMs = 150
    public static let poorAboveMs = 400
}

/// The tone a latency grade is drawn in.
public func flareAccessRttTone(_ grade: FlareAccessRttGrade) -> FlareStatusTone {
    switch grade {
    case .good: return .success
    case .fair: return .warning
    case .poor: return .danger
    }
}

/// The latency to show and its grade; unknown (missing, negative, not finite) has neither.
public func flareAccessRtt(_ rttMs: Double?) -> FlareAccessRtt {
    guard let rttMs, rttMs.isFinite, rttMs >= 0 else { return FlareAccessRtt() }
    let shown = Int(rttMs.rounded())
    if shown < FlareAccessRttThresholds.goodBelowMs { return FlareAccessRtt(shownMs: shown, grade: .good) }
    return FlareAccessRtt(shownMs: shown, grade: shown > FlareAccessRttThresholds.poorAboveMs ? .poor : .fair)
}

/// The protocol's name on screen; a protocol the kit does not know is shown as it arrives.
public func flareAccessProtocolLabel(_ protocol: String?) -> String? {
    switch `protocol` {
    case "quic": return "QUIC"
    case "ws": return "WebSocket"
    default: return `protocol`
    }
}

/// `https:<base>` and `wellKnown:<apId>` read apart; the plain sources are their own kinds.
public func flareAccessSource(_ source: String?) -> FlareAccessSource {
    guard let source, source != "none" else { return FlareAccessSource(kind: .none) }
    switch source {
    case "seed": return FlareAccessSource(kind: .seed)
    case "recovery": return FlareAccessSource(kind: .recovery)
    case "development": return FlareAccessSource(kind: .development)
    default: break
    }
    if source.hasPrefix("https:") {
        let base = source.dropFirst("https:".count)
        let authority = base.range(of: "://").map { base[$0.upperBound...] } ?? base
        return FlareAccessSource(kind: .mirror, detail: String(authority.prefix { $0 != "/" }))
    }
    if source.hasPrefix("wellKnown:") {
        return FlareAccessSource(kind: .wellKnown, detail: String(source.dropFirst("wellKnown:".count)))
    }
    return FlareAccessSource(kind: .unknown, detail: source)
}

/// One line's row: a pin needs an active line that is not cooling down; a pinned line can always be let go.
public func flareAccessPointRow(_ point: FlareAccessPoint) -> FlareAccessPointRow {
    let status: FlareAccessPointState
    let tone: FlareStatusTone
    switch point.status {
    case "active": (status, tone) = (.active, .success)
    case "draining": (status, tone) = (.draining, .warning)
    case "disabled": (status, tone) = (.disabled, .neutral)
    default: (status, tone) = (.unknown, .neutral)
    }
    let breaker: FlareAccessBreakerState? = point.breaker == "open" ? .open : point.breaker == "halfOpen" ? .halfOpen : nil
    var pin: FlareAccessPinAction?
    if point.pinned {
        pin = .unpin
    } else if status == .active && breaker != .open {
        pin = .pin
    }
    return FlareAccessPointRow(
        accessPointId: point.accessPointId, host: point.host, current: point.current, pinned: point.pinned,
        status: status, statusTone: tone, breaker: breaker,
        breakerTone: breaker.map { $0 == .open ? .danger : .warning },
        rtt: flareAccessRtt(point.rttMs), pin: pin)
}

private func regionsOf(_ accessPoints: [FlareAccessPoint]) -> [FlareAccessRegion] {
    var regions: [FlareAccessRegion] = []
    for point in accessPoints {
        let row = flareAccessPointRow(point)
        if let index = regions.firstIndex(where: { $0.regionId == point.regionId }) {
            regions[index].accessPoints.append(row)
        } else {
            regions.append(FlareAccessRegion(regionId: point.regionId, accessPoints: [row]))
        }
    }
    return regions
}

private func noticesOf(_ status: FlareAccessStatus, state: FlareAccessDiagnosticsState,
                       warnings: [FlareAccessNotice]) -> [FlareAccessNotice] {
    switch state {
    case .recovering:
        let offline = status.recovering != nil && status.recovering?.nextRoundAtMs == nil
        let lead = offline
            ? FlareAccessNotice(text: .waitingForNetwork, tone: .warning)
            : FlareAccessNotice(text: .serviceUnavailable, tone: .warning, pulse: true)
        return [lead] + warnings
    case .warning:
        return warnings
    case .normal:
        let online = !(status.accessPointId ?? "").isEmpty
        return [online ? FlareAccessNotice(text: .healthy, tone: .success)
                       : FlareAccessNotice(text: .notConnected, tone: .neutral)]
    }
}

/// What the page shows. `status` is nil until the host has read one. Rules:
/// `spec/access-diagnostics-vectors.json`, run by all four kits.
public func flareAccessDiagnostics(_ status: FlareAccessStatus?,
                                   accessPoints: [FlareAccessPoint]) -> FlareAccessDiagnosticsModel {
    let regions = regionsOf(accessPoints)
    let rtt = flareAccessRtt(accessPoints.first { $0.current }?.rttMs)
    guard let status else {
        return FlareAccessDiagnosticsModel(state: .normal, notices: [], manifest: .none, rtt: rtt,
                                           reportedAccessPointId: nil, recoveryRounds: nil, regions: regions)
    }
    let mismatch = status.connectAck?.accessPointMismatch ?? false
    var warnings: [FlareAccessNotice] = []
    if mismatch { warnings.append(FlareAccessNotice(text: .accessPointMismatch, tone: .warning)) }
    if status.stale { warnings.append(FlareAccessNotice(text: .manifestStale, tone: .warning)) }
    let recovering = status.recovering != nil || !status.loaded
    let state: FlareAccessDiagnosticsState = recovering ? .recovering : warnings.isEmpty ? .normal : .warning
    return FlareAccessDiagnosticsModel(
        state: state,
        notices: noticesOf(status, state: state, warnings: warnings),
        manifest: !status.loaded ? .none : status.stale ? .stale : .valid,
        rtt: rtt,
        reportedAccessPointId: mismatch ? status.connectAck?.accessPointId : nil,
        recoveryRounds: status.recovering?.rounds,
        regions: regions)
}

/// What `access.refresh` answered, in the page's words; nothing for an outcome the kit does not know.
public func flareAccessRefreshFeedback(_ outcome: String?) -> FlareAccessFeedback<FlareAccessRefreshText>? {
    switch outcome {
    case "adopted": return FlareAccessFeedback(text: .adopted, tone: .success)
    case "upToDate": return FlareAccessFeedback(text: .upToDate, tone: .success)
    case "failed", "oldValues": return FlareAccessFeedback(text: .failed, tone: .warning)
    case "skipped": return FlareAccessFeedback(text: .skipped, tone: .neutral)
    default: return nil
    }
}

private func rejectionText(_ code: String?) -> FlareAccessImportText {
    switch code {
    case "rollback": return .rollback
    case "expired": return .expired
    case "wrongBootstrapId": return .wrongApp
    case "developmentMode": return .developmentMode
    case "badSignature", "unknownKey", "revoked", "wrongPayloadType": return .untrusted
    case "malformedEnvelope", "invalidPayload", "tooLarge": return .malformed
    default: return code?.hasPrefix("keyCert.") == true ? .untrusted : .rejected
    }
}

/// What `access.importRecovery` answered: its `outcome`, and its `code` when rejected.
public func flareAccessImportFeedback(_ outcome: String?, code: String?) -> FlareAccessFeedback<FlareAccessImportText>? {
    switch outcome {
    case "adopted": return FlareAccessFeedback(text: .adopted, tone: .success)
    case "unchanged": return FlareAccessFeedback(text: .unchanged, tone: .neutral)
    case "rejected": return FlareAccessFeedback(text: rejectionText(code), tone: .danger)
    default: return nil
    }
}

/// The host's word on the clipboard: copied or failed.
public func flareAccessExportFeedback(_ outcome: String?) -> FlareAccessFeedback<FlareAccessExportText>? {
    switch outcome {
    case "copied": return FlareAccessFeedback(text: .copied, tone: .success)
    case "failed": return FlareAccessFeedback(text: .failed, tone: .danger)
    default: return nil
    }
}

public extension FlareAccessNoticeText {
    /// The words of a top-of-page notice.
    func label(_ strings: FlareStrings) -> String {
        switch self {
        case .healthy: return strings.accessDiagnosticsHealthy
        case .notConnected: return strings.accessDiagnosticsNotConnected
        case .serviceUnavailable: return strings.connectionServiceUnavailable
        case .waitingForNetwork: return strings.connectionWaitingForNetwork
        case .accessPointMismatch: return strings.accessDiagnosticsAccessPointMismatch
        case .manifestStale: return strings.accessDiagnosticsManifestStaleNotice
        }
    }
}

public extension FlareAccessRefreshText {
    /// The answer to a refresh.
    func label(_ strings: FlareStrings) -> String {
        switch self {
        case .adopted: return strings.accessDiagnosticsRefreshAdopted
        case .upToDate: return strings.accessDiagnosticsRefreshUpToDate
        case .failed: return strings.accessDiagnosticsRefreshFailed
        case .skipped: return strings.accessDiagnosticsRefreshSkipped
        }
    }
}

public extension FlareAccessImportText {
    /// The answer to an import.
    func label(_ strings: FlareStrings) -> String {
        switch self {
        case .adopted: return strings.accessDiagnosticsImportAdopted
        case .unchanged: return strings.accessDiagnosticsImportUnchanged
        case .rollback: return strings.accessDiagnosticsImportRollback
        case .expired: return strings.accessDiagnosticsImportExpired
        case .wrongApp: return strings.accessDiagnosticsImportWrongApp
        case .developmentMode: return strings.accessDiagnosticsImportDevelopmentMode
        case .untrusted: return strings.accessDiagnosticsImportUntrusted
        case .malformed: return strings.accessDiagnosticsImportMalformed
        case .rejected: return strings.accessDiagnosticsImportRejected
        }
    }
}

public extension FlareAccessExportText {
    /// The answer to an export.
    func label(_ strings: FlareStrings) -> String {
        switch self {
        case .copied: return strings.accessDiagnosticsExportCopied
        case .failed: return strings.accessDiagnosticsExportFailed
        }
    }
}

public extension FlareAccessRtt {
    /// A latency for the page: `86 ms · Good`.
    func label(_ strings: FlareStrings) -> String? {
        guard let shownMs, let grade else { return nil }
        let word: String
        switch grade {
        case .good: word = strings.accessDiagnosticsRttGood
        case .fair: word = strings.accessDiagnosticsRttFair
        case .poor: word = strings.accessDiagnosticsRttPoor
        }
        return "\(shownMs) ms · \(word)"
    }
}

/// Where the manifest came from, in words.
public func flareAccessSourceLabel(_ source: String?, strings: FlareStrings) -> String? {
    let read = flareAccessSource(source)
    switch read.kind {
    case .seed: return strings.accessDiagnosticsSourceSeed
    case .mirror: return "\(strings.accessDiagnosticsSourceMirror) \(read.detail ?? "")"
    case .wellKnown: return "\(strings.accessDiagnosticsAccessPoint) \(read.detail ?? "")"
    case .recovery: return strings.accessDiagnosticsSourceRecovery
    case .development: return strings.accessDiagnosticsSourceDevelopment
    case .none: return strings.accessDiagnosticsSourceNone
    case .unknown: return read.detail
    }
}
