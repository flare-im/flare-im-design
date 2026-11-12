package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
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
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp

/** On-screen keyboard an [Input] asks for (spec Input `inputmode`). Masked fields always use the password keyboard. */
enum class FlareInputMode { Text, Numeric, Decimal, Tel, Email, Url, Search }

internal fun FlareInputMode.keyboardType(): KeyboardType = when (this) {
    FlareInputMode.Text, FlareInputMode.Search -> KeyboardType.Text
    FlareInputMode.Numeric -> KeyboardType.Number
    FlareInputMode.Decimal -> KeyboardType.Decimal
    FlareInputMode.Tel -> KeyboardType.Phone
    FlareInputMode.Email -> KeyboardType.Email
    FlareInputMode.Url -> KeyboardType.Uri
}

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
    /** A secure field the person can unmask: the field draws the reveal key itself, named by the kit. */
    revealable: Boolean = false,
    /** Draw the value in the platform's monospaced face (codes, identifiers); the field's geometry does not change. */
    monospace: Boolean = false,
    size: FlareControlSize = FlareControlSize.Md,
    /** On-screen keyboard (spec `inputmode`); ignored on a secure field. */
    inputMode: FlareInputMode = FlareInputMode.Text,
    onSubmit: (() -> Unit)? = null,
) {
    val colors = flareColors()
    // Unmasking is the person's own, momentary choice: it lives in the field and is never reported.
    var revealed by remember { mutableStateOf(false) }
    val masked = secure && !revealed
    val interaction = remember { MutableInteractionSource() }
    val focused by interaction.collectIsFocusedAsState()
    val shape = RoundedCornerShape(FlareSizes.radiusLg)
    val showClear = clearable && value.isNotEmpty() && !disabled && !secure
    val showReveal = secure && revealable && !disabled
    Column(Modifier.fillMaxWidth()) {
        Row(
            Modifier.fillMaxWidth().heightIn(min = maxOf(size.visualHeight(), FlareSizes.touchTargetMin))
                .clip(shape)
                .background(colors.bgSecondary)
                .border(1.dp, if (focused) colors.borderSelected else colors.borderPrimary, shape)
                .padding(start = FlareSizes.spacingMd, end = if (showClear || showReveal) 0.dp else FlareSizes.spacingMd),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(Modifier.weight(1f).padding(vertical = FlareSizes.spacingSm)) {
                BasicTextField(
                    value = value,
                    onValueChange = { onValueChange(composerTextWithinLimit(it, maxLength)) },
                    enabled = !disabled,
                    singleLine = !multiline || secure,
                    maxLines = if (multiline && !secure) 6 else 1,
                    interactionSource = interaction,
                    textStyle = TextStyle(
                        color = colors.textPrimary,
                        fontSize = FlareSizes.fontSizeLg.value.sp,
                        fontFamily = if (monospace) FontFamily.Monospace else null,
                        letterSpacing = if (monospace) 0.08.em else TextUnit.Unspecified,
                    ),
                    cursorBrush = SolidColor(colors.primary),
                    visualTransformation = if (masked) PasswordVisualTransformation() else VisualTransformation.None,
                    keyboardOptions = KeyboardOptions(
                        keyboardType = if (secure) KeyboardType.Password else inputMode.keyboardType(),
                        imeAction = when {
                            multiline && !secure -> ImeAction.Default
                            inputMode == FlareInputMode.Search -> ImeAction.Search
                            else -> ImeAction.Done
                        },
                    ),
                    keyboardActions = KeyboardActions(onDone = { onSubmit?.invoke() }, onSearch = { onSubmit?.invoke() }),
                    modifier = Modifier.fillMaxWidth(),
                    decorationBox = { inner ->
                        if (value.isEmpty() && placeholder != null) {
                            Text(placeholder, color = colors.textTertiary, fontSize = FlareSizes.fontSizeLg.value.sp)
                        }
                        inner()
                    },
                )
            }
            if (showClear) {
                FlareIconControl(
                    label = flareStrings().clear,
                    onClick = { onValueChange("") },
                    minSize = FlareSizes.touchTargetMin,
                ) {
                    Icon(
                        Icons.Outlined.Cancel,
                        contentDescription = null,
                        tint = colors.textTertiary,
                        modifier = Modifier.size(18.dp),
                    )
                }
            }
            if (showReveal) {
                val strings = flareStrings()
                FlareIconControl(
                    label = if (revealed) strings.inputHide else strings.inputReveal,
                    onClick = { revealed = !revealed },
                    checked = revealed,
                    minSize = FlareSizes.touchTargetMin,
                ) {
                    Icon(
                        flareIconVector(if (revealed) "eye-off" else "eye"),
                        contentDescription = null,
                        tint = colors.textTertiary,
                        modifier = Modifier.size(18.dp),
                    )
                }
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
                    color = if (value.length >= maxLength) colors.errorText else colors.textTertiary,
                )
            }
        }
    }
}
