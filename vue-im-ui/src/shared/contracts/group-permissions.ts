/**
 * Group management contracts — pure logic shared by the four platforms and by
 * two components:
 *
 *  - GroupPermissionMatrix → `groupPermissionRows()`
 *  - MemberRoleSheet       → `memberRoleActions()`
 *
 * Permission keys mirror the real fields of `FlareGroupDetailModel`
 * (shared/contracts/directory.ts) — nothing here is invented on top of the
 * backend model. Both functions are pure: no defaults are fabricated, no input
 * is mutated, and neither performs any side effect.
 */

// ─────────────────────────── GroupPermissionMatrix ───────────────────────────

/** Join policy values as the backend defines them on `FlareGroupDetailModel.joinPolicy`. */
export const GROUP_JOIN_INVITE = 1;
export const GROUP_JOIN_APPROVAL = 2;
export const GROUP_JOIN_OPEN = 3;

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
  /** 1 = invite only, 2 = approval required, 3 = open. */
  joinPolicy: number;
}

/** `toggle` renders a switch (boolean value); `choice` renders a radio group (numeric value). */
export type GroupPermissionRowKind = "toggle" | "choice";

/** One rendered row. `value` is boolean for `toggle` rows and numeric for `choice` rows. */
export interface GroupPermissionRow {
  key: GroupPermissionKey;
  kind: GroupPermissionRowKind;
  value: boolean | number;
  /** Viewer may change this row; `false` renders a read-only value, never a dead switch. */
  editable: boolean;
  /** This row's command is in flight — the row alone locks, its siblings stay usable. */
  busy: boolean;
  /** Why this row's last command failed; kept until the host dismisses it. */
  error: string | null;
}

/** True when `value` is one of the three defined join policies. */
export function isGroupJoinPolicy(value: number): boolean {
  return value === GROUP_JOIN_INVITE || value === GROUP_JOIN_APPROVAL || value === GROUP_JOIN_OPEN;
}

/**
 * The rows to render, in canonical order.
 *
 * `editable` carries permission only (`canManage`), never transient state, so a
 * read-only panel keeps rendering values instead of disabled controls. `busy`
 * and `error` are per key: one failed setting neither hides nor reverts the
 * settings that succeeded, and its reason survives on the row for a retry.
 * An unknown `joinPolicy` number is passed through untouched — the component
 * shows no selected option rather than misreporting the group's real state.
 */
export function groupPermissionRows(
  settings: GroupPermissionSettings,
  canManage: boolean,
  busyKeys?: readonly string[] | null,
  errors?: Readonly<Record<string, string>> | null,
): GroupPermissionRow[] {
  const busy = new Set(busyKeys ?? []);
  return groupPermissionKeys.map((key) => ({
    key,
    kind: key === "joinPolicy" ? ("choice" as const) : ("toggle" as const),
    value: key === "joinPolicy" ? settings.joinPolicy : settings[key],
    editable: canManage === true,
    busy: busy.has(key),
    error: errors?.[key] ?? null,
  }));
}

/** Payload of the matrix `change` event. */
export interface GroupPermissionChangePayload {
  key: GroupPermissionKey;
  value: boolean | number;
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

/** Host-declared capabilities. Absent/false hides the action entirely. */
export interface MemberRoleCapabilities {
  promote?: boolean;
  demote?: boolean;
  mute?: boolean;
  unmute?: boolean;
  remove?: boolean;
  transferOwner?: boolean;
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
 * Ordered management actions for `member` as seen by `viewerRole`, filtered by
 * what the host says it can honour. Rank rules come first and capabilities only
 * narrow further:
 *
 *  - the owner is untouchable — no promote / demote / mute / remove / transfer;
 *  - a plain member sees nothing (the sheet then says it has no rights);
 *  - an admin cannot act on a peer admin and can never transfer ownership;
 *  - only the owner can transfer ownership;
 *  - promote only applies to a member, demote only to an admin;
 *  - mute / unmute are mutually exclusive by `member.muted`.
 *
 * `mute` still needs the host to supply duration options — a sheet with none
 * hides the row, since the kit never invents durations.
 */
export function memberRoleActions(
  member: GroupMemberSnapshot,
  viewerRole: GroupMemberRole,
  capabilities: MemberRoleCapabilities | null | undefined,
): MemberRoleActionEntry[] {
  if (member.role === "owner") return [];
  if (viewerRole === "member") return [];
  if (viewerRole === "admin" && member.role === "admin") return [];
  const caps = capabilities ?? {};
  const out: MemberRoleActionEntry[] = [];
  if (caps.promote && member.role === "member") out.push({ action: "promote", danger: false });
  if (caps.demote && member.role === "admin") out.push({ action: "demote", danger: false });
  if (caps.mute && !member.muted) out.push({ action: "mute", danger: false });
  if (caps.unmute && member.muted) out.push({ action: "unmute", danger: false });
  if (caps.transferOwner && viewerRole === "owner") out.push({ action: "transferOwner", danger: true });
  if (caps.remove) out.push({ action: "remove", danger: true });
  return out;
}
