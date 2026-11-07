package com.flare.im.ui

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.relocation.BringIntoViewRequester
import androidx.compose.foundation.relocation.bringIntoViewRequester
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

/**
 * The network and line diagnostics page's body. Spec: Feedback/AccessDiagnostics (`AccessDiagnostics`).
 *
 * The host passes what `access.getStatus` and `access.listAccessPoints` returned; what the page says is
 * [flareAccessDiagnostics]'s call (`spec/access-diagnostics-vectors.json`, the same in every kit). The panel holds no
 * SDK: it reports intent and draws what the host feeds back, and it never touches the clipboard. An action is drawn
 * only when the host passes its handler. Recovery comes first while recovering, because that is what the page is open
 * for then.
 */
@Composable
fun AccessDiagnostics(
    /** What `access.getStatus` returned; null until the host has read it. */
    status: FlareAccessStatus?,
    /** What `access.listAccessPoints` returned. */
    accessPoints: List<FlareAccessPoint> = emptyList(),
    /** `access.refresh` is in flight. */
    refreshing: Boolean = false,
    /** The `outcome` of the last `access.refresh`. */
    refreshOutcome: String? = null,
    /** `access.importRecovery` is in flight. */
    importing: Boolean = false,
    /** The `outcome` of the last `access.importRecovery`. */
    importOutcome: String? = null,
    /** Its `code` when rejected. */
    importCode: String? = null,
    /** The host is gathering and copying the diagnostics. */
    exporting: Boolean = false,
    /** The host's word on the clipboard: `copied` or `failed`. */
    exportOutcome: String? = null,
    /** Pin this access point (`access.pin`). */
    onPin: ((String) -> Unit)? = null,
    /** Let go of the pin (`access.unpin`). */
    onUnpin: (() -> Unit)? = null,
    /** Refresh the manifest now (`access.refresh`). */
    onRefresh: (() -> Unit)? = null,
    /** Import this recovery link (`access.importRecovery`), already trimmed. */
    onImportRecovery: ((String) -> Unit)? = null,
    /** Copy the diagnostics (`access.exportDiagnostics`, then the clipboard). */
    onExportDiagnostics: (() -> Unit)? = null,
) {
    val strings = flareStrings()
    val view = LocalView.current
    val model = remember(status, accessPoints) { flareAccessDiagnostics(status, accessPoints) }
    val refresh = flareAccessRefreshFeedback(refreshOutcome)
    val import = flareAccessImportFeedback(importOutcome, importCode)
    val export = flareAccessExportFeedback(exportOutcome)
    var link by rememberSaveable { mutableStateOf("") }
    // An adopted link is done with: left in the field it would only invite a second import.
    LaunchedEffect(importOutcome) { if (importOutcome == "adopted") link = "" }
    // The newest answer, else the page's lead notice, is what is announced.
    val spoken = import?.text?.label(strings) ?: refresh?.text?.label(strings) ?: export?.text?.label(strings)
        ?: model.notices.firstOrNull()?.text?.label(strings)
    LaunchedEffect(spoken) { if (spoken != null) view.announceForAccessibility(spoken) }

    val recovery: @Composable () -> Unit = {
        AccessRecovery(
            link = link,
            onLinkChange = { link = it },
            refreshing = refreshing,
            refresh = refresh,
            importing = importing,
            import = import,
            exporting = exporting,
            export = export,
            content = (status != null) to accessPoints.size,
            onRefresh = onRefresh,
            onImportRecovery = onImportRecovery,
            onExportDiagnostics = onExportDiagnostics,
        )
    }
    Column(
        Modifier.fillMaxWidth().semantics { contentDescription = strings.accessDiagnosticsTitle },
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXl),
    ) {
        if (model.notices.isNotEmpty()) {
            Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                model.notices.forEach { notice ->
                    StatusBanner(text = notice.text.label(strings), tone = notice.tone, pulse = notice.pulse)
                }
            }
        }
        if (model.state == FlareAccessDiagnosticsState.Recovering) recovery()
        AccessCurrentLine(status, model)
        AccessLines(model, onPin, onUnpin)
        if (model.state != FlareAccessDiagnosticsState.Recovering) recovery()
    }
}

@Composable
private fun AccessSection(title: String, content: @Composable () -> Unit) {
    val colors = flareColors()
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
        Text(
            title,
            color = colors.textPrimary,
            fontSize = FlareTextRoles.Body.fontSize,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.semantics { heading() },
        )
        content()
    }
}

@Composable
private fun AccessCurrentLine(status: FlareAccessStatus?, model: FlareAccessDiagnosticsModel) {
    val strings = flareStrings()
    AccessSection(strings.accessDiagnosticsCurrent) {
        AccessFact(strings.accessDiagnosticsAccessPoint, status?.accessPointId)
        AccessFact(strings.accessDiagnosticsRegion, status?.regionId)
        AccessFact(strings.accessDiagnosticsProtocol, flareAccessProtocolLabel(status?.protocol))
        AccessFact(strings.accessDiagnosticsRtt, model.rtt.label(strings), model.rtt.grade?.let(::flareAccessRttTone))
        AccessFact(strings.accessDiagnosticsSerial, status?.takeIf { it.loaded }?.serial?.toString())
        AccessFact(strings.accessDiagnosticsSource, flareAccessSourceLabel(status?.source, strings))
        AccessFact(
            strings.accessDiagnosticsManifest,
            when (model.manifest) {
                FlareAccessManifestState.Valid -> strings.accessDiagnosticsManifestValid
                FlareAccessManifestState.Stale -> strings.accessDiagnosticsManifestStale
                FlareAccessManifestState.None -> strings.accessDiagnosticsManifestNone
            },
        )
        AccessFact(
            strings.connectionDevelopmentMode,
            if (status?.developmentMode == true) strings.accessDiagnosticsOn else strings.accessDiagnosticsOff,
        )
        model.reportedAccessPointId?.let { AccessFact(strings.accessDiagnosticsReportedAccessPoint, it) }
        model.recoveryRounds?.let { AccessFact(strings.accessDiagnosticsRecoveryRounds, it.toString()) }
    }
}

/** A label and its value on one line; a missing value is a dash, never a blank. */
@Composable
private fun AccessFact(label: String, value: String?, tone: FlareStatusTone? = null) {
    val colors = flareColors()
    Row(
        Modifier.fillMaxWidth().semantics(mergeDescendants = true) {},
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
    ) {
        Text(label, color = colors.textSecondary, fontSize = FlareTextRoles.Body.fontSize, modifier = Modifier.weight(1f))
        Column(Modifier.weight(1f), horizontalAlignment = Alignment.End) {
            if (value != null && tone != null) {
                AccessTag(value, tone)
            } else {
                Text(
                    value ?: "—",
                    color = if (value == null) colors.textTertiary else colors.textPrimary,
                    fontSize = FlareTextRoles.Body.fontSize,
                    textAlign = TextAlign.End,
                )
            }
        }
    }
}

@Composable
private fun AccessLines(
    model: FlareAccessDiagnosticsModel,
    onPin: ((String) -> Unit)?,
    onUnpin: (() -> Unit)?,
) {
    val strings = flareStrings()
    val colors = flareColors()
    AccessSection(strings.accessDiagnosticsLines) {
        if (model.regions.isEmpty()) {
            Text(strings.accessDiagnosticsNoLines, color = colors.textTertiary, fontSize = FlareTextRoles.Body.fontSize)
        }
        model.regions.forEach { region ->
            Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                region.regionId?.let { regionId ->
                    Text(
                        regionId,
                        color = colors.textSecondary,
                        fontSize = FlareTextRoles.Caption.fontSize,
                        modifier = Modifier.semantics { heading() },
                    )
                }
                region.accessPoints.forEachIndexed { index, row ->
                    if (index > 0) HorizontalDivider(thickness = 1.dp, color = colors.borderSecondary)
                    AccessLineRow(row, onPin, onUnpin)
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun AccessLineRow(row: FlareAccessPointRow, onPin: ((String) -> Unit)?, onUnpin: (() -> Unit)?) {
    val strings = flareStrings()
    val colors = flareColors()
    val toggle: (() -> Unit)? = when (row.pin) {
        FlareAccessPinAction.Pin -> onPin?.let { pin -> { pin(row.accessPointId) } }
        FlareAccessPinAction.Unpin -> onUnpin
        null -> null
    }
    Row(
        Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
    ) {
        Column(
            Modifier.weight(1f).semantics(mergeDescendants = true) {},
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
        ) {
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
            ) {
                Text(row.accessPointId, color = colors.textPrimary, fontSize = FlareTextRoles.Body.fontSize, fontFamily = FontFamily.Monospace)
                if (row.current) AccessTag(strings.accessDiagnosticsCurrentTag, FlareStatusTone.Info)
                if (row.pinned) AccessTag(strings.accessDiagnosticsPinnedTag, FlareStatusTone.Neutral)
            }
            row.host?.let { Text(it, color = colors.textSecondary, fontSize = FlareTextRoles.Caption.fontSize) }
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
            ) {
                AccessTag(
                    when (row.status) {
                        FlareAccessPointState.Active -> strings.accessDiagnosticsStatusActive
                        FlareAccessPointState.Draining -> strings.accessDiagnosticsStatusDraining
                        FlareAccessPointState.Disabled -> strings.accessDiagnosticsStatusDisabled
                        FlareAccessPointState.Unknown -> strings.accessDiagnosticsStatusUnknown
                    },
                    row.statusTone,
                )
                row.breaker?.let { breaker ->
                    AccessTag(
                        when (breaker) {
                            FlareAccessBreakerState.Open -> strings.accessDiagnosticsBreakerOpen
                            FlareAccessBreakerState.HalfOpen -> strings.accessDiagnosticsBreakerHalfOpen
                        },
                        row.breakerTone ?: FlareStatusTone.Neutral,
                    )
                }
                val grade = row.rtt.grade
                val rtt = row.rtt.label(strings)
                if (grade != null && rtt != null) AccessTag(rtt, flareAccessRttTone(grade))
            }
        }
        if (toggle != null) {
            Button(
                label = if (row.pin == FlareAccessPinAction.Pin) strings.accessDiagnosticsPin else strings.accessDiagnosticsUnpin,
                variant = FlareButtonVariant.Secondary,
                size = FlareControlSize.Sm,
                maintainTouchTarget = true,
                onClick = toggle,
            )
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun AccessRecovery(
    link: String,
    onLinkChange: (String) -> Unit,
    refreshing: Boolean,
    refresh: FlareAccessFeedback<FlareAccessRefreshText>?,
    importing: Boolean,
    import: FlareAccessFeedback<FlareAccessImportText>?,
    exporting: Boolean,
    export: FlareAccessFeedback<FlareAccessExportText>?,
    content: Any,
    onRefresh: (() -> Unit)?,
    onImportRecovery: ((String) -> Unit)?,
    onExportDiagnostics: (() -> Unit)?,
) {
    val strings = flareStrings()
    val colors = flareColors()
    AccessSection(strings.accessDiagnosticsRecovery) {
        if (onRefresh != null || onExportDiagnostics != null) {
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            ) {
                if (onRefresh != null) {
                    Button(
                        label = strings.accessDiagnosticsRefresh,
                        variant = FlareButtonVariant.Secondary,
                        loading = refreshing,
                        maintainTouchTarget = true,
                        onClick = onRefresh,
                    )
                }
                if (onExportDiagnostics != null) {
                    Button(
                        label = strings.accessDiagnosticsExport,
                        variant = FlareButtonVariant.Secondary,
                        loading = exporting,
                        maintainTouchTarget = true,
                        onClick = onExportDiagnostics,
                    )
                }
            }
        }
        refresh?.let { StatusBanner(text = it.text.label(strings), tone = it.tone, dot = false) }
        export?.let { StatusBanner(text = it.text.label(strings), tone = it.tone, dot = false) }
        if (onImportRecovery != null) {
            val trimmed = link.trim()
            val importable = trimmed.isNotEmpty() && !importing
            val submit = { if (importable) onImportRecovery(trimmed) }
            Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                Text(strings.accessDiagnosticsImportLabel, color = colors.textSecondary, fontSize = FlareTextRoles.Caption.fontSize)
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
                ) {
                    Column(Modifier.weight(1f)) {
                        Input(
                            value = link,
                            onValueChange = onLinkChange,
                            placeholder = strings.accessDiagnosticsImportPlaceholder,
                            disabled = importing,
                            monospace = true,
                            onSubmit = submit,
                        )
                    }
                    Button(
                        label = strings.accessDiagnosticsImport,
                        loading = importing,
                        disabled = !importable,
                        maintainTouchTarget = true,
                        onClick = submit,
                    )
                }
                Text(strings.accessDiagnosticsImportHint, color = colors.textSecondary, fontSize = FlareTextRoles.Caption.fontSize)
                import?.let { ImportAnswer(it.text.label(strings), it.tone, importing, content) }
            }
        }
    }
}

/** The kit tag's look in a status tone: the tone's ink on a faint tint of the tone, caption size. It is words, never a control. */
@Composable
private fun AccessTag(text: String, tone: FlareStatusTone) {
    val colors = flareColors()
    val (ink, tint) = when (tone) {
        FlareStatusTone.Info -> colors.infoText to colors.info
        FlareStatusTone.Success -> colors.successText to colors.success
        FlareStatusTone.Warning -> colors.warningText to colors.warning
        FlareStatusTone.Danger -> colors.errorText to colors.error
        FlareStatusTone.Neutral -> colors.textSecondary to colors.textTertiary
    }
    val shape = RoundedCornerShape(FlareSizes.radiusSm)
    Text(
        text,
        color = ink,
        fontSize = FlareTextRoles.Caption.fontSize,
        fontWeight = FontWeight.Medium,
        modifier = Modifier.clip(shape).background(tint.copy(alpha = FlareOpacity.tintWeak)).padding(horizontal = FlareSizes.spacing2xs),
    )
}

/**
 * The answer to a recovery link. A link opens this page from outside, at its top, and the answer stands lower than a
 * phone shows: unseen, a refused link would look like nothing happened. The page loads while the link is checked, so
 * [content] (what has arrived above, not what ticks) brings it back when the lines push it down again.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun ImportAnswer(text: String, tone: FlareStatusTone, importing: Boolean, content: Any) {
    val answer = remember { BringIntoViewRequester() }
    Box(Modifier.bringIntoViewRequester(answer)) {
        StatusBanner(text = text, tone = tone, dot = false)
    }
    LaunchedEffect(text, importing, content) {
        if (importing) return@LaunchedEffect
        // Laid out in the frame after this composition: before that it has no place to bring into view.
        withFrameNanos { }
        answer.bringIntoView()
    }
}
