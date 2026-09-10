package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ComposerActionsTest {
    private val unifiedCore = listOf("image", "camera", "file", "location", "card", "vote", "task", "schedule")

    @Test fun defaultIdsMatchUnifiedTable() {
        assertEquals(unifiedCore, defaultComposerActionIds)
        assertEquals(unifiedCore, defaultComposerActions(FlareStrings()).map { it.id })
    }

    @Test fun labelsComeFromStringsProvider() {
        val en = FlareStrings(actionImage = "Photo", actionCamera = "Camera", actionFile = "File",
            actionLocation = "Location", actionCard = "Card", actionVote = "Vote", actionTask = "Task", actionSchedule = "Schedule")
        val labels = defaultComposerActions(en).map { it.label }
        assertEquals(listOf("Photo", "Camera", "File", "Location", "Card", "Vote", "Task", "Schedule"), labels)
        assertEquals(FlareStrings().actionImage, defaultComposerActions(FlareStrings()).first().label)
    }

    @Suppress("DEPRECATION")
    @Test fun deprecatedValStillResolvesToDefaultStrings() {
        assertEquals(defaultComposerActions(FlareStrings()), defaultComposerActions)
        assertTrue(defaultComposerActions.all { it.label.isNotEmpty() })
    }
}
