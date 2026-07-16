package com.flare.im.ui

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.CalendarToday
import androidx.compose.material.icons.outlined.ChevronLeft
import androidx.compose.material.icons.outlined.ChevronRight
import androidx.compose.material.icons.outlined.Remove
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.max
import kotlin.math.round
import java.time.LocalDate
import java.time.YearMonth

// MARK: - Textarea

/** Multi-line input — token container, optional char counter. Spec: Form/Textarea. */
@Composable
fun Textarea(
    value: String,
    placeholder: String? = null,
    size: FlareControlSize = FlareControlSize.Md,
    rows: Int = 3,
    maxRows: Int = 0,
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
            maxLines = if (maxRows > 0) maxRows else Int.MAX_VALUE,
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
    val h = when (size) { FlareControlSize.Sm -> 32; FlareControlSize.Md -> 40; FlareControlSize.Lg -> 48 }
    val btn = when (size) { FlareControlSize.Sm -> 30; FlareControlSize.Md -> 38; FlareControlSize.Lg -> 46 }
    val glyph = when (size) { FlareControlSize.Sm -> 15; FlareControlSize.Md -> 18; FlareControlSize.Lg -> 20 }
    val font = when (size) { FlareControlSize.Sm -> 13; FlareControlSize.Md -> 14; FlareControlSize.Lg -> 15 }
    val fieldW = when (size) { FlareControlSize.Lg -> 52; else -> 44 }
    val shape = RoundedCornerShape(FlareSizes.radiusLg)
    val canDec = !disabled && value > min
    val canInc = !disabled && value < max
    fun set(n: Int) { val c = n.coerceIn(min, max); if (c != value) onChange?.invoke(c) }

    Row(
        Modifier.height(h.dp).clip(shape).background(colors.bgSecondary)
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
    var dragging by remember { mutableStateOf(false) }
    val thumbScale by animateFloatAsState(if (dragging) 1.14f else 1f, label = "thumb")

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
                detectHorizontalDragGestures(
                    onDragStart = { dragging = true },
                    onDragEnd = { dragging = false },
                    onDragCancel = { dragging = false },
                ) { change, _ ->
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
        Box(Modifier.offset(x = (trackW - thumb) * pct).size(thumb).scale(thumbScale).clip(CircleShape)
            .background(Color.White).border(2.dp, colors.primary, CircleShape))
        if (showValue && dragging) {
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

// MARK: - TimePicker

/**
 * Time picker — a native app is always mobile, so it presents its hour/minute
 * columns as a bottom sheet. Trigger mirrors the Select pill with a clock icon.
 * value is "HH:mm". Spec: Form/TimePicker.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TimePicker(
    value: String,
    placeholder: String? = null,
    size: FlareControlSize = FlareControlSize.Md,
    minuteStep: Int = 5,
    title: String? = null,
    disabled: Boolean = false,
    cancelLabel: String = "取消",
    confirmLabel: String = "确定",
    onChange: ((String) -> Unit)? = null,
) {
    val colors = flareColors()
    val trigH = when (size) { FlareControlSize.Sm -> 32; FlareControlSize.Md -> 40; FlareControlSize.Lg -> 48 }
    val trigPad = when (size) { FlareControlSize.Sm -> 10; FlareControlSize.Md -> 12; FlareControlSize.Lg -> 14 }
    val trigFont = when (size) { FlareControlSize.Sm -> 13; FlareControlSize.Md -> 14; FlareControlSize.Lg -> 15 }
    val shape = RoundedCornerShape(FlareSizes.radiusLg)
    var open by remember { mutableStateOf(false) }
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val step = minuteStep.coerceIn(1, 30)
    val hours = (0..23).toList()
    val mins = (0 until 60 step step).toList()

    fun pad(n: Int) = n.toString().padStart(2, '0')
    val parsed = value.split(":")
    val curH = parsed.getOrNull(0)?.toIntOrNull() ?: 0
    val curM = parsed.getOrNull(1)?.toIntOrNull() ?: 0
    var th by remember(value, open) { mutableIntStateOf(curH) }
    var tm by remember(value, open) { mutableIntStateOf(curM) }

    Row(
        Modifier.height(trigH.dp).clip(shape).background(colors.bgSecondary)
            .border(1.dp, if (open) colors.primary else colors.borderPrimary, shape)
            .alpha(if (disabled) 0.55f else 1f)
            .then(if (!disabled) Modifier.clickable { open = true } else Modifier)
            .padding(horizontal = trigPad.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Icon(Icons.Outlined.Schedule, contentDescription = null, tint = colors.textTertiary, modifier = Modifier.size(16.dp))
        Text(
            value.ifEmpty { placeholder ?: "" },
            color = if (value.isNotEmpty()) colors.textPrimary else colors.textTertiary,
            fontSize = trigFont.sp, maxLines = 1,
        )
    }

    if (open) {
        ModalBottomSheet(
            onDismissRequest = { open = false },
            sheetState = sheetState,
            containerColor = colors.bgPrimary,
        ) {
            val heading = title ?: placeholder
            if (heading != null) {
                Text(heading, color = colors.textTertiary, fontSize = 13.sp, fontWeight = FontWeight.Medium,
                    modifier = Modifier.fillMaxWidth().padding(bottom = 6.dp), textAlign = TextAlign.Center)
            }
            Row(
                Modifier.fillMaxWidth().height(232.dp).padding(horizontal = 24.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                TimeColumn(hours, th, colors) { th = it }
                Text(":", color = colors.textTertiary, fontWeight = FontWeight.SemiBold, fontSize = 18.sp,
                    modifier = Modifier.padding(horizontal = 12.dp))
                TimeColumn(mins, tm, colors) { tm = it }
            }
            Row(
                Modifier.fillMaxWidth().padding(16.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Box(Modifier.weight(1f)) {
                    Button(label = cancelLabel, variant = FlareButtonVariant.Secondary, block = true, onClick = { open = false })
                }
                Box(Modifier.weight(1f)) {
                    Button(
                        label = confirmLabel, variant = FlareButtonVariant.Primary, block = true,
                        onClick = {
                            onChange?.invoke("${pad(th)}:${pad(tm)}")
                            open = false
                        },
                    )
                }
            }
        }
    }
}

@Composable
private fun androidx.compose.foundation.layout.RowScope.TimeColumn(
    values: List<Int>,
    selected: Int,
    colors: FlareColors,
    onPick: (Int) -> Unit,
) {
    val listState = rememberLazyListState()
    LaunchedEffect(Unit) {
        val idx = values.indexOf(selected)
        if (idx >= 0) listState.scrollToItem(idx.coerceAtLeast(0))
    }
    LazyColumn(
        state = listState,
        modifier = Modifier.weight(1f).height(232.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        items(values) { v ->
            val on = v == selected
            Text(
                v.toString().padStart(2, '0'),
                color = if (on) colors.primary else colors.textSecondary,
                fontWeight = if (on) FontWeight.SemiBold else FontWeight.Normal,
                fontSize = 17.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)
                    .clip(RoundedCornerShape(FlareSizes.radiusMd))
                    .background(if (on) colors.bgSelected else androidx.compose.ui.graphics.Color.Transparent)
                    .clickable { onPick(v) }
                    .padding(vertical = 10.dp),
            )
        }
    }
}

// MARK: - DatePicker

/**
 * Date picker — a native app is always mobile, so it presents a month calendar
 * in a bottom sheet. Trigger mirrors the Select pill with a calendar icon.
 * value is "YYYY-MM-DD". Spec: Form/DatePicker.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DatePicker(
    value: String,
    placeholder: String? = null,
    size: FlareControlSize = FlareControlSize.Md,
    min: String? = null,
    max: String? = null,
    title: String? = null,
    disabled: Boolean = false,
    cancelLabel: String = "取消",
    todayLabel: String = "今天",
    onChange: ((String) -> Unit)? = null,
) {
    val colors = flareColors()
    val trigH = when (size) { FlareControlSize.Sm -> 32; FlareControlSize.Md -> 40; FlareControlSize.Lg -> 48 }
    val trigPad = when (size) { FlareControlSize.Sm -> 10; FlareControlSize.Md -> 12; FlareControlSize.Lg -> 14 }
    val trigFont = when (size) { FlareControlSize.Sm -> 13; FlareControlSize.Md -> 14; FlareControlSize.Lg -> 15 }
    val shape = RoundedCornerShape(FlareSizes.radiusLg)
    var open by remember { mutableStateOf(false) }
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    fun pad(n: Int) = n.toString().padStart(2, '0')
    fun fmt(d: LocalDate) = "${d.year}-${pad(d.monthValue)}-${pad(d.dayOfMonth)}"
    val today = LocalDate.now()
    val todayStr = fmt(today)
    val parsed = runCatching { LocalDate.parse(value) }.getOrNull()
    var viewYm by remember(value, open) { mutableStateOf(YearMonth.from(parsed ?: today)) }

    Row(
        Modifier.height(trigH.dp).clip(shape).background(colors.bgSecondary)
            .border(1.dp, if (open) colors.primary else colors.borderPrimary, shape)
            .alpha(if (disabled) 0.55f else 1f)
            .then(if (!disabled) Modifier.clickable { open = true } else Modifier)
            .padding(horizontal = trigPad.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Icon(Icons.Outlined.CalendarToday, contentDescription = null, tint = colors.textTertiary, modifier = Modifier.size(16.dp))
        Text(
            value.ifEmpty { placeholder ?: "" },
            color = if (value.isNotEmpty()) colors.textPrimary else colors.textTertiary,
            fontSize = trigFont.sp, maxLines = 1,
        )
    }

    if (open) {
        ModalBottomSheet(
            onDismissRequest = { open = false },
            sheetState = sheetState,
            containerColor = colors.bgPrimary,
        ) {
            val heading = title ?: placeholder
            if (heading != null) {
                Text(heading, color = colors.textTertiary, fontSize = 13.sp, fontWeight = FontWeight.Medium,
                    modifier = Modifier.fillMaxWidth().padding(bottom = 6.dp), textAlign = TextAlign.Center)
            }
            Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp)) {
                // month nav
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
                    IconButton(Icons.Outlined.ChevronLeft, "上个月") { viewYm = viewYm.minusMonths(1) }
                    Text("${viewYm.year}年${viewYm.monthValue}月", color = colors.textPrimary, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
                    IconButton(Icons.Outlined.ChevronRight, "下个月") { viewYm = viewYm.plusMonths(1) }
                }
                // weekday row
                Row(Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
                    listOf("日", "一", "二", "三", "四", "五", "六").forEach {
                        Text(it, color = colors.textTertiary, fontSize = 12.sp, textAlign = TextAlign.Center, modifier = Modifier.weight(1f))
                    }
                }
                // day grid
                val lead = viewYm.atDay(1).dayOfWeek.value % 7
                val daysIn = viewYm.lengthOfMonth()
                val cells = (0 until lead).map<Int, Int?> { null } + (1..daysIn).toList()
                val weeks = cells.chunked(7).map { w -> if (w.size < 7) w + List(7 - w.size) { null } else w }
                weeks.forEach { week ->
                    Row(Modifier.fillMaxWidth()) {
                        week.forEach { d ->
                            if (d == null) {
                                Box(Modifier.weight(1f).aspectRatio(1f))
                            } else {
                                val ds = fmt(viewYm.atDay(d))
                                val selected = ds == value
                                val isToday = ds == todayStr
                                val dis = (min != null && ds < min) || (max != null && ds > max)
                                Box(
                                    Modifier.weight(1f).aspectRatio(1f).padding(2.dp)
                                        .clip(RoundedCornerShape(FlareSizes.radiusMd))
                                        .then(if (selected) Modifier.background(Brush.linearGradient(listOf(colors.primary, colors.primaryActive))) else Modifier)
                                        .then(if (isToday && !selected) Modifier.border(1.dp, colors.primary, RoundedCornerShape(FlareSizes.radiusMd)) else Modifier)
                                        .alpha(if (dis) 0.32f else 1f)
                                        .then(if (!dis) Modifier.clickable { onChange?.invoke(ds); open = false } else Modifier),
                                    contentAlignment = Alignment.Center,
                                ) {
                                    Text(
                                        "$d",
                                        color = if (selected) Color.White else if (isToday) colors.primary else colors.textPrimary,
                                        fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
                                        fontSize = 14.sp,
                                    )
                                }
                            }
                        }
                    }
                }
                // footer
                Row(Modifier.fillMaxWidth().padding(vertical = 12.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Box(Modifier.weight(1f)) { Button(label = cancelLabel, variant = FlareButtonVariant.Secondary, block = true, onClick = { open = false }) }
                    Box(Modifier.weight(1f)) { Button(label = todayLabel, variant = FlareButtonVariant.Primary, block = true, onClick = { onChange?.invoke(todayStr); open = false }) }
                }
            }
        }
    }
}
