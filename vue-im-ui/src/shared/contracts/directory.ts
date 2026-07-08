// Contacts / Profile / Layout data contracts (Phase C additions).

export interface FlareContact {
  id: string;
  name: string;
  avatarUrl?: string;
  signature?: string;
  presence?: "online" | "offline" | "busy" | "away";
  /** Explicit A-Z index letter; derived from name when absent. */
  indexKey?: string;
}

export interface FlareFriendRequest {
  id: string;
  name: string;
  avatarUrl?: string;
  message?: string;
}

export interface FlareGroupSummary {
  id: string;
  name: string;
  avatarUrl?: string;
  memberCount?: number;
}

export interface FlareUserProfile {
  id: string;
  name: string;
  avatarUrl?: string;
  signature?: string;
  flareId?: string;
}

export type FlareSettingKind = "navigation" | "toggle" | "value";

export interface FlareSettingsItem {
  key: string;
  label: string;
  icon?: string;
  kind?: FlareSettingKind;
  value?: boolean;
  detail?: string;
}

export interface FlareSettingsSection {
  title?: string;
  items: FlareSettingsItem[];
}

export interface FlareNavItem {
  key: string;
  label: string;
  icon?: string;
  badge?: number;
}
