import Foundation

// The update prompt, the progress bar and the version panel: what a person sees about a new version. The host hands in
// the SDK's update status as plain values; these rules turn it into the prompt's phase, words and actions, so every app
// offers an update the same way. Rules and their table: `spec/update-prompt-vectors.json`, run by all four kits.
//
// - forced: mandatory, the required state or the fullscreen form; it has no later, no skip and no way to the background;
// - a forced offer says the host's reason, when there is one, in place of its fixed words;
// - work under way (downloading, verifying, ready, installing) outranks a leftover error;
// - the first action drawn is the primary one, and an action is drawn only while the host handles it.

public enum FlareUpdatePromptForm: String, Sendable { case sheet, modal, fullscreen }

/// Where the fallback goes: the website on a direct install, the app store otherwise.
public enum FlareUpdateFallbackTarget: String, Sendable { case website, store }

/// What a progress bar's colour says; the words around it carry the meaning.
public enum FlareProgressBarTone: String, Sendable { case primary, success, warning, danger, neutral }

public enum FlareUpdatePromptPhase: String, Sendable {
    case offer, metered, downloading, verifying, ready, installing, failed
}

public enum FlareUpdatePromptLive: String, Sendable { case polite, assertive }

public enum FlareUpdatePromptTitle: String, Sendable {
    case available, required, metered, downloading, verifying, ready, installing, failed
}

public enum FlareUpdatePromptMessage: String, Sendable {
    case reason, required, requiredReadOnly, metered, meteredUnknown, ready
    case manifestUnavailable, manifestRejected, noArtifact, insufficientSpace, downloadFailed
    case hashMismatch, installFailed, signatureMismatch, downgradeRejected, notSkippable, unknown
}

public enum FlareUpdatePromptAction: String, Sendable {
    case update, continueDownload, restart, retry, fallback, later, background, skip, continueReadOnly
}

public enum FlareVersionPanelRow: String, Sendable { case check, update, restart }

public enum FlareVersionPanelAction: String, Sendable { case check, update }

public enum FlareVersionPanelDetail: String, Sendable {
    case checking, upToDate, available, required, downloading, verifying, ready, installing, failed
}

public enum FlareVersionChannelText: String, Sendable { case stable, beta, `internal` }

/// `UpdateStatus.progress`, as it arrives.
public struct FlareUpdateProgress: Equatable, Sendable {
    public let received: Int64
    /// Nil while the size is not known yet.
    public let total: Int64?

    public init(received: Int64, total: Int64? = nil) {
        self.received = received; self.total = total
    }
}

/// A bar's value. Nil reads as indeterminate.
public struct FlareProgressBarValue: Equatable, Sendable {
    /// 0...1.
    public let value: Double?
    /// Whole percent.
    public let percent: Int?

    public init(value: Double? = nil, percent: Int? = nil) {
        self.value = value; self.percent = percent
    }

    public static let none = FlareProgressBarValue()
}

/// What the prompt shows for one status.
public struct FlareUpdatePromptModel: Equatable, Sendable {
    public let phase: FlareUpdatePromptPhase
    public let forced: Bool
    public let dismissible: Bool
    public let live: FlareUpdatePromptLive
    public let title: FlareUpdatePromptTitle
    public let message: FlareUpdatePromptMessage?
    public let actions: [FlareUpdatePromptAction]
    /// The release notes are drawn.
    public let notes: Bool
    /// The bar; nil draws none.
    public let progress: FlareProgressBarValue?
}

/// What the version panel's update row shows for one state.
public struct FlareVersionPanelModel: Equatable, Sendable {
    public let row: FlareVersionPanelRow
    /// What tapping the row does; nil disables it.
    public let action: FlareVersionPanelAction?
    public let detail: FlareVersionPanelDetail?
}

public let flareUpdateMeteredCode = "update.meteredConfirmationRequired"

/// What an error code says on the prompt; a code the kit does not know reads as unknown.
public func flareUpdateFailure(_ errorCode: String?) -> FlareUpdatePromptMessage {
    switch errorCode {
    case "update.manifestUnavailable": return .manifestUnavailable
    case "update.manifestRejected": return .manifestRejected
    case "update.noArtifact": return .noArtifact
    case "update.insufficientSpace": return .insufficientSpace
    case "update.downloadFailed": return .downloadFailed
    case "update.hashMismatch": return .hashMismatch
    case "update.installFailed": return .installFailed
    case "update.signatureMismatch": return .signatureMismatch
    case "update.downgradeRejected": return .downgradeRejected
    case "update.notSkippable": return .notSkippable
    default: return .unknown
    }
}

/// Whether the version line is drawn: the server can refuse the client before any manifest brings a release to name.
public func flareUpdateVersionShown(_ version: String?) -> Bool {
    !(version ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}

/// A bar's value: clamped to 0...1, or none when it is missing, not finite or asked to be indeterminate.
public func flareProgressBarValue(_ value: Double?, indeterminate: Bool = false) -> FlareProgressBarValue {
    guard !indeterminate, let value, value.isFinite else { return .none }
    let shown = min(1, max(0, value))
    return FlareProgressBarValue(value: shown, percent: Int((shown * 100).rounded()))
}

private func flareUpdatePhase(state: String?, errorCode: String?) -> FlareUpdatePromptPhase {
    switch state {
    case "downloading": return .downloading
    case "verifying": return .verifying
    case "readyToInstall": return .ready
    case "installing": return .installing
    default: break
    }
    if errorCode == flareUpdateMeteredCode { return .metered }
    if state == "failed" || !(errorCode ?? "").isEmpty { return .failed }
    return .offer
}

private func flareUpdateBar(_ phase: FlareUpdatePromptPhase, progress: FlareUpdateProgress?) -> FlareProgressBarValue? {
    switch phase {
    case .downloading:
        guard let progress, let total = progress.total, total > 0 else { return FlareProgressBarValue.none }
        return flareProgressBarValue(Double(progress.received) / Double(total))
    case .verifying, .installing:
        return FlareProgressBarValue.none
    default:
        return nil
    }
}

/// What the prompt shows for one status (`spec/update-prompt-vectors.json`).
public func flareUpdatePrompt(form: FlareUpdatePromptForm, mandatory: Bool = false, state: String? = nil,
                              progress: FlareUpdateProgress? = nil, errorCode: String? = nil, retryable: Bool = true,
                              sizeBytes: Int64? = nil, canContinueReadOnly: Bool = false,
                              reason: String? = nil) -> FlareUpdatePromptModel {
    let forced = mandatory || state == "required" || form == .fullscreen
    let phase = flareUpdatePhase(state: state, errorCode: errorCode)
    let readOnly: [FlareUpdatePromptAction] = canContinueReadOnly ? [.continueReadOnly] : []
    let tail: [FlareUpdatePromptAction] = forced ? readOnly : [.later]

    let actions: [FlareUpdatePromptAction]
    let title: FlareUpdatePromptTitle
    var message: FlareUpdatePromptMessage?
    switch phase {
    case .offer:
        let skip: [FlareUpdatePromptAction] = !forced && form == .sheet ? [.skip] : []
        actions = [.update] + tail + skip
        title = forced ? .required : .available
        if forced {
            let hasReason = !(reason ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            message = hasReason ? .reason : canContinueReadOnly ? .requiredReadOnly : .required
        }
    case .metered:
        actions = [.continueDownload] + tail
        title = .metered
        message = (sizeBytes ?? -1) >= 0 ? .metered : .meteredUnknown
    case .downloading:
        actions = forced ? readOnly : [.background]
        title = .downloading
    case .verifying:
        actions = forced ? readOnly : [.background]
        title = .verifying
    case .ready:
        actions = [.restart] + tail
        title = .ready
        message = .ready
    case .installing:
        actions = []
        title = .installing
    case .failed:
        let retry: [FlareUpdatePromptAction] = retryable ? [.retry] : []
        actions = retry + [.fallback] + tail
        title = .failed
        message = flareUpdateFailure(errorCode)
    }
    return FlareUpdatePromptModel(
        phase: phase,
        forced: forced,
        dismissible: !forced && phase != .installing,
        live: forced ? .assertive : .polite,
        title: title,
        message: message,
        actions: actions,
        notes: phase == .offer || phase == .metered || phase == .downloading || phase == .verifying,
        progress: flareUpdateBar(phase, progress: progress)
    )
}

/// What the version panel's update row shows for one state (`spec/update-prompt-vectors.json`).
public func flareVersionPanel(_ updateState: String?) -> FlareVersionPanelModel {
    switch updateState {
    case "checking": return FlareVersionPanelModel(row: .check, action: nil, detail: .checking)
    case "upToDate": return FlareVersionPanelModel(row: .check, action: .check, detail: .upToDate)
    case "available": return FlareVersionPanelModel(row: .update, action: .update, detail: .available)
    case "required": return FlareVersionPanelModel(row: .update, action: .update, detail: .required)
    case "downloading": return FlareVersionPanelModel(row: .update, action: nil, detail: .downloading)
    case "verifying": return FlareVersionPanelModel(row: .update, action: nil, detail: .verifying)
    case "readyToInstall": return FlareVersionPanelModel(row: .restart, action: .update, detail: .ready)
    case "installing": return FlareVersionPanelModel(row: .update, action: nil, detail: .installing)
    case "failed": return FlareVersionPanelModel(row: .check, action: .check, detail: .failed)
    default: return FlareVersionPanelModel(row: .check, action: .check, detail: nil)
    }
}

/// The channel's words of its own; nil writes the channel as it arrived.
public func flareVersionChannelText(_ channel: String?) -> FlareVersionChannelText? {
    channel.flatMap(FlareVersionChannelText.init(rawValue:))
}

public extension FlareUpdatePromptTitle {
    /// The title's words.
    func label(_ strings: FlareStrings) -> String {
        switch self {
        case .available: return strings.updatePromptTitleAvailable
        case .required: return strings.updatePromptTitleRequired
        case .metered: return strings.updatePromptTitleMetered
        case .downloading: return strings.updatePromptTitleDownloading
        case .verifying: return strings.updatePromptTitleVerifying
        case .ready: return strings.updatePromptTitleReady
        case .installing: return strings.updatePromptTitleInstalling
        case .failed: return strings.updatePromptTitleFailed
        }
    }
}

public extension FlareUpdatePromptMessage {
    /// The message's words; `size` finishes the metered sentence and `reason` is what the host's reason says.
    func label(_ strings: FlareStrings, size: String? = nil, reason: String? = nil) -> String {
        switch self {
        case .reason: return reason ?? ""
        case .required: return strings.updatePromptMessageRequired
        case .requiredReadOnly: return strings.updatePromptMessageRequiredReadOnly
        case .metered: return [strings.updatePromptMessageMetered, size].compactMap { $0 }.joined(separator: " ")
        case .meteredUnknown: return strings.updatePromptMessageMeteredUnknown
        case .ready: return strings.updatePromptMessageReady
        case .manifestUnavailable: return strings.updatePromptFailManifestUnavailable
        case .manifestRejected: return strings.updatePromptFailManifestRejected
        case .noArtifact: return strings.updatePromptFailNoArtifact
        case .insufficientSpace: return strings.updatePromptFailInsufficientSpace
        case .downloadFailed: return strings.updatePromptFailDownload
        case .hashMismatch: return strings.updatePromptFailHashMismatch
        case .installFailed: return strings.updatePromptFailInstall
        case .signatureMismatch: return strings.updatePromptFailSignatureMismatch
        case .downgradeRejected: return strings.updatePromptFailDowngrade
        case .notSkippable: return strings.updatePromptFailNotSkippable
        case .unknown: return strings.updatePromptFailUnknown
        }
    }
}

public extension FlareUpdatePromptAction {
    /// The action's words.
    func label(_ strings: FlareStrings, fallbackTarget: FlareUpdateFallbackTarget = .website) -> String {
        switch self {
        case .update: return strings.connectionUpdate
        case .continueDownload: return strings.updatePromptContinueDownload
        case .restart: return strings.updatePromptRestart
        case .retry: return strings.updatePromptRetry
        case .fallback:
            return fallbackTarget == .store ? strings.updatePromptFallbackStore : strings.updatePromptFallbackWebsite
        case .later: return strings.updatePromptLater
        case .background: return strings.updatePromptBackground
        case .skip: return strings.updatePromptSkip
        case .continueReadOnly: return strings.updatePromptContinueReadOnly
        }
    }
}

public extension FlareVersionPanelRow {
    /// The words of the version panel's update row.
    func label(_ strings: FlareStrings) -> String {
        switch self {
        case .check: return strings.versionPanelCheck
        case .update: return strings.connectionUpdate
        case .restart: return strings.updatePromptRestart
        }
    }
}

public extension FlareVersionPanelDetail {
    /// What the version panel's update row writes at its end.
    func label(_ strings: FlareStrings) -> String {
        switch self {
        case .checking: return strings.versionPanelChecking
        case .upToDate: return strings.versionPanelUpToDate
        case .available: return strings.updatePromptTitleAvailable
        case .required: return strings.updatePromptTitleRequired
        case .downloading: return strings.updatePromptTitleDownloading
        case .verifying: return strings.updatePromptTitleVerifying
        case .ready: return strings.updatePromptTitleReady
        case .installing: return strings.updatePromptTitleInstalling
        case .failed: return strings.updatePromptTitleFailed
        }
    }
}

/// The channel in the reader's words, or as it arrived.
public func flareVersionChannelLabel(_ channel: String, strings: FlareStrings) -> String {
    switch flareVersionChannelText(channel) {
    case .stable: return strings.versionPanelChannelStable
    case .beta: return strings.versionPanelChannelBeta
    case .internal: return strings.versionPanelChannelInternal
    case nil: return channel
    }
}
