/**
 * Storage usage contracts — pure logic shared by the four platforms behind the
 * settings page's "storage management" section (StorageUsage).
 *
 * The host owns the numbers: it hands over a snapshot of per-category usage and
 * says which categories it can clear. Nothing here performs a side effect, and
 * nothing here invents a number: a category whose size the host has not measured
 * yet stays unknown all the way to the screen, it never becomes 0 B.
 */

/** One storage category as the host measured it. `id` must be stable — it is echoed in every event. */
export interface StorageCategory {
  id: string;
  label: string;
  /**
   * Bytes this category occupies. `null`/absent (or any non-finite or negative
   * number) means "not measured yet" — the component says so instead of
   * printing 0 B, and draws no share bar for it.
   */
  bytes?: number | null;
  /** How many files make up the category; omitted when the host does not count them. */
  fileCount?: number;
  /** Host can clear this category. Absent/false hides the clear button entirely. */
  clearable?: boolean;
  /** This category's clear command is in flight — that row alone locks. */
  busy?: boolean;
  /** Why this category's last clear failed; kept until the host dismisses it. */
  error?: string;
}

/** Result of {@link storageTotals}. */
export interface StorageTotals {
  /** Sum of the categories whose size is actually known. */
  knownBytes: number;
  /** At least one category has no measured size, so `knownBytes` is a floor, not the truth. */
  hasUnknown: boolean;
  /** What to display as the total: the host's `totalBytes` when it gave a usable one, else `knownBytes`. */
  total: number;
}

/** Units above bytes, in ascending order; the last one is never exceeded. */
const STORAGE_UNITS = ["KB", "MB", "GB", "TB"] as const;

/** True for a number this contract is willing to treat as a real byte count. */
function isKnownBytes(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value) && value >= 0;
}

/**
 * Human byte size, or `null` when the size is not known.
 *
 * The rules are identical on all four platforms and deliberately locale-invariant,
 * so one snapshot reads the same on web, Flutter, iOS and Android:
 *
 *  - `null` / `undefined` / `NaN` / `Infinity` / negative → `null`; the caller
 *    renders its own "unknown" text rather than a fake `0 B`;
 *  - below 1024 bytes → `"N B"` (rounded to a whole byte);
 *  - from there 1024 per step through KB, MB, GB, TB, one decimal ("2.0 KB",
 *    "1.5 GB"); TB is the last unit, matching the existing message-attachment
 *    formatters on iOS and Android.
 *
 * `locale` is accepted so hosts can thread their locale through today; the digits
 * and the unit suffixes are the same in every locale on purpose — the same
 * storage snapshot must never read differently on two of the user's devices.
 */
export function formatBytes(bytes: number | null | undefined, locale?: string): string | null {
  void locale;
  if (!isKnownBytes(bytes)) return null;
  const rounded = Math.round(bytes);
  if (rounded < 1024) return `${rounded} B`;
  let value = bytes / 1024;
  let unit = 0;
  while (value >= 1024 && unit < STORAGE_UNITS.length - 1) {
    value /= 1024;
    unit += 1;
  }
  return `${value.toFixed(1)} ${STORAGE_UNITS[unit]}`;
}

/**
 * What to show as the overall footprint.
 *
 * `knownBytes` only sums the categories that actually have a size, and
 * `hasUnknown` says whether anything was left out — the component then labels
 * its own sum as "at least", instead of passing a partial sum off as the truth.
 * A `totalBytes` the host supplied wins (it can see things the category list
 * does not, e.g. a shared cache); an unusable one (non-finite or negative) falls
 * back to `knownBytes` rather than rendering nonsense.
 */
export function storageTotals(
  categories: readonly StorageCategory[] | null | undefined,
  totalBytes?: number | null,
): StorageTotals {
  let knownBytes = 0;
  let hasUnknown = false;
  for (const category of categories ?? []) {
    if (isKnownBytes(category?.bytes)) knownBytes += category.bytes as number;
    else hasUnknown = true;
  }
  return {
    knownBytes,
    hasUnknown,
    total: isKnownBytes(totalBytes) ? totalBytes : knownBytes,
  };
}

/**
 * This category's share of `total`, in 0..1, or `null` when it cannot be drawn:
 * the size is unknown, or the total is zero/unknown. A missing bar is the honest
 * answer — a zero-width bar would read as "this category is empty".
 */
export function storageShare(bytes: number | null | undefined, total: number | null | undefined): number | null {
  if (!isKnownBytes(bytes) || !isKnownBytes(total) || total <= 0) return null;
  const share = bytes / total;
  return share > 1 ? 1 : share;
}

/**
 * Whether to offer a clear button at all. The host must say the category is
 * clearable, and a category measured at exactly 0 bytes offers nothing to clear
 * — a button that cannot do anything is never rendered. An unknown size keeps
 * the button: not having measured it is not evidence that it is empty.
 */
export function canClearStorage(category: StorageCategory | null | undefined): boolean {
  if (!category || category.clearable !== true) return false;
  return category.bytes !== 0;
}
