import { describe, it, expect } from 'vitest';
import {
  screenShareActions, screenShareIconName, screenShareStates, screenShareTone,
  type ScreenShareAction, type ScreenShareState,
} from './screen-share';

const all = { hasStart: true, hasStop: true, hasCancel: true, busy: false };
const none = { hasStart: false, hasStop: false, hasCancel: false, busy: false };
const visible: Record<ScreenShareState, ScreenShareAction[]> = {
  idle: ['start'],
  requesting: ['cancel'],
  sharing: ['stop'],
  viewing: [],
  unavailable: [],
};
const shown = (state: ScreenShareState, opts = all): ScreenShareAction[] => {
  const a = screenShareActions(state, opts);
  return (['start', 'stop', 'cancel'] as const).filter((k) => a[k]);
};

describe('screenShareActions', () => {
  it.each(screenShareStates)('%s exposes only state-appropriate actions', (state) => {
    expect(shown(state)).toEqual(visible[state]);
  });
  it.each(screenShareStates)('%s keeps its buttons but disables them while busy', (state) => {
    const busy = screenShareActions(state, { ...all, busy: true });
    expect(shown(state, { ...all, busy: true })).toEqual(visible[state]);
    expect(busy.enabled).toBe(false);
    expect(screenShareActions(state, all).enabled).toBe(true);
  });
  it.each(screenShareStates)('%s hides actions the host did not provide', (state) => {
    expect(shown(state, none)).toEqual([]);
    expect(screenShareActions(state, none).enabled).toBe(true);
  });
  it('treats an omitted busy flag as not busy', () => {
    expect(screenShareActions('idle', { hasStart: true, hasStop: true, hasCancel: true }).enabled).toBe(true);
  });
  it('never offers stop to a viewer, nor start while already sharing', () => {
    expect(screenShareActions('viewing', all).stop).toBe(false);
    expect(screenShareActions('viewing', all).start).toBe(false);
    expect(screenShareActions('sharing', all).start).toBe(false);
    expect(screenShareActions('requesting', all).start).toBe(false);
  });
  it('offers nothing at all when the runtime cannot share', () => {
    const a = screenShareActions('unavailable', all);
    expect([a.start, a.stop, a.cancel]).toEqual([false, false, false]);
  });
  it('exposes cancel only while the request is pending', () => {
    for (const state of screenShareStates) {
      expect(screenShareActions(state, all).cancel).toBe(state === 'requesting');
    }
  });
});

describe('tone and icon', () => {
  it('maps every state to a tone that is never the only signal', () => {
    expect(screenShareTone('idle')).toBe('neutral');
    expect(screenShareTone('requesting')).toBe('warning');
    expect(screenShareTone('sharing')).toBe('success');
    expect(screenShareTone('viewing')).toBe('info');
    expect(screenShareTone('unavailable')).toBe('neutral');
  });
  it('gives every state a kit icon alongside its tone', () => {
    expect(screenShareStates.map(screenShareIconName)).toEqual([
      'devices', 'refresh', 'video', 'eye', 'block',
    ]);
  });
  it('distinguishes the two neutral states by icon', () => {
    expect(screenShareIconName('idle')).not.toBe(screenShareIconName('unavailable'));
  });
});
