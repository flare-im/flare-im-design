import { describe, it, expect } from "vitest";
import vectors from "../../../../../spec/group-management-vectors.json";
import {
  groupDetailMemberActions,
  groupJoinPolicies,
  groupManagementEntries,
  groupManagementEntryOrder,
  groupPermissionKeys,
  groupPermissionRows,
  memberRoleActions,
  type FlareGroupCapabilities,
  type FlareMemberActions,
  type GroupDetailMemberState,
  type GroupMemberRole,
  type GroupPermissionSettings,
  type MemberRoleActionEntry,
} from "./group-permissions";

const settings: GroupPermissionSettings = {
  muteAll: false,
  onlyAdminCanAtAll: true,
  onlyAdminCanPin: false,
  shareCardPermission: true,
  joinPolicy: "approval",
};
const owner: FlareGroupCapabilities = {
  canManageInfo: true,
  canManageJoinSettings: true,
  canManageJoinRequests: true,
  canInvite: true,
  canDissolve: true,
};

describe("group management vectors (spec/group-management-vectors.json)", () => {
  it("keeps the shared display order", () => {
    expect([...groupManagementEntryOrder]).toEqual(vectors.entryOrder);
  });

  it("maps each capability to the entries it names, and nothing else", () => {
    expect(vectors.entries.length).toBeGreaterThanOrEqual(8);
    for (const vector of vectors.entries) {
      expect(groupManagementEntries(vector.capabilities as FlareGroupCapabilities), vector.id).toEqual(vector.expected);
    }
  });

  it("labels each member action from the host's answer and the member's state", () => {
    for (const vector of vectors.memberActions) {
      const member = vector.member as { role: GroupMemberRole; muted: boolean };
      const got = memberRoleActions(member, vector.actions as FlareMemberActions | null);
      expect(got, vector.id).toEqual(vector.expected as MemberRoleActionEntry[]);
    }
  });

  it("opens GroupDetail's member sheet only with what the host allows for that member", () => {
    for (const vector of vectors.detailSheet) {
      const got = groupDetailMemberActions(vector.model as GroupDetailMemberState, vector.memberId);
      expect(got, vector.id).toEqual(vector.expected as MemberRoleActionEntry[]);
    }
  });

  it("makes a permission matrix row editable exactly when its entry is offered", () => {
    for (const vector of vectors.entries) {
      const rows = groupPermissionRows(settings, vector.capabilities as FlareGroupCapabilities);
      const editable = rows.filter((row) => row.editable).map((row) => row.key);
      expect(editable, vector.id).toEqual(groupPermissionKeys.filter((key) => (vector.expected as string[]).includes(key)));
    }
  });
});

describe("groupPermissionRows", () => {
  it("returns the five real backend keys in canonical order", () => {
    expect(groupPermissionRows(settings, owner).map((r) => r.key)).toEqual([
      "joinPolicy",
      "muteAll",
      "onlyAdminCanAtAll",
      "onlyAdminCanPin",
      "shareCardPermission",
    ]);
  });

  it("marks joinPolicy as the only choice row and carries each value through", () => {
    const rows = groupPermissionRows(settings, owner);
    expect(rows.filter((r) => r.kind === "choice").map((r) => r.key)).toEqual(["joinPolicy"]);
    expect(rows.find((r) => r.key === "joinPolicy")?.value).toBe("approval");
    expect(rows.find((r) => r.key === "muteAll")?.value).toBe(false);
    expect(rows.find((r) => r.key === "onlyAdminCanAtAll")?.value).toBe(true);
    expect(rows.find((r) => r.key === "shareCardPermission")?.value).toBe(true);
  });

  it("editable follows the capabilities only — never busy, never an error", () => {
    expect(groupPermissionRows(settings, null).every((r) => r.editable === false)).toBe(true);
    const rows = groupPermissionRows(settings, owner, ["muteAll"], { muteAll: "网络错误" });
    expect(rows.every((r) => r.editable)).toBe(true);
  });

  it("lets an admin who may change the group's info switch the four flags but not the join policy", () => {
    const rows = groupPermissionRows(settings, { canManageInfo: true });
    expect(rows.filter((r) => r.editable).map((r) => r.key)).toEqual([
      "muteAll",
      "onlyAdminCanAtAll",
      "onlyAdminCanPin",
      "shareCardPermission",
    ]);
    expect(groupPermissionRows(settings, { canManageJoinSettings: true }).filter((r) => r.editable).map((r) => r.key)).toEqual(["joinPolicy"]);
  });

  it("busy and error are per key, so a failure keeps its siblings usable", () => {
    const rows = groupPermissionRows(settings, owner, ["muteAll"], { onlyAdminCanPin: "权限不足" });
    expect(rows.filter((r) => r.busy).map((r) => r.key)).toEqual(["muteAll"]);
    expect(rows.filter((r) => r.error).map((r) => [r.key, r.error])).toEqual([
      ["onlyAdminCanPin", "权限不足"],
    ]);
  });

  it("ignores unknown busy keys and treats null inputs as empty", () => {
    const rows = groupPermissionRows(settings, owner, ["nope", "muteAll", "muteAll"], null);
    expect(rows.filter((r) => r.busy).map((r) => r.key)).toEqual(["muteAll"]);
    expect(groupPermissionRows(settings, owner, null, null).every((r) => !r.busy && r.error === null)).toBe(true);
  });

  it("keeps an error visible on a read-only panel instead of dropping the reason", () => {
    const rows = groupPermissionRows(settings, null, [], { muteAll: "你已不是管理员" });
    expect(rows.find((r) => r.key === "muteAll")).toMatchObject({ editable: false, error: "你已不是管理员" });
  });

  it("passes an unknown join policy through rather than inventing one", () => {
    expect(groupPermissionRows({ ...settings, joinPolicy: null }, owner)[0]?.value).toBeNull();
    expect(groupJoinPolicies).toEqual(["open", "approval", "invite"]);
  });

  it("does not mutate its inputs", () => {
    const input = { ...settings };
    groupPermissionRows(input, owner, ["muteAll"], { muteAll: "x" });
    expect(input).toEqual(settings);
  });
});

const every: FlareMemberActions = { canRemove: true, canMute: true, canChangeRole: true, canTransferOwner: true };
const ids = (role: GroupMemberRole, actions: FlareMemberActions | null = every, muted = false) =>
  memberRoleActions({ role, muted }, actions).map((e) => e.action);

describe("memberRoleActions", () => {
  it("offers nothing the host did not answer for this member", () => {
    expect(ids("member", null)).toEqual([]);
    expect(ids("member", {})).toEqual([]);
    expect(ids("admin", { canRemove: false, canMute: false })).toEqual([]);
  });

  it("decides nothing by rank: what the host allows is what the sheet offers", () => {
    // The owner's protection and admins not managing each other come from the host's answer.
    expect(ids("admin")).toEqual(["demote", "mute", "transferOwner", "remove"]);
    expect(ids("member")).toEqual(["promote", "mute", "transferOwner", "remove"]);
  });

  it("promote only for a member, demote only for an admin, neither for the owner", () => {
    expect(ids("member", { canChangeRole: true })).toEqual(["promote"]);
    expect(ids("admin", { canChangeRole: true })).toEqual(["demote"]);
    expect(ids("owner", { canChangeRole: true })).toEqual([]);
  });

  it("mute and unmute are mutually exclusive by state", () => {
    expect(ids("member", { canMute: true }, false)).toEqual(["mute"]);
    expect(ids("member", { canMute: true }, true)).toEqual(["unmute"]);
  });

  it("each answer reveals exactly its action", () => {
    expect(ids("member", { canRemove: true })).toEqual(["remove"]);
    expect(ids("member", { canTransferOwner: true })).toEqual(["transferOwner"]);
  });

  it("flags transferOwner and remove as the trailing danger group", () => {
    const entries = memberRoleActions({ role: "member", muted: false }, every);
    expect(entries.filter((e) => e.danger).map((e) => e.action)).toEqual(["transferOwner", "remove"]);
    expect(entries.slice(-2).every((e) => e.danger)).toBe(true);
    expect(entries.at(-1)?.action).toBe("remove");
  });
});
