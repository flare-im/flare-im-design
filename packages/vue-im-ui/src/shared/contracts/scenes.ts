export type CapabilityState = 'loading' | 'available' | 'unavailable' | 'denied' | 'failed';
export interface SceneAction { id: string; label: string; destructive?: boolean; disabled?: boolean }
export interface SceneEntry { id: string; title: string; detail: string; badge?: string; error?: string; busy?: boolean; actions: SceneAction[] }
export interface DeviceSessionEntry extends SceneEntry { current: boolean }
export interface NotificationPreference { id: string; title: string; detail: string; value: boolean; enabled: boolean; busy?: boolean }
export interface MediaEntry extends SceneEntry { kind: 'image'|'video'|'audio'|'file'; availability: 'available'|'expired'|'unavailable' }
export function sceneActions(entry: SceneEntry): SceneAction[] { return entry.actions.filter(a=>!!a.label.trim()); }
export function deviceSessionActions(entry: DeviceSessionEntry): SceneAction[] { return entry.current ? [] : sceneActions(entry); }

/**
 * A reason the person writes before a recorded change — the audit reason a console sends with a
 * high-risk write. `maxBytes` is measured in UTF-8, the unit a server's limit is usually in, and
 * holds the confirm key until the text fits; `maxLength` stops typing at that many characters.
 */
export interface FlareConfirmReason {
  /** Field label, e.g. "Audit reason". */
  label: string;
  placeholder?: string;
  /** A line under the field: who reads the reason, where it is kept. */
  hint?: string;
  /** Characters the field takes. */
  maxLength?: number;
  /** UTF-8 bytes the trimmed reason may take; more marks the field and holds the confirm key. */
  maxBytes?: number;
  /** The reason may be left empty. Default false: the confirm key waits for one. */
  optional?: boolean;
}

/** What the person entered in a confirmation; handed to `confirm` and to the presenter's `action`. */
export interface FlareConfirmInput {
  /** The trimmed reason; empty when none was asked for. */
  reason: string;
}

/** UTF-8 length of a reason, the way a server limit counts it. */
export function confirmReasonBytes(text: string): number {
  return new TextEncoder().encode(text).length;
}
