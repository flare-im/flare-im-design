import { describe, it, expect } from 'vitest';
import {
  permissionActions, defaultPermissionCopy, defaultPermissionStateLabel, permissionIcon, permissionStateIcon,
  permissionKinds, permissionStates,
} from './permission-prompt';

const all = { hasRequest: true, hasOpenSettings: true, hasDismiss: true };

describe('permissionActions', () => {
  it('shows request only while undetermined and openSettings only while denied, for every kind', () => {
    for (const kind of permissionKinds) {
      for (const state of permissionStates) {
        const a = permissionActions(state, all);
        expect({ kind, state, request: a.request, openSettings: a.openSettings, dismiss: a.dismiss, enabled: a.enabled }).toEqual({
          kind, state,
          request: state === 'undetermined',
          openSettings: state === 'denied',
          dismiss: true,
          enabled: true,
        });
      }
    }
  });
  it('hides actions the host did not supply', () => {
    expect(permissionActions('undetermined', { hasRequest: false, hasOpenSettings: true, hasDismiss: false })).toEqual({ request: false, openSettings: false, dismiss: false, enabled: true });
    expect(permissionActions('denied', { hasRequest: true, hasOpenSettings: false, hasDismiss: false })).toEqual({ request: false, openSettings: false, dismiss: false, enabled: true });
  });
  it('restricted and unavailable never offer request/openSettings even with handlers', () => {
    for (const state of ['restricted', 'unavailable'] as const) {
      const a = permissionActions(state, all);
      expect(a.request).toBe(false); expect(a.openSettings).toBe(false); expect(a.dismiss).toBe(true);
    }
  });
  it('busy keeps actions visible but disabled', () => {
    expect(permissionActions('undetermined', { ...all, busy: true })).toEqual({ request: true, openSettings: false, dismiss: true, enabled: false });
  });
});

describe('defaultPermissionCopy', () => {
  it('has a title and description for all 7 kinds x 4 states, primary label only where an action exists', () => {
    for (const kind of permissionKinds) {
      for (const state of permissionStates) {
        const c = defaultPermissionCopy(kind, state);
        expect(c.title.length).toBeGreaterThan(0);
        expect(c.description.length).toBeGreaterThan(0);
        expect(c.primaryLabel.length > 0).toBe(state === 'undetermined' || state === 'denied');
        expect(defaultPermissionStateLabel(state).length).toBeGreaterThan(0);
        expect(permissionIcon[kind]).toBeTruthy();
        expect(permissionStateIcon[state]).toBeTruthy();
      }
    }
  });
  it('embeds the feature label and falls back to a generic subject', () => {
    expect(defaultPermissionCopy('microphone', 'undetermined', '发送语音消息').description).toContain('发送语音消息');
    expect(defaultPermissionCopy('microphone', 'denied', '  ').description).toContain('此功能');
    expect(defaultPermissionCopy('notifications', 'denied').primaryLabel).toBe('前往设置');
    expect(defaultPermissionCopy('camera', 'undetermined').primaryLabel).toBe('允许');
  });
});
