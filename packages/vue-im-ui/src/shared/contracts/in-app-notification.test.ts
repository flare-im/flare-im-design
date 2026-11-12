import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { createFlareInAppNotifications } from "../../composables/useFlareInAppNotifications";
import {
  IN_APP_NOTIFICATION_DURATION_MS,
  IN_APP_NOTIFICATION_PENDING_LIMIT,
  inAppNotificationEmphasis,
  inAppNotificationShowsCount,
  inAppNotificationSpoken,
  type FlareInAppNotification,
} from "./in-app-notification";

/**
 * The shared queue table (`spec/in-app-notification-vectors.json`): items fed in, what shows and waits out, and when
 * the visible banner's time starts over. The Flutter, SwiftUI and Compose kits run the same file.
 */
type Step = {
  op: "present" | "dismiss" | "clear" | "clearAll";
  item?: string;
  collapseIds?: string[];
  current: string | null;
  pending: string[];
  restart: boolean;
};
const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/in-app-notification-vectors.json"), "utf8")) as {
  limits: { durationMs: number; pendingLimit: number };
  cases: { name: string; steps: Step[] }[];
};

function item(text: string): FlareInAppNotification {
  const [collapseId, body] = text.split("/");
  return { collapseId, conversationId: collapseId.slice(2), title: collapseId, body };
}
const written = (entry: FlareInAppNotification | null) => (entry ? `${entry.collapseId}/${entry.body}` : null);

describe("in-app notification queue", () => {
  it("keeps the table's limits", () => {
    expect(IN_APP_NOTIFICATION_DURATION_MS).toBe(table.limits.durationMs);
    expect(IN_APP_NOTIFICATION_PENDING_LIMIT).toBe(table.limits.pendingLimit);
  });

  for (const vector of table.cases) {
    it(vector.name, () => {
      const presenter = createFlareInAppNotifications();
      vector.steps.forEach((step, index) => {
        const before = presenter.revision.value;
        switch (step.op) {
          case "present": presenter.present(item(step.item!)); break;
          case "dismiss": presenter.dismiss(); break;
          case "clear": presenter.clear(step.collapseIds ?? []); break;
          case "clearAll": presenter.clearAll(); break;
        }
        const where = `${vector.name} step ${index + 1}`;
        expect(written(presenter.current.value), where).toBe(step.current);
        expect(presenter.pending.value.map(written), where).toEqual(step.pending);
        expect(presenter.revision.value !== before, where).toBe(step.restart);
      });
    });
  }
});

describe("in-app notification words", () => {
  const words = { label: "New message", mention: "[Mention]", urgent: "[Urgent]", count: (n: number) => `[${n} messages]` };

  it("tags only mentions and urgent", () => {
    expect(inAppNotificationEmphasis("mentions")).toBe("mentions");
    expect(inAppNotificationEmphasis("urgent")).toBe("urgent");
    expect(inAppNotificationEmphasis("quiet")).toBeNull();
    expect(inAppNotificationEmphasis(undefined)).toBeNull();
  });

  it("counts only above one message", () => {
    expect(inAppNotificationShowsCount({})).toBe(false);
    expect(inAppNotificationShowsCount({ count: 1 })).toBe(false);
    expect(inAppNotificationShowsCount({ count: 2 })).toBe(true);
  });

  it("reads the label, the title, the tag, the count and the body", () => {
    expect(inAppNotificationSpoken({ collapseId: "c:a", conversationId: "a", title: "Alice", body: "hi", count: 3, channel: "mentions" }, words))
      .toBe("New message, Alice, [Mention], [3 messages], hi");
    expect(inAppNotificationSpoken({ collapseId: "c:a", conversationId: "a", title: "Alice", body: "hi" }, words))
      .toBe("New message, Alice, hi");
  });
});
