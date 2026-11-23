package com.flare.im.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.error
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp

/**
 * PIN input — a 6-digit payment password as six cells (5.10 of docs/plugin-experience.md; a plugin form's password of
 * `maxLength` 6, the payment confirmation's credential slot). Focused when it appears; each cell shows a dot for a digit
 * and, while the field has focus, the next cell wears the input focus style (§12.22: 1px `borderSelected` + `focusRing` halo); only digits go in (full-width ones folded), at most six. The sixth digit calls
 * [onComplete]. [error] (a wrong PIN) clears it, outlines the cells in the error colour and shakes them once (not under
 * reduced motion). TalkBack reads [label] and how many digits are in, never the digits.
 */
@Composable
fun FlarePinInput(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    disabled: Boolean = false,
    error: Boolean = false,
    autoFocus: Boolean = true,
    onComplete: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val focus = remember { FocusRequester() }
    val reducedMotion = flareReducedMotion()
    val shake = remember { Animatable(0f) }
    var focused by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { if (autoFocus) runCatching { focus.requestFocus() } }
    PluginOnChange(error) { _, now -> if (now) onValueChange("") }
    LaunchedEffect(error) {
        if (!error || reducedMotion) return@LaunchedEffect
        for (x in listOf(-8f, 8f, -6f, 6f, -3f, 0f)) shake.animateTo(x, tween(40))
    }
    BasicTextField(
        value = value,
        onValueChange = { raw ->
            val next = pluginPinDigits(raw)
            if (next != value) {
                onValueChange(next)
                if (next.length == FLARE_PIN_LENGTH) onComplete?.invoke()
            }
        },
        enabled = !disabled,
        singleLine = true,
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
        modifier = modifier.fillMaxWidth().focusRequester(focus).onFocusChanged { focused = it.isFocused }.semantics {
            contentDescription = strings.pinInputProgress.replace("{label}", label).replace("{count}", value.length.toString())
            if (error) this.error(label)
        },
        decorationBox = { _ ->
            androidx.compose.foundation.layout.BoxWithConstraints(Modifier.fillMaxWidth()) {
            // §12.19: the cells shrink with a narrow panel (320 wide leaves 288), never below `component.pinCellMinWidth`.
            val cell = flarePinCellWidth(maxWidth)
            Row(Modifier.fillMaxWidth().offset(x = shake.value.dp), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm, Alignment.CenterHorizontally)) {
                repeat(FLARE_PIN_LENGTH) { index ->
                    val shape = RoundedCornerShape(FlareSizes.radiusLg)
                    val current = focused && index == value.length && !disabled
                    val halo = colors.focusRing
                    Box(
                        Modifier.size(cell, FlareSizes.componentPinCellHeight)
                            .drawBehind {
                                if (current) {
                                    val width = FlareSizes.componentFocusRingWidth.toPx()
                                    drawRoundRect(halo, topLeft = Offset(-width / 2, -width / 2), size = Size(size.width + width, size.height + width),
                                        cornerRadius = CornerRadius(FlareSizes.radiusLg.toPx() + width / 2), style = Stroke(width))
                                }
                            }
                            .clip(shape).background(colors.bgSecondary)
                            .border(1.dp, when {
                                error -> colors.error
                                current -> colors.borderSelected
                                else -> colors.borderPrimary
                            }, shape)
                            .flareDimmed(if (disabled) FlareOpacity.disabled else 1f)
                            .clearAndSetSemantics {},
                        contentAlignment = Alignment.Center,
                    ) {
                        if (index < value.length) Box(Modifier.size(10.dp).clip(CircleShape).background(colors.textPrimary))
                    }
                }
            }
            }
        },
    )
}

/** A PIN cell's width in [available]: the token's, or what six cells and their five sm gaps leave, at least `component.pinCellMinWidth`. */
internal fun flarePinCellWidth(available: androidx.compose.ui.unit.Dp): androidx.compose.ui.unit.Dp =
    minOf(FlareSizes.componentPinCellWidth, (available - FlareSizes.spacingSm * (FLARE_PIN_LENGTH - 1)) / FLARE_PIN_LENGTH)
        .coerceAtLeast(FlareSizes.componentPinCellMinWidth)

/** How many digits a PIN has. */
const val FLARE_PIN_LENGTH = 6
