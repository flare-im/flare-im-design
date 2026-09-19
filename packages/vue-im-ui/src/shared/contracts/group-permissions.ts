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
 * `editable` carries permission only (`canManage`), never transient state, so a
 * read-only panel keeps rendering values instead of disabled controls. `busy`
 * and `error` are per key: one failed setting neither hides nor reverts the
 * settings that succeeded, and its reason survives on the row for a retry.
 * An unknown join policy (null) is passed through — the component shows no
 * selected option rather than misreporting the group's real state.
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
