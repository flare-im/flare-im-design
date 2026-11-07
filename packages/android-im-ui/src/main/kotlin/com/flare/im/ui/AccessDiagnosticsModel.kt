package com.flare.im.ui

import kotlin.math.roundToLong

/** The connection diagnostics of `access.getStatus`: only what the page reads. */
data class FlareAccessConnectAck(
    /** The access point the server reports for the connection. */
    val accessPointId: String? = null,
    /** The server reports a different access point than the client chose. */
    val accessPointMismatch: Boolean = false,
)

/** `access.getStatus.recovering`: there only while every line has failed. */
data class FlareAccessRecovering(
    /** Bootstrap rounds so far. */
    val rounds: Int,
    /** When the next round starts; null while the device has no network. */
    val nextRoundAtMs: Long? = null,
)

/** What `access.getStatus` returns, as far as the page reads it (Vue `FlareAccessStatus`). */
data class FlareAccessStatus(
    /** The directory holds a usable manifest. */
    val loaded: Boolean,
    val serial: Long? = null,
    /** seed, https:<mirror base>, wellKnown:<apId>, recovery, development or none. */
    val source: String? = null,
    /** Past its expiry: still connectable. */
    val stale: Boolean = false,
    val developmentMode: Boolean = false,
    val regionId: String? = null,
    /** The access point of the current connection. */
    val accessPointId: String? = null,
    val protocol: String? = null,
    val connectAck: FlareAccessConnectAck? = null,
    val recovering: FlareAccessRecovering? = null,
)

/** One line of `access.listAccessPoints`. */
data class FlareAccessPoint(
    val accessPointId: String,
    val regionId: String? = null,
    val host: String? = null,
    /** active, draining, disabled or unknown; any other string reads unknown. */
    val status: String,
    val rttMs: Double? = null,
    /** closed, open or halfOpen. */
    val breaker: String,
    val pinned: Boolean = false,
    val current: Boolean = false,
)

/** How the page stands as a whole. */
enum class FlareAccessDiagnosticsState { Normal, Recovering, Warning }
enum class FlareAccessManifestState { Valid, Stale, None }
enum class FlareAccessRttGrade { Good, Fair, Poor }
enum class FlareAccessPointState { Active, Draining, Disabled, Unknown }
enum class FlareAccessBreakerState { Open, HalfOpen }
enum class FlareAccessPinAction { Pin, Unpin }
enum class FlareAccessSourceKind { Seed, Mirror, WellKnown, Recovery, Development, None, Unknown }

/** A line at the top of the page. */
enum class FlareAccessNoticeText { Healthy, NotConnected, ServiceUnavailable, WaitingForNetwork, AccessPointMismatch, ManifestStale }
enum class FlareAccessRefreshText { Adopted, UpToDate, Failed, Skipped }
enum class FlareAccessImportText { Adopted, Unchanged, Rollback, Expired, WrongApp, DevelopmentMode, Untrusted, Malformed, Rejected }
enum class FlareAccessExportText { Copied, Failed }

data class FlareAccessNotice(val text: FlareAccessNoticeText, val tone: FlareStatusTone, val pulse: Boolean = false)

/** The latency to show and its grade; unknown has neither. */
data class FlareAccessRtt(
    /** Whole milliseconds to show; null when unknown. */
    val shownMs: Long? = null,
    val grade: FlareAccessRttGrade? = null,
)

data class FlareAccessSource(
    val kind: FlareAccessSourceKind,
    /** A mirror's host, a well-known access point, or an unknown source as it arrived. */
    val detail: String? = null,
)

/** One row of the line list. */
data class FlareAccessPointRow(
    val accessPointId: String,
    val host: String?,
    val current: Boolean,
    val pinned: Boolean,
    val status: FlareAccessPointState,
    val statusTone: FlareStatusTone,
    val breaker: FlareAccessBreakerState?,
    val breakerTone: FlareStatusTone?,
    val rtt: FlareAccessRtt,
    val pin: FlareAccessPinAction?,
)

data class FlareAccessRegion(
    /** Null for lines without a region: no heading. */
    val regionId: String?,
    val accessPoints: List<FlareAccessPointRow>,
)

/** What the page shows for one status and list. */
data class FlareAccessDiagnosticsModel(
    val state: FlareAccessDiagnosticsState,
    val notices: List<FlareAccessNotice>,
    val manifest: FlareAccessManifestState,
    /** The current line's latency, from its row. */
    val rtt: FlareAccessRtt,
    /** What the server reports while it disagrees with the client. */
    val reportedAccessPointId: String? = null,
    val recoveryRounds: Int? = null,
    val regions: List<FlareAccessRegion>,
)

/** A one-line answer to one of the page's actions. */
data class FlareAccessFeedback<T>(val text: T, val tone: FlareStatusTone)

/** Where the latency grades change, in whole milliseconds (the shared table's `thresholds`). */
object FlareAccessRttThresholds {
    const val GOOD_BELOW_MS = 150L
    const val POOR_ABOVE_MS = 400L
}

/** The tone a latency grade is drawn in. */
fun flareAccessRttTone(grade: FlareAccessRttGrade): FlareStatusTone = when (grade) {
    FlareAccessRttGrade.Good -> FlareStatusTone.Success
    FlareAccessRttGrade.Fair -> FlareStatusTone.Warning
    FlareAccessRttGrade.Poor -> FlareStatusTone.Danger
}

/** The latency to show and its grade; unknown (missing, negative, not finite) has neither. */
fun flareAccessRtt(rttMs: Double?): FlareAccessRtt {
    if (rttMs == null || !rttMs.isFinite() || rttMs < 0) return FlareAccessRtt()
    val shown = rttMs.roundToLong()
    if (shown < FlareAccessRttThresholds.GOOD_BELOW_MS) return FlareAccessRtt(shown, FlareAccessRttGrade.Good)
    return FlareAccessRtt(shown, if (shown > FlareAccessRttThresholds.POOR_ABOVE_MS) FlareAccessRttGrade.Poor else FlareAccessRttGrade.Fair)
}

/** The protocol's name on screen; a protocol the kit does not know is shown as it arrives. */
fun flareAccessProtocolLabel(protocol: String?): String? = when (protocol) {
    "quic" -> "QUIC"
    "ws" -> "WebSocket"
    else -> protocol
}

/** `https:<base>` and `wellKnown:<apId>` read apart; the plain sources are their own kinds. */
fun flareAccessSource(source: String?): FlareAccessSource = when {
    source == null || source == "none" -> FlareAccessSource(FlareAccessSourceKind.None)
    source == "seed" -> FlareAccessSource(FlareAccessSourceKind.Seed)
    source == "recovery" -> FlareAccessSource(FlareAccessSourceKind.Recovery)
    source == "development" -> FlareAccessSource(FlareAccessSourceKind.Development)
    source.startsWith("https:") -> {
        val authority = source.removePrefix("https:").substringAfter("://")
        FlareAccessSource(FlareAccessSourceKind.Mirror, authority.substringBefore('/'))
    }
    source.startsWith("wellKnown:") -> FlareAccessSource(FlareAccessSourceKind.WellKnown, source.removePrefix("wellKnown:"))
    else -> FlareAccessSource(FlareAccessSourceKind.Unknown, source)
}

/** One line's row: a pin needs an active line that is not cooling down; a pinned line can always be let go. */
fun flareAccessPointRow(point: FlareAccessPoint): FlareAccessPointRow {
    val (status, tone) = when (point.status) {
        "active" -> FlareAccessPointState.Active to FlareStatusTone.Success
        "draining" -> FlareAccessPointState.Draining to FlareStatusTone.Warning
        "disabled" -> FlareAccessPointState.Disabled to FlareStatusTone.Neutral
        else -> FlareAccessPointState.Unknown to FlareStatusTone.Neutral
    }
    val breaker = when (point.breaker) {
        "open" -> FlareAccessBreakerState.Open
        "halfOpen" -> FlareAccessBreakerState.HalfOpen
        else -> null
    }
    val pin = when {
        point.pinned -> FlareAccessPinAction.Unpin
        status == FlareAccessPointState.Active && breaker != FlareAccessBreakerState.Open -> FlareAccessPinAction.Pin
        else -> null
    }
    return FlareAccessPointRow(
        accessPointId = point.accessPointId,
        host = point.host,
        current = point.current,
        pinned = point.pinned,
        status = status,
        statusTone = tone,
        breaker = breaker,
        breakerTone = when (breaker) {
            FlareAccessBreakerState.Open -> FlareStatusTone.Danger
            FlareAccessBreakerState.HalfOpen -> FlareStatusTone.Warning
            null -> null
        },
        rtt = flareAccessRtt(point.rttMs),
        pin = pin,
    )
}

private fun noticesOf(
    status: FlareAccessStatus,
    state: FlareAccessDiagnosticsState,
    warnings: List<FlareAccessNotice>,
): List<FlareAccessNotice> = when (state) {
    FlareAccessDiagnosticsState.Recovering -> {
        val recovering = status.recovering
        val lead = if (recovering != null && recovering.nextRoundAtMs == null) {
            FlareAccessNotice(FlareAccessNoticeText.WaitingForNetwork, FlareStatusTone.Warning)
        } else {
            FlareAccessNotice(FlareAccessNoticeText.ServiceUnavailable, FlareStatusTone.Warning, pulse = true)
        }
        listOf(lead) + warnings
    }
    FlareAccessDiagnosticsState.Warning -> warnings
    FlareAccessDiagnosticsState.Normal -> listOf(
        if (status.accessPointId.isNullOrEmpty()) {
            FlareAccessNotice(FlareAccessNoticeText.NotConnected, FlareStatusTone.Neutral)
        } else {
            FlareAccessNotice(FlareAccessNoticeText.Healthy, FlareStatusTone.Success)
        },
    )
}

/**
 * What the page shows. [status] is null until the host has read one. Rules:
 * `spec/access-diagnostics-vectors.json`, run by all four kits.
 */
fun flareAccessDiagnostics(status: FlareAccessStatus?, accessPoints: List<FlareAccessPoint>): FlareAccessDiagnosticsModel {
    val regions = accessPoints.groupBy { it.regionId }
        .map { (regionId, points) -> FlareAccessRegion(regionId, points.map(::flareAccessPointRow)) }
    val rtt = flareAccessRtt(accessPoints.firstOrNull { it.current }?.rttMs)
    if (status == null) {
        return FlareAccessDiagnosticsModel(FlareAccessDiagnosticsState.Normal, emptyList(), FlareAccessManifestState.None, rtt, regions = regions)
    }
    val mismatch = status.connectAck?.accessPointMismatch == true
    val warnings = buildList {
        if (mismatch) add(FlareAccessNotice(FlareAccessNoticeText.AccessPointMismatch, FlareStatusTone.Warning))
        if (status.stale) add(FlareAccessNotice(FlareAccessNoticeText.ManifestStale, FlareStatusTone.Warning))
    }
    val state = when {
        status.recovering != null || !status.loaded -> FlareAccessDiagnosticsState.Recovering
        warnings.isNotEmpty() -> FlareAccessDiagnosticsState.Warning
        else -> FlareAccessDiagnosticsState.Normal
    }
    return FlareAccessDiagnosticsModel(
        state = state,
        notices = noticesOf(status, state, warnings),
        manifest = when {
            !status.loaded -> FlareAccessManifestState.None
            status.stale -> FlareAccessManifestState.Stale
            else -> FlareAccessManifestState.Valid
        },
        rtt = rtt,
        reportedAccessPointId = if (mismatch) status.connectAck?.accessPointId else null,
        recoveryRounds = status.recovering?.rounds,
        regions = regions,
    )
}

/** What `access.refresh` answered, in the page's words; nothing for an outcome the kit does not know. */
fun flareAccessRefreshFeedback(outcome: String?): FlareAccessFeedback<FlareAccessRefreshText>? = when (outcome) {
    "adopted" -> FlareAccessFeedback(FlareAccessRefreshText.Adopted, FlareStatusTone.Success)
    "upToDate" -> FlareAccessFeedback(FlareAccessRefreshText.UpToDate, FlareStatusTone.Success)
    "failed", "oldValues" -> FlareAccessFeedback(FlareAccessRefreshText.Failed, FlareStatusTone.Warning)
    "skipped" -> FlareAccessFeedback(FlareAccessRefreshText.Skipped, FlareStatusTone.Neutral)
    else -> null
}

private fun rejectionText(code: String?): FlareAccessImportText = when (code) {
    "rollback" -> FlareAccessImportText.Rollback
    "expired" -> FlareAccessImportText.Expired
    "wrongBootstrapId" -> FlareAccessImportText.WrongApp
    "developmentMode" -> FlareAccessImportText.DevelopmentMode
    "badSignature", "unknownKey", "revoked", "wrongPayloadType" -> FlareAccessImportText.Untrusted
    "malformedEnvelope", "invalidPayload", "tooLarge" -> FlareAccessImportText.Malformed
    else -> if (code?.startsWith("keyCert.") == true) FlareAccessImportText.Untrusted else FlareAccessImportText.Rejected
}

/** What `access.importRecovery` answered: its `outcome`, and its `code` when rejected. */
fun flareAccessImportFeedback(outcome: String?, code: String?): FlareAccessFeedback<FlareAccessImportText>? = when (outcome) {
    "adopted" -> FlareAccessFeedback(FlareAccessImportText.Adopted, FlareStatusTone.Success)
    "unchanged" -> FlareAccessFeedback(FlareAccessImportText.Unchanged, FlareStatusTone.Neutral)
    "rejected" -> FlareAccessFeedback(rejectionText(code), FlareStatusTone.Danger)
    else -> null
}

/** The host's word on the clipboard: copied or failed. */
fun flareAccessExportFeedback(outcome: String?): FlareAccessFeedback<FlareAccessExportText>? = when (outcome) {
    "copied" -> FlareAccessFeedback(FlareAccessExportText.Copied, FlareStatusTone.Success)
    "failed" -> FlareAccessFeedback(FlareAccessExportText.Failed, FlareStatusTone.Danger)
    else -> null
}

/** The words of a top-of-page notice. */
fun FlareAccessNoticeText.label(strings: FlareStrings): String = when (this) {
    FlareAccessNoticeText.Healthy -> strings.accessDiagnosticsHealthy
    FlareAccessNoticeText.NotConnected -> strings.accessDiagnosticsNotConnected
    FlareAccessNoticeText.ServiceUnavailable -> strings.connectionServiceUnavailable
    FlareAccessNoticeText.WaitingForNetwork -> strings.connectionWaitingForNetwork
    FlareAccessNoticeText.AccessPointMismatch -> strings.accessDiagnosticsAccessPointMismatch
    FlareAccessNoticeText.ManifestStale -> strings.accessDiagnosticsManifestStaleNotice
}

/** The answer to a refresh. */
fun FlareAccessRefreshText.label(strings: FlareStrings): String = when (this) {
    FlareAccessRefreshText.Adopted -> strings.accessDiagnosticsRefreshAdopted
    FlareAccessRefreshText.UpToDate -> strings.accessDiagnosticsRefreshUpToDate
    FlareAccessRefreshText.Failed -> strings.accessDiagnosticsRefreshFailed
    FlareAccessRefreshText.Skipped -> strings.accessDiagnosticsRefreshSkipped
}

/** The answer to an import. */
fun FlareAccessImportText.label(strings: FlareStrings): String = when (this) {
    FlareAccessImportText.Adopted -> strings.accessDiagnosticsImportAdopted
    FlareAccessImportText.Unchanged -> strings.accessDiagnosticsImportUnchanged
    FlareAccessImportText.Rollback -> strings.accessDiagnosticsImportRollback
    FlareAccessImportText.Expired -> strings.accessDiagnosticsImportExpired
    FlareAccessImportText.WrongApp -> strings.accessDiagnosticsImportWrongApp
    FlareAccessImportText.DevelopmentMode -> strings.accessDiagnosticsImportDevelopmentMode
    FlareAccessImportText.Untrusted -> strings.accessDiagnosticsImportUntrusted
    FlareAccessImportText.Malformed -> strings.accessDiagnosticsImportMalformed
    FlareAccessImportText.Rejected -> strings.accessDiagnosticsImportRejected
}

/** The answer to an export. */
fun FlareAccessExportText.label(strings: FlareStrings): String = when (this) {
    FlareAccessExportText.Copied -> strings.accessDiagnosticsExportCopied
    FlareAccessExportText.Failed -> strings.accessDiagnosticsExportFailed
}

/** A latency for the page: `86 ms · Good`. */
fun FlareAccessRtt.label(strings: FlareStrings): String? {
    val word = when (grade) {
        FlareAccessRttGrade.Good -> strings.accessDiagnosticsRttGood
        FlareAccessRttGrade.Fair -> strings.accessDiagnosticsRttFair
        FlareAccessRttGrade.Poor -> strings.accessDiagnosticsRttPoor
        null -> return null
    }
    return "$shownMs ms · $word"
}

/** Where the manifest came from, in words. */
fun flareAccessSourceLabel(source: String?, strings: FlareStrings): String? {
    val read = flareAccessSource(source)
    return when (read.kind) {
        FlareAccessSourceKind.Seed -> strings.accessDiagnosticsSourceSeed
        FlareAccessSourceKind.Mirror -> "${strings.accessDiagnosticsSourceMirror} ${read.detail}"
        FlareAccessSourceKind.WellKnown -> "${strings.accessDiagnosticsAccessPoint} ${read.detail}"
        FlareAccessSourceKind.Recovery -> strings.accessDiagnosticsSourceRecovery
        FlareAccessSourceKind.Development -> strings.accessDiagnosticsSourceDevelopment
        FlareAccessSourceKind.None -> strings.accessDiagnosticsSourceNone
        FlareAccessSourceKind.Unknown -> read.detail
    }
}
