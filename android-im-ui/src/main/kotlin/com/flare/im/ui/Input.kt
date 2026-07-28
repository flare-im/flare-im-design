package com.flare.im.ui

import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.shape.RoundedCornerShape
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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
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
    /** Mask the value (password entry). Forces single-line and a password keyboard. */
    secure: Boolean = false,
    onSubmit: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val interaction = remember { MutableInteractionSource() }
    val focused by interaction.collectIsFocusedAsState()
    val shape = RoundedCornerShape(FlareSizes.radiusLg)
    Column(Modifier.fillMaxWidth()) {
        TextField(
            value = value,
            onValueChange = { if (maxLength == null || it.length <= maxLength) onValueChange(it) },
            enabled = !disabled,
            singleLine = !multiline || secure,
            maxLines = if (multiline && !secure) 6 else 1,
            shape = shape,
            interactionSource = interaction,
            placeholder = placeholder?.let { { Text(it, color = colors.textTertiary) } },
            visualTransformation = if (secure) PasswordVisualTransformation() else VisualTransformation.None,
            trailingIcon = if (clearable && value.isNotEmpty()) {
                { IconButton(onClick = { onValueChange("") }) { Icon(Icons.Outlined.Cancel, flareStrings().clear, tint = colors.textTertiary) } }
            } else null,
            keyboardOptions = KeyboardOptions(
                keyboardType = if (secure) KeyboardType.Password else KeyboardType.Text,
                imeAction = if (multiline && !secure) ImeAction.Default else ImeAction.Done,
            ),
            keyboardActions = KeyboardActions(onDone = { onSubmit?.invoke() }),
            colors = TextFieldDefaults.colors(
                focusedContainerColor = colors.bgSecondary,
                unfocusedContainerColor = colors.bgSecondary,
                disabledContainerColor = colors.bgSecondary,
                focusedIndicatorColor = Color.Transparent,
                unfocusedIndicatorColor = Color.Transparent,
                disabledIndicatorColor = Color.Transparent,
            ),
            modifier = Modifier.fillMaxWidth()
                .clip(shape)
                .border(1.dp, if (focused) colors.primary else colors.borderPrimary, shape),
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
