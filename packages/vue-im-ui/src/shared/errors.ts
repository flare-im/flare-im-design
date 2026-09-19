/**
 * The one place a caught value becomes something a person can read (FR-067). Every app was writing
 * `e instanceof Error ? e.message : String(e)` at each catch, which loses an `Error` with an empty
 * message, prints `[object Object]` for a rejected object, and reads as "undefined" for a throw of
 * nothing. The kit answers the question once, and the toast presenter uses it.
 */
export function flareErrorText(error: unknown, fallback = ""): string {
  const text = rawText(error);
  return text || fallback;
}

function rawText(error: unknown): string {
  if (error == null) return "";
  if (typeof error === "string") return error.trim();
  if (error instanceof Error) return error.message.trim();
  if (typeof error === "object") {
    const message = (error as { message?: unknown }).message;
    if (typeof message === "string" && message.trim()) return message.trim();
    // A rejected plain object has no readable text; `String(...)` would print [object Object].
    return "";
  }
  return String(error).trim();
}
