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
    val amount get() = row.cells.firstOrNull()?.text.orEmpty()
    val title get() = (if (separateBadge) null else row.badge?.text) ?: row.cells.getOrNull(1)?.text ?: block.columns.firstOrNull()?.label.orEmpty()
    val walletTitle get() = row.cells.getOrNull(1)?.text.orEmpty()
    val walletCaption get() = block.columns.firstOrNull()?.label.orEmpty()
    val walletFields get() = row.cells.mapIndexedNotNull { index, cell ->
        if (index < 2 || cell.text.isEmpty()) null else block.columns.getOrNull(index)?.let { PluginViewField(it.label, cell.text) }
    }
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
) = AccountViewContent(view, busyActionId, error, formErrors, members, settleToken, onAction, null,
    fileStates = fileStates, onFileAction = onFileAction, membersLoading = membersLoading, membersError = membersError, onMemberSearch = onMemberSearch, onMembersRetry = onMembersRetry, membersRevision = membersRevision)

@OptIn(ExperimentalLayoutApi::class)
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
) {
    val colors = flareColors()
    val strings = flareStrings()
    val locale = LocalConfiguration.current.locales[0]
    var hidden by remember { mutableStateOf(false) }
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
        if (busyActionId != null) return
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
        PluginView(view = projected, embedded = true,
            actionLayout = layout, showError = showError,
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
                    Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusLg)).background(colors.bgSecondary).padding(FlareSizes.spacingLg)) {
                        actions(projection(actions = account.services), null, PluginViewActionLayout.List, flowInlineId == null)
                    }
                }
            }
        } else if (account.layout == AccountLayout.Wallet) {
            item(key = "account:wallet") {
                Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                    AccountHeader {
                        Text(presentation["sectionTitle"] as? String ?: presentation["summaryTitle"] as? String ?: view.title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, fontWeight = FontWeight.SemiBold, modifier = Modifier.semantics { heading() })
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                            if (account.primary.isNotEmpty()) Box(Modifier.weight(1f, fill = false)) { actions(projection(actions = account.primary), null, PluginViewActionLayout.Compact, false) }
                            IconButton(if (hidden) "eye-off" else "eye", if (hidden) strings.accountShowBalance else strings.accountHideBalance, onClick = { hidden = !hidden })
                        }
                    }
                    if (urgent.isNotEmpty()) actions(projection(blocks = urgent), null, PluginViewActionLayout.Inline, false)
                    error?.takeIf { it.isNotEmpty() }?.let { StatusBanner(text = it, tone = FlareStatusTone.Danger) }
                    if (entries.isEmpty()) view.fields.firstOrNull()?.let { first ->
                        Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusLg)).background(colors.bgSecondary).padding(FlareSizes.spacingLg), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                            Text(first.label, color = colors.textSecondary)
                            Text(if (hidden) "••••" else first.value, color = colors.textPrimary, fontSize = FlareSizes.fontSize3xl, fontWeight = FontWeight.SemiBold)
                        }
                    } else BoxWithConstraints {
                        val columns = accountWalletColumnCount(maxWidth, entries.size)
                        Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                            entries.chunked(columns).forEach { row -> Row(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                                row.forEach { entry -> key(entry.id) { Box(Modifier.weight(1f)) {
                                    AccountWalletCard(entry, hidden, busyActionId != null, accountEntryAction(view, entry, false, onAction != null)?.first?.label) { activateEntry(entry) }
                                } } }
                                if (row.size < columns) Spacer(Modifier.weight(1f))
                            } }
                        }
                    }
                }
            }
            if (account.shortcuts.isNotEmpty()) item(key = "account:shortcuts") {
                Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
                    (presentation["shortcutsTitle"] as? String)?.takeIf { it.isNotEmpty() }?.let { Text(it, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, fontWeight = FontWeight.SemiBold, modifier = Modifier.semantics { heading() }) }
                    actions(projection(actions = account.shortcuts), null, PluginViewActionLayout.Compact, false)
                }
            }
            if (entries.isEmpty()) item(key = "account:empty") { EmptyState(title = presentation["emptyTitle"] as? String ?: strings.accountEmpty, description = presentation["emptyDescription"] as? String ?: strings.accountEmptyDescription, icon = "wallet") }
            if (view.fields.isNotEmpty() || otherBlocks.isNotEmpty()) item(key = "account:info") {
                Column {
                    Row(Modifier.fillMaxWidth().clickable(role = Role.Button) { information = !information }.heightIn(min = FlareSizes.touchTarget), verticalAlignment = Alignment.CenterVertically) {
                        Text(presentation["informationTitle"] as? String ?: strings.accountInformation, color = colors.textSecondary, modifier = Modifier.weight(1f))
                        FlareIcon(if (information) "chevron-up" else "chevron-down", tint = colors.textSecondary)
                    }
                    if (information) actions(projection(fields = view.fields.map { if (hidden) it.copy(value = "••••") else it }, blocks = otherBlocks), null, PluginViewActionLayout.Inline, false)
                }
            }
            if (account.services.isNotEmpty()) item(key = "account:services") {
                Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                    (presentation["servicesTitle"] as? String)?.let { Text(it, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, fontWeight = FontWeight.SemiBold, modifier = Modifier.semantics { heading() }) }
                    Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusLg)).background(colors.bgSecondary).padding(FlareSizes.spacingLg)) { actions(projection(actions = account.services), null, PluginViewActionLayout.List, false) }
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
        error?.takeIf { it.isNotEmpty() }?.let { item(key = "account:error") { StatusBanner(text = it, tone = FlareStatusTone.Danger) } }
        }
        view.fields.firstOrNull()?.let { first -> item(key = "account:overview") {
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusLg)).background(colors.bgSecondary).padding(FlareSizes.spacingLg),
                verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(first.label, color = colors.textSecondary, modifier = Modifier.weight(1f))
                    IconButton(icon = if (hidden) "eye-off" else "eye",
                        contentDescription = if (hidden) strings.accountShowBalance else strings.accountHideBalance,
                        onClick = { hidden = !hidden })
                }
                Text(if (hidden) "••••" else first.value, color = colors.textPrimary,
                    fontSize = FlareSizes.componentRedPacketAmountFontSize.value.sp, fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.clearAndSetSemantics { contentDescription = if (hidden) strings.accountBalanceHidden else first.value })
                FlowRow(horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingXl), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                    view.fields.drop(1).forEach { field -> Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                        Text(field.label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
                        Text(if (hidden) "••••" else field.value, color = colors.textPrimary, fontWeight = FontWeight.SemiBold)
                    } }
                }
            }
        } }
        if (presentation["layout"] != "ledger") {
            if (urgent.isNotEmpty()) item(key = "account:notices") { actions(projection(blocks = urgent), null, PluginViewActionLayout.Inline, false) }
            error?.takeIf { it.isNotEmpty() }?.let { item(key = "account:error") { StatusBanner(text = it, tone = FlareStatusTone.Danger) } }
        }
        if (view.fields.isNotEmpty() || presentation["sectionTitle"] is String) item(key = "account:heading") { Text(((view.presentation?.get("props") as? Map<*, *>)?.get("sectionTitle") as? String) ?: strings.accountTransactions, color = colors.textPrimary, fontSize = FlareSizes.fontSize3xl, fontWeight = FontWeight.SemiBold, modifier = Modifier.semantics { heading() }) }
        if (entries.isEmpty()) item(key = "account:empty") { EmptyState(title = presentation["emptyTitle"] as? String ?: strings.accountEmpty, description = presentation["emptyDescription"] as? String ?: strings.accountEmptyDescription, icon = "wallet") }
        entries.forEachIndexed { index, entry ->
            if (account.groupByDate && (index == 0 || day(entry) != day(entries[index - 1]))) item(key = "account:day:${entry.id}") {
                Text(dayLabel(entry), color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm, modifier = Modifier.semantics { heading() })
            }
            item(key = "account:entry:${entry.id}") {
                Row(Modifier.fillMaxWidth().clickable(enabled = busyActionId == null, role = Role.Button) {
                    val action = accountEntryAction(view, entry, busyActionId != null, onAction != null)
                    if (action != null) onAction?.invoke(action.first.id, PluginActionPayload(row = PluginActionRow(entry.row.key, action.second.input))) else selectedId = entry.id
                }
                    .heightIn(min = FlareSizes.touchTarget).padding(vertical = FlareSizes.spacingSm),
                    verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                    Box(Modifier.clip(RoundedCornerShape(FlareSizes.radiusMd)).background(colors.bgSecondary).padding(FlareSizes.spacingSm)) {
                        FlareIcon("wallet", tint = colors.textSecondary)
                    }
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                        Text(entry.title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg, fontWeight = FontWeight.Medium)
                        if (entry.separateBadge) entry.row.badge?.let { PluginBadgeTag(it) }
                        if (entry.subtitle.isNotEmpty()) Text(entry.subtitle, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm, maxLines = 2, overflow = TextOverflow.Ellipsis)
                    }
                    Column(Modifier.weight(1f), horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                        Text(if (hidden && presentation["maskRowAmounts"] == true) "••••" else entry.amount, color = if (entry.amount.startsWith("+")) colors.successText else colors.textPrimary, fontSize = FlareSizes.fontSizeLg, fontWeight = FontWeight.SemiBold)
                        Text(entry.timeMs?.let { Instant.ofEpochMilli(it).atZone(zone).format(DateTimeFormatter.ofPattern("HH:mm", locale)) }.orEmpty(), color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm)
                    }
                    FlareIcon("chevron-right", size = FlareSizes.iconSizeSm, tint = colors.textTertiary)
                }
            }
        }
        if (otherBlocks.isNotEmpty()) item(key = "account:info") {
            Column {
                Row(Modifier.fillMaxWidth().clickable(role = Role.Button) { information = !information }.heightIn(min = FlareSizes.touchTarget), verticalAlignment = Alignment.CenterVertically) {
                    Text(presentation["informationTitle"] as? String ?: strings.accountInformation, color = colors.textSecondary, modifier = Modifier.weight(1f))
                    FlareIcon(if (information) "chevron-up" else "chevron-down", tint = colors.textSecondary)
                }
                if (information) actions(projection(blocks = otherBlocks), null, PluginViewActionLayout.Inline, false)
            }
        }
        if ((view.actions + view.menuActions).isNotEmpty()) item(key = "account:services") {
            Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                (presentation["servicesTitle"] as? String)?.let { Text(it, color = colors.textPrimary, fontSize = FlareSizes.fontSizeXl, fontWeight = FontWeight.SemiBold, modifier = Modifier.semantics { heading() }) }
                Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(FlareSizes.radiusLg)).background(colors.bgSecondary).padding(FlareSizes.spacingLg)) {
                    actions(projection(actions = view.actions + view.menuActions), null, PluginViewActionLayout.List, false)
                }
            }
        }
        }
        list?.footer?.invoke(this)
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
private fun AccountWalletCard(entry: AccountEntry, hidden: Boolean, disabled: Boolean, directLabel: String?, onSelect: () -> Unit) {
    val colors = flareColors()
    val strings = flareStrings()
    val interaction = remember { MutableInteractionSource() }
    val focused by interaction.collectIsFocusedAsState()
    val hovered by interaction.collectIsHoveredAsState()
    val shape = RoundedCornerShape(FlareSizes.radiusLg)
    Column(Modifier.fillMaxWidth().clip(shape).background(colors.bgSecondary)
        .border(if (focused) 3.dp else 1.dp, if (focused && !disabled) colors.focusRing else if (hovered && !disabled) colors.borderHover else colors.borderSecondary, shape)
        .clickable(enabled = !disabled, role = Role.Button, onClickLabel = directLabel ?: strings.accountEntryDetails, interactionSource = interaction, indication = androidx.compose.foundation.LocalIndication.current, onClick = onSelect).padding(FlareSizes.spacingLg),
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            FlareIcon("wallet", tint = colors.primaryText)
            Spacer(Modifier.width(FlareSizes.spacingSm))
            Text(entry.walletTitle, color = colors.textPrimary, fontSize = FlareSizes.fontSize4xl, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
            if (directLabel == null) FlareIcon("chevron-right", size = FlareSizes.iconSizeSm, tint = colors.textSecondary)
        }
        Text(entry.walletCaption, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
        Text(if (hidden) "••••" else entry.amount, color = colors.textPrimary, fontSize = FlareSizes.fontSize5xl, fontWeight = FontWeight.Bold,
            modifier = Modifier.clearAndSetSemantics { contentDescription = if (hidden) strings.accountBalanceHidden else entry.amount })
        Column(verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm)) {
            entry.walletFields.chunked(2).forEach { fields -> Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                fields.forEach { field -> Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                    Text(field.label, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
                    Text(if (hidden) "••••" else field.value, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg, fontWeight = FontWeight.Medium)
                } }
                if (entry.walletFields.size > 1 && fields.size < 2) Spacer(Modifier.weight(1f))
            } }
        }
        if (directLabel != null) {
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
