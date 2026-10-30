package com.flare.im.ui

import java.util.Locale
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The message surface, meta placement and receipt rules (docs/design/message-surface-and-meta.md C1–C3) against the
 * tables the four kits run: spec/message-surface-vectors.json, spec/message-meta-placement-vectors.json and
 * spec/message-receipt-vectors.json.
 */
class MessageSurfaceVectorsTest {
    private val zh = FlareStrings()

    private fun surface(name: String?): FlareMessageSurface =
        FlareMessageSurface.fromWire(name) ?: error("unknown surface $name")

    private fun status(name: String?): FlareMessageDeliveryStatus =
        FlareMessageDeliveryStatus.entries.first { it.name.equals(name, ignoreCase = true) }

    // ── C1 surface ──

    @Test fun everySurfaceCaseFollowsTheTable() {
        val table = SpecTables.table("message-surface-vectors.json")
        assertEquals(FlareMessageSurface.entries.map { it.wire }, table["surfaces"])
        val cases = table.items("cases")
        assertTrue(cases.size >= 40, "the shared table lost cases: ${cases.size}")
        for (case in cases) {
            val id = case.str("id")!!
            val input = case.obj("input")!!
            val got = flareMessageSurface(
                FlareMessageSurfaceInput(
                    contentType = input.str("contentType")!!,
                    subtype = input.str("subtype"),
                    registered = input.str("registered")?.let(::surface),
                    loneEmoji = input.bool("loneEmoji") ?: false,
                    hasQuote = input.bool("hasQuote") ?: false,
                    hasCaption = input.bool("hasCaption") ?: false,
                    recalled = input.bool("recalled") ?: false,
                    deleted = input.bool("deleted") ?: false,
                ),
            )
            assertEquals(surface(case.str("surface")), got, id)
        }
    }

    @Test fun theDefaultsTableIsTheKitsOwn() {
        val defaults = SpecTables.table("message-surface-vectors.json").obj("defaults")!!
        for ((wire, types) in defaults) {
            for (type in types as List<*>) {
                assertEquals(surface(wire as String), flareMessageSurface(FlareMessageSurfaceInput(contentType = type as String)), "$type")
            }
        }
    }

    @Test fun kitContentsMapOntoTheSpecVocabulary() {
        val expected = mapOf(
            FlareTextContent("hi") to "text",
            FlareRichTextContent("{}") to "richText",
            FlareImageContent("https://example.com/a.png") to "image",
            FlareImageGroupContent(emptyList()) to "imageGroup",
            FlareVideoContent("v") to "video",
            FlareAudioContent("a") to "audio",
            FlareFileContent("f.pdf", "u") to "file",
            FlareLocationContent("Here") to "location",
            FlareStickerContent() to "sticker",
            FlareEmojiContent("🎉") to "emoji",
            FlareCardContent("Ann") to "card",
            FlareNotificationContent("joined") to "notification",
            FlarePlaceholderContent("…") to "placeholder",
            FlarePollContent("p", "Lunch?") to "vote",
            FlareTaskContent("t", "Do") to "task",
            FlareCalendarContent("c", "Meet") to "schedule",
            FlareMiniAppContent("m", "App") to "miniProgram",
            FlareAnnouncementContent("a", "News") to "announcement",
            FlareLinkCardContent("u", "Link") to "linkCard",
            FlareGenericContent("rich_text", "") to "richText",
            FlareGenericContent("image_group", "") to "imageGroup",
            FlareGenericContent("link_card", "") to "linkCard",
            FlareGenericContent("mini_program", "") to "miniProgram",
            FlareGenericContent("merged_forward", "") to "forward",
            FlareGenericContent("forward", "") to "forward",
            FlareGenericContent("thread", "") to "thread",
            FlareGenericContent("quote", "") to "quote",
            FlareGenericContent("custom", "") to "custom",
        )
        for ((content, type) in expected) assertEquals(type, flareMessageContentType(content).first, content.toString())
        assertEquals("custom" to "flare.redpacket.card", flareMessageContentType(FlareGenericContent("custom.flare.redpacket.card", "")))
        assertEquals("custom" to "acme.gif", flareMessageContentType(FlareGenericContent("custom:acme.gif", "")))
        assertEquals("custom" to "flare.plugin.message.v1",
            flareMessageContentType(FlareGenericContent("custom", "", subtype = "flare.plugin.message.v1")))
    }

    private fun message(content: FlareMessageContent, replyTo: FlareReplyTarget? = null, lifecycle: FlareMessageLifecycle? = null) =
        FlareMessageData(id = "m", senderId = "u", senderName = "Ann", content = content, replyTo = replyTo, lifecycle = lifecycle)

    /** The double layer of P0-1: every plugin card is a card, so the row draws no bubble around PluginView's shell. */
    @Test fun pluginAndRedPacketCardsAreCardsWithoutRegistering() {
        val plugin = message(FlareGenericContent("custom", "Poll", subtype = "flare.plugin.message.v1"))
        val packet = message(FlareGenericContent("custom.flare.redpacket.card", "Red packet"))
        val bare = message(FlareGenericContent("custom", "Card"))
        for (m in listOf(plugin, packet, bare)) {
            assertEquals(FlareMessageSurface.Card, flareMessageSurface(m), m.content.type)
            val chrome = messageSurfaceChrome(flareMessageSurface(m), tail = true)
            assertFalse(chrome.background || chrome.padding || chrome.tail || chrome.shadow, "a card draws no bubble chrome")
        }
        val quoted = plugin.copy(replyTo = FlareReplyTarget(messageId = "m0", senderName = "Bo", summary = "hi"))
        assertEquals(FlareMessageSurface.Card, flareMessageSurface(quoted), "a quote goes inside the card's shell")
        assertEquals(FlareMessageSurface.Card, flareMessageSurface(message(FlareLocationContent("Here"))))
        assertEquals(FlareMessageSurface.Card, flareMessageSurface(message(FlareCardContent("Ann"))))
        val bubble = messageSurfaceChrome(FlareMessageSurface.Bubble, tail = true)
        assertTrue(bubble.background && bubble.padding && bubble.tail && bubble.shadow)
    }

    @Test fun registrationsAreLookedUpByKeySubtypeAndType() {
        val gif = message(FlareGenericContent("custom", "", subtype = "acme.gif"))
        assertEquals(FlareMessageSurface.BareMedia, flareMessageSurface(gif, mapOf("custom:acme.gif" to FlareMessageSurface.BareMedia)))
        assertEquals(FlareMessageSurface.Card, flareMessageSurface(gif, mapOf("custom:other" to FlareMessageSurface.BareMedia)))
        val weather = message(FlareGenericContent("acme.weather", "Sunny"))
        assertEquals(FlareMessageSurface.Bubble, flareMessageSurface(weather), "a type the kit does not know is a bubble")
        assertEquals(FlareMessageSurface.Card, flareMessageSurface(weather, mapOf("acme.weather" to FlareMessageSurface.Card)))
        val quoted = gif.copy(replyTo = FlareReplyTarget(messageId = "m0", senderName = "Bo", summary = "hi"))
        assertEquals(FlareMessageSurface.Bubble, flareMessageSurface(quoted, mapOf("custom:acme.gif" to FlareMessageSurface.BareMedia)))
    }

    @Test fun recallsDeletionsAndNoticesAreCentred() {
        assertEquals(FlareMessageSurface.Centered, flareMessageSurface(message(FlareTextContent("x"), lifecycle = FlareMessageLifecycle(mutation = FlareMessageMutationState.Deleted))))
        assertEquals(FlareMessageSurface.Centered, flareMessageSurface(message(FlareTextContent("x"), lifecycle = FlareMessageLifecycle(mutation = FlareMessageMutationState.Recalled))))
        assertEquals(FlareMessageSurface.Centered, flareMessageSurface(message(FlareNotificationContent("joined"))))
        val deleted = message(FlareImageContent("u"), lifecycle = FlareMessageLifecycle(mutation = FlareMessageMutationState.Deleted))
        assertTrue(deleted.isDeleted)
        assertEquals("消息已删除", messageNoticeText(deleted, self = false, FlareConversationKind.Group, zh))
    }

    @Test fun aLoneEmojiIsBareMedia() {
        val known = { key: String -> key == "smile" }
        assertTrue(flareIsLoneEmojiText("[smile]", emptyList(), known))
        assertFalse(flareIsLoneEmojiText("[nope]", emptyList(), known), "an unknown pack key stays text")
        assertTrue(flareIsLoneEmojiText(" 😀 ", emptyList(), known))
        assertTrue(flareIsLoneEmojiText("👨‍👩‍👧", emptyList(), known), "a ZWJ family is one emoji")
        assertTrue(flareIsLoneEmojiText("🇨🇳", emptyList(), known), "a flag is one emoji")
        assertTrue(flareIsLoneEmojiText("👍🏽", emptyList(), known), "a skin tone joins its emoji")
        assertTrue(flareIsLoneEmojiText("1️⃣", emptyList(), known), "a keycap")
        assertFalse(flareIsLoneEmojiText("😀😀", emptyList(), known))
        assertFalse(flareIsLoneEmojiText("hi 😀", emptyList(), known))
        assertFalse(flareIsLoneEmojiText("1", emptyList(), known))
        assertFalse(flareIsLoneEmojiText("😀", listOf(FlareTextMentionSpan(0, 2)), known), "mentions make it text")
        assertEquals(FlareMessageSurface.BareMedia, flareMessageSurface(message(FlareTextContent("😀"))))
        assertEquals(FlareMessageSurface.Bubble, flareMessageSurface(message(FlareTextContent("😀"), replyTo = FlareReplyTarget(messageId = "m0", senderName = "Bo", summary = "hi"))))
    }

    // ── C2 meta placement ──

    @Test fun metaPlacementToneAndRetryFollowTheTable() {
        val table = SpecTables.table("message-meta-placement-vectors.json")
        assertEquals(FlareMessageMetaPlacement.entries.map { it.wire }, table["placements"])
        val cases = table.items("cases")
        assertTrue(cases.size >= 17)
        for (case in cases) {
            val id = case.str("id")!!
            val placement = flareMessageMetaPlacement(surface(case.str("surface")), case.str("contentType")!!)
            val expect = case.obj("expect")!!
            assertEquals(expect.str("placement"), placement.wire, "$id placement")
            val self = case.bool("self")!!
            val st = status(case.str("status"))
            val tone = when (flareMessageMetaTone(placement, self, st)) {
                FlareMessageMetaTone.Default -> "default"
                FlareMessageMetaTone.OnOutgoing -> "onOutgoing"
            }
            assertEquals(expect.str("tone"), tone, "$id tone")
            val retry = when (flareMessageRetryControl(placement, self, st)) {
                FlareMessageRetryControl.Glyph -> "glyph"
                FlareMessageRetryControl.Text -> "text"
                null -> null
            }
            assertEquals(expect.str("retry"), retry, "$id retry")
        }
        assertEquals("发送失败，重试", zh.messageSendFailedRetry)
        assertEquals(SpecTables.copy("messageSendFailedRetry", "zh"), zh.messageSendFailedRetry)
    }

    // ── bubble palette ──

    /** A token path of the shared table in [colors]. */
    private fun token(path: String?, colors: FlareColors): androidx.compose.ui.graphics.Color? = when (path) {
        null -> null
        "message.incoming.background" -> colors.messageIncomingBackground
        "message.incoming.foreground" -> colors.messageIncomingForeground
        "message.outgoing.background" -> colors.messageOutgoingBackground
        "message.outgoing.foreground" -> colors.messageOutgoingForeground
        "message.failed.background" -> colors.messageFailedBackground
        "message.failed.foreground" -> colors.messageFailedForeground
        "message.failed.border" -> colors.messageFailedBorder
        else -> error("unknown token $path")
    }

    @Test fun theBubblePaletteFollowsTheTable() {
        val palette = SpecTables.table("message-surface-vectors.json").obj("palette")!!
        val tones = palette.obj("tones")!!
        assertEquals(FlareMessageBubbleTone.entries.map { it.wire }.toSet(), tones.keys)
        val cases = palette.items("cases")
        assertTrue(cases.size >= 8, "the shared table lost cases: ${cases.size}")
        for (case in cases) {
            val id = case.str("id")!!
            val tone = flareMessageBubbleTone(case.bool("self")!!, status(case.str("status")))
            assertEquals(case.str("tone"), tone.wire, id)
        }
        for (colors in listOf(FlareColors.Light, FlareColors.Dark, FlareColors.resolve(FlareBrandTheme.Ocean, false))) {
            for (tone in FlareMessageBubbleTone.entries) {
                val expected = tones.obj(tone.wire)!!
                val got = flareMessageBubblePalette(tone, colors)
                assertEquals(token(expected.str("background"), colors), got.background, "${tone.wire} background")
                assertEquals(token(expected.str("foreground"), colors), got.foreground, "${tone.wire} foreground")
                assertEquals(token(expected.str("edge"), colors), got.edge, "${tone.wire} edge")
            }
        }
    }

    // ── C3 receipt ──

    private fun readSummary(raw: Map<*, *>?): FlareMessageReadSummary? =
        raw?.let { FlareMessageReadSummary(it.int("readCount")!!, it.int("unreadCount")!!, it.int("total")!!) }

    private fun kind(name: String?): FlareConversationKind =
        if (name == "group") FlareConversationKind.Group else FlareConversationKind.Single

    /** The kit's strings with the shared English source's words for the receipt and status fields. */
    private val english = FlareStrings {
        messagePending = SpecTables.copy("messagePending", "en")
        messageSending = SpecTables.copy("messageSending", "en")
        messageSent = SpecTables.copy("messageSent", "en")
        messageRead = SpecTables.copy("messageRead", "en")
        messageFailed = SpecTables.copy("messageFailed", "en")
        messageSendFailedRetry = SpecTables.copy("messageSendFailedRetry", "en")
        messageReadSummaryUnread = SpecTables.copy("messageReadSummaryUnread", "en")
        messageReadSummaryAllRead = SpecTables.copy("messageReadSummaryAllRead", "en")
    }

    @Test fun receiptGlyphsAndReadSummariesFollowTheTable() {
        val table = SpecTables.table("message-receipt-vectors.json")
        assertEquals(FlareMessageDeliveryStatus.entries.map { it.name.lowercase() }, table["statuses"], "five states, no delivered")
        val glyphs = table.obj("glyphs")!!
        for (st in FlareMessageDeliveryStatus.entries) assertEquals(glyphs.str(st.name.lowercase()), flareMessageReceiptGlyph(st).wire)
        val cases = table.items("cases")
        assertTrue(cases.size >= 14)
        for (case in cases) {
            val id = case.str("id")!!
            val receipt = flareMessageReceiptPresentation(kind(case.str("conversationKind")), case.bool("self")!!, status(case.str("status")),
                readSummary(case.obj("readSummary")))
            val expect = case.obj("expect")!!
            assertEquals(expect.str("glyph"), receipt.glyph?.wire, "$id glyph")
            val summary = expect.obj("summary")
            if (summary == null) {
                assertNull(receipt.summary, "$id summary")
            } else {
                val shown = receipt.summary!!
                assertEquals(summary.bool("allRead"), shown.allRead, "$id allRead")
                assertEquals(summary.str("zh"), shown.text(zh), "$id zh")
                assertEquals(summary.str("en"), shown.text(english), "$id en")
                assertEquals(SpecTables.copy(summary.str("key")!!, "zh").replace("{count}", summary.int("count")?.toString() ?: ""), shown.text(zh), "$id key")
            }
        }
    }

    @Test fun theRowReadsAsOneUnit() {
        val cases = SpecTables.table("message-receipt-vectors.json").items("accessibility")
        assertTrue(cases.size >= 5)
        for (case in cases) {
            val locale = Locale.forLanguageTag(case.str("locale")!!)
            val strings = if (locale.language == "zh") zh else english
            val label = flareMessageAccessibilityLabel(
                sender = case.str("sender")!!, preview = case.str("preview")!!, time = case.str("time")!!,
                self = case.bool("self")!!, status = status(case.str("status")), strings = strings, locale = locale,
                conversationKind = kind(case.str("conversationKind")), readSummary = readSummary(case.obj("readSummary")),
            )
            assertEquals(case.str("expect"), label, case.str("id"))
        }
    }

    @Test fun theNewCopyMatchesTheSharedSource() {
        for ((key, value) in listOf(
            "messageReadSummaryUnread" to zh.messageReadSummaryUnread,
            "messageReadSummaryAllRead" to zh.messageReadSummaryAllRead,
            "messageSendFailedRetry" to zh.messageSendFailedRetry,
        )) assertEquals(SpecTables.copy(key, "zh"), value, key)
    }

    @Test fun theBubbleCapsAgainstThePaneNotTheScreen() {
        // A two-pane tablet: the timeline pane is narrower than the rail breakpoint, so it takes the compact share.
        assertEquals(FlareSizes.componentBubbleMaxWidthRatioCompact * 500, flareBubbleMaxWidth(androidx.compose.ui.unit.Dp(500f)).value, 0.01f)
        assertEquals(FlareSizes.componentBubbleMaxWidthRatioRegular * 800, flareBubbleMaxWidth(androidx.compose.ui.unit.Dp(800f)).value, 0.01f)
        assertEquals(FlareSizes.bubbleMaxWidth, flareBubbleMaxWidth(androidx.compose.ui.unit.Dp(2000f)))
    }

    @Test fun fileSizesSpeakTheKitLocale() {
        assertEquals("512 B", flareFileSize(512, zh, Locale.CHINA))
        assertEquals("2.0 KB", flareFileSize(2048, zh, Locale.US))
        assertEquals("1,5 MB", flareFileSize(1_572_864, zh, Locale.GERMANY))
        assertEquals("1.0 GB", flareFileSize(1L shl 30, zh, Locale.UK))
        assertEquals("3 Bytes", flareFileSize(3, FlareStrings { fileSizeBytes = "{n} Bytes" }, Locale.US))
    }
}
