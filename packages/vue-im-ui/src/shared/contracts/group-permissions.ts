/**
 * Group management contracts — pure logic shared by the four platforms and by
 * three components:
 *
 *  - GroupDetail           → `groupManagementEntries()`, `groupDetailMemberActions()`
 *  - GroupPermissionMatrix → `groupPermissionRows()`
 *  - MemberRoleSheet       → `memberRoleActions()`
 *
 * Who may do what is not decided here. The host passes what its permission source
 * answered — the viewer's `FlareGroupCapabilities` and, per member, the
 * `FlareMemberActions` — and the kit only maps each answer to the entry it
 * names. No role, owner or permission-bit rule lives in the kit: a host that says
 * nothing gets no management entry. The shared cases are in
 * `spec/group-management-vectors.json`; all four platforms run them.
 *
 * Permission keys mirror the real fields of `FlareGroupDetailModel`
 * (shared/contracts/directory.ts) — nothing here is invented on top of the
 * backend model. Every function is pure: no defaults are fabricated, no input
 * is mutated, and none performs any side effect.
 */

// ─────────────────────────────── Capabilities ───────────────────────────────

/**
 * What the viewer may manage in the group, as the host's permission source answers it
 * (the social SDK's `memberCapabilities` carries these fields under the same names).
 * Absent or false hides the entries the field names.
 */
export interface FlareGroupCapabilities {
  /** Group name, announcement, mute-all and the three group permission switches. */
  canManageInfo?: boolean;
  /** Join policy and whether the group can be found by search. */
  canManageJoinSettings?: boolean;
  /** List and answer join requests. */
  canManageJoinRequests?: boolean;
  /** Invite friends into the group and read its invite link. */
  canInvite?: boolean;
  /** Dissolve the group; without it the viewer's way out is leaving. */
  canDissolve?: boolean;
}

/** No management at all: what a host passes when it could not read the viewer's capabilities. */
export const noGroupCapabilities: Readonly<FlareGroupCapabilities> = Object.freeze({});

/**
 * What the viewer may do to one member, as the host's permission source answers it
 * (the social SDK's `memberActions`, one entry per member, carries these fields).
 * Absent or false hides the action.
 */
export interface FlareMemberActions {
  /** Remove the member from the group. */
  canRemove?: boolean;
  /** Mute or unmute the member; the label follows the member's muted state. */
  canMute?: boolean;
  /** Make the member an admin or revoke it; the label follows the member's role. */
  canChangeRole?: boolean;
  /** Hand ownership over to the member. */
  canTransferOwner?: boolean;
}

/** The management entries of a group page, in display order; identical on all four platforms. */
export type GroupManagementEntry =
  | "editName"
  | "editAnnouncement"
  | "discoverable"
  | "joinPolicy"
  | "joinRequests"
  | "muteAll"
  | "inviteLink"
  | "onlyAdminCanAtAll"
  | "onlyAdminCanPin"
  | "shareCardPermission"
  | "inviteMembers"
  | "dissolve";

/** Which capability each entry reads; one field per entry, nothing combined. */
const entryCapability: Readonly<Record<GroupManagementEntry, keyof FlareGroupCapabilities>> = {
  editName: "canManageInfo",
  editAnnouncement: "canManageInfo",
  discoverable: "canManageJoinSettings",
  joinPolicy: "canManageJoinSettings",
  joinRequests: "canManageJoinRequests",
  muteAll: "canManageInfo",
  inviteLink: "canInvite",
  onlyAdminCanAtAll: "canManageInfo",
  onlyAdminCanPin: "canManageInfo",
  shareCardPermission: "canManageInfo",
  inviteMembers: "canInvite",
  dissolve: "canDissolve",
};

export const groupManagementEntryOrder: readonly GroupManagementEntry[] = [
  "editName",
  "editAnnouncement",
  "discoverable",
  "joinPolicy",
  "joinRequests",
  "muteAll",
  "inviteLink",
  "onlyAdminCanAtAll",
  "onlyAdminCanPin",
  "shareCardPermission",
  "inviteMembers",
  "dissolve",
];

/**
 * The management entries the viewer gets, in display order. Only an explicit `true`
 * counts. Without `dissolve` the page offers leaving instead.
 */
export function groupManagementEntries(
  capabilities: FlareGroupCapabilities | null | undefined,
): GroupManagementEntry[] {
  const caps = capabilities ?? {};
  return groupManagementEntryOrder.filter((entry) => caps[entryCapability[entry]] === true);
}

// ─────────────────────────── GroupPermissionMatrix ───────────────────────────

/**
 * How people join a group: anyone, after approval, or by invitation only. Hosts map
 * their SDK's codes to these values in their own mapper; the kit knows no codes.
 */
export type FlareGroupJoinPolicy = "open" | "approval" | "invite";

/** Display order of the join policies; identical on all four platforms. */
export const groupJoinPolicies: readonly FlareGroupJoinPolicy[] = ["open", "approval", "invite"];

/** The five settings the matrix can edit — one key per real backend field. */
export type GroupPermissionKey =
  | "joinPolicy"
  | "muteAll"
  | "onlyAdminCanAtAll"
  | "onlyAdminCanPin"
  | "shareCardPermission";

/** Display order; identical on all four platforms. */
export const groupPermissionKeys: readonly GroupPermissionKey[] = [
  "joinPolicy",
  "muteAll",
  "onlyAdminCanAtAll",
  "onlyAdminCanPin",
  "shareCardPermission",
];

/** The subset of `FlareGroupDetailModel` this panel edits. */
export interface GroupPermissionSettings {
  muteAll: boolean;
  onlyAdminCanAtAll: boolean;
  onlyAdminCanPin: boolean;
  shareCardPermission: boolean;
  /** Null when the host does not know the group's policy: no choice is shown as selected. */
  joinPolicy: FlareGroupJoinPolicy | null;
}

/** `toggle` renders a switch (boolean value); `choice` renders a radio group (a join policy, or null when unknown). */
export type GroupPermissionRowKind = "toggle" | "choice";

/** One rendered row. `value` is boolean for `toggle` rows and the join policy for the `choice` row. */
export interface GroupPermissionRow {
  key: GroupPermissionKey;
  kind: GroupPermissionRowKind;
  value: boolean | FlareGroupJoinPolicy | null;
  /** Viewer may change this row; `false` renders a read-only value, never a dead switch. */
  editable: boolean;
  /** This row's command is in flight — the row alone locks, its siblings stay usable. */
  busy: boolean;
  /** Why this row's last command failed; kept until the host dismisses it. */
  error: string | null;
}

/**
 * The rows to render, in canonical order.
 *
 * `editable` carries permission only, never transient state, so a read-only row
 * keeps rendering its value instead of a disabled control. Each row is editable
 * exactly when `groupManagementEntries(capabilities)` offers its key: the join
 * policy follows `canManageJoinSettings`, the four switches `canManageInfo`.
 * `busy` and `error` are per key: one failed setting neither hides nor reverts
 * the settings that succeeded, and its reason survives on the row for a retry.
 * An unknown join policy (null) is passed through — the component shows no
 * selected option rather than misreporting the group's real state.
 */
export function groupPermissionRows(
  settings: GroupPermissionSettings,
  capabilities: FlareGroupCapabilities | null | undefined,
  busyKeys?: readonly string[] | null,
  errors?: Readonly<Record<string, string>> | null,
): GroupPermissionRow[] {
  const busy = new Set(busyKeys ?? []);
  const entries = new Set<string>(groupManagementEntries(capabilities));
  return groupPermissionKeys.map((key) => ({
    key,
    kind: key === "joinPolicy" ? ("choice" as const) : ("toggle" as const),
    value: key === "joinPolicy" ? settings.joinPolicy : settings[key],
    editable: entries.has(key),
    busy: busy.has(key),
    error: errors?.[key] ?? null,
  }));
}

/** Payload of the matrix `change` event. */
export interface GroupPermissionChangePayload {
  key: GroupPermissionKey;
  value: boolean | FlareGroupJoinPolicy;
}

// ───────────────────────────── MemberRoleSheet ──────────────────────────────

/** A member's role in the group. */
export type GroupMemberRole = "owner" | "admin" | "member";

/** Management actions the sheet can emit. */
export type MemberRoleActionId =
  | "promote"
  | "demote"
  | "mute"
  | "unmute"
  | "remove"
  | "transferOwner";

/** Canonical display order; `transferOwner` and `remove` form the trailing danger group. */
export const memberRoleActionOrder: readonly MemberRoleActionId[] = [
  "promote",
  "demote",
  "mute",
  "unmute",
  "transferOwner",
  "remove",
];

/** The member the sheet acts on; `id` must be stable and is echoed in the payload. */
export interface GroupMemberSnapshot {
  id: string;
  name: string;
  avatarUrl?: string;
  role: GroupMemberRole;
  muted: boolean;
}

/** One host-supplied mute duration option; the kit ships no durations of its own. */
export interface MemberMuteDuration {
  id: string;
  label: string;
}

/** One displayable action; `danger` entries render in the trailing danger group. */
export interface MemberRoleActionEntry {
  action: MemberRoleActionId;
  danger: boolean;
}

/** Payload of the sheet's `action` event; `durationId` is set for `mute` only. */
export interface MemberRoleActionPayload {
  memberId: string;
  action: MemberRoleActionId;
  durationId?: string;
}

/**
 * Ordered management actions for `member`, from what the host says the viewer may do
 * to that member (`actions`). The kit decides nothing about who may act on whom — the
 * owner's protection, admins not managing each other, the owner-only actions all come
 * from the host's answer. It only picks the label each answer needs:
 *
 *  - `canChangeRole` offers promote for a member and demote for an admin;
 *  - `canMute` offers mute or unmute by `member.muted`;
 *  - `canTransferOwner` and `canRemove` form the trailing danger group.
 *
 * `mute` still needs the host to supply duration options in MemberRoleSheet — a sheet
 * with none hides the row, since the kit never invents durations.
 */
export function memberRoleActions(
  member: Pick<GroupMemberSnapshot, "role" | "muted">,
  actions: FlareMemberActions | null | undefined,
): MemberRoleActionEntry[] {
  const can = actions ?? {};
  const out: MemberRoleActionEntry[] = [];
  if (can.canChangeRole === true && member.role === "member") out.push({ action: "promote", danger: false });
  if (can.canChangeRole === true && member.role === "admin") out.push({ action: "demote", danger: false });
  if (can.canMute === true && !member.muted) out.push({ action: "mute", danger: false });
  if (can.canMute === true && member.muted) out.push({ action: "unmute", danger: false });
  if (can.canTransferOwner === true) out.push({ action: "transferOwner", danger: true });
  if (can.canRemove === true) out.push({ action: "remove", danger: true });
  return out;
}

/** The part of `FlareGroupDetailModel` the member sheet reads. */
export interface GroupDetailMemberState {
  ownerId: string;
  adminIds: readonly string[];
  mutedIds: readonly string[];
  memberActions?: Readonly<Record<string, FlareMemberActions>> | null;
}

/** A member's role on the group page: the owner by `ownerId`, an admin by `adminIds`, otherwise a member. */
export function groupDetailMemberRole(model: GroupDetailMemberState, memberId: string): GroupMemberRole {
  if (memberId === model.ownerId) return "owner";
  return model.adminIds.includes(memberId) ? "admin" : "member";
}

/**
 * The actions GroupDetail's member sheet offers for `memberId`: `memberRoleActions` over the
 * member's state on the page and the host's `memberActions` entry for that id. A member the host
 * gave no entry gets nothing, and the sheet does not open for an empty list.
 */
export function groupDetailMemberActions(model: GroupDetailMemberState, memberId: string): MemberRoleActionEntry[] {
  const actions = model.memberActions?.[memberId] ?? null;
  return memberRoleActions(
    { role: groupDetailMemberRole(model, memberId), muted: model.mutedIds.includes(memberId) },
    actions,
  );
}
