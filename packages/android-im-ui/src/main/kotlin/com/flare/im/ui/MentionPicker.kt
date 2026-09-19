package com.flare.im.ui

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.relocation.BringIntoViewRequester
import androidx.compose.foundation.relocation.bringIntoViewRequester
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.People
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** The id of the everyone row a [MentionPicker] offers when everyone may be mentioned. */
internal const val FLARE_MENTION_EVERYONE_ID = "__all__"

/**
 * The picker's rows for [query] (Vue `results`): the everyone row first when [allowEveryone], then the
 * candidates, keeping those whose name or detail contains the query (case-insensitive).
 */
internal fun mentionPickerResults(
    candidates: List<MentionCandidate>,
    allowEveryone: Boolean,
    everyoneName: String,
    query: String,
): List<MentionCandidate> {
    val all = if (allowEveryone) listOf(MentionCandidate(FLARE_MENTION_EVERYONE_ID, everyoneName, isEveryone = true)) + candidates else candidates
    val q = query.trim().lowercase()
    if (q.isEmpty()) return all
    return all.filter { "${it.name} ${it.detail.orEmpty()}".lowercase().contains(q) }
}

/** A hardware key the picker's search field acts on. */
internal enum class MentionPickerInput { Down, Up, Enter, Escape }

/** What a key does in the picker's search field. */
internal sealed interface MentionPickerAction {
    data class Highlight(val index: Int) : MentionPickerAction
    data class Pick(val index: Int) : MentionPickerAction
    data object Close : MentionPickerAction
}

/**
 * The combobox keys (Vue `FlareMentionPicker`): Escape closes; the arrows move the highlight over the [count]
 * rows and wrap; Enter picks the highlighted row. While an input method is [composing], its Enter confirms the
 * typed letters, not a person, so only Escape acts. Null when the key does nothing.
 */
internal fun mentionPickerAction(input: MentionPickerInput, composing: Boolean, count: Int, active: Int): MentionPickerAction? = when {
    input == MentionPickerInput.Escape -> MentionPickerAction.Close
    composing || count == 0 -> null
    input == MentionPickerInput.Down -> MentionPickerAction.Highlight((active + 1).mod(count))
    input == MentionPickerInput.Up -> MentionPickerAction.Highlight((active - 1).mod(count))
    else -> MentionPickerAction.Pick(active.coerceIn(0, count - 1))
}

/**
 * @-mention candidate picker with search. Spec: Composer/MentionPicker.
 *
 * With a hardware keyboard it is a combobox: focus stays in the search field, the first match is
 * highlighted, the arrow keys move the highlight, Enter picks it (not the Enter that commits an input
 * method's composition) and Escape runs [onClose]. A tap picks the row tapped.
 *
 * [framed] draws the floating card; unframed, the picker fills the sheet or panel it sits in. [autofocus]
 * focuses the search field when the picker appears, as when the composer opens it.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun MentionPicker(
    candidates: List<MentionCandidate>,
    allowEveryone: Boolean = false,
    onSelect: ((MentionCandidate) -> Unit)? = null,
    onClose: (() -> Unit)? = null,
    framed: Boolean = true,
    autofocus: Boolean = false,
) {
    val colors = flareColors()
    val strings = flareStrings()
    var query by remember { mutableStateOf(TextFieldValue("")) }
    val results = remember(candidates, allowEveryone, strings.everyone, query.text) {
        mentionPickerResults(candidates, allowEveryone, strings.everyone, query.text)
    }
    // The first match is highlighted again whenever the matches change.
    var active by remember(results) { mutableIntStateOf(0) }
    val focus = remember { FocusRequester() }
    if (autofocus) LaunchedEffect(Unit) { runCatching { focus.requestFocus() } }
    val shape = RoundedCornerShape(FlareSizes.radiusXl)
    Column(
        if (framed) Modifier.width(280.dp).clip(shape).background(colors.bgPrimary).border(1.dp, colors.borderPrimary, shape)
        else Modifier.fillMaxWidth(),
    ) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Outlined.Search, contentDescription = null, tint = colors.textTertiary, modifier = Modifier.size(FlareSizes.iconSizeSm))
            Spacer(Modifier.width(FlareSizes.spacingSm))
            Box(Modifier.weight(1f)) {
                if (query.text.isEmpty()) {
                    // The field carries the name; the placeholder is not read twice.
                    Text(strings.searchMembers, color = colors.textTertiary, fontSize = FlareSizes.fontSizeLg.value.sp, modifier = Modifier.clearAndSetSemantics {})
                }
                BasicTextField(
                    value = query,
                    onValueChange = { query = it },
                    singleLine = true,
                    textStyle = TextStyle(color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp),
                    cursorBrush = SolidColor(colors.primary),
                    modifier = Modifier.fillMaxWidth()
                        .focusRequester(focus)
                        .semantics { contentDescription = strings.searchMembers }
                        .onPreviewKeyEvent { event ->
                            if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
                            val input = when (event.key) {
                                Key.DirectionDown -> MentionPickerInput.Down
                                Key.DirectionUp -> MentionPickerInput.Up
                                Key.Enter, Key.NumPadEnter -> MentionPickerInput.Enter
                                Key.Escape -> MentionPickerInput.Escape
                                else -> return@onPreviewKeyEvent false
                            }
                            when (val action = mentionPickerAction(input, query.composition != null, results.size, active)) {
                                is MentionPickerAction.Highlight -> { active = action.index; true }
                                is MentionPickerAction.Pick -> { onSelect?.invoke(results[action.index]); onSelect != null }
                                MentionPickerAction.Close -> { onClose?.invoke(); onClose != null }
                                null -> false
                            }
                        },
                )
            }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderPrimary))
        Column(Modifier.fillMaxWidth().heightIn(max = 264.dp).verticalScroll(rememberScrollState())) {
            results.forEachIndexed { index, candidate ->
                val highlighted = index == active
                val reveal = remember { BringIntoViewRequester() }
                if (highlighted) LaunchedEffect(index) { runCatching { reveal.bringIntoView() } }
                Row(
                    Modifier.fillMaxWidth()
                        .bringIntoViewRequester(reveal)
                        .background(if (highlighted) colors.bgSelected else Color.Transparent)
                        .then(if (onSelect != null) Modifier.clickable { onSelect(candidate) } else Modifier)
                        .semantics { selected = highlighted }
                        .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    if (candidate.isEveryone) {
                        Box(
                            Modifier.size(FlareSizes.iconSizeXl).clip(CircleShape).background(colors.primary),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(Icons.Outlined.People, contentDescription = null, tint = Color.White, modifier = Modifier.size(18.dp))
                        }
                    } else {
                        Avatar(userId = candidate.id, displayName = candidate.name, avatarUrl = candidate.avatarUrl, size = FlareSizes.iconSizeXl)
                    }
                    Spacer(Modifier.width(FlareSizes.spacingMd))
                    Column {
                        Text(candidate.name, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp,
                            maxLines = 1, overflow = TextOverflow.Ellipsis)
                        val detail = if (candidate.isEveryone) strings.notifyEveryone else candidate.detail
                        if (!detail.isNullOrEmpty()) {
                            Text(detail, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm.value.sp,
                                maxLines = 1, overflow = TextOverflow.Ellipsis)
                        }
                    }
                }
            }
            if (results.isEmpty()) {
                Text(
                    strings.noMatchingMembers,
                    color = colors.textTertiary,
                    fontSize = FlareSizes.fontSizeSm.value.sp,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacing2xl),
                )
            }
        }
    }
}
