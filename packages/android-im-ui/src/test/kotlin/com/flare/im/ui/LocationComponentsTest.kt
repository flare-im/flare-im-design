package com.flare.im.ui

import java.io.File
import kotlin.coroutines.suspendCoroutine
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.runBlocking

/**
 * The location family without a UI: the shared link, label and distance rules (`spec/location-vectors.json`), where a
 * card's tap goes, and the picker's states as its model moves through them. Copy is read from the strings table.
 */
class LocationComponentsTest {
    private val s = FlareStrings()

    /** `spec/location-vectors.json`, the table the four kits run. */
    private fun vectors(): Map<*, *> {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "spec/location-vectors.json")
            if (candidate.isFile) return FlareJson.parse(candidate.readText()) as Map<*, *>
            dir = dir.parentFile
        }
        error("spec/location-vectors.json not found above ${File(".").absolutePath}")
    }

    private fun Map<*, *>.number(key: String): Double = (this[key] as Number).toDouble()

    @Test fun linksFollowTheSharedTable() {
        val table = vectors()
        assertEquals(FlareLocationFormat.OSM_ZOOM, (table["osmZoom"] as Number).toInt())
        val rows = table["links"] as List<*>
        assertTrue(rows.size >= 10, "the shared table lost cases: ${rows.size}")
        for (raw in rows) {
            val row = raw as Map<*, *>
            val id = row["id"] as String
            val input = row["input"] as Map<*, *>
            val lat = input.number("latitude")
            val lng = input.number("longitude")
            val title = input["title"] as String?
            val provider = FlareLocationProvider.fromWire(input["provider"] as String?) ?: FlareLocationProvider.Osm
            assertEquals(row["web"], FlareLocationFormat.webLink(lat, lng, title, provider), "$id web")
            assertEquals(row["apple"], FlareLocationFormat.appleLink(lat, lng, title), "$id apple")
            assertEquals(row["geo"], FlareLocationFormat.geoLink(lat, lng, title), "$id geo")
            // The card opens the geo column (and falls back to the web one) when the host takes no tap.
            val links = FlareLocationFormat.links(lat, lng, title, provider)
            assertEquals(row["geo"], links?.geo, "$id card")
            assertEquals(row["web"], links?.web, "$id card fallback")
        }
    }

    @Test fun labelsAndDistancesFollowTheSharedTable() {
        val table = vectors()
        for (raw in table["label"] as List<*>) {
            val row = raw as Map<*, *>
            val input = row["input"] as Map<*, *>
            assertEquals(row["output"], FlareLocationFormat.label(input.number("latitude"), input.number("longitude")), row["id"] as String)
        }
        for (raw in table["distance"] as List<*>) {
            val row = raw as Map<*, *>
            assertEquals(row["output"], FlareLocationFormat.distance((row["input"] as Number?)?.toDouble()), row["id"] as String)
        }
        assertNull(FlareLocationFormat.distance(Double.NaN))
        assertNull(FlareLocationFormat.distance(Double.POSITIVE_INFINITY))
        assertNull(FlareLocationFormat.label(Double.NaN, 0.0))
        assertNull(FlareLocationFormat.links(null, 1.0))
    }

    @Test fun numbersDoNotFollowTheDeviceLocale() {
        val before = java.util.Locale.getDefault()
        try {
            java.util.Locale.setDefault(java.util.Locale.GERMANY)
            assertEquals("31.230417", FlareLocationFormat.coordinate(31.2304167))
            assertEquals("39.90870, 116.39750", FlareLocationFormat.label(39.9087, 116.3975))
            assertEquals("1.2km", FlareLocationFormat.distance(1240.0))
        } finally {
            java.util.Locale.setDefault(before)
        }
    }

    @Test fun providerValuesFollowTheSharedTable() {
        val rows = vectors()["providerFrom"] as List<*>
        assertTrue(rows.size >= 8, "the shared table lost cases: ${rows.size}")
        for (raw in rows) {
            val row = raw as Map<*, *>
            assertEquals(row["output"], flareLocationProviderFrom(row["input"]).wire, row["id"] as String)
        }
    }

    @Test fun webMapUrlsFollowTheSharedTable() {
        val rows = vectors()["webMapUrl"] as List<*>
        assertTrue(rows.size >= 10, "the shared table lost cases: ${rows.size}")
        for (raw in rows) {
            val row = raw as Map<*, *>
            val input = row["input"] as Map<*, *>
            val location = FlareLocationContent(
                name = input["title"] as String? ?: "",
                latitude = (input["latitude"] as Number?)?.toDouble(),
                longitude = (input["longitude"] as Number?)?.toDouble(),
                provider = flareLocationProviderFrom(input["provider"]),
            )
            val provider = row["provider"]?.let { flareLocationProviderFrom(it) }
            assertEquals(row["output"], flareLocationWebMapUrl(location, provider), row["id"] as String)
        }
    }

    @Test fun providersReadTheirWireNames() {
        assertEquals(FlareLocationProvider.Amap, FlareLocationProvider.fromWire("amap"))
        assertEquals(FlareLocationProvider.Osm, FlareLocationProvider.fromWire("osm"))
        assertNull(FlareLocationProvider.fromWire("google"))
    }

    // Message card

    @Test fun theLineUnderTheTitleIsTheAddressElseTheCoordinate() {
        assertEquals("杭州", locationMessageDetail(" 杭州 ", 30.2741, 120.1551))
        assertEquals("30.27410, 120.15510", locationMessageDetail("", 30.2741, 120.1551))
        assertEquals("", locationMessageDetail("", null, null))
    }

    @Test fun theCardOpensTheMapAppElseTheWebMap() {
        val links = FlareLocationFormat.links(30.2741, 120.1551, "西湖", FlareLocationProvider.Amap)!!
        val opened = mutableListOf<String>()
        openLocationLinks(links) { opened += it }
        assertEquals(listOf(links.geo), opened, "a map app takes geo:")
        opened.clear()
        openLocationLinks(links) { uri -> if (uri.startsWith("geo:")) throw IllegalStateException("no map app") else opened += uri }
        assertEquals(listOf(links.web), opened, "no map app: the provider's web map")
        assertTrue(links.web.startsWith("https://uri.amap.com/marker"))
    }

    @Test fun cardTapsGoToCardOpenThenTheMediaHandler() {
        val card = FlareCardContent(title = "Ivy", userId = "u-ivy")
        val people = mutableListOf<String>()
        val media = mutableListOf<FlareMessageContent>()
        contactCardOpener(card, { people += it }, { media += it })!!.invoke("")
        assertEquals(listOf("u-ivy"), people)
        assertTrue(media.isEmpty(), "onCardOpen comes before the media handler")
        val anonymous = FlareCardContent(title = "Someone")
        assertNull(contactCardOpener(anonymous, { people += it }, null), "a card that names no one is not a profile link")
        contactCardOpener(anonymous, { people += it }, { media += it })!!.invoke("")
        assertEquals(listOf<FlareMessageContent>(anonymous), media)
        assertNull(contactCardOpener(card, null, null))
    }

    // Picker model

    private val here = FlareLocationCoordinate(30.2741, 120.1551)
    private val last = FlareLocationPlace("poi-9", "上次的咖啡馆", "延安路", 30.25, 120.16)
    private fun poi(id: String, meters: Double? = null) = FlareLocationPlace(id, "POI $id", "Road $id", 30.27, 120.15, meters)

    @Test fun thePickerOpensOnTheLastPlaceOrASkeleton() {
        val warm = FlareLocationPickerModel.initial(last)
        assertEquals(listOf(FlareLocationPlace.CURRENT_ID), warm.rows.map { it.id })
        assertEquals("上次的咖啡馆", warm.rows.first().title)
        assertEquals(FlareLocationPlace.CURRENT_ID, warm.selected?.id)
        assertEquals(last.coordinate, warm.mapCenter)
        assertEquals(setOf(FlareLocationPickerStatus.Locating), warm.statuses)
        assertFalse(warm.waitingForRows)

        val cold = FlareLocationPickerModel.initial(null)
        assertTrue(cold.rows.isEmpty())
        assertTrue(cold.waitingForRows)
        assertNull(cold.mapCenter)
        assertNull(cold.sendable(s.locationCurrent), "nothing to send yet")
    }

    @Test fun aFixMovesTheFirstRowAndGeocodingNamesIt() {
        var model = FlareLocationPickerModel.initial(last).located(here)
        assertEquals(setOf(FlareLocationPickerStatus.Located), model.statuses)
        assertEquals(here, model.current?.coordinate)
        assertEquals("", model.current?.title, "the old name does not follow a new point")
        assertEquals(s.locationCurrent, model.sendable(s.locationCurrent)?.title)
        model = model.geocoded(FlareLocationAddress("Elsewhere"), last.coordinate)
        assertEquals("", model.current?.title, "geocoding for a point the row has left is dropped")
        model = model.geocoded(FlareLocationAddress("西湖", "杭州"), here)
        assertEquals("西湖", model.rows.first().title)
        assertEquals(FlareLocationPlace(FlareLocationPlace.CURRENT_ID, "西湖", "杭州", here.latitude, here.longitude), model.sendable(s.locationCurrent))
    }

    @Test fun noFixIsDeniedAndKeepsTheLastPlace() {
        val model = FlareLocationPickerModel.initial(last).locateFailed()
        assertEquals(setOf(FlareLocationPickerStatus.Denied), model.statuses)
        assertEquals("上次的咖啡馆", model.rows.first().title)
        val cold = FlareLocationPickerModel.initial(null).locateFailed()
        assertFalse(cold.waitingForRows, "denied: the user searches instead of waiting")
        assertTrue(cold.rows.isEmpty())
    }

    @Test fun nearbyPlacesFollowTheFirstRow() {
        var model = FlareLocationPickerModel.initial(null).located(here)
        model = model.nearbyLoaded(listOf(poi("a")), last.coordinate)
        assertEquals(listOf(FlareLocationPlace.CURRENT_ID), model.rows.map { it.id }, "places around another point are dropped")
        model = model.nearbyLoaded(listOf(poi("a", 12.4), poi(FlareLocationPlace.CURRENT_ID), poi("b", 1240.0)), here)
        assertEquals(listOf(FlareLocationPlace.CURRENT_ID, "a", "b"), model.rows.map { it.id })
        assertEquals("Road a · 12m", locationPlaceDetail(model.rows[1], locating = false, strings = s))
        assertEquals(s.locationLocating, locationPlaceDetail(model.rows[0], locating = true, strings = s))
    }

    @Test fun aSearchRunsShowsNoResultsAndGivesWayToANewerOne() {
        var model = FlareLocationPickerModel.initial(null).located(here).let { it.nearbyLoaded(listOf(poi("a")), here) }
        model = model.queryChanged("cof")
        assertEquals(setOf(FlareLocationPickerStatus.Located, FlareLocationPickerStatus.Searching), model.statuses)
        model = model.queryChanged("coffee").searchFinished("cof", listOf(poi("old")))
        assertTrue(FlareLocationPickerStatus.Searching in model.statuses, "an answer to an older query is dropped")
        model = model.searchFinished("coffee", emptyList())
        assertEquals(setOf(FlareLocationPickerStatus.Located, FlareLocationPickerStatus.NoResults), model.statuses)
        assertTrue(model.rows.isEmpty())
        model = model.queryChanged("coffee shop").searchFinished("coffee shop", listOf(poi("c")))
        assertEquals(listOf("c"), model.rows.map { it.id }, "a search lists its places, without the first row")
        model = model.queryChanged("  ")
        assertEquals(listOf(FlareLocationPlace.CURRENT_ID, "a"), model.rows.map { it.id }, "a blank query is the nearby list")
        assertEquals(setOf(FlareLocationPickerStatus.Located), model.statuses)
    }

    @Test fun selectingAPlaceMovesTheMapAndAMissingImageIsMapUnavailable() {
        var model = FlareLocationPickerModel.initial(null).located(here).previewStarted(here)
            .previewLoaded("https://geo.example.com/a.png", here)
        assertEquals("https://geo.example.com/a.png", model.snapshotUrl)
        val place = FlareLocationPlace("b", "B", latitude = 30.3, longitude = 120.2)
        model = model.select(place)
        assertEquals(place.coordinate, model.mapCenter)
        model = model.previewStarted(place.coordinate)
        assertNull(model.snapshotUrl, "the old point's image does not stand in for the new one")
        model = model.previewLoaded("https://geo.example.com/late.png", here)
        assertNull(model.snapshotUrl, "an image for a point the map has left is dropped")
        model = model.previewLoaded(null, place.coordinate)
        assertTrue(FlareLocationPickerStatus.MapUnavailable in model.statuses)
        assertTrue(model.previewLoaded(" ", place.coordinate).mapUnavailable, "a blank address is no image")
        // A fix keeps the place the user chose; the locate key chooses the position again.
        model = model.located(FlareLocationCoordinate(30.28, 120.16))
        assertEquals("b", model.selected?.id)
        model = model.located(here, select = true)
        assertEquals(FlareLocationPlace.CURRENT_ID, model.selected?.id)
    }

    @Test fun theLocateTimeoutWinsOverAHostThatNeverAnswers() = runBlocking {
        val started = System.nanoTime()
        // A location callback wrapped in suspendCoroutine: not cancellable, and here never answered.
        val never = flareFirstOrNull<FlareLocationCoordinate>(50) { suspendCoroutine { } }
        assertNull(never)
        assertTrue(System.nanoTime() - started < 2_000_000_000L)
        assertEquals(FlareLocationCoordinate(1.0, 2.0), flareFirstOrNull(5000) { FlareLocationCoordinate(1.0, 2.0) })
        val failure = runCatching { flareFirstOrNull<FlareLocationCoordinate>(5000) { throw SecurityException("denied") } }
        assertTrue(failure.exceptionOrNull() is SecurityException, "a refusal is thrown, not waited out")
    }

    @Test fun theCopyExistsInBothLanguages() {
        val en = flareStringsEnglish()
        assertEquals("位置", s.locationTitle)
        assertEquals("Location", en.locationTitle)
        assertEquals("Open in Maps", en.locationOpenInMaps)
        assertEquals("无法获取定位，可以搜索地点", s.locationDenied)
        for ((zh, english) in listOf(
            s.locationSend to en.locationSend, s.locationLocateMe to en.locationLocateMe, s.locationLocating to en.locationLocating,
            s.locationSearchPlaceholder to en.locationSearchPlaceholder, s.locationNoResults to en.locationNoResults,
            s.locationMapUnavailable to en.locationMapUnavailable, s.locationCurrent to en.locationCurrent,
        )) assertNotEquals(zh, english)
    }
}
