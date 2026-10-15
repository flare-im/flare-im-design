import { describe, expect, it } from "vitest";
import { FlareChartCard, FlareEmptyState } from "./admin";
import ChartCard from "./components/data/FlareChartCard.vue";
import EmptyState from "./components/general/FlareEmptyState.vue";

describe("focused admin data states", () => {
  it("exports the existing chart without a separate dashboard implementation", () => {
    expect(FlareChartCard).toBe(ChartCard);
  });
  it("exports the existing empty state without a host-only variant", () => {
    expect(FlareEmptyState).toBe(EmptyState);
  });
});
