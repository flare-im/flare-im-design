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
import androidx.compose.material.icons.outlined.MicNone
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** One semantic attachment/action tile shared by the composer and its sheet. */
data class FlareComposerAction(
    val id: String,
    val label: String,
    /** A semantic icon name from the registry (`docs/ICON-LIBRARY.md`), not a platform glyph. */
    val icon: String,
    val group: String? = null,
    val order: Int? = null,
    val visible: Boolean = true,
    val enabled: Boolean = true,
    val badge: String? = null,
    val intent: String? = null,
    val accessibilityLabel: String? = null,
    val disabledReason: String? = null,
)

data class FlareComposerCapabilities(val availableActionIds: Set<String>? = null)

/** Ids of the default action set shared across the four platforms. */
val defaultComposerActionIds: List<String> =
    listOf("image", "file", "voice", "location", "contact")

/**
 * Default attachment actions with labels taken from [strings] (the same
 * `actionImage`/`actionCamera`/… keys as iOS `FlareStrings`). Pure — usable from
 * tests and non-composable code; composables should call [defaultComposerActions].
 */
fun defaultComposerActions(strings: FlareStrings): List<FlareComposerAction> = listOf(
    FlareComposerAction("image", strings.actionImage, "image"),
    FlareComposerAction("file", strings.actionFile, "file"),
    FlareComposerAction("voice", strings.composerVoice, "mic"),
    FlareComposerAction("location", strings.actionLocation, "location"),
    FlareComposerAction("contact", strings.actionCard, "card"),
)

/** Defaults -> capabilities -> host list. A host list is a full replacement. */
fun resolveComposerActions(
    defaults: List<FlareComposerAction>,
    capabilities: FlareComposerCapabilities = FlareComposerCapabilities(),
    actions: List<FlareComposerAction>? = null,
): List<FlareComposerAction> {
    val seen = mutableSetOf<String>()
    return (actions ?: defaults).withIndex()
        .filter { (_, action) ->
            action.visible && action.id.isNotBlank() && seen.add(action.id) &&
                (capabilities.availableActionIds?.contains(action.id) ?: true)
        }
        .sortedWith(compareBy<IndexedValue<FlareComposerAction>> { it.value.order ?: it.index }.thenBy { it.index })
        .map { it.value }
}

/** Default attachment actions labelled from the current [LocalFlareStrings]. */
@Composable
@ReadOnlyComposable
fun defaultComposerActions(): List<FlareComposerAction> = defaultComposerActions(flareStrings())
