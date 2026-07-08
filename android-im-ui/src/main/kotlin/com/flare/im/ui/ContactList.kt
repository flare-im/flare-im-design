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
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ContactList(
    items: List<Contact>,
    indexed: Boolean = true,
    loading: Boolean = false,
    onSelect: ((Contact) -> Unit)? = null,
) {
    val colors = flareColors()
    if (items.isEmpty()) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            if (loading) androidx.compose.material3.CircularProgressIndicator()
            else EmptyState(title = "还没有联系人")
        }
        return
    }

    val grouped = items.groupBy { contactLetter(it) }.toSortedMap()
    val letters = grouped.keys.toList()

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
                                .padding(horizontal = FlareSizes.spacingMd, vertical = 4.dp),
                        )
                    }
                } else {
                    item(key = e.contact!!.id) {
                        ContactItem(item = e.contact, onSelect = onSelect?.let { cb -> { cb(e.contact) } })
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
                        color = colors.primary,
                        fontSize = 10.sp,
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
