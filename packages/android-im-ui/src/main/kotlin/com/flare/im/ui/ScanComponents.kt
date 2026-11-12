package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp

/** Canonical preview-space coordinates; capture and permission effects stay in the host. */
data class FlareScanMarker(val id: String, val corners: List<FlareScanPoint>, val label: String? = null)
data class FlareScanCapabilities(val live: Boolean = true, val album: Boolean = true, val paste: Boolean = true, val myCode: Boolean = true, val torch: Boolean = false)
data class FlareScanHeader(val title: String, val subtitle: String? = null, val avatarUrl: String? = null)
data class FlareScanFact(val label: String, val value: String)
data class FlareScanInput(val id: String, val kind: String, val label: String, val maxLen: Int)
data class FlareScanAction(val id: String, val label: String, val primary: Boolean = false, val inputs: List<FlareScanInput> = emptyList())

data class FlareScanMarkerBounds(val left: Double, val top: Double, val width: Double, val height: Double)

/** Decoder corners are normalized preview coordinates; missing/invalid geometry remains selectable. */
fun flareScanMarkerBounds(corners: List<FlareScanPoint>): FlareScanMarkerBounds {
    val points = corners.filter { it.x.isFinite() && it.y.isFinite() }
    val left = (points.minOfOrNull { it.x } ?: 0.0).coerceIn(0.0, 1.0)
    val top = (points.minOfOrNull { it.y } ?: 0.0).coerceIn(0.0, 1.0)
    val right = (points.maxOfOrNull { it.x } ?: 1.0).coerceIn(0.0, 1.0)
    val bottom = (points.maxOfOrNull { it.y } ?: 1.0).coerceIn(0.0, 1.0)
    return FlareScanMarkerBounds(left, top, right - left, bottom - top)
}

@Composable
fun ScanViewfinder(
    state: String,
    capabilities: FlareScanCapabilities,
    modifier: Modifier = Modifier,
    markers: List<FlareScanMarker> = emptyList(),
    hint: String? = null,
    torch: Boolean = false,
    onClose: () -> Unit,
    onToggleTorch: (() -> Unit)? = null,
    onPickImage: (() -> Unit)? = null,
    onPaste: (() -> Unit)? = null,
    onOpenMyCode: (() -> Unit)? = null,
    onSelectMarker: ((String) -> Unit)? = null,
    onRetry: (() -> Unit)? = null,
    onRequestPermission: (() -> Unit)? = null,
    onOpenSettings: (() -> Unit)? = null,
    preview: @Composable BoxScope.() -> Unit,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val label = hint ?: when (state) {
        "preparing" -> strings.scanPreparing; "live" -> strings.scanLive; "lowLight" -> strings.scanLowLight
        "locked" -> strings.scanLocked; "choosing" -> strings.scanChoosing; "paused" -> strings.scanPaused
        "imageDecoding" -> strings.scanImageDecoding; "imageError" -> strings.scanImageError; "noCodeInImage" -> strings.scanNoCodeInImage
        "noCamera" -> strings.scanNoCamera; "cameraBusy" -> strings.scanCameraBusy
        "insecureContext" -> strings.scanInsecureContext; else -> strings.scanCameraError
    }
    Column(modifier.fillMaxSize().background(colors.bgPrimary)) {
        Row(Modifier.fillMaxWidth().padding(FlareSizes.spacingMd), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
            Button(label = strings.close, variant = FlareButtonVariant.Quiet, onClick = onClose)
            Text(strings.scanTitle, color = colors.textPrimary)
            if (capabilities.torch) Button(label = if (torch) strings.scanTorchOff else strings.scanTorchOn, variant = FlareButtonVariant.Quiet, onClick = onToggleTorch)
        }
        BoxWithConstraints(Modifier.fillMaxWidth().weight(1f).background(colors.bgSecondary)) {
            preview()
            val previewWidth = maxWidth
            val previewHeight = maxHeight
            markers.forEachIndexed { index, marker ->
                val bounds = flareScanMarkerBounds(marker.corners)
                Box(Modifier.offset(x = previewWidth * bounds.left.toFloat(), y = previewHeight * bounds.top.toFloat()).width((previewWidth * bounds.width.toFloat()).coerceAtLeast(48.dp)).height((previewHeight * bounds.height.toFloat()).coerceAtLeast(48.dp)).border(2.dp, colors.primary)) {
                    Button(label = marker.label ?: "${strings.scanChooseCode} ${index + 1}", disabled = state != "choosing", onClick = { onSelectMarker?.invoke(marker.id) })
                }
            }
            val permission = when (state) { "permissionUndetermined" -> FlarePermissionState.Undetermined; "denied" -> FlarePermissionState.Denied; "restricted" -> FlarePermissionState.Restricted; else -> null }
            if (permission != null) Box(Modifier.align(Alignment.Center)) { PermissionPrompt(kind = FlarePermissionKind.Camera, state = permission, onRequest = onRequestPermission, onOpenSettings = onOpenSettings) }
            Text(label, color = colors.textPrimary, modifier = Modifier.align(Alignment.BottomCenter).background(colors.bgPrimary).padding(FlareSizes.spacingMd).semantics { liveRegion = LiveRegionMode.Polite })
        }
        Row(Modifier.fillMaxWidth().padding(FlareSizes.spacingMd), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
            if (capabilities.album) Button(label = strings.scanAlbum, variant = FlareButtonVariant.Secondary, onClick = onPickImage)
            if (capabilities.paste) Button(label = strings.scanPaste, variant = FlareButtonVariant.Secondary, onClick = onPaste)
            if (capabilities.myCode) Button(label = strings.myQrCode, variant = FlareButtonVariant.Secondary, onClick = onOpenMyCode)
            if (state in listOf("cameraError", "imageError", "noCodeInImage", "noCamera", "paused")) Button(label = strings.retry, onClick = onRetry)
        }
    }
}

@Composable
fun ScanResultSheet(
    phase: String,
    header: FlareScanHeader,
    facts: List<FlareScanFact> = emptyList(),
    notice: String? = null,
    actions: List<FlareScanAction> = emptyList(),
    busy: Boolean = false,
    onAction: (String, Map<String, String>) -> Unit,
    onDismiss: () -> Unit,
    onRetry: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val values = remember(actions) { mutableStateMapOf<String, String>() }
    BottomSheet(onClose = onDismiss, title = strings.scanResult, dismissible = !busy) {
        Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(FlareSizes.spacingLg), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                Avatar(userId = header.title, displayName = header.title, avatarUrl = header.avatarUrl, size = 48.dp)
                Column { Text(header.title, color = colors.textPrimary); header.subtitle?.let { Text(it, color = colors.textSecondary) } }
            }
            facts.forEach { fact -> Column { Text(fact.label, color = colors.textTertiary); Text(fact.value, color = colors.textPrimary) } }
            if (!notice.isNullOrEmpty()) Text(notice, color = colors.textSecondary, modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite })
            if (phase == "loading" || phase == "slow" || phase == "acting") Text(strings.scanPreparing, color = colors.textSecondary)
            actions.forEach { action ->
                val supported = action.inputs.all { it.kind == "text" && it.maxLen > 0 }
                action.inputs.filter { it.kind == "text" }.forEach { input ->
                    val key = "${action.id}/${input.id}"
                    Text(input.label, color = colors.textSecondary)
                    Input(value = values[key] ?: "", onValueChange = { values[key] = it }, maxLength = input.maxLen, disabled = busy)
                }
                if (!supported) Text(strings.scanUpgradeRequired, color = colors.textSecondary)
                Button(label = action.label, block = true, loading = busy, disabled = phase != "ready" || !supported,
                    variant = if (action.primary) FlareButtonVariant.Primary else FlareButtonVariant.Secondary,
                    onClick = { onAction(action.id, action.inputs.associate { it.id to (values["${action.id}/${it.id}"] ?: "").take(it.maxLen) }) })
            }
            if (phase in listOf("failed", "offlineWaiting", "unknown")) Button(label = strings.retry, disabled = busy, onClick = onRetry)
        }
    }
}
