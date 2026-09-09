import type { FlareSearchResultGroup } from './search';
/** Inclusive UTC epoch milliseconds; absent bounds mean unrestricted. */
export interface FlareSearchTimeRange { fromTime?: number; toTime?: number }
export interface FlareSearchRangeOption extends FlareSearchTimeRange { id: string; label: string }
export interface FlareSearchCriteria extends FlareSearchTimeRange { query: string; filterId: string }
export function validSearchTimeRange(range: FlareSearchTimeRange): boolean {
  const valid = (value: number | undefined) => value === undefined || (Number.isSafeInteger(value) && value >= 0);
  return valid(range.fromTime) && valid(range.toTime)
    && (range.fromTime === undefined || range.toTime === undefined || range.fromTime <= range.toTime);
}
export function sameSearchTimeRange(a: FlareSearchTimeRange, b: FlareSearchTimeRange): boolean {
  return a.fromTime === b.fromTime && a.toTime === b.toTime;
}
export interface FlareSearchSnapshot {
  criteria: FlareSearchCriteria;
  state: 'idle' | 'loading' | 'success' | 'failure';
  groups: FlareSearchResultGroup[];
  error?: string;
}
export function sameSearchCriteria(a: FlareSearchCriteria, b: FlareSearchCriteria): boolean {
  return a.query === b.query && a.filterId === b.filterId && sameSearchTimeRange(a, b);
}
