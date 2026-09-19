package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class MessageActionSheetTest {
    private val reply = FlareMessageMenuEntry("reply", "回复", "reply", FlareMessageMenuGroup.Primary)
    private val pin = FlareMessageMenuEntry("pin", "置顶", "pin")
    private val delete = FlareMessageMenuEntry("delete", "删除", "delete", FlareMessageMenuGroup.Destructive, enabled = false)

    @Test fun groupsRenderInContractOrderAndDropEmptyGroups() {
        val groups = messageMenuGroups(listOf(delete, pin, reply))
        assertEquals(listOf(listOf("reply"), listOf("pin"), listOf("delete")), groups.map { g -> g.map { it.id } })
        assertEquals(listOf(listOf("pin")), messageMenuGroups(listOf(pin)).map { g -> g.map { it.id } })
        assertTrue(messageMenuGroups(emptyList()).isEmpty())
    }

    @Test fun entryDefaultsToOrganizeAndEnabled() {
        assertEquals(FlareMessageMenuGroup.Organize, pin.group)
        assertTrue(pin.enabled)
        assertEquals("暂无可用操作", FlareStrings().messageActionSheetEmpty)
        assertEquals("消息操作", FlareStrings().messageActionSheetLabel)
    }

    private val everything = FlareMessageActionAvailability(
        canReply = true, canForward = true, canCopy = true, canEdit = true, canDelete = true, canRecall = true,
        canPin = true, canUnpin = true, canReact = true, canMultiSelect = true, canSave = true, canResend = true,
    )

    private val text = FlareTextContent("明天十点开会")

    private fun ids(availability: FlareMessageActionAvailability, hidden: Set<String> = emptySet(), content: FlareMessageContent? = text) =
        messageMenuActions(availability, FlareStrings(), hidden, content).map { it.id }

    @Test fun standardActionsFollowTheCoreFlagsInContractOrder() {
        assertEquals(
            listOf("reply", "forward", "recall", "resend", "multiSelect", "mark", "pin", "pinSelf", "unpin", "copy", "preview", "save", "edit", "delete"),
            ids(everything),
        )
        assertTrue(ids(FlareMessageActionAvailability()).isEmpty())
    }

    @Test fun eachStandardActionHangsOnItsCoreFlag() {
        assertEquals(listOf("mark", "delete"), ids(FlareMessageActionAvailability(canDelete = true)))
        assertEquals(listOf("pin", "pinSelf"), ids(FlareMessageActionAvailability(canPin = true)))
        assertEquals(listOf("multiSelect", "preview"), ids(FlareMessageActionAvailability(canMultiSelect = true)))
        assertEquals(listOf("unpin"), ids(FlareMessageActionAvailability(canUnpin = true)))
        assertEquals(listOf("resend"), ids(FlareMessageActionAvailability(canResend = true)))
        assertTrue(ids(FlareMessageActionAvailability(canReact = true)).isEmpty())
    }

    @Test fun groupsAndLabelsBelongToTheKit() {
        val entries = messageMenuActions(everything, FlareStrings(), content = text)
        assertEquals(listOf("reply", "forward", "recall", "resend"), entries.filter { it.group == FlareMessageMenuGroup.Primary }.map { it.id })
        assertEquals(listOf("delete"), entries.filter { it.group == FlareMessageMenuGroup.Destructive }.map { it.id })
        assertEquals("撤回", entries.single { it.id == "recall" }.label)
        val english = FlareStrings { messageActionRecall = "Recall" }
        assertEquals("Recall", messageMenuActions(everything, english, content = text).single { it.id == "recall" }.label)
    }

    @Test fun copyNeedsTextToCopyEvenWhenTheCoreAllowsIt() {
        // The core's canCopy counts a media preview token as text; an image, voice or file message has nothing to copy.
        val copyOnly = FlareMessageActionAvailability(canCopy = true)
        assertEquals(listOf("copy"), ids(copyOnly))
        for (media in listOf<FlareMessageContent>(
            FlareImageContent("https://example.invalid/a.jpg"), FlareAudioContent("https://example.invalid/a.m4a", 3),
            FlareFileContent("spec.pdf", "https://example.invalid/spec.pdf"), FlareVideoContent("https://example.invalid/v.mp4"),
        )) assertTrue(ids(copyOnly, content = media).isEmpty(), "${media.type} offers no Copy")
        assertTrue(ids(copyOnly, content = FlareTextContent("   ")).isEmpty(), "blank text offers no Copy")
        assertTrue(ids(copyOnly, content = null).isEmpty(), "an unknown message offers no Copy")
        assertEquals("明天十点开会", flareMessageCopyText(text))
        assertEquals(null, flareMessageCopyText(FlareImageContent("https://example.invalid/a.jpg")))
    }

    @Test fun hiddenActionsAreLeftOut() {
        val shown = ids(everything, hidden = setOf("multiSelect", "preview"))
        assertTrue("multiSelect" !in shown && "preview" !in shown)
        assertEquals(12, shown.size)
    }

    @Test fun availabilityReadsTheCoreJson() {
        val parsed = FlareMessageActionAvailability.fromJson(
            mapOf("canReply" to true, "canPin" to false, "canCopy" to "true", "canDelete" to 1, "unknown" to true),
        )
        assertEquals(FlareMessageActionAvailability(canReply = true), parsed)
        assertEquals(FlareMessageActionAvailability(), FlareMessageActionAvailability.fromJson(emptyMap()))
    }

    @Test fun standardActionsNameTheRegistryIconForTheirConcept() {
        val icons = messageMenuActions(everything, FlareStrings(), content = text).associate { it.id to it.icon }
        val registry = mapOf(
            "reply" to "reply", "forward" to "forward", "recall" to "recall", "resend" to "refresh",
            "multiSelect" to "multi-select", "mark" to "mark", "pin" to "pin", "unpin" to "unpin",
            "copy" to "copy", "preview" to "eye", "save" to "download", "edit" to "edit", "delete" to "delete",
        )
        for ((id, name) in registry) assertEquals(name, icons[id], "$id draws `$name`")
        // Every name is one the registry really has, so no standard action draws the fallback glyph.
        for (name in icons.values) assertTrue(name in flareIconNames, "`$name` is a registry name")
        // Recall is not reply, and unpin is not pin.
        assertTrue(icons["recall"] != icons["reply"])
        assertTrue(icons["unpin"] != icons["pin"])
    }
}
