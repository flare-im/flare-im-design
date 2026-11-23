package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Forward-target picker — search + multi-select + send. Spec: Conversation/ForwardPicker.
 *
 * Height: the header, search field and Send footer always keep their size; the target list takes what is left,
 * up to 300 dp, and scrolls. So under a bounded host (a [BottomSheet], a [Modal], `FlareScreen(scroll = false)`,
 * or any fixed-height box) Send stays on screen however short the host gets — a small phone, landscape, or the
 * keyboard raised by the search field. Under an unbounded host (inside a vertical scroll) the list is simply
 * 300 dp tall.
 *
 * On a kit overlay (sheet, modal, drawer) the overlay supplies the surface and closes on its scrim and back, so
 * the picker drops its own card, fixed width and close control; standalone it is a 340 dp card.
 *
 * A host that sends from the picker (Vue `ForwardPicker` in a busy `FlareFormSheet`) names it with [title], holds
 * the selection ([selectedIds] with [onSelectionChange]) so a partial failure can keep only the targets that failed,
 * marks it [busy] while sending (Send spins, the rows and the search are locked) and shows what failed in [error].
 * With [cancelLabel] the footer is the form sheet's two equal keys — [cancelLabel] (closes; locked while busy) and
 * [confirmLabel] (发送（N）, off with nothing picked) — instead of the picked count beside 发送.
 */
@Composable
fun ForwardPicker(
    targets: List<ForwardTarget>,
    multiple: Boolean = true,
    dismissible: Boolean = true,
    onConfirm: ((List<String>) -> Unit)? = null,
    onClose: (() -> Unit)? = null,
    title: String? = null,
    selectedIds: List<String>? = null,
    onSelectionChange: ((List<String>) -> Unit)? = null,
    busy: Boolean = false,
    error: String? = null,
    confirmLabel: String? = null,
    cancelLabel: String? = null,
) {
    val colors = flareColors()
    var query by remember { mutableStateOf("") }
    val own = remember { mutableStateListOf<String>() }
    val selected: List<String> = selectedIds ?: own
    val filtered = targets.filter {
        val q = query.trim().lowercase()
        q.isEmpty() || it.name.lowercase().contains(q) || (it.subtitle?.lowercase()?.contains(q) == true)
    }
    fun toggle(id: String) {
        if (busy) return
        val next = if (!multiple) listOf(id) else if (id in selected) selected - id else selected + id
        if (selectedIds == null) { own.clear(); own.addAll(next) }
        onSelectionChange?.invoke(next)
    }

    val onOverlay = LocalFlareOverlaySurface.current != null
    BoxWithConstraints(
        if (onOverlay) Modifier.fillMaxWidth()
        else Modifier.width(340.dp).clip(RoundedCornerShape(FlareSizes.radiusXl))
            .background(colors.bgPrimary)
            .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusXl)),
    ) {
        // A weighted child of an unbounded Column collapses to nothing, so the list yields to the footer only when
        // there is a bound to yield under.
        val bounded = constraints.hasBoundedHeight
        Column(Modifier.fillMaxWidth()) {
            Row(
                Modifier.fillMaxWidth().padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingMd, top = FlareSizes.spacing2md, bottom = FlareSizes.spacingSm),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(title ?: flareStrings().forwardTo, color = colors.textPrimary, fontWeight = FontWeight.SemiBold,
                    fontSize = FlareSizes.fontSizeXl.value.sp)
                Spacer(Modifier.weight(1f))
                if (dismissible && !onOverlay) {
                    Icon(Icons.Outlined.Close, contentDescription = flareStrings().close, tint = colors.textTertiary,
                        modifier = Modifier.size(18.dp).clickable { onClose?.invoke() })
                }
            }
            // search
            Row(
                Modifier.padding(horizontal = FlareSizes.spacingMd).fillMaxWidth()
                    .clip(RoundedCornerShape(FlareSizes.radiusLg)).background(colors.bgSecondary)
                    .padding(horizontal = FlareSizes.spacing2sm, vertical = FlareSizes.spacingSm),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Outlined.Search, contentDescription = null, tint = colors.textTertiary, modifier = Modifier.size(FlareSizes.iconSizeSm))
                Spacer(Modifier.width(FlareSizes.spacingSm))
                BasicTextField(
                    value = query, onValueChange = { query = it }, singleLine = true, enabled = !busy,
                    textStyle = TextStyle(color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg),
                    cursorBrush = SolidColor(colors.primary),
                    modifier = Modifier.weight(1f),
                    decorationBox = { inner ->
                        if (query.isEmpty()) Text(flareStrings().searchConversations, color = colors.textTertiary, fontSize = FlareSizes.fontSizeLg)
                        inner()
                    },
                )
            }
            Column(
                Modifier.then(if (bounded) Modifier.weight(1f, fill = false) else Modifier)
                    .heightIn(max = 300.dp).verticalScroll(rememberScrollState())
                    .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs),
            ) {
                filtered.forEach { tgt ->
                    val on = selected.contains(tgt.id)
                    Row(
                        Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusLg))
                            .background(if (on) colors.bgSelected else Color.Transparent)
                            .clickable(enabled = !busy) { toggle(tgt.id) }.padding(horizontal = FlareSizes.spacingSm, vertical = 7.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Box(
                            Modifier.size(20.dp).clip(CircleShape)
                                .background(if (on) colors.primary else Color.Transparent)
                                .border(1.5.dp, if (on) colors.primary else colors.borderHover, CircleShape),
                            contentAlignment = Alignment.Center,
                        ) {
                            if (on) Icon(Icons.Outlined.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(13.dp))
                        }
                        Spacer(Modifier.width(FlareSizes.spacing2sm))
                        Avatar(userId = tgt.id, displayName = tgt.name, size = 38.dp)
                        Spacer(Modifier.width(FlareSizes.spacing2sm))
                        Column(Modifier.weight(1f)) {
                            Text(tgt.name, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp,
                                maxLines = 1, overflow = TextOverflow.Ellipsis)
                            tgt.subtitle?.let {
                                Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                                    maxLines = 1, overflow = TextOverflow.Ellipsis)
                            }
                        }
                    }
                }
                if (filtered.isEmpty()) {
                    Text(flareStrings().noMatchingConversations, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                        modifier = Modifier.fillMaxWidth().padding(FlareSizes.spacing2xl), textAlign = androidx.compose.ui.text.style.TextAlign.Center)
                }
            }
            error?.let {
                Text(it, color = colors.errorText, fontSize = FlareSizes.fontSizeSm.value.sp,
                    modifier = Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingXs))
            }
            Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
            if (cancelLabel != null) Row(
                Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd),
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing2sm),
            ) {
                Box(Modifier.weight(1f)) {
                    Button(label = cancelLabel, variant = FlareButtonVariant.Secondary, disabled = busy, block = true, onClick = { onClose?.invoke() })
                }
                Box(Modifier.weight(1f)) {
                    Button(
                        label = confirmLabel ?: flareStrings().send, disabled = selected.isEmpty(), loading = busy, block = true,
                        onClick = { if (!busy) onConfirm?.invoke(selected.toList()) },
                    )
                }
            } else Row(
                Modifier.fillMaxWidth().padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = FlareSizes.spacing2sm, bottom = FlareSizes.spacing2md),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(flareStrings().selectedCount(selected.size), color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd.value.sp)
                Spacer(Modifier.weight(1f))
                val enabled = selected.isNotEmpty() && !busy
                Box(
                    Modifier.height(36.dp).clip(RoundedCornerShape(FlareSizes.radiusLg))
                        .background(
                            if (enabled) Brush.linearGradient(listOf(colors.primary, colors.primaryActive))
                            else Brush.linearGradient(listOf(colors.bgSecondary, colors.bgSecondary)),
                        )
                        .then(if (enabled) Modifier.clickable { onConfirm?.invoke(selected.toList()) } else Modifier)
                        .padding(horizontal = FlareSizes.spacingXl),
                    contentAlignment = Alignment.Center,
                ) {
                    if (busy) androidx.compose.material3.CircularProgressIndicator(Modifier.size(18.dp), color = colors.primaryText, strokeWidth = 2.dp)
                    else Text(flareStrings().send, color = if (enabled) Color.White else colors.textTertiary,
                        fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeMd.value.sp)
                }
            }
        }
    }
}
