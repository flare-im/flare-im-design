/**
 * The server clock (spec/server-clock-vectors.json). An instant the server issued — a plugin card's deadline or
 * countdown, the end of an invite cooldown, the time a feed post was made — is a reading of the server's clock, so
 * the kit compares it with the server's "now", not the device's: a device clock running five minutes fast would
 * otherwise close a vote five minutes early, and one running slow would keep a cooldown on after it ended.
 *
 * The kit does not measure the offset. The host hands in the core SDK's estimate (`connection.getServerClock`,
 * server clock minus device clock) whenever it reads one; until then, and for an offset that is not a finite
 * number, the server's now is the device's.
 */

let offsetMs = 0;

/** The offset as the kit uses it: a finite number of milliseconds (toward zero), else none. */
function usableOffset(offset: unknown): number {
  return typeof offset === "number" && Number.isFinite(offset) ? Math.trunc(offset) : 0;
}

/** Server now for a device reading and an offset: `deviceNowMs + offsetMs`, the device reading without an offset. */
export function flareServerNow(deviceNowMs: number, offset: number | null | undefined): number {
  return deviceNowMs + usableOffset(offset);
}

/** Hands in the host's estimate of the server clock minus the device clock; `null` goes back to the device clock. */
export function setFlareServerClockOffset(offset: number | null | undefined): void {
  offsetMs = usableOffset(offset);
}

/** The offset the kit currently applies (0: the device clock). */
export function flareServerClockOffset(): number {
  return offsetMs;
}

/** The server's now, as the kit reads it wherever it compares now with a server-issued instant. */
export function flareServerNowMs(): number {
  return flareServerNow(Date.now(), offsetMs);
}
