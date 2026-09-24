package com.flare.im.ui

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.sp
import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The shared table (`spec/rich-doc-vectors.json`): what a rich-text body draws for a RichDoc v2 document. Vue
 * states the rule in the table's own shape; this kit reads the same file and turns its model into that shape.
 */
class RichDocVectorsTest {
    private fun vectorsFile(): File {
        var dir: File? = File(".").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "spec/rich-doc-vectors.json")
            if (candidate.isFile) return candidate
            dir = dir.parentFile
        }
        error("spec/rich-doc-vectors.json not found above ${File(".").absolutePath}")
    }

    private fun outline(run: FlareRichRun): Map<String, Any?> = buildMap {
        put("text", run.text)
        if (run.marks.isNotEmpty()) put("marks", run.marks.map { it.wire })
        if (run.code) put("code", true)
        run.link?.let { put("link", it) }
        run.mention?.let { put("mention", it) }
        run.emoji?.let { put("emoji", it) }
    }

    private fun outline(block: FlareRichBlock): Map<String, Any?> = when (block) {
        is FlareRichBlock.Paragraph -> mapOf("kind" to "paragraph", "runs" to block.runs.map(::outline))
        // JSON numbers read back as doubles; the level is compared the same way.
        is FlareRichBlock.Heading -> mapOf("kind" to "heading", "level" to block.level.toDouble(), "runs" to block.runs.map(::outline))
        is FlareRichBlock.Quote -> mapOf("kind" to "quote", "blocks" to block.blocks.map(::outline))
        is FlareRichBlock.Code -> buildMap {
            put("kind", "code")
            block.language?.let { put("language", it) }
            put("text", block.text)
        }
        is FlareRichBlock.ListBlock -> mapOf("kind" to "list", "ordered" to block.ordered, "items" to block.items.map { it.map(::outline) })
        FlareRichBlock.Divider -> mapOf("kind" to "divider")
    }

    private fun generated(spec: Map<*, *>): Map<String, Any?> {
        val text = mapOf("type" to "text", "text" to "a")
        (spec["nestedQuotes"] as? Double)?.let { levels ->
            var node: Map<String, Any?> = mapOf("type" to "paragraph", "children" to listOf(text))
            repeat(levels.toInt()) { node = mapOf("type" to "quote", "children" to listOf(node)) }
            return mapOf("type" to "doc", "version" to 2.0, "children" to listOf(node))
        }
        val count = (spec["paragraphTextNodes"] as Double).toInt()
        return mapOf("type" to "doc", "version" to 2.0, "children" to listOf(mapOf("type" to "paragraph", "children" to List(count) { text })))
    }

    @Test fun aCoveredSpoilerIsBlankSpaceKeepingItsWhitespace() {
        val covers = (FlareJson.parse(vectorsFile().readText()) as Map<*, *>)["spoilerCovers"] as List<*>
        assertTrue(covers.size >= 5)
        for (raw in covers) {
            val cover = raw as Map<*, *>
            assertEquals(cover["cover"], flareRichSpoilerCover(cover["text"] as String), cover["text"] as String)
        }
    }

    @Test fun everyCaseDrawsWhatTheTableSays() {
        val cases = (FlareJson.parse(vectorsFile().readText()) as Map<*, *>)["cases"] as List<*>
        assertTrue(cases.size >= 30, "the shared table lost cases: ${cases.size}")
        for (raw in cases) {
            val case = raw as Map<*, *>
            val id = case["id"] as String
            val generate = case["generate"] as? Map<*, *>
            if (generate != null) {
                assertEquals(case["drawable"], flareParseRichDoc(generated(generate)) != null, id)
                continue
            }
            val blocks = flareParseRichDoc(case["doc"])
            assertEquals(case["blocks"], blocks?.map(::outline), id)
        }
    }
}

class RichTextMessageTest {
    private val paint = FlareRichPaint(
        foreground = Color.Black, link = Color.Blue, mention = Color.Magenta, self = false, revealed = false,
        spoilerLabel = "剧透内容，点按显示",
    )

    @Test fun aLinkIsClickableOnlyForAnAcceptedAddressAndAHandler() {
        val opened = mutableListOf<String>()
        val text = flareRichRunsText(
            listOf(FlareRichRun("文档", link = "https://flare.im/docs"), FlareRichRun("别点", link = "javascript:alert(1)")),
            paint, 15.sp, onLinkTap = { opened += it }, onReveal = {},
        )
        val links = text.getLinkAnnotations(0, text.length)
        assertEquals(1, links.size)
        val link = links.single().item as LinkAnnotation.Url
        assertEquals("https://flare.im/docs", link.url)
        link.linkInteractionListener!!.onClick(link)
        assertEquals(listOf("https://flare.im/docs"), opened)
        // Without a handler an accepted link still looks like one, but nothing is clickable.
        val inert = flareRichRunsText(listOf(FlareRichRun("文档", link = "https://flare.im/docs")), paint, 15.sp, null) {}
        assertTrue(inert.getLinkAnnotations(0, inert.length).isEmpty())
        assertEquals(Color.Blue, inert.spanStyles.single().item.color)
    }

    @Test fun aCoveredSpoilerRevealsOnClickAndIsReadAsItsName() {
        var revealed = false
        val runs = listOf(FlareRichRun("谜底是 "), FlareRichRun("42", marks = listOf(FlareRichMark.Spoiler)))
        val text = flareRichRunsText(runs, paint, 15.sp, null) { revealed = true }
        val clickable = text.getLinkAnnotations(0, text.length).single().item as LinkAnnotation.Clickable
        assertEquals(FLARE_RICH_SPOILER_TAG, clickable.tag)
        val ground = text.spanStyles.single { it.start == 4 }.item
        assertEquals(Color.Black, ground.background)
        assertEquals("谜底是 \u3000\u3000", text.text, "the words are not drawn while covered")
        clickable.linkInteractionListener!!.onClick(clickable)
        assertTrue(revealed)
        assertEquals("谜底是 剧透内容，点按显示", flareRichSpokenText(runs, paint))
        val open = flareRichRunsText(runs, paint.copy(revealed = true), 15.sp, null) {}
        assertTrue(open.getLinkAnnotations(0, open.length).isEmpty())
        assertEquals("谜底是 42", flareRichSpokenText(runs, paint.copy(revealed = true)))
    }

    @Test fun marksMentionsAndCodeTakeTheirLook() {
        val text = flareRichRunsText(
            listOf(
                FlareRichRun("结论", marks = listOf(FlareRichMark.Bold, FlareRichMark.Strike)),
                FlareRichRun("@Ada", mention = "u_ada"),
                FlareRichRun("npm test", code = true),
            ),
            paint, 15.sp, null,
        ) {}
        val styles = text.spanStyles.map { it.item }
        assertEquals(FontWeight.Bold, styles[0].fontWeight)
        assertEquals(TextDecoration.LineThrough, styles[0].textDecoration)
        assertEquals(Color.Magenta, styles[1].color)
        assertEquals(FontWeight.Medium, styles[1].fontWeight)
        assertEquals(Color.Black.copy(alpha = 0.10f), styles[2].background)
    }

    @Test fun emojiKeysAreCollectedFromEveryBlock() {
        val blocks = flareParseRichDoc(
            """{"type":"doc","version":2,"children":[{"type":"quote","children":[{"type":"paragraph","children":[{"type":"emoji","key":"smile"}]}]},{"type":"bullet_list","children":[{"type":"list_item","children":[{"type":"paragraph","children":[{"type":"emoji","key":"cry_loudly","text":"😭"}]}]}]}]}""",
        )!!
        assertEquals(setOf("smile", "cry_loudly"), flareRichEmojiKeys(blocks))
    }

    // The core's Markdown normaliser stores the composer's `[key]` as literal text, not as an emoji run; a rich
    // body reads the token as a plain text body does. Unknown keys and code stay the words they are.
    @Test fun emojiPackTokensInATextRunDrawInline() {
        val blocks = flareParseRichDoc(
            """{"type":"doc","version":2,"children":[{"type":"paragraph","children":[{"type":"text","text":"[angry_face] 高峰 [not_a_key]"},{"type":"inline_code","text":"[alien]"}]}]}""",
        )!!
        assertEquals(setOf("angry_face", "not_a_key"), flareRichEmojiKeys(blocks))
        val runs = (blocks.single() as FlareRichBlock.Paragraph).runs
        val text = flareRichRunsText(runs, paint.copy(drawableEmoji = setOf("angry_face")), 15.sp, null) {}
        val inline = text.getStringAnnotations("androidx.compose.foundation.text.inlineContent", 0, text.length)
        assertEquals(listOf(flareInlineEmojiId("angry_face")), inline.map { it.item })
        assertEquals(0 to "[angry_face]".length, inline.single().let { it.start to it.end })
        assertEquals("[angry_face] 高峰 [not_a_key][alien]", text.text)
        // Nothing is drawable until the catalog says so.
        val plain = flareRichRunsText(runs, paint, 15.sp, null) {}
        assertTrue(plain.getStringAnnotations("androidx.compose.foundation.text.inlineContent", 0, plain.length).isEmpty())
    }

    @Test fun copyAndSummaryUseThePlainText() {
        val content = FlareRichTextContent(docJson = "", plainText = "周会纪要", title = "项目周报")
        assertEquals("周会纪要", flareMessageCopyText(content))
        assertEquals("项目周报 周会纪要", flareMessagePreviewText(content, FlareStrings()))
        assertNull(flareMessageCopyText(FlareRichTextContent(docJson = "", plainText = "  ")))
    }
}

class FlareJsonTest {
    @Test fun readsTheShapesADocumentUses() {
        val value = FlareJson.parse("""{"a":[1,true,null,"\u4e2d\n"],"b":{}}""") as Map<*, *>
        assertEquals(listOf(1.0, true, null, "中\n"), value["a"])
        assertEquals(emptyMap<String, Any?>(), value["b"])
    }

    @Test fun refusesWhatIsNotOneValue() {
        for (bad in listOf("", "{", "[1,", "{\"a\":1} x", "\"\\u12\"", "tru", "-")) {
            assertFailsWith<RuntimeException>(bad) { FlareJson.parse(bad) }
        }
    }

    @Test fun refusesNestingDeeperThanTheLimitInsteadOfOverflowing() {
        val depth = FlareJson.MAX_NESTING + 1
        assertFailsWith<IllegalArgumentException> { FlareJson.parse("[".repeat(depth + 1) + "]".repeat(depth + 1)) }
        FlareJson.parse("[".repeat(FlareJson.MAX_NESTING) + "]".repeat(FlareJson.MAX_NESTING))
        // A hostile document is not drawable, never a crash.
        assertNull(flareParseRichDoc("[".repeat(100_000)))
    }
}
