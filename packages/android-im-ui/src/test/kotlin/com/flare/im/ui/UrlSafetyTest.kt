package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * DoD 32 — the vector table of spec/security-boundary.json. Every hostile entry
 * is something an attacker can put in a message; the four platforms run the same
 * ids and tooling/check-security-boundary.mjs fails when one stops.
 */
class UrlSafetyTest {
    private val hostile = listOf(
        "javascript.plain" to "javascript:alert(1)",
        "javascript.uppercase" to "JaVaScRiPt:alert(1)",
        "javascript.leadingSpace" to "   javascript:alert(1)",
        "javascript.embeddedTab" to "java\tscript:alert(1)",
        "javascript.embeddedNewline" to "java\nscript:alert(1)",
        "data.html" to "data:text/html,<script>alert(1)</script>",
        "data.base64" to "data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==",
        "vbscript" to "vbscript:msgbox(1)",
        "file" to "file:///etc/passwd",
        "blob" to "blob:https://evil.example/9b2d",
        "about" to "about:blank",
        "empty" to "",
        "whitespace" to "   ",
        "notAUrl" to "just some text",
    )

    private val allowed = listOf(
        "http" to "http://example.com/path?q=1",
        "https" to "https://example.com/path#anchor",
        "schemeless" to "example.com/path",
        "schemelessWithPort" to "example.com:8443/path",
    )

    @Test fun refusesEveryHostileVector() {
        for ((id, input) in hostile) {
            assertNull(safeExternalUrl(input), id)
            assertFalse(isSafeExternalUrl(input), id)
        }
    }

    @Test fun allowsPlainWebAddresses() {
        for ((id, input) in allowed) assertTrue(isSafeExternalUrl(input), id)
    }

    @Test fun readsASchemeLessStringAsHttpsAndNeverRescuesOneThatHasAScheme() {
        assertEquals("https://example.com", safeExternalUrl("example.com"))
        assertNull(safeExternalUrl("javascript:alert(1)"))
    }

    @Test fun refusesNullWithoutThrowing() {
        assertNull(safeExternalUrl(null))
        assertFalse(isSafeExternalUrl(null))
    }
}
