package com.flare.im.ui

/**
 * A mention as the core sends it on a text content (`content.mentions`): [start] and [length] count
 * Unicode code points of the text. [type] is the flare-proto MentionType ([USER], [ALL], [ROLE] or
 * [MULTI]); [userIds] carries the people of a multi mention.
 */
data class FlareMentionEntity(
    val type: Int,
    val start: Int,
    val length: Int,
    val userId: String = "",
    val userIds: List<String> = emptyList(),
    val roleId: String = "",
) {
    companion object {
        const val USER = 1
        const val ALL = 2
        const val ROLE = 3
        const val MULTI = 4
    }
}

/**
 * A mention inside a text body, in UTF-16 indices of the rendered text ([String] indices). [self]
 * marks a mention of the current user and [all] a mention of everyone; both get the stronger look.
 */
data class FlareTextMentionSpan(
    val start: Int,
    val length: Int,
    val self: Boolean = false,
    val all: Boolean = false,
)

/**
 * The mention spans of [text] for [TextMessage], from the core's [mentions] (code point offsets,
 * converted with [String.offsetByCodePoints], so an emoji before a mention moves it by its code points,
 * not its UTF-16 units). A mention is kept only when it lies inside the text, is at least two code
 * points long and starts with "@": a span that lands anywhere else would highlight the wrong words, so
 * it is dropped instead. Spans come back sorted; one that overlaps the span kept before it is dropped.
 * [currentUserId] marks the mentions of the reader ([FlareTextMentionSpan.self]).
 */
fun textMentionSpans(text: String, mentions: List<FlareMentionEntity>, currentUserId: String? = null): List<FlareTextMentionSpan> {
    if (text.isEmpty() || mentions.isEmpty()) return emptyList()
    val codePoints = text.codePointCount(0, text.length)
    val spans = mentions.mapNotNull { mention ->
        if (mention.start < 0 || mention.length < 2 || mention.start.toLong() + mention.length > codePoints) return@mapNotNull null
        val from = text.offsetByCodePoints(0, mention.start)
        val to = text.offsetByCodePoints(from, mention.length)
        if (text[from] != '@') return@mapNotNull null
        FlareTextMentionSpan(
            start = from,
            length = to - from,
            self = !currentUserId.isNullOrEmpty() && (mention.userId == currentUserId || currentUserId in mention.userIds),
            all = mention.type == FlareMentionEntity.ALL,
        )
    }
    return withoutOverlaps(spans.sortedBy { it.start })
}

/**
 * The spans [TextMessage] can draw: inside [text], not empty, sorted, and not overlapping the span
 * kept before. Host-built spans pass through the same guard, so a stale index never throws.
 */
internal fun drawableMentionSpans(text: String, spans: List<FlareTextMentionSpan>): List<FlareTextMentionSpan> {
    if (spans.isEmpty()) return emptyList()
    val inside = spans.filter { it.start >= 0 && it.length > 0 && it.start.toLong() + it.length <= text.length }
    return withoutOverlaps(inside.sortedBy { it.start })
}

private fun withoutOverlaps(sorted: List<FlareTextMentionSpan>): List<FlareTextMentionSpan> {
    val kept = ArrayList<FlareTextMentionSpan>(sorted.size)
    for (span in sorted) {
        val previous = kept.lastOrNull()
        if (previous == null || span.start >= previous.start + previous.length) kept += span
    }
    return kept
}
