/** Why the current session can no longer be used. Supplied by the host session layer. */
export type ReauthReason = 'sessionExpired' | 'kicked' | 'credentialInvalid' | 'accountDisabled';
export const reauthReasons: readonly ReauthReason[] = ['sessionExpired', 'kicked', 'credentialInvalid', 'accountDisabled'];

/** Semantic tone used for the reason glyph / status colour (never the only signal: the text always names the reason). */
export type ReauthTone = 'info' | 'warning' | 'danger';
export function reauthTone(reason: ReauthReason): ReauthTone {
  switch (reason) {
    case 'sessionExpired': return 'info';
    case 'kicked': return 'warning';
    case 'credentialInvalid': return 'warning';
    case 'accountDisabled': return 'danger';
  }
}

/** Semantic icon name (shared icon library) for each reason. */
export function reauthIcon(reason: ReauthReason): 'clock' | 'devices' | 'lock' | 'block' {
  switch (reason) {
    case 'sessionExpired': return 'clock';
    case 'kicked': return 'devices';
    case 'credentialInvalid': return 'lock';
    case 'accountDisabled': return 'block';
  }
}

export interface ReauthActionState { visible: boolean; enabled: boolean }
export interface ReauthActions {
  reauthenticate: ReauthActionState;
  logout: ReauthActionState;
  /** The action Enter triggers; null when re-authentication is unavailable (e.g. accountDisabled). */
  primary: 'reauthenticate' | null;
}
export interface ReauthActionInput { hasReauth: boolean; hasLogout: boolean; busy?: boolean }

/**
 * Which actions to show and whether they are enabled.
 * - reauthenticate needs a host handler and is never offered for a disabled account.
 * - logout needs a host handler.
 * - busy locks every action; the host sets it synchronously before dispatching.
 */
export function reauthActions(reason: ReauthReason, { hasReauth, hasLogout, busy = false }: ReauthActionInput): ReauthActions {
  const reauthVisible = hasReauth && reason !== 'accountDisabled';
  return {
    reauthenticate: { visible: reauthVisible, enabled: reauthVisible && !busy },
    logout: { visible: hasLogout, enabled: hasLogout && !busy },
    primary: reauthVisible ? 'reauthenticate' : null,
  };
}
