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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** One attachment/action tile in [MessageActionSheet]. */
data class FlareComposerAction(val id: String, val label: String, val icon: ImageVector)

/** Default attachment actions. */
val defaultComposerActions: List<FlareComposerAction> = listOf(
    FlareComposerAction("image", "Image", Icons.Outlined.Image),
    FlareComposerAction("camera", "Camera", Icons.Outlined.CameraAlt),
    FlareComposerAction("file", "File", Icons.Outlined.Folder),
    FlareComposerAction("location", "Location", Icons.Outlined.LocationOn),
    FlareComposerAction("card", "Contact", Icons.Outlined.ContactPage),
    FlareComposerAction("vote", "Poll", Icons.Outlined.HowToVote),
    FlareComposerAction("task", "Task", Icons.Outlined.Checklist),
    FlareComposerAction("schedule", "Schedule", Icons.Outlined.CalendarMonth),
)

/**
 * The attachment "+" action grid — image, file, card, vote, location, etc. Spec:
 * Composer/MessageActionSheet (`MessageActionSheet`). Emits the chosen action;
 * the host builds the content message.
 */
@Composable
fun MessageActionSheet(
    actions: List<FlareComposerAction> = defaultComposerActions,
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
