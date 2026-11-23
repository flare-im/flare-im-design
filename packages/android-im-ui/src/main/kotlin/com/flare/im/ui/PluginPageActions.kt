package com.flare.im.ui

import androidx.compose.animation.core.animateFloat
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp

// The places of R2 (docs/plugin-experience.md) drawn with kit parts: key rows (Button), list cards (SettingsRow), the
// danger card, the task bar, the status card of 6.1 and the field rows of R3 (Tags, folded references).

/** A section title (`textRole.section`, secondary): a heading, never brand coloured (R1). */
@Composable
internal fun PluginSectionTitle(text: String, modifier: Modifier = Modifier) {
    Text(
        text, color = flareColors().textSecondary, fontSize = FlareTextRoles.Section.fontSize,
        fontWeight = FlareTextRoles.Section.fontWeight, modifier = modifier.semantics { heading() },
    )
}

/** The card surface the list places sit on: `radius.card`, the primary surface and a hairline edge. */
@Composable
internal fun Modifier.pluginListCard(): Modifier {
    val colors = flareColors()
    val shape = RoundedCornerShape(FlareSizes.radiusCard)
    return fillMaxWidth().clip(shape).background(colors.bgPrimary).border(1.dp, colors.borderSecondary, shape)
}

/**
 * One list card of actions (R2.1 list, more): a kit settings row per action, the label always in the primary text
 * colour, the action's icon in the leading slot (none, no gap), chevron-right only on a destination.
 */
@Composable
internal fun PluginActionListCard(
    title: String?,
    actions: List<PluginViewAction>,
    disabled: Boolean,
    onRun: (PluginViewAction) -> Unit,
    busyActionId: String? = null,
) {
    if (actions.isEmpty()) return
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
        title?.let { PluginSectionTitle(it) }
        Column(Modifier.pluginListCard()) {
            actions.forEachIndexed { index, action ->
                if (index > 0) FlareGroupedCardDivider()
                SettingsRow(
                    item = SettingsItem(
                        key = action.id, label = action.label, icon = action.icon,
                        kind = if (pluginActionChevron(action)) FlareSettingKind.Navigation else FlareSettingKind.Action,
                        // R2.5: an action that cannot run now says why under its label.
                        disabled = (disabled && busyActionId != action.id) || action.disabledReason != null,
                        description = action.disabledReason,
                        // The running row spins in place of its chevron.
                        loading = busyActionId == action.id,
                    ),
                    onSelect = { onRun(action) },
                )
            }
        }
    }
}

/** The danger card (R2.1): one centred row per action in the error colour, no chevron; the run asks DangerConfirm. */
@Composable
internal fun PluginDangerCard(actions: List<PluginViewAction>, disabled: Boolean, onRun: (PluginViewAction) -> Unit) {
    if (actions.isEmpty()) return
    val colors = flareColors()
    Column(Modifier.pluginListCard()) {
        actions.forEachIndexed { index, action ->
            if (index > 0) FlareGroupedCardDivider()
            val off = disabled || action.disabledReason != null
            Column(
                Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget)
                    .flareDimmed(if (off) FlareOpacity.disabled else 1f)
                    .clickable(enabled = !off, role = Role.Button) { onRun(action) }
                    .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                // R2.1 / §12.3: the danger row's words are `color.error`.
                Text(action.label, color = colors.errorText, fontSize = FlareSizes.fontSizeLg, textAlign = TextAlign.Center)
                action.disabledReason?.let { PluginCaption(it, align = TextAlign.Center) }
            }
        }
    }
}

/**
 * A key of a place: primary solid, danger, or the secondary key; [quiet] draws the quiet text key of the task bar and
 * [secondary] the secondary key whatever the style (a command row has no solid key, R2.2 / R2.3).
 */
@Composable
internal fun PluginPlaceKey(
    action: PluginViewAction,
    size: FlareControlSize,
    busyActionId: String?,
    disabled: Boolean,
    block: Boolean,
    quiet: Boolean = false,
    secondary: Boolean = false,
    onRun: (PluginViewAction) -> Unit,
) {
    val reason = action.disabledReason
    if (reason != null) {
        // R2.5: the key waits and its reason reads under it.
        Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
            PluginPlaceKey(action.copy(disabledReason = null), size, busyActionId, disabled = true, block = block, quiet = quiet, secondary = secondary, onRun = onRun)
            PluginCaption(reason, align = if (block) TextAlign.Center else TextAlign.Start)
        }
        return
    }
    Button(
        label = action.label,
        variant = when {
            quiet -> FlareButtonVariant.Quiet
            secondary && action.style != PluginActionStyle.Danger -> FlareButtonVariant.Secondary
            action.style == PluginActionStyle.Primary -> FlareButtonVariant.Primary
            action.style == PluginActionStyle.Danger -> FlareButtonVariant.Danger
            else -> FlareButtonVariant.Secondary
        },
        size = size,
        loading = busyActionId == action.id,
        disabled = disabled && busyActionId != action.id,
        block = block,
        maintainTouchTarget = true,
        onClick = { onRun(action) },
    )
}

/**
 * The overview's quick row (R2.1), at the bottom of the overview card: on a phone equal widths 48 high, else natural
 * widths of at least `component.actionMinWidth`, 40 high, from the start.
 */
@Composable
internal fun PluginQuickKeys(
    actions: List<PluginViewAction>,
    phone: Boolean,
    busyActionId: String?,
    disabled: Boolean,
    caption: String?,
    onRun: (PluginViewAction) -> Unit,
) {
    if (actions.isEmpty()) return
    Column(Modifier.fillMaxWidth().padding(top = FlareSizes.spacingLg), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
            actions.forEach { action ->
                // Wide: each key its own width (at least actionMinWidth) — a block key in an unsized box took the whole row.
                Box(if (phone) Modifier.weight(1f) else Modifier.width(androidx.compose.foundation.layout.IntrinsicSize.Max).widthIn(min = FlareSizes.componentActionMinWidth)) {
                    PluginPlaceKey(action, if (phone) FlareControlSize.Lg else FlareControlSize.Md, busyActionId, disabled, block = true, onRun = onRun)
                }
            }
        }
        caption?.let { PluginCaption(it) }
    }
}

/** A `textRole.caption` line in the secondary colour (an offline note, why a key waits). */
@Composable
internal fun PluginCaption(text: String, modifier: Modifier = Modifier, align: TextAlign = TextAlign.Start) {
    Text(
        text, color = flareColors().textSecondary, fontSize = FlareTextRoles.Caption.fontSize, textAlign = align,
        modifier = modifier.fillMaxWidth(),
    )
}

/**
 * A row of keys after the body: [lead] as its role draws it (a task's primary on a wide window), then [rest] as
 * secondary keys (records commands, a task's other keys) — one solid key per screen at most (R2.2 / R2.3).
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun PluginKeyRow(
    lead: List<PluginViewAction>,
    rest: List<PluginViewAction>,
    busyActionId: String?,
    disabled: Boolean,
    caption: String?,
    onRun: (PluginViewAction) -> Unit,
) {
    if (lead.isEmpty() && rest.isEmpty()) return
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
        ) {
            (lead + rest).forEach { action ->
                Box(Modifier.widthIn(min = FlareSizes.componentActionMinWidth)) {
                    PluginPlaceKey(action, FlareControlSize.Md, busyActionId, disabled, block = true, secondary = action in rest, onRun = onRun)
                }
            }
        }
        caption?.let { PluginCaption(it) }
    }
}

/**
 * The task bar (R2.2) on a phone: pinned over the navigation bar on the primary surface with a hairline on top; the
 * quiet keys (at most 2) above the full-width 48 high primary.
 */
@Composable
internal fun PluginTaskBar(
    primary: PluginViewAction?,
    secondary: List<PluginViewAction>,
    busyActionId: String?,
    disabled: Boolean,
    primaryDisabled: Boolean,
    caption: String?,
    onRun: (PluginViewAction) -> Unit,
) {
    if (primary == null && secondary.isEmpty()) return
    val colors = flareColors()
    Column(
        Modifier.fillMaxWidth().background(colors.bgPrimary).windowInsetsPadding(WindowInsets.navigationBars),
    ) {
        Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderSecondary))
        Column(
            Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
        ) {
            if (secondary.isNotEmpty()) Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                secondary.forEach { action ->
                    Box(Modifier.weight(1f)) { PluginPlaceKey(action, FlareControlSize.Md, busyActionId, disabled, block = true, quiet = true, onRun = onRun) }
                }
            }
            primary?.let { PluginPlaceKey(it, FlareControlSize.Lg, busyActionId, disabled || primaryDisabled, block = true, onRun = onRun) }
            caption?.let { PluginCaption(it, align = TextAlign.Center) }
        }
    }
}

/** A resolved value as R3 draws it: the kit Tag for a tone (the unknown status when unmapped), else its text. */
@Composable
internal fun PluginStatusValue(
    value: String,
    format: PluginValueFormat?,
    tone: PluginTone?,
    unmapped: Boolean,
    strings: FlareStrings,
    align: TextAlign = TextAlign.Start,
    warnKey: String? = null,
) {
    val context = LocalContext.current
    // R3: the warning names the plugin and page (the page provides them), the path and the raw value.
    val scope = LocalPluginWarnScope.current.orEmpty()
    when (val draw = pluginStatusDraw(PluginFormatRules.text(value, format, strings), tone, unmapped, strings)) {
        is PluginStatusDraw.Tag -> {
            if (draw.unknown) PluginDevWarnings.warn(context, "unmapped:$scope:${warnKey.orEmpty()}:$value",
                "A plugin value outside its declared values: $scope ${warnKey.orEmpty()} = $value")
            PluginBadgeTag(PluginBadge(draw.text, draw.tone))
        }
        is PluginStatusDraw.Text -> Text(draw.text, color = flareColors().textPrimary, fontSize = FlareSizes.fontSizeLg,
            textAlign = align, style = if (format is PluginValueFormat.Money) FlareTabularFigures else androidx.compose.material3.LocalTextStyle.current)
    }
}

/**
 * Label/value rows of a view (R3): a toned value is a Tag, an unmapped one the unknown status; reference fields fold
 * into one "References" group after the others, each with a copy key named "copy" and the field's label.
 */
@Composable
internal fun PluginFieldList(fields: List<PluginViewField>, warnScope: String) {
    val colors = flareColors()
    val strings = flareStrings()
    val (main, references) = remember(fields) { pluginSplitReferences(fields) }
    var open by remember(fields) { mutableStateOf(false) }
    val clipboard = LocalClipboardManager.current
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
        main.forEach { field ->
            Row(
                Modifier.fillMaxWidth().semantics(mergeDescendants = true) {},
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
            ) {
                Text(field.label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg, modifier = Modifier.widthIn(min = 56.dp))
                Box(Modifier.weight(1f)) {
                    PluginStatusValue(field.value, field.format, field.tone, field.unmapped, strings, warnKey = "$warnScope/${field.label}")
                }
            }
        }
        if (references.isNotEmpty()) {
            Row(
                Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTargetMin)
                    .clickable(role = Role.Button) { open = !open }
                    .semantics { stateDescription = if (open) strings.collapse else strings.expand },
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(strings.pluginViewReferences, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd,
                    fontWeight = FontWeight.Medium, modifier = Modifier.weight(1f))
                FlareIcon(if (open) "chevron-down" else "chevron-right", size = FlareSizes.iconSizeSm, tint = colors.textTertiary)
            }
            if (open) references.forEach { field ->
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                    Column(Modifier.weight(1f).semantics(mergeDescendants = true) {}) {
                        Text(field.label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
                        Text(field.value, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd, maxLines = 2, overflow = TextOverflow.Ellipsis)
                    }
                    IconButton(icon = "copy", contentDescription = strings.pluginViewCopyReference.replace("{label}", field.label), size = FlareControlSize.Sm,
                        onClick = { clipboard.setText(AnnotatedString((field.format as? PluginValueFormat.Reference)?.id ?: field.value)) })
                }
            }
        }
    }
}

/**
 * The status card (6.1): a tone icon 48 in its circle, the status as the title (`textRole.title`), the description,
 * the steps across and the card's key (the page's first primary).
 */
@Composable
internal fun PluginStatusCard(
    parts: PluginStatusCardParts,
    key: PluginViewAction?,
    busyActionId: String?,
    disabled: Boolean,
    caption: String?,
    onRun: (PluginViewAction) -> Unit,
) {
    val colors = flareColors()
    Column(
        Modifier.pluginListCard().padding(FlareSizes.spacingLg),
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
            Box(
                Modifier.size(48.dp).clip(CircleShape).background(pluginToneFill(parts.tone).copy(alpha = FlareOpacity.tintWeak)),
                contentAlignment = Alignment.Center,
            ) { FlareIcon(pluginStatusCardIcon(parts.tone, parts.unmapped), size = FlareSizes.iconSizeLg, tint = pluginToneText(parts.tone)) }
            Column(Modifier.weight(1f).semantics(mergeDescendants = true) {}, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                Text(parts.title, color = colors.textPrimary, fontSize = FlareTextRoles.Title.fontSize, fontWeight = FlareTextRoles.Title.fontWeight,
                    modifier = Modifier.semantics { heading() })
                parts.description?.let { Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg) }
            }
        }
        parts.steps?.let { PluginStepsBlockView(it) }
        key?.let {
            PluginPlaceKey(it, FlareControlSize.Lg, busyActionId, disabled, block = true, onRun = onRun)
            caption?.let { text -> PluginCaption(text, align = TextAlign.Center) }
        }
    }
}

/** The compact empty state of an empty data block (R8) with the page's create action under it. */
@Composable
internal fun PluginBlockEmpty(text: String, icon: String, create: PluginViewAction?, busyActionId: String?, disabled: Boolean, onRun: (PluginViewAction) -> Unit) {
    EmptyState(
        title = text, icon = icon, compact = true,
        actions = if (create == null) null else ({ PluginPlaceKey(create, FlareControlSize.Md, busyActionId, disabled, block = false, onRun = onRun) }),
    )
}

/** The 2-high refresh bar under the header (R1): indeterminate, or a still half bar under reduced motion. */
@Composable
internal fun PluginRefreshBar(visible: Boolean) {
    if (!visible) return
    val colors = flareColors()
    val label = flareStrings().loading
    val still = flareReducedMotion()
    // §12.8: a half bar sweeping across once every 1.2 s; under reduced motion it holds still at the start.
    val sweep = if (still) 0f else androidx.compose.animation.core.rememberInfiniteTransition(label = "plugin-refresh").animateFloat(
        initialValue = -0.5f, targetValue = 1f,
        animationSpec = androidx.compose.animation.core.infiniteRepeatable(
            androidx.compose.animation.core.tween(FlareMotion.refreshLoop, easing = FlareMotion.refreshLoopEasing),
        ),
        label = "plugin-refresh-sweep",
    ).value
    androidx.compose.foundation.layout.BoxWithConstraints(
        Modifier.fillMaxWidth().height(2.dp).background(colors.bgSecondary).clipToBounds().semantics { contentDescription = label },
    ) {
        Box(Modifier.offset(x = maxWidth * sweep).fillMaxWidth(0.5f).height(2.dp).background(colors.primary))
    }
}


/**
 * A page form (R6): a long form, or one with files, documents or members, as a whole page over the current one — the
 * action's label as the title, the form scrolling, and the task bar (R2.2) pinned over the navigation bar with the
 * submit; the header's back key closes it. While [pending] the page cannot be closed (back does nothing).
 */
@Composable
internal fun PluginPageForm(
    title: String,
    submitLabel: String,
    pending: Boolean,
    submitState: PluginFormSubmitState,
    onClose: () -> Unit,
    onSubmit: () -> Unit,
    content: @Composable () -> Unit,
) {
    val colors = flareColors()
    androidx.compose.ui.window.Dialog(
        onDismissRequest = { if (!pending) onClose() },
        properties = androidx.compose.ui.window.DialogProperties(
            usePlatformDefaultWidth = false, decorFitsSystemWindows = false,
            dismissOnBackPress = !pending, dismissOnClickOutside = false,
        ),
    ) {
        // Under the bars, with the keyboard as an inset: the bar's submit stays on screen above it.
        FlareEdgeToEdgeDialogWindow()
        FlareScreen(title = title, onBack = { if (!pending) onClose() }, scroll = false,
            contentMaxWidth = FlareSizes.componentFormColumnWidth) {
            Column(Modifier.fillMaxWidth()) {
                Column(
                    Modifier.weight(1f).fillMaxWidth().verticalScroll(androidx.compose.foundation.rememberScrollState())
                        .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd),
                ) { content() }
                Column(Modifier.fillMaxWidth().background(colors.bgPrimary).windowInsetsPadding(WindowInsets.navigationBars)) {
                    Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderSecondary))
                    Column(
                        Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd),
                        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
                    ) {
                        // R6: a page form ends with the R2.2 bar — the full-width 48 submit; the header's back closes it.
                        Button(label = submitLabel, size = FlareControlSize.Lg, loading = pending,
                            disabled = !submitState.enabled, block = true, onClick = onSubmit)
                        submitState.caption?.let { PluginCaption(it, align = TextAlign.Center) }
                    }
                }
            }
        }
    }
}

/** Tabular figures for amounts, durations and countdowns (0.1 of docs/plugin-experience.md). */
internal val FlareTabularFigures: androidx.compose.ui.text.TextStyle
    @Composable get() = androidx.compose.material3.LocalTextStyle.current.merge(androidx.compose.ui.text.TextStyle(fontFeatureSettings = "tnum"))

/** What a ledger row records (5.8): money in, money out, or a move between the viewer's own wallets. */
internal enum class PluginLedgerKind { Income, Expense, Internal }

/** A signed amount says the kind: "+" in, "-" or "−" out, unsigned internal. */
internal fun pluginLedgerKind(amount: String): PluginLedgerKind {
    val text = amount.trimStart()
    return when {
        text.startsWith("+") -> PluginLedgerKind.Income
        text.startsWith("-") || text.startsWith("\u2212") -> PluginLedgerKind.Expense
        else -> PluginLedgerKind.Internal
    }
}

/** R10: spending reads with the minus sign (U+2212), never a hyphen. */
internal fun pluginSignedAmount(amount: String): String {
    val lead = amount.length - amount.trimStart().length
    return if (amount.getOrNull(lead) == '-') amount.substring(0, lead) + "\u2212" + amount.substring(lead + 1) else amount
}

/** §12.24 (rules.rowsIcon): only a block that declares an icon draws its rows as records; the kit never guesses a ledger. */
internal fun pluginRowsAreRecords(block: PluginRowsBlock): Boolean = block.icon != null

/** A ledger line's words (5.8, spec rules.rowsIcon): the title and the line under it, the value at the end, its Tags. */
internal data class PluginLedgerLine(val title: String, val line: String?, val value: String, val tags: List<PluginRowCell>)

/**
 * [row] as a ledger line: the first cell is the value, toned or unmapped cells are its Tags (a completed status stays
 * quiet), the second cell titles it and the others make the line under the title.
 */
internal fun pluginLedgerLine(block: PluginRowsBlock, row: PluginRow, nowMs: Long, strings: FlareStrings): PluginLedgerLine {
    val tagged = row.cells.withIndex().filter { (i, cell) -> i > 0 && (cell.tone != null || cell.unmapped) }.map { it.index }.toSet()
    val rest = tagged + 0
    val lines = PluginViewFormat.rowLines(block.copy(columns = block.columns.filterIndexed { i, _ -> i !in rest }),
        row.copy(cells = row.cells.filterIndexed { i, _ -> i !in rest }), nowMs, strings, null)
    return PluginLedgerLine(
        title = lines.primary,
        line = lines.secondary,
        value = row.cells.firstOrNull()?.let { PluginFormatRules.text(it.text, it.format, strings) }.orEmpty(),
        tags = tagged.sorted().map { row.cells[it] }.filter { it.unmapped || it.tone != PluginTone.Success },
    )
}

/**
 * The 36 circle a ledger row leads with (5.8): in on the success tint, out and internal on the neutral one.
 * shortcut: recharge (add) and withdraw (download) need a declared row kind the protocol does not carry yet; until then
 * only a row's or block's own `icon` draws them.
 */
@Composable
internal fun PluginLedgerIcon(kind: PluginLedgerKind, icon: String? = null) {
    val colors = flareColors()
    val income = kind == PluginLedgerKind.Income
    Box(
        Modifier.size(FlareSizes.componentRecordIconSize).clip(CircleShape).background(if (income) colors.success.copy(alpha = FlareOpacity.tintWeak) else colors.bgTertiary),
        contentAlignment = Alignment.Center,
    ) {
        FlareIcon(pluginLedgerIconName(kind, icon), size = FlareSizes.iconSizeMd, tint = if (income) colors.successText else colors.textSecondary)
    }
}

/** The glyph in a ledger row's circle: the declared [icon] when the kit knows it, else the one of the value's sign (rules.rowsIcon). */
internal fun pluginLedgerIconName(kind: PluginLedgerKind, icon: String?): String =
    icon?.trim()?.takeIf { flareIconVectorOrNull(it) != null } ?: when (kind) {
        PluginLedgerKind.Income -> "arrow-down"
        PluginLedgerKind.Expense -> "send"
        PluginLedgerKind.Internal -> "refresh"
    }
