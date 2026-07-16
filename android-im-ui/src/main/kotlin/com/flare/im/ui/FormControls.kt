package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Remove
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.max
import kotlin.math.round

// MARK: - Textarea

/** Multi-line input — token container, optional char counter. Spec: Form/Textarea. */
@Composable
fun Textarea(
    value: String,
    placeholder: String? = null,
    size: FlareControlSize = FlareControlSize.Md,
    rows: Int = 3,
    showCount: Boolean = false,
    maxlength: Int? = null,
    disabled: Boolean = false,
    onChange: ((String) -> Unit)? = null,
) {
    val colors = flareColors()
    var focused by remember { mutableStateOf(false) }
    val font = when (size) { FlareControlSize.Sm -> 13; FlareControlSize.Md -> 14; FlareControlSize.Lg -> 15 }
    val pad = when (size) { FlareControlSize.Sm -> 8; FlareControlSize.Md -> 10; FlareControlSize.Lg -> 12 }
    val shape = RoundedCornerShape(FlareSizes.radiusLg)
    val minH = (font * 1.5 * rows + pad * 2).dp

    Box(
        Modifier.fillMaxWidth().clip(shape)
            .background(if (focused) colors.bgPrimary else colors.bgSecondary)
            .border(1.dp, if (focused) colors.primary else colors.borderPrimary, shape)
            .alpha(if (disabled) 0.55f else 1f)
            .padding(pad.dp),
    ) {
        BasicTextField(
            value = value,
            onValueChange = { next -> if (!disabled) onChange?.invoke(if (maxlength != null) next.take(maxlength) else next) },
            enabled = !disabled,
            textStyle = TextStyle(color = colors.textPrimary, fontSize = font.sp, lineHeight = (font * 1.5).sp),
            cursorBrush = SolidColor(colors.primary),
            modifier = Modifier.fillMaxWidth().defaultMinSize(minHeight = minH)
                .onFocusChanged { focused = it.isFocused },
            decorationBox = { inner ->
                if (value.isEmpty() && placeholder != null) {
                    Text(placeholder, color = colors.textTertiary, fontSize = font.sp, lineHeight = (font * 1.5).sp)
                }
                inner()
            },
        )
        if (showCount) {
            val count = value.length
            Text(
                if (maxlength != null) "$count / $maxlength" else "$count",
                color = colors.textTertiary, fontSize = 12.sp,
                modifier = Modifier.align(Alignment.BottomEnd),
            )
        }
    }
}

// MARK: - Stepper

/** −/+ numeric stepper. Spec: Form/Stepper. */
@Composable
fun Stepper(
    value: Int,
    min: Int = 0,
    max: Int = Int.MAX_VALUE,
    step: Int = 1,
    size: FlareControlSize = FlareControlSize.Md,
    readonly: Boolean = false,
    disabled: Boolean = false,
    onChange: ((Int) -> Unit)? = null,
) {
    val colors = flareColors()
    val btn = when (size) { FlareControlSize.Sm -> 30; FlareControlSize.Md -> 38; FlareControlSize.Lg -> 46 }
    val glyph = when (size) { FlareControlSize.Sm -> 15; FlareControlSize.Md -> 18; FlareControlSize.Lg -> 20 }
    val font = when (size) { FlareControlSize.Sm -> 13; FlareControlSize.Md -> 14; FlareControlSize.Lg -> 15 }
    val fieldW = when (size) { FlareControlSize.Lg -> 52; else -> 44 }
    val shape = RoundedCornerShape(FlareSizes.radiusLg)
    val canDec = !disabled && value > min
    val canInc = !disabled && value < max
    fun set(n: Int) { val c = n.coerceIn(min, max); if (c != value) onChange?.invoke(c) }

    Row(
        Modifier.height((btn).dp).clip(shape).background(colors.bgSecondary)
            .border(1.dp, colors.borderPrimary, shape).alpha(if (disabled) 0.55f else 1f),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            Modifier.size(btn.dp).alpha(if (canDec) 1f else 0.4f)
                .then(if (canDec) Modifier.clickable { set(value - step) } else Modifier),
            contentAlignment = Alignment.Center,
        ) { Icon(Icons.Outlined.Remove, contentDescription = "Decrease", tint = colors.textSecondary, modifier = Modifier.size(glyph.dp)) }
        Text(
            "$value", color = colors.textPrimary, fontSize = font.sp, textAlign = TextAlign.Center,
            modifier = Modifier.width(fieldW.dp),
        )
        Box(
            Modifier.size(btn.dp).alpha(if (canInc) 1f else 0.4f)
                .then(if (canInc) Modifier.clickable { set(value + step) } else Modifier),
            contentAlignment = Alignment.Center,
        ) { Icon(Icons.Outlined.Add, contentDescription = "Increase", tint = colors.textSecondary, modifier = Modifier.size(glyph.dp)) }
    }
}

// MARK: - Slider

/** Range slider with brand-gradient fill + optional value bubble. Spec: Form/Slider. */
@Composable
fun Slider(
    value: Float,
    min: Float = 0f,
    max: Float = 100f,
    step: Float = 1f,
    disabled: Boolean = false,
    showValue: Boolean = false,
    onChange: ((Float) -> Unit)? = null,
) {
    val colors = flareColors()
    val span = (max - min).takeIf { it != 0f } ?: 1f
    val pct = ((value - min) / span).coerceIn(0f, 1f)
    val thumb = 18.dp
    val density = LocalDensity.current

    fun emit(fraction: Float) {
        val raw = min + fraction.coerceIn(0f, 1f) * span
        val snapped = if (step > 0f) min + round((raw - min) / step) * step else raw
        onChange?.invoke(snapped.coerceIn(min, max))
    }

    BoxWithConstraints(
        Modifier.fillMaxWidth().height(28.dp).alpha(if (disabled) 0.5f else 1f),
        contentAlignment = Alignment.CenterStart,
    ) {
        val trackW = maxWidth
        val thumbPx = with(density) { thumb.toPx() }
        val trackPx = with(density) { trackW.toPx() }
        val usable = max(1f, trackPx - thumbPx)
        val gestureMod = if (!disabled) {
            Modifier.pointerInput(min, max, step) {
                detectHorizontalDragGestures { change, _ ->
                    change.consume()
                    emit((change.position.x - thumbPx / 2f) / usable)
                }
            }
        } else Modifier

        // track
        Box(Modifier.fillMaxWidth().height(6.dp).clip(RoundedCornerShape(999.dp)).background(colors.borderHover).then(gestureMod))
        // fill
        Box(
            Modifier.width((trackW - thumb) * pct + thumb / 2)
                .height(6.dp).clip(RoundedCornerShape(999.dp))
                .background(Brush.horizontalGradient(listOf(colors.primary, colors.primaryActive))),
        )
        // thumb
        Box(Modifier.offset(x = (trackW - thumb) * pct).size(thumb).clip(CircleShape)
            .background(Color.White).border(2.dp, colors.primary, CircleShape))
        if (showValue) {
            Box(Modifier.offset(x = (trackW - thumb) * pct - 8.dp, y = (-16).dp)) {
                Text(
                    "${round(value).toInt()}", color = Color.White, fontSize = 12.sp,
                    modifier = Modifier.clip(RoundedCornerShape(6.dp)).background(colors.primary).padding(horizontal = 8.dp, vertical = 2.dp),
                )
            }
        }
    }
}

// MARK: - Rating

/** Star rating — tap to set, optional clearable / read-only. Spec: Form/Rating. */
@Composable
fun Rating(
    value: Int,
    count: Int = 5,
    size: Int = 24,
    readonly: Boolean = false,
    clearable: Boolean = false,
    disabled: Boolean = false,
    onChange: ((Int) -> Unit)? = null,
) {
    val colors = flareColors()
    val interactive = !readonly && !disabled
    Row(
        Modifier.alpha(if (disabled) 0.5f else 1f),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        for (n in 1..count) {
            val on = n <= value
            Box(
                Modifier.size(size.dp)
                    .then(if (interactive) Modifier.clickable {
                        onChange?.invoke(if (clearable && value == n) 0 else n)
                    } else Modifier),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    if (on) Icons.Outlined.Star else Icons.Outlined.StarBorder,
                    contentDescription = "$n",
                    tint = if (on) colors.warning else colors.borderHover,
                    modifier = Modifier.size(size.dp),
                )
            }
        }
    }
}
