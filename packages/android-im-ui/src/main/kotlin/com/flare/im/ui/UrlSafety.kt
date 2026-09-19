package com.flare.im.ui

import java.net.URI

/**
 * Which URLs a chat surface may navigate to.
 *
 * Message content is written by other people, so a link in it is a string an
 * attacker chose. `javascript:` and `data:` execute in a web view's origin;
 * `file:` and `content:` read local state. The only safe default is: render it
 * as text unless it is plainly a web address.
 *
 * The kit itself almost never navigates — components report the URL and the host
 * opens it. This is the rule both sides apply.
 */
val flareSafeUrlSchemes: List<String> = listOf("http", "https")

/**
 * The URL to navigate to, or null when the string is not a safe web address.
 *
 * A scheme-less string is read as https — that is what a user typing
 * `example.com` means — but only when it carries no scheme at all, so
 * `javascript:alert(1)` is never rescued into `https://javascript:alert(1)`.
 */
fun safeExternalUrl(raw: String?): String? {
    if (raw == null) return null
    // Strip only what a URL parser itself ignores — tab, newline, carriage
    // return — so `java\tscript:` normalizes to `javascript:` before the check.
    // Interior spaces must stay: removing them turns a sentence
    // (`just some text`) into a valid host name.
    val trimmed = raw.trim().filter { it != '\t' && it != '\n' && it != '\r' }
    if (trimmed.isEmpty()) return null
    val candidate = if (hasScheme(trimmed)) trimmed else "https://$trimmed"
    val parsed = runCatching { URI(candidate) }.getOrNull() ?: return null
    val scheme = parsed.scheme?.lowercase() ?: return null
    if (scheme !in flareSafeUrlSchemes) return null
    if (parsed.host.isNullOrEmpty()) return null
    return parsed.toString()
}

/** Whether the string is a web address this surface may open. */
fun isSafeExternalUrl(raw: String?): Boolean = safeExternalUrl(raw) != null

/**
 * `scheme:` at the start, per RFC 3986 — letters, digits, `+`, `-`, `.`.
 *
 * A host and a port look the same to that grammar, so a colon followed by digits
 * is read as a port. Mis-reading that way yields an https URL with an odd host,
 * which is harmless; reading a real scheme as a host is what must not happen.
 */
private fun hasScheme(value: String): Boolean {
    val match = Regex("^[a-z][a-z0-9+.\\-]*:", RegexOption.IGNORE_CASE).find(value) ?: return false
    val rest = value.substring(match.value.length)
    return rest.firstOrNull()?.isDigit() != true
}
