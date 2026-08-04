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
  /** Optional red count badge (e.g. pending friend requests) on a navigation row. */
  badge?: number;
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

/** The full data model for FlareGroupDetail — a group's settings/management page. */
export interface FlareGroupDetailModel {
  groupId: string;
  name: string;
  avatarUrl?: string;
  memberCount: number;
  announcement?: string;
  members: FlareContact[];
  ownerId: string;
  adminIds: string[];
  /** Muted member ids — drives the per-member mute action label. */
  mutedIds: string[];
  /** Viewer owns or administers the group (gates the management sections). */
  canManage: boolean;
  isOwner: boolean;
  /** Viewer's own nickname in this group. */
  myNickname?: string;
  /** Viewer's per-group notification/pin preference. */
  myMuted: boolean;
  myPinned: boolean;
  /** Join policy: 1 = invite-only, 2 = approval, 3 = open. */
  joinPolicy: number;
  muteAll: boolean;
  onlyAdminCanAtAll: boolean;
  onlyAdminCanPin: boolean;
  shareCardPermission: boolean;
}

/** A pending group join request, resolved for display. */
export interface FlareGroupJoinRequestView {
  requestId: string;
  applicantId: string;
  applicantName: string;
  avatarUrl?: string;
  message?: string;
}

/** 联系人的最小画像 —— 名单类组件只需要这些字段。 */
export interface FlareContactBrief {
  userId: string;
  displayName: string;
  avatarUrl?: string;
}

/** 通讯录匹配命中的一条。 */
export interface FlareMatchedContact extends FlareContactBrief {
  /** 命中的手机号或邮箱，条目上回显便于用户确认是谁。 */
  matchedBy: string;
  /** 已是好友时显示「发消息」，否则显示「添加」。 */
  alreadyFriend: boolean;
}
