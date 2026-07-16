package com.flare.im.ui

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.Remove
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

private data class SizeSpec(val height: Int, val hPad: Int, val font: Int)

private fun sizeSpec(size: FlareControlSize) = when (size) {
    FlareControlSize.Sm -> SizeSpec(32, 12, 13)
    FlareControlSize.Md -> SizeSpec(40, 18, 14)
    FlareControlSize.Lg -> SizeSpec(48, 24, 15)
}

// MARK: - Button

/** Foundation button — variant × size. Spec: General/Button. */
@Composable
fun Button(
    label: String? = null,
    variant: FlareButtonVariant = FlareButtonVariant.Primary,
    size: FlareControlSize = FlareControlSize.Md,
    loading: Boolean = false,
    disabled: Boolean = false,
    block: Boolean = false,
    icon: ImageVector? = null,
    onClick: (() -> Unit)? = null,
    content: (@Composable () -> Unit)? = null,
) {
    val colors = flareColors()
    val spec = sizeSpec(size)
    val off = disabled || loading
    val shape = RoundedCornerShape(FlareSizes.radiusLg)

    val (bgBrush, fg, borderColor) = when (variant) {
        FlareButtonVariant.Primary -> Triple(Brush.linearGradient(listOf(colors.primary, colors.primaryActive)), Color.White, Color.Transparent)
        FlareButtonVariant.Secondary -> Triple(Brush.linearGradient(listOf(colors.bgSecondary, colors.bgSecondary)), colors.textPrimary, colors.borderPrimary)
        FlareButtonVariant.Ghost -> Triple(Brush.linearGradient(listOf(Color.Transparent, Color.Transparent)), colors.primary, colors.primary.copy(alpha = 0.4f))
        FlareButtonVariant.Danger -> Triple(Brush.linearGradient(listOf(colors.error, colors.error)), Color.White, Color.Transparent)
        FlareButtonVariant.Text -> Triple(Brush.linearGradient(listOf(Color.Transparent, Color.Transparent)), colors.primary, Color.Transparent)
    }

    var m = Modifier
        .then(if (block) Modifier.fillMaxWidth() else Modifier)
        .height(spec.height.dp).clip(shape).background(bgBrush)
        .border(1.dp, borderColor, shape)
        .alpha(if (disabled) 0.5f else 1f)
    if (!off && onClick != null) m = m.clickable { onClick() }
    m = m.padding(horizontal = spec.hPad.dp)

    Row(m, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        if (loading) {
            CircularProgressIndicator(Modifier.size(15.dp), color = fg, strokeWidth = 2.dp)
        } else if (icon != null) {
            Icon(icon, contentDescription = null, tint = fg, modifier = Modifier.size((spec.font + 4).dp))
        }
        if (content != null) content() else if (label != null) {
            Text(label, color = fg, fontWeight = FontWeight.SemiBold, fontSize = spec.font.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
    }
}

// MARK: - IconButton

/** Icon-only button. Spec: General/IconButton. */
@Composable
fun IconButton(
    icon: ImageVector,
    contentDescription: String,
    size: FlareControlSize = FlareControlSize.Md,
    variant: FlareIconButtonVariant = FlareIconButtonVariant.Plain,
    square: Boolean = false,
    disabled: Boolean = false,
    active: Boolean = false,
    onClick: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val dim = when (size) { FlareControlSize.Sm -> 30; FlareControlSize.Md -> 38; FlareControlSize.Lg -> 46 }
    val glyph = when (size) { FlareControlSize.Sm -> 16; FlareControlSize.Md -> 19; FlareControlSize.Lg -> 22 }
    val shape: Shape = if (square) RoundedCornerShape(FlareSizes.radiusMd) else CircleShape
    val (bg, fg) = when {
        active -> colors.bgSelected to colors.primary
        variant == FlareIconButtonVariant.Solid -> colors.primary to Color.White
        variant == FlareIconButtonVariant.Tinted -> colors.bgSecondary to colors.textSecondary
        else -> Color.Transparent to colors.textSecondary
    }
    Box(
        Modifier.size(dim.dp).clip(shape).background(bg).alpha(if (disabled) 0.45f else 1f)
            .then(if (!disabled && onClick != null) Modifier.clickable { onClick() } else Modifier),
        contentAlignment = Alignment.Center,
    ) { Icon(icon, contentDescription = contentDescription, tint = fg, modifier = Modifier.size(glyph.dp)) }
}

// MARK: - FormField

/** Label + control + hint/error wrapper. Spec: Form/FormField. */
@Composable
fun FormField(
    label: String? = null,
    required: Boolean = false,
    hint: String? = null,
    error: String? = null,
    content: @Composable () -> Unit,
) {
    val colors = flareColors()
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        if (label != null) {
            Row {
                Text(label, color = colors.textSecondary, fontWeight = FontWeight.Medium, fontSize = 13.sp)
                if (required) Text("*", color = colors.error, fontSize = 13.sp, modifier = Modifier.padding(start = 2.dp))
            }
        }
        content()
        when {
            error != null -> Text(error, color = colors.error, fontSize = 12.sp)
            hint != null -> Text(hint, color = colors.textTertiary, fontSize = 12.sp)
        }
    }
}

// MARK: - Switch

/** Toggle switch. Spec: Form/Switch. */
@Composable
fun Switch(value: Boolean, disabled: Boolean = false, onChange: ((Boolean) -> Unit)? = null) {
    val colors = flareColors()
    val knobX by animateDpAsState(if (value) 21.dp else 3.dp, label = "knob")
    Box(
        Modifier.width(44.dp).height(26.dp).clip(RoundedCornerShape(999.dp))
            .background(if (value) colors.primary else colors.borderHover)
            .alpha(if (disabled) 0.5f else 1f)
            .then(if (!disabled && onChange != null) Modifier.clickable { onChange(!value) } else Modifier),
    ) {
        Box(Modifier.offset(x = knobX, y = 3.dp).size(20.dp).clip(CircleShape).background(Color.White))
    }
}

// MARK: - Checkbox

/** Checkbox + label. Spec: Form/Checkbox. */
@Composable
fun Checkbox(
    value: Boolean,
    label: String? = null,
    indeterminate: Boolean = false,
    disabled: Boolean = false,
    onChange: ((Boolean) -> Unit)? = null,
) {
    val colors = flareColors()
    val on = value || indeterminate
    Row(
        Modifier.alpha(if (disabled) 0.5f else 1f)
            .then(if (!disabled && onChange != null) Modifier.clickable { onChange(!value) } else Modifier),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Box(
            Modifier.size(20.dp).clip(RoundedCornerShape(FlareSizes.radiusSm))
                .background(if (on) colors.primary else colors.bgPrimary)
                .border(1.5.dp, if (on) colors.primary else colors.borderHover, RoundedCornerShape(FlareSizes.radiusSm)),
            contentAlignment = Alignment.Center,
        ) {
            if (indeterminate) Icon(Icons.Outlined.Remove, contentDescription = null, tint = Color.White, modifier = Modifier.size(13.dp))
            else if (value) Icon(Icons.Outlined.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(13.dp))
        }
        label?.let { Text(it, color = colors.textPrimary, fontSize = 14.sp) }
    }
}

// MARK: - RadioGroup

/** Single-choice radio group. Spec: Form/RadioGroup. */
@Composable
fun RadioGroup(
    options: List<FlareSelectOption>,
    value: String,
    vertical: Boolean = false,
    onSelect: ((String) -> Unit)? = null,
) {
    val colors = flareColors()
    val row: @Composable (FlareSelectOption) -> Unit = { o ->
        val on = o.value == value
        Row(
            Modifier.alpha(if (o.disabled) 0.5f else 1f)
                .then(if (!o.disabled && onSelect != null) Modifier.clickable { onSelect(o.value) } else Modifier),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Box(
                Modifier.size(18.dp).clip(CircleShape).background(colors.bgPrimary)
                    .border(1.5.dp, if (on) colors.primary else colors.borderHover, CircleShape),
                contentAlignment = Alignment.Center,
            ) { if (on) Box(Modifier.size(9.dp).clip(CircleShape).background(colors.primary)) }
            Text(o.label, color = colors.textPrimary, fontSize = 14.sp)
        }
    }
    if (vertical) Column(verticalArrangement = Arrangement.spacedBy(12.dp)) { options.forEach { row(it) } }
    else Row(horizontalArrangement = Arrangement.spacedBy(18.dp)) { options.forEach { row(it) } }
}

// MARK: - Select

/**
 * Select — adaptive: on a native app (always mobile) it presents its options as
 * a bottom sheet. The trigger is a token-styled pill; the sheet lists options
 * with the selected row on brand primary + a check. Spec: Form/Select.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun Select(
    options: List<FlareSelectOption>,
    value: String,
    placeholder: String? = null,
    size: FlareControlSize = FlareControlSize.Md,
    disabled: Boolean = false,
    title: String? = null,
    onChange: ((String) -> Unit)? = null,
) {
    val colors = flareColors()
    var open by remember { mutableStateOf(false) }
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val spec = sizeSpec(size)
    val current = options.firstOrNull { it.value == value }
    val shape = RoundedCornerShape(FlareSizes.radiusLg)

    Row(
        Modifier.height(spec.height.dp).defaultMinSize(minWidth = 160.dp).clip(shape).background(colors.bgSecondary)
            .border(1.dp, if (open) colors.primary else colors.borderPrimary, shape)
            .alpha(if (disabled) 0.55f else 1f)
            .then(if (!disabled) Modifier.clickable { open = true } else Modifier)
            .padding(horizontal = spec.hPad.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            current?.label ?: (placeholder ?: ""),
            color = if (current != null) colors.textPrimary else colors.textTertiary,
            fontSize = spec.font.sp, maxLines = 1, overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f),
        )
        Spacer(Modifier.width(8.dp))
        Icon(Icons.Outlined.ExpandMore, contentDescription = null, tint = colors.textTertiary,
            modifier = Modifier.size(16.dp).rotate(if (open) 180f else 0f))
    }

    if (open) {
        ModalBottomSheet(
            onDismissRequest = { open = false },
            sheetState = sheetState,
            containerColor = colors.bgPrimary,
        ) {
            val heading = title ?: placeholder
            if (heading != null) {
                Text(
                    heading,
                    color = colors.textTertiary, fontSize = 13.sp, fontWeight = FontWeight.Medium,
                    modifier = Modifier.fillMaxWidth().padding(bottom = 10.dp), textAlign = TextAlign.Center,
                )
            }
            Column(Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 4.dp)) {
                options.forEach { o ->
                    val selected = o.value == value
                    Row(
                        Modifier.fillMaxWidth().height(52.dp).clip(RoundedCornerShape(FlareSizes.radiusLg))
                            .alpha(if (o.disabled) 0.4f else 1f)
                            .then(if (!o.disabled) Modifier.clickable { onChange?.invoke(o.value); open = false } else Modifier)
                            .padding(horizontal = 16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(o.label, color = if (selected) colors.primary else colors.textPrimary,
                            fontSize = 16.sp, fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
                            modifier = Modifier.weight(1f))
                        if (selected) Icon(Icons.Outlined.Check, contentDescription = null, tint = colors.primary, modifier = Modifier.size(19.dp))
                    }
                }
                Spacer(Modifier.height(8.dp))
            }
        }
    }
}
