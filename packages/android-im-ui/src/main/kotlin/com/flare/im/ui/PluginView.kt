package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.progressBarRangeInfo
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay

/**
 * Plugin card — the core SDK's resolved plugin view drawn as a kit business card. Spec: Message/PluginView
 * (`PluginView`). Render facts follow `spec/plugin-view-vectors.json`.
 *
 * No plugin code, path or URL is executed: actions go out as opaque ids with the viewer's selection or form values
 * ([onAction] (id, payload)) and the host invokes them.
 * - Shell: card width `componentRichCardWidth` (within the parent), radius lg, a hairline border and the card shadow; the
 *   title row carries [icon] (a kit icon name). [embedded] drops the shell and the title row (the detail sheet);
 *   [inset] [PluginViewInset.Sheet] pads the view like [PluginForm] (spacing md on top, lg at the sides, xl at the
 *   bottom), so it goes straight into a kit [BottomSheet], and [PluginViewInset.SheetTop] does the same without the bottom
 *   inset for a view with more of the sheet under it (a preface above the form). The inset pads every state: the embedded
 *   body, available or not, and a card shell kept in a sheet (around it). `available` false shows only the title
 *   (embedded, which has no title row: as one line of secondary text).
 * - Actions: style danger → the danger key, primary → the primary key, else the secondary key. `confirm` asks in the kit
 *   [DangerConfirm] first; `form` collects [PluginForm] in the kit [BottomSheet], whose submit emits
 *   `onAction(id, PluginActionPayload(formValues = …))`.
 * - Choices: a single choice submits on tap; a multiple choice toggles a draft submitted by a key named after the block's
 *   action. The submitted options show at once and revert when [error] turns non-empty; a new [view] settles them.
 * - Settling: the host increments [settleToken] once per finished action, after setting that result's [error] and
 *   [formErrors]. A clean result closes the submitted form and keeps an optimistic choice marked until the new view; an
 *   error reverts the choice (an open form stays and shows it); form errors keep the form open with them (a choice it
 *   carries reverts). [busyActionId] leaving the action settles the same way as a fallback; a host that sets and clears
 *   it within one frame settles only through the token.
 * - [busy] disables everything; [busyActionId] too, and spins that action's key. [error] shows at the card's foot.
 * - People and entries name users through [resolveUser]; without an answer the avatar draws initials and the name is the
 *   id's last 4 characters. "See all" (entries with more) calls [onOpenDetail]; the host opens [PluginDetailSheet]. A
 *   view with a detail that no entries block offers gets a full-width quiet "view details" key under the action keys
 *   (not embedded, and only with [onOpenDetail]), disabled while busy.
 * - Time is formatted in the device zone (`pluginViewDateTimeFormat`); a countdown redraws every second under an hour and
 *   every minute otherwise.
 * - Protocol v2 (spec/plugin-view-vectors.json rules.menuActions, entriesGrouped, unavailableReason, shell): the view's
 *   `menuActions` open from a ⋯ key at the end of the title row (an embedded view draws them as keys after its
 *   actions) and run exactly like a key — confirm, then form, then the action. A grouped entries block puts a header row
 *   ("火锅 · 3 票 · 38%") before each group and tags the [viewerId]'s row "me". `unavailableReason` adds its line under
 *   the title, led by [displayName]; a read-only copy (`unbound_copy`) keeps its content, acts on nothing and closes with
 *   its own line.
 * - The shell is the message's card surface: the timeline draws no bubble around it. A quoted reply goes in the shell's
 *   [quote] slot, above the title row (a card message row passes its quote by itself).
 */
@Composable
fun PluginView(
    view: PluginViewModel,
    icon: String? = null,
    busy: Boolean = false,
    busyActionId: String? = null,
    error: String? = null,
    embedded: Boolean = false,
    /** Where the view sits: none, the bottom sheet's insets ([PluginForm]'s), or those without the bottom one. */
    inset: PluginViewInset = PluginViewInset.None,
    resolveUser: (suspend (String) -> PluginUser?)? = null,
    members: List<PluginMember> = emptyList(),
    formErrors: List<PluginFormError> = emptyList(),
    /** The host's settle signal: incremented once per finished action, after that result's [error] / [formErrors]. */
    settleToken: Int = 0,
    /** The card envelope's displayName (the plugin's name), leading the unavailable reason line. */
    displayName: String? = null,
    /** The viewer's user id: entries of that user carry the "me" tag. */
    viewerId: String? = null,
    /** A quoted reply drawn inside the shell, above the title row; a card message row passes its own. */
    quote: (@Composable () -> Unit)? = LocalFlareCardQuote.current,
    onAction: ((String, PluginActionPayload) -> Unit)? = null,
    onOpenDetail: (() -> Unit)? = null,
) {
    // A read-only copy acts on nothing, whatever the host passed.
    val onAction = onAction.takeUnless { PluginViewFormat.readOnly(view) }
    val onOpenDetail = onOpenDetail.takeUnless { PluginViewFormat.readOnly(view) }
    val colors = flareColors()
    val strings = flareStrings()
    var menuOpen by remember { mutableStateOf(false) }
    val menuActions = PluginViewFormat.menuActions(view)
    val reasonLine = PluginViewFormat.reasonLine(view, displayName, strings)
    var interaction by remember { mutableStateOf(PluginChoicesInteraction()) }
    var users by remember { mutableStateOf<Map<String, PluginUser>>(emptyMap()) }
    var confirming by remember { mutableStateOf<PluginActionRun?>(null) }
    var formRun by remember { mutableStateOf<PluginActionRun?>(null) }
    var formSubmitted by remember { mutableStateOf(false) }
    val locked = busy || busyActionId != null
    val failure = error?.takeIf { it.isNotEmpty() }
    val formPending = formRun?.let { busy || busyActionId == it.action.id } ?: false
    val emitAction by rememberUpdatedState(onAction)

    // A new view is the truth.
    PluginOnChange(view) { _, _ -> interaction = interaction.viewChanged() }
    // The host's signals compared whole, so an error set in the same frame as the settle is read: a failure reverts the
    // optimistic choice; a settle closes the submitted form unless it came back with errors.
    PluginOnChange(PluginHostSignal(busy, busyActionId, error, formErrors, settleToken)) { old, new ->
        interaction = interaction.hostChanged(old, new)
        val request = formRun
        if (request != null && formSubmitted && pluginFormSettle(old, new, request.action.id) == PluginFormSettle.Close) {
            formRun = null
            formSubmitted = false
        }
    }
    val ids = PluginViewFormat.userIds(view)
    LaunchedEffect(ids, resolveUser) {
        val resolve = resolveUser ?: return@LaunchedEffect
        val found = pluginResolvedUsers(ids, users, resolve)
        if (found.isNotEmpty()) users = users + found
    }

    fun emit(request: PluginActionRun, formValues: Map<String, Any?>?) {
        val payload = if (formValues != null) request.payload.copy(formValues = formValues) else request.payload
        val selection = payload.selection
        if (request.block != null && selection != null) {
            interaction = interaction.submitted(request.block, request.action.id, selection)
        }
        emitAction?.invoke(request.action.id, payload)
    }

    fun proceed(request: PluginActionRun) {
        if (!request.action.form.isNullOrEmpty()) {
            formSubmitted = false
            formRun = request
        } else {
            emit(request, null)
        }
    }

    /** Confirm, then collect the form, then hand the action over. */
    fun run(action: PluginViewAction, payload: PluginActionPayload, block: Int? = null) {
        if (locked || emitAction == null) return
        val request = PluginActionRun(action, payload, block)
        if (!action.confirm.isNullOrEmpty()) confirming = request else proceed(request)
    }

    val shape = RoundedCornerShape(FlareSizes.radiusLg)
    // Every state takes the inset; a card shell kept in a sheet takes it around the shell.
    val shell = if (embedded) Modifier.fillMaxWidth().padding(pluginViewInsetPadding(inset)) else Modifier
        .padding(pluginViewInsetPadding(inset))
        .widthIn(max = FlareSizes.componentRichCardWidth)
        .fillMaxWidth()
        .shadow(flareShadowElevation(flareShadows().card), shape, clip = false)
        .clip(shape)
        .background(colors.bgPrimary)
        .border(1.dp, colors.borderSecondary, shape)
        .padding(FlareSizes.spacingMd)
    Column(
        shell,
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
    ) {
        // The quote slot: a reply's quote sits inside the shell, above the title row; nothing nested inherits it.
        if (!embedded && quote != null) quote()
        if (!embedded) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                if (icon != null && icon in flareIconNames) FlareIcon(icon, size = FlareSizes.iconSizeSm, tint = colors.primaryText)
                Text(view.title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.weight(1f, fill = false).semantics { heading() })
                if (menuActions.isNotEmpty()) {
                    Spacer(Modifier.weight(1f))
                    // The ⋯ key keeps the title row's height; its touch target reaches past the glyph.
                    Box(Modifier.flareTouchTargetBeyond(FlareSizes.iconSizeMd)) {
                        FlareIconControl(
                            label = strings.pluginViewMore,
                            onClick = { menuOpen = true },
                            enabled = !locked && onAction != null,
                        ) { FlareIcon("more", size = FlareSizes.iconSizeMd, tint = colors.textSecondary) }
                        ActionMenu(
                            expanded = menuOpen,
                            items = menuActions.map { action ->
                                FlareActionItem(id = action.id, label = action.label, danger = action.style == PluginActionStyle.Danger)
                            },
                            onDismiss = { menuOpen = false },
                            onSelect = { id -> menuActions.firstOrNull { it.id == id }?.let { run(it, PluginActionPayload.Empty) } },
                            label = strings.pluginViewMore,
                        )
                    }
                }
            }
        }
        // No title row: an unavailable embedded view still says what it was.
        PluginViewFormat.unavailableLine(view, embedded)?.let { Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd) }
        // Why it is unavailable, under the title.
        if (!view.available && reasonLine != null) Text(reasonLine, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd)
        if (view.available) {
            if (view.fields.isNotEmpty()) PluginFieldRows(view.fields)
            view.blocks.forEachIndexed { index, block ->
                when (block) {
                    is PluginTextBlock -> PluginTextBlockView(block)
                    is PluginFieldsBlock -> PluginFieldRows(block.fields)
                    is PluginChoicesBlock -> PluginChoicesBlockView(
                        block = block,
                        shown = interaction.shown(block, index),
                        interactive = onAction != null && interaction.isInteractive(block, index, locked),
                        submitEnabled = interaction.submitEnabled(block, index),
                        submitLoading = block.action != null && block.action.id == busyActionId,
                        onPick = { option ->
                            val action = block.action
                            if (action != null) {
                                val (next, selection) = interaction.tap(block, index, option, locked)
                                interaction = next
                                if (selection != null) run(action, PluginActionPayload(selection = selection), index)
                            }
                        },
                        onSubmit = {
                            val action = block.action
                            val selection = interaction.submission(block, index, locked)
                            if (action != null && selection != null) run(action, PluginActionPayload(selection = selection), index)
                        },
                    )
                    is PluginEntriesBlock -> PluginEntriesBlockView(block, users, viewerId, onOpenDetail)
                    is PluginPeopleBlock -> PluginPeopleBlockView(block, users)
                    is PluginStatusBlock -> PluginStatusBlockView(block)
                    is PluginProgressBlock -> PluginProgressBlockView(block)
                    is PluginTimeBlock -> PluginTimeBlockView(block)
                    is PluginDividerBlock -> Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderSecondary))
                    is PluginNoteBlock -> PluginNoteBlockView(block)
                }
            }
            // Embedded (the detail sheet, a plugin page): no title row, so the menu actions are keys after the others.
            val keys = if (embedded) view.actions + menuActions else view.actions
            if (keys.isNotEmpty()) {
                val key: @Composable (PluginViewAction, Modifier) -> Unit = { action, modifier ->
                    Box(modifier) {
                        Button(
                            label = action.label, variant = PluginViewFormat.variant(action), loading = busyActionId == action.id,
                            disabled = (locked && busyActionId != action.id) || onAction == null, block = true,
                            onClick = { run(action, PluginActionPayload.Empty) },
                        )
                    }
                }
                if (keys.size > 2) {
                    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                        keys.forEach { key(it, Modifier.fillMaxWidth()) }
                    }
                } else {
                    Row(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                        keys.forEach { key(it, Modifier.weight(1f)) }
                    }
                }
            }
            val detailEnabled = PluginViewFormat.detailKey(view, embedded, onOpenDetail != null, busy, busyActionId)
            if (detailEnabled != null && onOpenDetail != null) {
                Button(
                    label = flareStrings().pluginViewDetail, variant = FlareButtonVariant.Quiet, size = FlareControlSize.Sm,
                    disabled = !detailEnabled, block = true, onClick = onOpenDetail,
                )
            }
        }
        // A read-only copy closes with why nothing on it acts.
        if (view.available && reasonLine != null) Text(reasonLine, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm)
        if (failure != null) StatusBanner(text = failure, tone = FlareStatusTone.Danger)
    }

    confirming?.let { request ->
        DangerConfirm(
            title = request.action.label, description = request.action.confirm.orEmpty(), target = "",
            confirmText = request.action.label,
            onConfirm = { confirming = null; proceed(request) },
            onCancel = { confirming = null },
        )
    }
    formRun?.let { request ->
        BottomSheet(
            onClose = { if (!formPending) { formRun = null; formSubmitted = false } },
            title = request.action.label,
            dismissible = !formPending,
        ) {
            Column(Modifier.fillMaxWidth().weight(1f, fill = false).verticalScroll(rememberScrollState())) {
                PluginForm(
                    inputs = view.formInputs(request.action),
                    errors = if (formSubmitted) formErrors else emptyList(),
                    busy = formPending,
                    error = if (formSubmitted) failure else null,
                    members = members,
                    onSubmit = { values -> formSubmitted = true; emit(request, values) },
                    onCancel = { if (!formPending) { formRun = null; formSubmitted = false } },
                )
            }
        }
    }
}

/**
 * Where a [PluginView] sits — the padding it gives itself, in every state: [None] leaves it to the host's surface;
 * [Sheet] is the kit bottom sheet's insets — spacing md on top, lg at the sides and xl at the bottom ([PluginForm]'s);
 * [SheetTop] is the top of a sheet with more under it (a preface above [PluginForm]) — md on top, lg at the sides and no
 * bottom inset, so the next part's own top inset is the gap.
 */
enum class PluginViewInset { None, Sheet, SheetTop }

/** The padding of [inset] (spec rules.inset), around whatever the view draws — the card shell included. */
internal fun pluginViewInsetPadding(inset: PluginViewInset): PaddingValues = when (inset) {
    PluginViewInset.None -> PaddingValues(0.dp)
    PluginViewInset.Sheet ->
        PaddingValues(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = FlareSizes.spacingMd, bottom = FlareSizes.spacingXl)
    PluginViewInset.SheetTop ->
        PaddingValues(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = FlareSizes.spacingMd, bottom = 0.dp)
}

/** An action on its way out: confirmation and form come first; [block] marks a choices submit. */
internal data class PluginActionRun(val action: PluginViewAction, val payload: PluginActionPayload, val block: Int?)

/** The host's answers for the ids not known yet; an id it cannot answer keeps the fallback. */
internal suspend fun pluginResolvedUsers(
    ids: List<String>,
    known: Map<String, PluginUser>,
    resolveUser: suspend (String) -> PluginUser?,
): Map<String, PluginUser> {
    val found = LinkedHashMap<String, PluginUser>()
    for (id in ids) {
        if (id in known || id in found) continue
        val user = runCatching { resolveUser(id) }.getOrNull() ?: continue
        found[id] = user
    }
    return found
}

/** Runs [onChange] after a composition in which [value] differs from the last one seen (not on the first). */
@Composable
internal fun <T> PluginOnChange(value: T, onChange: (old: T, new: T) -> Unit) {
    val seen = remember { arrayOf<Any?>(value) }
    val action by rememberUpdatedState(onChange)
    LaunchedEffect(value) {
        @Suppress("UNCHECKED_CAST")
        val old = seen[0] as T
        if (old != value) {
            seen[0] = value
            action(old, value)
        }
    }
}

// ── blocks ──────────────────────────────────────────────────────────────────

/** The semantic colour of a tone as text (`*Text` tokens; neutral is the secondary text). */
@Composable
internal fun pluginToneText(tone: PluginTone?): androidx.compose.ui.graphics.Color {
    val colors = flareColors()
    return when (tone ?: PluginTone.Neutral) {
        PluginTone.Neutral -> colors.textSecondary
        PluginTone.Info -> colors.infoText
        PluginTone.Success -> colors.successText
        PluginTone.Warning -> colors.warningText
        PluginTone.Danger -> colors.errorText
    }
}

/** The ground a tone tints (the fill of the pair, faint). */
@Composable
internal fun pluginToneGround(tone: PluginTone?): androidx.compose.ui.graphics.Color {
    val colors = flareColors()
    return when (tone ?: PluginTone.Neutral) {
        PluginTone.Neutral -> colors.bgTertiary
        PluginTone.Info -> colors.info.copy(alpha = 0.12f)
        PluginTone.Success -> colors.success.copy(alpha = 0.12f)
        PluginTone.Warning -> colors.warning.copy(alpha = 0.12f)
        PluginTone.Danger -> colors.error.copy(alpha = 0.12f)
    }
}

@Composable
private fun PluginFieldRows(fields: List<PluginViewField>) {
    val colors = flareColors()
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
        fields.forEach { field ->
            Row(Modifier.fillMaxWidth().semantics(mergeDescendants = true) {}, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                Text(field.label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg, modifier = Modifier.widthIn(min = 56.dp))
                Text(field.value, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg, modifier = Modifier.weight(1f))
            }
        }
    }
}

@Composable
private fun PluginTextBlockView(block: PluginTextBlock) {
    val colors = flareColors()
    val strings = flareStrings()
    var expanded by remember(block) { mutableStateOf(false) }
    var overflows by remember(block) { mutableStateOf(false) }
    val (size, weight) = when (block.style) {
        PluginTextStyle.Title -> FlareSizes.fontSize2xl to FontWeight.SemiBold
        PluginTextStyle.Body -> FlareSizes.fontSizeLg to FontWeight.Normal
        PluginTextStyle.Secondary -> FlareSizes.fontSizeMd to FontWeight.Normal
    }
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
        Text(
            block.text,
            color = if (block.style == PluginTextStyle.Secondary) colors.textSecondary else colors.textPrimary,
            fontSize = size, fontWeight = weight,
            maxLines = if (expanded) Int.MAX_VALUE else block.maxLines ?: Int.MAX_VALUE,
            overflow = TextOverflow.Ellipsis,
            onTextLayout = { if (!expanded) overflows = it.hasVisualOverflow },
        )
        if (block.maxLines != null && (overflows || expanded)) {
            Text(
                if (expanded) strings.collapse else strings.expand,
                color = colors.primaryText, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.Medium,
                modifier = Modifier.clickable(role = Role.Button) { expanded = !expanded }.padding(vertical = FlareSizes.spacing3xs),
            )
        }
    }
}

@Composable
private fun PluginChoicesBlockView(
    block: PluginChoicesBlock,
    shown: List<Int>,
    interactive: Boolean,
    submitEnabled: Boolean,
    submitLoading: Boolean,
    onPick: (Int) -> Unit,
    onSubmit: () -> Unit,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val chosen = shown.toSet()
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
        block.options.forEach { option ->
            val selected = option.index in chosen
            val percent = PluginViewFormat.percentText(option, block.showResults)
            val votes = PluginViewFormat.votesText(option, block.showResults, strings)
            val shape = RoundedCornerShape(FlareSizes.radiusMd)
            Box(
                Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTargetMin).clip(shape)
                    .background(colors.bgSecondary)
                    .border(1.dp, if (selected) colors.borderSelected else colors.borderPrimary, shape)
                    .clickable(enabled = interactive, role = if (block.multiple) Role.Checkbox else Role.Button) { onPick(option.index) }
                    .semantics(mergeDescendants = true) {
                        this.selected = selected
                        contentDescription = listOfNotNull(option.label, percent, votes).joinToString(", ")
                    },
                contentAlignment = Alignment.CenterStart,
            ) {
                if (block.showResults) {
                    val fraction = ((option.percent ?: 0).coerceIn(0, 100)) / 100f
                    Box(Modifier.matchParentSize()) {
                        Box(Modifier.fillMaxHeight().fillMaxWidth(fraction).background(colors.primary.copy(alpha = if (selected) 0.16f else 0.08f)))
                    }
                }
                Row(
                    Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingXs),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
                ) {
                    if (block.multiple && interactive) PluginCheckBox(selected)
                    Text(option.label, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg,
                        fontWeight = if (selected) FontWeight.Medium else FontWeight.Normal, modifier = Modifier.weight(1f))
                    if (selected && !(block.multiple && interactive)) FlareIcon("check", size = FlareSizes.iconSizeSm, tint = colors.primaryText)
                    percent?.let { Text(it, color = if (selected) colors.primaryText else colors.textSecondary, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.SemiBold) }
                    votes?.let { Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm) }
                }
            }
        }
        val action = block.action
        if (action != null && block.multiple && !block.closed) {
            Button(
                label = action.label,
                variant = if (action.style == PluginActionStyle.Danger) FlareButtonVariant.Danger else FlareButtonVariant.Primary,
                loading = submitLoading, disabled = !(interactive && submitEnabled), block = true, onClick = onSubmit,
            )
        }
        PluginViewFormat.choicesFooter(block, strings)?.let { Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm) }
    }
}

/** The square a multiple choice draws while it can still be changed. */
@Composable
private fun PluginCheckBox(on: Boolean) {
    val colors = flareColors()
    val shape = RoundedCornerShape(FlareSizes.radiusXs)
    Box(
        Modifier.size(18.dp).clip(shape).background(if (on) colors.primary else colors.bgPrimary)
            .border(1.5.dp, if (on) colors.primary else colors.borderHover, shape),
        contentAlignment = Alignment.Center,
    ) {
        if (on) FlareIcon("check", size = 12.dp, tint = androidx.compose.ui.graphics.Color.White)
    }
}

@Composable
private fun PluginEntriesBlockView(block: PluginEntriesBlock, users: Map<String, PluginUser>, viewerId: String?, onSeeAll: (() -> Unit)?) {
    val colors = flareColors()
    val strings = flareStrings()
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
        if (block.items.isEmpty()) {
            block.emptyText?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd) }
        }
        block.items.forEachIndexed { position, entry ->
            // A grouped block opens each group with its header row.
            PluginViewFormat.entryGroupHeader(block, entry, strings)?.let { header ->
                Text(
                    header, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.fillMaxWidth().padding(top = if (position > 0) FlareSizes.spacingXs else 0.dp).semantics { heading() },
                )
            }
            val name = PluginViewFormat.entryName(entry, users)
            val me = PluginViewFormat.isMe(entry, viewerId)
            Row(
                Modifier.fillMaxWidth().semantics(mergeDescendants = true) {},
                verticalAlignment = Alignment.Top,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            ) {
                PluginViewFormat.entryNumber(block, entry)?.let { number ->
                    Text("$number.", color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd, modifier = Modifier.widthIn(min = 20.dp))
                }
                val userId = entry.userId
                if (!userId.isNullOrEmpty()) Avatar(userId = userId, displayName = name.orEmpty(), size = 20.dp, avatarUrl = users[userId]?.avatarUrl)
                if (name != null) {
                    Text(name, color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg, fontWeight = FontWeight.SemiBold, maxLines = 1)
                }
                if (me) {
                    Text(
                        strings.pluginViewMe, color = colors.primaryText, fontSize = FlareSizes.fontSizeXs, fontWeight = FontWeight.Medium,
                        modifier = Modifier.clip(RoundedCornerShape(FlareSizes.radiusXs)).background(colors.primary.copy(alpha = FlareOpacity.tintWeak))
                            .padding(horizontal = FlareSizes.spacingXs),
                    )
                }
                Text(entry.text, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg, modifier = Modifier.weight(1f))
            }
        }
        if (block.more) {
            Row(
                Modifier.heightIn(min = FlareSizes.touchTargetMin)
                    .clickable(enabled = onSeeAll != null, role = Role.Button) { onSeeAll?.invoke() },
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs),
            ) {
                Text(PluginViewFormat.seeAll(block.total, strings), color = colors.primaryText, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.Medium)
                FlareIcon("chevron-right", size = FlareSizes.iconSizeSm, tint = colors.primaryText)
            }
        }
    }
}

@Composable
private fun PluginPeopleBlockView(block: PluginPeopleBlock, users: Map<String, PluginUser>) {
    val colors = flareColors()
    val side = 24.dp
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
        block.groups.forEach { group ->
            val tone = pluginToneText(group.tone)
            Row(
                Modifier.fillMaxWidth().semantics(mergeDescendants = true) {},
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
            ) {
                if (group.userIds.isNotEmpty()) {
                    Box(Modifier.width(side + (side * 2 / 3) * (group.userIds.size - 1)).height(side)) {
                        group.userIds.forEachIndexed { i, userId ->
                            val user = PluginViewFormat.user(userId, users)
                            Box(Modifier.offset(x = (side * 2 / 3) * i).border(1.5.dp, colors.bgPrimary, CircleShape)) {
                                Avatar(userId = userId, displayName = user.name, size = side, avatarUrl = user.avatarUrl)
                            }
                        }
                    }
                }
                Text(group.label, color = tone, fontSize = FlareSizes.fontSizeMd)
                Text(group.count.toString(), color = tone, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.weight(1f))
            }
        }
    }
}

@Composable
private fun PluginStatusBlockView(block: PluginStatusBlock) {
    val colors = flareColors()
    Row(
        Modifier.semantics(mergeDescendants = true) {},
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
    ) {
        block.label?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd) }
        Text(
            block.text, color = pluginToneText(block.tone), fontSize = FlareSizes.fontSizeSm, fontWeight = FontWeight.SemiBold,
            modifier = Modifier.clip(RoundedCornerShape(FlareSizes.radiusFull)).background(pluginToneGround(block.tone))
                .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacing3xs),
        )
    }
}

@Composable
private fun PluginProgressBlockView(block: PluginProgressBlock) {
    val colors = flareColors()
    val text = PluginViewFormat.progressText(block)
    val fraction = block.percent.coerceIn(0, 100) / 100f
    Column(
        Modifier.fillMaxWidth().semantics(mergeDescendants = true) {
            progressBarRangeInfo = ProgressBarRangeInfo(fraction, 0f..1f)
            stateDescription = text
        },
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
    ) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            block.label?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd) }
            Spacer(Modifier.weight(1f))
            Text(text, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.SemiBold)
        }
        Box(Modifier.fillMaxWidth().height(FlareSizes.spacing2xs).clip(CircleShape).background(colors.bgTertiary)) {
            Box(Modifier.fillMaxHeight().fillMaxWidth(fraction).clip(CircleShape).background(colors.primary))
        }
    }
}

@Composable
private fun PluginTimeBlockView(block: PluginTimeBlock) {
    val colors = flareColors()
    val strings = flareStrings()
    var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
    LaunchedEffect(block) {
        if (!block.countdown) return@LaunchedEffect
        while (true) {
            now = System.currentTimeMillis()
            val wait = PluginViewFormat.countdownDelay(block.atMs, now) ?: break
            delay(wait)
        }
    }
    val text = PluginViewFormat.timeText(block.atMs, block.endMs, now, strings, null)
    val countdown = if (block.countdown) PluginViewFormat.countdown(block.atMs, now, strings) else null
    Row(
        Modifier.fillMaxWidth().semantics(mergeDescendants = true) {},
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
    ) {
        block.label?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd) }
        Text(text, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg)
        Spacer(Modifier.weight(1f))
        countdown?.let {
            Text(it.text, color = if (it.refreshMs == null) colors.textTertiary else colors.warningText, fontSize = FlareSizes.fontSizeSm,
                fontWeight = FontWeight.Medium)
        }
    }
}

@Composable
private fun PluginNoteBlockView(block: PluginNoteBlock) {
    Text(
        block.text, color = pluginToneText(block.tone), fontSize = FlareSizes.fontSizeMd,
        modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusSm)).background(pluginToneGround(block.tone))
            .padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingXs),
    )
}
