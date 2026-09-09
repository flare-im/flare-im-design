import { describe, it, expect } from 'vitest';
import { reauthActions, reauthIcon, reauthReasons, reauthTone } from './reauth-prompt';

describe('reauthActions', () => {
  for (const reason of reauthReasons) {
    for (const busy of [false, true]) {
      it(`${reason} busy=${busy}: visibility follows handlers, enabled follows busy`, () => {
        const both = reauthActions(reason, { hasReauth: true, hasLogout: true, busy });
        const reauthAllowed = reason !== 'accountDisabled';
        expect(both.reauthenticate.visible).toBe(reauthAllowed);
        expect(both.reauthenticate.enabled).toBe(reauthAllowed && !busy);
        expect(both.logout.visible).toBe(true);
        expect(both.logout.enabled).toBe(!busy);
        expect(both.primary).toBe(reauthAllowed ? 'reauthenticate' : null);

        const none = reauthActions(reason, { hasReauth: false, hasLogout: false, busy });
        expect(none.reauthenticate).toEqual({ visible: false, enabled: false });
        expect(none.logout).toEqual({ visible: false, enabled: false });
        expect(none.primary).toBeNull();
      });
    }
  }
  it('defaults busy to false', () => {
    expect(reauthActions('sessionExpired', { hasReauth: true, hasLogout: false }).reauthenticate.enabled).toBe(true);
  });
  it('maps every reason to a tone and an icon', () => {
    expect(reauthReasons.map(reauthTone)).toEqual(['info', 'warning', 'warning', 'danger']);
    expect(reauthReasons.map(reauthIcon)).toEqual(['clock', 'devices', 'lock', 'block']);
  });
});
