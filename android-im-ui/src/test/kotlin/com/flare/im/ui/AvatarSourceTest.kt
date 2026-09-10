package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals

class AvatarSourceTest {
    @Test fun imageSlotWinsOverUrl() {
        assertEquals(AvatarSource.Slot, avatarSource(hasImageSlot = true, avatarUrl = "https://x/a.png"))
    }

    @Test fun urlUsedWhenNoSlot() {
        assertEquals(AvatarSource.Url, avatarSource(hasImageSlot = false, avatarUrl = "https://x/a.png"))
    }

    @Test fun blankUrlFallsBackToInitials() {
        assertEquals(AvatarSource.Initials, avatarSource(hasImageSlot = false, avatarUrl = null))
        assertEquals(AvatarSource.Initials, avatarSource(hasImageSlot = false, avatarUrl = "  "))
    }
}
