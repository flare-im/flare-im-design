package com.flare.im.ui

/*
 * A rich-text message as it is drawn: the RichDoc v2 document the core stores (`docJson`, flare-proto
 * `RichTextContent.doc_json`) read into blocks and runs. The rule is shared with the other three kits and
 * written down in `spec/rich-doc-vectors.json`; Vue implements it in `utils/richDoc.ts`.
 */

/** The marks a run can carry, in the order a run lists them. */
enum class FlareRichMark(val wire: String) {
    Bold("bold"), Italic("italic"), Underline("underline"), Strike("strike"), Spoiler("spoiler"),
}

/**
 * One run of a paragraph or heading. [marks] are the known marks once each, in [FlareRichMark] order; [link] is
 * the href of the innermost link around the run that [safeExternalUrl] accepts, as written; [mention] is the
 * user id a mention names and [emoji] an emoji's pack key (either possibly empty).
 */
data class FlareRichRun(
    val text: String,
    val marks: List<FlareRichMark> = emptyList(),
    val code: Boolean = false,
    val link: String? = null,
    val mention: String? = null,
    val emoji: String? = null,
) {
    fun has(mark: FlareRichMark) = mark in marks
}

/** A block of a rich-text body. */
sealed interface FlareRichBlock {
    data class Paragraph(val runs: List<FlareRichRun>) : FlareRichBlock
    /** [level] is 1…6. */
    data class Heading(val level: Int, val runs: List<FlareRichRun>) : FlareRichBlock
    data class Quote(val blocks: List<FlareRichBlock>) : FlareRichBlock
    data class Code(val text: String, val language: String? = null) : FlareRichBlock
    /** Each item's blocks; never empty. */
    data class ListBlock(val ordered: Boolean, val items: List<List<FlareRichBlock>>) : FlareRichBlock
    data object Divider : FlareRichBlock
}

/**
 * What a covered spoiler run draws in place of [text]: every code point that is not whitespace becomes U+3000
 * IDEOGRAPHIC SPACE, so the words are in neither the rendered text nor a copy until the reader reveals them.
 */
fun flareRichSpoilerCover(text: String): String = buildString {
    text.codePoints().forEach { codePoint -> if (Character.isWhitespace(codePoint)) appendCodePoint(codePoint) else append('\u3000') }
}

/** The core's own limits (`rich_doc_v2/validate.rs`). */
const val FLARE_RICH_DOC_MAX_DEPTH = 64
const val FLARE_RICH_DOC_MAX_NODES = 10_000

/**
 * The blocks a rich-text body draws for [input] — the document's JSON text or its decoded map — or null when it
 * is not a drawable RichDoc v2 document, and the body shows the message's plain text instead.
 */
fun flareParseRichDoc(input: Any?): List<FlareRichBlock>? {
    val value = if (input is String) {
        try { FlareJson.parse(input) } catch (_: IllegalArgumentException) { return null } catch (_: NumberFormatException) { return null }
    } else {
        input
    }
    val root = value as? Map<*, *> ?: return null
    val version = root["version"]
    if (root["type"] != "doc" || version !is Number || version.toDouble() != 2.0 || root["children"] !is List<*>) return null
    val children = root["children"] as List<*>
    if (!withinLimits(children)) return null
    return blocks(children)
}

private fun childrenOf(node: Any?): List<*> = ((node as? Map<*, *>)?.get("children") as? List<*>).orEmpty()

private fun stringOf(value: Any?): String = value as? String ?: ""

private fun withinLimits(top: List<*>): Boolean {
    var nodes = 1
    val stack = ArrayDeque<Pair<Any?, Int>>()
    top.forEach { stack.addLast(it to 1) }
    while (stack.isNotEmpty()) {
        val (node, depth) = stack.removeLast()
        if (depth > FLARE_RICH_DOC_MAX_DEPTH) return false
        nodes += 1
        if (nodes > FLARE_RICH_DOC_MAX_NODES) return false
        childrenOf(node).forEach { stack.addLast(it to depth + 1) }
    }
    return true
}

private fun runs(inlines: List<*>, link: String?, out: MutableList<FlareRichRun> = mutableListOf()): MutableList<FlareRichRun> {
    fun push(run: FlareRichRun) { out += if (link == null) run else run.copy(link = link) }
    for (value in inlines) {
        val node = value as? Map<*, *> ?: continue
        when (node["type"]) {
            "text" -> {
                val text = stringOf(node["text"])
                if (text.isEmpty()) continue
                val named = (node["marks"] as? List<*>).orEmpty().mapNotNull { (it as? Map<*, *>)?.get("type") }.toSet()
                push(FlareRichRun(text, marks = FlareRichMark.entries.filter { it.wire in named }))
            }
            "inline_code" -> stringOf(node["text"]).takeIf { it.isNotEmpty() }?.let { push(FlareRichRun(it, code = true)) }
            "hard_break" -> push(FlareRichRun("\n"))
            "mention" -> {
                val userId = stringOf(node["user_id"])
                val text = stringOf(node["text"])
                if (userId.isNotEmpty() || text.isNotEmpty()) push(FlareRichRun(text.ifEmpty { "@$userId" }, mention = userId))
            }
            "emoji" -> {
                val key = stringOf(node["key"])
                val text = stringOf(node["text"])
                if (key.isNotEmpty() || text.isNotEmpty()) push(FlareRichRun(text.ifEmpty { ":$key:" }, emoji = key))
            }
            "link" -> {
                val href = stringOf(node["href"])
                val accepted = href.isNotEmpty() && safeExternalUrl(href) != null
                runs(childrenOf(node), if (accepted) href else link, out)
            }
            "custom_inline" -> Unit
            else -> stringOf(node["text"]).takeIf { it.isNotEmpty() }?.let { push(FlareRichRun(it)) }
        }
    }
    return out
}

private fun blocks(values: List<*>, out: MutableList<FlareRichBlock> = mutableListOf()): MutableList<FlareRichBlock> {
    for (value in values) {
        val node = value as? Map<*, *> ?: continue
        when (val type = node["type"]) {
            "paragraph" -> runs(childrenOf(node), null).takeIf { it.isNotEmpty() }?.let { out += FlareRichBlock.Paragraph(it) }
            "heading" -> {
                val inline = runs(childrenOf(node), null)
                if (inline.isEmpty()) continue
                val raw = (node["level"] as? Number)?.toDouble()?.takeIf { it.isFinite() }?.toInt() ?: 1
                out += FlareRichBlock.Heading(raw.coerceIn(1, 6), inline)
            }
            "quote" -> blocks(childrenOf(node)).takeIf { it.isNotEmpty() }?.let { out += FlareRichBlock.Quote(it) }
            "code_block" -> {
                val text = childrenOf(node).joinToString("") { child ->
                    val inline = child as? Map<*, *>
                    when (inline?.get("type")) {
                        "text" -> stringOf(inline["text"])
                        "hard_break" -> "\n"
                        else -> ""
                    }
                }
                if (text.isEmpty()) continue
                out += FlareRichBlock.Code(text, stringOf(node["language"]).ifEmpty { null })
            }
            "bullet_list", "ordered_list" -> {
                val items = childrenOf(node)
                    .filter { (it as? Map<*, *>)?.get("type") == "list_item" }
                    .map { blocks(childrenOf(it)) }
                    .filter { it.isNotEmpty() }
                if (items.isNotEmpty()) out += FlareRichBlock.ListBlock(ordered = type == "ordered_list", items = items)
            }
            "divider" -> out += FlareRichBlock.Divider
            "custom_block" -> blocks(childrenOf(node), out)
            else -> Unit
        }
    }
    return out
}
