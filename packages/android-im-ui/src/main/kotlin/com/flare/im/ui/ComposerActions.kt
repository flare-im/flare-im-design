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

/**
 * Where a "+" panel tile comes from: a built-in feature the tenant's feature switches govern, or an entry an
 * authorized plugin declares (a `composer-action` contribution).
 */
enum class FlareComposerActionKind { Feature, Plugin }

/** One semantic attachment/action tile shared by the composer and its sheet. */
data class FlareComposerAction(
    val id: String,
    /** The host's label. Null takes the kit's copy for a built-in id ([resolvedLabel]), so a host passing the built-in items through never writes their text. */
    val label: String? = null,
    /**
     * A semantic icon name from the registry (`docs/ICON-LIBRARY.md`), not a platform glyph. A name the registry does
     * not know draws the generic `plugin` glyph ([resolvedIcon]).
     */
    val icon: String,
    val group: String? = null,
    val order: Int? = null,
    val visible: Boolean = true,
    val enabled: Boolean = true,
    val badge: String? = null,
    val intent: String? = null,
    val accessibilityLabel: String? = null,
    val disabledReason: String? = null,
    /** Built-in feature or plugin entry; null for a host's own tile. */
    val kind: FlareComposerActionKind? = null,
) {
    /** The label the tile shows: the host's, else the kit's copy for a built-in id, else the id itself so a tile never renders blank. */
    fun resolvedLabel(strings: FlareStrings): String = label ?: composerActionKitLabel(id, strings) ?: id

    /**
     * The icon the tile draws: its own name, or for a name not in the registry (a plugin's old manifest, a name from a
     * newer kit or menu) the generic `plugin` glyph — a tile never draws the unknown-name question mark.
     */
    val resolvedIcon: String
        get() = if (flareIconVectorOrNull(icon) == null) "plugin" else icon
}

/** The kit's copy for the ids the panel knows, the eight built-in items first (`composerActions`). */
internal fun composerActionKitLabel(id: String, strings: FlareStrings): String? = when (id) {
    "image" -> strings.actionImage
    "camera" -> strings.actionCamera
    "video" -> strings.actionVideo
    "file" -> strings.actionFile
    "voice" -> strings.composerVoice
    "location" -> strings.actionLocation
    "card", "contact" -> strings.actionCard
    "poll", "vote" -> strings.actionVote
    "task" -> strings.actionTask
    "schedule", "event" -> strings.actionSchedule
    else -> null
}

/**
 * Business availability supplied by the host. Host-owned presentation, not an authorization decision: the server still
 * decides what may be sent.
 */
data class FlareComposerCapabilities(
    /** The "+" panel ids to keep; null keeps every tile. */
    val availableActionIds: Set<String>? = null,
    /** The toolbar keys to offer: `emoji`, `mention`, `voice`, `image`, `richText` and `attachments` (the "+" key). Null offers every key. */
    val availableToolIds: Set<String>? = null,
) {
    /** Whether the toolbar offers the key [id]. */
    fun allowsTool(id: String): Boolean = availableToolIds?.contains(id) ?: true
}

/** Ids of the built-in feature set, in panel order, shared across the four platforms (`composerActions.defaults`). */
val defaultComposerActionIds: List<String> =
    listOf("image", "camera", "video", "file", "voice", "location", "card")

/**
 * Default attachment actions with labels taken from [strings] (the same
 * `actionImage`/`actionVideo`/… keys as iOS `FlareStrings`). Pure — usable from
 * tests and non-composable code; composables should call [defaultComposerActions].
 */
fun defaultComposerActions(strings: FlareStrings): List<FlareComposerAction> = listOf(
    FlareComposerAction("image", strings.actionImage, "image", kind = FlareComposerActionKind.Feature),
    FlareComposerAction("camera", strings.actionCamera, "camera", kind = FlareComposerActionKind.Feature),
    FlareComposerAction("video", strings.actionVideo, "video", kind = FlareComposerActionKind.Feature),
    FlareComposerAction("file", strings.actionFile, "file", kind = FlareComposerActionKind.Feature),
    FlareComposerAction("voice", strings.composerVoice, "mic", kind = FlareComposerActionKind.Feature),
    FlareComposerAction("location", strings.actionLocation, "location", kind = FlareComposerActionKind.Feature),
    FlareComposerAction("card", strings.actionCard, "card", kind = FlareComposerActionKind.Feature),
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
