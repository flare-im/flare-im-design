package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Cancel
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.sp

/**
 * General text input — single/multi-line, char limit, clearable, disabled.
 * Spec: General/Input (`Input`).
 */
@Composable
fun Input(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String? = null,
    multiline: Boolean = false,
    maxLength: Int? = null,
    disabled: Boolean = false,
    clearable: Boolean = false,
    onSubmit: (() -> Unit)? = null,
) {
    val colors = flareColors()
    Column(Modifier.fillMaxWidth()) {
        TextField(
            value = value,
            onValueChange = { if (maxLength == null || it.length <= maxLength) onValueChange(it) },
            enabled = !disabled,
            singleLine = !multiline,
            maxLines = if (multiline) 6 else 1,
            placeholder = placeholder?.let { { Text(it, color = colors.textTertiary) } },
            trailingIcon = if (clearable && value.isNotEmpty()) {
                { IconButton(onClick = { onValueChange("") }) { Icon(Icons.Outlined.Cancel, "清除", tint = colors.textTertiary) } }
            } else null,
            keyboardOptions = KeyboardOptions(imeAction = if (multiline) ImeAction.Default else ImeAction.Done),
            keyboardActions = KeyboardActions(onDone = { onSubmit?.invoke() }),
            colors = TextFieldDefaults.colors(
                focusedContainerColor = colors.bgSecondary,
                unfocusedContainerColor = colors.bgSecondary,
                focusedIndicatorColor = colors.primary,
                unfocusedIndicatorColor = Color.Transparent,
            ),
            modifier = Modifier.fillMaxWidth(),
        )
        if (maxLength != null) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                Text(
                    "${value.length}/$maxLength",
                    fontSize = FlareSizes.fontSizeXs.value.sp,
                    color = if (value.length >= maxLength) colors.error else colors.textTertiary,
                )
            }
        }
    }
}
