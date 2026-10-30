package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter

/** Explicit visual contract selected by the product; no plugin IDs or financial rules in the kit. */
enum class FlarePluginPageAppearance { Document, Account }

internal data class AccountEntry(val id: String, val block: PluginRowsBlock, val row: PluginRow) {
    val amount get() = row.cells.firstOrNull()?.text.orEmpty()
    val title get() = row.badge?.text ?: row.cells.getOrNull(1)?.text ?: block.columns.firstOrNull()?.label.orEmpty()
    val subtitle get() = row.cells.mapIndexedNotNull { i, cell ->
        cell.text.takeIf { i >= (if (row.badge == null) 2 else 1) && i < 3 && block.columns.getOrNull(i)?.format != PluginRowsFormat.Time && it.isNotEmpty() }
    }.joinToString(" · ")
    val timeMs get() = block.columns.indexOfFirst { it.format == PluginRowsFormat.Time }.let { row.cells.getOrNull(it)?.timeMs }
}

internal fun accountEntries(view: PluginViewModel): List<AccountEntry> = view.blocks.flatMapIndexed { index, block ->
    if (block is PluginRowsBlock) PluginViewFormat.rowsOnce(block.rows).map { AccountEntry("$index/${it.key}", block, it) }
    else emptyList()
}

/** Ledger over resolved rows. Amount text and row action input are emitted unchanged. */
@Composable
fun FlareAccountView(
    view: PluginViewModel,
    busyActionId: String? = null,
    error: String? = null,
    formErrors: List<PluginFormError> = emptyList(),
    members: List<PluginMember> = emptyList(),
    settleToken: Int = 0,
    onAction: ((String, PluginActionPayload) -> Unit)? = null,
) = AccountViewContent(view, busyActionId, error, formErrors, members, settleToken, onAction, null)

@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun AccountViewContent(
    view: PluginViewModel, busyActionId: String?, error: String?, formErrors: List<PluginFormError>,
    members: List<PluginMember>, settleToken: Int, onAction: ((String, PluginActionPayload) -> Unit)?, list: PluginViewList?,
) {
    val colors = flareColors()
    val strings = flareStrings()
    val locale = LocalConfiguration.current.locales[0]
    var hidden by remember { mutableStateOf(false) }
    var information by remember { mutableStateOf(false) }
    var selectedId by remember { mutableStateOf<String?>(null) }
    val entries = remember(view) { accountEntries(view) }
    val presentation = view.presentation?.get("props") as? Map<*, *> ?: emptyMap<Any, Any>()
    val detailTitle = presentation["detailTitle"] as? String ?: presentation["sectionTitle"] as? String ?: strings.accountEntryDetails
    val urgent = remember(view) { view.blocks.filter { it is PluginNoteBlock && it.tone in listOf(PluginTone.Warning, PluginTone.Danger) } }
    val otherBlocks = remember(view) { view.blocks.filterNot { it is PluginRowsBlock || it in urgent } }
    val selected = entries.firstOrNull { it.id == selectedId }
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
    fun projection(actions: List<PluginViewAction> = emptyList(), blocks: List<PluginBlock> = emptyList()) =
        view.copy(fields = emptyList(), actions = actions, blocks = blocks, menuActions = emptyList(), detail = false, nextCursor = null)
    val actions: @Composable (PluginViewModel, AccountEntry?) -> Unit = { projected, entry ->
        PluginView(view = projected, embedded = true,
            busyActionId = busyActionId, error = error, formErrors = formErrors, members = members, settleToken = settleToken,
            onAction = onAction?.let { emit -> { id, payload ->
                val binding = entry?.row?.actions?.firstOrNull { it.id == id }
                emit(id, if (entry == null || binding == null) payload else payload.copy(row = PluginActionRow(entry.row.key, binding.input)))
            } })
    }
    if (!view.available) { actions(view, null); return }
    LazyColumn(
        state = list?.state ?: rememberLazyListState(),
        contentPadding = list?.contentPadding ?: PaddingValues(FlareSizes.spacingLg),
        verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
    ) {
        list?.header?.invoke(this)
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
        if (urgent.isNotEmpty()) item(key = "account:notices") { actions(projection(blocks = urgent), null) }
        item(key = "account:actions") { actions(projection(actions = view.actions + view.menuActions), null) }
        if (view.fields.isNotEmpty() || presentation["sectionTitle"] is String) item(key = "account:heading") { Text(((view.presentation?.get("props") as? Map<*, *>)?.get("sectionTitle") as? String) ?: strings.accountTransactions, color = colors.textPrimary, fontSize = FlareSizes.fontSize3xl, fontWeight = FontWeight.SemiBold) }
        if (entries.isEmpty()) item(key = "account:empty") { EmptyState(title = presentation["emptyTitle"] as? String ?: strings.accountEmpty, description = presentation["emptyDescription"] as? String ?: strings.accountEmptyDescription, icon = "wallet") }
        entries.forEachIndexed { index, entry ->
            if (presentation["groupByDate"] != false && (index == 0 || day(entry) != day(entries[index - 1]))) item(key = "account:day:${entry.id}") {
                Text(dayLabel(entry), color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm)
            }
            item(key = "account:entry:${entry.id}") {
                Row(Modifier.fillMaxWidth().clickable(enabled = busyActionId == null, role = Role.Button) { selectedId = entry.id }
                    .heightIn(min = FlareSizes.touchTarget).padding(vertical = FlareSizes.spacingSm),
                    verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
                    Box(Modifier.clip(RoundedCornerShape(FlareSizes.radiusMd)).background(colors.bgSecondary).padding(FlareSizes.spacingSm)) {
                        FlareIcon("wallet", tint = colors.textSecondary)
                    }
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                        Text(entry.title, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg, fontWeight = FontWeight.Medium)
                        if (entry.subtitle.isNotEmpty()) Text(entry.subtitle, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm, maxLines = 2, overflow = TextOverflow.Ellipsis)
                    }
                    Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs)) {
                        Text(if (hidden && presentation["maskRowAmounts"] == true) "••••" else entry.amount, color = if (entry.amount.startsWith("+")) colors.successText else colors.textPrimary, fontWeight = FontWeight.SemiBold)
                        Text(entry.timeMs?.let { Instant.ofEpochMilli(it).atZone(zone).format(DateTimeFormatter.ofPattern("HH:mm", locale)) }.orEmpty(), color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm)
                    }
                    FlareIcon("chevron-right", size = FlareSizes.iconSizeSm, tint = colors.textTertiary)
                }
            }
        }
        if (otherBlocks.isNotEmpty()) item(key = "account:info") {
            Column {
                Row(Modifier.fillMaxWidth().clickable(role = Role.Button) { information = !information }.heightIn(min = FlareSizes.touchTarget), verticalAlignment = Alignment.CenterVertically) {
                    Text(strings.accountInformation, color = colors.textSecondary, modifier = Modifier.weight(1f))
                    FlareIcon(if (information) "chevron-up" else "chevron-down", tint = colors.textSecondary)
                }
                if (information) actions(projection(blocks = otherBlocks), null)
            }
        }
        list?.footer?.invoke(this)
    }
    if (selected != null) BottomSheet(onClose = { selectedId = null }, title = detailTitle, titleHidden = true, dismissible = busyActionId == null) {
        Column(Modifier.verticalScroll(rememberScrollState()).padding(FlareSizes.spacingLg), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(detailTitle, color = colors.textPrimary, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                IconButton("close", strings.close, disabled = busyActionId != null, onClick = { selectedId = null })
            }
            Text(selected.amount, color = if (selected.amount.startsWith("+")) colors.successText else colors.textPrimary,
                fontSize = FlareSizes.fontSize5xl, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(vertical = FlareSizes.spacingMd))
            selected.row.badge?.let { AccountDetailLine(strings.accountType, it.text) }
            selected.row.cells.forEachIndexed { index, cell -> if (index > 0) {
                val column = selected.block.columns.getOrNull(index)
                AccountDetailLine(column?.label.orEmpty(), if (column?.format == PluginRowsFormat.Time && cell.timeMs != null)
                    Instant.ofEpochMilli(cell.timeMs).atZone(zone).format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm", locale)) else cell.text)
            } }
            AccountDetailLine(presentation["rowKeyLabel"] as? String ?: strings.accountEntryId, selected.row.key)
            actions(projection(actions = selected.block.actions.filter { a -> selected.row.actions.any { it.id == a.id } }), selected)
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
