package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * The shell contract (FR-095) as far as it is arithmetic: which destinations a shell keeps, when its phone navigation
 * shows, and how a destination counts the pages beyond its root. The composition itself (the saveable state holder,
 * the navigation in place) runs on a device: see the instrumented `ShellContractTest`.
 */
class FlareShellTest {
    @Test fun aShellKeepsEveryDestinationOpenedSoFarAndAddsTheActiveOne() {
        val known = setOf("chats", "contacts", "me")
        assertEquals(listOf("chats"), flareShellDestinations(emptyList(), "chats", known))
        assertEquals(listOf("chats", "contacts"), flareShellDestinations(listOf("chats"), "contacts", known))
        assertEquals(listOf("chats", "contacts"), flareShellDestinations(listOf("chats", "contacts"), "chats", known))
    }

    @Test fun aDestinationWhoseNavigationItemIsGoneIsDropped() {
        assertEquals(listOf("contacts"), flareShellDestinations(listOf("chats", "contacts"), "contacts", setOf("contacts")))
        // The active one stays even before its item is registered.
        assertEquals(listOf("draft"), flareShellDestinations(listOf("chats"), "draft", emptySet()))
    }

    @Test fun thePhoneNavigationStepsAsideForAPageBeyondTheRootAndARailNever() {
        assertEquals(true, flareShellNavigationVisible(FlareApplicationResponsiveMode.Mobile, 0))
        assertEquals(false, flareShellNavigationVisible(FlareApplicationResponsiveMode.Mobile, 1))
        assertEquals(false, flareShellNavigationVisible(FlareApplicationResponsiveMode.Mobile, 2))
        for (mode in listOf(FlareApplicationResponsiveMode.Tablet, FlareApplicationResponsiveMode.Desktop, FlareApplicationResponsiveMode.WideDesktop)) {
            assertEquals(true, flareShellNavigationVisible(mode, 1), mode.name)
        }
    }

    @Test fun aDestinationCountsItsPagesAndNeverGoesBelowItsRoot() {
        val registry = FlareDestinationDepthRegistry()
        registry.enter()
        registry.enter()
        assertEquals(2, registry.depth)
        registry.leave()
        registry.leave()
        registry.leave()
        assertEquals(0, registry.depth)
    }
}
