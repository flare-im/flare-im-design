import type { RelationState } from "./relation";
import type { FlareGroupJoinPolicy } from "./group-permissions";
// Contacts / Profile / Layout data contracts (Phase C additions).

export interface FlareContact {
  id: string;
  name: string;
  avatarUrl?: string;
  signature?: string;
  presence?: "online" | "offline" | "busy" | "away";
  /** Explicit A-Z index letter; derived from name when absent. */
  indexKey?: string;
  /**
   * The person's public Flare ID (the handle they chose), shown by ContactDetail and ProfileCard only
   * when set. Never pass the internal account id here.
   */
  flareId?: string;
  /** Optional profile detail — surfaced by ContactDetail's info card. */
  remark?: string;
  region?: string;
  phone?: string;
  tags?: string[];
  /**
   * The viewer's relationship with this person (FR-098). A row shows it as a small tag, so a search
   * result says "已申请" or "好友" instead of an app rewriting the signature line to say it.
   */
  relation?: RelationState;
}

export interface FlareFriendRequest {
  id: string;
  name: string;
  avatarUrl?: string;
  message?: string;
  /** "incoming" (default): someone asked the viewer; "outgoing": the viewer asked and waits. */
  direction?: "incoming" | "outgoing";
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

/**
 * - `navigation`: opens a page or a picker (a button with a chevron; `detail` shows the current value).
 * - `toggle`: a switch.
 * - `action`: runs in place, such as clearing history or signing out (a button without a chevron).
 * - `value`: read-only information (not a control; ignores taps).
 */
export type FlareSettingKind = "navigation" | "toggle" | "value" | "action";

export interface FlareSettingsItem {
  disabled?: boolean;
  danger?: boolean;
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
  /** The viewer's own notification and pin settings; `null` when they could not be read, so no state is claimed. */
  myMuted: boolean | null;
  myPinned: boolean | null;
  /** How people join; null when the host does not know. */
  joinPolicy: FlareGroupJoinPolicy | null;
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

/**
 * A host action the kit cannot know about (report, share a profile, an admin tool), shown in the
 * detail surfaces beside the ones the kit owns (FR-046). `danger` draws it as destructive; the kit
 * reports the id back and nothing else.
 */
export interface FlareDetailExtraAction {
  id: string;
  label: string;
  danger?: boolean;
}
