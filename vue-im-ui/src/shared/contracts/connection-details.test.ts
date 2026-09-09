import { describe, it, expect } from 'vitest';
import {
  availableConnectionActions, connectionInProgress, connectionStates, connectionTone,
  type ConnectionAction, type ConnectionState,
} from './connection-details';

const all = { hasReconnect: true, hasReauth: true, hasDiagnostics: true, busy: false };
const expected: Record<ConnectionState, ConnectionAction[]> = {
  connected: ['copyDiagnostics'],
  connecting: ['copyDiagnostics'],
  reconnecting: ['reconnect', 'copyDiagnostics'],
  offline: ['reconnect', 'copyDiagnostics'],
  sessionExpired: ['reauth', 'copyDiagnostics'],
  kicked: ['reauth', 'copyDiagnostics'],
  sdkUnready: [],
};

describe('availableConnectionActions', () => {
  it.each(connectionStates)('%s exposes only state-appropriate actions', (state) => {
    expect(availableConnectionActions(state, all)).toEqual(expected[state]);
  });
  it.each(connectionStates)('%s exposes nothing while busy', (state) => {
    expect(availableConnectionActions(state, { ...all, busy: true })).toEqual([]);
  });
  it.each(connectionStates)('%s hides actions the host did not provide', (state) => {
    expect(availableConnectionActions(state, { hasReconnect: false, hasReauth: false, hasDiagnostics: false, busy: false })).toEqual([]);
  });
  it('reconnect never appears while connected or connecting', () => {
    expect(availableConnectionActions('connected', all)).not.toContain('reconnect');
    expect(availableConnectionActions('connecting', all)).not.toContain('reconnect');
  });
  it('reauth never appears for a plain network loss', () => {
    expect(availableConnectionActions('offline', all)).not.toContain('reauth');
    expect(availableConnectionActions('reconnecting', all)).not.toContain('reauth');
  });
});

describe('tone and progress', () => {
  it('maps every state to a tone that is never the only signal', () => {
    expect(connectionTone('connected')).toBe('success');
    expect(connectionTone('connecting')).toBe('warning');
    expect(connectionTone('reconnecting')).toBe('warning');
    expect(connectionTone('offline')).toBe('danger');
    expect(connectionTone('sessionExpired')).toBe('danger');
    expect(connectionTone('kicked')).toBe('danger');
    expect(connectionTone('sdkUnready')).toBe('neutral');
  });
  it('shows progress only while connecting or reconnecting', () => {
    expect(connectionStates.filter(connectionInProgress)).toEqual(['connecting', 'reconnecting']);
  });
});
