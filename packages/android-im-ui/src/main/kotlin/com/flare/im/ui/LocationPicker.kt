package com.flare.im.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull

/**
 * What [LocationPicker] is showing, as the contract names its states. More than one holds at a time: denied with no
 * results, located with the map unavailable.
 */
enum class FlareLocationPickerStatus { Locating, Located, Denied, Searching, NoResults, MapUnavailable, Sending }

/**
 * The picker's state, without a view: the position, the lists, the search, the selection and the map. Every host
 * answer goes through one of its transitions, so an answer that arrives late (a search the user has typed past, a map
 * for a place no longer selected) is dropped here rather than shown. Each transition returns the next state.
 */
internal data class FlareLocationPickerModel(
    /**
     * The first row, the user's position: the place passed in until a fix arrives, then the fix with what reverse
     * geocoding says about it. Its id is [FlareLocationPlace.CURRENT_ID].
     */
    val current: FlareLocationPlace? = null,
    val locate: Locate = Locate.Locating,
    /** The places around [current], the list for an empty query; null until they have been asked for. */
    val nearby: List<FlareLocationPlace>? = null,
    val query: String = "",
    /** The places for [query]; null while the search runs. */
    val results: List<FlareLocationPlace>? = emptyList(),
    val searchUnavailable: Boolean = false,
    val nearbyUnavailable: Boolean = false,
    val selected: FlareLocationPlace? = null,
    /** The point the map shows and the image for it; [mapUnavailable] once the host had no image for it. */
    val previewing: FlareLocationCoordinate? = null,
    val snapshotUrl: String? = null,
    val mapUnavailable: Boolean = false,
) {
    enum class Locate { Locating, Located, Denied }

    private val searchQuery: String get() = query.trim()
    val isSearching: Boolean get() = searchQuery.isNotEmpty()
    val lookupUnavailable: Boolean get() = if (isSearching) searchUnavailable else nearbyUnavailable

    // Position

    fun locateStarted() = copy(locate = Locate.Locating)

    /**
     * A fix: the first row moves to it (its name comes with [geocoded]). It is selected when nothing is, or when the
     * user asked for it with the locate key ([select]).
     */
    fun located(point: FlareLocationCoordinate, select: Boolean = false): FlareLocationPickerModel {
        val moved = current?.coordinate != point
        val place = FlareLocationPlace(
            id = FlareLocationPlace.CURRENT_ID,
            title = if (moved) "" else current?.title.orEmpty(),
            address = if (moved) "" else current?.address.orEmpty(),
            latitude = point.latitude, longitude = point.longitude,
        )
        val keepSelection = !select && selected != null && selected.id != FlareLocationPlace.CURRENT_ID
        return copy(
            locate = Locate.Located, current = place, nearby = if (moved) null else nearby,
            selected = if (keepSelection) selected else place,
        )
    }

    /** No fix — no permission, a failure or the timeout. The place passed in, if any, stays the first row. */
    fun locateFailed() = copy(locate = Locate.Denied)

    /** What reverse geocoding says about [point]; dropped when the first row has moved on. */
    fun geocoded(address: FlareLocationAddress, point: FlareLocationCoordinate): FlareLocationPickerModel {
        val row = current?.takeIf { it.coordinate == point } ?: return this
        val named = row.copy(title = address.title, address = address.address)
        return copy(current = named, selected = if (selected?.id == FlareLocationPlace.CURRENT_ID) named else selected)
    }

    // Lists

    /** The places around [point]; dropped when the first row has moved on. A place that repeats the first row's id is left out. */
    fun nearbyLoaded(places: List<FlareLocationPlace>, point: FlareLocationCoordinate?): FlareLocationPickerModel {
        if (current?.coordinate != point) return this
        return copy(nearby = places.filter { it.id != FlareLocationPlace.CURRENT_ID }, nearbyUnavailable = false)
    }

    fun nearbyStarted() = copy(nearbyUnavailable = false)

    fun nearbyFailed(point: FlareLocationCoordinate?): FlareLocationPickerModel =
        if (current?.coordinate == point) copy(nearbyUnavailable = true) else this

    /** The user typed: a blank query goes back to the nearby list, any other starts its search. */
    fun queryChanged(text: String): FlareLocationPickerModel {
        val next = copy(query = text)
        return next.copy(results = if (next.isSearching) null else emptyList(), searchUnavailable = false)
    }

    fun searchStarted(text: String): FlareLocationPickerModel =
        if (text == searchQuery) copy(results = null, searchUnavailable = false) else this

    fun searchFailed(text: String): FlareLocationPickerModel =
        if (text == searchQuery) copy(results = emptyList(), searchUnavailable = true) else this

    /** The successful places for [text]; dropped unless it is still the query. */
    fun searchFinished(text: String, places: List<FlareLocationPlace>): FlareLocationPickerModel =
        if (text == searchQuery) copy(results = places, searchUnavailable = false) else this

    fun select(place: FlareLocationPlace) = copy(selected = place)

    // Map

    /** The point the map should show: the selected place, else the first row. */
    val mapCenter: FlareLocationCoordinate? get() = selected?.coordinate ?: current?.coordinate

    fun previewStarted(point: FlareLocationCoordinate): FlareLocationPickerModel =
        if (previewing == point) this else copy(previewing = point, snapshotUrl = null)

    /** The host's map image for [point], or null when it has none; dropped when the map has moved on. */
    fun previewLoaded(url: String?, point: FlareLocationCoordinate): FlareLocationPickerModel {
        if (previewing != point) return this
        val image = url?.trim()?.takeIf { it.isNotEmpty() }
        return copy(snapshotUrl = image, mapUnavailable = image == null)
    }

    // What the view draws

    /** The list: the first row and the nearby places, or the search's places. */
    val rows: List<FlareLocationPlace>
        get() = if (isSearching) results.orEmpty() else listOfNotNull(current) + nearby.orEmpty()

    /** Whether the list is still waiting for its first answer: no position and nothing nearby yet. */
    val waitingForRows: Boolean get() = !isSearching && current == null && locate == Locate.Locating

    val statuses: Set<FlareLocationPickerStatus>
        get() = buildSet {
            add(
                when (locate) {
                    Locate.Locating -> FlareLocationPickerStatus.Locating
                    Locate.Located -> FlareLocationPickerStatus.Located
                    Locate.Denied -> FlareLocationPickerStatus.Denied
                },
            )
            if (isSearching && results == null) add(FlareLocationPickerStatus.Searching)
            if (isSearching && !searchUnavailable && results?.isEmpty() == true) add(FlareLocationPickerStatus.NoResults)
            if (mapUnavailable || lookupUnavailable) add(FlareLocationPickerStatus.MapUnavailable)
        }

    /** [statuses] with the host's send in flight (`sending`). */
    fun statuses(sending: Boolean): Set<FlareLocationPickerStatus> =
        if (sending) statuses + FlareLocationPickerStatus.Sending else statuses

    /** The selected place as it is sent: the first row without a name is called [fallbackTitle]. */
    fun sendable(fallbackTitle: String): FlareLocationPlace? {
        val place = selected ?: return null
        return if (place.title.isBlank()) place.copy(title = fallbackTitle) else place
    }

    companion object {
        /** The picker as it opens: on the last place, if there is one, as its first row and selection. */
        fun initial(place: FlareLocationPlace?): FlareLocationPickerModel {
            val current = place?.copy(id = FlareLocationPlace.CURRENT_ID, distanceM = null)
            return FlareLocationPickerModel(current = current, selected = current)
        }
    }
}

/**
 * [work], or null after [timeoutMs] — whichever comes first. The host's call need not honour cancellation (a location
 * callback wrapped in `suspendCoroutine` does not): the picker stops waiting for it either way. A failure of [work]
 * is thrown.
 */
internal suspend fun <T : Any> flareFirstOrNull(timeoutMs: Long, work: suspend () -> T): T? {
    val answer = CompletableDeferred<T>()
    val worker = CoroutineScope(currentCoroutineContext().minusKey(Job)).launch {
        runCatching { work() }.fold({ answer.complete(it) }, { answer.completeExceptionally(it) })
    }
    return try {
        withTimeoutOrNull(timeoutMs.coerceAtLeast(0)) { answer.await() }
    } finally {
        worker.cancel()
    }
}

/**
 * One locate: the host's permission step first — its wait (the system prompt) is not timed — then the position within
 * [timeoutMs]. Null is denied: no permission (false or a throw, and [request] is not called), a failure, the timeout or
 * an invalid fix.
 */
internal suspend fun flareLocatePosition(
    ensurePermission: (suspend () -> Boolean)?,
    request: suspend () -> FlareLocationCoordinate,
    timeoutMs: Long,
): FlareLocationCoordinate? {
    if (ensurePermission != null) {
        val granted = try {
            ensurePermission()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            false
        }
        if (!granted) return null
    }
    val point = try {
        flareFirstOrNull(timeoutMs) { request() }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        null
    }
    return point?.takeIf { FlareLocationFormat.isValid(it.latitude, it.longitude) }
}

/** The picker map's height; its width is the sheet's. */
private val LOCATION_PICKER_MAP_HEIGHT = 168.dp

/** The list's tallest, so it stays bounded in a host that does not bound it. */
private val LOCATION_PICKER_LIST_MAX_HEIGHT = 360.dp

/** How long typing pauses before the search runs. */
internal const val LOCATION_PICKER_SEARCH_DELAY_MS = 300L

/**
 * Location picker — the content of the kit bottom sheet a location is chosen in. Spec: Message/LocationPicker
 * (`LocationPicker`).
 *
 * A map of the selected place with a centre pin and a key that locates the user again; a search field; the list, whose
 * first row is the user's position ([FlareLocationPlace.CURRENT_ID], named by reverse geocoding, else
 * `locationCurrent`) followed by the places nearby, or the search's places; and the send key.
 *
 * The host does the locating, geocoding, searching and map images through the functions it passes; the kit owns the
 * states ([FlareLocationPickerStatus]):
 * - [initialLocation] (the last place the user sent from) is the first row and the map from the first frame, so the
 *   sheet never opens empty; without it the list starts as a skeleton.
 * - [requestCurrentLocation] throwing, or not answering within [locateTimeoutMs], is `denied`: the picker says the
 *   user can search for a place, and keeps [initialLocation] if there is one. Without the function the picker starts
 *   denied.
 * - [ensurePermission] is the host's permission step, awaited before every locate (the first and the locate key) while
 *   the picker shows locating: the system prompt's wait is not counted, [locateTimeoutMs] starts once it answers true;
 *   false (or a throw) is `denied` at once, without calling [requestCurrentLocation].
 * - [searchNearby] (latitude, longitude, query) is asked with an empty query for the list around the position and with
 *   the user's words (after a short pause in typing) for a search; the coordinate is null while the picker does not
 *   know one.
 * - [previewUrl] (latitude, longitude, zoom, width, height) returning null or throwing is `mapUnavailable`: the map
 *   area shows the coordinate and the address. Width and height are device pixels: the map's size in dp times the
 *   density clamped to 1..2, rounded ([FlareLocationFormat.previewPixels]).
 * - [onSend] receives the selected place; [onCancel] the cancel key. While [sending] the send key spins and is
 *   disabled, so a second tap sends nothing; the host clears it when the send settles.
 * - It draws its own header (Cancel and the title) and declares it ([FlareSheetOwnHeader]): put it in
 *   `BottomSheet(fill = true)` and the sheet keeps its title as the accessible name only, while the list fills the
 *   sheet's height.
 * - [provider] is the tenant's map service: with osm the map preview carries OpenStreetMap's credit
 *   (`locationOsmAttribution`) once the picture shows; never while the map is unavailable, and never for amap.
 */
@Composable
fun LocationPicker(
    initialLocation: FlareLocationPlace? = null,
    zoom: Int = 16,
    locateTimeoutMs: Long = 5000,
    requestCurrentLocation: (suspend () -> FlareLocationCoordinate)? = null,
    reverseGeocode: (suspend (Double, Double) -> FlareLocationAddress)? = null,
    searchNearby: (suspend (Double?, Double?, String) -> List<FlareLocationPlace>)? = null,
    previewUrl: (suspend (Double, Double, Int, Int, Int) -> String?)? = null,
    /** The tenant's map service: osm puts OpenStreetMap's credit on the map preview once it shows. */
    provider: FlareLocationProvider = FlareLocationProvider.Osm,
    /** The host's permission step before each locate: false (or a throw) is denied; its wait is not timed. */
    ensurePermission: (suspend () -> Boolean)? = null,
    /** The host is sending the chosen place: the send key spins and takes no second tap. */
    sending: Boolean = false,
    onSend: ((FlareLocationPlace) -> Unit)? = null,
    onCancel: (() -> Unit)? = null,
) {
    val colors = flareColors()
    val strings = flareStrings()
    var model by remember { mutableStateOf(FlareLocationPickerModel.initial(initialLocation)) }
    var locateRun by remember { mutableIntStateOf(0) }
    var lookupRun by remember { mutableIntStateOf(0) }
    var previewRun by remember { mutableIntStateOf(0) }
    // The map's width in dp; the request is in device pixels.
    var mapWidth by remember { mutableFloatStateOf(0f) }
    val density = LocalDensity.current.density
    val fills = flareSheetFills()
    FlareSheetOwnHeader()
    val permission by rememberUpdatedState(ensurePermission)
    val locateNow by rememberUpdatedState(requestCurrentLocation)
    val geocode by rememberUpdatedState(reverseGeocode)
    val search by rememberUpdatedState(searchNearby)
    val preview by rememberUpdatedState(previewUrl)
    val statuses = model.statuses(sending)

    LaunchedEffect(locateRun) {
        val request = locateNow
        if (request == null) { model = model.locateFailed(); return@LaunchedEffect }
        model = model.locateStarted()
        val point = flareLocatePosition(permission, request, locateTimeoutMs)
        if (point == null) {
            model = model.locateFailed(); return@LaunchedEffect
        }
        model = model.located(point, select = locateRun > 0)
        if (locateRun > 0) model = model.queryChanged("")
        val address = geocode?.let { runCatching { it(point.latitude, point.longitude) }.getOrNull() } ?: return@LaunchedEffect
        model = model.geocoded(address, point)
    }
    LaunchedEffect(model.query, model.current?.coordinate, lookupRun) {
        val text = model.query.trim()
        val host = search ?: return@LaunchedEffect
        val point = model.current?.coordinate
        if (text.isEmpty()) {
            if (point == null) return@LaunchedEffect
            model = model.nearbyStarted()
        } else {
            model = model.searchStarted(text)
            delay(LOCATION_PICKER_SEARCH_DELAY_MS)
        }
        try {
            val places = host(point?.latitude, point?.longitude, text)
            currentCoroutineContext().ensureActive()
            model = if (text.isEmpty()) model.nearbyLoaded(places, point) else model.searchFinished(text, places)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            currentCoroutineContext().ensureActive()
            model = if (text.isEmpty()) model.nearbyFailed(point) else model.searchFailed(text)
        }
    }
    val (previewWidth, previewHeight) =
        FlareLocationFormat.previewPixels(mapWidth.toDouble(), LOCATION_PICKER_MAP_HEIGHT.value.toDouble(), density.toDouble())
    LaunchedEffect(model.mapCenter, previewWidth, previewHeight, previewRun) {
        val point = model.mapCenter ?: return@LaunchedEffect
        if (previewWidth <= 0) return@LaunchedEffect
        model = model.previewStarted(point)
        val host = preview
        val url = host?.let {
            runCatching { it(point.latitude, point.longitude, zoom, previewWidth, previewHeight) }.getOrNull()
        }
        currentCoroutineContext().ensureActive()
        model = model.previewLoaded(url, point)
    }

    Column(Modifier.fillMaxWidth()) {
        // Header: the title, with the cancel key at the leading edge.
        Box(Modifier.fillMaxWidth().padding(horizontal = FlareSizes.spacingSm, vertical = FlareSizes.spacingSm)) {
            Text(
                strings.locationTitle, color = colors.textPrimary, fontSize = FlareSizes.fontSize2xl, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.align(Alignment.Center).semantics { heading() },
            )
            Box(Modifier.align(Alignment.CenterStart)) {
                Button(label = strings.cancel, variant = FlareButtonVariant.Text, size = FlareControlSize.Sm, onClick = { onCancel?.invoke() })
            }
        }
        // Map.
        BoxWithConstraints(
            Modifier.padding(horizontal = FlareSizes.spacingLg).fillMaxWidth().height(LOCATION_PICKER_MAP_HEIGHT)
                .clip(RoundedCornerShape(FlareSizes.radiusCard)),
        ) {
            val width = maxWidth.value
            LaunchedEffect(width) { mapWidth = width }
            if (model.mapUnavailable) {
                FlareMapPlaceholder(Modifier.matchParentSize(), pin = false)
                Column(
                    Modifier.align(Alignment.Center).padding(horizontal = FlareSizes.spacingLg).semantics(mergeDescendants = true) {},
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(FlareSizes.spacingXs),
                ) {
                    Text(strings.locationMapUnavailable, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm, fontWeight = FontWeight.Medium)
                    model.mapCenter?.let { FlareLocationFormat.label(it.latitude, it.longitude) }?.let {
                        Text(it, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg, fontWeight = FontWeight.SemiBold)
                    }
                    model.selected?.address?.takeIf { it.isNotEmpty() }?.let {
                        Text(it, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm, maxLines = 2,
                            overflow = TextOverflow.Ellipsis, textAlign = TextAlign.Center)
                    }
                    Button(label = strings.retry, variant = FlareButtonVariant.Text, size = FlareControlSize.Sm,
                           onClick = { previewRun += 1 })
                }
            } else {
                FlareMapSnapshot(model.snapshotUrl, provider, Modifier.matchParentSize(), pin = false)
                // The point the map shows: the pin's tip at the centre.
                Box(Modifier.align(Alignment.Center).offset(y = -FlareSizes.iconSizeXl / 2)) {
                    FlareIcon("location", size = FlareSizes.iconSizeXl, tint = colors.primaryText)
                }
            }
            Box(Modifier.align(Alignment.BottomEnd).padding(FlareSizes.spacingXs)) {
                IconButton(
                    icon = "locate", contentDescription = strings.locationLocateMe, variant = FlareIconButtonVariant.Tinted,
                    active = FlareLocationPickerStatus.Locating in statuses, background = colors.bgPrimary,
                    onClick = { locateRun += 1 },
                )
            }
        }
        if (FlareLocationPickerStatus.Denied in statuses) {
            Text(
                strings.locationDenied, color = colors.textSecondary, fontSize = FlareSizes.fontSizeSm,
                modifier = Modifier.fillMaxWidth().padding(start = FlareSizes.spacingLg, end = FlareSizes.spacingLg, top = FlareSizes.spacingSm),
            )
        }
        Box(Modifier.padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm)) {
            SearchBar(
                value = model.query, onValueChange = { model = model.queryChanged(it) },
                placeholder = strings.locationSearchPlaceholder, loading = FlareLocationPickerStatus.Searching in statuses,
            )
        }
        // In a filled sheet the list takes the height left; elsewhere it stays bounded.
        val listModifier = if (fills) Modifier.weight(1f) else Modifier.weight(1f, fill = false).heightIn(max = LOCATION_PICKER_LIST_MAX_HEIGHT)
        when {
            model.waitingForRows -> Column(listModifier) {
                LocatingRow()
                Box(Modifier.padding(horizontal = FlareSizes.spacingLg)) { Skeleton(variant = SkeletonVariant.Text, rows = 3) }
            }
            FlareLocationPickerStatus.NoResults in statuses -> Box(listModifier) { EmptyState(title = strings.locationNoResults, icon = "location") }
            FlareLocationPickerStatus.Searching in statuses -> Box(listModifier.fillMaxWidth().padding(FlareSizes.spacingLg), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(Modifier.size(FlareSizes.iconSizeMd), strokeWidth = 2.dp, color = colors.primaryText)
            }
            else -> LazyColumn(listModifier) {
                if (model.lookupUnavailable) item {
                    EmptyState(title = strings.locationMapUnavailable, actionText = strings.retry,
                               icon = "location", tone = FlareEmptyStateTone.Error, onAction = { lookupRun += 1 })
                }
                items(model.rows, key = { it.id }) { place ->
                    LocationPlaceRow(
                        place = place, selected = model.selected?.id == place.id,
                        locating = place.id == FlareLocationPlace.CURRENT_ID && FlareLocationPickerStatus.Locating in statuses,
                        onSelect = { model = model.select(place) },
                    )
                }
            }
        }
        HorizontalDivider(color = colors.borderPrimary)
        Box(Modifier.padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingMd)) {
            // Loading disables the key without dimming it, as on every kit busy key.
            Button(
                label = strings.locationSend, size = FlareControlSize.Lg, loading = sending, disabled = model.selected == null,
                block = true,
                onClick = { if (!sending) model.sendable(strings.locationCurrent)?.let { onSend?.invoke(it) } },
            )
        }
    }
}

/** The list's first row while no position is known yet. */
@Composable
private fun LocatingRow() {
    val colors = flareColors()
    Row(
        Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget).padding(horizontal = FlareSizes.spacingLg)
            .semantics(mergeDescendants = true) {},
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingSm),
    ) {
        CircularProgressIndicator(Modifier.size(FlareSizes.iconSizeSm), strokeWidth = 2.dp, color = colors.primaryText)
        Text(flareStrings().locationLocating, color = colors.textSecondary, fontSize = FlareSizes.fontSizeLg)
    }
}

/** The line under a place's name: its address, "locating" while the first row is being located, and its distance. */
internal fun locationPlaceDetail(place: FlareLocationPlace, locating: Boolean, strings: FlareStrings): String =
    listOfNotNull(place.address, if (locating) strings.locationLocating else null, FlareLocationFormat.distance(place.distanceM))
        .filter { it.isNotEmpty() }
        .joinToString(" · ")

@Composable
private fun LocationPlaceRow(place: FlareLocationPlace, selected: Boolean, locating: Boolean, onSelect: () -> Unit) {
    val colors = flareColors()
    val strings = flareStrings()
    val current = place.id == FlareLocationPlace.CURRENT_ID
    val detail = locationPlaceDetail(place, locating, strings)
    Row(
        Modifier.fillMaxWidth().heightIn(min = FlareSizes.touchTarget)
            .selectable(selected = selected, role = Role.RadioButton, onClick = onSelect)
            .padding(horizontal = FlareSizes.spacingLg, vertical = FlareSizes.spacingSm),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(FlareSizes.spacingMd),
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(FlareSizes.spacing3xs)) {
            Text(
                place.title.ifBlank { strings.locationCurrent }, color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg,
                fontWeight = if (current) FontWeight.SemiBold else FontWeight.Normal, maxLines = 1, overflow = TextOverflow.Ellipsis,
            )
            if (detail.isNotEmpty()) {
                Text(detail, color = colors.textTertiary, fontSize = FlareSizes.fontSizeSm, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
        if (selected) FlareIcon("check", size = FlareSizes.iconSizeMd, tint = colors.primaryText)
    }
}
