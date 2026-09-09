import XCTest
@testable import FlareIMUI

final class StorageUsageTests: XCTestCase {
    private let kb = 1024.0
    private let mb = 1024.0 * 1024
    private let gb = 1024.0 * 1024 * 1024
    private let tb = 1024.0 * 1024 * 1024 * 1024

    private func category(id: String = "images", label: String = "图片",
                          bytes: Double? = 12 * 1024 * 1024, fileCount: Int? = nil,
                          clearable: Bool = true, busy: Bool = false,
                          error: String? = nil) -> FlareStorageCategory {
        FlareStorageCategory(id: id, label: label, bytes: bytes, fileCount: fileCount,
                             clearable: clearable, busy: busy, error: error)
    }

    // MARK: formatBytes

    func testPrintsWholeBytesBelowOneKilobyte() {
        XCTAssertEqual(formatBytes(0), "0 B")
        XCTAssertEqual(formatBytes(1), "1 B")
        XCTAssertEqual(formatBytes(1023), "1023 B")
    }

    func testStepsByOneThousandTwentyFourThroughTerabytes() {
        XCTAssertEqual(formatBytes(kb), "1.0 KB")
        XCTAssertEqual(formatBytes(1536), "1.5 KB")
        XCTAssertEqual(formatBytes(2 * kb), "2.0 KB")
        XCTAssertEqual(formatBytes(mb), "1.0 MB")
        XCTAssertEqual(formatBytes(gb), "1.0 GB")
        XCTAssertEqual(formatBytes(1.5 * gb), "1.5 GB")
        XCTAssertEqual(formatBytes(tb), "1.0 TB")
    }

    func testNeverGoesAboveTerabytes() {
        XCTAssertEqual(formatBytes(2048 * tb), "2048.0 TB")
    }

    func testReturnsNilRatherThanZeroBytesForUnknownSizes() {
        XCTAssertNil(formatBytes(nil))
        XCTAssertNil(formatBytes(Double.nan))
        XCTAssertNil(formatBytes(Double.infinity))
        XCTAssertNil(formatBytes(-Double.infinity))
        XCTAssertNil(formatBytes(-1))
        XCTAssertNil(formatBytes(-1 * gb))
    }

    func testReadsTheSameInEveryLocale() {
        XCTAssertEqual(formatBytes(1536, locale: "de-DE"), formatBytes(1536))
        XCTAssertEqual(formatBytes(1536, locale: "zh-CN"), "1.5 KB")
    }

    // MARK: storageTotals

    func testSumsKnownCategories() {
        let totals = storageTotals([category(bytes: mb), category(id: "files", bytes: 2 * mb)])
        XCTAssertEqual(totals.knownBytes, 3 * mb)
        XCTAssertFalse(totals.hasUnknown)
        XCTAssertEqual(totals.total, 3 * mb)
    }

    func testFlagsUnknownAndLeavesUnmeasuredOutOfTheSum() {
        let totals = storageTotals([
            category(bytes: mb),
            category(id: "video", bytes: nil),
            category(id: "broken", bytes: Double.nan),
            category(id: "negative", bytes: -5),
        ])
        XCTAssertEqual(totals.knownBytes, mb)
        XCTAssertTrue(totals.hasUnknown)
        XCTAssertEqual(totals.total, mb)
    }

    func testPrefersUsableHostTotal() {
        let rows = [category(bytes: mb)]
        XCTAssertEqual(storageTotals(rows, totalBytes: 9 * mb).total, 9 * mb)
        XCTAssertEqual(storageTotals(rows, totalBytes: 9 * mb).knownBytes, mb)
        XCTAssertEqual(storageTotals(rows, totalBytes: 0).total, 0)
    }

    func testFallsBackToOwnSumWhenHostTotalIsUnusable() {
        let rows = [category(bytes: mb)]
        XCTAssertEqual(storageTotals(rows, totalBytes: nil).total, mb)
        XCTAssertEqual(storageTotals(rows, totalBytes: Double.nan).total, mb)
        XCTAssertEqual(storageTotals(rows, totalBytes: -1).total, mb)
    }

    func testEmptyListIsZeroWithNothingUnknown() {
        let totals = storageTotals([])
        XCTAssertEqual(totals.knownBytes, 0)
        XCTAssertFalse(totals.hasUnknown)
        XCTAssertEqual(totals.total, 0)
    }

    // MARK: storageShare

    func testShareIsThePlainRatio() {
        XCTAssertEqual(storageShare(mb, total: 4 * mb) ?? -1, 0.25, accuracy: 1e-10)
        XCTAssertEqual(storageShare(0, total: 4 * mb), 0)
        XCTAssertEqual(storageShare(4 * mb, total: 4 * mb), 1)
    }

    func testShareClampsAboveTheHostTotal() {
        XCTAssertEqual(storageShare(8 * mb, total: 4 * mb), 1)
    }

    func testShareIsNilWhenTheTotalIsZero() {
        XCTAssertNil(storageShare(0, total: 0))
        XCTAssertNil(storageShare(mb, total: 0))
        XCTAssertNil(storageShare(mb, total: -1))
    }

    func testShareIsNilForUnknownSizes() {
        XCTAssertNil(storageShare(nil, total: 4 * mb))
        XCTAssertNil(storageShare(Double.nan, total: 4 * mb))
        XCTAssertNil(storageShare(-1, total: 4 * mb))
        XCTAssertNil(storageShare(mb, total: nil))
        XCTAssertNil(storageShare(mb, total: Double.nan))
    }

    // MARK: canClearStorage

    func testClearNeedsTheHostToDeclareItClearable() {
        XCTAssertTrue(canClearStorage(category(clearable: true)))
        XCTAssertFalse(canClearStorage(category(clearable: false)))
        XCTAssertFalse(canClearStorage(nil))
    }

    func testNothingToClearOnAZeroByteCategory() {
        XCTAssertFalse(canClearStorage(category(bytes: 0)))
    }

    func testUnknownSizeKeepsTheClearButton() {
        XCTAssertTrue(canClearStorage(category(bytes: nil)))
        XCTAssertTrue(canClearStorage(category(bytes: Double.nan)))
    }

    func testClearIsIndependentOfBusyAndError() {
        XCTAssertTrue(canClearStorage(category(busy: true)))
        XCTAssertTrue(canClearStorage(category(error: "清理失败")))
    }

    // MARK: view text rules

    func testUnknownSizeRendersUnknownTextNotZeroBytes() {
        let view = StorageUsageView(categories: [category(bytes: nil)])
        XCTAssertEqual(view.sizeText(nil), "未知")
        XCTAssertEqual(view.sizeText(0), "0 B")
        XCTAssertEqual(view.rowMeta(category(bytes: nil)), "未知")
        XCTAssertEqual(view.rowMeta(category(bytes: mb, fileCount: 12)), "1.0 MB · 12 个文件")
    }

    func testTotalIsLabelledAsAFloorOnlyWhenTheViewSummedItItself() {
        let rows = [category(bytes: mb), category(id: "video", bytes: nil)]
        let summed = StorageUsageView(categories: rows)
        XCTAssertEqual(summed.totalLabel(storageTotals(rows)), "至少 1.0 MB")

        let hosted = StorageUsageView(categories: rows, totalBytes: 9 * mb)
        XCTAssertEqual(hosted.totalLabel(storageTotals(rows, totalBytes: 9 * mb)), "9.0 MB")

        let allKnown = StorageUsageView(categories: [category(bytes: mb)])
        XCTAssertEqual(allKnown.totalLabel(storageTotals([category(bytes: mb)])), "1.0 MB")
    }

    func testHeadSummaryAddsFreeSpaceOnlyWhenTheHostKnowsIt() {
        let rows = [category(bytes: mb)]
        let totals = storageTotals(rows)
        XCTAssertEqual(StorageUsageView(categories: rows).headSummary(totals), "总计 1.0 MB")
        XCTAssertEqual(
            StorageUsageView(categories: rows, deviceFreeBytes: 2 * gb).headSummary(totals),
            "总计 1.0 MB · 可用空间 2.0 GB"
        )
    }

    func testFileCountLabelIgnoresMissingOrNegativeCounts() {
        let view = StorageUsageView(categories: [])
        XCTAssertEqual(view.fileCountLabel(0), "0 个文件")
        XCTAssertNil(view.fileCountLabel(nil))
        XCTAssertNil(view.fileCountLabel(-1))
    }
}
