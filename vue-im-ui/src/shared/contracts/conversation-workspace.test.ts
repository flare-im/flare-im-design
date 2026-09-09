import { describe, it, expect } from "vitest";
import {
  paneRender,
  paneRetryVisible,
  paneSkeletonVariant,
  workspaceBannerActionVisible,
  workspaceBannerTone,
  workspaceBannerVisible,
  workspacePaneKeys,
  workspacePaneStatuses,
  type WorkspacePaneState,
} from "./conversation-workspace";

describe("paneRender", () => {
  it("maps every declared status", () => {
    expect(workspacePaneStatuses.map(status => paneRender({ status }))).toEqual([
      "content",
      "skeleton",
      "empty",
      "failure",
    ]);
  });

  it("degrades a missing / absent status to the host content", () => {
    expect(paneRender(undefined)).toBe("content");
    expect(paneRender(null)).toBe("content");
    expect(paneRender({})).toBe("content");
    expect(paneRender({ message: "只有文案" })).toBe("content");
  });

  it("degrades an illegal status to content instead of throwing or blanking", () => {
    for (const bogus of ["", "READY", "idle", "Loading", "0", "null"]) {
      const state = { status: bogus } as unknown as WorkspacePaneState;
      expect(() => paneRender(state)).not.toThrow();
      expect(paneRender(state)).toBe("content");
    }
  });

  it("never reports skeleton as empty (loading must not look like an empty list)", () => {
    expect(paneRender({ status: "loading" })).not.toBe("empty");
  });
});

describe("paneRetryVisible", () => {
  it("needs failure + non-blank label + host handler, all three", () => {
    for (const status of workspacePaneStatuses) {
      for (const actionLabel of [undefined, "", "   ", "重试"]) {
        for (const hasRetry of [false, true]) {
          const expected = status === "failure" && actionLabel === "重试" && hasRetry;
          expect(paneRetryVisible({ status, actionLabel }, hasRetry)).toBe(expected);
        }
      }
    }
  });

  it("shows the reason without a button when the host bound no handler", () => {
    const failed: WorkspacePaneState = { status: "failure", message: "网络中断", actionLabel: "重试" };
    expect(paneRender(failed)).toBe("failure");
    expect(paneRetryVisible(failed, false)).toBe(false);
  });

  it("shows the reason without a button when the host gave no label", () => {
    expect(paneRetryVisible({ status: "failure", message: "网络中断" }, true)).toBe(false);
  });

  it("is false for a missing state and for an illegal status", () => {
    expect(paneRetryVisible(undefined, true)).toBe(false);
    expect(paneRetryVisible(null, true)).toBe(false);
    expect(paneRetryVisible({ status: "boom", actionLabel: "重试" } as unknown as WorkspacePaneState, true)).toBe(false);
  });
});

describe("pane independence", () => {
  it("keeps a loaded pane on content while another pane fails", () => {
    const list: WorkspacePaneState = { status: "ready" };
    const chat: WorkspacePaneState = { status: "failure", message: "消息加载失败", actionLabel: "重试" };
    const detail: WorkspacePaneState = { status: "loading" };
    expect(paneRender(list)).toBe("content");
    expect(paneRender(chat)).toBe("failure");
    expect(paneRender(detail)).toBe("skeleton");
    // Retry visibility is per pane: only the failing one offers recovery.
    expect(paneRetryVisible(list, true)).toBe(false);
    expect(paneRetryVisible(chat, true)).toBe(true);
    expect(paneRetryVisible(detail, true)).toBe(false);
  });

  it("resolves each pane from its own state only", () => {
    const failure: WorkspacePaneState = { status: "failure", message: "x" };
    const empty: WorkspacePaneState = { status: "empty" };
    for (const state of [failure, empty]) {
      expect(paneRender({ status: "ready" })).toBe("content");
      expect(paneRender(state)).not.toBe("content");
    }
  });
});

describe("workspaceBannerVisible", () => {
  it("hides a missing, blank or whitespace-only banner", () => {
    expect(workspaceBannerVisible(undefined)).toBe(false);
    expect(workspaceBannerVisible(null)).toBe(false);
    expect(workspaceBannerVisible({ message: "" })).toBe(false);
    expect(workspaceBannerVisible({ message: "   " })).toBe(false);
    expect(workspaceBannerVisible({ message: "\n\t " })).toBe(false);
    expect(workspaceBannerVisible({ message: undefined as unknown as string })).toBe(false);
  });

  it("shows a banner with a real message, tone or not", () => {
    expect(workspaceBannerVisible({ message: "网络已断开" })).toBe(true);
    expect(workspaceBannerVisible({ tone: "error", message: "会话已过期" })).toBe(true);
  });

  it("is independent of pane state (offline banner over a readable cached list)", () => {
    const banner = { tone: "warning" as const, message: "离线，显示的是缓存内容" };
    expect(workspaceBannerVisible(banner)).toBe(true);
    expect(paneRender({ status: "ready" })).toBe("content");
  });
});

describe("workspaceBannerActionVisible", () => {
  it("needs a visible banner + non-blank label + host handler", () => {
    expect(workspaceBannerActionVisible({ message: "离线", actionLabel: "重连" }, true)).toBe(true);
    expect(workspaceBannerActionVisible({ message: "离线", actionLabel: "重连" }, false)).toBe(false);
    expect(workspaceBannerActionVisible({ message: "离线", actionLabel: "  " }, true)).toBe(false);
    expect(workspaceBannerActionVisible({ message: "离线" }, true)).toBe(false);
    expect(workspaceBannerActionVisible({ message: "  ", actionLabel: "重连" }, true)).toBe(false);
    expect(workspaceBannerActionVisible(undefined, true)).toBe(false);
  });
});

describe("workspaceBannerTone", () => {
  it("maps every tone onto a StatusBanner tone, error becoming danger", () => {
    expect(workspaceBannerTone("info")).toBe("info");
    expect(workspaceBannerTone("warning")).toBe("warning");
    expect(workspaceBannerTone("error")).toBe("danger");
    expect(workspaceBannerTone("success")).toBe("success");
  });

  it("defaults to info for a missing or unknown tone", () => {
    expect(workspaceBannerTone(undefined)).toBe("info");
    expect(workspaceBannerTone("magenta" as never)).toBe("info");
  });
});

describe("paneSkeletonVariant", () => {
  it("gives rows to the inbox, bubbles to the timeline and a card to details", () => {
    expect(workspacePaneKeys.map(paneSkeletonVariant)).toEqual(["conversation", "message", "profile"]);
  });
});
