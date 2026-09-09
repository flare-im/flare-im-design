import { describe, it, expect } from "vitest";
import {
  GROUP_JOIN_APPROVAL,
  GROUP_JOIN_INVITE,
  GROUP_JOIN_OPEN,
  groupPermissionRows,
  isGroupJoinPolicy,
  memberRoleActions,
  type GroupMemberRole,
  type GroupMemberSnapshot,
  type GroupPermissionSettings,
  type MemberRoleCapabilities,
} from "./group-permissions";

const settings: GroupPermissionSettings = {
  muteAll: false,
  onlyAdminCanAtAll: true,
  onlyAdminCanPin: false,
  shareCardPermission: true,
  joinPolicy: GROUP_JOIN_APPROVAL,
};

describe("groupPermissionRows", () => {
  it("returns the five real backend keys in canonical order", () => {
    expect(groupPermissionRows(settings, true).map((r) => r.key)).toEqual([
      "joinPolicy",
      "muteAll",
      "onlyAdminCanAtAll",
      "onlyAdminCanPin",
      "shareCardPermission",
    ]);
  });

  it("marks joinPolicy as the only choice row and carries each value through", () => {
    const rows = groupPermissionRows(settings, true);
    expect(rows.filter((r) => r.kind === "choice").map((r) => r.key)).toEqual(["joinPolicy"]);
    expect(rows.find((r) => r.key === "joinPolicy")?.value).toBe(GROUP_JOIN_APPROVAL);
    expect(rows.find((r) => r.key === "muteAll")?.value).toBe(false);
    expect(rows.find((r) => r.key === "onlyAdminCanAtAll")?.value).toBe(true);
    expect(rows.find((r) => r.key === "shareCardPermission")?.value).toBe(true);
  });

  it("editable follows canManage only — never busy, never an error", () => {
    expect(groupPermissionRows(settings, false).every((r) => r.editable === false)).toBe(true);
    const rows = groupPermissionRows(settings, true, ["muteAll"], { muteAll: "网络错误" });
    expect(rows.every((r) => r.editable)).toBe(true);
  });

  it("busy and error are per key, so a failure keeps its siblings usable", () => {
    const rows = groupPermissionRows(settings, true, ["muteAll"], { onlyAdminCanPin: "权限不足" });
    expect(rows.filter((r) => r.busy).map((r) => r.key)).toEqual(["muteAll"]);
    expect(rows.filter((r) => r.error).map((r) => [r.key, r.error])).toEqual([
      ["onlyAdminCanPin", "权限不足"],
    ]);
  });

  it("ignores unknown busy keys and treats null inputs as empty", () => {
    const rows = groupPermissionRows(settings, true, ["nope", "muteAll", "muteAll"], null);
    expect(rows.filter((r) => r.busy).map((r) => r.key)).toEqual(["muteAll"]);
    expect(groupPermissionRows(settings, true, null, null).every((r) => !r.busy && r.error === null)).toBe(true);
  });

  it("keeps an error visible on a read-only panel instead of dropping the reason", () => {
    const rows = groupPermissionRows(settings, false, [], { muteAll: "你已不是管理员" });
    expect(rows.find((r) => r.key === "muteAll")).toMatchObject({ editable: false, error: "你已不是管理员" });
  });

  it("passes an unknown joinPolicy through rather than inventing one", () => {
    expect(groupPermissionRows({ ...settings, joinPolicy: 9 }, true)[0]?.value).toBe(9);
    expect(isGroupJoinPolicy(9)).toBe(false);
    expect([GROUP_JOIN_INVITE, GROUP_JOIN_APPROVAL, GROUP_JOIN_OPEN].every(isGroupJoinPolicy)).toBe(true);
  });

  it("does not mutate its inputs", () => {
    const input = { ...settings };
    groupPermissionRows(input, true, ["muteAll"], { muteAll: "x" });
    expect(input).toEqual(settings);
  });
});

const all: MemberRoleCapabilities = {
  promote: true,
  demote: true,
  mute: true,
  unmute: true,
  remove: true,
  transferOwner: true,
};
const member = (role: GroupMemberRole, muted = false): GroupMemberSnapshot => ({
  id: `u-${role}`,
  name: role,
  role,
  muted,
});
const ids = (m: GroupMemberSnapshot, viewer: GroupMemberRole, caps: MemberRoleCapabilities | null = all) =>
  memberRoleActions(m, viewer, caps).map((e) => e.action);

describe("memberRoleActions", () => {
  it("never offers an action against the owner, whoever is looking", () => {
    for (const viewer of ["owner", "admin", "member"] as GroupMemberRole[]) {
      expect(ids(member("owner"), viewer)).toEqual([]);
      expect(ids(member("owner", true), viewer)).toEqual([]);
    }
  });

  it("gives a plain member no management action at all", () => {
    expect(ids(member("member"), "member")).toEqual([]);
    expect(ids(member("admin"), "member")).toEqual([]);
  });

  it("stops an admin at a peer admin and never lets one transfer ownership", () => {
    expect(ids(member("admin"), "admin")).toEqual([]);
    expect(ids(member("member"), "admin")).toEqual(["promote", "mute", "remove"]);
    expect(ids(member("member"), "admin")).not.toContain("transferOwner");
  });

  it("lets the owner manage members and admins, transfer included", () => {
    expect(ids(member("member"), "owner")).toEqual(["promote", "mute", "transferOwner", "remove"]);
    expect(ids(member("admin"), "owner")).toEqual(["demote", "mute", "transferOwner", "remove"]);
  });

  it("promote only for a member, demote only for an admin", () => {
    expect(ids(member("member"), "owner", { promote: true, demote: true })).toEqual(["promote"]);
    expect(ids(member("admin"), "owner", { promote: true, demote: true })).toEqual(["demote"]);
  });

  it("mute and unmute are mutually exclusive by state", () => {
    expect(ids(member("member", false), "owner", { mute: true, unmute: true })).toEqual(["mute"]);
    expect(ids(member("member", true), "owner", { mute: true, unmute: true })).toEqual(["unmute"]);
  });

  it("renders nothing without capabilities and each switch reveals exactly its action", () => {
    expect(ids(member("member"), "owner", {})).toEqual([]);
    expect(ids(member("member"), "owner", null)).toEqual([]);
    expect(ids(member("member"), "owner", { remove: true })).toEqual(["remove"]);
    expect(ids(member("member"), "owner", { transferOwner: true })).toEqual(["transferOwner"]);
    expect(ids(member("member"), "owner", { promote: false, remove: false })).toEqual([]);
  });

  it("flags transferOwner and remove as the trailing danger group", () => {
    const entries = memberRoleActions(member("member"), "owner", all);
    expect(entries.filter((e) => e.danger).map((e) => e.action)).toEqual(["transferOwner", "remove"]);
    expect(entries.slice(-2).every((e) => e.danger)).toBe(true);
    expect(entries.at(-1)?.action).toBe("remove");
  });
});
