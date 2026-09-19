package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Display group of a [FlareMessageMenuEntry]; groups render in this order. */
enum class FlareMessageMenuGroup { Primary, Organize, Destructive }

/** One action of the message long-press sheet; [id] is the stable action id. */
data class FlareMessageMenuEntry(
    val id: String,
    val label: String,
    /** A semantic icon name from the registry (`docs/ICON-LIBRARY.md`), not a platform glyph. */
    val icon: String,
    val group: FlareMessageMenuGroup = FlareMessageMenuGroup.Organize,
    val enabled: Boolean = true,
)

/** Entries grouped in display order (primary, organize, destructive); empty groups are dropped. */
fun messageMenuGroups(entries: List<FlareMessageMenuEntry>): List<List<FlareMessageMenuEntry>> =
    FlareMessageMenuGroup.values().map { group -> entries.filter { it.group == group } }.filter { it.isNotEmpty() }

/**
 * What can be done with one message right now: the `can*` flags of the core's action availability
 * (`domain::message_actions`), under the core's names. The host asks the core and hands the answer
 * to [MessageActionSheet], which turns it into the standard actions.
 */
data class FlareMessageActionAvailability(
    val canReply: Boolean = false,
    val canForward: Boolean = false,
    val canCopy: Boolean = false,
    val canEdit: Boolean = false,
    val canDelete: Boolean = false,
    val canRecall: Boolean = false,
    val canPin: Boolean = false,
    val canUnpin: Boolean = false,
    val canReact: Boolean = false,
    val canMultiSelect: Boolean = false,
    val canSave: Boolean = false,
    val canResend: Boolean = false,
) {
    companion object {
        /** The core's answer as the SDK returns it (camelCase JSON); a flag that is not `true` is off. */
        fun fromJson(json: Map<String, Any?>) = FlareMessageActionAvailability(
            canReply = json["canReply"] == true,
            canForward = json["canForward"] == true,
            canCopy = json["canCopy"] == true,
            canEdit = json["canEdit"] == true,
            canDelete = json["canDelete"] == true,
            canRecall = json["canRecall"] == true,
            canPin = json["canPin"] == true,
            canUnpin = json["canUnpin"] == true,
            canReact = json["canReact"] == true,
            canMultiSelect = json["canMultiSelect"] == true,
            canSave = json["canSave"] == true,
            canResend = json["canResend"] == true,
        )
    }
}

/** Quick reactions the sheet offers when the host passes none; the same set on every platform. */
val flareQuickReactions: List<String> = listOf("👍", "❤️", "😂", "😮", "😢", "🎉")

/**
 * The text Copy puts on the clipboard for a message's [content], or null when there is none: the text of a
 * text body, or the core's plain text of a rich-text body (quotes reach the kit as their text). Images, voice,
 * video, files, cards and every other body have nothing to copy, even though the core's `canCopy` allows them
 * (it counts their preview token as text).
 */
fun flareMessageCopyText(content: FlareMessageContent?): String? = when (content) {
    is FlareTextContent -> content.text
    is FlareRichTextContent -> content.plainText
    else -> null
}?.takeIf { it.isNotBlank() }

/**
 * The standard actions [availability] allows, in the order every platform shows them: reply,
 * forward, recall and resend as quick actions; multi-select, mark, pin, pin for me, unpin, copy,
 * preview, save and edit as the list; delete last. Mark and delete share `canDelete`, pin and
 * pin-for-me share `canPin`, multi-select and preview share `canMultiSelect`. Copy also needs text to
 * copy in the message's [content] ([flareMessageCopyText]), so an unknown content offers none. Ids in
 * [hidden] (actions the host does not implement) are left out.
 */
fun messageMenuActions(
    availability: FlareMessageActionAvailability,
    strings: FlareStrings,
    hidden: Set<String> = emptySet(),
    content: FlareMessageContent? = null,
): List<FlareMessageMenuEntry> = buildList {
    val a = availability
    fun offer(allowed: Boolean, id: String, label: String, icon: String, group: FlareMessageMenuGroup = FlareMessageMenuGroup.Organize) {
        if (allowed && id !in hidden) add(FlareMessageMenuEntry(id, label, icon, group))
    }
    offer(a.canReply, "reply", strings.messageActionReply, "reply", FlareMessageMenuGroup.Primary)
    offer(a.canForward, "forward", strings.messageActionForward, "forward", FlareMessageMenuGroup.Primary)
    offer(a.canRecall, "recall", strings.messageActionRecall, "recall", FlareMessageMenuGroup.Primary)
    offer(a.canResend, "resend", strings.messageActionResend, "refresh", FlareMessageMenuGroup.Primary)
    offer(a.canMultiSelect, "multiSelect", strings.messageActionMultiSelect, "multi-select")
    offer(a.canDelete, "mark", strings.messageActionMark, "mark")
    offer(a.canPin, "pin", strings.messageActionPin, "pin")
    // A pin for this reader only: its own name, so it never shares the pin's glyph in one sheet.
    offer(a.canPin, "pinSelf", strings.messageActionPinSelf, "pin-self")
    offer(a.canUnpin, "unpin", strings.messageActionUnpin, "unpin")
    offer(a.canCopy && flareMessageCopyText(content) != null, "copy", strings.messageActionCopy, "copy")
    offer(a.canMultiSelect, "preview", strings.messageActionPreview, "eye")
    offer(a.canSave, "save", strings.messageActionSave, "download")
    offer(a.canEdit, "edit", strings.messageActionEdit, "edit")
    offer(a.canDelete, "delete", strings.messageActionDelete, "delete", FlareMessageMenuGroup.Destructive)
}

/**
 * The message long-press action sheet — a reaction strip plus grouped actions
 * (primary / organize / destructive, destructive in red). Spec:
 * Message/MessageActionSheet (`MessageActionSheet`). The host passes the core's
 * [availability] and the message's [content] and gets the standard actions (see [messageMenuActions]; Copy
 * only when [content] has text to copy), leaves out the ones it does not implement with [hiddenActions], and
 * appends its own [actions] to their groups. [reactions] defaults to [flareQuickReactions] when the message can
 * take one (a host list is gated by `canReact` too). Dispatches [onAction] with the action id and [onReact] with the emoji;
 * owns no positioning — present it in [BottomSheet], where it draws on the sheet's surface.
 */
@Composable
fun MessageActionSheet(
    availability: FlareMessageActionAvailability = FlareMessageActionAvailability(),
    /** The message's content; Copy is offered only when it has text to copy ([flareMessageCopyText]). */
    content: FlareMessageContent? = null,
    hiddenActions: Set<String> = emptySet(),
    actions: List<FlareMessageMenuEntry> = emptyList(),
    reactions: List<String>? = null,
    label: String? = null,
    emptyText: String? = null,
    onAction: ((String) -> Unit)? = null,
    onReact: ((String) -> Unit)? = null,
) {
    val strings = flareStrings()
    val colors = flareColors()
    val sheetLabel = label ?: strings.messageActionSheetLabel
    val empty = emptyText ?: strings.messageActionSheetEmpty
    val groups = messageMenuGroups(messageMenuActions(availability, strings, hiddenActions, content) + actions)
    val strip = if (availability.canReact) reactions ?: flareQuickReactions else emptyList()
    // In a BottomSheet the sheet supplies the surface and the top spacing above the handle.
    val inSheet = LocalFlareBottomSheet.current
    Column(
        Modifier.fillMaxWidth()
            .then(
                if (inSheet) Modifier
                else Modifier.background(colors.bgSecondary, RoundedCornerShape(topStart = FlareSizes.radiusXl, topEnd = FlareSizes.radiusXl)),
            )
            .padding(
                start = FlareSizes.spacingMd,
                top = if (inSheet) FlareSizes.spacingSm else FlareSizes.spacingLg,
                end = FlareSizes.spacingMd,
                bottom = FlareSizes.spacingMd,
            )
            .semantics { contentDescription = sheetLabel },
    ) {
        if (strip.isNotEmpty()) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                strip.forEach { reaction ->
                    Box(
                        Modifier.size(FlareSizes.touchTarget).clip(RoundedCornerShape(FlareSizes.radiusFull))
                            .clickable(enabled = onReact != null) { onReact?.invoke(reaction) }
                            .semantics { contentDescription = reaction },
                        contentAlignment = Alignment.Center,
                    ) { Text(reaction, fontSize = FlareSizes.iconSizeLg.value.sp) }
                }
            }
            Spacer(Modifier.height(FlareSizes.spacingMd))
        }
        if (groups.isEmpty() && strip.isEmpty()) {
            Text(
                empty,
                Modifier.fillMaxWidth().padding(FlareSizes.spacingLg),
                color = colors.textSecondary,
                textAlign = TextAlign.Center,
            )
        }
        groups.forEachIndexed { index, entries ->
            if (index > 0) Spacer(Modifier.height(FlareSizes.spacingSm))
            Column(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusLg))
                    .background(colors.bgPrimary)
                    .border(1.dp, colors.borderPrimary, RoundedCornerShape(FlareSizes.radiusLg)),
            ) {
                entries.forEachIndexed { rowIndex, entry ->
                    if (rowIndex > 0) HorizontalDivider(color = colors.borderSecondary)
                    val destructive = entry.group == FlareMessageMenuGroup.Destructive
                    val foreground = when {
                        !entry.enabled -> colors.textTertiary
                        destructive -> colors.error
                        else -> colors.textPrimary
                    }
                    Row(
                        Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget)
                            .clickable(enabled = entry.enabled && onAction != null) { onAction?.invoke(entry.id) }
                            .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        FlareIcon(name = entry.icon, size = FlareSizes.iconSizeMd, tint = foreground)
                        Spacer(Modifier.width(FlareSizes.spacingMd))
                        Text(entry.label, color = foreground, fontSize = FlareSizes.fontSizeXl.value.sp)
                    }
                }
            }
        }
    }
}
