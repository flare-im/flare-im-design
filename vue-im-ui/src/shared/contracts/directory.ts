// Contacts / Profile / Layout data contracts (Phase C additions).

export interface FlareContact {
  id: string;
  name: string;
  avatarUrl?: string;
  signature?: string;
  presence?: "online" | "offline" | "busy" | "away";
  /** Explicit A-Z index letter; derived from name when absent. */
  indexKey?: string;
  /** Optional profile detail — surfaced by ContactDetail's info card. */
  remark?: string;
  region?: string;
  phone?: string;
  tags?: string[];
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

/** A candidate person (or "@all") in the mention picker. */
export interface FlareMentionCandidate {
  id: string;
  name: string;
  avatarUrl?: string;
  /** Secondary line — role, department, or handle. */
  detail?: string;
  /** Marks the synthetic "@everyone" row so it can be styled / pinned. */
  isEveryone?: boolean;
}
