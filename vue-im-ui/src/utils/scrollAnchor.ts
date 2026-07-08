export type ScrollAnchorSnapshot = {
  scrollTop: number;
  scrollHeight: number;
};

type KeyOf<T> = (item: T) => string;

type ListWindow = {
  prepended: number;
  appended: number;
};

function locatePreviousWindow<T>(
  previous: readonly T[],
  next: readonly T[],
  keyOf: KeyOf<T>,
): ListWindow | null {
  if (previous.length === 0 || next.length <= previous.length) return null;
  const lastStart = next.length - previous.length;
  for (let start = 0; start <= lastStart; start += 1) {
    let matched = true;
    for (let index = 0; index < previous.length; index += 1) {
      if (keyOf(previous[index]!) !== keyOf(next[start + index]!)) {
        matched = false;
        break;
      }
    }
    if (!matched) continue;
    return {
      prepended: start,
      appended: next.length - start - previous.length,
    };
  }
  return null;
}

export function countPrependedItems<T>(
  previous: readonly T[],
  next: readonly T[],
  keyOf: KeyOf<T>,
): number {
  return locatePreviousWindow(previous, next, keyOf)?.prepended ?? 0;
}

export function countAppendedItems<T>(
  previous: readonly T[],
  next: readonly T[],
  keyOf: KeyOf<T>,
): number {
  return locatePreviousWindow(previous, next, keyOf)?.appended ?? 0;
}

export function restorePrependScrollTop(
  snapshot: ScrollAnchorSnapshot,
  nextScrollHeight: number,
): number {
  return Math.max(
    0,
    snapshot.scrollTop + Math.max(0, nextScrollHeight - snapshot.scrollHeight),
  );
}
