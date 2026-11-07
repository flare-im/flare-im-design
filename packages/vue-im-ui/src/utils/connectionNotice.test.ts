import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  FLARE_CONNECTION_RECONNECTING_MIN_SHOWN_MS,
  FLARE_CONNECTION_SWITCHING_DELAY_MS,
  FLARE_CONNECTION_SYNCING_DELAY_MS,
  FlareConnectionNoticeTracker,
  flareConnectionActionReason,
  type FlareConnectionStatus,
} from "./connectionNotice";

/**
 * The shared connection notice table (`spec/connection-notice-vectors.json`): statuses over time in, what
 * the notice shows at each moment out. The Flutter, SwiftUI and Compose kits run the same file.
 */
type Expect = {
  visible: boolean;
  text?: string | null;
  tone?: string | null;
  pulse?: boolean;
  countdown?: number | null;
  progress?: number | null;
  action?: string | null;
  badge?: boolean;
  next?: number | null;
};
type Step = { at: number; status?: FlareConnectionStatus; expect: Expect };
const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../spec/connection-notice-vectors.json"), "utf8")) as {
  thresholds: { syncingDelayMs: number; switchingDelayMs: number; reconnectingMinShownMs: number };
  cases: { name: string; steps: Step[] }[];
};

describe("what the connection notice shows over time", () => {
  it("uses the shared thresholds", () => {
    expect(FLARE_CONNECTION_SYNCING_DELAY_MS).toBe(table.thresholds.syncingDelayMs);
    expect(FLARE_CONNECTION_SWITCHING_DELAY_MS).toBe(table.thresholds.switchingDelayMs);
    expect(FLARE_CONNECTION_RECONNECTING_MIN_SHOWN_MS).toBe(table.thresholds.reconnectingMinShownMs);
    expect(table.cases.length).toBeGreaterThanOrEqual(23);
  });

  for (const vector of table.cases) {
    it(vector.name, () => {
      const tracker = new FlareConnectionNoticeTracker();
      vector.steps.forEach((step, index) => {
        if (step.status) tracker.observe(step.status, step.at);
        const model = tracker.present(step.at);
        const seen = {
          visible: model.visible,
          text: model.text,
          tone: model.tone,
          pulse: model.pulse,
          countdown: model.countdown,
          progress: model.progress,
          action: model.action,
          badge: model.badge,
          next: tracker.nextChangeAt(step.at),
        };
        const want = {
          text: null, tone: null, pulse: false, countdown: null, progress: null, action: null, badge: false, next: null,
          ...step.expect,
        };
        expect(seen, `${vector.name} — step ${index} at ${step.at}`).toEqual(want);
      });
    });
  }
});

describe("the reason a status carries", () => {
  it("is the SDK's string: a switching reason and an actionRequired reason without words are both taken", () => {
    // The core SDK types `reason` as a string; a status straight from `connection://status` is a status here.
    const fromSdk: { phase: "switching" | "actionRequired"; reason?: string; attempt: number; developmentMode: boolean } =
      { phase: "switching", reason: "failback", attempt: 0, developmentMode: false };
    const status: FlareConnectionStatus = fromSdk;
    const tracker = new FlareConnectionNoticeTracker();
    tracker.observe(status, 0);
    expect(tracker.present(FLARE_CONNECTION_SWITCHING_DELAY_MS).text).toBe("switching");
    tracker.observe({ ...fromSdk, phase: "actionRequired", reason: "accountSuspended" }, FLARE_CONNECTION_SWITCHING_DELAY_MS + 1);
    const model = tracker.present(FLARE_CONNECTION_SWITCHING_DELAY_MS + 1);
    expect([model.text, model.action]).toEqual(["expired", "signIn"]);
  });

  it("reads only the four actionRequired reasons; anything else, or none, is expired", () => {
    for (const reason of ["kicked", "expired", "upgradeRequired", "tenantUnavailable"] as const) {
      expect(flareConnectionActionReason(reason)).toBe(reason);
    }
    for (const other of [undefined, null, "", "drain", "Kicked", "accountSuspended"]) {
      expect(flareConnectionActionReason(other)).toBe("expired");
    }
  });
});
