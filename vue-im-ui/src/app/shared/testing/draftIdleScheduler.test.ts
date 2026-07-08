import { describe, expect, it, vi } from "vitest";
import { DraftIdleScheduler } from "../draftIdleScheduler";

describe("DraftIdleScheduler", () => {
  it("saves non-empty drafts after the idle delay", () => {
    vi.useFakeTimers();
    try {
      const saved: string[] = [];
      const scheduler = new DraftIdleScheduler(5_000, (_conversationId, draft) => {
        saved.push(draft);
      });

      scheduler.schedule({ conversationId: "c1", draft: "hello" });
      vi.advanceTimersByTime(4_999);
      expect(saved).toEqual([]);

      vi.advanceTimersByTime(1);
      expect(saved).toEqual(["hello"]);
      scheduler.dispose();
    } finally {
      vi.useRealTimers();
    }
  });

  it("resets the idle window when the draft changes", () => {
    vi.useFakeTimers();
    try {
      const saved: string[] = [];
      const scheduler = new DraftIdleScheduler(5_000, (_conversationId, draft) => {
        saved.push(draft);
      });

      scheduler.schedule({ conversationId: "c1", draft: "hel" });
      vi.advanceTimersByTime(4_000);
      scheduler.schedule({ conversationId: "c1", draft: "hello" });
      vi.advanceTimersByTime(4_999);
      expect(saved).toEqual([]);

      vi.advanceTimersByTime(1);
      expect(saved).toEqual(["hello"]);
      scheduler.dispose();
    } finally {
      vi.useRealTimers();
    }
  });

  it("flushes the pending draft immediately", async () => {
    vi.useFakeTimers();
    try {
      const saved: string[] = [];
      const scheduler = new DraftIdleScheduler(5_000, (_conversationId, draft) => {
        saved.push(draft);
      });

      scheduler.schedule({ conversationId: "c1", draft: "hello" });
      vi.advanceTimersByTime(1_000);
      await scheduler.flush();
      expect(saved).toEqual(["hello"]);

      vi.advanceTimersByTime(5_000);
      expect(saved).toEqual(["hello"]);
      scheduler.dispose();
    } finally {
      vi.useRealTimers();
    }
  });

  it("ignores empty drafts and canceled drafts", () => {
    vi.useFakeTimers();
    try {
      const saved: string[] = [];
      const scheduler = new DraftIdleScheduler(5_000, (_conversationId, draft) => {
        saved.push(draft);
      });

      scheduler.schedule({ conversationId: "c1", draft: "   " });
      vi.advanceTimersByTime(5_000);
      scheduler.schedule({ conversationId: "c1", draft: "hello" });
      scheduler.cancel();
      vi.advanceTimersByTime(5_000);

      expect(saved).toEqual([]);
      scheduler.dispose();
    } finally {
      vi.useRealTimers();
    }
  });
});
