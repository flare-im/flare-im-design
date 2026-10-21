package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ComposerActionsTest {
    private val defaultActions = listOf("image", "video", "file", "voice", "card", "poll")

    @Test fun defaultIdsMatchUnifiedTable() {
        assertEquals(defaultActions, defaultComposerActionIds)
        assertEquals(defaultActions, defaultComposerActions(FlareStrings()).map { it.id })
    }

    @Test fun builtInItemsComeInOneOrderWithOneSetOfIcons() {
        val defaults = defaultComposerActions(FlareStrings())
        assertEquals(listOf("image", "video", "file", "mic", "card", "poll"), defaults.map { it.icon })
        assertTrue(defaults.all { it.kind == FlareComposerActionKind.Feature })
        assertFalse(defaults.any { it.id == "location" }, "no location source yet")
        for (icon in defaults.map { it.icon }) assertNotNull(flareIconVectorOrNull(icon), "$icon is a registry name")
        assertEquals(defaultActions, resolveComposerActions(defaults).map { it.id })
    }

    @Test fun labelsComeFromStringsProvider() {
        val en = FlareStrings {
            actionImage = "Photo"
            actionVideo = "Video"
            actionFile = "File"
            actionCard = "Card"
            actionVote = "Poll"
            composerVoice = "Voice"
        }
        val labels = defaultComposerActions(en).map { it.label }
        assertEquals(listOf("Photo", "Video", "File", "Voice", "Card", "Poll"), labels)
        assertEquals(FlareStrings().actionImage, defaultComposerActions(FlareStrings()).first().label)
    }

    @Test fun theKitSuppliesTheBuiltInLabelsInBothLanguages() {
        fun labels(strings: FlareStrings) =
            defaultActions.map { FlareComposerAction(it, icon = "image", kind = FlareComposerActionKind.Feature).resolvedLabel(strings) }
        assertEquals(listOf("图片", "视频", "文件", "语音", "名片", "投票"), labels(FlareStrings()))
        assertEquals(listOf("Photo", "Video", "File", "Voice", "Contact card", "Poll"), labels(flareStringsEnglish()))
        assertEquals("Album", FlareComposerAction("image", "Album", "image").resolvedLabel(FlareStrings()), "the host's label wins")
        assertEquals("order", FlareComposerAction("order", icon = "file").resolvedLabel(FlareStrings()), "an id the kit has no copy for shows itself")
    }

    @Test fun aTileWithAnUnknownIconDrawsThePluginGlyph() {
        fun plugin(icon: String) = FlareComposerAction("plugin:acme.order", "Order", icon, kind = FlareComposerActionKind.Plugin)
        assertEquals("red-packet", plugin("red-packet").resolvedIcon, "a known name is kept")
        assertEquals("plugin", plugin("shopping-cart").resolvedIcon)
        assertEquals("plugin", plugin("").resolvedIcon, "an old manifest declares no icon")
        assertEquals(
            "plugin", FlareComposerAction("card", icon = "contact", kind = FlareComposerActionKind.Feature).resolvedIcon,
            "a built-in item with a name the registry lacks falls back too, never to the question mark",
        )
        assertEquals("plugin", FlareComposerAction("x", "X", "shopping-cart").resolvedIcon)
        for (action in defaultComposerActions(FlareStrings())) assertEquals(action.icon, action.resolvedIcon, "${action.id} keeps its registry name")
        assertNotNull(flareIconVectorOrNull("plugin"), "plugin is a registry name")
    }

    /**
     * The voice tile is the composer's own: it opens the recorder the voice key opens (as on Flutter), and the host gets
     * the recording through `onVoiceSend`. Without a recorder, and for every other tile, the host decides.
     */
    @Test fun theVoiceTileOpensTheComposersRecorder() {
        val voice = FlareComposerAction("voice", icon = "mic", kind = FlareComposerActionKind.Feature)
        assertTrue(composerPanelTileOpensRecorder(voice, offersVoice = true))
        assertFalse(composerPanelTileOpensRecorder(voice, offersVoice = false), "no recorder: the host handles it")
        for (id in listOf("image", "video", "file", "card", "poll", "plugin:flare.redpacket.send")) {
            assertFalse(composerPanelTileOpensRecorder(FlareComposerAction(id, icon = "image"), offersVoice = true), id)
        }
    }

    @Test fun capabilitiesOfferEveryToolUntilTheHostNamesTheirOwn() {
        val tools = listOf("emoji", "mention", "voice", "image", "richText", "attachments")
        val all = FlareComposerCapabilities()
        assertNull(all.availableToolIds)
        assertTrue(tools.all(all::allowsTool))
        assertEquals(listOf("emoji", "attachments"), tools.filter(FlareComposerCapabilities(availableToolIds = setOf("emoji", "attachments"))::allowsTool))
        assertFalse(FlareComposerCapabilities(availableToolIds = emptySet()).allowsTool("emoji"))
    }

    @Test fun resolvesHostConfigurationAndCapabilities() {
        val defaults = defaultComposerActions(FlareStrings())
        val actions = listOf(
            defaults[2].copy(order = 30),
            defaults[3].copy(visible = false),
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
