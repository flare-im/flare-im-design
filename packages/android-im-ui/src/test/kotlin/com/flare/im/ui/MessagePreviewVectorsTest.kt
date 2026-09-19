package com.flare.im.ui

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The shared summary table (`spec/message-preview-vectors.json`) is what a conversation row, a reply
 * strip and a bubble's quote say about a message. Vue is the reference implementation; the three
 * native kits read the same file. A case's `fields` become this platform's content object: `text` on
 * the body itself, everything else the field that body carries, and `count` how many items the body
 * carries — a type this kit has no body for arrives as [FlareGenericContent] under its wire type.
 */
class MessagePreviewVectorsTest {
    /**
     * The emoji cases read the pack names the kit ships. There are no Android assets in a JVM test, so the
     * shipped file is parsed here and handed to the catalog through the same entry `ensureLoaded` uses —
     * the rule that reads the table runs, only the reading of the asset is replaced.
     */
    init {
        val raw = FlareJson.parse(localesFile().readText()) as Map<*, *>
        FlareEmojiStickerCatalog.loadLocales(
            raw.entries.associate { (column, labels) ->
                column as String to (labels as Map<*, *>).entries.associate { (k, v) -> k as String to v as String }
            },
        )
    }

    /** The shipped pack names, the same file the app loads from `assets`. */
    private fun localesFile(): File =
        File(vectorsFile().parentFile.parentFile, "packages/android-im-ui/src/main/assets/emoji-sticker/emoji-locales.json")

    @Test fun everyCaseReadsTheSameInBothLocales() {
        val vectors = FlareJson.parse(vectorsFile().readText()) as Map<*, *>
        val cases = vectors["cases"] as List<*>
        assertTrue(cases.size >= 20, "the shared table lost cases: ${cases.size}")
        for (raw in cases) {
            val case = raw as Map<*, *>
            val id = case["id"] as String
            val content = contentFor(case["kind"] as String, case["fields"] as Map<*, *>)
            val expected = case["expected"] as Map<*, *>
            val replyExpected = case["replyExpected"] as? Map<*, *>
            for ((locale, strings) in listOf("zh-CN" to zhStrings, "en-US" to enStrings)) {
                assertEquals(expected[locale], flareMessagePreviewText(content, strings, locale), "$id summary in $locale")
                assertEquals(
                    replyExpected?.get(locale) ?: expected[locale],
                    flareMessageReplySummary(content, strings, locale),
                    "$id reply summary in $locale",
                )
            }
        }
    }

    /** The fallback the table names is the kit's own word, so a reply strip is never a blank line. */
    @Test fun fallbackKeyIsTheKitsMessageWord() {
        val vectors = FlareJson.parse(vectorsFile().readText()) as Map<*, *>
        assertEquals("preview.message", vectors["fallbackKey"])
        assertEquals("[消息]", flareMessageReplySummary(FlareTextContent("  "), zhStrings))
        assertEquals("[Message]", flareMessageReplySummary(FlareTextContent("  "), enStrings))
    }

    private fun contentFor(kind: String, fields: Map<*, *>): FlareMessageContent {
        fun text(key: String) = (fields[key] as? String).orEmpty()
        val count = (fields["count"] as? Double)?.toInt() ?: 0
        return when (kind) {
            "text" -> FlareTextContent(text("text"))
            "image" -> FlareImageContent(url = "", alt = fields["description"] as? String, animated = fields["animated"] == true)
            "video" -> FlareVideoContent(url = "")
            "audio" -> FlareAudioContent(url = "")
            "file" -> FlareFileContent(name = text("fileName"), url = "")
            "location" -> FlareLocationContent(name = text("title"))
            "card" -> FlareCardContent(title = text("title"))
            "sticker" -> FlareStickerContent()
            "link_card" -> FlareLinkCardContent(url = "", title = text("title"))
            "vote" -> FlarePollContent(id = "", title = text("title"))
            "task" -> FlareTaskContent(id = "", title = text("title"))
            "announcement" -> FlareAnnouncementContent(id = "", title = text("title"))
            // One centred-line body stands for both `system` and `notification`.
            "system" -> FlareNotificationContent(text("text"))
            "quote" -> FlareGenericContent("quote", label = text("quotedTextPreview"))
            "emoji" -> FlareEmojiContent(text("key"))
            "rich_text" -> FlareRichTextContent(docJson = "", plainText = text("plainText"))
            "image_group" -> FlareImageGroupContent(List(count) { FlareImageContent("") })
            "mini_program" -> FlareMiniAppContent(appId = "", title = text("title"))
            else -> FlareGenericContent(kind, label = text("title"), itemCount = count)
        }
    }

    /** The table lives beside the four kits, so find the repository root from the module's directory. */
    private fun vectorsFile(): File {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "spec/message-preview-vectors.json")
            if (candidate.isFile) return candidate
            dir = dir.parentFile
        }
        error("spec/message-preview-vectors.json not found above ${File(".").absolutePath}")
    }

    private val zhStrings = FlareStrings()

    /** The English wording of the same table — the words a host provides to read the kit in English. */
    private val enStrings = FlareStrings {
        previewMessage = "[Message]"
        previewRichText = "[Rich text]"
        previewGif = "[GIF]"
        previewImage = "[Image]"
        previewVideo = "[Video]"
        previewAudio = "[Voice]"
        previewFile = "[File]"
        previewFileNamed = { "[File] $it" }
        previewLocation = "[Location]"
        previewLocationNamed = { "[Location] $it" }
        previewCard = "[Contact]"
        previewCardNamed = { "[Contact] $it" }
        previewSticker = "[Sticker]"
        previewEmoji = "[Emoji]"
        previewQuote = "[Quote]"
        previewLink = "[Link]"
        previewForward = "[Forward]"
        previewForwardCount = { "[Forward] $it messages" }
        previewThread = "[Thread]"
        previewMiniProgram = "[Mini Program]"
        previewImageGroup = "[Album]"
        previewImageGroupCount = { "[Album] $it" }
        previewSystem = "[System]"
        previewNotification = "[Notification]"
        previewVote = "[Poll]"
        previewTask = "[Task]"
        previewSchedule = "[Schedule]"
        previewAnnouncement = "[Announcement]"
        previewCustom = "[Custom]"
        previewPlaceholder = "[Placeholder]"
        previewUnknown = "[Unknown]"
    }
}
