import { describe, it, expect } from 'vitest';
import { sameSearchCriteria, validSearchTimeRange } from './search-panel';
describe('search time range contract', () => {
  it('compares the whole request and rejects invalid bounds without rejecting zero', () => {
    const base = { query: 'x', filterId: 'file', fromTime: 0, toTime: 100 };
    expect(validSearchTimeRange(base)).toBe(true);
    for (const range of [{ fromTime: -1 }, { toTime: NaN }, { fromTime: 2, toTime: 1 }, { toTime: 1.5 }]) expect(validSearchTimeRange(range)).toBe(false);
    expect(sameSearchCriteria(base, { ...base, toTime: 101 })).toBe(false);
    expect(sameSearchCriteria(base, { ...base })).toBe(true);
  });
});
