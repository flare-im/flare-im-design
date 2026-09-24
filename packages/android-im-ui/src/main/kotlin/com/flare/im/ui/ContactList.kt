package com.flare.im.ui

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch

/**
 * Directory — contacts grouped A-Z with sticky group headers and a side index
 * bar for quick jump. Spec: Contacts/ContactList (`ContactList`). Virtualised.
 *
 * Chinese names index by the pinyin initial of their first character and Latin names by their letter; anything
 * else goes under "#", listed last. Names are ordered by pinyin inside a letter. [Contact.indexKey] overrides both.
 *
 * [selectable] turns the rows into checkboxes: a row is checked when its id is in
 * [selectedIds] and a tap runs [onToggleSelect] instead of [onSelect]. [trailing]
 * renders per-row content at the row end (see [ContactItem]).
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ContactList(
    items: List<Contact>,
    indexed: Boolean = true,
    loading: Boolean = false,
    onSelect: ((Contact) -> Unit)? = null,
    selectable: Boolean = false,
    selectedIds: Set<String> = emptySet(),
    onToggleSelect: ((Contact) -> Unit)? = null,
    trailing: (@Composable (Contact) -> Unit)? = null,
    /**
     * Replaces the kit's own empty state, for a directory that is empty for a reason only the host
     * knows — a filter, a permission, an invitation to add someone.
     */
    empty: (@Composable () -> Unit)? = null,
) {
    val colors = flareColors()
    if (items.isEmpty()) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            if (loading) androidx.compose.material3.CircularProgressIndicator()
            else if (empty != null) empty()
            else EmptyState(title = flareStrings().noContacts)
        }
        return
    }

    val grouped = remember(items) { contactIndexGroups(items) }
    val letters = grouped.map { it.first }

    // flat entries so we can map a letter → its header item index for jump
    data class Entry(val letter: String?, val contact: Contact?)
    val entries = ArrayList<Entry>()
    val headerIndexOf = HashMap<String, Int>()
    for ((letter, people) in grouped) {
        headerIndexOf[letter] = entries.size
        entries.add(Entry(letter, null))
        for (p in people) entries.add(Entry(null, p))
    }

    val listState = rememberLazyListState()
    val scope = rememberCoroutineScope()

    Box(Modifier.fillMaxSize()) {
        LazyColumn(state = listState, modifier = Modifier.fillMaxSize()) {
            entries.forEachIndexed { i, e ->
                if (e.letter != null) {
                    stickyHeader(key = "h-${e.letter}") {
                        Text(
                            e.letter,
                            color = colors.textTertiary,
                            fontSize = FlareSizes.fontSizeSm.value.sp,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.fillMaxWidth().background(colors.bgSecondary)
                                .padding(horizontal = FlareSizes.spacingMd, vertical = FlareSizes.spacingXs),
                        )
                    }
                } else {
                    item(key = e.contact!!.id) {
                        val contact = e.contact
                        ContactItem(
                            item = contact,
                            onSelect = onSelect?.let { cb -> { cb(contact) } },
                            selectable = selectable,
                            selected = contact.id in selectedIds,
                            onToggleSelect = onToggleSelect?.let { cb -> { cb(contact) } },
                            trailing = trailing?.let { slot -> { slot(contact) } },
                        )
                    }
                }
            }
        }

        if (indexed && letters.size > 1) {
            Column(
                Modifier.align(Alignment.CenterEnd).padding(end = 2.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                for (l in letters) {
                    Text(
                        l,
                        color = colors.primaryText,
                        fontSize = FlareSizes.fontSize2xs,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.padding(vertical = 1.dp).clickable {
                            headerIndexOf[l]?.let { idx -> scope.launch { listState.scrollToItem(idx) } }
                        },
                    )
                }
            }
        }
    }
}
