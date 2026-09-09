package com.flare.im.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp

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

/** Search controls and a result snapshot. The host owns filtering and latest-request arbitration. */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun SearchPanel(
    snapshot: FlareSearchSnapshot,
    filters: Map<String, String>,
    onSearch: (FlareSearchCriteria) -> Unit,
    onOpen: ((SearchResultItem) -> Unit)? = null,
    onViewAll: ((SearchResultKind) -> Unit)? = null,
    searchText: String = "搜索",
    idleText: String = "输入关键词或选择类型",
    timeRanges: List<FlareSearchRangeOption> = emptyList(),
    timeRangeText: String = "时间范围",
) {
    var query by remember { mutableStateOf(snapshot.criteria.query) }
    var filter by remember { mutableStateOf(snapshot.criteria.filterId) }
    var fromTime by remember { mutableStateOf(snapshot.criteria.fromTime) }
    var toTime by remember { mutableStateOf(snapshot.criteria.toTime) }
    var submitted by remember { mutableStateOf(snapshot.criteria) }
    val submit = {
        submitted = FlareSearchCriteria(query.trim(), filter, fromTime, toTime)
        onSearch(submitted)
    }
    val colors = flareColors()
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        SearchBar(value = query, onValueChange = { query = it }, placeholder = searchText, onSubmit = submit)
        TextButton(onClick = submit, modifier = Modifier.defaultMinSize(minWidth = 48.dp, minHeight = 48.dp)) { Text(searchText) }
        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            filters.forEach { (id, label) ->
                OutlinedButton(
                    onClick = { filter = id; submit() },
                    modifier = Modifier.defaultMinSize(minWidth = 48.dp, minHeight = 48.dp).semantics { selected = filter == id },
                    colors = ButtonDefaults.outlinedButtonColors(containerColor = if (filter == id) colors.bgSelected else colors.bgPrimary),
                ) { Text(label, color = colors.textPrimary) }
            }
        }
        if (timeRanges.isNotEmpty()) {
            Text(timeRangeText, color = colors.textSecondary)
            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                timeRanges.forEach { range ->
                    val active = range.fromTime == fromTime && range.toTime == toTime
                    OutlinedButton(onClick = { fromTime = range.fromTime; toTime = range.toTime; submit() }, enabled = range.isValid,
                        modifier = Modifier.defaultMinSize(minWidth = 48.dp, minHeight = 48.dp).semantics { selected = active },
                        colors = ButtonDefaults.outlinedButtonColors(containerColor = if (active) colors.bgSelected else colors.bgPrimary)) { Text(range.label) }
                }
            }
        }
        when {
            snapshot.criteria != submitted || snapshot.state == FlareSearchState.Loading -> CircularProgressIndicator()
            snapshot.state == FlareSearchState.Failure -> StatusBanner(snapshot.error ?: idleText, tone = FlareStatusTone.Danger, actionText = searchText, onAction = { onSearch(submitted) })
            snapshot.state == FlareSearchState.Success -> SearchResults(snapshot.groups, submitted.query, onOpen, onViewAll)
            else -> Text(idleText, color = colors.textSecondary)
        }
    }
}
