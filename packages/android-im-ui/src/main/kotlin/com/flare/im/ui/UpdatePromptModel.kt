package com.flare.im.ui

import kotlin.math.roundToInt

// The update prompt, the progress bar and the version panel: what a person sees about a new version. The host hands in
// the SDK's update status as plain values; these rules turn it into the prompt's phase, words and actions, so every app
// offers an update the same way. Rules and their table: `spec/update-prompt-vectors.json`, run by all four kits.
//
// - forced: mandatory, the required state or the fullscreen form; it has no later, no skip and no way to the background;
// - a forced offer says the host's reason, when there is one, in place of its fixed words;
// - work under way (downloading, verifying, ready, installing) outranks a leftover error;
// - the first action drawn is the primary one, and an action is drawn only while the host handles it.

enum class FlareUpdatePromptForm { Sheet, Modal, Fullscreen }

/** Where the fallback goes: the website on a direct install, the app store otherwise. */
enum class FlareUpdateFallbackTarget { Website, Store }

/** What a progress bar's colour says; the words around it carry the meaning. */
enum class FlareProgressBarTone { Primary, Success, Warning, Danger, Neutral }

enum class FlareUpdatePromptPhase { Offer, Metered, Downloading, Verifying, Ready, Installing, Failed }

enum class FlareUpdatePromptLive { Polite, Assertive }

enum class FlareUpdatePromptTitle { Available, Required, Metered, Downloading, Verifying, Ready, Installing, Failed }

enum class FlareUpdatePromptMessage {
    Reason, Required, RequiredReadOnly, Metered, MeteredUnknown, Ready,
    ManifestUnavailable, ManifestRejected, NoArtifact, InsufficientSpace, DownloadFailed,
    HashMismatch, InstallFailed, SignatureMismatch, DowngradeRejected, NotSkippable, Unknown,
}

enum class FlareUpdatePromptAction { Update, ContinueDownload, Restart, Retry, Fallback, Later, Background, Skip, ContinueReadOnly }

enum class FlareVersionPanelRow { Check, Update, Restart }

enum class FlareVersionPanelAction { Check, Update }

enum class FlareVersionPanelDetail { Checking, UpToDate, Available, Required, Downloading, Verifying, Ready, Installing, Failed }

enum class FlareVersionChannelText { Stable, Beta, Internal }

/** `UpdateStatus.progress`, as it arrives. [total] is null while the size is not known yet. */
data class FlareUpdateProgress(val received: Long, val total: Long? = null)

/** A bar's [value] (0..1) and whole [percent]. Null reads as indeterminate. */
data class FlareProgressBarValue(val value: Double? = null, val percent: Int? = null) {
    companion object {
        val None = FlareProgressBarValue()
    }
}

/** What the prompt shows for one status. */
data class FlareUpdatePromptModel(
    val phase: FlareUpdatePromptPhase,
    val forced: Boolean,
    val dismissible: Boolean,
    val live: FlareUpdatePromptLive,
    val title: FlareUpdatePromptTitle,
    val message: FlareUpdatePromptMessage?,
    val actions: List<FlareUpdatePromptAction>,
    /** The release notes are drawn. */
    val notes: Boolean,
    /** The bar; null draws none. */
    val progress: FlareProgressBarValue?,
)

/** What the version panel's update row shows for one state. */
data class FlareVersionPanelModel(
    val row: FlareVersionPanelRow,
    /** What tapping the row does; null disables it. */
    val action: FlareVersionPanelAction?,
    val detail: FlareVersionPanelDetail?,
)

const val FLARE_UPDATE_METERED_CODE = "update.meteredConfirmationRequired"

/** What an error code says on the prompt; a code the kit does not know reads as unknown. */
fun flareUpdateFailure(errorCode: String?): FlareUpdatePromptMessage = when (errorCode) {
    "update.manifestUnavailable" -> FlareUpdatePromptMessage.ManifestUnavailable
    "update.manifestRejected" -> FlareUpdatePromptMessage.ManifestRejected
    "update.noArtifact" -> FlareUpdatePromptMessage.NoArtifact
    "update.insufficientSpace" -> FlareUpdatePromptMessage.InsufficientSpace
    "update.downloadFailed" -> FlareUpdatePromptMessage.DownloadFailed
    "update.hashMismatch" -> FlareUpdatePromptMessage.HashMismatch
    "update.installFailed" -> FlareUpdatePromptMessage.InstallFailed
    "update.signatureMismatch" -> FlareUpdatePromptMessage.SignatureMismatch
    "update.downgradeRejected" -> FlareUpdatePromptMessage.DowngradeRejected
    "update.notSkippable" -> FlareUpdatePromptMessage.NotSkippable
    else -> FlareUpdatePromptMessage.Unknown
}

/** Whether the version line is drawn: the server can refuse the client before any manifest brings a release to name. */
fun flareUpdateVersionShown(version: String?): Boolean = !version.isNullOrBlank()

/** A bar's value: clamped to 0..1, or none when it is missing, not finite or asked to be indeterminate. */
fun flareProgressBarValue(value: Double?, indeterminate: Boolean = false): FlareProgressBarValue {
    if (indeterminate || value == null || !value.isFinite()) return FlareProgressBarValue.None
    val shown = value.coerceIn(0.0, 1.0)
    return FlareProgressBarValue(shown, (shown * 100).roundToInt())
}

private fun flareUpdatePhase(state: String?, errorCode: String?): FlareUpdatePromptPhase = when {
    state == "downloading" -> FlareUpdatePromptPhase.Downloading
    state == "verifying" -> FlareUpdatePromptPhase.Verifying
    state == "readyToInstall" -> FlareUpdatePromptPhase.Ready
    state == "installing" -> FlareUpdatePromptPhase.Installing
    errorCode == FLARE_UPDATE_METERED_CODE -> FlareUpdatePromptPhase.Metered
    state == "failed" || !errorCode.isNullOrEmpty() -> FlareUpdatePromptPhase.Failed
    else -> FlareUpdatePromptPhase.Offer
}

private fun flareUpdateBar(phase: FlareUpdatePromptPhase, progress: FlareUpdateProgress?): FlareProgressBarValue? = when (phase) {
    FlareUpdatePromptPhase.Downloading -> {
        val total = progress?.total
        if (progress == null || total == null || total <= 0L) FlareProgressBarValue.None
        else flareProgressBarValue(progress.received.toDouble() / total.toDouble())
    }
    FlareUpdatePromptPhase.Verifying, FlareUpdatePromptPhase.Installing -> FlareProgressBarValue.None
    else -> null
}

/** What the prompt shows for one status (`spec/update-prompt-vectors.json`). */
fun flareUpdatePrompt(
    form: FlareUpdatePromptForm,
    mandatory: Boolean = false,
    state: String? = null,
    progress: FlareUpdateProgress? = null,
    errorCode: String? = null,
    retryable: Boolean = true,
    sizeBytes: Long? = null,
    canContinueReadOnly: Boolean = false,
    reason: String? = null,
): FlareUpdatePromptModel {
    val forced = mandatory || state == "required" || form == FlareUpdatePromptForm.Fullscreen
    val phase = flareUpdatePhase(state, errorCode)
    val readOnly: List<FlareUpdatePromptAction> =
        if (canContinueReadOnly) listOf(FlareUpdatePromptAction.ContinueReadOnly) else emptyList()
    val tail: List<FlareUpdatePromptAction> = if (forced) readOnly else listOf(FlareUpdatePromptAction.Later)
    val actions: List<FlareUpdatePromptAction> = when (phase) {
        FlareUpdatePromptPhase.Offer -> buildList {
            add(FlareUpdatePromptAction.Update)
            addAll(tail)
            if (!forced && form == FlareUpdatePromptForm.Sheet) add(FlareUpdatePromptAction.Skip)
        }
        FlareUpdatePromptPhase.Metered -> listOf(FlareUpdatePromptAction.ContinueDownload) + tail
        FlareUpdatePromptPhase.Downloading, FlareUpdatePromptPhase.Verifying ->
            if (forced) readOnly else listOf(FlareUpdatePromptAction.Background)
        FlareUpdatePromptPhase.Ready -> listOf(FlareUpdatePromptAction.Restart) + tail
        FlareUpdatePromptPhase.Installing -> emptyList()
        FlareUpdatePromptPhase.Failed -> buildList {
            if (retryable) add(FlareUpdatePromptAction.Retry)
            add(FlareUpdatePromptAction.Fallback)
            addAll(tail)
        }
    }
    val title = when (phase) {
        FlareUpdatePromptPhase.Offer -> if (forced) FlareUpdatePromptTitle.Required else FlareUpdatePromptTitle.Available
        FlareUpdatePromptPhase.Metered -> FlareUpdatePromptTitle.Metered
        FlareUpdatePromptPhase.Downloading -> FlareUpdatePromptTitle.Downloading
        FlareUpdatePromptPhase.Verifying -> FlareUpdatePromptTitle.Verifying
        FlareUpdatePromptPhase.Ready -> FlareUpdatePromptTitle.Ready
        FlareUpdatePromptPhase.Installing -> FlareUpdatePromptTitle.Installing
        FlareUpdatePromptPhase.Failed -> FlareUpdatePromptTitle.Failed
    }
    val message: FlareUpdatePromptMessage? = when (phase) {
        FlareUpdatePromptPhase.Offer -> when {
            !forced -> null
            !reason.isNullOrBlank() -> FlareUpdatePromptMessage.Reason
            canContinueReadOnly -> FlareUpdatePromptMessage.RequiredReadOnly
            else -> FlareUpdatePromptMessage.Required
        }
        FlareUpdatePromptPhase.Metered ->
            if (sizeBytes != null && sizeBytes >= 0L) FlareUpdatePromptMessage.Metered else FlareUpdatePromptMessage.MeteredUnknown
        FlareUpdatePromptPhase.Ready -> FlareUpdatePromptMessage.Ready
        FlareUpdatePromptPhase.Failed -> flareUpdateFailure(errorCode)
        else -> null
    }
    return FlareUpdatePromptModel(
        phase = phase,
        forced = forced,
        dismissible = !forced && phase != FlareUpdatePromptPhase.Installing,
        live = if (forced) FlareUpdatePromptLive.Assertive else FlareUpdatePromptLive.Polite,
        title = title,
        message = message,
        actions = actions,
        notes = phase == FlareUpdatePromptPhase.Offer || phase == FlareUpdatePromptPhase.Metered ||
            phase == FlareUpdatePromptPhase.Downloading || phase == FlareUpdatePromptPhase.Verifying,
        progress = flareUpdateBar(phase, progress),
    )
}

/** What the version panel's update row shows for one state (`spec/update-prompt-vectors.json`). */
fun flareVersionPanel(updateState: String?): FlareVersionPanelModel = when (updateState) {
    "checking" -> FlareVersionPanelModel(FlareVersionPanelRow.Check, null, FlareVersionPanelDetail.Checking)
    "upToDate" -> FlareVersionPanelModel(FlareVersionPanelRow.Check, FlareVersionPanelAction.Check, FlareVersionPanelDetail.UpToDate)
    "available" -> FlareVersionPanelModel(FlareVersionPanelRow.Update, FlareVersionPanelAction.Update, FlareVersionPanelDetail.Available)
    "required" -> FlareVersionPanelModel(FlareVersionPanelRow.Update, FlareVersionPanelAction.Update, FlareVersionPanelDetail.Required)
    "downloading" -> FlareVersionPanelModel(FlareVersionPanelRow.Update, null, FlareVersionPanelDetail.Downloading)
    "verifying" -> FlareVersionPanelModel(FlareVersionPanelRow.Update, null, FlareVersionPanelDetail.Verifying)
    "readyToInstall" -> FlareVersionPanelModel(FlareVersionPanelRow.Restart, FlareVersionPanelAction.Update, FlareVersionPanelDetail.Ready)
    "installing" -> FlareVersionPanelModel(FlareVersionPanelRow.Update, null, FlareVersionPanelDetail.Installing)
    "failed" -> FlareVersionPanelModel(FlareVersionPanelRow.Check, FlareVersionPanelAction.Check, FlareVersionPanelDetail.Failed)
    else -> FlareVersionPanelModel(FlareVersionPanelRow.Check, FlareVersionPanelAction.Check, null)
}

/** The channel's words of its own; null writes the channel as it arrived. */
fun flareVersionChannelText(channel: String?): FlareVersionChannelText? = when (channel) {
    "stable" -> FlareVersionChannelText.Stable
    "beta" -> FlareVersionChannelText.Beta
    "internal" -> FlareVersionChannelText.Internal
    else -> null
}

/** The title's words. */
fun FlareUpdatePromptTitle.label(strings: FlareStrings): String = when (this) {
    FlareUpdatePromptTitle.Available -> strings.updatePromptTitleAvailable
    FlareUpdatePromptTitle.Required -> strings.updatePromptTitleRequired
    FlareUpdatePromptTitle.Metered -> strings.updatePromptTitleMetered
    FlareUpdatePromptTitle.Downloading -> strings.updatePromptTitleDownloading
    FlareUpdatePromptTitle.Verifying -> strings.updatePromptTitleVerifying
    FlareUpdatePromptTitle.Ready -> strings.updatePromptTitleReady
    FlareUpdatePromptTitle.Installing -> strings.updatePromptTitleInstalling
    FlareUpdatePromptTitle.Failed -> strings.updatePromptTitleFailed
}

/** The message's words; [size] finishes the metered sentence and [reason] is what the host's reason says. */
fun FlareUpdatePromptMessage.label(strings: FlareStrings, size: String? = null, reason: String? = null): String = when (this) {
    FlareUpdatePromptMessage.Reason -> reason.orEmpty()
    FlareUpdatePromptMessage.Required -> strings.updatePromptMessageRequired
    FlareUpdatePromptMessage.RequiredReadOnly -> strings.updatePromptMessageRequiredReadOnly
    FlareUpdatePromptMessage.Metered -> listOfNotNull(strings.updatePromptMessageMetered, size).joinToString(" ")
    FlareUpdatePromptMessage.MeteredUnknown -> strings.updatePromptMessageMeteredUnknown
    FlareUpdatePromptMessage.Ready -> strings.updatePromptMessageReady
    FlareUpdatePromptMessage.ManifestUnavailable -> strings.updatePromptFailManifestUnavailable
    FlareUpdatePromptMessage.ManifestRejected -> strings.updatePromptFailManifestRejected
    FlareUpdatePromptMessage.NoArtifact -> strings.updatePromptFailNoArtifact
    FlareUpdatePromptMessage.InsufficientSpace -> strings.updatePromptFailInsufficientSpace
    FlareUpdatePromptMessage.DownloadFailed -> strings.updatePromptFailDownload
    FlareUpdatePromptMessage.HashMismatch -> strings.updatePromptFailHashMismatch
    FlareUpdatePromptMessage.InstallFailed -> strings.updatePromptFailInstall
    FlareUpdatePromptMessage.SignatureMismatch -> strings.updatePromptFailSignatureMismatch
    FlareUpdatePromptMessage.DowngradeRejected -> strings.updatePromptFailDowngrade
    FlareUpdatePromptMessage.NotSkippable -> strings.updatePromptFailNotSkippable
    FlareUpdatePromptMessage.Unknown -> strings.updatePromptFailUnknown
}

/** The action's words. */
fun FlareUpdatePromptAction.label(
    strings: FlareStrings,
    fallbackTarget: FlareUpdateFallbackTarget = FlareUpdateFallbackTarget.Website,
): String = when (this) {
    FlareUpdatePromptAction.Update -> strings.connectionUpdate
    FlareUpdatePromptAction.ContinueDownload -> strings.updatePromptContinueDownload
    FlareUpdatePromptAction.Restart -> strings.updatePromptRestart
    FlareUpdatePromptAction.Retry -> strings.updatePromptRetry
    FlareUpdatePromptAction.Fallback ->
        if (fallbackTarget == FlareUpdateFallbackTarget.Store) strings.updatePromptFallbackStore else strings.updatePromptFallbackWebsite
    FlareUpdatePromptAction.Later -> strings.updatePromptLater
    FlareUpdatePromptAction.Background -> strings.updatePromptBackground
    FlareUpdatePromptAction.Skip -> strings.updatePromptSkip
    FlareUpdatePromptAction.ContinueReadOnly -> strings.updatePromptContinueReadOnly
}

/** The words of the version panel's update row. */
fun FlareVersionPanelRow.label(strings: FlareStrings): String = when (this) {
    FlareVersionPanelRow.Check -> strings.versionPanelCheck
    FlareVersionPanelRow.Update -> strings.connectionUpdate
    FlareVersionPanelRow.Restart -> strings.updatePromptRestart
}

/** What the version panel's update row writes at its end. */
fun FlareVersionPanelDetail.label(strings: FlareStrings): String = when (this) {
    FlareVersionPanelDetail.Checking -> strings.versionPanelChecking
    FlareVersionPanelDetail.UpToDate -> strings.versionPanelUpToDate
    FlareVersionPanelDetail.Available -> strings.updatePromptTitleAvailable
    FlareVersionPanelDetail.Required -> strings.updatePromptTitleRequired
    FlareVersionPanelDetail.Downloading -> strings.updatePromptTitleDownloading
    FlareVersionPanelDetail.Verifying -> strings.updatePromptTitleVerifying
    FlareVersionPanelDetail.Ready -> strings.updatePromptTitleReady
    FlareVersionPanelDetail.Installing -> strings.updatePromptTitleInstalling
    FlareVersionPanelDetail.Failed -> strings.updatePromptTitleFailed
}

/** The channel in the reader's words, or as it arrived. */
fun flareVersionChannelLabel(channel: String, strings: FlareStrings): String = when (flareVersionChannelText(channel)) {
    FlareVersionChannelText.Stable -> strings.versionPanelChannelStable
    FlareVersionChannelText.Beta -> strings.versionPanelChannelBeta
    FlareVersionChannelText.Internal -> strings.versionPanelChannelInternal
    null -> channel
}
