import { describe, it, expect, vi } from 'vitest';
import { effectScope } from 'vue';
import { sameSearchCriteria, validSearchTimeRange } from './search-panel';
import { messageSearchRange } from '../../app/shared/messageSearchRanges';
import { useFlareCoreClient } from '../../composables/useFlareCoreClient';
describe('search time range contract', () => {
  it('compares the whole request and rejects invalid bounds without rejecting zero', () => {
    const base = { query: 'x', filterId: 'file', fromTime: 0, toTime: 100 };
    expect(validSearchTimeRange(base)).toBe(true);
    for (const range of [{ fromTime: -1 }, { toTime: NaN }, { fromTime: 2, toTime: 1 }, { toTime: 1.5 }]) expect(validSearchTimeRange(range)).toBe(false);
    expect(sameSearchCriteria(base, { ...base, toTime: 101 })).toBe(false);
    expect(sameSearchCriteria(base, { ...base })).toBe(true);
  });
  it('keeps local calendar boundaries separate from rolling elapsed days', () => {
    const now = new Date(2026, 8, 9, 12).getTime();
    expect(messageSearchRange('today', now)).toEqual({ fromTime: new Date(2026, 8, 9).getTime(), toTime: now });
    expect(messageSearchRange('week', now)).toEqual({ fromTime: now - 604800000, toTime: now });
    expect(messageSearchRange('any', now)).toEqual({});
  });
  it('passes inclusive bounds to the SDK and rejects reversed ranges before querying', async () => {
    const search = vi.fn(async (_query: unknown) => ({ messages: [] }));
    const scope = effectScope();
    const sdk = scope.run(() => useFlareCoreClient({ createClient: () => ({
      events: { onTypingAggregateChanged: () => ({ unsubscribe() {} }), addEventListener: () => ({ unsubscribe() {} }), subscribeEvents: async () => {} },
      messages: { searchMessagesByQuery: search },
    } as never) }))!;
    await sdk.searchActiveMessages('x', [], { fromTime: 0, toTime: 100 });
    expect(search.mock.calls[0]?.[0]).toMatchObject({ fromTime: 0, toTime: 100 });
    await expect(sdk.searchActiveMessages('x', [], { fromTime: 2, toTime: 1 })).rejects.toThrow();
    expect(search).toHaveBeenCalledTimes(1);
    scope.stop();
  });
});
