package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals

/**
 * Drawer and Modal fall back to these pane titles when the host gives neither a title nor a
 * label, so an overlay window is never announced without a name.
 */
class OverlayStringsTest {
    @Test fun fallbackNamesDefaultToChineseAndDiffer() {
        val zh = FlareStrings()
        assertEquals("侧边面板", zh.drawerLabel)
        assertEquals("对话框", zh.modalLabel)
        assertNotEquals(zh.drawerLabel, zh.modalLabel)
        assertNotEquals(zh.bottomSheetLabel, zh.modalLabel)
    }

    @Test fun englishPresetAndOverridesReachTheFallbackNames() {
        val en = flareStringsEnglish()
        assertEquals("Side panel", en.drawerLabel)
        assertEquals("Dialog", en.modalLabel)
        val host = FlareStrings { drawerLabel = "Details" }
        assertEquals("Details", host.drawerLabel)
        assertEquals("对话框", host.modalLabel)
    }
}
