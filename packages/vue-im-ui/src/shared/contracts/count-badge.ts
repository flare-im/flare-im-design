/**
 * A count badge: a navigation item's count badge, a filter tab's badge and a settings row's badge
 * (spec/count-badge-vectors.json, the same on all four kits). A badge takes a count and `more`, which says there are
 * more than the count — the server had more than the one page it counted — and is false when left out.
 */

/** The badge's text: 99+ when `more` or when the count is above 99, else the count; a missing or negative count is 0. */
export function flareCountBadgeText(count?: number | null, more = false): string {
  const value = typeof count === "number" && Number.isFinite(count) ? Math.trunc(count) : 0;
  return more || value > 99 ? "99+" : String(Math.max(0, value));
}

/** Whether a filter tab or a settings row draws its badge: a count above 0, or `more`. */
export function flareCountBadgeDrawn(count?: number | null, more = false): boolean {
  return more || (typeof count === "number" && Number.isFinite(count) && Math.trunc(count) > 0);
}
