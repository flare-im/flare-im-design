package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class AuthShellLayoutTest {
    @Test fun theBrandStoryNeverCompetesWithAPhoneForm() {
        assertFalse(authShellUsesSplitLayout(320f))
        assertFalse(authShellUsesSplitLayout(899f))
        assertTrue(authShellUsesSplitLayout(900f))
    }

    @Test fun largeTextKeepsTheFormInOneColumnUntilThereIsRoom() {
        assertFalse(authShellUsesSplitLayout(1024f, 1.4f))
        assertTrue(authShellUsesSplitLayout(1440f, 1.4f))
        assertFalse(authShellUsesSplitLayout(1024f, 2f))
    }
}
