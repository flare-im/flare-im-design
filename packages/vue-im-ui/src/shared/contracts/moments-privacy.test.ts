import { describe, expect, it } from "vitest";
import vocabulary from "../../../../../spec/moments-privacy.json";
import {
  flareMomentAudienceApplies,
  flareMomentAudienceModes,
  flareMomentHistoryRanges,
  flareMomentVisibilities,
} from "./moments";

// FR-100: moments privacy in words, not SDK codes. The five apps mapped numbers at every call site;
// `spec/moments-privacy.json` is the vocabulary now, and all four kits read it.

describe("moments privacy vocabulary", () => {
  it("is the shared list", () => {
    expect([...flareMomentVisibilities]).toEqual(vocabulary.visibility);
    expect([...flareMomentAudienceModes]).toEqual(vocabulary.audienceMode);
    expect([...flareMomentHistoryRanges]).toEqual(vocabulary.historyRange);
  });

  it("keeps a list only where someone can see the moment", () => {
    expect(flareMomentVisibilities.filter(flareMomentAudienceApplies)).toEqual(["friends", "public"]);
  });

  it("records what the reference apps used to send, so a host can check its own mapping", () => {
    expect(Object.values(vocabulary.legacyCodes.visibility)).toEqual(vocabulary.visibility);
    expect(Object.values(vocabulary.legacyCodes.audienceMode)).toEqual(vocabulary.audienceMode);
    expect(Object.values(vocabulary.legacyCodes.historyRange)).toEqual(vocabulary.historyRange);
  });
});
