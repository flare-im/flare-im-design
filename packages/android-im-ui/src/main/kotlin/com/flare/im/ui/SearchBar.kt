package com.flare.im.ui

import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.getValue
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.waitForUpOrCancellation
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.heightIn
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics

internal class SearchTapRegion {
    var coordinates: LayoutCoordinates? = null
}

internal class SearchTapScope {
    var active: SearchTapRegion? = null
}

internal val LocalSearchTapScope = compositionLocalOf<SearchTapScope?> { null }

/** Observes an outside tap before child controls receive it, without consuming the gesture. */
@Composable
internal fun Modifier.dismissSearchOnOutsideTap(scope: SearchTapScope, dismiss: () -> Unit): Modifier {
    val root = remember { SearchTapRegion() }
    return onGloballyPositioned { root.coordinates = it }.pointerInput(scope) {
        awaitEachGesture {
            val down = awaitFirstDown(requireUnconsumed = false, pass = PointerEventPass.Initial)
            val search = scope.active ?: return@awaitEachGesture
            val container = root.coordinates?.takeIf { it.isAttached } ?: return@awaitEachGesture
            val coordinates = search.coordinates?.takeIf { it.isAttached } ?: return@awaitEachGesture
            if (coordinates.boundsInRoot().contains(container.localToRoot(down.position))) return@awaitEachGesture
            val up = waitForUpOrCancellation(PointerEventPass.Initial) ?: return@awaitEachGesture
            if (scope.active === search && container.isAttached && coordinates.isAttached &&
                !coordinates.boundsInRoot().contains(container.localToRoot(up.position))
            ) dismiss()
        }
    }
}

/**
 * Unified search field — the entry to conversation/contact/message search, with
 * clear and submit. Spec: General/SearchBar (`SearchBar`).
 *
 * [readOnly] keeps the look (icon plus value or placeholder) without a text field:
 * no caret, no focus as an input, no clear button. With [onActivate] the whole bar is
 * then one button named by the placeholder — tap, Enter or Space opens the real search;
 * without it the bar only displays.
 */
@Suppress("NAME_SHADOWING")
@Composable
fun SearchBar(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String? = null,
    loading: Boolean = false,
    onSubmit: (() -> Unit)? = null,
    readOnly: Boolean = false,
    onActivate: (() -> Unit)? = null,
    /** Vue's `appearance="quiet"`: no fill and no rounded corners — a search that heads a list. */
    quiet: Boolean = false,
    dismissesKeyboardOnOutsideTap: Boolean = false,
) {
    val strings = flareStrings()
    val placeholder = placeholder ?: strings.search
    val colors = flareColors()
    val activate = onActivate?.takeIf { readOnly }
    // A focused field draws its own edge in the selected border colour, as Vue's `:focus-within`.
    var focused by remember { mutableStateOf(false) }
    val tapScope = LocalSearchTapScope.current.takeIf { dismissesKeyboardOnOutsideTap && !readOnly }
    val tapRegion = remember { SearchTapRegion() }
    val focus = LocalFocusManager.current
    DisposableEffect(tapScope) {
        onDispose { if (tapScope != null && tapScope.active === tapRegion) tapScope.active = null }
    }
    val shape = if (quiet) RectangleShape else RoundedCornerShape(FlareSizes.radiusLg)
    Row(
        Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget)
            .then(if (tapScope == null) Modifier else Modifier.onGloballyPositioned { tapRegion.coordinates = it })
            .clip(shape).background(if (quiet) Color.Transparent else colors.bgSecondary)
            .border(1.dp, if (focused) colors.borderSelected else Color.Transparent, shape)
            .then(
                if (activate == null) Modifier
                else Modifier
                    .onKeyEvent { event ->
                        // Clickable answers Enter; a button answers Space as well.
                        if (event.key != Key.Spacebar) return@onKeyEvent false
                        if (event.type == KeyEventType.KeyUp) activate()
                        true
                    }
                    .clickable(role = Role.Button) { activate() }
                    .semantics { contentDescription = placeholder },
            )
            // Touch-target tall, the clear key inside that height (the web's 48), not padded below it.
            .padding(horizontal = if (quiet) FlareSizes.spacingSm else FlareSizes.spacingMd),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(Icons.Rounded.Search, null, Modifier.size(FlareSizes.iconSizeMd), tint = colors.textTertiary)
        Spacer(Modifier.width(FlareSizes.spacingSm))
        Box(Modifier.weight(1f), contentAlignment = Alignment.CenterStart) {
            if (readOnly) {
                Text(
                    value.ifEmpty { placeholder },
                    color = if (value.isEmpty()) colors.textTertiary else colors.textPrimary,
                    fontSize = FlareSizes.fontSizeLg.value.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            } else {
                if (value.isEmpty()) {
                    Text(placeholder, color = colors.textTertiary, fontSize = FlareSizes.fontSizeLg.value.sp)
                }
                BasicTextField(
                    value = value,
                    onValueChange = onValueChange,
                    singleLine = true,
                    textStyle = TextStyle(color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp),
                    cursorBrush = SolidColor(colors.primary),
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                    keyboardActions = KeyboardActions(onSearch = {
                        if (dismissesKeyboardOnOutsideTap) focus.clearFocus()
                        onSubmit?.invoke()
                    }),
                    modifier = Modifier.fillMaxWidth().onFocusChanged {
                        focused = it.isFocused
                        if (tapScope != null) {
                            if (focused) tapScope.active = tapRegion
                            else if (tapScope.active === tapRegion) tapScope.active = null
                        }
                    }.semantics { contentDescription = placeholder },
                )
            }
        }
        if (loading) {
            CircularProgressIndicator(Modifier.size(FlareSizes.iconSizeSm), strokeWidth = 2.dp, color = colors.textTertiary)
        } else if (value.isNotEmpty() && !readOnly) {
            IconButton(onClick = { onValueChange("") }, modifier = Modifier.size(FlareSizes.touchTarget)) {
                FlareIcon("close", size = 18.dp, tint = colors.textTertiary, contentDescription = strings.clear)
            }
        }
    }
}
