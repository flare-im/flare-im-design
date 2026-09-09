export type CapabilityState = 'loading' | 'available' | 'unavailable' | 'denied' | 'failed';
export interface SceneAction { id: string; label: string; destructive?: boolean; disabled?: boolean }
export interface SceneEntry { id: string; title: string; detail: string; badge?: string; error?: string; busy?: boolean; actions: SceneAction[] }
export interface DeviceSessionEntry extends SceneEntry { current: boolean }
export interface NotificationPreference { id: string; title: string; detail: string; value: boolean; enabled: boolean; busy?: boolean }
export interface MediaEntry extends SceneEntry { kind: 'image'|'video'|'audio'|'file'; availability: 'available'|'expired'|'unavailable' }
export function sceneActions(entry: SceneEntry): SceneAction[] { return entry.actions.filter(a=>!!a.label.trim()); }
export function deviceSessionActions(entry: DeviceSessionEntry): SceneAction[] { return entry.current ? [] : sceneActions(entry); }
