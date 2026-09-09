import { describe, it, expect } from 'vitest';
import {
  datesFromRange, dayEndMs, dayStartMs, matchedOptionId, rangeFromDates,
  shouldOpenCustomRange, unrestrictedRange,
} from './search-date-range';
import { validSearchTimeRange, type FlareSearchRangeOption } from './search-panel';

const CST = 480; // UTC+8, minutes east of UTC
const EST = -300; // UTC-5
const iso = (ms: number | null) => (ms === null ? null : new Date(ms).toISOString());

describe('dayStartMs / dayEndMs', () => {
  it('anchors a day to 00:00:00.000 and 23:59:59.999 of the given zone', () => {
    expect(iso(dayStartMs('2026-03-15', 0))).toBe('2026-03-15T00:00:00.000Z');
    expect(iso(dayEndMs('2026-03-15', 0))).toBe('2026-03-15T23:59:59.999Z');
    expect(iso(dayStartMs('2026-03-15', CST))).toBe('2026-03-14T16:00:00.000Z');
    expect(iso(dayEndMs('2026-03-15', CST))).toBe('2026-03-15T15:59:59.999Z');
    expect(iso(dayStartMs('2026-03-15', EST))).toBe('2026-03-15T05:00:00.000Z');
    expect(iso(dayEndMs('2026-03-15', EST))).toBe('2026-03-16T04:59:59.999Z');
  });

  it('spans exactly one inclusive day in a fixed-offset zone', () => {
    for (const tz of [0, CST, EST]) {
      expect(dayEndMs('2026-03-15', tz)! - dayStartMs('2026-03-15', tz)!).toBe(86_399_999);
    }
  });

  it('the same date in different zones is a different instant', () => {
    expect(dayStartMs('2026-03-15', CST)).not.toBe(dayStartMs('2026-03-15', EST));
    expect(dayStartMs('2026-03-15', CST)! + CST * 60_000).toBe(dayStartMs('2026-03-15', 0)! );
  });

  it('handles the epoch, month and year boundaries', () => {
    expect(iso(dayStartMs('1970-01-01', 0))).toBe('1970-01-01T00:00:00.000Z');
    expect(iso(dayEndMs('2026-02-28', 0))).toBe('2026-02-28T23:59:59.999Z');
    expect(iso(dayStartMs('2024-02-29', 0))).toBe('2024-02-29T00:00:00.000Z');
    expect(iso(dayEndMs('2026-12-31', 0))).toBe('2026-12-31T23:59:59.999Z');
  });

  it('rejects anything that is not a real YYYY-MM-DD date', () => {
    for (const bad of ['', '   ', '2026-3-15', '15/03/2026', '2026-13-01', '2026-00-10', '2026-02-30', '2026-04-31', 'today']) {
      expect(dayStartMs(bad, 0), bad).toBeNull();
      expect(dayEndMs(bad, 0), bad).toBeNull();
    }
  });

  it('uses the host zone when no offset is given', () => {
    const start = dayStartMs('2026-03-15')!;
    const end = dayEndMs('2026-03-15')!;
    const local = new Date(start);
    expect(local.getFullYear()).toBe(2026);
    expect(local.getMonth()).toBe(2);
    expect(local.getDate()).toBe(15);
    expect(local.getHours()).toBe(0);
    expect(local.getMinutes()).toBe(0);
    expect(local.getSeconds()).toBe(0);
    expect(local.getMilliseconds()).toBe(0);
    const localEnd = new Date(end);
    expect(localEnd.getDate()).toBe(15);
    expect(localEnd.getHours()).toBe(23);
    expect(localEnd.getMilliseconds()).toBe(999);
    expect(end).toBeGreaterThan(start);
  });
});

describe('rangeFromDates', () => {
  it('same day covers the whole day, both ends inclusive', () => {
    const range = rangeFromDates('2026-03-15', '2026-03-15', CST)!;
    expect(iso(range.fromTime!)).toBe('2026-03-14T16:00:00.000Z');
    expect(iso(range.toTime!)).toBe('2026-03-15T15:59:59.999Z');
    expect(validSearchTimeRange(range)).toBe(true);
  });

  it('spans months and years', () => {
    const month = rangeFromDates('2026-01-28', '2026-02-03', 0)!;
    expect(iso(month.fromTime!)).toBe('2026-01-28T00:00:00.000Z');
    expect(iso(month.toTime!)).toBe('2026-02-03T23:59:59.999Z');
    const year = rangeFromDates('2025-12-30', '2026-01-02', CST)!;
    expect(iso(year.fromTime!)).toBe('2025-12-29T16:00:00.000Z');
    expect(iso(year.toTime!)).toBe('2026-01-02T15:59:59.999Z');
  });

  it('keeps a single open end open', () => {
    expect(rangeFromDates('2026-03-15', '', CST)).toEqual({ fromTime: dayStartMs('2026-03-15', CST)! });
    expect(rangeFromDates('', '2026-03-15', CST)).toEqual({ toTime: dayEndMs('2026-03-15', CST)! });
    expect(rangeFromDates('2026-03-15', '', CST)!.toTime).toBeUndefined();
    expect(rangeFromDates('', '2026-03-15', CST)!.fromTime).toBeUndefined();
  });

  it('both blank is unrestricted, not an error', () => {
    const range = rangeFromDates('', '', CST)!;
    expect(range).toEqual({});
    expect(unrestrictedRange(range)).toBe(true);
    expect(validSearchTimeRange(range)).toBe(true);
  });

  it('refuses from > to, but accepts from == to', () => {
    expect(rangeFromDates('2026-03-16', '2026-03-15', CST)).toBeNull();
    expect(rangeFromDates('2027-01-01', '2026-12-31', 0)).toBeNull();
    expect(rangeFromDates('2026-03-15', '2026-03-15', CST)).not.toBeNull();
  });

  it('refuses unparsable dates and instants before the epoch', () => {
    expect(rangeFromDates('2026-02-30', '2026-03-15', 0)).toBeNull();
    expect(rangeFromDates('2026-03-15', 'tomorrow', 0)).toBeNull();
    expect(rangeFromDates('1969-12-31', '', 0)).toBeNull();
    expect(rangeFromDates('', '1969-12-31', 0)).toBeNull();
  });

  it('produces a range the wire contract already considers valid', () => {
    for (const [from, to] of [['2026-01-01', '2026-12-31'], ['2026-03-15', ''], ['', '2026-03-15'], ['', '']]) {
      expect(validSearchTimeRange(rangeFromDates(from, to, CST)!)).toBe(true);
    }
  });
});

describe('datesFromRange', () => {
  it('round-trips the dates the pickers are bound to', () => {
    for (const tz of [0, CST, EST]) {
      const range = rangeFromDates('2026-03-15', '2026-04-02', tz)!;
      expect(datesFromRange(range, tz)).toEqual({ from: '2026-03-15', to: '2026-04-02' });
    }
    const local = rangeFromDates('2026-03-15', '2026-04-02')!;
    expect(datesFromRange(local)).toEqual({ from: '2026-03-15', to: '2026-04-02' });
  });

  it('leaves an absent or unusable bound blank', () => {
    expect(datesFromRange({}, CST)).toEqual({ from: '', to: '' });
    expect(datesFromRange({ fromTime: dayStartMs('2026-03-15', CST)! }, CST)).toEqual({ from: '2026-03-15', to: '' });
    expect(datesFromRange({ toTime: dayEndMs('2026-03-15', CST)! }, CST)).toEqual({ from: '', to: '2026-03-15' });
    expect(datesFromRange({ fromTime: -1, toTime: 1.5 }, CST)).toEqual({ from: '', to: '' });
  });

  it('reads a preset built in another zone back in the viewer zone', () => {
    const range = rangeFromDates('2026-03-15', '2026-03-15', CST)!;
    expect(datesFromRange(range, EST)).toEqual({ from: '2026-03-14', to: '2026-03-15' });
  });
});

describe('matchedOptionId', () => {
  const options: FlareSearchRangeOption[] = [
    { id: 'today', label: '今天', fromTime: 1_000, toTime: 2_000 },
    { id: 'week', label: '近 7 天', fromTime: 500 },
    { id: 'all', label: '不限时间' },
  ];

  it('matches by value, not by identity or id', () => {
    expect(matchedOptionId({ fromTime: 1_000, toTime: 2_000 }, options)).toBe('today');
    expect(matchedOptionId({ fromTime: 500 }, options)).toBe('week');
    expect(matchedOptionId({}, options)).toBe('all');
  });

  it('returns null when no preset covers the value', () => {
    expect(matchedOptionId({ fromTime: 1_000, toTime: 2_001 }, options)).toBeNull();
    expect(matchedOptionId({ fromTime: 500, toTime: 900 }, options)).toBeNull();
    expect(matchedOptionId({ fromTime: 1_000, toTime: 2_000 }, [])).toBeNull();
  });

  it('does not confuse an open end with a bounded one', () => {
    expect(matchedOptionId({ toTime: 500 }, options)).toBeNull();
  });
});

describe('shouldOpenCustomRange', () => {
  const options: FlareSearchRangeOption[] = [{ id: 'today', label: '今天', fromTime: 1_000, toTime: 2_000 }];

  it('never opens when custom ranges are not allowed', () => {
    expect(shouldOpenCustomRange({ fromTime: 7 }, options, false)).toBe(false);
    expect(shouldOpenCustomRange({ fromTime: 7 }, options, false, true)).toBe(false);
  });

  it('opens when the host forces it', () => {
    expect(shouldOpenCustomRange({}, options, true, true)).toBe(true);
  });

  it('opens for a value no preset covers and stays closed otherwise', () => {
    expect(shouldOpenCustomRange({ fromTime: 7, toTime: 9 }, options, true)).toBe(true);
    expect(shouldOpenCustomRange({ fromTime: 1_000, toTime: 2_000 }, options, true)).toBe(false);
    expect(shouldOpenCustomRange({}, options, true)).toBe(false);
  });
});
