import { describe, expect, it } from "vitest";
import { defaultMessageLifecycle } from "./message-lifecycle";
import { composerAllowedActions, reduceSelection, resolveComposerMode, resolveDesktopShortcut, resolveMessageActions, resolveMessageCapabilities, resolveMessageMode, resolveSwipeIntent } from "./interaction-state";

describe("interaction state contracts", () => {
  it("uses deterministic composer precedence", () => {
    expect(resolveComposerMode({ readOnly: true, recording: true, online: false })).toBe("readOnly");
    expect(resolveComposerMode({ permissionGranted: false, online: false })).toBe("permissionDenied");
    expect(resolveComposerMode({ hasText: true })).toBe("typing");
    expect(composerAllowedActions("offline").has("send")).toBe(false);
  });

  it("projects lifecycle before transient pointer state", () => {
    expect(resolveMessageMode({ lifecycle: { ...defaultMessageLifecycle, mutation: "recalled" }, hovered: true })).toBe("recalled");
    expect(resolveMessageMode({ lifecycle: { ...defaultMessageLifecycle, read: "read" } })).toBe("read");
  });

  it("extends selection from a stable anchor", () => {
    const anchored = reduceSelection({ selectedIds: new Set() }, { type: "replace", id: "b" });
    const extended = reduceSelection(anchored, { type: "extend", id: "d", orderedIds: ["a", "b", "c", "d"] });
    expect([...extended.selectedIds]).toEqual(["b", "c", "d"]);
  });

  it("resolves scoped shortcuts and rejects diagonal swipes", () => {
    expect(resolveDesktopShortcut({ key: "k", primary: true })).toBe("commandPalette");
    expect(resolveDesktopShortcut({ key: "Enter", primary: true, scope: "composer" })).toBe("send");
    expect(resolveSwipeIntent({ deltaX: 80, deltaY: 70, target: "message" })).toBe("none");
    expect(resolveSwipeIntent({ deltaX: 80, deltaY: 8, target: "message" })).toBe("reply");
  });

  it("derives message actions from ownership, lifecycle, and host capabilities", () => {
    const own = resolveMessageCapabilities({ lifecycle: defaultMessageLifecycle, own: true });
    expect(own.has("edit")).toBe(true);
    expect(own.has("report")).toBe(false);
    const peer = resolveMessageCapabilities({ lifecycle: defaultMessageLifecycle, own: false });
    expect(peer.has("edit")).toBe(false);
    expect(peer.has("report")).toBe(true);
    const recalled = resolveMessageCapabilities({
      lifecycle: { ...defaultMessageLifecycle, mutation: "recalled" },
      own: true,
    });
    expect([...recalled]).toEqual([]);
  });

  it("derives extended actions from the same capability resolver", () => {
    const actions = resolveMessageCapabilities({
      lifecycle: defaultMessageLifecycle,
      own: true,
      pinned: true,
      hasThread: true,
      hasQuote: true,
      supportsMergeForward: true,
    });
    expect(actions.has("unpin")).toBe(true);
    expect(actions.has("pin")).toBe(false);
    expect(actions.has("openThread")).toBe(true);
    expect(actions.has("jumpToQuote")).toBe(true);
    expect(actions.has("mergeForward")).toBe(true);

    const retry = resolveMessageCapabilities({
      lifecycle: { ...defaultMessageLifecycle, send: "failed" },
      own: true,
    });
    expect(retry.has("retry")).toBe(true);
    expect(retry.has("reply")).toBe(false);
  });

  it("resolves conversation-scoped forward and thread shortcuts", () => {
    expect(resolveDesktopShortcut({ key: "f", scope: "conversation" })).toBe("forward");
    expect(resolveDesktopShortcut({ key: "t", scope: "conversation" })).toBe("openThread");
  });

  it("keeps action presentation downstream of availability", () => {
    const actions = resolveMessageActions({ lifecycle: defaultMessageLifecycle, own: false }, "hoverToolbar");
    expect(actions.find((action) => action.id === "reply")?.promoted).toBe(true);
    expect(actions.find((action) => action.id === "report")?.group).toBe("destructive");
  });
});
