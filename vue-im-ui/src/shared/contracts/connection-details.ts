/** Connection / session state supplied by the host; the UI never opens or closes a connection. */
export type ConnectionState =
  | 'connected'
  | 'connecting'
  | 'reconnecting'
  | 'offline'
  | 'sessionExpired'
  | 'kicked'
  | 'sdkUnready';
export type ConnectionAction = 'reconnect' | 'reauth' | 'copyDiagnostics';
export type ConnectionTone = 'success' | 'warning' | 'danger' | 'neutral';

export const connectionStates: readonly ConnectionState[] = [
  'connected', 'connecting', 'reconnecting', 'offline', 'sessionExpired', 'kicked', 'sdkUnready',
];

/** Semantic tone per state; every state also carries an icon and text, never colour alone. */
export function connectionTone(state: ConnectionState): ConnectionTone {
  switch (state) {
    case 'connected': return 'success';
    case 'connecting':
    case 'reconnecting': return 'warning';
    case 'offline':
    case 'sessionExpired':
    case 'kicked': return 'danger';
    case 'sdkUnready': return 'neutral';
  }
}

/** States that show an indeterminate progress indicator. */
export function connectionInProgress(state: ConnectionState): boolean {
  return state === 'connecting' || state === 'reconnecting';
}

export interface ConnectionCapabilities {
  hasReconnect: boolean;
  hasReauth: boolean;
  hasDiagnostics: boolean;
  busy: boolean;
}

/**
 * Actions the host may currently trigger. `reconnect` only while offline/reconnecting,
 * `reauth` only after sessionExpired/kicked, `copyDiagnostics` only with non-blank diagnostics.
 * `sdkUnready` never exposes an action; `busy` disables everything.
 */
export function availableConnectionActions(
  state: ConnectionState,
  { hasReconnect, hasReauth, hasDiagnostics, busy }: ConnectionCapabilities,
): ConnectionAction[] {
  if (busy || state === 'sdkUnready') return [];
  const actions: ConnectionAction[] = [];
  if (hasReconnect && (state === 'offline' || state === 'reconnecting')) actions.push('reconnect');
  if (hasReauth && (state === 'sessionExpired' || state === 'kicked')) actions.push('reauth');
  if (hasDiagnostics) actions.push('copyDiagnostics');
  return actions;
}
