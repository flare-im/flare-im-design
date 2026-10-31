import Foundation

/// The server clock (spec/server-clock-vectors.json). An instant the server issued — a plugin card's deadline or
/// countdown, the end of an invite cooldown — is a reading of the server's clock, so the kit compares it with the
/// server's now, not the device's: a device clock running five minutes fast would otherwise close a vote five minutes
/// early, and one running slow would keep a cooldown on after it ended.
///
/// The kit does not measure the offset. The host hands in the core SDK's estimate (`connection.getServerClock`, server
/// clock minus device clock) whenever it reads one; until then the server's now is the device's.
public enum FlareServerClock {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var offset: Int64 = 0

    /// The offset the kit currently applies (0: the device clock).
    public static var offsetMs: Int64 {
        lock.lock(); defer { lock.unlock() }
        return offset
    }

    /// Hands in the host's estimate of the server clock minus the device clock; nil goes back to the device clock.
    public static func setOffsetMs(_ offsetMs: Int64?) {
        lock.lock(); defer { lock.unlock() }
        offset = offsetMs ?? 0
    }

    /// The server's now, as the kit reads it wherever it compares now with a server-issued instant.
    public static func nowMs() -> Int64 {
        now(deviceNowMs: Int64((Date().timeIntervalSince1970 * 1000).rounded(.down)), offsetMs: offsetMs)
    }

    /// Server now for a device reading and an offset: the device reading itself without an offset.
    public static func now(deviceNowMs: Int64, offsetMs: Int64?) -> Int64 {
        deviceNowMs &+ (offsetMs ?? 0)
    }
}
