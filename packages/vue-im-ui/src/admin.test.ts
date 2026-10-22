import { describe, expect, it } from "vitest";
import { FlareChartCard, FlareEmptyState } from "./admin";
import ChartCard from "./components/data/FlareChartCard.vue";
import EmptyState from "./components/general/FlareEmptyState.vue";
import { FlarePluginDetailSheet, FlarePluginForm, FlarePluginView } from "./admin";
import PluginView from "./components/messages/FlarePluginView.vue";
import PluginForm from "./components/form/FlarePluginForm.vue";
import PluginDetailSheet from "./components/messages/FlarePluginDetailSheet.vue";

describe("focused admin data states", () => {
  it("exports the existing chart without a separate dashboard implementation", () => {
    expect(FlareChartCard).toBe(ChartCard);
  });
  it("exports the existing empty state without a host-only variant", () => {
    expect(FlareEmptyState).toBe(EmptyState);
  });
  it("exports the plugin view, form and detail sheet for plugin admin pages", () => {
    expect(FlarePluginView).toBe(PluginView);
    expect(FlarePluginForm).toBe(PluginForm);
    expect(FlarePluginDetailSheet).toBe(PluginDetailSheet);
  });
});
