package com.flare.im.ui

private const val WORD = "A-Za-z0-9_"

// A fenced block keeps what is inside it; the fence and its language are not words.
private val FENCE = Regex("```(?:[^\\n`]*)\\n?([\\s\\S]*?)```")
private val IMAGE = Regex("!\\[([^\\]\\n]*)\\]\\([^)]+\\)")
private val LINK = Regex("\\[([^\\]\\n]+)\\]\\([^)]+\\)")
private val HEADING = Regex("^#{1,6}\\s+", RegexOption.MULTILINE)
private val QUOTE = Regex("^\\s{0,3}>\\s?", RegexOption.MULTILINE)
private val BULLET = Regex("^\\s{0,3}(?:[-*+]|\\d+\\.)\\s+", RegexOption.MULTILINE)
private val RULE = Regex("^\\s{0,3}---+\\s*$", RegexOption.MULTILINE)
private val UNDERLINE = Regex("<u>([\\s\\S]+?)</u>", RegexOption.IGNORE_CASE)
private val BOLD_ITALIC = Regex("\\*\\*\\*([\\s\\S]+?)\\*\\*\\*")
private val BOLD_ITALIC_UNDERSCORE = Regex("___([\\s\\S]+?)___")
private val BOLD = Regex("\\*\\*([\\s\\S]+?)\\*\\*")
private val BOLD_UNDERSCORE = Regex("(^|[^$WORD])__([^_\\n]+?)__(?=$|[^$WORD])")
private val STRIKE = Regex("~~([\\s\\S]+?)~~")
private val CODE = Regex("`([^`\\n]+?)`")
private val ITALIC = Regex("\\*([^*\\n]+?)\\*")
private val ITALIC_UNDERSCORE = Regex("(^|[^$WORD])_([^_\\n]+?)_(?=$|[^$WORD])")
private val TRAILING_SPACE = Regex("[ \\t]+\\n")
private val BLANK_LINES = Regex("\\n{3,}")
private val NEWLINES = Regex("\\r\\n?")

/**
 * One markdown message read as one plain line — what a conversation row, a reply strip or a quote shows.
 * (The renderer that draws markdown as blocks is `MarkdownPreview`; this is the one-line reading of it.)
 *
 * Marks are stripped, never interpreted: a link keeps its words and loses its target, an image becomes the
 * `preview.image` term with its alt text when it has one, and a fenced block keeps the code inside it. The
 * rule is shared with the Vue, Flutter and SwiftUI kits and tested against
 * `spec/markdown-preview-vectors.json`; Vue has applied it to every preview since before this kit existed,
 * which is why the same string used to arrive here with its asterisks (FR-120).
 *
 * The word classes are written out as ASCII on purpose. `\w` means different things in different regex
 * engines, and `__周报__已发出` must read the same on every platform.
 */
fun flareMarkdownToPlainText(content: String, strings: FlareStrings): String {
    var text = NEWLINES.replace(content, "\n")
    text = FENCE.replace(text) { it.groupValues[1] }
    text = IMAGE.replace(text) { match ->
        val label = match.groupValues[1].trim()
        if (label.isEmpty()) strings.previewImage else strings.previewImageNamed(label)
    }
    text = LINK.replace(text) { it.groupValues[1] }
    text = HEADING.replace(text, "")
    text = QUOTE.replace(text, "")
    text = BULLET.replace(text, "")
    text = RULE.replace(text, " ")
    text = UNDERLINE.replace(text) { it.groupValues[1] }
    text = BOLD_ITALIC.replace(text) { it.groupValues[1] }
    text = BOLD_ITALIC_UNDERSCORE.replace(text) { it.groupValues[1] }
    text = BOLD.replace(text) { it.groupValues[1] }
    text = BOLD_UNDERSCORE.replace(text) { it.groupValues[1] + it.groupValues[2] }
    text = STRIKE.replace(text) { it.groupValues[1] }
    text = CODE.replace(text) { it.groupValues[1] }
    text = ITALIC.replace(text) { it.groupValues[1] }
    text = ITALIC_UNDERSCORE.replace(text) { it.groupValues[1] + it.groupValues[2] }
    text = TRAILING_SPACE.replace(text, "\n")
    text = BLANK_LINES.replace(text, "\n\n")
    return text.trim()
}
