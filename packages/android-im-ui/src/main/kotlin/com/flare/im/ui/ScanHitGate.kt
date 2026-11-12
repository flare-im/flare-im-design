package com.flare.im.ui

/** Pure scan arbitration; no camera, SDK, wall clock, or side effects. */
data class FlareScanPoint(val x: Double, val y: Double)
data class FlareScanCode(val raw: String, val corners: List<FlareScanPoint> = emptyList())
sealed interface FlareScanHit {
    data object Ignore : FlareScanHit
    data class Lock(val code: FlareScanCode, val ready: Boolean) : FlareScanHit
    data class Choose(val codes: List<FlareScanCode>) : FlareScanHit
}
class FlareScanHitGate {
    private var phase = "idle"
    private var startedAt = 0L
    private var lastAt = Long.MIN_VALUE
    private val candidates = linkedMapOf<String, FlareScanCode>()
    private val suppressed = mutableMapOf<String, Long?>()
    private var selected: String? = null

    fun observe(codes: List<FlareScanCode>, tsMs: Long): FlareScanHit {
        if (tsMs < lastAt) return FlareScanHit.Ignore
        lastAt = tsMs
        val visible = codes.filter { it.raw.isNotEmpty() }.associateBy { it.raw }
        for ((raw, absentAt) in suppressed.toMap()) {
            if (absentAt != null && tsMs - absentAt >= 1500) suppressed.remove(raw)
            else if (visible.containsKey(raw)) suppressed[raw] = null
            else if (absentAt == null) suppressed[raw] = tsMs
            else if (tsMs - absentAt >= 1500) suppressed.remove(raw)
        }
        if (phase == "busy" || phase == "choosing") return FlareScanHit.Ignore
        val available = visible.values.filter { !suppressed.containsKey(it.raw) }
        if (phase == "idle") {
            if (available.isEmpty()) return FlareScanHit.Ignore
            phase = "collecting"
            startedAt = tsMs
            candidates.clear()
            available.forEach { candidates[it.raw] = it }
            return FlareScanHit.Lock(available.first(), false)
        }
        available.forEach { candidates[it.raw] = it }
        if (tsMs - startedAt < 150) return FlareScanHit.Ignore
        val found = candidates.values.toList()
        if (found.size > 1) {
            phase = "choosing"
            return FlareScanHit.Choose(found)
        }
        phase = "busy"
        selected = found.first().raw
        return FlareScanHit.Lock(found.first(), true)
    }
    fun select(raw: String): FlareScanHit {
        val code = candidates[raw] ?: return FlareScanHit.Ignore
        if (phase != "choosing") return FlareScanHit.Ignore
        phase = "busy"
        selected = raw
        return FlareScanHit.Lock(code, true)
    }
    /** Discard an interrupted observation window, keeping a user's choices or lock. */
    fun interruptObservations(): Boolean {
        if (phase != "collecting") return false
        candidates.clear()
        selected = null
        startedAt = 0L
        phase = "idle"
        return true
    }
    fun dismiss() {
        (selected?.let { listOf(it) } ?: candidates.keys.toList()).forEach { suppressed[it] = null }
        candidates.clear()
        selected = null
        phase = "idle"
    }
}
