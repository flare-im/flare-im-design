package com.flare.im.ui

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class StorageUsageTest {
    private val kb = 1024.0
    private val mb = 1024.0 * 1024
    private val gb = 1024.0 * 1024 * 1024
    private val tb = 1024.0 * 1024 * 1024 * 1024

    private fun category(
        id: String = "images",
        label: String = "图片",
        bytes: Double? = 12 * 1024.0 * 1024,
        fileCount: Int? = null,
        clearable: Boolean = true,
        busy: Boolean = false,
        error: String? = null,
    ) = FlareStorageCategory(id, label, bytes, fileCount, clearable, busy, error)

    // formatBytes

    @Test fun printsWholeBytesBelowOneKilobyte() {
        assertEquals("0 B", formatBytes(0.0))
        assertEquals("1 B", formatBytes(1.0))
        assertEquals("1023 B", formatBytes(1023.0))
    }

    @Test fun stepsBy1024ThroughTerabytesWithOneDecimal() {
        assertEquals("1.0 KB", formatBytes(kb))
        assertEquals("1.5 KB", formatBytes(1536.0))
        assertEquals("2.0 KB", formatBytes(2 * kb))
        assertEquals("1.0 MB", formatBytes(mb))
        assertEquals("1.0 GB", formatBytes(gb))
        assertEquals("1.5 GB", formatBytes(1.5 * gb))
        assertEquals("1.0 TB", formatBytes(tb))
    }

    @Test fun neverGoesAboveTerabytes() {
        assertEquals("2048.0 TB", formatBytes(2048 * tb))
    }

    @Test fun returnsNullRatherThanZeroBytesForUnknownSizes() {
        assertNull(formatBytes(null))
        assertNull(formatBytes(Double.NaN))
        assertNull(formatBytes(Double.POSITIVE_INFINITY))
        assertNull(formatBytes(Double.NEGATIVE_INFINITY))
        assertNull(formatBytes(-1.0))
        assertNull(formatBytes(-1 * gb))
    }

    @Test fun readsTheSameInEveryLocale() {
        assertEquals(formatBytes(1536.0), formatBytes(1536.0, "de-DE"))
        assertEquals("1.5 KB", formatBytes(1536.0, "zh-CN"))
    }

    // storageTotals

    @Test fun sumsKnownCategories() {
        val totals = storageTotals(listOf(category(bytes = mb), category(id = "files", bytes = 2 * mb)))
        assertEquals(3 * mb, totals.knownBytes)
        assertFalse(totals.hasUnknown)
        assertEquals(3 * mb, totals.total)
    }

    @Test fun flagsUnknownAndLeavesUnmeasuredOutOfTheSum() {
        val totals = storageTotals(
            listOf(
                category(bytes = mb),
                category(id = "video", bytes = null),
                category(id = "broken", bytes = Double.NaN),
                category(id = "negative", bytes = -5.0),
            ),
        )
        assertEquals(mb, totals.knownBytes)
        assertTrue(totals.hasUnknown)
        assertEquals(mb, totals.total)
    }

    @Test fun prefersUsableHostTotal() {
        val rows = listOf(category(bytes = mb))
        assertEquals(9 * mb, storageTotals(rows, 9 * mb).total)
        assertEquals(mb, storageTotals(rows, 9 * mb).knownBytes)
        assertEquals(0.0, storageTotals(rows, 0.0).total)
    }

    @Test fun fallsBackToOwnSumWhenHostTotalIsUnusable() {
        val rows = listOf(category(bytes = mb))
        assertEquals(mb, storageTotals(rows, null).total)
        assertEquals(mb, storageTotals(rows, Double.NaN).total)
        assertEquals(mb, storageTotals(rows, -1.0).total)
    }

    @Test fun emptyListIsZeroWithNothingUnknown() {
        val totals = storageTotals(emptyList())
        assertEquals(0.0, totals.knownBytes)
        assertFalse(totals.hasUnknown)
        assertEquals(0.0, totals.total)
    }

    // storageShare

    @Test fun shareIsThePlainRatio() {
        assertEquals(0.25, storageShare(mb, 4 * mb)!!, 1e-10)
        assertEquals(0.0, storageShare(0.0, 4 * mb))
        assertEquals(1.0, storageShare(4 * mb, 4 * mb))
    }

    @Test fun shareClampsAboveTheHostTotal() {
        assertEquals(1.0, storageShare(8 * mb, 4 * mb))
    }

    @Test fun shareIsNullWhenTheTotalIsZero() {
        assertNull(storageShare(0.0, 0.0))
        assertNull(storageShare(mb, 0.0))
        assertNull(storageShare(mb, -1.0))
    }

    @Test fun shareIsNullForUnknownSizes() {
        assertNull(storageShare(null, 4 * mb))
        assertNull(storageShare(Double.NaN, 4 * mb))
        assertNull(storageShare(-1.0, 4 * mb))
        assertNull(storageShare(mb, null))
        assertNull(storageShare(mb, Double.NaN))
    }

    // canClearStorage

    @Test fun clearNeedsTheHostToDeclareItClearable() {
        assertTrue(canClearStorage(category(clearable = true)))
        assertFalse(canClearStorage(category(clearable = false)))
        assertFalse(canClearStorage(null))
    }

    @Test fun nothingToClearOnAZeroByteCategory() {
        assertFalse(canClearStorage(category(bytes = 0.0)))
    }

    @Test fun unknownSizeKeepsTheClearButton() {
        assertTrue(canClearStorage(category(bytes = null)))
        assertTrue(canClearStorage(category(bytes = Double.NaN)))
    }

    @Test fun clearIsIndependentOfBusyAndError() {
        assertTrue(canClearStorage(category(busy = true)))
        assertTrue(canClearStorage(category(error = "清理失败")))
    }

    // panel text rules

    @Test fun totalIsAFloorOnlyWhenThePanelSummedItItself() {
        val rows = listOf(category(bytes = mb), category(id = "video", bytes = null))
        assertTrue(storageTotalIsFloor(storageTotals(rows), null))
        assertFalse(storageTotalIsFloor(storageTotals(rows, 9 * mb), 9 * mb))
        assertFalse(storageTotalIsFloor(storageTotals(listOf(category(bytes = mb))), null))
    }

    @Test fun fileCountLabelIgnoresMissingOrNegativeCounts() {
        assertEquals("0 个文件", storageFileCountLabel("{count} 个文件", 0))
        assertEquals("12 个文件", storageFileCountLabel("{count} 个文件", 12))
        assertNull(storageFileCountLabel("{count} 个文件", null))
        assertNull(storageFileCountLabel("{count} 个文件", -1))
    }
}
