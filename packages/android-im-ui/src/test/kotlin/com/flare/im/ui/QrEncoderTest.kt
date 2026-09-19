package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

/** FR-031: the kit QR encoder against the qrcodegen reference matrices in [QrOracleData]. */
class QrEncoderTest {
    private fun rows(symbol: QrSymbol): List<String> = (0 until symbol.size).map { y ->
        buildString { for (x in 0 until symbol.size) append(if (symbol.isDark(x, y)) '1' else '0') }
    }

    /** FNV-1a 32 over the concatenated row strings (same as the oracle dump). */
    private fun fnv1a32(rows: List<String>): String {
        var hash = 0x811c9dc5.toInt()
        for (row in rows) for (unit in row) hash = (hash xor unit.code) * 0x01000193
        return hash.toUInt().toString(16).padStart(8, '0')
    }

    private fun darkCount(rows: List<String>) = rows.sumOf { row -> row.count { it == '1' } }

    @Test fun matchesReferenceMatricesBitForBit() {
        for (case in QrOracleData.cases) {
            val symbol = assertNotNull(
                QrEncoder.encodeText(case.payload, case.forcedMask.takeIf { it >= 0 }),
                case.id,
            )
            assertEquals(case.version, symbol.version, "${case.id}: smallest version")
            assertEquals(4 * case.version + 17, symbol.size, "${case.id}: size")
            val maskKind = if (case.forcedMask < 0) "automatic mask choice" else "forced mask"
            assertEquals(case.mask, symbol.mask, "${case.id}: $maskKind")
            val actual = rows(symbol)
            for (y in actual.indices) assertEquals(case.rows[y], actual[y], "${case.id}: row $y")
        }
    }

    @Test fun forcedCasesCoverAllEightMasks() {
        assertEquals((0..7).toSet(), QrOracleData.cases.map { it.forcedMask }.filter { it >= 0 }.toSet())
    }

    @Test fun versionSweepAtByteCapacityMatchesReference() {
        assertEquals((1..40).toList(), QrOracleData.sweep.map { it.version })
        for (s in QrOracleData.sweep) {
            val payload = String(CharArray(s.length) { i -> (33 + (i * 7 + s.version * 13) % 94).toChar() })
            val auto = assertNotNull(QrEncoder.encodeText(payload), "v${s.version}")
            assertEquals(s.version, auto.version, "v${s.version}: version")
            assertEquals(s.autoMask, auto.mask, "v${s.version}: automatic mask choice")
            val autoRows = rows(auto)
            assertEquals(s.autoDark, darkCount(autoRows), "v${s.version}: dark modules")
            assertEquals(s.autoHash, fnv1a32(autoRows), "v${s.version}: matrix hash")

            val forced = assertNotNull(QrEncoder.encodeText(payload, s.forcedMask), "v${s.version} forced")
            assertEquals(s.forcedMask, forced.mask)
            val forcedRows = rows(forced)
            assertEquals(s.forcedDark, darkCount(forcedRows), "v${s.version} mask ${s.forcedMask}: dark modules")
            assertEquals(s.forcedHash, fnv1a32(forcedRows), "v${s.version} mask ${s.forcedMask}: matrix hash")
        }
    }

    @Test fun picksTheSmallestVersionAtEveryCapacityBoundary() {
        for (version in 1 until 40) {
            val fits = ByteArray(QrOracleData.capacity[version]) { 0x61 }
            assertEquals(version, QrEncoder.encodeBytes(fits)?.version, "${fits.size} bytes")
            assertEquals(version + 1, QrEncoder.encodeBytes(fits + 0x61.toByte())?.version, "${fits.size + 1} bytes")
        }
    }

    @Test fun rejectsPayloadsLongerThanVersion40Holds() {
        assertNotNull(QrEncoder.encodeBytes(ByteArray(QrOracleData.capacity[40]) { 0x61 }))
        assertNull(QrEncoder.encodeBytes(ByteArray(QrOracleData.capacity[40] + 1) { 0x61 }))
    }
}
