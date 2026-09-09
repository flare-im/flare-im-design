import { describe, it, expect } from "vitest";
import {
  canClearStorage,
  formatBytes,
  storageShare,
  storageTotals,
  type StorageCategory,
} from "./storage-usage";

const KB = 1024;
const MB = 1024 * 1024;
const GB = 1024 * 1024 * 1024;
const TB = 1024 * 1024 * 1024 * 1024;

const category = (over: Partial<StorageCategory> = {}): StorageCategory => ({
  id: "images",
  label: "图片",
  bytes: 12 * MB,
  clearable: true,
  ...over,
});

describe("formatBytes", () => {
  it("prints whole bytes below 1 KB, zero included", () => {
    expect(formatBytes(0)).toBe("0 B");
    expect(formatBytes(1)).toBe("1 B");
    expect(formatBytes(1023)).toBe("1023 B");
  });

  it("steps by 1024 through KB, MB, GB and TB with one decimal", () => {
    expect(formatBytes(KB)).toBe("1.0 KB");
    expect(formatBytes(1536)).toBe("1.5 KB");
    expect(formatBytes(2 * KB)).toBe("2.0 KB");
    expect(formatBytes(MB)).toBe("1.0 MB");
    expect(formatBytes(GB)).toBe("1.0 GB");
    expect(formatBytes(1.5 * GB)).toBe("1.5 GB");
    expect(formatBytes(TB)).toBe("1.0 TB");
  });

  it("never goes above TB, so a huge number stays readable", () => {
    expect(formatBytes(2048 * TB)).toBe("2048.0 TB");
  });

  it("returns null — not 0 B — for every size it does not know", () => {
    expect(formatBytes(null)).toBeNull();
    expect(formatBytes(undefined)).toBeNull();
    expect(formatBytes(Number.NaN)).toBeNull();
    expect(formatBytes(Number.POSITIVE_INFINITY)).toBeNull();
    expect(formatBytes(Number.NEGATIVE_INFINITY)).toBeNull();
    expect(formatBytes(-1)).toBeNull();
    expect(formatBytes(-1 * GB)).toBeNull();
  });

  it("reads the same in every locale, so two devices never disagree", () => {
    expect(formatBytes(1536, "de-DE")).toBe(formatBytes(1536));
    expect(formatBytes(1536, "zh-CN")).toBe("1.5 KB");
  });
});

describe("storageTotals", () => {
  it("sums the known categories and reports nothing missing", () => {
    const totals = storageTotals([category({ bytes: MB }), category({ id: "files", bytes: 2 * MB })]);
    expect(totals).toEqual({ knownBytes: 3 * MB, hasUnknown: false, total: 3 * MB });
  });

  it("flags hasUnknown when any category has no measured size, and leaves it out of the sum", () => {
    const totals = storageTotals([
      category({ bytes: MB }),
      category({ id: "video", bytes: null }),
      category({ id: "voice", bytes: undefined }),
      category({ id: "broken", bytes: Number.NaN }),
      category({ id: "negative", bytes: -5 }),
    ]);
    expect(totals.knownBytes).toBe(MB);
    expect(totals.hasUnknown).toBe(true);
    expect(totals.total).toBe(MB);
  });

  it("prefers a usable host total over its own sum", () => {
    const rows = [category({ bytes: MB })];
    expect(storageTotals(rows, 9 * MB).total).toBe(9 * MB);
    expect(storageTotals(rows, 9 * MB).knownBytes).toBe(MB);
    expect(storageTotals(rows, 0).total).toBe(0);
  });

  it("falls back to its own sum when the host total is unusable", () => {
    const rows = [category({ bytes: MB })];
    expect(storageTotals(rows, null).total).toBe(MB);
    expect(storageTotals(rows, undefined).total).toBe(MB);
    expect(storageTotals(rows, Number.NaN).total).toBe(MB);
    expect(storageTotals(rows, -1).total).toBe(MB);
  });

  it("treats an empty or missing list as zero, with nothing unknown", () => {
    expect(storageTotals([])).toEqual({ knownBytes: 0, hasUnknown: false, total: 0 });
    expect(storageTotals(null)).toEqual({ knownBytes: 0, hasUnknown: false, total: 0 });
  });

  it("does not mutate its input", () => {
    const rows = [category({ bytes: MB })];
    const snapshot = JSON.stringify(rows);
    storageTotals(rows, 2 * MB);
    expect(JSON.stringify(rows)).toBe(snapshot);
  });
});

describe("storageShare", () => {
  it("is the plain ratio when both sides are known", () => {
    expect(storageShare(MB, 4 * MB)).toBeCloseTo(0.25, 10);
    expect(storageShare(0, 4 * MB)).toBe(0);
    expect(storageShare(4 * MB, 4 * MB)).toBe(1);
  });

  it("clamps a category larger than the host total instead of overflowing the bar", () => {
    expect(storageShare(8 * MB, 4 * MB)).toBe(1);
  });

  it("returns null when the total is zero, so nothing draws a bar", () => {
    expect(storageShare(0, 0)).toBeNull();
    expect(storageShare(MB, 0)).toBeNull();
    expect(storageShare(MB, -1)).toBeNull();
  });

  it("returns null for an unknown size rather than a zero-width bar", () => {
    expect(storageShare(null, 4 * MB)).toBeNull();
    expect(storageShare(undefined, 4 * MB)).toBeNull();
    expect(storageShare(Number.NaN, 4 * MB)).toBeNull();
    expect(storageShare(-1, 4 * MB)).toBeNull();
    expect(storageShare(MB, null)).toBeNull();
    expect(storageShare(MB, Number.NaN)).toBeNull();
  });
});

describe("canClearStorage", () => {
  it("needs the host to declare the category clearable", () => {
    expect(canClearStorage(category({ clearable: true }))).toBe(true);
    expect(canClearStorage(category({ clearable: false }))).toBe(false);
    expect(canClearStorage(category({ clearable: undefined }))).toBe(false);
    expect(canClearStorage(null)).toBe(false);
    expect(canClearStorage(undefined)).toBe(false);
  });

  it("offers nothing to clear on a category measured at exactly zero", () => {
    expect(canClearStorage(category({ bytes: 0 }))).toBe(false);
  });

  it("keeps the button while the size is unknown — unmeasured is not empty", () => {
    expect(canClearStorage(category({ bytes: null }))).toBe(true);
    expect(canClearStorage(category({ bytes: undefined }))).toBe(true);
    expect(canClearStorage(category({ bytes: Number.NaN }))).toBe(true);
  });

  it("is independent of busy and error, which only lock or explain the row", () => {
    expect(canClearStorage(category({ busy: true }))).toBe(true);
    expect(canClearStorage(category({ error: "清理失败" }))).toBe(true);
  });
});
