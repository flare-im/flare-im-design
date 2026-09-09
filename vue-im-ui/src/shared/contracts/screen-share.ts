/**
 * ScreenShare contract — pure logic shared by all four platforms.
 * The component never captures a screen, enumerates sources or encodes video:
 * the host / RTC plugin owns all of that and reports `state`. Permission denial
 * is NOT handled here — the host renders PermissionPrompt(kind: 'screen',
 * state: 'denied') instead, so one intent keeps exactly one path.
 */
import type { FlareIconName } from '../icons';

/**
 * idle — nothing is being shared, the local user may start.
 * requesting — a share was requested; waiting for the system / plugin to answer.
 * sharing — the local user is sharing.
 * viewing — someone else is sharing and the local user is watching.
 * unavailable — the runtime or plugin does not support screen sharing at all.
 */
export type ScreenShareState = 'idle' | 'requesting' | 'sharing' | 'viewing' | 'unavailable';
export type ScreenShareAction = 'start' | 'stop' | 'cancel';
export type ScreenShareTone = 'neutral' | 'warning' | 'success' | 'info';

export const screenShareStates: readonly ScreenShareState[] = [
  'idle', 'requesting', 'sharing', 'viewing', 'unavailable',
];

/** Semantic tone per state; every state also carries an icon and text, never colour alone. */
export function screenShareTone(state: ScreenShareState): ScreenShareTone {
  switch (state) {
    case 'idle': return 'neutral';
    case 'requesting': return 'warning';
    case 'sharing': return 'success';
    case 'viewing': return 'info';
    case 'unavailable': return 'neutral';
  }
}

/** Kit icon per state; the same semantic names resolve on iOS / Flutter / Compose. */
export function screenShareIconName(state: ScreenShareState): FlareIconName {
  switch (state) {
    case 'idle': return 'devices';
    case 'requesting': return 'refresh';
    case 'sharing': return 'video';
    case 'viewing': return 'eye';
    case 'unavailable': return 'block';
  }
}

export interface ScreenShareActionOptions {
  /** Host bound a start handler. */
  hasStart: boolean;
  /** Host bound a stop handler. */
  hasStop: boolean;
  /** Host bound a cancel handler. */
  hasCancel: boolean;
  /** Host is executing a command; buttons stay rendered but disabled. */
  busy?: boolean;
}

export interface ScreenShareActions {
  /** Visible only while idle and the host supplied a handler. */
  start: boolean;
  /** Visible only while sharing — a viewer can never stop someone else's share. */
  stop: boolean;
  /** Visible only while requesting. */
  cancel: boolean;
  /** false while busy: visible actions keep their place but cannot be pressed. */
  enabled: boolean;
}

/**
 * Actions the host may currently trigger. `viewing` and `unavailable` never expose one —
 * an unsupported runtime shows the reason instead of a button that would do nothing.
 * Visibility ignores `busy` on purpose so buttons do not disappear mid-command.
 */
export function screenShareActions(
  state: ScreenShareState,
  { hasStart, hasStop, hasCancel, busy }: ScreenShareActionOptions,
): ScreenShareActions {
  return {
    start: state === 'idle' && hasStart,
    stop: state === 'sharing' && hasStop,
    cancel: state === 'requesting' && hasCancel,
    enabled: !busy,
  };
}
