import { describe, it, expect } from "vitest";
import {
  relationActions,
  relationShowsPending,
  shortenUserId,
  unknownUserPresentation,
  type RelationCapabilities,
  type RelationState,
} from "./relation";

const allCaps: RelationCapabilities = {
  add: true,
  accept: true,
  reject: true,
  remove: true,
  block: true,
  unblock: true,
  message: true,
};

const ids = (relation: RelationState, caps: RelationCapabilities | null | undefined) =>
  relationActions(relation, caps).map((e) => e.action);

describe("unknownUserPresentation", () => {
  it("maps every kind to its own icon", () => {
    expect(unknownUserPresentation("unknown").icon).toBe("unknown");
    expect(unknownUserPresentation("deactivated").icon).toBe("deactivated");
    expect(unknownUserPresentation("blocked").icon).toBe("blocked");
    expect(unknownUserPresentation("unreachable").icon).toBe("unreachable");
  });

  it("carries a tone alongside the icon, never instead of it", () => {
    expect(unknownUserPresentation("unknown").tone).toBe("neutral");
    expect(unknownUserPresentation("deactivated").tone).toBe("neutral");
    expect(unknownUserPresentation("blocked").tone).toBe("danger");
    expect(unknownUserPresentation("unreachable").tone).toBe("warning");
  });

  it("degrades an absent or unrecognised kind to unknown instead of blank", () => {
    expect(unknownUserPresentation(undefined)).toEqual({ kind: "unknown", icon: "unknown", tone: "neutral" });
    expect(unknownUserPresentation(null)).toEqual({ kind: "unknown", icon: "unknown", tone: "neutral" });
    expect(unknownUserPresentation("ghost" as never).kind).toBe("unknown");
  });
});

describe("shortenUserId", () => {
  it("keeps short ids intact and trims surrounding space", () => {
    expect(shortenUserId("u_42")).toBe("u_42");
    expect(shortenUserId("  u_42  ")).toBe("u_42");
    expect(shortenUserId("")).toBe("");
    expect(shortenUserId(undefined)).toBe("");
    expect(shortenUserId(null)).toBe("");
  });

  it("keeps an id exactly at the budget", () => {
    const exact = "0123456789abcdef01234567"; // 24
    expect(exact.length).toBe(24);
    expect(shortenUserId(exact)).toBe(exact);
  });

  it("middle-elides a long id to the budget", () => {
    const long = "2AW1QQ2SKVWFEPJRXN0123456789abcdef";
    const out = shortenUserId(long);
    expect(out.length).toBe(24);
    expect(out).toBe("2AW1QQ2SKVWF…56789abcdef");
    expect(out.startsWith("2AW1QQ2SKVWF")).toBe(true);
    expect(out.endsWith("56789abcdef")).toBe(true);
  });

  it("honours a custom budget and floors it so the result stays readable", () => {
    expect(shortenUserId("abcdefghijklmnop", 10).length).toBe(10);
    expect(shortenUserId("abcdefghijklmnop", 2).length).toBe(8);
  });
});

describe("relationActions", () => {
  it("renders nothing when the host grants no capability", () => {
    for (const relation of ["none", "pendingOut", "pendingIn", "friends", "blocked"] as RelationState[]) {
      expect(ids(relation, {})).toEqual([]);
      expect(ids(relation, undefined)).toEqual([]);
      expect(ids(relation, null)).toEqual([]);
    }
  });

  it("none offers add as primary plus block", () => {
    expect(ids("none", allCaps)).toEqual(["add", "block"]);
    const entries = relationActions("none", allCaps);
    expect(entries[0]).toEqual({ action: "add", primary: true, destructive: false });
    expect(entries[1]).toEqual({ action: "block", primary: false, destructive: false });
  });

  it("pendingOut never re-offers add, only block", () => {
    expect(ids("pendingOut", allCaps)).toEqual(["block"]);
    expect(ids("pendingOut", { add: true })).toEqual([]);
    expect(relationShowsPending("pendingOut")).toBe(true);
    expect(relationShowsPending("none")).toBe(false);
    expect(relationShowsPending("pendingIn")).toBe(false);
    expect(relationShowsPending("friends")).toBe(false);
    expect(relationShowsPending("blocked")).toBe(false);
    expect(relationShowsPending(undefined)).toBe(false);
  });

  it("pendingIn offers accept as primary, then reject and block", () => {
    expect(ids("pendingIn", allCaps)).toEqual(["accept", "reject", "block"]);
    expect(relationActions("pendingIn", allCaps).filter((e) => e.primary).map((e) => e.action)).toEqual(["accept"]);
    expect(relationActions("pendingIn", allCaps).some((e) => e.destructive)).toBe(false);
  });

  it("friends offers message as primary and marks remove and block destructive", () => {
    expect(ids("friends", allCaps)).toEqual(["message", "remove", "block"]);
    const entries = relationActions("friends", allCaps);
    expect(entries.filter((e) => e.primary).map((e) => e.action)).toEqual(["message"]);
    expect(entries.filter((e) => e.destructive).map((e) => e.action)).toEqual(["remove", "block"]);
  });

  it("blocked offers unblock and nothing else", () => {
    expect(ids("blocked", allCaps)).toEqual(["unblock"]);
    expect(relationActions("blocked", allCaps)[0]).toEqual({
      action: "unblock",
      primary: true,
      destructive: false,
    });
  });

  it("a missing capability removes just its own entry and keeps the order", () => {
    expect(ids("none", { block: true })).toEqual(["block"]);
    expect(ids("none", { add: true })).toEqual(["add"]);
    expect(ids("pendingIn", { accept: true, block: true })).toEqual(["accept", "block"]);
    expect(ids("pendingIn", { reject: true })).toEqual(["reject"]);
    expect(ids("friends", { remove: true, block: true })).toEqual(["remove", "block"]);
    expect(ids("friends", { message: true })).toEqual(["message"]);
    expect(ids("blocked", { message: true, add: true, unblock: false })).toEqual([]);
  });

  it("a false switch is as good as an absent one", () => {
    expect(ids("none", { add: false, block: false })).toEqual([]);
    expect(ids("friends", { message: false, remove: true, block: false })).toEqual(["remove"]);
  });

  it("an absent relation degrades to none rather than throwing", () => {
    expect(relationActions(undefined, allCaps).map((e) => e.action)).toEqual(["add", "block"]);
    expect(relationActions("ghost" as never, allCaps).map((e) => e.action)).toEqual(["add", "block"]);
  });
});
