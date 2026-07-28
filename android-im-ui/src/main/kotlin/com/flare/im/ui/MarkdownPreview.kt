package com.flare.im.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.sp

/**
 * Read-only Markdown/RichDoc renderer with optional stats. Spec:
 * Media/MarkdownPreview (`MarkdownPreview`). Compact, dependency-free: headings,
 * bold/italic, inline code, fenced code, bullet/ordered lists, links.
 */
@Composable
fun MarkdownPreview(content: String, showStats: Boolean = false) {
    val colors = flareColors()
    Column(Modifier.fillMaxWidth()) {
        for (block in parseBlocks(content)) {
            when (block) {
                is Block.Heading -> Text(
                    inline(block.text), color = colors.textPrimary, fontWeight = FontWeight.Bold,
                    fontSize = (if (block.level == 1) FlareSizes.fontSize4xl else if (block.level == 2) FlareSizes.fontSize3xl else FlareSizes.fontSize2xl).value.sp,
                    modifier = Modifier.padding(vertical = FlareSizes.spacingXs),
                )
                is Block.Bullet -> Row(Modifier.padding(bottom = FlareSizes.spacingXs)) {
                    Text("•  ", color = colors.textPrimary); Text(inline(block.text), color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp)
                }
                is Block.Ordered -> Row(Modifier.padding(bottom = FlareSizes.spacingXs)) {
                    Text("${block.n}.  ", color = colors.textPrimary); Text(inline(block.text), color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp)
                }
                is Block.Code -> Text(
                    block.text, fontFamily = FontFamily.Monospace, color = colors.textPrimary, fontSize = FlareSizes.fontSizeMd.value.sp,
                    modifier = Modifier.fillMaxWidth().padding(bottom = FlareSizes.spacingSm)
                        .clip(RoundedCornerShape(FlareSizes.radiusMd)).background(colors.bgTertiary).padding(FlareSizes.spacingMd),
                )
                is Block.Paragraph -> Text(inline(block.text), color = colors.textPrimary, fontSize = FlareSizes.fontSizeLg.value.sp,
                    modifier = Modifier.padding(bottom = FlareSizes.spacingSm))
            }
        }
        if (showStats) {
            val words = content.split(Regex("\\s+")).count { it.isNotEmpty() }
            Text("$words 个词 · ${content.length} 字符", color = colors.textTertiary, fontSize = FlareSizes.fontSizeXs.value.sp)
        }
    }
}

private sealed interface Block {
    data class Heading(val text: String, val level: Int) : Block
    data class Bullet(val text: String) : Block
    data class Ordered(val n: Int, val text: String) : Block
    data class Code(val text: String) : Block
    data class Paragraph(val text: String) : Block
}

private fun parseBlocks(src: String): List<Block> {
    val lines = src.replace("\r\n", "\n").split("\n")
    val out = mutableListOf<Block>()
    var i = 0
    while (i < lines.size) {
        val line = lines[i]
        if (line.trimStart().startsWith("```")) {
            val buf = mutableListOf<String>(); i++
            while (i < lines.size && !lines[i].trimStart().startsWith("```")) { buf.add(lines[i]); i++ }
            i++; out.add(Block.Code(buf.joinToString("\n"))); continue
        }
        if (line.isBlank()) { i++; continue }
        val h = Regex("^(#{1,3})\\s+(.*)$").find(line)
        if (h != null) {
            out.add(Block.Heading(h.groupValues[2], h.groupValues[1].length)); i++; continue
        }
        if (Regex("^\\s*[-*]\\s+").containsMatchIn(line)) {
            while (i < lines.size && Regex("^\\s*[-*]\\s+").containsMatchIn(lines[i])) {
                out.add(Block.Bullet(lines[i].replaceFirst(Regex("^\\s*[-*]\\s+"), ""))); i++
            }
            continue
        }
        if (Regex("^\\s*\\d+\\.\\s+").containsMatchIn(line)) {
            var n = 1
            while (i < lines.size && Regex("^\\s*\\d+\\.\\s+").containsMatchIn(lines[i])) {
                out.add(Block.Ordered(n, lines[i].replaceFirst(Regex("^\\s*\\d+\\.\\s+"), ""))); n++; i++
            }
            continue
        }
        out.add(Block.Paragraph(line)); i++
    }
    return out
}

private val inlinePattern = Regex("(\\*\\*(.+?)\\*\\*)|(\\*(.+?)\\*)|(_(.+?)_)|(`(.+?)`)|(\\[(.+?)\\]\\((.+?)\\))")

private fun inline(text: String): AnnotatedString = buildAnnotatedString {
    var last = 0
    for (m in inlinePattern.findAll(text)) {
        if (m.range.first > last) append(text.substring(last, m.range.first))
        val g = m.groupValues
        when {
            g[1].isNotEmpty() -> withStyle(SpanStyle(fontWeight = FontWeight.Bold)) { append(g[2]) }
            g[3].isNotEmpty() -> withStyle(SpanStyle(fontStyle = FontStyle.Italic)) { append(g[4]) }
            g[5].isNotEmpty() -> withStyle(SpanStyle(fontStyle = FontStyle.Italic)) { append(g[6]) }
            g[7].isNotEmpty() -> withStyle(SpanStyle(fontFamily = FontFamily.Monospace)) { append(g[8]) }
            g[9].isNotEmpty() -> withStyle(SpanStyle(textDecoration = TextDecoration.Underline)) { append(g[10]) }
        }
        last = m.range.last + 1
    }
    if (last < text.length) append(text.substring(last))
}
