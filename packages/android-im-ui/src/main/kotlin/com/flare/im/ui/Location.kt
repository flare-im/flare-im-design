package com.flare.im.ui

import java.util.Locale
import kotlin.math.roundToLong

/**
 * The map service a tenant chose for locations (`chat.location`'s `provider`). It decides which web map a location
 * opens on the web; on Android a location opens the device's map app through `geo:`, and the web map only when no app
 * takes it.
 */
enum class FlareLocationProvider(val wire: String) {
    Osm("osm"),
    Amap("amap");

    companion object {
        /** The provider a wire value names; null for one the kit does not know. */
        fun fromWire(value: String?): FlareLocationProvider? = entries.firstOrNull { it.wire == value }
    }
}

/** A point on the map, WGS-84, as a location message stores it. */
data class FlareLocationCoordinate(val latitude: Double, val longitude: Double)

/** What reverse geocoding a coordinate gives: the place's name and its address line. */
data class FlareLocationAddress(val title: String, val address: String = "")

/**
 * One place: a row of [LocationPicker]'s list, and what the picker sends. [distanceM] is how far it is from the
 * picker's centre, when the search knows.
 */
data class FlareLocationPlace(
    val id: String,
    val title: String,
    val address: String = "",
    val latitude: Double,
    val longitude: Double,
    val distanceM: Double? = null,
) {
    val coordinate: FlareLocationCoordinate get() = FlareLocationCoordinate(latitude, longitude)

    companion object {
        /** The id of the picker's first row, the user's own position. */
        const val CURRENT_ID = "current"
    }
}

/** The links a location opens without a host handler, for one point (`spec/location-vectors.json`). */
data class FlareLocationLinks(val web: String, val apple: String, val geo: String)

/** The lines a location card draws under its map: [primary] always, [secondary] when there is one. */
data class FlareLocationCardLines(val primary: String, val secondary: String?)

/**
 * The location rules every kit shares (`spec/location-vectors.json`): the default links a location opens, the
 * coordinate line shown when there is no map, and a place's distance. Numbers are written with [Locale.ROOT], so a
 * device in a locale with a decimal comma writes the same links.
 */
object FlareLocationFormat {
    /** The zoom the OpenStreetMap link opens at (`osmZoom`). */
    const val OSM_ZOOM = 17

    /** The map area of a [LocationMessage] (`cardMap`); the social SDK asks for its static map at twice it (528×264). */
    const val CARD_MAP_WIDTH = 264
    const val CARD_MAP_HEIGHT = 132

    /**
     * Whether the pair is a coordinate: finite, latitude within ±90, longitude within ±180, and not exactly 0, 0 — the
     * wire writes an absent coordinate as 0, 0, and the SDK never sends it.
     */
    fun isValid(latitude: Double?, longitude: Double?): Boolean =
        latitude != null && longitude != null && latitude.isFinite() && longitude.isFinite() &&
            latitude in -90.0..90.0 && longitude in -180.0..180.0 && !(latitude == 0.0 && longitude == 0.0)

    /** A coordinate in a link: fixed to 6 decimals, trailing zeros and a trailing point dropped, `-0` written `0`. */
    fun coordinate(value: Double): String {
        var text = String.format(Locale.ROOT, "%.6f", value)
        if ('.' in text) text = text.trimEnd('0').trimEnd('.')
        return if (text == "-0") "0" else text
    }

    /**
     * The title as a link carries it: trimmed, then UTF-8 percent-encoded except `A-Z a-z 0-9 - . _ ~`, in capital hex.
     * Null for a blank title.
     */
    fun encodedTitle(title: String?): String? {
        val trimmed = title?.trim().orEmpty()
        if (trimmed.isEmpty()) return null
        val out = StringBuilder()
        for (byte in trimmed.toByteArray(Charsets.UTF_8)) {
            val b = byte.toInt() and 0xFF
            val c = b.toChar()
            if (c in 'A'..'Z' || c in 'a'..'z' || c in '0'..'9' || c == '-' || c == '.' || c == '_' || c == '~') out.append(c)
            else out.append('%').append(String.format(Locale.ROOT, "%02X", b))
        }
        return out.toString()
    }

    /**
     * The web map for [provider]: OpenStreetMap's marker link, or Amap's marker (told the point is WGS-84). Null for an
     * invalid coordinate.
     */
    fun webLink(latitude: Double, longitude: Double, title: String? = null, provider: FlareLocationProvider = FlareLocationProvider.Osm): String? {
        if (!isValid(latitude, longitude)) return null
        val lat = coordinate(latitude)
        val lng = coordinate(longitude)
        return when (provider) {
            FlareLocationProvider.Osm -> "https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=$OSM_ZOOM/$lat/$lng"
            FlareLocationProvider.Amap -> {
                val name = encodedTitle(title)?.let { "&name=$it" }.orEmpty()
                "https://uri.amap.com/marker?position=$lng,$lat$name&coordinate=wgs84&callnative=0"
            }
        }
    }

    /** Apple Maps at the point, named by the title, else by the coordinate pair. Null for an invalid coordinate. */
    fun appleLink(latitude: Double, longitude: Double, title: String? = null): String? {
        if (!isValid(latitude, longitude)) return null
        val pair = "${coordinate(latitude)},${coordinate(longitude)}"
        return "http://maps.apple.com/?ll=$pair&q=${encodedTitle(title) ?: pair}"
    }

    /** The `geo:` URI Android's map apps take, with the title as the pin's label when there is one. Null for an invalid coordinate. */
    fun geoLink(latitude: Double, longitude: Double, title: String? = null): String? {
        if (!isValid(latitude, longitude)) return null
        val pair = "${coordinate(latitude)},${coordinate(longitude)}"
        return "geo:$pair?q=$pair" + (encodedTitle(title)?.let { "($it)" } ?: "")
    }

    /** All three links for a point; null for an invalid or missing coordinate. */
    fun links(latitude: Double?, longitude: Double?, title: String? = null, provider: FlareLocationProvider = FlareLocationProvider.Osm): FlareLocationLinks? {
        if (latitude == null || longitude == null || !isValid(latitude, longitude)) return null
        return FlareLocationLinks(
            web = webLink(latitude, longitude, title, provider) ?: return null,
            apple = appleLink(latitude, longitude, title) ?: return null,
            geo = geoLink(latitude, longitude, title) ?: return null,
        )
    }

    /** The coordinate line shown without a map: each number fixed to 5 decimals, joined by ", ". Null for an invalid coordinate. */
    fun label(latitude: Double, longitude: Double): String? {
        if (!isValid(latitude, longitude)) return null
        fun fixed(value: Double): String = String.format(Locale.ROOT, "%.5f", value).let { if (it == "-0.00000") "0.00000" else it }
        return "${fixed(latitude)}, ${fixed(longitude)}"
    }

    /**
     * The lines a [LocationMessage] draws under its map (`cardLines`): the trimmed title over the trimmed address; a title
     * alone over the coordinate label; an address alone moves up over the coordinate label; neither, the coordinate label
     * alone, or [place] (`locationCardPlace`) without a valid coordinate. Never a blank line.
     */
    fun cardLines(title: String?, address: String?, latitude: Double?, longitude: Double?, place: String): FlareLocationCardLines {
        val name = title?.trim().orEmpty()
        val line = address?.trim().orEmpty()
        val label = if (latitude != null && longitude != null) label(latitude, longitude) else null
        return when {
            name.isNotEmpty() -> FlareLocationCardLines(name, line.ifEmpty { null } ?: label)
            line.isNotEmpty() -> FlareLocationCardLines(line, label)
            else -> FlareLocationCardLines(label ?: place, null)
        }
    }

    /**
     * A place's distance: whole metres below 1000 (rounded half up), else kilometres to one decimal. Null for a missing,
     * negative or non-finite value.
     */
    fun distance(meters: Double?): String? {
        if (meters == null || !meters.isFinite() || meters < 0) return null
        val rounded = meters.roundToLong()
        if (rounded < 1000) return "${rounded}m"
        return String.format(Locale.ROOT, "%.1fkm", meters / 1000)
    }

    /**
     * What the picker asks `previewUrl` for: the map area's logical size (dp) times the screen density clamped to
     * 1..2, each rounded half up — device pixels, never dp (`spec/location-vectors.json` previewSize).
     */
    fun previewPixels(width: Double, height: Double, scale: Double): Pair<Int, Int> {
        val factor = (if (scale.isFinite()) scale else 1.0).coerceIn(1.0, 2.0)
        fun pixels(logical: Double): Int = if (!logical.isFinite() || logical <= 0) 0 else (logical * factor).roundToLong().toInt()
        return pixels(width) to pixels(height)
    }
}

/**
 * The map service a `chat.location` config value names: the string `amap` (trimmed, any case) is AMap, anything else —
 * `osm`, an unknown name, blank, null, not a string — is OpenStreetMap (`spec/location-vectors.json` providerFrom; the
 * same on all four kits). [FlareLocationProvider.fromWire] stays the exact, nullable reading of a wire value.
 */
fun flareLocationProviderFrom(value: Any?): FlareLocationProvider =
    if ((value as? String)?.trim()?.lowercase(Locale.ROOT) == FlareLocationProvider.Amap.wire) FlareLocationProvider.Amap
    else FlareLocationProvider.Osm

/**
 * The web map a host opens for a location message: [FlareLocationFormat.webLink] for [provider] when given, else the
 * location's own, named by its place. Null without a coordinate to open — one of the pair missing, out of range, or
 * exactly 0, 0, which the wire writes for "none" (`spec/location-vectors.json` webMapUrl). The kit card opens the
 * `geo:` link; this is for a host that opens the tenant's web map itself.
 */
fun flareLocationWebMapUrl(location: FlareLocationContent, provider: FlareLocationProvider? = null): String? {
    val latitude = location.latitude ?: return null
    val longitude = location.longitude ?: return null
    if (latitude == 0.0 && longitude == 0.0) return null
    return FlareLocationFormat.webLink(latitude, longitude, location.name, provider ?: location.provider)
}
