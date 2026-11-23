package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.disabled
import androidx.compose.ui.semantics.error
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.semantics.isTraversalGroup
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.sp

/**
 * The kind of red packet a composer sends. Spec: RedPacketComposer `kind`.
 *
 * [Lucky] splits a total at random, [Normal] sends the same amount in each share, [Exclusive] goes to one chosen
 * member. The host offers the kinds the conversation allows (a direct chat only has [Normal]).
 */
enum class FlareRedPacketKind { Lucky, Normal, Exclusive }

/**
 * Which part of the composer an error belongs to (RedPacketComposer `errorField` / `focusField`): a field row gets the
 * failed background and the caption under it; [Form] puts the error in a banner above the cards.
 */
enum class FlareRedPacketField(val wire: String) {
    Amount("amount"), Count("count"), Recipient("recipient"), Greeting("greeting"), Form("form");

    companion object {
        fun fromWire(value: String?): FlareRedPacketField? = entries.firstOrNull { it.wire == value }
    }
}

private val redPacketDecimalPoints = setOf('.', '．', '。')

/** An ASCII digit for [ch], full-width digits folded; null for anything else. */
private fun redPacketDigit(ch: Char): Char? = when (ch) {
    in '0'..'9' -> ch
    in '０'..'９' -> '0' + (ch - '０')
    else -> null
}

/** A currency exponent as the composer uses it: a whole number of decimals, 0..12. */
fun flareRedPacketExponent(exponent: Int): Int = exponent.coerceIn(0, 12)

/**
 * The amount field's format (`spec/red-packet-vectors.json` amountInput, amountInputExponent): digits (full-width ones
 * folded) and one decimal point (`.`, `．` or `。`), at most [exponent] digits after it — none at all, the point dropped,
 * for a currency without a minor unit; a leading point gains a zero and leading zeros fold away. Ranges are the host's.
 */
internal fun sanitizeRedPacketAmount(text: String, exponent: Int = 2): String {
    val scale = flareRedPacketExponent(exponent)
    val out = StringBuilder()
    var point = false
    var decimals = 0
    for (ch in text) {
        val digit = redPacketDigit(ch)
        if (digit != null) {
            if (point) {
                if (decimals >= scale) continue
                decimals++
            }
            out.append(digit)
        } else if (ch in redPacketDecimalPoints && !point && scale > 0) {
            point = true
            out.append(if (out.isEmpty()) "0." else ".")
        }
    }
    // Leading zeros before another digit go: "007" is 7, "00.50" is 0.50.
    while (out.length > 1 && out[0] == '0' && out[1].isDigit()) out.deleteCharAt(0)
    return out.toString()
}

/**
 * The composer's amount text in minor units — a string of digits, by integer arithmetic, never floating point ("8.8", 2 →
 * "880"; spec/red-packet-vectors.json amountMinor). Null while the text is not an amount: empty, a lone point, more
 * decimals than [exponent] allows, or anything but ASCII digits and one point.
 */
fun flareRedPacketAmountMinor(text: String, exponent: Int): String? {
    val scale = flareRedPacketExponent(exponent)
    val match = Regex("^([0-9]*)(?:\\.([0-9]*))?$").matchEntire(text.trim()) ?: return null
    val whole = match.groupValues[1]
    val hasPoint = match.groups[2] != null
    val fraction = match.groups[2]?.value.orEmpty()
    if (hasPoint && scale == 0) return null
    if (whole.isEmpty() && fraction.isEmpty()) return null
    if (fraction.length > scale) return null
    return (whole + fraction.padEnd(scale, '0')).trimStart('0').ifEmpty { "0" }
}

/** The count field's format: digits only (full-width folded), at most three after leading zeros; empty is 0. */
internal fun sanitizeRedPacketCount(text: String): Int {
    val digits = StringBuilder()
    for (ch in text) {
        val digit = redPacketDigit(ch) ?: continue
        if (digits.length >= 3 || (digit == '0' && digits.isEmpty())) continue
        digits.append(digit)
    }
    return digits.toString().toIntOrNull() ?: 0
}

// shortcut: §4.2's 24-character greeting has no token or contract field; move it there once one exists.
internal const val RED_PACKET_GREETING_MAX = 24

/** §4.2: the greeting keeps at most [RED_PACKET_GREETING_MAX] characters (code points, as the core counts them). */
internal fun redPacketGreeting(text: String): String =
    if (text.codePointCount(0, text.length) <= RED_PACKET_GREETING_MAX) text
    else text.substring(0, text.offsetByCodePoints(0, RED_PACKET_GREETING_MAX))

/**
 * §4.2: the submit key waits on a zero total or a field error. The total is the host's formatted text, so zero is read
 * from the raw [amount] it is built from: empty or equal to 0 makes every kind's total 0.
 */
internal fun redPacketComposerBlocked(kinds: List<FlareRedPacketKind>, amount: String, exponent: Int, locked: Boolean, fieldError: Boolean): Boolean =
    locked || kinds.isEmpty() || fieldError || amount.isBlank() || flareRedPacketAmountMinor(amount, exponent) == "0"

/** What the count field shows for [count]: nothing for 0. */
internal fun redPacketCountText(count: Int): String = if (count > 0) count.toString() else ""

/** The kind the form shows: [kind], or the first offered one when [kind] is not offered. */
internal fun redPacketShownKind(kind: FlareRedPacketKind, kinds: List<FlareRedPacketKind>): FlareRedPacketKind =
    if (kind in kinds) kind else kinds.firstOrNull() ?: kind

/** A direct chat's composer: the host offers only the normal kind, and a normal packet there has one share. */
internal fun redPacketDirect(kinds: List<FlareRedPacketKind>): Boolean = kinds == listOf(FlareRedPacketKind.Normal)

/** Whether the share-count row is drawn: lucky and normal packets, outside a direct chat. */
internal fun redPacketShowsCount(kind: FlareRedPacketKind, kinds: List<FlareRedPacketKind>): Boolean =
    kind != FlareRedPacketKind.Exclusive && !redPacketDirect(kinds)

/**
 * The amount row's label: the total for lucky, each share's amount for normal, the amount for exclusive and for a
 * direct chat's single share.
 */
internal fun redPacketAmountLabel(kind: FlareRedPacketKind, kinds: List<FlareRedPacketKind>, strings: FlareStrings): String =
    when (kind) {
        FlareRedPacketKind.Lucky -> strings.packetFieldTotal
        FlareRedPacketKind.Normal -> if (redPacketDirect(kinds)) strings.packetFieldAmount else strings.packetFieldEach
        FlareRedPacketKind.Exclusive -> strings.packetFieldAmount
    }

internal fun redPacketKindLabel(kind: FlareRedPacketKind, strings: FlareStrings): String = when (kind) {
    FlareRedPacketKind.Lucky -> strings.packetKindLucky
    FlareRedPacketKind.Normal -> strings.packetKindNormal
    FlareRedPacketKind.Exclusive -> strings.packetKindExclusive
}

/**
 * The send-a-red-packet form: the kind switch, the amount, the share count (lucky and normal), the [recipient] slot
 * (exclusive), the greeting, the host-formatted [total] in large type, the [error] line and the red submit button.
 * Spec: RedPacketComposer (`RedPacketComposer`).
 *
 * - Values come in and changes go out through the `on…Change` callbacks; the host owns the form. The amount field
 *   takes digits and at most [currencyExponent] decimals (whole numbers at 0, with a number keyboard; the placeholder
 *   has that many decimals) through [sanitizeRedPacketAmount], the count field digits ([count] is 0 while empty), as
 *   `spec/red-packet-vectors.json` fixes for every kit. The host turns the amount into minor units with
 *   [flareRedPacketAmountMinor]; a currency with fewer decimals trims what was typed.
 * - The switch shows only when the host offers more than one kind; a [kind] outside [kinds] shows as the first.
 *   The amount's label follows the kind ([redPacketAmountLabel]). The count row is there for lucky and normal, the
 *   recipient row (the host's member picker) for exclusive. A direct chat ([kinds] exactly normal) sends one share:
 *   no count row, and the label is the amount.
 * - The greeting's placeholder is the default greeting the packet carries when nothing is typed.
 * - The submit button is the kit [Button] re-tinted with the deep red; it waits while the amount is empty or 0 and
 *   while a row shows an error ([redPacketComposerBlocked]). The greeting keeps 24 characters. [busy] locks every field
 *   and the button.
 *   [locked] (a sent command whose result is still being checked) makes the form read-only and the button inert
 *   without progress; TalkBack reads the fields and the kind switch as disabled. The host usually explains why in a
 *   status banner above. Place it on the canvas surface: the field groups are drawn on the primary background.
 * - The kind switch marks the chosen kind in `redPacketAccent`.
 */
@Composable
fun RedPacketComposer(
    kinds: List<FlareRedPacketKind>,
    kind: FlareRedPacketKind,
    amount: String,
    total: String,
    modifier: Modifier = Modifier,
    count: Int = 0,
    greeting: String = "",
    error: String? = null,
    busy: Boolean = false,
    locked: Boolean = false,
    submitLabel: String? = null,
    /** The currency's ISO 4217 exponent from the plugin's limits (0 JPY, 2 CNY, 3 KWD). */
    currencyExponent: Int = 2,
    onKindChange: ((FlareRedPacketKind) -> Unit)? = null,
    onAmountChange: ((String) -> Unit)? = null,
    onCountChange: ((Int) -> Unit)? = null,
    onGreetingChange: ((String) -> Unit)? = null,
    onSubmit: (() -> Unit)? = null,
    recipient: (@Composable () -> Unit)? = null,
    /** Which part [error] belongs to: a row (its caption and failed background) or the form (a banner); absent: the form. */
    errorField: FlareRedPacketField? = null,
    /** Moves focus to this field whenever it changes. */
    focusField: FlareRedPacketField? = null,
    /** The currency's symbol before the amount ("¥"); none when absent. */
    currencySymbol: String? = null,
    /** A group's member count: "本群共 n 人" under the count row (groups only). */
    memberCount: Int? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val shown = redPacketShownKind(kind, kinds)
    val amountFocus = remember { FocusRequester() }
    val countFocus = remember { FocusRequester() }
    val greetingFocus = remember { FocusRequester() }
    LaunchedEffect(focusField) {
        when (focusField) {
            FlareRedPacketField.Amount -> amountFocus
            FlareRedPacketField.Count -> countFocus
            FlareRedPacketField.Greeting -> greetingFocus
            else -> null
        }?.let { runCatching { it.requestFocus() } }
    }
    val fieldError = error?.takeIf { it.isNotEmpty() && errorField != null && errorField != FlareRedPacketField.Form }
    val formError = error?.takeIf { it.isNotEmpty() && fieldError == null }
    fun rowError(field: FlareRedPacketField) = fieldError?.takeIf { errorField == field }
    val editable = !busy && !locked && kinds.isNotEmpty()
    val exponent = flareRedPacketExponent(currencyExponent)
    // A currency with fewer decimals (the host switched currency) trims what was typed for the old one.
    LaunchedEffect(exponent) {
        val next = sanitizeRedPacketAmount(amount, exponent)
        if (next != amount) onAmountChange?.invoke(next)
    }
    Column(modifier.fillMaxWidth()) {
    // 4.2: the arch runs the page's full width right under the header, never clipped inside a card.
    RedPacketArch(compact = true)
    Column(
        Modifier.fillMaxWidth().padding(FlareSizes.spacingLg),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingLg),
    ) {
        // A service failure above the cards; the values stay.
        formError?.let { Box(Modifier.fillMaxWidth()) { StatusBanner(text = it, tone = FlareStatusTone.Danger) } }
        if (kinds.size > 1) {
            val shownLabel = redPacketKindLabel(shown, strings)
            SegmentedControl(
                options = kinds.map { redPacketKindLabel(it, strings) },
                selectedIndex = kinds.indexOf(shown).coerceAtLeast(0),
                onSelect = { index ->
                    val next = kinds.getOrNull(index)
                    if (editable && next != null && next != shown) onKindChange?.invoke(next)
                },
                accent = colors.redPacketAccent,
                modifier = Modifier.fillMaxWidth().then(
                    if (editable) {
                        Modifier.semantics {
                            contentDescription = strings.packetKindPicker
                            isTraversalGroup = true
                        }
                    } else {
                        // Read-only: one disabled node that names the chosen kind, and no taps reach the segments.
                        Modifier
                            .clearAndSetSemantics {
                                contentDescription = strings.packetKindPicker
                                stateDescription = shownLabel
                                disabled()
                            }
                            .pointerInput(Unit) {
                                awaitPointerEventScope {
                                    while (true) awaitPointerEvent(PointerEventPass.Initial).changes.forEach { it.consume() }
                                }
                            }
                    },
                ),
            )
        }
        RedPacketFieldGroup {
            RedPacketFieldRow(
                label = redPacketAmountLabel(shown, kinds, strings),
                value = amount,
                placeholder = flareRedPacketAmountText("0", exponent) ?: "0",
                keyboardType = if (exponent > 0) KeyboardType.Decimal else KeyboardType.Number,
                enabled = editable,
                onValueChange = { onAmountChange?.invoke(sanitizeRedPacketAmount(it, exponent)) },
                focus = amountFocus,
                error = rowError(FlareRedPacketField.Amount),
                amount = true,
                prefix = currencySymbol,
                // 4.2: a lucky packet's total leads with its 「拼」 badge.
                badge = strings.packetBadgeLuckyShort.takeIf { shown == FlareRedPacketKind.Lucky },
            )
            if (redPacketShowsCount(shown, kinds)) {
                RedPacketFieldDivider()
                RedPacketFieldRow(
                    label = strings.packetFieldCount,
                    value = redPacketCountText(count),
                    placeholder = strings.packetCountPlaceholder,
                    // 4.2: the count reads with its unit after it ("个"; none in English).
                    suffix = strings.packetCountUnit.takeIf { it.isNotEmpty() },
                    keyboardType = KeyboardType.Number,
                    enabled = editable,
                    onValueChange = { onCountChange?.invoke(sanitizeRedPacketCount(it)) },
                    focus = countFocus,
                    error = rowError(FlareRedPacketField.Count),
                )
            }
            if (shown == FlareRedPacketKind.Exclusive) {
                RedPacketFieldDivider()
                val recipientError = rowError(FlareRedPacketField.Recipient)
                Row(
                    Modifier.fillMaxWidth().heightIn(min = FlareSizes.componentRedPacketFormRowHeight)
                        .background(if (recipientError != null) colors.messageFailedBackground else androidx.compose.ui.graphics.Color.Transparent)
                        .padding(horizontal = FlareSizes.spacingLg),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
                ) {
                    Text(strings.packetFieldRecipient, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl)
                    Box(Modifier.weight(1f), contentAlignment = Alignment.CenterEnd) { recipient?.invoke() }
                }
                recipientError?.let { RedPacketRowError(it) }
            }
        }
        memberCount?.takeIf { it > 0 && !redPacketDirect(kinds) }?.let { count ->
            Text(strings.packetGroupMembers.replace("{count}", count.toString()), color = colors.textTertiary,
                fontSize = FlareTextRoles.Caption.fontSize, modifier = Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg))
        }
        RedPacketFieldGroup {
            RedPacketGreetingField(greeting, enabled = editable, onValueChange = { onGreetingChange?.invoke(redPacketGreeting(it)) }, focus = greetingFocus)
            rowError(FlareRedPacketField.Greeting)?.let { RedPacketRowError(it) }
        }
        Text(
            total, color = colors.textPrimary,
            fontSize = (if (flareCompactOverlays()) FlareSizes.componentRedPacketAmountFontSize else FlareSizes.componentRedPacketAmountFontSizeWide).value.sp,
            fontWeight = FontWeight.SemiBold, style = FlareTabularFigures, maxLines = 1, modifier = Modifier.padding(top = FlareSizes.spacingLg),
        )
        Box(Modifier.padding(top = FlareSizes.spacingSm).fillMaxWidth()) {
            RedPacketMoneyTint {
                Button(
                    label = submitLabel ?: strings.packetSubmit, variant = FlareButtonVariant.Primary,
                    size = FlareControlSize.Lg, loading = busy, block = true, onClick = onSubmit,
                    disabled = redPacketComposerBlocked(kinds, amount, exponent, locked, fieldError != null),
                )
            }
        }
        Text(strings.packetRefundNotice, color = colors.textTertiary, fontSize = FlareTextRoles.Caption.fontSize, textAlign = TextAlign.Center)
    }
    }
}

/** A row's error under it (4.2): the caption in the error ink, announced politely. */
@Composable
private fun RedPacketRowError(text: String) {
    val colors = flareColors()
    Text(
        text, color = colors.errorText, fontSize = FlareTextRoles.Caption.fontSize,
        modifier = Modifier.fillMaxWidth().background(colors.messageFailedBackground)
            .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingXs)
            .semantics { liveRegion = LiveRegionMode.Polite },
    )
}

@Composable
private fun RedPacketFieldGroup(content: @Composable ColumnScope.() -> Unit) {
    Column(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusCard)).background(flareColors().bgPrimary),
        content = content,
    )
}

@Composable
private fun RedPacketFieldDivider() {
    HorizontalDivider(
        Modifier.padding(start = FlareSizes.spacingLg),
        thickness = RedPacketMetrics.hairline,
        color = flareColors().borderSecondary,
    )
}

/** A label leading and the field trailing; a tap anywhere on the row focuses the field, which carries the label. */
@Composable
private fun RedPacketFieldRow(
    label: String,
    value: String,
    placeholder: String,
    keyboardType: KeyboardType,
    enabled: Boolean,
    onValueChange: (String) -> Unit,
    focus: FocusRequester = remember { FocusRequester() },
    error: String? = null,
    /** The amount: 18/600 tabular figures (4.2). */
    amount: Boolean = false,
    /** Drawn before the value (the currency symbol). */
    prefix: String? = null,
    /** A small badge before the label (the lucky packet's 「拼」). */
    badge: String? = null,
    /** Drawn after the value (the count's unit). */
    suffix: String? = null,
) {
    val colors = flareColors()
    Row(
        Modifier.fillMaxWidth().heightIn(min = FlareSizes.componentRedPacketFormRowHeight)
            .background(if (error != null) colors.messageFailedBackground else androidx.compose.ui.graphics.Color.Transparent)
            .pointerInput(enabled) { detectTapGestures { if (enabled) runCatching { focus.requestFocus() } } }
            .padding(horizontal = FlareSizes.spacingLg),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
    ) {
        badge?.let {
            // Vue `.flare-rp-composer__badge`: the accent on its weak tint, sm semibold, radius sm.
            Text(it, color = colors.redPacketAccent, fontSize = FlareSizes.fontSizeSm, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.clip(RoundedCornerShape(FlareSizes.radiusSm))
                    .background(colors.redPacketAccent.copy(alpha = FlareOpacity.tintWeak))
                    .padding(horizontal = FlareSizes.spacing2xs).clearAndSetSemantics {})
        }
        Text(label, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, modifier = Modifier.clearAndSetSemantics {})
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            enabled = enabled,
            singleLine = true,
            textStyle = TextStyle(color = colors.textPrimary, fontSize = if (amount) FlareSizes.fontSize3xl else FlareSizes.fontSizeXl,
                fontWeight = if (amount) FontWeight.SemiBold else null, fontFeatureSettings = if (amount) "tnum" else null, textAlign = TextAlign.End),
            cursorBrush = SolidColor(colors.primary),
            keyboardOptions = KeyboardOptions(keyboardType = keyboardType, imeAction = ImeAction.Next),
            modifier = Modifier.weight(1f).focusRequester(focus).semantics {
                contentDescription = label
                error?.let { this.error(it) }
            },
            decorationBox = { inner ->
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.End) {
                    prefix?.let {
                        Text(it, color = colors.textPrimary, fontSize = if (amount) FlareSizes.fontSize3xl else FlareSizes.fontSizeXl,
                            fontWeight = if (amount) FontWeight.SemiBold else null, modifier = Modifier.padding(end = FlareSizes.spacing3xs).clearAndSetSemantics {})
                    }
                    Box(Modifier.weight(1f, fill = false), contentAlignment = Alignment.CenterEnd) {
                        if (value.isEmpty()) {
                            Text(placeholder, color = colors.textTertiary, fontSize = FlareSizes.fontSizeXl, textAlign = TextAlign.End,
                                modifier = Modifier.clearAndSetSemantics {})
                        }
                        inner()
                    }
                    suffix?.let {
                        Text(it, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl,
                            modifier = Modifier.padding(start = FlareSizes.spacing3xs).clearAndSetSemantics {})
                    }
                }
            },
        )
    }
    error?.let { RedPacketRowError(it) }
}

@Composable
private fun RedPacketGreetingField(value: String, enabled: Boolean, onValueChange: (String) -> Unit, focus: FocusRequester = remember { FocusRequester() }) {
    val colors = flareColors()
    val strings = flareStrings()
    Box(
        Modifier.fillMaxWidth().heightIn(min = FlareSizes.componentRedPacketFormRowHeight)
            .pointerInput(enabled) { detectTapGestures { if (enabled) runCatching { focus.requestFocus() } } }
            .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd),
        contentAlignment = Alignment.CenterStart,
    ) {
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            enabled = enabled,
            maxLines = 3,
            textStyle = TextStyle(color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl),
            cursorBrush = SolidColor(colors.primary),
            modifier = Modifier.fillMaxWidth().focusRequester(focus).semantics { contentDescription = strings.packetGreetingLabel },
            decorationBox = { inner ->
                Box {
                    if (value.isEmpty()) {
                        Text(strings.packetDefaultGreeting, color = colors.textTertiary, fontSize = FlareSizes.fontSizeXl,
                            modifier = Modifier.clearAndSetSemantics {})
                    }
                    inner()
                }
            },
        )
    }
}
