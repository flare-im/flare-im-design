import { describe, expect, it } from "vitest";
import { FlareChartCard, FlareEmptyState } from "./admin";
import ChartCard from "./components/data/FlareChartCard.vue";
import EmptyState from "./components/general/FlareEmptyState.vue";
import { FlareDescriptionList, FlareMetricTile, FlarePluginDetailSheet, FlarePluginForm, FlarePluginView } from "./admin";
import DescriptionList from "./components/data/FlareDescriptionList.vue";
import MetricTile from "./components/data/FlareMetricTile.vue";
import PluginView from "./components/messages/FlarePluginView.vue";
import PluginForm from "./components/form/FlarePluginForm.vue";
import PluginDetailSheet from "./components/messages/FlarePluginDetailSheet.vue";
import { FlareAdminInheritField, FlareCodeBlock, FlareTag } from "./admin";
import AdminInheritField from "./components/form/FlareAdminInheritField.vue";
import CodeBlock from "./components/data/FlareCodeBlock.vue";
import Tag from "./components/general/FlareTag.vue";
import { FlarePluginBundleHost } from "./admin";
import PluginBundleHost from "./components/plugin/FlarePluginBundleHost.vue";

describe("focused admin data states", () => {
  it("exports the existing chart without a separate dashboard implementation", () => {
    expect(FlareChartCard).toBe(ChartCard);
  });
  it("exports the existing empty state without a host-only variant", () => {
    expect(FlareEmptyState).toBe(EmptyState);
  });
  it("exports the description list and metric tile without importing the chat graph", () => {
    expect(FlareDescriptionList).toBe(DescriptionList);
    expect(FlareMetricTile).toBe(MetricTile);
  });
  it("exports the plugin view, form and detail sheet for plugin admin pages", () => {
    expect(FlarePluginView).toBe(PluginView);
    expect(FlarePluginForm).toBe(PluginForm);
    expect(FlarePluginDetailSheet).toBe(PluginDetailSheet);
  });
  it("exports the tag, code block and inherit field without the chat graph", () => {
    expect(FlareTag).toBe(Tag);
    expect(FlareCodeBlock).toBe(CodeBlock);
    expect(FlareAdminInheritField).toBe(AdminInheritField);
  });
  it("exports the plugin web bundle host for a review preview", () => {
    expect(FlarePluginBundleHost).toBe(PluginBundleHost);
  });
});
