import { describe, expect, it } from "vitest";
import { formatConversationTime, formatMessageTime, formatRelativeTime, startsTimelineDay, timelineDateLabel } from "./timeline-label";

const now = new Date(2026, 8, 14, 15, 0).getTime();

describe("timelineDateLabel", () => {
  const labels = { today: "Today", yesterday: "Yesterday" };

  it("names today and yesterday through the host catalog", () => {
    expect(timelineDateLabel(now - 30_000, "en-US", labels, now)).toBe("Today");
    expect(timelineDateLabel(new Date(2026, 8, 13, 21, 40).getTime(), "en-US", labels, now)).toBe("Yesterday");
  });

  it("uses the locale's date, with the year only when it differs", () => {
    expect(timelineDateLabel(new Date(2026, 6, 2, 8, 0).getTime(), "en-US", labels, now)).toBe("7/2");
    expect(timelineDateLabel(new Date(2025, 11, 31, 8, 0).getTime(), "zh-CN", labels, now)).toBe("2025/12/31");
  });
});

describe("startsTimelineDay", () => {
  it("starts a day at the first message and at each new date, not at gaps within a day", () => {
    const morning = new Date(2026, 8, 14, 9, 0).getTime();
    expect(startsTimelineDay(0, morning)).toBe(true);
    expect(startsTimelineDay(morning, morning + 6 * 3_600_000)).toBe(false);
    expect(startsTimelineDay(new Date(2026, 8, 13, 23, 59).getTime(), morning)).toBe(true);
  });
});

describe("message and conversation times", () => {
  it("formats the message time in the locale's hour cycle", () => {
    const at = new Date(2026, 8, 14, 9, 5).getTime();
    expect(formatMessageTime(at, "zh-CN")).toBe("09:05");
    expect(formatMessageTime(at, "en-US")).toBe("9:05 AM");
    expect(formatMessageTime(at, "de-DE")).toBe("09:05");
  });

  it("shows the time today, the host's word for yesterday, then the date", () => {
    expect(formatConversationTime(new Date(2026, 8, 14, 13, 30).getTime(), "en-US", "Yesterday", now)).toBe("1:30 PM");
    expect(formatConversationTime(new Date(2026, 8, 13, 23, 59).getTime(), "zh-CN", "昨天", now)).toBe("昨天");
    expect(formatConversationTime(new Date(2026, 6, 2, 8, 0).getTime(), "en-US", "Yesterday", now)).toBe("7/2");
    expect(formatConversationTime(new Date(2026, 6, 2, 8, 0).getTime(), "de-DE", "Gestern", now)).toBe("2.7.");
    expect(formatConversationTime(new Date(2025, 11, 31, 8, 0).getTime(), "zh-CN", "昨天", now)).toBe("2025/12/31");
  });

  it("counts back in minutes, hours and days for feeds, then shows the date", () => {
    expect(formatRelativeTime(now - 20_000, "en-US", now)).toBe("now");
    expect(formatRelativeTime(now - 5 * 60_000, "en-US", now)).toBe("5 minutes ago");
    expect(formatRelativeTime(now - 3 * 3_600_000, "zh-CN", now)).toBe("3小时前");
    expect(formatRelativeTime(now - 86_400_000, "en-US", now)).toBe("yesterday");
    expect(formatRelativeTime(now - 30 * 86_400_000, "en-US", now)).toBe("8/15");
  });
});
