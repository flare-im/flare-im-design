package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse

class ComposerActionsTest {
    private val defaultActions = listOf("image", "file", "voice", "location", "contact")

    @Test fun defaultIdsMatchUnifiedTable() {
        assertEquals(defaultActions, defaultComposerActionIds)
        assertEquals(defaultActions, defaultComposerActions(FlareStrings()).map { it.id })
    }

    @Test fun labelsComeFromStringsProvider() {
        val en = FlareStrings {
            actionImage = "Photo"
            actionFile = "File"
            actionLocation = "Location"
            actionCard = "Card"
            composerVoice = "Voice"
        }
        val labels = defaultComposerActions(en).map { it.label }
        assertEquals(listOf("Photo", "File", "Voice", "Location", "Card"), labels)
        assertEquals(FlareStrings().actionImage, defaultComposerActions(FlareStrings()).first().label)
    }

    @Test fun resolvesHostConfigurationAndCapabilities() {
        val defaults = defaultComposerActions(FlareStrings())
        val actions = listOf(
            defaults[1].copy(order = 30),
            defaults[2].copy(visible = false),
            defaults[0].copy(order = 10, enabled = false),
            defaults[0].copy(id = "order", label = "Order", order = 20, intent = "open-order"),
        )
        val resolved = resolveComposerActions(
            defaults,
            FlareComposerCapabilities(setOf("image", "order", "file")),
            actions,
        )
        assertEquals(listOf("image", "order", "file"), resolved.map { it.id })
        assertFalse(resolved.first().enabled)
        assertEquals("open-order", resolved[1].intent)
    }
}
