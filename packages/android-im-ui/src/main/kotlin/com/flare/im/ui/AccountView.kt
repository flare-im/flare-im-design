package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.constrainWidth
import androidx.compose.ui.unit.constrainHeight
import androidx.compose.ui.unit.dp
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter

/** Explicit visual contract selected by the product; no plugin IDs or financial rules in the kit. */
enum class FlarePluginPageAppearance { Document, Account }

internal enum class AccountLayout { Wallet, Flow, Ledger }

internal data class AccountFlowResult(val text: String, val tone: FlareStatusTone)
internal fun accountFlowResult(view: PluginViewModel): AccountFlowResult? {
    val props = view.presentation?.get("props") as? Map<*, *> ?: return null
    val lines = listOfNotNull(props["resultTitle"] as? String, props["resultDescription"] as? String).filter { it.isNotBlank() }
    if (lines.isEmpty()) {
        val account = accountPresentation(view)
        if (account.layout != AccountLayout.Flow || account.primary.isNotEmpty() || pluginInlineFormHeading(props["formTitle"] as? String) == null) return null
        if (view.blocks.any { it is PluginStatusBlock && it.text.isNotBlank() && (it.tone == PluginTone.Warning || it.tone == PluginTone.Danger) }) return null
        val description = pluginInlineFormHeading(props["formUnavailableDescription"] as? String) ?: return null
        return AccountFlowResult(description, FlareStatusTone.Neutral)
    }
    val tone = when (props["resultTone"]) {
        "success" -> FlareStatusTone.Success
        "warning" -> FlareStatusTone.Warning
        "danger" -> FlareStatusTone.Danger
        "info" -> FlareStatusTone.Info
        else -> FlareStatusTone.Neutral
    }
    return AccountFlowResult(lines.joinToString("\n"), tone)
}

/** Slots only order resolved, visible actions. They never grant a capability or synthesize a command. */
internal data class AccountPresentation(val layout: AccountLayout, val primary: List<PluginViewAction>, val shortcuts: List<PluginViewAction>, val services: List<PluginViewAction>, val groupByDate: Boolean)
internal fun accountPresentation(view: PluginViewModel): AccountPresentation {
    val props = view.presentation?.get("props") as? Map<*, *>
    val layout = when (props?.get("layout")) { "wallet" -> AccountLayout.Wallet; "flow" -> AccountLayout.Flow; else -> AccountLayout.Ledger }
    val slots = view.presentation?.get("actions") as? Map<*, *>
    val visible = if (view.available && !PluginViewFormat.readOnly(view)) view.actions + view.menuActions else emptyList()
    val ids = (if (layout == AccountLayout.Flow) listOf("submit") else listOf("primary", "secondary", "tertiary"))
        .mapNotNull { slots?.get(it) as? String }.distinct()
    val primary = (ids.mapNotNull { id -> visible.firstOrNull { it.id == id } } +
        if (layout == AccountLayout.Flow) visible.filter { it.style == PluginActionStyle.Primary } else emptyList()).distinctBy { it.id }
    val shortcuts = if (layout == AccountLayout.Wallet) listOf("shortcutPrimary", "shortcutSecondary", "shortcutTertiary")
        .mapNotNull { slot -> (slots?.get(slot) as? String)?.let { id -> visible.firstOrNull { it.id == id && primary.none { p -> p.id == id } } } }.distinctBy { it.id } else emptyList()
    return AccountPresentation(layout, primary, shortcuts, visible.filter { action -> primary.none { it.id == action.id } && shortcuts.none { it.id == action.id } }, props?.get("groupByDate") as? Boolean ?: (layout != AccountLayout.Wallet))
}

internal data class AccountEntry(val id: String, val block: PluginRowsBlock, val row: PluginRow, val separateBadge: Boolean = false) {
    /** The first cell as drawn: money with its currency (R10, as Vue `flarePluginMoneyFormatted`), else as sent. */
    val amount get() = row.cells.firstOrNull()?.let { cell -> (cell.format as? PluginValueFormat.Money)?.let { PluginFormatRules.money(cell.text, it) } ?: cell.text }.orEmpty()
    val title get() = (if (separateBadge) null else row.badge?.text) ?: row.cells.getOrNull(1)?.text ?: block.columns.firstOrNull()?.label.orEmpty()
    val walletTitle get() = row.cells.getOrNull(1)?.text.orEmpty()
    val walletCaption get() = block.columns.firstOrNull()?.label.orEmpty()
    val walletFields get() = row.cells.mapIndexedNotNull { index, cell ->
        if (index < 2 || cell.text.isEmpty()) null else block.columns.getOrNull(index)?.let { PluginViewField(it.label, cell.text, cell.format, cell.tone, cell.unmapped) }
    }
    /** §12.23: a PC wallet card's foot keeps only the statuses (toned or unmapped), never plain details like the asset. */
    val walletStatuses get() = walletFields.filter { it.tone != null || it.unmapped }
    /** R3: the row's toned cells (its statuses), drawn as Tags under the amount; a completed (success) one stays quiet (5.8). */
    val statusCells get() = row.cells.drop(1).filter { (it.tone != null && it.tone != PluginTone.Success) || it.unmapped }
    val subtitle get() = row.cells.mapIndexedNotNull { i, cell ->
        cell.text.takeIf { i >= (if (separateBadge || row.badge == null) 2 else 1) && i < 3 && block.columns.getOrNull(i)?.format != PluginRowsFormat.Time && it.isNotEmpty() }
    }.joinToString(" · ")
    val timeMs get() = block.columns.indexOfFirst { it.format == PluginRowsFormat.Time }.let { row.cells.getOrNull(it)?.timeMs }
}

internal fun accountEntries(view: PluginViewModel): List<AccountEntry> = view.blocks.flatMapIndexed { index, block ->
    if (block is PluginRowsBlock) PluginViewFormat.rowsOnce(block.rows).map { AccountEntry("$index/${it.key}", block, it, (view.presentation?.get("props") as? Map<*, *>)?.get("rowBadgePlacement") == "separate") }
    else emptyList()
}

internal fun accountEntryAction(view: PluginViewModel, entry: AccountEntry, busy: Boolean, handled: Boolean): Pair<PluginViewAction, PluginRowAction>? {
    if (!view.available || PluginViewFormat.readOnly(view) || busy || !handled) return null
    val id = (view.presentation?.get("props") as? Map<*, *>)?.get("rowEntryAction") as? String ?: return null
    return PluginViewFormat.rowActions(entry.block, entry.row).firstOrNull { (action, _) -> action.id == id && action.confirm.isNullOrEmpty() && action.form.isNullOrEmpty() }
}

internal fun accountUrgentBlocks(view: PluginViewModel): List<PluginBlock> {
    val layout = (view.presentation?.get("props") as? Map<*, *>)?.get("layout")
    if (layout != "wallet" && layout != "ledger") return view.blocks.filter {
        it is PluginNoteBlock && it.tone in listOf(PluginTone.Warning, PluginTone.Danger)
    }
    return view.blocks.filter {
    when (it) {
        is PluginNoteBlock -> it.text.isNotBlank() && it.tone in listOf(PluginTone.Warning, PluginTone.Danger)
        is PluginStatusBlock -> it.text.isNotBlank() && it.tone in listOf(PluginTone.Warning, PluginTone.Danger)
        // 5.1: a pending operation's warning banner (with its review key) sits above the overview card.
        is PluginBannerBlock -> it.text.isNotBlank() && (it.tone == PluginBannerTone.Warning || it.tone == PluginBannerTone.Danger)
        else -> false
    }
    }
}

internal fun accountWalletColumnCount(width: Dp, count: Int): Int =
    if (count > 1 && width >= FlareSizes.primaryPaneMinWidth * 2 + FlareSizes.spacingMd) 2 else 1

/** Ledger over resolved rows. Amount text and row action input are emitted unchanged. */
@Composable
fun FlareAccountView(
    view: PluginViewModel,
    busyActionId: String? = null,
    error: String? = null,
    formErrors: List<PluginFormError> = emptyList(),
    members: List<PluginMember> = emptyList(),
    settleToken: Int = 0,
    fileStates: Map<String, PluginFileState> = emptyMap(),
    onFileAction: ((PluginFileAction) -> Unit)? = null,
    membersLoading: Boolean = false,
    membersError: String? = null,
    onMemberSearch: ((String) -> Unit)? = null,
    onMembersRetry: (() -> Unit)? = null,
    membersRevision: Int = 0,
    onAction: ((String, PluginActionPayload) -> Unit)? = null,
    /** Names and avatars of the users the view mentions (people, entries), as [PluginView]'s. */
    resolveUser: (suspend (String) -> PluginUser?)? = null,
    /** The viewer's user id: entries of that user carry the "me" tag. */
    viewerId: String? = null,
) = AccountViewContent(view, busyActionId, error, formErrors, members, settleToken, onAction, null,
    fileStates = fileStates, onFileAction = onFileAction, membersLoading = membersLoading, membersError = membersError, onMemberSearch = onMemberSearch, onMembersRetry = onMembersRetry, membersRevision = membersRevision,
    resolveUser = resolveUser, viewerId = viewerId)

@OptIn(ExperimentalLayoutApi::class, androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
internal fun AccountViewContent(
    view: PluginViewModel, busyActionId: String?, error: String?, formErrors: List<PluginFormError>,
    members: List<PluginMember>, settleToken: Int, onAction: ((String, PluginActionPayload) -> Unit)?, list: PluginViewList?,
    contentMaxWidth: Dp? = FlareSizes.directoryContentMaxWidth,
    fileStates: Map<String, PluginFileState> = emptyMap(),
    onFileAction: ((PluginFileAction) -> Unit)? = null,
    membersLoading: Boolean = false,
    membersError: String? = null,
    onMemberSearch: ((String) -> Unit)? = null,
    onMembersRetry: (() -> Unit)? = null,
    membersRevision: Int = 0,
    /** R8: offline holds every action and entry (not hidden); the primary keys say they are available online. */
    offline: Boolean = false,
    resolveUser: (suspend (String) -> PluginUser?)? = null,
    viewerId: String? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val locale = LocalConfiguration.current.locales[0]
    val phone = flareCompactOverlays()
    var hidden by remember { mutableStateOf(false) }
    // R8: an action's failure is a banner at the top the viewer can close; closed, it stays closed for that failure.
    var dismissedError by remember { mutableStateOf<String?>(null) }
    val failure = error?.takeIf { it.isNotEmpty() && it != dismissedError }
    var information by remember { mutableStateOf(false) }
    var selectedId by remember { mutableStateOf<String?>(null) }
    val entries = remember(view) { accountEntries(view) }
    val presentation = view.presentation?.get("props") as? Map<*, *> ?: emptyMap<Any, Any>()
    val account = remember(view) { accountPresentation(view) }
    val flowInlineId = if (account.layout == AccountLayout.Flow && account.primary.size == 1)
        pluginInlineFormAction(view, account.primary.single().id, onAction != null)?.id else null
    val detailTitle = presentation["detailTitle"] as? String ?: presentation["sectionTitle"] as? String ?: strings.accountEntryDetails
    val urgent = remember(view) { accountUrgentBlocks(view) }
    val otherBlocks = remember(view) { view.blocks.filterNot { it is PluginRowsBlock || it in urgent } }
    val selected = entries.firstOrNull { it.id == selectedId }
    fun activateEntry(entry: AccountEntry) {
        if (busyActionId != null || offline) return
        val action = accountEntryAction(view, entry, busy = false, handled = onAction != null)
        if (action != null) onAction?.invoke(action.first.id, PluginActionPayload(row = PluginActionRow(entry.row.key, action.second.input)))
        else selectedId = entry.id
    }
    val zone = ZoneId.systemDefault()
    fun day(entry: AccountEntry): LocalDate? = entry.timeMs?.let { Instant.ofEpochMilli(it).atZone(zone).toLocalDate() }
    fun dayLabel(entry: AccountEntry): String {
        val date = day(entry) ?: return strings.accountOtherEntries
        val today = LocalDate.now(zone)
        return when(date) {
            today -> strings.accountToday
            today.minusDays(1) -> strings.accountYesterday
            else -> date.format(DateTimeFormatter.ofPattern(if (date.year == today.year) strings.accountDayFormat else strings.accountDayYearFormat, locale))
        }
    }
    fun projection(fields: List<PluginViewField> = emptyList(), actions: List<PluginViewAction> = emptyList(), blocks: List<PluginBlock> = emptyList()) =
        view.copy(fields = fields, actions = actions, blocks = blocks, menuActions = emptyList(), detail = false, nextCursor = null, presentation = null)
    val actions: @Composable (PluginViewModel, AccountEntry?, PluginViewActionLayout, Boolean) -> Unit = { projected, entry, layout, showError ->
        PluginView(view = projected, embedded = true, busy = offline,
            actionLayout = layout, showError = showError, resolveUser = resolveUser, viewerId = viewerId,
            labelRows = account.layout == AccountLayout.Flow,
            inlineFormActionId = flowInlineId.takeIf { entry == null && projected.actions == account.primary },
            inlineFormTitle = (presentation["formTitle"] as? String).takeIf { account.layout == AccountLayout.Flow },
            inlineFormDescription = (presentation["formDescription"] as? String).takeIf { account.layout == AccountLayout.Flow },
            busyActionId = busyActionId, error = error, formErrors = formErrors, members = members, membersLoading = membersLoading, membersError = membersError, onMemberSearch = onMemberSearch, onMembersRetry = onMembersRetry, membersRevision = membersRevision,  settleToken = settleToken,
            fileStates = fileStates, onFileAction = onFileAction,
            onAction = onAction?.let { emit -> { id, payload ->
                val binding = entry?.row?.actions?.firstOrNull { it.id == id }
                if (entry != null && binding != null && entry.block.actions.firstOrNull { it.id == id }?.form.isNullOrEmpty()) selectedId = null
                emit(id, if (entry == null || binding == null) payload else payload.copy(row = PluginActionRow(entry.row.key, binding.input)))
            } })
    }
    if (!view.available) { actions(view, null, PluginViewActionLayout.Inline, true); return }
    val maxContentWidth = flareContentMaxWidth(contentMaxWidth)
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.TopCenter) {
    LazyColumn(
        modifier = Modifier.then(if (maxContentWidth == null) Modifier else Modifier.widthIn(max = maxContentWidth)).fillMaxSize(),
        state = list?.state ?: rememberLazyListState(),
        contentPadding = list?.contentPadding ?: PaddingValues(FlareSizes.spacingLg),
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
    ) {
        list?.header?.invoke(this)
        if (account.layout != AccountLayout.Flow) failure?.let { text ->
            item(key = "account:error") { StatusBanner(text = text, tone = FlareStatusTone.Danger, dismissible = true, onDismiss = { dismissedError = text }) }
        }
        if (account.layout == AccountLayout.Flow) {
            item(key = "account:introduction") {
                Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                    (presentation["stepLabel"] as? String)?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.primaryText, fontSize = FlareSizes.fontSizeSm, fontWeight = FontWeight.SemiBold) }
                    (presentation["summaryTitle"] as? String)?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, fontWeight = FontWeight.SemiBold, modifier = Modifier.semantics { heading() }) }
                    (presentation["description"] as? String)?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm) }
                }
            }
            accountFlowResult(view)?.let { result -> item(key = "account:result") { StatusBanner(text = result.text, tone = result.tone) } }
            item(key = "account:flow") {
                Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusLg)).background(colors.bgSecondary).padding(FlareSizes.spacingLg), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                    (presentation["sectionTitle"] as? String)?.let { Text(it, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, fontWeight = FontWeight.SemiBold, modifier = Modifier.semantics { heading() }) }
                    actions(projection(fields = view.fields, actions = account.primary, blocks = view.blocks), null, PluginViewActionLayout.Compact, account.services.isEmpty())
                }
            }
            if (account.services.isNotEmpty()) item(key = "account:services") {
                Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                    (presentation["servicesTitle"] as? String)?.let { Text(it, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, fontWeight = FontWeight.SemiBold, modifier = Modifier.semantics { heading() }) }
                    // R2.1: list cards by group, danger in its own card.
                    actions(projection(actions = account.services), null, PluginViewActionLayout.Groups, flowInlineId == null)
                }
            }
        } else if (account.layout == AccountLayout.Wallet) {
            item(key = "account:wallet") {
                val title = presentation["sectionTitle"] as? String ?: presentation["summaryTitle"] as? String ?: view.title
                // §12.23: a PC wallet home has no title row (the page header names it); the section keeps it for the reader.
                val pc = !phone && entries.isNotEmpty()
                Column(if (pc) Modifier.semantics { contentDescription = title } else Modifier, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                    if (!pc) AccountHeader {
                        Text(title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, fontWeight = FontWeight.SemiBold, modifier = Modifier.semantics { heading() })
                        // 5.2: no wallet, no balance to hide.
                        if (entries.isNotEmpty()) AccountMaskKey(hidden) { hidden = !hidden }
                    }
                    if (urgent.isNotEmpty()) actions(projection(blocks = urgent), null, PluginViewActionLayout.Inline, false)
                    // 5.1: the primary keys close the overview card (phone: equal widths, 48 high), never the title row.
                    val quick: @Composable () -> Unit = {
                        if (account.primary.isNotEmpty()) quickKeys(projection(actions = account.primary), actions, offline, strings)
                    }
                    val directLabel = { entry: AccountEntry -> accountEntryAction(view, entry, false, onAction != null)?.first?.label }
                    if (entries.isEmpty()) Unit
                    else if (phone) {
                        // 5.1: the default wallet is the overview card; any other wallet is a row under it.
                        val lead = entries.first()
                        key(lead.id) { AccountWalletCard(lead, hidden, busyActionId != null || offline, directLabel(lead), footer = quick) { activateEntry(lead) } }
                        val others = entries.drop(1)
                        if (others.isNotEmpty()) {
                            PluginSectionTitle(accountOtherWalletsTitle(presentation, strings), Modifier.padding(top = FlareSizes.spacingSm))
                            Column(Modifier.pluginListCard()) {
                                others.forEachIndexed { index, entry ->
                                    if (index > 0) FlareGroupedCardDivider()
                                    key(entry.id) { AccountWalletRow(entry, hidden, busyActionId != null || offline) { activateEntry(entry) } }
                                }
                            }
                        }
                    } else {
                        BoxWithConstraints {
                            val columns = accountWalletColumnCount(maxWidth, entries.size)
                            Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                                entries.chunked(columns).forEach { row -> Row(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                                    row.forEach { entry -> key(entry.id) { Box(Modifier.weight(1f)) {
                                        AccountWalletCard(entry, hidden, busyActionId != null || offline, directLabel(entry), pc = true) { activateEntry(entry) }
                                    } } }
                                    if (row.size < columns) Spacer(Modifier.weight(1f))
                                } }
                            }
                        }
                        // §12.23: the quick keys (R2.1 PC) start the row under the cards, the eye ends it (alone there without keys).
                        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                            Box(Modifier.weight(1f)) {
                                if (account.primary.isNotEmpty()) actions(projection(actions = account.primary), null, PluginViewActionLayout.Quick, false)
                            }
                            // The keys stand spacing.lg under the cards (PluginQuickKeys); the eye keeps their line.
                            Box(Modifier.padding(top = FlareSizes.spacingLg)) { AccountMaskKey(hidden) { hidden = !hidden } }
                        }
                        if (offline && account.primary.isNotEmpty()) PluginCaption(strings.pluginViewAvailableOnline)
                    }
                }
            }
            if (account.shortcuts.isNotEmpty()) item(key = "account:shortcuts") {
                Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                    (presentation["shortcutsTitle"] as? String)?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, fontWeight = FontWeight.SemiBold, modifier = Modifier.semantics { heading() }) }
                    actions(projection(actions = account.shortcuts), null, PluginViewActionLayout.Compact, false)
                }
            }
            // 5.2: no wallet yet is a whole-page setup state — no balance, the primary (open a wallet) under it.
            if (entries.isEmpty()) item(key = "account:empty") {
                AccountSetupState(
                    title = presentation["emptyTitle"] as? String ?: strings.walletSetupTitle,
                    description = presentation["emptyDescription"] as? String ?: strings.walletSetupBody,
                    phone = phone,
                    keys = if (account.primary.isEmpty()) null else ({ quickKeys(projection(actions = account.primary), actions, offline, strings) }),
                )
            }
            if (view.fields.isNotEmpty() || otherBlocks.isNotEmpty()) item(key = "account:info") {
                AccountInformationRow(presentation["informationTitle"] as? String ?: strings.accountInformation) { information = true }
            }
            if (account.services.isNotEmpty()) item(key = "account:services") {
                Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                    (presentation["servicesTitle"] as? String)?.let { Text(it, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, fontWeight = FontWeight.SemiBold, modifier = Modifier.semantics { heading() }) }
                    // R2.1: list cards by group (`group`, the row icon), chevrons on destinations only, danger in its own centred card.
                    actions(projection(actions = account.services), null, PluginViewActionLayout.Groups, false)
                }
            }
        } else {
        if (presentation["layout"] == "ledger") item(key = "account:introduction") {
            Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                (presentation["contextLabel"] as? String)?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd, fontWeight = FontWeight.Medium) }
                (presentation["description"] as? String)?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm) }
            }
        } else {
            (presentation["description"] as? String)?.takeIf { it.isNotEmpty() }?.let { description -> item(key = "account:description") { Text(description, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd) } }
            (presentation["contextLabel"] as? String)?.takeIf { it.isNotEmpty() }?.let { context -> item(key = "account:context") { Text(context, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm) } }
        }
        if (presentation["layout"] == "ledger") {
        if (urgent.isNotEmpty()) item(key = "account:notices") { actions(projection(blocks = urgent), null, PluginViewActionLayout.Inline, false) }
        }
        view.fields.firstOrNull()?.let { first -> item(key = "account:overview") {
            // R10: the overview card (bg.primary, radius.card); the balance 32/700 and the figures 18/600, tabular.
            Column(Modifier.pluginListCard().padding(FlareSizes.spacingLg),
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(first.label, color = colors.textSecondary, modifier = Modifier.weight(1f))
                    AccountMaskKey(hidden) { hidden = !hidden }
                }
                Text(if (hidden) PLUGIN_HIDDEN_AMOUNT else first.value, color = colors.textPrimary,
                    fontSize = FlareSizes.componentAmountHeroFontSize.value.sp, fontWeight = FontWeight.Bold, style = FlareTabularFigures,
                    modifier = Modifier.clearAndSetSemantics { contentDescription = if (hidden) strings.accountBalanceHidden else FlarePaymentRules.spokenAmount(first.value, locale) })
                FlowRow(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXl), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                    view.fields.drop(1).forEach { field -> Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                        Text(field.label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
                        Text(if (hidden) PLUGIN_HIDDEN_AMOUNT else field.value, color = colors.textPrimary, fontSize = FlareSizes.fontSize3xl,
                            fontWeight = FontWeight.SemiBold, style = FlareTabularFigures)
                    } }
                }
            }
        } }
        if (presentation["layout"] != "ledger") {
            if (urgent.isNotEmpty()) item(key = "account:notices") { actions(projection(blocks = urgent), null, PluginViewActionLayout.Inline, false) }
        }
        if (view.fields.isNotEmpty() || presentation["sectionTitle"] is String) item(key = "account:heading") { Text(((view.presentation?.get("props") as? Map<*, *>)?.get("sectionTitle") as? String) ?: strings.accountTransactions, color = colors.textPrimary, fontSize = FlareSizes.fontSize3xl, fontWeight = FontWeight.SemiBold, modifier = Modifier.semantics { heading() }) }
        // R8 / 5.8: the records' empty state is the compact one with the clock.
        if (entries.isEmpty()) item(key = "account:empty") { EmptyState(title = presentation["emptyTitle"] as? String ?: strings.accountEmpty, description = presentation["emptyDescription"] as? String ?: strings.accountEmptyDescription, icon = "clock", compact = true) }
        entries.forEachIndexed { index, entry ->
            // 5.8: the day heading sticks while its rows scroll under it.
            if (account.groupByDate && (index == 0 || day(entry) != day(entries[index - 1]))) stickyHeader(key = "account:day:${entry.id}") {
                Text(dayLabel(entry), color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm, fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.fillMaxWidth().background(colors.bgPrimary).padding(vertical = FlareSizes.spacingXs).semantics { heading() })
            }
            item(key = "account:entry:${entry.id}") {
                // 5.8: a 64 high row — the kind's 36 circle, the title 15 over "time · the rest" 12, the signed amount
                // 16/600 with its non-completed status Tags under it; the row opens its detail, no chevron.
                val time = entry.timeMs?.let { Instant.ofEpochMilli(it).atZone(zone).format(DateTimeFormatter.ofPattern("HH:mm", locale)) }
                val line = listOfNotNull(time, entry.subtitle.takeIf { it.isNotEmpty() }).joinToString(" · ")
                val masked = hidden && presentation["maskRowAmounts"] == true
                // R11: the row reads as one line, its amount with the currency's name and its statuses after it.
                val spoken = listOfNotNull(
                    entry.title, entry.row.badge?.text?.takeIf { entry.separateBadge }, line.takeIf { it.isNotEmpty() },
                    if (masked) strings.accountBalanceHidden else FlarePaymentRules.spokenAmount(pluginSignedAmount(entry.amount), locale),
                ) + entry.statusCells.map { cell ->
                    when (val draw = pluginStatusDraw(PluginFormatRules.text(cell.text, cell.format, strings), cell.tone, cell.unmapped, strings)) {
                        is PluginStatusDraw.Tag -> draw.text
                        is PluginStatusDraw.Text -> draw.text
                    }
                }
                Row(Modifier.fillMaxWidth().clickable(enabled = busyActionId == null && !offline, role = Role.Button) {
                    val action = accountEntryAction(view, entry, busyActionId != null, onAction != null)
                    if (action != null) onAction?.invoke(action.first.id, PluginActionPayload(row = PluginActionRow(entry.row.key, action.second.input))) else selectedId = entry.id
                }
                    .clearAndSetSemantics { contentDescription = spoken.joinToString(", ") }
                    .heightIn(min = FlareSizes.componentRecordRowHeight).padding(vertical = FlareSizes.spacingSm),
                    verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                    PluginLedgerIcon(pluginLedgerKind(entry.amount), entry.row.icon)
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
                        Text(entry.title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        if (entry.separateBadge) entry.row.badge?.let { PluginBadgeTag(it) }
                        if (line.isNotEmpty()) Text(line, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    }
                    Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
                        // R10: income in the success ink with "+", spending in the primary ink with "−" (U+2212), tabular.
                        Text(if (masked) PLUGIN_HIDDEN_AMOUNT else pluginSignedAmount(entry.amount),
                            color = if (pluginLedgerKind(entry.amount) == PluginLedgerKind.Income) colors.successText else colors.textPrimary,
                            fontSize = FlareSizes.fontSize2xl, fontWeight = FontWeight.SemiBold, style = FlareTabularFigures, maxLines = 1)
                        entry.statusCells.forEach { cell -> PluginStatusValue(cell.text, cell.format, cell.tone, cell.unmapped, strings, warnKey = entry.block.source) }
                    }
                }
            }
        }
        if (otherBlocks.isNotEmpty()) item(key = "account:info") {
            AccountInformationRow(presentation["informationTitle"] as? String ?: strings.accountInformation) { information = true }
        }
        if ((view.actions + view.menuActions).isNotEmpty()) item(key = "account:services") {
            Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                (presentation["servicesTitle"] as? String)?.let { Text(it, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, fontWeight = FontWeight.SemiBold, modifier = Modifier.semantics { heading() }) }
                actions(projection(actions = view.actions + view.menuActions), null, PluginViewActionLayout.Groups, false)
            }
        }
        }
        list?.footer?.invoke(this)
    }
    }
    // 5.1: account information opens as a panel of label/value rows (and the account's other blocks).
    if (information) BottomSheet(onClose = { information = false }, title = presentation["informationTitle"] as? String ?: strings.accountInformation) {
        Column(Modifier.fillMaxWidth().weight(1f, fill = false).verticalScroll(rememberScrollState()).padding(FlareSizes.spacingLg),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
            if (view.fields.isNotEmpty()) PluginDescriptionList(view.fields.map { if (hidden) it.copy(value = PLUGIN_HIDDEN_AMOUNT) else it })
            if (otherBlocks.isNotEmpty()) actions(projection(blocks = otherBlocks), null, PluginViewActionLayout.Inline, false)
        }
    }
    if (selected != null) BottomSheet(onClose = { selectedId = null }, title = detailTitle, titleHidden = true, dismissible = busyActionId == null) {
        Column(Modifier.verticalScroll(rememberScrollState()).padding(FlareSizes.spacingLg), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(detailTitle, color = colors.textPrimary, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                IconButton("close", strings.close, disabled = busyActionId != null, onClick = { selectedId = null })
            }
            selected.block.columns.firstOrNull()?.label?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textSecondary, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center) }
            Text(if (hidden && presentation["maskRowAmounts"] == true) "••••" else selected.amount, color = if (selected.amount.startsWith("+")) colors.successText else colors.textPrimary,
                fontSize = FlareSizes.fontSize5xl, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacingMd))
            selected.row.badge?.let { badge -> Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(presentation["rowBadgeLabel"] as? String ?: strings.accountType, color = colors.textSecondary); PluginBadgeTag(badge)
            } }
            selected.row.cells.forEachIndexed { index, cell -> if (index > 0) {
                val column = selected.block.columns.getOrNull(index)
                AccountDetailLine(column?.label.orEmpty(), if (column?.format == PluginRowsFormat.Time && cell.timeMs != null)
                    PluginViewFormat.dateTime(cell.timeMs, FlareServerClock.nowMs(), strings, null) else cell.text)
            } }
            AccountDetailLine(presentation["rowKeyLabel"] as? String ?: strings.accountEntryId, selected.row.key)
            actions(projection(actions = selected.block.actions.filter { a -> selected.row.actions.any { it.id == a.id } }), selected, PluginViewActionLayout.Inline, true)
        }
    }
}

@Composable
private fun AccountDetailLine(label: String, value: String) {
    val colors = flareColors()
    Row(Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacingSm), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
        Text(label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd, modifier = Modifier.weight(1f))
        Text(value, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd, textAlign = TextAlign.End, modifier = Modifier.weight(2f))
    }
}

@Composable
private fun AccountWalletCard(entry: AccountEntry, hidden: Boolean, disabled: Boolean, directLabel: String?, footer: (@Composable () -> Unit)? = null, pc: Boolean = false, onSelect: () -> Unit) {
    val colors = flareColors()
    val strings = flareStrings()
    val interaction = remember { MutableInteractionSource() }
    val focused by interaction.collectIsFocusedAsState()
    val hovered by interaction.collectIsHoveredAsState()
    val locale = flareLocale()
    // 5.1: the overview card is the primary surface on `radius.card`, never the secondary fill.
    val shape = RoundedCornerShape(FlareSizes.radiusCard)
    Column(Modifier.fillMaxWidth().clip(shape).background(colors.bgPrimary)
        .border(if (focused) 3.dp else 1.dp, if (focused && !disabled) colors.borderSelected else if (hovered && !disabled) colors.borderHover else colors.borderSecondary, shape)
        .clickable(enabled = !disabled, role = Role.Button, onClickLabel = directLabel ?: strings.accountEntryDetails, interactionSource = interaction, indication = androidx.compose.foundation.LocalIndication.current, onClick = onSelect).padding(FlareSizes.spacingLg),
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            FlareIcon("wallet", tint = colors.primaryText)
            Spacer(Modifier.width(FlareSizes.spacingSm))
            Text(entry.walletTitle, color = colors.textPrimary, fontSize = FlareSizes.fontSize4xl, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
            if (directLabel == null) FlareIcon("chevron-right", size = FlareSizes.iconSizeSm, tint = colors.textSecondary)
        }
        if (!pc) Text(entry.walletCaption, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
        Text(if (hidden) PLUGIN_HIDDEN_AMOUNT else entry.amount, color = colors.textPrimary, fontSize = FlareSizes.componentAmountHeroFontSize.value.sp,
            fontWeight = FontWeight.Bold, style = FlareTabularFigures,
            modifier = Modifier.clearAndSetSemantics { contentDescription = if (hidden) strings.accountBalanceHidden else FlarePaymentRules.spokenAmount(entry.amount, locale) })
        // §12.23: a PC card ends with one line, its statuses then 「查看明细 ›」 (no balance label, no plain details).
        if (pc) {
            if (entry.walletStatuses.isNotEmpty() || directLabel != null) Row(verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                val dot: @Composable () -> Unit = { Text("·", color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm) }
                entry.walletStatuses.forEachIndexed { index, field ->
                    if (index > 0) dot()
                    PluginStatusValue(field.value, field.format, field.tone, field.unmapped, strings)
                }
                if (directLabel != null) {
                    if (entry.walletStatuses.isNotEmpty()) dot()
                    Text(directLabel, color = colors.primaryText, fontSize = FlareSizes.fontSizeSm, fontWeight = FontWeight.SemiBold)
                    FlareIcon("chevron-right", size = FlareSizes.iconSizeSm, tint = colors.primaryText)
                }
            }
        } else Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
            entry.walletFields.chunked(2).forEach { fields -> Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                fields.forEach { field -> Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                    Text(field.label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
                    // R3 / W-04: a status reads as its Tag; figures hide with the balance.
                    if (field.tone != null || field.unmapped) PluginStatusValue(field.value, field.format, field.tone, field.unmapped, strings)
                    // R10: a card's secondary figure is 18/600 in tabular digits.
                    else Text(if (hidden) PLUGIN_HIDDEN_AMOUNT else field.value, color = colors.textPrimary, fontSize = FlareSizes.fontSize3xl,
                        fontWeight = FontWeight.SemiBold, style = FlareTabularFigures)
                } }
                if (entry.walletFields.size > 1 && fields.size < 2) Spacer(Modifier.weight(1f))
            } }
        }
        footer?.invoke()
        if (directLabel != null && !pc) {
            Box(Modifier.fillMaxWidth().height(1.dp).background(colors.borderSecondary))
            Row(Modifier.fillMaxWidth().padding(top = FlareSizes.spacingXs), verticalAlignment = Alignment.CenterVertically) {
                Text(directLabel, color = colors.primaryText, fontSize = FlareSizes.fontSizeSm, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                FlareIcon("chevron-right", size = FlareSizes.iconSizeSm, tint = colors.primaryText)
            }
        }
    }
}

@Composable
private fun AccountHeader(content: @Composable () -> Unit) {
    Layout(content = content, modifier = Modifier.fillMaxWidth()) { measurables, constraints ->
        val items = measurables.map { it.measure(constraints.copy(minWidth = 0, minHeight = 0)) }
        val gap = FlareSizes.spacingMd.roundToPx()
        val lineGap = FlareSizes.spacingMd.roundToPx()
        val width = constraints.constrainWidth(items.sumOf { it.width } + gap)
        val wrapped = items.sumOf { it.width } + gap > width
        val height = if (wrapped) items.sumOf { it.height } + lineGap else items.maxOfOrNull { it.height } ?: 0
        layout(width, constraints.constrainHeight(height)) {
            var y = 0
            items.forEachIndexed { index, item ->
                item.placeRelative(if (!wrapped && index > 0) width - item.width else 0,
                    if (wrapped) y else (height - item.height) / 2)
                y += item.height + lineGap
            }
        }
    }
}

/** The eye key that hides the balances (R10): a switch read as hide / show balance. */
@Composable
private fun AccountMaskKey(hidden: Boolean, onToggle: () -> Unit) {
    val strings = flareStrings()
    FlareIconControl(label = if (hidden) strings.accountShowBalance else strings.accountHideBalance, onClick = onToggle, checked = hidden) {
        FlareIcon(if (hidden) "eye-off" else "eye", size = FlareSizes.iconSizeMd, tint = flareColors().textSecondary)
    }
}

/** The "other wallets" heading (5.1): the presentation's own words, else the kit's. */
internal fun accountOtherWalletsTitle(presentation: Map<*, *>, strings: FlareStrings): String =
    presentation["otherWalletsTitle"] as? String ?: strings.accountOtherWallets

/** One more wallet under the overview card on a phone (5.1): its name and caption, the balance, a chevron. */
@Composable
private fun AccountWalletRow(entry: AccountEntry, hidden: Boolean, disabled: Boolean, onSelect: () -> Unit) {
    val colors = flareColors()
    val strings = flareStrings()
    val locale = flareLocale()
    Row(
        Modifier.fillMaxWidth().heightIn(min = 52.dp).flareDimmed(if (disabled) FlareOpacity.disabled else 1f)
            .clickable(enabled = !disabled, role = Role.Button, onClickLabel = strings.accountEntryDetails, onClick = onSelect)
            .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
    ) {
        Column(Modifier.weight(1f).semantics(mergeDescendants = true) {}) {
            Text(entry.walletTitle, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(entry.walletCaption, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm, maxLines = 1)
        }
        Text(if (hidden) PLUGIN_HIDDEN_AMOUNT else entry.amount, color = colors.textPrimary, fontSize = FlareSizes.fontSize2xl,
            fontWeight = FontWeight.SemiBold, style = FlareTabularFigures,
            modifier = Modifier.clearAndSetSemantics { contentDescription = if (hidden) strings.accountBalanceHidden else FlarePaymentRules.spokenAmount(entry.amount, locale) })
        FlareIcon("chevron-right", size = FlareSizes.iconSizeSm, tint = colors.textTertiary)
    }
}

/** The account information row (5.1): one list row that opens the information panel. */
@Composable
private fun AccountInformationRow(title: String, onOpen: () -> Unit) {
    Column(Modifier.pluginListCard()) {
        SettingsRow(SettingsItem("account-information", title, icon = "info"), onSelect = { onOpen() })
    }
}

/**
 * 5.2: no wallet yet — the wallet in its 48 circle on `bg.selected`, the title at `textRole.title` 20/700, what a
 * wallet gives, then the open key: full width 48 on a phone, `component.accountSetupActionWidth` on a wide window.
 */
@Composable
private fun AccountSetupState(title: String, description: String, phone: Boolean, keys: (@Composable () -> Unit)?) {
    val colors = flareColors()
    Column(
        Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacing2xl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
    ) {
        Box(Modifier.size(FlareSizes.controlHeightLg + FlareSizes.spacingLg).clip(androidx.compose.foundation.shape.CircleShape).background(colors.bgSelected),
            contentAlignment = Alignment.Center) {
            FlareIcon("wallet", size = FlareSizes.controlHeightLg, tint = colors.primaryText)
        }
        Text(title, color = colors.textPrimary, fontSize = FlareTextRoles.Title.fontSize, fontWeight = FlareTextRoles.Title.fontWeight,
            textAlign = TextAlign.Center, modifier = Modifier.semantics { heading() })
        Text(description, color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg, textAlign = TextAlign.Center)
        keys?.let {
            Box(Modifier.padding(top = FlareSizes.spacingMd).then(if (phone) Modifier.fillMaxWidth() else Modifier.width(FlareSizes.componentAccountSetupActionWidth))) { it() }
        }
    }
}

/** The account's primary keys at the quick row's size, with the offline caption under them. */
@Composable
private fun quickKeys(
    primary: PluginViewModel,
    actions: @Composable (PluginViewModel, AccountEntry?, PluginViewActionLayout, Boolean) -> Unit,
    offline: Boolean,
    strings: FlareStrings,
) {
    Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
        actions(primary, null, PluginViewActionLayout.Quick, false)
        if (offline) PluginCaption(strings.pluginViewAvailableOnline)
    }
}
