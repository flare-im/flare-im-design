import { describe, expect, it, vi } from 'vitest';
import { locateTimelineMessage } from './locateTimelineMessage';

describe('timeline navigation ownership', () => {
  it('loads history until the target is visible and stops at the bound', async () => {
    let pages = 0;
    const loadOlder = vi.fn(async () => { pages += 1; });
    const options = { isCurrent: () => true, scroll: async () => pages === 2,
      hasOlder: () => true, loadOlder, maxLoads: 4 };
    expect(await locateTimelineMessage(options)).toBe('found');
    expect(loadOlder).toHaveBeenCalledTimes(2);
    loadOlder.mockClear();
    expect(await locateTimelineMessage({ ...options, scroll: async () => false, maxLoads: 3 })).toBe('missing');
    expect(loadOlder).toHaveBeenCalledTimes(3);
  });

  it('does not scroll or load the new conversation after an old page resolves', async () => {
    let current = true;
    let release!: () => void;
    const pending = new Promise<void>(resolve => { release = resolve; });
    const scroll = vi.fn(async () => false);
    const loadOlder = vi.fn(() => pending);
    const result = locateTimelineMessage({ isCurrent: () => current, scroll,
      hasOlder: () => true, loadOlder, maxLoads: 48 });
    await vi.waitFor(() => expect(loadOlder).toHaveBeenCalledTimes(1));
    current = false;
    release();
    expect(await result).toBe('cancelled');
    expect(scroll).toHaveBeenCalledTimes(1);
    expect(loadOlder).toHaveBeenCalledTimes(1);
  });

  it('suppresses obsolete failures and preserves actionable failures', async () => {
    let current = true;
    const options = { isCurrent: () => current, scroll: async () => false,
      hasOlder: () => true, maxLoads: 1,
      loadOlder: async () => { current = false; throw Error('old request'); } };
    expect(await locateTimelineMessage(options)).toBe('cancelled');
    current = true;
    await expect(locateTimelineMessage({ ...options, loadOlder: async () => { throw Error('offline'); } })).rejects.toThrow('offline');
  });
});
