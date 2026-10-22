package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/** One person [ContactPicker] offers. [isSelf] marks the user themselves, whose name carries `contactPickerSelfSuffix`. */
data class FlareContactPickerEntry(
    val userId: String,
    val name: String,
    val avatarUrl: String? = null,
    val subtitle: String? = null,
    val isSelf: Boolean = false,
)

/**
 * One tab of [ContactPicker]. The ids [FRIENDS] and [GROUP_MEMBERS] take the kit's tab names when [label] is null; any
 * other id needs its [label].
 */
data class FlareContactPickerGroup(
    val id: String,
    val label: String? = null,
    val entries: List<FlareContactPickerEntry>,
) {
    /** The tab's name: the host's label, else the kit's for a known id, else the id. */
    fun resolvedLabel(strings: FlareStrings): String = label?.takeIf { it.isNotEmpty() } ?: when (id) {
        FRIENDS -> strings.contactPickerFriends
        GROUP_MEMBERS -> strings.contactPickerGroupMembers
        else -> id
    }

    companion object {
        const val FRIENDS = "friends"
        const val GROUP_MEMBERS = "groupMembers"
    }
}

/** The name a row shows: the user's own carries `contactPickerSelfSuffix`. */
internal fun contactPickerDisplayName(entry: FlareContactPickerEntry, strings: FlareStrings): String =
    if (entry.isSelf) entry.name + strings.contactPickerSelfSuffix else entry.name

/** The entries matching [query] (case-insensitive, in the name or the subtitle); all of them for a blank query. */
internal fun filterContactPickerEntries(entries: List<FlareContactPickerEntry>, query: String): List<FlareContactPickerEntry> {
    val needle = query.trim().lowercase()
    if (needle.isEmpty()) return entries
    return entries.filter { it.name.lowercase().contains(needle) || it.subtitle?.lowercase()?.contains(needle) == true }
}

/** The picked entries in the order they were picked, each once, found in whichever group holds them. */
internal fun contactPickerPicked(ids: List<String>, groups: List<FlareContactPickerGroup>): List<FlareContactPickerEntry> {
    val byId = LinkedHashMap<String, FlareContactPickerEntry>()
    for (group in groups) for (entry in group.entries) byId.putIfAbsent(entry.userId, entry)
    return ids.mapNotNull { byId[it] }
}

/** [ids] with [userId] added at the end, or taken out. */
internal fun contactPickerToggled(ids: List<String>, userId: String): List<String> =
    if (userId in ids) ids - userId else ids + userId

/** The list's tallest, so it stays bounded in a host that does not bound it. */
private val CONTACT_PICKER_LIST_MAX_HEIGHT = 420.dp

/**
 * Contact picker — choose the person a contact card shares. Spec: Contacts/ContactPicker (`ContactPicker`).
 *
 * A title with a cancel key, tabs for the groups when there is more than one (friends, group members), a search field
 * ([searchable]) over the open tab's names and subtitles, and a lazy list; a tab with no one, or a search that matches
 * no one, shows `contactPickerEmpty`. The user's own row reads "name（我）".
 *
 * One person ([multiple] off): a tap on a row calls [onSelect] with that entry. Several: rows are checkboxes and the
 * confirm key calls [onSelect] with the entries in the order they were picked.
 *
 * It draws its own header (Cancel, the title) and declares it ([FlareSheetOwnHeader]): put it in
 * `BottomSheet(fill = true)` and the sheet keeps its title as the accessible name only, while the list fills the
 * sheet's height.
 */
@Composable
fun ContactPicker(
    groups: List<FlareContactPickerGroup>,
    searchable: Boolean = true,
    multiple: Boolean = false,
    title: String? = null,
    onSelect: ((List<FlareContactPickerEntry>) -> Unit)? = null,
    onCancel: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    var activeGroup by remember { mutableStateOf(groups.firstOrNull()?.id.orEmpty()) }
    var query by remember { mutableStateOf("") }
    var picked by remember { mutableStateOf(emptyList<String>()) }
    val open = groups.firstOrNull { it.id == activeGroup } ?: groups.firstOrNull()
    val entries = filterContactPickerEntries(open?.entries.orEmpty(), if (searchable) query else "")
    val fills = flareSheetFills()
    FlareSheetOwnHeader()

    Column(Modifier.fillMaxWidth()) {
        Box(Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingSm)) {
            Text(
                title ?: strings.contactPickerTitle, color = colors.textPrimary, fontSize = FlareSizes.fontSize2xl,
                fontWeight = FontWeight.SemiBold, modifier = Modifier.align(Alignment.Center).semantics { heading() },
            )
            Box(Modifier.align(Alignment.CenterStart)) {
                Button(label = strings.cancel, variant = FlareButtonVariant.Text, size = FlareControlSize.Sm, onClick = { onCancel?.invoke() })
            }
        }
        if (groups.size > 1) {
            Box(Modifier.fillMaxWidth().padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, bottom = FlareSizes.spacingSm)) {
                FilterTabs(
                    options = groups.map { FlareFilterTabOption(it.id, it.resolvedLabel(strings)) },
                    selected = open?.id.orEmpty(),
                    onSelect = { activeGroup = it },
                )
            }
        }
        if (searchable) {
            Box(Modifier.padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, bottom = FlareSizes.spacingSm)) {
                SearchBar(value = query, onValueChange = { query = it }, placeholder = strings.contactPickerSearch)
            }
        }
        // In a filled sheet the list takes the height left; elsewhere it stays bounded.
        val listModifier = if (fills) Modifier.weight(1f) else Modifier.weight(1f, fill = false).heightIn(max = CONTACT_PICKER_LIST_MAX_HEIGHT)
        if (entries.isEmpty()) {
            Box(listModifier.fillMaxWidth()) { EmptyState(title = strings.contactPickerEmpty, icon = "people") }
        } else {
            LazyColumn(listModifier) {
                items(entries, key = { it.userId }) { entry ->
                    val contact = Contact(id = entry.userId, name = contactPickerDisplayName(entry, strings),
                        avatarUrl = entry.avatarUrl, signature = entry.subtitle)
                    ContactItem(
                        item = contact, showPresence = false,
                        onSelect = if (multiple) null else { { onSelect?.invoke(listOf(entry)) } },
                        selectable = multiple, selected = entry.userId in picked,
                        onToggleSelect = if (multiple) { { picked = contactPickerToggled(picked, entry.userId) } } else null,
                    )
                }
            }
        }
        if (multiple) {
            HorizontalDivider(color = colors.borderPrimary)
            Row(
                Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
            ) {
                Text(strings.selectedCount(picked.size), color = colors.textSecondary, fontSize = FlareSizes.fontSizeMd)
                Spacer(Modifier.weight(1f))
                Button(
                    label = strings.confirm, disabled = picked.isEmpty(),
                    onClick = { onSelect?.invoke(contactPickerPicked(picked, groups)) },
                )
            }
        }
    }
}
