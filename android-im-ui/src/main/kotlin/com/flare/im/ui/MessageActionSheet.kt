package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.CameraAlt
import androidx.compose.material.icons.outlined.Checklist
import androidx.compose.material.icons.outlined.ContactPage
import androidx.compose.material.icons.outlined.Folder
import androidx.compose.material.icons.outlined.HowToVote
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** One attachment/action tile in [MessageActionSheet]. */
data class FlareComposerAction(val id: String, val label: String, val icon: ImageVector)

/** Ids of the core default action set — one table across the four platforms. */
val defaultComposerActionIds: List<String> =
    listOf("image", "camera", "file", "location", "card", "vote", "task", "schedule")

/**
 * Default attachment actions with labels taken from [strings] (the same
 * `actionImage`/`actionCamera`/… keys as iOS `FlareStrings`). Pure — usable from
 * tests and non-composable code; composables should call [defaultComposerActions].
 */
fun defaultComposerActions(strings: FlareStrings): List<FlareComposerAction> = listOf(
    FlareComposerAction("image", strings.actionImage, Icons.Outlined.Image),
    FlareComposerAction("camera", strings.actionCamera, Icons.Outlined.CameraAlt),
    FlareComposerAction("file", strings.actionFile, Icons.Outlined.Folder),
    FlareComposerAction("location", strings.actionLocation, Icons.Outlined.LocationOn),
    FlareComposerAction("card", strings.actionCard, Icons.Outlined.ContactPage),
    FlareComposerAction("vote", strings.actionVote, Icons.Outlined.HowToVote),
    FlareComposerAction("task", strings.actionTask, Icons.Outlined.Checklist),
    FlareComposerAction("schedule", strings.actionSchedule, Icons.Outlined.CalendarMonth),
)

/** Default attachment actions labelled from the current [LocalFlareStrings]. */
@Composable
@ReadOnlyComposable
fun defaultComposerActions(): List<FlareComposerAction> = defaultComposerActions(flareStrings())

/**
 * Default attachment actions with the built-in (zh) labels, ignoring the
 * host's strings provider. Kept for source compatibility only.
 */
@Deprecated(
    "Labels bypass LocalFlareStrings; call defaultComposerActions() inside a composable " +
        "or defaultComposerActions(strings) elsewhere.",
    ReplaceWith("defaultComposerActions()"),
)
val defaultComposerActions: List<FlareComposerAction>
    get() = defaultComposerActions(FlareStrings())

/**
 * The attachment "+" action grid — image, file, card, vote, location, etc. Spec:
 * Composer/MessageActionSheet (`MessageActionSheet`). Emits the chosen action;
 * the host builds the content message.
 */
@Composable
fun MessageActionSheet(
    actions: List<FlareComposerAction> = defaultComposerActions(),
    onAction: ((FlareComposerAction) -> Unit)? = null,
) {
    val colors = flareColors()
    Column(Modifier.fillMaxWidth().background(colors.bgPrimary).padding(FlareSizes.spacingLg)) {
        actions.chunked(4).forEach { rowActions ->
            Row(Modifier.fillMaxWidth().padding(bottom = FlareSizes.spacingLg), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg)) {
                rowActions.forEach { action ->
                    Column(
                        Modifier.weight(1f).clickable { onAction?.invoke(action) },
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Box(
                            Modifier.size(52.dp).clip(RoundedCornerShape(FlareSizes.radiusLg)).background(colors.bgSecondary),
                            contentAlignment = Alignment.Center,
                        ) { Icon(action.icon, null, Modifier.size(24.dp), tint = colors.textPrimary) }
                        Spacer(Modifier.size(FlareSizes.spacingXs))
                        Text(action.label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeXs.value.sp)
                    }
                }
                repeat(4 - rowActions.size) { Spacer(Modifier.weight(1f)) }
            }
        }
    }
}
