package com.flare.im.ui

import kotlin.math.abs

/**
 * One encoded QR Code symbol (ISO/IEC 18004): [size] × [size] modules without the quiet zone.
 * Internal to the kit — [QRCard] renders it.
 */
internal class QrSymbol(
    /** Symbol version, 1…40. */
    val version: Int,
    /** Data mask pattern reference, 0…7. */
    val mask: Int,
    /** Modules per side: `4 * version + 17`. */
    val size: Int,
    /** Row-major module colors, true = dark. */
    private val modules: BooleanArray,
) {
    /** Whether the module in column [x] and row [y] is dark. */
    fun isDark(x: Int, y: Int): Boolean = modules[y * size + x]
}

/**
 * Byte-mode QR Code encoder at error correction level M.
 *
 * Data encoding, Reed–Solomon error correction with block interleaving, function patterns
 * (finders, separators, timing, alignment, format and version information) and mask selection
 * by the four penalty rules follow ISO/IEC 18004. The kit only needs level M, so the level
 * tables are M only.
 */
internal object QrEncoder {
    /** Light modules required around the symbol on every side. */
    const val QUIET_ZONE = 4

    private const val MAX_VERSION = 40

    // Level M, indexed by version - 1 (ISO/IEC 18004 Table 9).
    private val eccCodewordsPerBlock = intArrayOf(
        10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26, 26, 26,
        26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
    )
    private val eccBlockCount = intArrayOf(
        1, 1, 1, 2, 2, 4, 4, 4, 5, 5, 5, 8, 9, 9, 10, 10, 11, 13, 14, 16,
        17, 17, 18, 20, 21, 23, 25, 26, 28, 29, 31, 33, 35, 37, 38, 40, 43, 45, 47, 49,
    )

    /**
     * Encodes [text] as UTF-8 bytes in the smallest version that holds it. Returns null when the
     * payload does not fit version 40. [mask] forces a mask pattern (0…7); by default the
     * lowest-penalty pattern is used.
     */
    fun encodeText(text: String, mask: Int? = null): QrSymbol? =
        encodeBytes(text.toByteArray(Charsets.UTF_8), mask)

    /** Encodes raw [bytes]; see [encodeText]. */
    fun encodeBytes(bytes: ByteArray, mask: Int? = null): QrSymbol? {
        require(mask == null || mask in 0..7) { "mask must be 0..7" }
        val version = (1..MAX_VERSION).firstOrNull { v ->
            4 + countBits(v) + bytes.size * 8 <= dataCodewords(v) * 8
        } ?: return null
        val codewords = addErrorCorrection(version, dataBytes(version, bytes))
        return SymbolBuilder(version).build(codewords, mask)
    }

    /** Byte-mode character count indicator width. */
    private fun countBits(version: Int): Int = if (version < 10) 8 else 16

    /** Modules left for codewords once every function pattern is placed. */
    private fun rawDataModules(version: Int): Int {
        val size = 4 * version + 17
        // Three finders with separators (8 × 8 each), 31 format modules including the dark
        // module, and the two timing lines between the finders.
        var modules = size * size - 3 * 64 - 31 - 2 * (size - 16)
        if (version >= 2) {
            val perAxis = version / 7 + 2
            // n² - 3 alignment patterns of 25 modules; the ones centred on row or column 6
            // share five modules with a timing line.
            modules -= 25 * (perAxis * perAxis - 3) - 10 * (perAxis - 2)
        }
        if (version >= 7) modules -= 36
        return modules
    }

    private fun totalCodewords(version: Int): Int = rawDataModules(version) / 8

    private fun dataCodewords(version: Int): Int =
        totalCodewords(version) - eccCodewordsPerBlock[version - 1] * eccBlockCount[version - 1]

    /** Mode indicator, count, payload, terminator, bit padding and pad codewords. */
    private fun dataBytes(version: Int, bytes: ByteArray): IntArray {
        val capacity = dataCodewords(version)
        val out = IntArray(capacity)
        var bit = 0
        fun write(value: Int, width: Int) {
            for (i in width - 1 downTo 0) {
                if ((value shr i) and 1 == 1) out[bit shr 3] = out[bit shr 3] or (0x80 shr (bit and 7))
                bit++
            }
        }
        write(0x4, 4)
        write(bytes.size, countBits(version))
        for (byte in bytes) write(byte.toInt() and 0xFF, 8)
        bit += minOf(4, capacity * 8 - bit) // terminator (zero bits)
        var pad = 0xEC
        for (index in (bit + 7) shr 3 until capacity) { // the rest of the last byte stays zero
            out[index] = pad
            pad = pad xor (0xEC xor 0x11)
        }
        return out
    }

    /** Splits [data] into blocks, appends each block's Reed–Solomon codewords and interleaves. */
    private fun addErrorCorrection(version: Int, data: IntArray): IntArray {
        val blocks = eccBlockCount[version - 1]
        val eccLength = eccCodewordsPerBlock[version - 1]
        val shortLength = data.size / blocks
        val shortBlocks = blocks - data.size % blocks
        val divisor = Gf256.generator(eccLength)

        val starts = IntArray(blocks)
        val lengths = IntArray(blocks)
        val ecc = ArrayList<IntArray>(blocks)
        var offset = 0
        for (b in 0 until blocks) {
            val length = if (b < shortBlocks) shortLength else shortLength + 1
            starts[b] = offset
            lengths[b] = length
            ecc += Gf256.remainder(data, offset, length, divisor)
            offset += length
        }

        val out = IntArray(totalCodewords(version))
        var k = 0
        for (i in 0..shortLength) {
            for (b in 0 until blocks) if (i < lengths[b]) out[k++] = data[starts[b] + i]
        }
        for (i in 0 until eccLength) {
            for (b in 0 until blocks) out[k++] = ecc[b][i]
        }
        check(k == out.size)
        return out
    }
}

/** GF(2⁸) arithmetic over the QR Code field polynomial x⁸ + x⁴ + x³ + x² + 1. */
private object Gf256 {
    /** αⁱ for i in 0…509 (the period is written twice to avoid a modulo). */
    private val exp = IntArray(510).also { table ->
        var value = 1
        for (power in 0 until 255) {
            table[power] = value
            table[power + 255] = value
            value = value shl 1
            if ((value and 0x100) != 0) value = value xor 0x11D
        }
    }

    /** Discrete logarithm base α of every non-zero element. */
    private val log = IntArray(256).also { table ->
        for (power in 0 until 255) table[exp[power]] = power
    }

    fun multiply(a: Int, b: Int): Int = if (a == 0 || b == 0) 0 else exp[log[a] + log[b]]

    /** Monic generator polynomial ∏(x − αⁱ), i < [degree], highest power first. */
    fun generator(degree: Int): IntArray {
        var poly = intArrayOf(1)
        for (i in 0 until degree) {
            val next = IntArray(poly.size + 1)
            for (j in poly.indices) {
                next[j] = next[j] xor poly[j]
                next[j + 1] = next[j + 1] xor multiply(poly[j], exp[i])
            }
            poly = next
        }
        return poly
    }

    /** Remainder of message(x) · x^degree divided by [divisor]. */
    fun remainder(message: IntArray, start: Int, length: Int, divisor: IntArray): IntArray {
        val degree = divisor.size - 1
        val register = IntArray(degree)
        for (i in start until start + length) {
            val factor = message[i] xor register[0]
            System.arraycopy(register, 1, register, 0, degree - 1)
            register[degree - 1] = 0
            if (factor == 0) continue
            for (j in 0 until degree) register[j] = register[j] xor multiply(divisor[j + 1], factor)
        }
        return register
    }
}

/** Places function patterns and codewords for one version, then masks. */
private class SymbolBuilder(private val version: Int) {
    private val size = 4 * version + 17

    /** true = dark. */
    private val modules = BooleanArray(size * size)

    /** true = function module (never masked, never holds data). */
    private val function = BooleanArray(size * size)

    fun build(codewords: IntArray, forcedMask: Int?): QrSymbol {
        placeFunctionPatterns()
        placeCodewords(codewords)
        var mask = forcedMask ?: -1
        if (mask < 0) {
            var lowest = Int.MAX_VALUE
            for (candidate in 0..7) {
                toggleMask(candidate)
                placeFormat(candidate)
                val score = penalty()
                if (score < lowest) {
                    lowest = score
                    mask = candidate
                }
                toggleMask(candidate)
            }
        }
        toggleMask(mask)
        placeFormat(mask)
        return QrSymbol(version, mask, size, modules)
    }

    private fun set(x: Int, y: Int, dark: Boolean) {
        val index = y * size + x
        modules[index] = dark
        function[index] = true
    }

    private fun placeFunctionPatterns() {
        for (i in 0 until size) {
            set(6, i, i % 2 == 0)
            set(i, 6, i % 2 == 0)
        }
        finder(3, 3)
        finder(size - 4, 3)
        finder(3, size - 4)

        val centres = alignmentCentres()
        val last = centres.lastIndex
        for (i in centres.indices) {
            for (j in centres.indices) {
                val onFinder = (i == 0 && j == 0) || (i == 0 && j == last) || (i == last && j == 0)
                if (!onFinder) alignment(centres[i], centres[j])
            }
        }

        placeFormat(0) // reserves the format areas; rewritten after masking
        if (version >= 7) placeVersion()
    }

    /** 7 × 7 finder pattern plus its one-module light separator. */
    private fun finder(cx: Int, cy: Int) {
        for (dy in -4..4) {
            for (dx in -4..4) {
                val x = cx + dx
                val y = cy + dy
                if (x < 0 || y < 0 || x >= size || y >= size) continue
                val ring = maxOf(abs(dx), abs(dy))
                set(x, y, ring != 2 && ring != 4)
            }
        }
    }

    private fun alignment(cx: Int, cy: Int) {
        for (dy in -2..2) {
            for (dx in -2..2) set(cx + dx, cy + dy, maxOf(abs(dx), abs(dy)) != 1)
        }
    }

    /**
     * Row/column centres of the alignment patterns (ISO/IEC 18004 Annex E): 6, then evenly
     * spaced back from `size - 7` by an even step.
     */
    private fun alignmentCentres(): IntArray {
        if (version == 1) return IntArray(0)
        val count = version / 7 + 2
        val last = size - 7
        val step = if (version == 32) 26 else ((last - 6) + 2 * (count - 1) - 1) / (2 * (count - 1)) * 2
        return IntArray(count) { i -> if (i == 0) 6 else last - (count - 1 - i) * step }
    }

    private fun placeFormat(mask: Int) {
        val bits = formatBits(mask)
        fun bit(i: Int) = (bits shr i) and 1 == 1
        // Copy next to the top-left finder.
        for (i in 0..5) set(8, i, bit(i))
        set(8, 7, bit(6))
        set(8, 8, bit(7))
        set(7, 8, bit(8))
        for (i in 9 until 15) set(14 - i, 8, bit(i))
        // Copy split between the top-right and bottom-left finders.
        for (i in 0 until 8) set(size - 1 - i, 8, bit(i))
        for (i in 8 until 15) set(8, size - 15 + i, bit(i))
        set(8, size - 8, true) // dark module
    }

    /** Level M (indicator 00) + mask, BCH(15, 5) protected, XOR 101010000010010. */
    private fun formatBits(mask: Int): Int {
        val data = mask // (0b00 shl 3) or mask
        var value = data shl 10
        for (i in 14 downTo 10) {
            if ((value shr i) and 1 == 1) value = value xor (0x537 shl (i - 10))
        }
        return ((data shl 10) or value) xor 0x5412
    }

    private fun placeVersion() {
        var value = version shl 12
        for (i in 17 downTo 12) {
            if ((value shr i) and 1 == 1) value = value xor (0x1F25 shl (i - 12))
        }
        val bits = (version shl 12) or value
        for (i in 0 until 18) {
            val dark = (bits shr i) and 1 == 1
            val across = size - 11 + i % 3
            val down = i / 3
            set(across, down, dark) // top-right block
            set(down, across, dark) // bottom-left block
        }
    }

    /**
     * Zig-zag placement in two-module columns from the bottom-right corner, skipping the
     * vertical timing line. Remainder bits stay light.
     */
    private fun placeCodewords(codewords: IntArray) {
        val totalBits = codewords.size * 8
        var bit = 0
        var upward = true
        var right = size - 1
        while (right >= 1) {
            if (right == 6) right = 5
            for (step in 0 until size) {
                val y = if (upward) size - 1 - step else step
                for (x in right downTo right - 1) {
                    val index = y * size + x
                    if (function[index]) continue
                    if (bit < totalBits) {
                        modules[index] = (codewords[bit shr 3] shr (7 - (bit and 7))) and 1 == 1
                    }
                    bit++
                }
            }
            upward = !upward
            right -= 2
        }
    }

    private fun toggleMask(mask: Int) {
        for (y in 0 until size) {
            for (x in 0 until size) {
                val index = y * size + x
                if (!function[index] && maskHit(mask, x, y)) modules[index] = !modules[index]
            }
        }
    }

    /** Mask condition for column [x], row [y]. */
    private fun maskHit(mask: Int, x: Int, y: Int): Boolean = when (mask) {
        0 -> (x + y) % 2 == 0
        1 -> y % 2 == 0
        2 -> x % 3 == 0
        3 -> (x + y) % 3 == 0
        4 -> (y / 2 + x / 3) % 2 == 0
        5 -> (x * y) % 2 + (x * y) % 3 == 0
        6 -> ((x * y) % 2 + (x * y) % 3) % 2 == 0
        else -> ((x + y) % 2 + (x * y) % 3) % 2 == 0
    }

    /** Penalty score of the current symbol, format information included. */
    private fun penalty(): Int {
        var score = 0
        val runs = IntArray(size + 2)
        for (line in 0 until size) {
            score += linePenalty(runs, line, horizontal = true)
            score += linePenalty(runs, line, horizontal = false)
        }
        // N2: every 2 × 2 block of one color.
        for (y in 0 until size - 1) {
            for (x in 0 until size - 1) {
                val c = modules[y * size + x]
                if (c == modules[y * size + x + 1] && c == modules[(y + 1) * size + x] &&
                    c == modules[(y + 1) * size + x + 1]
                ) {
                    score += 3
                }
            }
        }
        // N4: 10 for every full 5 % step the dark share lies beyond 45…55 %.
        val dark = modules.count { it }
        val total = size * size
        val deviation = abs(dark * 20 - total * 10)
        score += ((deviation + total - 1) / total - 1) * 10
        return score
    }

    /**
     * N1 (runs of five or more) and N3 (1:1:3:1:1 finder-like patterns with four light modules
     * on one side) for one row or column. The quiet zone counts as light beyond both ends.
     */
    private fun linePenalty(runs: IntArray, line: Int, horizontal: Boolean): Int {
        var score = 0
        var count = 0 // runs[0] is light, then colors alternate
        var dark = false
        var length = 0
        fun close() {
            if (length >= 5) score += 3 + (length - 5)
            runs[count++] = length
        }
        for (i in 0 until size) {
            val m = if (horizontal) modules[line * size + i] else modules[i * size + line]
            if (m == dark) {
                length++
            } else {
                close()
                dark = m
                length = 1
            }
        }
        close()
        if (dark) runs[count++] = 0 // trailing light run of zero modules
        runs[0] += size
        runs[count - 1] += size

        // Dark runs sit at odd indices; a pattern needs a light run on each side.
        var d = 1
        while (d + 5 < count) {
            val n = runs[d]
            if (runs[d + 1] == n && runs[d + 2] == 3 * n && runs[d + 3] == n && runs[d + 4] == n) {
                val before = runs[d - 1]
                val after = runs[d + 5]
                if (before >= 4 * n && after >= n) score += 40
                if (after >= 4 * n && before >= n) score += 40
            }
            d += 2
        }
        return score
    }
}
