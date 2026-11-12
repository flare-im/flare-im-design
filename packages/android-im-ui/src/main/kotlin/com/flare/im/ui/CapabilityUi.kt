package com.flare.im.ui

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.net.URI
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/*
 * Plugin host capability components — pure rules shared by FlareCapabilityConsent, FlareDocumentCapture and
 * FlarePaymentConfirmation (spec/capability-ui-vectors.json; docs/design/plugin-client-hot-delivery.md 7).
 *
 * The kit draws what the engine asks the host (`plugin.capability_request`: consent, captureDocument,
 * confirmPayment). It never runs a request itself: the host listens, shows the component and answers the engine with
 * what the component hands back.
 */

/** The viewer's answer to a consent prompt. */
enum class FlareCapabilityConsentDecision(val wire: String) {
    Once("once"), Always("always"), Deny("deny");

    /** The engine's `{granted}`; when false, [remember] tells the host to revoke a once-grant after the request. */
    val granted: Boolean get() = this != Deny
    val remember: Boolean get() = this == Always
}

object FlareCapabilityRules {
    /** The FlareStrings field naming what a plugin asks to use; an unknown capability is the generic line. */
    fun labelKey(capability: String, params: Map<String, Any?>? = null): String = when (capability) {
        "documentCapture" -> "capabilityDocumentCapture"
        "paymentConfirmation" -> "capabilityPaymentConfirmation"
        "locationOnce" -> if (params?.get("precision") == "fine") "capabilityLocationFine" else "capabilityLocationCoarse"
        "camera" -> "capabilityCamera"
        "microphone" -> "capabilityMicrophone"
        "rtcSession" -> "capabilityRtcSession"
        else -> "capabilityGeneric"
    }

    fun label(strings: FlareStrings, capability: String, params: Map<String, Any?>? = null): String =
        when (labelKey(capability, params)) {
            "capabilityDocumentCapture" -> strings.capabilityDocumentCapture
            "capabilityPaymentConfirmation" -> strings.capabilityPaymentConfirmation
            "capabilityLocationFine" -> strings.capabilityLocationFine
            "capabilityLocationCoarse" -> strings.capabilityLocationCoarse
            "capabilityCamera" -> strings.capabilityCamera
            "capabilityMicrophone" -> strings.capabilityMicrophone
            "capabilityRtcSession" -> strings.capabilityRtcSession
            else -> strings.capabilityGeneric
        }

    /** Whether the consent offers "Always allow": a one-time location is confirmed every time. */
    fun allowsAlways(capability: String): Boolean = capability != "locationOnce"
}

// ── payment confirmation ──────────────────────────────────────────────────

/** The order the engine hands the host (`confirmPayment.order`). */
data class FlarePaymentOrder(
    val orderId: String,
    /** Decimal string, up to 18 fraction digits. */
    val amount: String,
    val currency: String,
    val payee: String,
    val title: String,
    /** Server clock. */
    val expiresAtMs: Long,
    /** The plugin's transient operation; the kit never reads it. */
    val operation: String? = null,
) {
    companion object {
        /** The engine's `order` map; null when a required field is missing. */
        fun fromJson(json: Map<String, Any?>): FlarePaymentOrder? {
            val orderId = json["orderId"] as? String ?: return null
            val amount = json["amount"] as? String ?: return null
            val currency = json["currency"] as? String ?: return null
            val expires = (json["expiresAtMs"] as? Number)?.toLong() ?: return null
            return FlarePaymentOrder(orderId, amount, currency, json["payee"] as? String ?: "", json["title"] as? String ?: "",
                expires, json["operation"] as? String)
        }
    }
}

object FlarePaymentRules {
    private val prefix = mapOf("CNY" to "¥", "USD" to "$", "EUR" to "€", "GBP" to "£", "JPY" to "JP¥", "HKD" to "HK$")
    private val plain = Regex("^(\\d+)(?:\\.(\\d{1,18}))?$")

    /**
     * The amount as the confirmation draws it: the currency's symbol (or the code after the number), the integer part
     * grouped by three, the fraction exactly as written. Never a Double. Null: not a plain non-negative decimal.
     */
    fun amountText(amount: String, currency: String): String? {
        val match = plain.matchEntire(amount) ?: return null
        val digits = match.groupValues[1]
        val whole = StringBuilder()
        digits.forEachIndexed { i, c -> if (i > 0 && (digits.length - i) % 3 == 0) whole.append(','); whole.append(c) }
        val fraction = match.groups[2]?.value
        val number = if (fraction == null) whole.toString() else "$whole.$fraction"
        val code = currency.trim().uppercase()
        prefix[code]?.let { return it + number }
        return if (code.isEmpty()) number else "$number $code"
    }

    /** What is left of an order: whole seconds rounded up, mm:ss under an hour, h:mm:ss from an hour on. */
    fun countdown(remainingMs: Long): Pair<String, Boolean> {
        if (remainingMs <= 0) return "00:00" to true
        val total = (remainingMs + 999) / 1000
        val hours = total / 3600
        val minutes = (total % 3600) / 60
        val seconds = total % 60
        fun two(n: Long) = n.toString().padStart(2, '0')
        return (if (hours > 0) "$hours:${two(minutes)}:${two(seconds)}" else "${two(minutes)}:${two(seconds)}") to false
    }

    /** Confirm takes a tap only with a readable amount, time left and nothing running. */
    fun confirmEnabled(order: FlarePaymentOrder, nowMs: Long, busy: Boolean, confirmDisabled: Boolean): Boolean =
        !busy && !confirmDisabled && amountText(order.amount, order.currency) != null &&
            !countdown(order.expiresAtMs - nowMs).second
}

// ── document capture ─────────────────────────────────────────────────────

/** Which side of a document the capture takes. */
enum class FlareDocumentSide(val wire: String) {
    Front("front"), Back("back"), Holding("holding");

    /** The viewfinder frame's width over height: an ID-1 card for front and back, 3:4 portrait for holding. */
    val frameAspect: Float get() = if (this == Holding) 0.75f else 1.585f
    val fileName: String get() = "document-$wire.jpg"

    companion object {
        fun of(wire: String?): FlareDocumentSide? = entries.firstOrNull { it.wire == wire }
    }
}

/** The photo the capture hands the host: `captureDocument`'s `{file}`. */
class FlareCapturedDocument(val fileName: String, val bytes: ByteArray, val contentType: String = "image/jpeg") {
    /** The engine's `{file}` shape (bytes as a number list). */
    fun toJson(): Map<String, Any> =
        mapOf("fileName" to fileName, "contentType" to contentType, "bytes" to bytes.map { it.toInt() and 0xFF })
}

enum class FlareDocumentProcessError { TooLarge, Failed, NotAccepted }

class FlareDocumentProcessException(val error: FlareDocumentProcessError) : Exception(error.name)

object FlareDocumentRules {
    /** The (longest edge, JPEG quality 0..100) steps the kit tries until the photo fits; none fits: too large. */
    val compressionPlan: List<Pair<Int, Int>> = listOf(
        2048 to 86, 2048 to 72, 2048 to 58, 1600 to 72, 1600 to 58, 1280 to 58, 1024 to 50,
    )

    /** Whether an accept list takes the kit's JPEG (an empty list takes anything). */
    fun acceptsJpeg(accept: List<String>): Boolean =
        accept.isEmpty() || accept.any { it.trim().lowercase() in setOf("image/jpeg", "image/*", "*/*") }

    /** Whether bytes are a JPEG with an APP1 Exif segment before the scan (the engine's jpeg_has_exif). */
    fun jpegHasExif(bytes: ByteArray): Boolean {
        fun at(i: Int) = bytes[i].toInt() and 0xFF
        if (bytes.size < 4 || at(0) != 0xFF || at(1) != 0xD8) return false
        var i = 2
        val exif = intArrayOf(0x45, 0x78, 0x69, 0x66, 0x00, 0x00)
        while (i + 4 <= bytes.size) {
            if (at(i) != 0xFF) return false
            val marker = at(i + 1)
            if (marker == 0xDA || marker == 0xD9) return false
            val length = (at(i + 2) shl 8) or at(i + 3)
            if (length < 2) return false
            if (marker == 0xE1 && i + 10 <= bytes.size && exif.indices.all { at(i + 4 + it) == exif[it] }) return true
            i += 2 + length
        }
        return false
    }

    /** The rotation an EXIF orientation asks for, and whether it mirrors. */
    internal fun orientationMatrix(orientation: Int): Matrix = Matrix().apply {
        when (orientation) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> postScale(-1f, 1f)
            ExifInterface.ORIENTATION_ROTATE_180 -> postRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> postScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> { postRotate(90f); postScale(-1f, 1f) }
            ExifInterface.ORIENTATION_ROTATE_90 -> postRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE -> { postRotate(-90f); postScale(-1f, 1f) }
            ExifInterface.ORIENTATION_ROTATE_270 -> postRotate(270f)
        }
    }

    /**
     * Re-encodes a photo to a JPEG that fits [maxBytes], off the main thread: the EXIF orientation is applied to the
     * pixels, then each step's scaled bitmap is compressed by [Bitmap.compress], which writes no metadata, so nothing
     * of the original file (EXIF, GPS, maker notes, thumbnails) survives. Throws [FlareDocumentProcessException].
     */
    suspend fun process(photo: ByteArray, side: FlareDocumentSide, maxBytes: Int, accept: List<String> = emptyList()): FlareCapturedDocument {
        if (!acceptsJpeg(accept)) throw FlareDocumentProcessException(FlareDocumentProcessError.NotAccepted)
        val out = withContext(Dispatchers.Default) { encode(photo, maxBytes) }
        if (jpegHasExif(out)) throw FlareDocumentProcessException(FlareDocumentProcessError.Failed)
        return FlareCapturedDocument(side.fileName, out)
    }

    private fun encode(photo: ByteArray, maxBytes: Int): ByteArray {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(photo, 0, photo.size, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) throw FlareDocumentProcessException(FlareDocumentProcessError.Failed)
        val orientation = runCatching {
            ExifInterface(ByteArrayInputStream(photo)).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
        }.getOrDefault(ExifInterface.ORIENTATION_NORMAL)
        // Decode no larger than the first step needs (a power of two above it).
        val longest = maxOf(bounds.outWidth, bounds.outHeight)
        var sample = 1
        while (longest / (sample * 2) >= compressionPlan.first().first) sample *= 2
        val decoded = BitmapFactory.decodeByteArray(photo, 0, photo.size, BitmapFactory.Options().apply { inSampleSize = sample })
            ?: throw FlareDocumentProcessException(FlareDocumentProcessError.Failed)
        val upright = Bitmap.createBitmap(decoded, 0, 0, decoded.width, decoded.height, orientationMatrix(orientation), true)
        if (upright !== decoded) decoded.recycle()
        try {
            for ((edge, quality) in compressionPlan) {
                val scale = minOf(1f, edge.toFloat() / maxOf(upright.width, upright.height))
                val scaled = if (scale < 1f) Bitmap.createScaledBitmap(upright, (upright.width * scale).toInt().coerceAtLeast(1),
                    (upright.height * scale).toInt().coerceAtLeast(1), true) else upright
                val buffer = ByteArrayOutputStream()
                val ok = scaled.compress(Bitmap.CompressFormat.JPEG, quality, buffer)
                if (scaled !== upright) scaled.recycle()
                if (!ok) throw FlareDocumentProcessException(FlareDocumentProcessError.Failed)
                if (buffer.size() <= maxBytes) return buffer.toByteArray()
            }
        } finally {
            upright.recycle()
        }
        throw FlareDocumentProcessException(FlareDocumentProcessError.TooLarge)
    }
}

// ── protected media ──────────────────────────────────────────────────────

object FlarePluginProtectedMedia {
    /** The address of [url] a protected media block may draw: https (the server's `?grant=` address) or data:image. */
    fun source(url: String?): String? {
        if (url.isNullOrEmpty()) return null
        if (url.lowercase().startsWith("data:image/")) return url
        val uri = runCatching { URI(url) }.getOrNull() ?: return null
        return if (uri.scheme?.lowercase() == "https" && !uri.host.isNullOrEmpty()) url else null
    }

    /** The address at [urlPath] (a JSON pointer) of a protected media action's result. */
    fun url(result: Any?, urlPath: String): String? {
        var value = result
        for (key in urlPath.split('/').drop(1)) value = (value as? Map<*, *>)?.get(key) ?: return null
        return (value as? String)?.takeIf { it.isNotEmpty() }
    }
}

// ── location input ───────────────────────────────────────────────────────

/** How precise a fix a location input takes. */
enum class PluginLocationPrecision(val wire: String) {
    Coarse("coarse"), Fine("fine");

    companion object {
        fun fromWire(value: String?): PluginLocationPrecision? = entries.firstOrNull { it.wire == value }
    }
}

/**
 * A location input's value (flare-plugin-protocol UiLocationValue): what the engine writes into the input when the
 * viewer's one-time location (locationOnce) completes, already truncated to the input's precision.
 */
data class PluginLocationValue(val latitude: Double, val longitude: Double, val accuracyM: Long, val precision: PluginLocationPrecision) {
    fun toMap(): Map<String, Any> =
        mapOf("latitude" to latitude, "longitude" to longitude, "accuracyM" to accuracyM, "precision" to precision.wire)

    /** The fix as the input shows it: "31.23°N, 121.47°E". */
    val text: String
        get() {
            fun degrees(v: Double): String {
                val a = kotlin.math.abs(v)
                return if (a == Math.rint(a)) a.toLong().toString() else java.math.BigDecimal.valueOf(a).stripTrailingZeros().toPlainString()
            }
            return "${degrees(latitude)}°${if (latitude < 0) "S" else "N"}, ${degrees(longitude)}°${if (longitude < 0) "W" else "E"}"
        }

    companion object {
        private fun places(v: Double): Int = java.math.BigDecimal.valueOf(v).stripTrailingZeros().scale().coerceAtLeast(0)

        /**
         * [value] as a location of [precision] (UiLocationValue::fits): the same precision, a point on the globe, at
         * most 2 (coarse) or 5 (fine) decimal places and a whole accuracy of at least 1000 m or 1 m. Else null.
         */
        fun read(value: Any?, precision: PluginLocationPrecision?): PluginLocationValue? {
            if (value is PluginLocationValue) return read(value.toMap(), precision)
            val map = value as? Map<*, *> ?: return null
            if (precision == null || map["precision"] != precision.wire) return null
            val lat = (map["latitude"] as? Number)?.toDouble() ?: return null
            val lng = (map["longitude"] as? Number)?.toDouble() ?: return null
            val accuracy = (map["accuracyM"] as? Number)?.toDouble() ?: return null
            if (!lat.isFinite() || !lng.isFinite() || !accuracy.isFinite()) return null
            if (lat !in -90.0..90.0 || lng !in -180.0..180.0) return null
            val (maxPlaces, floor) = if (precision == PluginLocationPrecision.Coarse) 2 to 1000.0 else 5 to 1.0
            if (places(lat) > maxPlaces || places(lng) > maxPlaces) return null
            if (accuracy != Math.rint(accuracy) || accuracy < floor) return null
            return PluginLocationValue(lat, lng, accuracy.toLong(), precision)
        }
    }
}

/** What a location input shows while the host locates: the host's state by input id. */
data class PluginLocationState(
    /** The fix the engine wrote (`{kind: "input", input, value}`). */
    val value: PluginLocationValue? = null,
    val locating: Boolean = false,
    val error: String? = null,
)

/** A location input's key: `Locate` runs the page's locationOnce action into the input; `Clear` empties it. */
enum class PluginLocationActionKind { Locate, Clear }

data class PluginLocationAction(
    val action: PluginLocationActionKind,
    val inputId: String,
    val input: PluginInput,
    val formValues: Map<String, Any?>,
)
