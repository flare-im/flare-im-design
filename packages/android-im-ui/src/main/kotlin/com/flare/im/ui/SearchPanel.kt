package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay

data class FlareSearchCriteria(val query: String, val filterId: String, val fromTime: Long? = null, val toTime: Long? = null)
data class FlareSearchRangeOption(val id: String, val label: String, val fromTime: Long? = null, val toTime: Long? = null) {
    val isValid: Boolean get() = (fromTime == null || fromTime in 0..9007199254740991L)
        && (toTime == null || toTime in 0..9007199254740991L)
        && (fromTime == null || toTime == null || fromTime <= toTime)
}
enum class FlareSearchState { Idle, Loading, Success, Failure }
data class FlareSearchSnapshot(
    val criteria: FlareSearchCriteria,
    val state: FlareSearchState,
    val groups: List<SearchResultGroup> = emptyList(),
    val error: String? = null,
)

/** The pause after typing before the panel searches (Vue `SEARCH_DELAY_MS`). */
private const val SEARCH_DELAY_MS = 300L

/**
 * With nothing typed, the first type ([defaultFilter]) and no time range there is nothing to look for: the panel rests
 * idle. A type or a time range alone is a search (inside a conversation "no words + 图片" lists every picture).
 */
internal fun flareSearchIdle(criteria: FlareSearchCriteria, defaultFilter: String): Boolean =
    criteria.query.isBlank() && (criteria.filterId.isEmpty() || criteria.filterId == defaultFilter) &&
        criteria.fromTime == null && criteria.toTime == null

/**
 * Search with filters as a whole page (Vue `FlareSearchPanel layout="page"`): the search field, one row of result types
 * that scrolls sideways with a trailing time-range chip that opens a menu, a hairline, then the results — the only part
 * that scrolls. The host runs the search and reports it back through [snapshot]. Typing searches after a short pause;
 * Enter, clearing, a type or a time range searches at once, and the same criteria are not sent twice unless the last
 * search failed. The last results stay on screen, dimmed, while the next search runs; a failure is a danger banner with
 * a retry of the same criteria. Give it a bounded height (a non-scrolling screen). The time ranges open as a menu
 * anchored to the chip, or as a bottom sheet on the phone form factor; [autofocus] puts the caret in the field on open.
 */
@Composable
fun SearchPanel(
    snapshot: FlareSearchSnapshot,
    filters: Map<String, String>,
    onSearch: (FlareSearchCriteria) -> Unit,
    modifier: Modifier = Modifier,
    onOpen: ((SearchResultItem) -> Unit)? = null,
    onViewAll: ((SearchResultKind) -> Unit)? = null,
    searchText: String? = null,
    idleText: String? = null,
    timeRanges: List<FlareSearchRangeOption> = emptyList(),
    timeRangeText: String? = null,
    autofocus: Boolean = false,
) {
    val strings = flareStrings()
    val colors = flareColors()
    val searchText = searchText ?: strings.search
    val idleText = idleText ?: strings.searchIdleHint
    val timeRangeText = timeRangeText ?: strings.timeRange
    val defaultFilter = filters.keys.firstOrNull().orEmpty()
    val ranges = timeRanges.filter { it.isValid }
    var draft by remember { mutableStateOf(snapshot.criteria.query) }
    var filter by remember { mutableStateOf(snapshot.criteria.filterId) }
    var range by remember { mutableStateOf(snapshot.criteria.fromTime to snapshot.criteria.toTime) }
    var submitted by remember { mutableStateOf(snapshot.criteria) }
    var shown by remember { mutableStateOf(snapshot.takeIf { it.state == FlareSearchState.Success }) }
    var rangeMenuOpen by remember { mutableStateOf(false) }
    val results = rememberScrollState()
    val field = remember { FocusRequester() }
    LaunchedEffect(Unit) { if (autofocus) runCatching { field.requestFocus() } }
    LaunchedEffect(snapshot) {
        if (snapshot.state != FlareSearchState.Success) return@LaunchedEffect
        // Another query's results start at the top.
        if (shown?.criteria != snapshot.criteria) results.scrollTo(0)
        shown = snapshot
    }
    fun submit() {
        val criteria = FlareSearchCriteria(draft.trim(), filter, range.first, range.second)
        val idle = flareSearchIdle(criteria, defaultFilter)
        if (criteria == submitted && !idle && snapshot.state != FlareSearchState.Failure) return
        submitted = criteria
        if (idle) shown = null else onSearch(criteria)
    }
    LaunchedEffect(draft) {
        if (draft.trim() == submitted.query && filter == submitted.filterId && range == (submitted.fromTime to submitted.toTime)) return@LaunchedEffect
        // Clearing the field searches at once; typing waits for a pause.
        if (draft.isNotBlank()) delay(SEARCH_DELAY_MS)
        submit()
    }
    val idle = flareSearchIdle(submitted, defaultFilter)
    val current = submitted == snapshot.criteria
    val waiting = !idle && (!current || snapshot.state == FlareSearchState.Loading)
    val activeRange = ranges.firstOrNull { it.fromTime == range.first && it.toTime == range.second }
    val narrowed = activeRange != null && activeRange.id != ranges.firstOrNull()?.id

    Column(modifier.fillMaxWidth()) {
        Column(
            Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
            verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
        ) {
            Box(Modifier.focusRequester(field)) {
                SearchBar(value = draft, onValueChange = { draft = it }, placeholder = searchText, loading = waiting, onSubmit = ::submit)
            }
            if (filters.size > 1 || ranges.isNotEmpty()) Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.weight(1f)) {
                    if (filters.size > 1) FilterTabs(
                        options = filters.map { (id, label) -> FlareFilterTabOption(value = id, label = label) },
                        selected = filter,
                        onSelect = { filter = it; submit() },
                    )
                }
                // The time range is a filter of the filter: one chip at the end of the row, not a row of its own.
                if (ranges.isNotEmpty()) Box {
                    val shape = RoundedCornerShape(FlareSizes.radiusFull)
                    Row(
                        Modifier.padding(start = FlareSizes.spacingSm).heightIn(min = 30.dp)
                            .background(if (narrowed) colors.primary.copy(alpha = 0.12f) else colors.bgSecondary, shape)
                            .border(1.dp, if (narrowed) colors.primary.copy(alpha = 0.26f) else Color.Transparent, shape)
                            .clickable(role = Role.Button) { rangeMenuOpen = true }
                            .semantics { contentDescription = timeRangeText }
                            .padding(horizontal = FlareSizes.spacingSm),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            if (narrowed) activeRange!!.label else timeRangeText,
                            color = if (narrowed) colors.primaryText else colors.textSecondary,
                            fontSize = FlareSizes.fontSizeSm.value.sp,
                            fontWeight = if (narrowed) FontWeight.SemiBold else FontWeight.Medium,
                        )
                        Box(Modifier.width(4.dp))
                        FlareIcon(name = "chevron-down", size = 16.dp, tint = if (narrowed) colors.primaryText else colors.textSecondary)
                    }
                    val choose = { id: String ->
                        rangeMenuOpen = false
                        ranges.firstOrNull { it.id == id }?.let { range = it.fromTime to it.toTime; submit() }
                    }
                    if (!flareCompactOverlays()) ActionMenu(
                        expanded = rangeMenuOpen,
                        items = ranges.map { FlareActionItem(id = it.id, label = it.label) },
                        onDismiss = { rangeMenuOpen = false },
                        onSelect = { choose(it) },
                        label = timeRangeText,
                    )
                    else if (rangeMenuOpen) BottomSheet(onClose = { rangeMenuOpen = false }, title = timeRangeText) {
                        SettingsList(
                            sections = listOf(SettingsSection(items = ranges.map { SettingsItem(it.id, it.label, kind = FlareSettingKind.Action) })),
                            onSelect = { choose(it.key) },
                            scrollable = false,
                        )
                    }
                }
            }
        }
        HorizontalDivider(thickness = 1.dp, color = colors.borderSecondary)
        Column(Modifier.fillMaxWidth().weight(1f).verticalScroll(results).padding(vertical = FlareSizes.spacingSm)) {
            val status: @Composable (String) -> Unit = { text ->
                Text(text, color = colors.textTertiary, fontSize = FlareSizes.fontSizeMd.value.sp,
                    modifier = Modifier.padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm))
            }
            val done = shown
            when {
                idle -> status(idleText)
                current && snapshot.state == FlareSearchState.Failure -> Box(Modifier.padding(horizontal = FlareSizes.spacingLg)) {
                    StatusBanner(snapshot.error ?: idleText, tone = FlareStatusTone.Danger, actionText = strings.retry, onAction = { onSearch(submitted) })
                }
                done != null -> Box(Modifier.flareDimmed(if (waiting) 0.6f else 1f)) {
                    SearchResults(done.groups, done.criteria.query, onOpen, onViewAll)
                }
                else -> status(strings.searchSearching)
            }
        }
    }
}
