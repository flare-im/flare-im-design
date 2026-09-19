package com.flare.im.ui

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
import androidx.compose.material.icons.outlined.Cancel
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
) {
    val strings = flareStrings()
    val placeholder = placeholder ?: strings.search
    val colors = flareColors()
    val activate = onActivate?.takeIf { readOnly }
    Row(
        Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget).clip(RoundedCornerShape(FlareSizes.radiusLg)).background(colors.bgSecondary)
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
            .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
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
                    keyboardActions = KeyboardActions(onSearch = { onSubmit?.invoke() }),
                    modifier = Modifier.fillMaxWidth().semantics { contentDescription = placeholder },
                )
            }
        }
        if (loading) {
            CircularProgressIndicator(Modifier.size(FlareSizes.iconSizeSm), strokeWidth = 2.dp, color = colors.textTertiary)
        } else if (value.isNotEmpty() && !readOnly) {
            IconButton(onClick = { onValueChange("") }, modifier = Modifier.size(FlareSizes.touchTarget)) {
                Icon(Icons.Outlined.Cancel, strings.clear, Modifier.size(18.dp), tint = colors.textTertiary)
            }
        }
    }
}
