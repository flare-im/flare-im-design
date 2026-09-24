import { describe, expect, it } from "vitest";
import vectors from "../../../../../spec/invite-vectors.json";
import {
  formatInviteJoinedDate,
  inviteCodeFieldState,
  inviteCodeToCheck,
  normalizeInviteCode,
  referralDepthRows,
  regenerateAvailability,
} from "./invite";

describe("invite contracts (spec/invite-vectors.json)", () => {
  it.each(vectors.normalize)("normalize $id", (v) => {
    expect(normalizeInviteCode(v.raw, (v as { length?: number }).length)).toBe(v.expected);
  });

  it.each(vectors.fieldState)("fieldState $id", (v) => {
    expect(inviteCodeFieldState({
      mode: v.mode as "off" | "optional" | "required",
      value: v.value,
      checking: (v as { checking?: boolean }).checking,
      checkResult: (v as { checkResult?: { valid: boolean } }).checkResult ?? null,
      error: (v as { error?: string }).error,
      disabled: (v as { disabled?: boolean }).disabled,
    })).toBe(v.expected);
  });

  it.each(vectors.checkRequest)("checkRequest $id", (v) => {
    expect(inviteCodeToCheck({
      value: v.value,
      length: (v as { length?: number }).length,
      mode: (v as { mode?: "off" }).mode,
      disabled: (v as { disabled?: boolean }).disabled,
    })).toBe(v.expected);
  });

  it.each(vectors.depthRows)("depthRows $id", (v) => {
    expect(referralDepthRows(v.stats, v.maxDepthShown)).toEqual(v.expected);
  });

  it.each(vectors.regenerate)("regenerate $id", (v) => {
    expect(regenerateAvailability(v.canRegenerate, v.availableAt, v.now)).toEqual(v.expected);
  });

  it.each(vectors.joinedDate)("joinedDate $id", (v) => {
    expect(formatInviteJoinedDate(v.year, v.month, v.day)).toBe(v.expected);
  });

  it("normalization is idempotent", () => {
    for (const v of vectors.normalize) {
      const once = normalizeInviteCode(v.raw, (v as { length?: number }).length);
      expect(normalizeInviteCode(once, (v as { length?: number }).length)).toBe(once);
    }
  });
});
