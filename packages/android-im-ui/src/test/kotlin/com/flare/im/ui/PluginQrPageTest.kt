package com.flare.im.ui

import kotlin.test.*

class PluginQrPageTest {
    private fun page(renderer: String = "flare.qr", ttlMs: Long? = 5_000L, interval: Long? = 5_000L): PluginPageViewModel =
        PluginPageViewModel.fromMap(buildMap<String, Any?> {
            put("available", true)
            put("title", "A title cannot replace the provider")
            put("refreshMs", interval)
            put("presentation", mapOf("renderer" to renderer, "props" to buildMap {
                put("token", "0000000000000000000000")
                ttlMs?.let { put("ttlMs", it) }
            }))
        })

    @Test fun qrValidityUsesOnlyMonotonicElapsedTimeAndCannotGoBelowZero() {
        val received = 9_000_000_000L
        assertEquals(5_000L, pluginQrRemainingMs(5_000L, received, received))
        assertEquals(1L, pluginQrRemainingMs(5_000L, received, received + 4_999_000_000L))
        assertEquals(0L, pluginQrRemainingMs(5_000L, received, received + 5_000_000_000L))
        assertEquals(0L, pluginQrRemainingMs(5_000L, received, received + 60_000_000_000L))
    }

    @Test fun qrPresentationPreservesFieldsAndDerivesWindowHintsFromTtl() {
        assertTrue(hasResolvedPresentation(page().view))
        assertTrue(pluginPresentationKeepsFields("flare.qr"))
        assertEquals(PluginSurfaceHints(true, true), pluginPageSurfaceHints(page()))
        assertEquals(PluginSurfaceHints(false, true), pluginPageSurfaceHints(page(ttlMs = null)))
        assertEquals(PluginSurfaceHints(), pluginPageSurfaceHints(page(renderer = "unknown")))
        assertEquals(PluginSurfaceHints(), pluginPageSurfaceHints(page().copy(view = page().view.copy(available = false))))
    }

    @Test fun catalogFailureKeepsPollingButAnExplicitlyNonRefreshingPageStopsIt() {
        val live = page()
        assertEquals(5_000L, live.refreshMs)
        val unreachable = PluginPageViewModel(PluginViewModel(false, "", unavailableReason = PluginUnavailableReason.CatalogUnreachable))
        assertEquals(5_000L, pluginPageRefreshInterval(live.refreshMs, unreachable))
        assertNull(pluginPageRefreshInterval(live.refreshMs, page(interval = null)))
        assertNull(page(interval = 2_999L).refreshMs)
        assertNull(page(interval = 60_001L).refreshMs)
    }
}
