import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  FLARE_SWIPE_REPLY_ARM_DISTANCE,
  FLARE_SWIPE_REPLY_MAX_TRAVEL,
  flareSwipeReplyGesture,
} from "./swipe-reply";

type Case = { id: string; dx: number; dy: number; rtl: boolean; expected: { travel: number; armed: boolean } };
const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/swipe-reply-vectors.json"), "utf8")) as {
  armDistance: number;
  maxTravel: number;
  resistance: number;
  dominance: number;
  cases: Case[];
};

describe("swipe to reply (spec/swipe-reply-vectors.json)", () => {
  it("uses the shared geometry", () => {
    expect(FLARE_SWIPE_REPLY_ARM_DISTANCE).toBe(vectors.armDistance);
    expect(FLARE_SWIPE_REPLY_MAX_TRAVEL).toBe(vectors.maxTravel);
    expect(vectors.cases.length).toBeGreaterThanOrEqual(19);
  });

  it.each(vectors.cases.map((v) => [v.id, v] as const))("%s", (_, v) => {
    const gesture = flareSwipeReplyGesture(v.dx, v.dy, { rtl: v.rtl });
    expect(Math.abs(gesture.travel - v.expected.travel)).toBeLessThan(0.001);
    expect(gesture.armed).toBe(v.expected.armed);
  });

  it("treats a missing or broken travel as no gesture", () => {
    expect(flareSwipeReplyGesture(Number.NaN, 0)).toEqual({ travel: 0, armed: false });
    expect(flareSwipeReplyGesture(80, Number.POSITIVE_INFINITY)).toEqual({ travel: 0, armed: false });
  });
});
