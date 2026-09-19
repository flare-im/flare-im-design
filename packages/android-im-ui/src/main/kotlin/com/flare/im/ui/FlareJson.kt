package com.flare.im.ui

/**
 * Just enough JSON for the kit to read a document it is handed (a rich-text message's `docJson`) and for its
 * tests to read the shared tables. Android's `org.json` is not on a JVM test's classpath, so the kit carries
 * this instead: objects become [Map]s in source order, arrays [List]s, numbers [Double]s.
 *
 * Message documents come from other people. Nesting deeper than [MAX_NESTING] and anything after the value
 * are refused with an [IllegalArgumentException], like any other malformed input, rather than overflowing
 * the stack.
 */
internal object FlareJson {
    /** Deeper than any document the core accepts (64), shallow enough never to exhaust a thread's stack. */
    const val MAX_NESTING = 512

    fun parse(source: String): Any? {
        val reader = Reader(source)
        val value = reader.value(0)
        reader.skipSpace()
        require(reader.atEnd()) { "unexpected content after the value at ${reader.position}" }
        return value
    }

    private class Reader(private val src: String) {
        var position = 0
            private set

        fun atEnd() = position >= src.length

        fun value(depth: Int): Any? {
            require(depth <= MAX_NESTING) { "nesting deeper than $MAX_NESTING at $position" }
            skipSpace()
            require(!atEnd()) { "unexpected end of input" }
            return when (val c = src[position]) {
                '{' -> obj(depth)
                '[' -> array(depth)
                '"' -> string()
                't' -> literal("true", true)
                'f' -> literal("false", false)
                'n' -> literal("null", null)
                else -> if (c == '-' || c.isDigit()) number() else throw IllegalArgumentException("unexpected '$c' at $position")
            }
        }

        fun skipSpace() { while (!atEnd() && src[position].isWhitespace()) position++ }

        private fun obj(depth: Int): Map<String, Any?> {
            val out = LinkedHashMap<String, Any?>()
            position++ // {
            skipSpace()
            if (peek() == '}') { position++; return out }
            while (true) {
                skipSpace()
                val key = string()
                skipSpace()
                expect(':')
                out[key] = value(depth + 1)
                skipSpace()
                if (peek() == ',') { position++; continue }
                expect('}')
                return out
            }
        }

        private fun array(depth: Int): List<Any?> {
            val out = ArrayList<Any?>()
            position++ // [
            skipSpace()
            if (peek() == ']') { position++; return out }
            while (true) {
                out.add(value(depth + 1))
                skipSpace()
                if (peek() == ',') { position++; continue }
                expect(']')
                return out
            }
        }

        private fun string(): String {
            expect('"')
            val out = StringBuilder()
            while (peek() != '"') {
                val c = src[position++]
                if (c != '\\') { out.append(c); continue }
                when (val escape = next()) {
                    '"', '\\', '/' -> out.append(escape)
                    'b' -> out.append('\b')
                    'f' -> out.append('')
                    'n' -> out.append('\n')
                    'r' -> out.append('\r')
                    't' -> out.append('\t')
                    'u' -> {
                        require(position + 4 <= src.length) { "truncated escape at $position" }
                        out.append(src.substring(position, position + 4).toInt(16).toChar())
                        position += 4
                    }
                    else -> throw IllegalArgumentException("bad escape '\\$escape' at ${position - 1}")
                }
            }
            position++ // closing quote
            return out.toString()
        }

        private fun number(): Double {
            val start = position
            while (!atEnd() && (src[position].isDigit() || src[position] in "-+.eE")) position++
            return src.substring(start, position).toDouble()
        }

        private fun <T> literal(word: String, value: T): T {
            require(src.startsWith(word, position)) { "unexpected literal at $position" }
            position += word.length
            return value
        }

        private fun peek(): Char {
            require(!atEnd()) { "unexpected end of input" }
            return src[position]
        }

        private fun next(): Char = peek().also { position++ }

        private fun expect(c: Char) {
            require(peek() == c) { "expected '$c' at $position, found '${src[position]}'" }
            position++
        }
    }
}
