package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
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
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * General text input — single/multi-line, char limit, clearable, disabled.
 * Spec: General/Input (`Input`). Token-padded raised field (bgSecondary track, radiusLg corners,
 * focus-tinted border) rather than a Material 56dp box, matching iOS/Flutter.
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
        Row(
            Modifier.fillMaxWidth()
                .clip(shape)
                .background(colors.bgSecondary)
                .border(1.dp, if (focused) colors.primary else colors.borderPrimary, shape)
                .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(Modifier.weight(1f)) {
                BasicTextField(
                    value = value,
                    onValueChange = { if (maxLength == null || it.length <= maxLength) onValueChange(it) },
                    enabled = !disabled,
                    singleLine = !multiline || secure,
                    maxLines = if (multiline && !secure) 6 else 1,
                    interactionSource = interaction,
                    textStyle = TextStyle(color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp),
                    cursorBrush = SolidColor(colors.primary),
                    visualTransformation = if (secure) PasswordVisualTransformation() else VisualTransformation.None,
                    keyboardOptions = KeyboardOptions(
                        keyboardType = if (secure) KeyboardType.Password else KeyboardType.Text,
                        imeAction = if (multiline && !secure) ImeAction.Default else ImeAction.Done,
                    ),
                    keyboardActions = KeyboardActions(onDone = { onSubmit?.invoke() }),
                    modifier = Modifier.fillMaxWidth(),
                    decorationBox = { inner ->
                        if (value.isEmpty() && placeholder != null) {
                            Text(placeholder, color = colors.textTertiary, fontSize = FlareSizes.fontSizeLg.value.sp)
                        }
                        inner()
                    },
                )
            }
            if (clearable && value.isNotEmpty() && !disabled && !secure) {
                Icon(
                    Icons.Outlined.Cancel,
                    contentDescription = flareStrings().clear,
                    tint = colors.textTertiary,
                    modifier = Modifier
                        .padding(start = FlareSizes.spacingSm)
                        .size(18.dp)
                        .clickable { onValueChange("") },
                )
            }
        }
        if (maxLength != null) {
            Row(
                Modifier.fillMaxWidth().padding(top = FlareSizes.spacingXs),
                horizontalArrangement = Arrangement.End,
            ) {
                Text(
                    "${value.length}/$maxLength",
                    fontSize = FlareSizes.fontSizeXs.value.sp,
                    color = if (value.length >= maxLength) colors.error else colors.textTertiary,
                )
            }
        }
    }
}
