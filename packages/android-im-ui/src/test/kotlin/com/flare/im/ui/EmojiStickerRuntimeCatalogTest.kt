package com.flare.im.ui

import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class EmojiStickerRuntimeCatalogTest {
    @AfterTest
    fun clearRuntimeCatalog() {
        FlareEmojiStickerCatalog.clearRegisteredEmojiAssets()
        FlareEmojiStickerCatalog.clearRegisteredStickerPacks()
    }

    @Test
    fun runtimeEmojiKeepsAnimationAndStaticPreviewSeparate() {
        val preview = byteArrayOf(1, 2, 3)
        FlareEmojiStickerCatalog.registerEmojiAssets(
            listOf(
                FlareEmojiAssetRegistration(
                    key = "user_wave",
                    animatedUri = "https://cdn.example/user-wave.webp",
                    staticPreviewBytes = preview,
                    labels = mapOf("en" to "User wave", "zh-Hans" to "用户挥手"),
                ),
            ),
        )

        assertTrue(FlareEmojiStickerCatalog.hasEmojiKey("user_wave"))
        assertEquals("https://cdn.example/user-wave.webp", FlareEmojiStickerCatalog.emojiAssetUri("user_wave"))
        assertContentEquals(preview, FlareEmojiStickerCatalog.emojiStaticPreviewBytes("user_wave"))
        assertEquals("用户挥手", FlareEmojiStickerCatalog.emojiLabel("user_wave", "zh-CN"))
        assertEquals("user_wave", flareLoneEmojiPackKey(" [user_wave] "))
        assertFalse(preview === FlareEmojiStickerCatalog.emojiStaticPreviewBytes("user_wave"))
    }

    @Test
    fun runtimeStickerPackIsMergedUsingProtocolIds() {
        FlareEmojiStickerCatalog.registerStickerPacks(
            listOf(
                FlareStickerPackRegistration(
                    id = "my_pack",
                    title = "My Pack",
                    stickers = listOf(
                        FlareStickerAssetRegistration(
                            stickerId = "party",
                            uri = "file:///tmp/party.webp",
                            staticPreviewBytes = byteArrayOf(9),
                        ),
                    ),
                ),
            ),
        )

        assertEquals(listOf("party"), FlareEmojiStickerCatalog.stickerPacks.single { it.id == "my_pack" }.stickerIds)
        assertEquals("file:///tmp/party.webp", FlareEmojiStickerCatalog.stickerAssetUri("party", "my_pack"))
        assertContentEquals(byteArrayOf(9), FlareEmojiStickerCatalog.stickerStaticPreviewBytes("party", "my_pack"))
    }
}
