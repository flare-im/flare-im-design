package com.flare.im.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.selection.triStateToggleable
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.state.ToggleableState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.Remove
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.roundToInt

internal fun FlareControlSize.visualHeight(): Dp = when (this) {
    FlareControlSize.Sm -> FlareSizes.controlHeightSm
    FlareControlSize.Md -> FlareSizes.controlHeightMd
    FlareControlSize.Lg -> FlareSizes.controlHeightLg
}

private data class SizeSpec(val hPad: Dp, val font: Int)

private fun sizeSpec(size: FlareControlSize) = when (size) {
    FlareControlSize.Sm -> SizeSpec(FlareSizes.controlPadXSm, FlareSizes.fontSizeMd.value.toInt())
    FlareControlSize.Md -> SizeSpec(FlareSizes.controlPadXMd, FlareSizes.fontSizeLg.value.toInt())
    FlareControlSize.Lg -> SizeSpec(FlareSizes.controlPadXLg, FlareSizes.fontSizeXl.value.toInt())
}

/** Select trigger uses input-style (tighter) horizontal padding, not button padding. */
private fun selectHPad(size: FlareControlSize) = when (size) {
    FlareControlSize.Sm -> 10
    FlareControlSize.Md -> 12
    FlareControlSize.Lg -> 14
}

// MARK: - Button

enum class FlareButtonAppearance { Standard, Text }

/** Foundation button — variant × size. Spec: General/Button. */
@Composable
fun Button(
    label: String? = null,
    variant: FlareButtonVariant = FlareButtonVariant.Primary,
    size: FlareControlSize = FlareControlSize.Md,
    loading: Boolean = false,
    disabled: Boolean = false,
    block: Boolean = false,
    /** A semantic icon name from the registry (`docs/ICON-LIBRARY.md`), not a platform glyph. */
    icon: String? = null,
    onClick: (() -> Unit)? = null,
    appearance: FlareButtonAppearance = FlareButtonAppearance.Standard,
    maintainTouchTarget: Boolean = false,
    content: (@Composable () -> Unit)? = null,
) {
    val colors = flareColors()
    val spec = sizeSpec(size)
    val largeText = LocalDensity.current.fontScale >= 2f
    val off = disabled || loading || onClick == null
    val shape = RoundedCornerShape(FlareSizes.radiusLg)

    // ghost / text 的**文字**取 primaryText 而不是 primary:两者是一对的两半,浅色下同为
    // #7047D6 所以看不出来,暗色下 primary 不变(在 #20232B 上 2.66:1,AA 正文要 4.5)而
    // primaryText 提亮成 #A78BFA(5.77:1)。ghost 的描边仍用 primary —— 描边是填充不是文字。
    val (fill, fg, borderColor) = if (appearance == FlareButtonAppearance.Text) Triple(Color.Transparent, when (variant) {
        FlareButtonVariant.Primary, FlareButtonVariant.Text, FlareButtonVariant.Ghost -> colors.primaryText
        FlareButtonVariant.Danger -> colors.errorText
        else -> colors.textSecondary
    }, Color.Transparent) else when (variant) {
        FlareButtonVariant.Primary -> Triple(colors.primary, Color.White, Color.Transparent)
        FlareButtonVariant.Secondary -> Triple(colors.bgSecondary, colors.textPrimary, colors.borderPrimary)
        FlareButtonVariant.Ghost -> Triple(Color.Transparent, colors.primaryText, colors.primary.copy(alpha = 0.4f))
        FlareButtonVariant.Danger -> Triple(colors.error, Color.White, Color.Transparent)
        FlareButtonVariant.Text -> Triple(Color.Transparent, colors.primaryText, Color.Transparent)
        FlareButtonVariant.Quiet -> Triple(Color.Transparent, colors.textSecondary, Color.Transparent)
    }

    val interactionSource = remember { MutableInteractionSource() }
    val focused by interactionSource.collectIsFocusedAsState()
    val down by interactionSource.collectIsPressedAsState()
    // Hover only ever comes from a pointer (mouse, stylus), so touch never sees the hover fill.
    val hovered by interactionSource.collectIsHoveredAsState()
    val textFocus = appearance == FlareButtonAppearance.Text && focused && !off
    val background = if (textFocus) fg.copy(alpha = 0.1f) else fill
    val (hoverFill, pressedFill) = buttonFeedbackFills(variant, appearance, colors)
    // §7 / §12.10: pressed takes the pressed fill and 0.98 (`transitions.fast`); reduced motion keeps the colour only.
    val shownFill by animateColorAsState(
        when { off -> background; down -> pressedFill; hovered -> hoverFill; else -> background },
        tween(FlareMotion.fast, easing = FlareMotion.fastEasing), label = "button-fill",
    )
    val reducedMotion = flareReducedMotion()
    val scale by animateFloatAsState(if (down && !off && !reducedMotion) FlareSizes.componentPressScale else 1f,
        tween(FlareMotion.fast, easing = FlareMotion.fastEasing), label = "button-scale")

    var m = Modifier
        .then(if (block) Modifier.fillMaxWidth() else Modifier)
        .then(if (maintainTouchTarget) Modifier.minimumInteractiveComponentSize() else Modifier)
        .defaultMinSize(minHeight = if (appearance == FlareButtonAppearance.Text) FlareSizes.touchTarget else size.visualHeight(), minWidth = if (appearance == FlareButtonAppearance.Text) FlareSizes.touchTarget else 0.dp)
        .graphicsLayer { scaleX = scale; scaleY = scale }
        // Before the fill: a disabled button fades whole, fill and label, like the web's `opacity`.
        .flareDimmed(if (disabled || onClick == null) 0.5f else 1f)
        .clip(shape).background(shownFill)
        .border(1.dp, borderColor, shape)
    m = m.clickable(interactionSource = interactionSource, indication = androidx.compose.foundation.LocalIndication.current,
        enabled = !off, role = androidx.compose.ui.semantics.Role.Button) { onClick?.invoke() }
    m = m.padding(horizontal = if (appearance == FlareButtonAppearance.Text) 0.dp else spec.hPad, vertical = FlareSizes.spacing2xs)

    // A block button centres its label across the width, as on iOS and the web; a hugging one has no slack to place.
    Row(
        m,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs, Alignment.CenterHorizontally),
    ) {
        if (loading) {
            CircularProgressIndicator(Modifier.size(15.dp), color = fg, strokeWidth = 2.dp)
        } else if (icon != null) {
            FlareIcon(name = icon, size = (spec.font + 4).dp, tint = fg)
        }
        if (content != null) content() else if (label != null) {
            Text(
                label,
                color = fg,
                fontWeight = if (textFocus) FontWeight.Bold else FontWeight.SemiBold,
                textDecoration = TextDecoration.None,
                fontSize = spec.font.sp,
                maxLines = if (largeText) 2 else 1,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center,
            )
        }
    }
}

/**
 * The fills a button turns while hovered and while pressed (§12.10): primary → primaryHover / primaryActive (a red
 * packet's money key re-tints these to `redPacketEndHover` / `Active`), danger → errorHover / errorActive, and the
 * secondary-like rest → bgHover.
 */
internal fun buttonFeedbackFills(variant: FlareButtonVariant, appearance: FlareButtonAppearance, colors: FlareColors): Pair<Color, Color> = when {
    appearance == FlareButtonAppearance.Text -> colors.bgHover to colors.bgHover
    variant == FlareButtonVariant.Primary -> colors.primaryHover to colors.primaryActive
    variant == FlareButtonVariant.Danger -> colors.errorHover to colors.errorActive
    else -> colors.bgHover to colors.bgHover
}

/**
 * Dims what follows in the chain to [alpha], keeping one layer whatever the value. `Modifier.alpha(1f)` drops its layer,
 * and dropping a layer below a fill as a control becomes enabled left the fill undrawn — a submit lost its colour as its
 * form became valid, only its label staying on the page.
 */
internal fun Modifier.flareDimmed(alpha: Float): Modifier = graphicsLayer { this.alpha = alpha }

// MARK: - IconButton

internal val LocalFlareHeaderIcons = staticCompositionLocalOf { false }

/**
 * Icon-only button. Spec: General/IconButton. [dot] marks something new behind it (an unread count the key does not
 * spell out): a small error-coloured dot on the disc's top end, decorative — [contentDescription] says what it opens.
 */
@Composable
fun IconButton(
    /** A semantic icon name from the registry (`docs/ICON-LIBRARY.md`), not a platform glyph. */
    icon: String,
    contentDescription: String,
    size: FlareControlSize = FlareControlSize.Md,
    variant: FlareIconButtonVariant = FlareIconButtonVariant.Plain,
    square: Boolean = false,
    disabled: Boolean = false,
    active: Boolean = false,
    tint: Color? = null,
    background: Color? = null,
    customSize: Dp? = null,
    // Before [onClick], so a trailing lambda is still the click.
    dot: Boolean = false,
    onClick: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val phone = flareCompactOverlays()
    val header = phone && LocalFlareHeaderIcons.current
    val baseSide: Dp = customSize ?: when (size) { FlareControlSize.Sm -> FlareSizes.componentIconButtonSideSm; FlareControlSize.Md -> FlareSizes.componentIconButtonSideMd; FlareControlSize.Lg -> FlareSizes.componentIconButtonSideLg }
    val dimDp = if (header) maxOf(baseSide, FlareSizes.touchTarget) else baseSide
    val baseGlyph: Dp = if (customSize != null) (customSize.value * 0.46f).roundToInt().dp
        else when (size) { FlareControlSize.Sm -> FlareSizes.componentIconButtonGlyphSm; FlareControlSize.Md -> FlareSizes.componentIconButtonGlyphMd; FlareControlSize.Lg -> FlareSizes.componentIconButtonGlyphLg }
    val glyphDp = when {
        header -> maxOf(baseGlyph, FlareSizes.iconSizeLg)
        phone -> maxOf(baseGlyph, FlareSizes.iconSizeMd)
        else -> baseGlyph
    }
    val shape: Shape = if (square) RoundedCornerShape(FlareSizes.radiusMd) else CircleShape
    val (bgDerived, fgDerived) = when {
        active -> colors.bgSelected to colors.primary
        variant == FlareIconButtonVariant.Solid -> colors.primary to Color.White
        variant == FlareIconButtonVariant.Tinted -> colors.bgSecondary to colors.textSecondary
        else -> Color.Transparent to colors.textSecondary
    }
    val fg = tint ?: fgDerived
    val source = remember { MutableInteractionSource() }
    val down by source.collectIsPressedAsState()
    val hovered by source.collectIsHoveredAsState()
    val live = onClick != null && !disabled
    // §12.10: pressed or hovered (a pointer) the disc takes its pressed fill; pressed it also scales to 0.98 unless
    // motion is reduced. A host-given background keeps its colour.
    val pressedFill = if (variant == FlareIconButtonVariant.Solid && !active) colors.primaryActive else colors.bgHover
    val bg by animateColorAsState(
        background ?: if (live && (down || hovered)) pressedFill else bgDerived,
        tween(FlareMotion.fast, easing = FlareMotion.fastEasing), label = "icon-button-fill",
    )
    val reducedMotion = flareReducedMotion()
    val scale by animateFloatAsState(if (live && down && !reducedMotion) FlareSizes.componentPressScale else 1f,
        tween(FlareMotion.fast, easing = FlareMotion.fastEasing), label = "icon-button-scale")
    // 外层拿触达区与语义,内层只画那个圆盘。两件事从前挤在一个节点上,后果有两个:
    //  · 整个节点就是 30/38/46 的圆盘,低于 48dp —— 只剩 Compose 那点隐式命中扩张兜着,
    //    而隐式扩张的优先级低于任何自身边界包住该点的兄弟节点,恰恰在密集行里先失效;
    //  · disabled 时整个 clickable 被换成 Modifier,连 Role.Button 和 disabled 状态一起丢了,
    //    TalkBack 把一颗停用的按钮念成一张带描述的图片。
    // 存在性守卫要留着:onClick == null 的那些是装饰,不该被安上一个停用的按钮语义。
    Box(
        Modifier
            .sizeIn(minWidth = FlareSizes.touchTarget, minHeight = FlareSizes.touchTarget)
            .then(if (onClick != null) Modifier.clickable(interactionSource = source, indication = androidx.compose.foundation.LocalIndication.current, enabled = !disabled, role = Role.Button) { onClick() } else Modifier),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            Modifier.size(dimDp).graphicsLayer { scaleX = scale; scaleY = scale }.flareDimmed(if (disabled) 0.45f else 1f).clip(shape).background(bg),
            contentAlignment = Alignment.Center,
        ) { FlareIcon(name = icon, size = glyphDp, tint = fg, contentDescription = contentDescription) }
        if (dot) Box(
            Modifier.align(Alignment.Center).offset(x = dimDp / 2 - 6.dp, y = -dimDp / 2 + 6.dp)
                .size(8.dp).clip(CircleShape).background(colors.error),
        )
    }
}

// MARK: - FormField

/** Label + control + hint/error wrapper. Spec: Form/FormField. */
@Composable
fun FormField(
    label: String? = null,
    required: Boolean = false,
    hint: String? = null,
    error: String? = null,
    /** A count drawn at the end of the label row ("3/24"), as the Vue field's `counter`. */
    counter: String? = null,
    content: @Composable () -> Unit,
) {
    val colors = flareColors()
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing2xs)) {
        if (label != null || counter != null) {
            Row(Modifier.fillMaxWidth()) {
                if (label != null) Text(label, color = colors.textSecondary, fontWeight = FontWeight.Medium, fontSize = FlareSizes.fontSizeMd)
                if (required) Text("*", color = colors.errorText, fontSize = FlareSizes.fontSizeMd, modifier = Modifier.padding(start = 2.dp))
                if (counter != null) {
                    Spacer(Modifier.weight(1f))
                    Text(counter, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm)
                }
            }
        }
        content()
        when {
            error != null -> Text(error, color = colors.errorText, fontSize = FlareSizes.fontSizeSm)
            hint != null -> Text(hint, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm)
        }
    }
}

// MARK: - Switch

/** Toggle switch. Spec: Form/Switch. */
@Composable
fun Switch(value: Boolean, disabled: Boolean = false, onChange: ((Boolean) -> Unit)? = null) {
    Box(
        Modifier.sizeIn(minWidth = FlareSizes.touchTarget, minHeight = FlareSizes.touchTarget)
            .toggleable(value = value, enabled = !disabled && onChange != null, role = Role.Switch) { onChange?.invoke(it) }
            .flareDimmed(if (disabled) 0.5f else 1f),
        contentAlignment = Alignment.Center,
    ) { FlareSwitchTrack(value) }
}

@Composable
internal fun FlareSwitchTrack(value: Boolean, size: FlareControlSize = FlareControlSize.Md) {
    val colors = flareColors()
    val (width, height, thumb) = when (size) {
        FlareControlSize.Sm -> Triple(FlareSizes.componentSwitchWidthSm, FlareSizes.componentSwitchHeightSm, FlareSizes.componentSwitchThumbSm)
        FlareControlSize.Md -> Triple(FlareSizes.componentSwitchWidthMd, FlareSizes.componentSwitchHeightMd, FlareSizes.componentSwitchThumbMd)
        FlareControlSize.Lg -> Triple(FlareSizes.componentSwitchWidthLg, FlareSizes.componentSwitchHeightLg, FlareSizes.componentSwitchThumbLg)
    }
    val inset = (height - thumb) / 2
    val knobX by animateDpAsState(if (value) width - thumb - inset else inset, label = "knob")
    Box(
        Modifier.width(width).height(height)
            .background(if (value) colors.primary else colors.borderHover, CircleShape),
        contentAlignment = Alignment.CenterStart,
    ) {
        Box(
            Modifier.offset(x = knobX).size(thumb)
                .shadow(2.dp, CircleShape, clip = false, ambientColor = Color(0xFF151220), spotColor = Color(0xFF151220))
                .background(Color.White, CircleShape),
        )
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
        Modifier.sizeIn(minWidth = FlareSizes.touchTarget, minHeight = FlareSizes.touchTarget)
            .flareDimmed(if (disabled) 0.5f else 1f)
            .triStateToggleable(
                state = when { indeterminate -> ToggleableState.Indeterminate; value -> ToggleableState.On; else -> ToggleableState.Off },
                enabled = !disabled && onChange != null,
                role = Role.Checkbox,
            ) { onChange?.invoke(!value) },
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
    ) {
        Box(
            Modifier.size(FlareSizes.iconSizeMd).clip(RoundedCornerShape(FlareSizes.radiusSm))
                .background(if (on) colors.primary else colors.bgPrimary)
                .border(1.5.dp, if (on) colors.primary else colors.borderHover, RoundedCornerShape(FlareSizes.radiusSm)),
            contentAlignment = Alignment.Center,
        ) {
            if (indeterminate) Icon(Icons.Outlined.Remove, contentDescription = null, tint = Color.White, modifier = Modifier.size(13.dp))
            else if (value) Icon(Icons.Outlined.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(13.dp))
        }
        label?.let { Text(it, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg) }
    }
}

// MARK: - RadioGroup

/**
 * How a [RadioGroup] lays out its options (RadioGroup `optionLayout`): [Compact] inline (or stacked with `vertical`);
 * [List] full-width 48 rows with the selected tint; [Cards] one 48-high card per option with the selected border and a
 * check, stacked on a phone and in equal columns on a wide window (a plugin form's select of at most 4 choices).
 */
enum class FlareRadioOptionLayout { Compact, List, Cards }

/** Single-choice radio group. Spec: Form/RadioGroup. */
@Composable
fun RadioGroup(
    options: List<FlareSelectOption>,
    value: String,
    vertical: Boolean = false,
    onSelect: ((String) -> Unit)? = null,
    optionLayout: FlareRadioOptionLayout = FlareRadioOptionLayout.Compact,
    grouped: Boolean = false,
) {
    val colors = flareColors()
    if (optionLayout != FlareRadioOptionLayout.Compact) {
        val cards = optionLayout == FlareRadioOptionLayout.Cards
        val groupedList = grouped && !cards
        val shape = RoundedCornerShape(FlareSizes.radiusLg)
        val option: @Composable (FlareSelectOption, Modifier) -> Unit = { o, modifier ->
            val on = o.value == value
            Row(
                modifier.heightIn(min = FlareSizes.touchTarget)
                    .then(if (cards) Modifier.clip(shape).background(colors.bgSecondary)
                        .border(if (on) 1.5.dp else 1.dp, if (on) colors.borderSelected else colors.borderPrimary, shape)
                    else Modifier.background(if (on && !groupedList) colors.bgSelected else Color.Transparent))
                    .flareDimmed(if (o.disabled) FlareOpacity.disabled else 1f)
                    .selectable(selected = on, enabled = !o.disabled && onSelect != null, role = Role.RadioButton) { onSelect?.invoke(o.value) }
                    .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingSm),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            ) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
                    Text(o.label, color = if (on && groupedList) colors.primaryText else colors.textPrimary,
                        fontSize = FlareSizes.fontSizeLg, fontWeight = if (on || groupedList) FontWeight.SemiBold else FontWeight.Normal)
                    o.description?.let { Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm) }
                }
                if (on) FlareIcon("check", size = FlareSizes.iconSizeSm, tint = colors.primaryText)
            }
        }
        if (cards && !flareCompactOverlays()) {
            Row(Modifier.fillMaxWidth().selectableGroup(), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                options.forEach { option(it, Modifier.weight(1f)) }
            }
        } else {
            Column(
                Modifier.fillMaxWidth().selectableGroup().then(
                    if (groupedList) Modifier.clip(shape).background(colors.bgElevated).border(1.dp, colors.borderPrimary, shape)
                    else Modifier
                ),
                verticalArrangement = Arrangement.spacedBy(if (cards) FlareSizes.spacingSm else 0.dp),
            ) {
                options.forEachIndexed { index, item ->
                    if (groupedList && index > 0) HorizontalDivider(color = colors.borderSecondary)
                    option(item, Modifier.fillMaxWidth())
                }
            }
        }
        return
    }
    val row: @Composable (FlareSelectOption) -> Unit = { o ->
        val on = o.value == value
        Row(
            Modifier.sizeIn(minWidth = FlareSizes.touchTarget, minHeight = FlareSizes.touchTarget)
                .flareDimmed(if (o.disabled) 0.5f else 1f)
                .selectable(selected = on, enabled = !o.disabled && onSelect != null, role = Role.RadioButton) { onSelect?.invoke(o.value) },
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
        ) {
            Box(
                Modifier.size(FlareSizes.componentRadioIndicator).clip(CircleShape).background(colors.bgPrimary)
                    .border(1.5.dp, if (on) colors.primary else colors.borderHover, CircleShape),
                contentAlignment = Alignment.Center,
            ) { if (on) Box(Modifier.size(FlareSizes.componentRadioDot).clip(CircleShape).background(colors.primary)) }
            Text(o.label, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg)
        }
    }
    if (vertical) Column(Modifier.selectableGroup(), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) { options.forEach { row(it) } }
    else Row(Modifier.selectableGroup(), horizontalArrangement = Arrangement.spacedBy(18.dp)) { options.forEach { row(it) } }
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
    val source = remember { MutableInteractionSource() }
    val active = (open || source.collectIsFocusedAsState().value) && !disabled
    val halo = colors.focusRing

    Row(
        Modifier.height(size.visualHeight()).defaultMinSize(minWidth = 160.dp)
            // §12.22: open or focused, a 1px `borderSelected` edge plus a 3px `focusRing` halo (Vue Select).
            .drawBehind {
                if (active) {
                    val width = 3.dp.toPx()
                    drawRoundRect(halo, topLeft = androidx.compose.ui.geometry.Offset(-width / 2, -width / 2),
                        size = androidx.compose.ui.geometry.Size(this.size.width + width, this.size.height + width),
                        cornerRadius = androidx.compose.ui.geometry.CornerRadius(FlareSizes.radiusLg.toPx() + width / 2),
                        style = androidx.compose.ui.graphics.drawscope.Stroke(width))
                }
            }
            .clip(shape).background(colors.bgSecondary)
            .border(1.dp, if (active) colors.borderSelected else colors.borderPrimary, shape)
            .flareDimmed(if (disabled) 0.55f else 1f)
            // 停用要写进 clickable 里,而不是把整条 clickable 换掉 —— 换掉就连
            // Role.Button 和 disabled 状态一起丢了,读屏会把它念成普通一行文字。
            .clickable(interactionSource = source, indication = androidx.compose.foundation.LocalIndication.current,
                enabled = !disabled, role = Role.Button) { open = true }
            .padding(horizontal = selectHPad(size).dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            current?.label ?: (placeholder ?: ""),
            color = if (current != null) colors.textPrimary else colors.textTertiary,
            fontSize = spec.font.sp, maxLines = 1, overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f),
        )
        Spacer(Modifier.width(FlareSizes.spacingSm))
        Icon(Icons.Outlined.ExpandMore, contentDescription = null, tint = colors.textTertiary,
            modifier = Modifier.size(FlareSizes.iconSizeSm).rotate(if (open) 180f else 0f))
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
                    color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.Medium,
                    modifier = Modifier.fillMaxWidth().padding(bottom = FlareSizes.spacing2sm), textAlign = TextAlign.Center,
                )
            }
            Column(Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs)) {
                options.forEach { o ->
                    val selected = o.value == value
                    Row(
                        Modifier.fillMaxWidth().height(52.dp).clip(RoundedCornerShape(FlareSizes.radiusLg))
                            .flareDimmed(if (o.disabled) 0.4f else 1f)
                            .clickable(enabled = !o.disabled, role = Role.Button) { onChange?.invoke(o.value); open = false }
                            .padding(horizontal = FlareSizes.spacingLg),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(o.label, color = if (selected) colors.primaryText else colors.textPrimary,
                            fontSize = FlareSizes.fontSize2xl, fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
                            modifier = Modifier.weight(1f))
                        if (selected) Icon(Icons.Outlined.Check, contentDescription = null, tint = colors.primaryText, modifier = Modifier.size(19.dp))
                    }
                }
                Spacer(Modifier.height(FlareSizes.spacingSm))
            }
        }
    }
}
