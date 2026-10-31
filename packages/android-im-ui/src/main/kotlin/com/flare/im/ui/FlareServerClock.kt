package com.flare.im.ui

/**
 * The server clock (spec/server-clock-vectors.json). An instant the server issued — a plugin card's deadline or
 * countdown, the end of an invite cooldown — is a reading of the server's clock, so the kit compares it with the
 * server's now, not the device's: a device clock running five minutes fast would otherwise close a vote five minutes
 * early, and one running slow would keep a cooldown on after it ended.
 *
 * The kit does not measure the offset. The host hands in the core SDK's estimate (`connection.getServerClock`, server
 * clock minus device clock) whenever it reads one; until then the server's now is the device's.
 */
object FlareServerClock {
    @Volatile
    private var offset = 0L

    /** The offset the kit currently applies (0: the device clock). */
    val offsetMs: Long get() = offset

    /** Hands in the host's estimate of the server clock minus the device clock; null goes back to the device clock. */
    fun setOffsetMs(offsetMs: Long?) {
        offset = offsetMs ?: 0L
    }

    /** The server's now, as the kit reads it wherever it compares now with a server-issued instant. */
    fun nowMs(): Long = now(System.currentTimeMillis(), offset)

    /** Server now for a device reading and an offset: the device reading itself without an offset. */
    fun now(deviceNowMs: Long, offsetMs: Long?): Long = deviceNowMs + (offsetMs ?: 0L)
}
