package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

/** Bundle WebView storage per user (design 8.5) and the reply channel across reloads. */
class PluginBundleStorageTest {
    private val origin = "https://abcdefgh.plugin.flare.invalid"

    @Test fun eachUserGetsAProfileOfTheirOwn() {
        val a = pluginBundleProfileName("prod|0|1001")
        val b = pluginBundleProfileName("prod|0|1002")
        assertNotEquals(a, b)
        assertEquals(a, pluginBundleProfileName("prod|0|1001"))
        assertTrue(a.startsWith("$PLUGIN_BUNDLE_PROFILE_PREFIX-"))
        // The name never carries the user id itself.
        assertFalse(a.contains("1001"))
        assertTrue(a.removePrefix("$PLUGIN_BUNDLE_PROFILE_PREFIX-").all { it in '0'..'9' || it in 'a'..'f' })
        assertEquals("$PLUGIN_BUNDLE_PROFILE_PREFIX-anonymous", pluginBundleProfileName(null))
        assertEquals("$PLUGIN_BUNDLE_PROFILE_PREFIX-anonymous", pluginBundleProfileName(" "))
    }

    @Test fun cookieNamesAndTheirExpiry() {
        assertEquals(listOf("a", "track", "b"), pluginBundleCookieNames("a=1; track=x=y; b=; a=2"))
        assertEquals(emptyList(), pluginBundleCookieNames(null))
        assertEquals(emptyList(), pluginBundleCookieNames(""))
        val expired = pluginBundleExpiredCookie("track", "/assets")
        assertTrue(expired.startsWith("track=;"))
        assertTrue(expired.contains("Max-Age=0"))
        assertTrue(expired.contains("Path=/assets"))
    }

    @Test fun cookiePathsCoverEveryFolderAndFile() {
        val paths = pluginBundleCookiePaths(listOf("index.html", "assets/app.js", "assets/img/a.png"))
        assertEquals("/", paths.first())
        listOf("/index.html", "/assets", "/assets/", "/assets/img", "/assets/img/", "/assets/img/a.png").forEach {
            assertTrue(it in paths, it)
        }
        assertEquals(paths.size, paths.toSet().size)
    }

    @Test fun anOriginIsWipedOnlyWhenItsLastPageCloses() {
        val ledger = PluginBundleStorageLedger()
        val first = PluginBundleStorageLease(origin, "p-a", listOf("/"))
        val second = PluginBundleStorageLease(origin, "p-a", listOf("/", "/v2"))
        val other = PluginBundleStorageLease("https://zzzz.plugin.flare.invalid", "p-a", listOf("/"))
        assertTrue(ledger.isEmpty())
        ledger.opened(first)
        ledger.opened(second)
        ledger.opened(other)
        assertTrue(ledger.inUse("p-a"))
        assertFalse(ledger.inUse(null))
        // Another page of the same origin still runs.
        assertFalse(ledger.closed(first))
        assertTrue(ledger.closed(second))
        assertTrue(ledger.closed(other))
        assertTrue(ledger.isEmpty())
        assertFalse(ledger.inUse("p-a"))
        // A lease that was never opened wipes nothing.
        assertFalse(ledger.closed(first))
    }

    @Test fun theSameLeaseTwiceCountsTwice() {
        val ledger = PluginBundleStorageLedger()
        val lease = PluginBundleStorageLease(origin, null, listOf("/"))
        ledger.opened(lease)
        ledger.opened(lease)
        assertTrue(ledger.inUse(null))
        assertFalse(ledger.closed(lease))
        assertTrue(ledger.closed(lease))
        assertFalse(ledger.inUse(null))
    }

    @Test fun repliesFollowTheDocumentThatSpokeLast() {
        val sent = mutableListOf<Pair<String, String>>()
        val reply = PluginBundleReply<String> { proxy, envelope -> sent += proxy to envelope }
        reply.post("hello")
        assertEquals(emptyList(), sent)
        reply.speaking("doc1")
        assertEquals(listOf("doc1" to "hello"), sent)
        reply.post("e1")
        // location.reload(): a new document starts; answers wait for it instead of going to the old proxy.
        reply.documentStarted()
        reply.post("e2")
        assertEquals(listOf("doc1" to "hello", "doc1" to "e1"), sent)
        reply.speaking("doc2")
        reply.post("e3")
        assertEquals(listOf("doc1" to "hello", "doc1" to "e1", "doc2" to "e2", "doc2" to "e3"), sent)
        // Even without a start notice, a message from a new document moves the channel to it.
        reply.speaking("doc3")
        reply.post("e4")
        assertEquals("doc3" to "e4", sent.last())
    }

    @Test fun waitingRepliesAreBoundedAndDroppedWhenThePageGoes() {
        val sent = mutableListOf<String>()
        val reply = PluginBundleReply<String> { _, envelope -> sent += envelope }
        repeat(PLUGIN_BUNDLE_PENDING_LIMIT + 10) { reply.post("e$it") }
        reply.speaking("doc")
        assertEquals(PLUGIN_BUNDLE_PENDING_LIMIT, sent.size)
        sent.clear()
        reply.reset()
        reply.post("late")
        reply.speaking("doc")
        assertEquals(listOf("late"), sent)
        reply.reset()
        reply.speaking("other")
        assertEquals(listOf("late"), sent)
    }
}
