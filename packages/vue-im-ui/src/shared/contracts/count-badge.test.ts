// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import FlareFilterTabs from "../../components/general/FlareFilterTabs.vue";
import FlareAdaptiveNavigation from "../../components/layout/FlareAdaptiveNavigation.vue";
import FlareSettingsRow from "../../components/profile/FlareSettingsRow.vue";
import type { FlareNavigationGroup } from "./application";
import { flareCountBadgeDrawn, flareCountBadgeText } from "./count-badge";

type Case = { id: string; count?: number; more?: boolean; text: string; drawn: boolean };
const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/count-badge-vectors.json"), "utf8")) as {
  cap: number;
  overflow: string;
  cases: Case[];
};

afterEach(() => {
  document.body.innerHTML = "";
});

/**
 * The shared count badge table (spec/count-badge-vectors.json): what a navigation item's count badge, a filter tab's
 * badge and a settings row's badge read, and when a filter tab and a settings row draw one.
 */
describe("count badges (spec/count-badge-vectors.json)", () => {
  it("keeps every case the other kits run", () => {
    expect(vectors.cases.length).toBeGreaterThanOrEqual(14);
    expect(vectors.cap).toBe(99);
    expect(vectors.overflow).toBe("99+");
  });

  it.each(vectors.cases.map((v) => [v.id, v] as const))("%s", (_, v) => {
    expect(flareCountBadgeText(v.count, v.more)).toBe(v.text);
    expect(flareCountBadgeDrawn(v.count, v.more)).toBe(v.drawn);
  });

  it.each(vectors.cases.map((v) => [v.id, v] as const))("a filter tab and a settings row draw %s", (_, v) => {
    const tabs = mount(FlareFilterTabs, {
      props: { options: [{ value: "requests", label: "申请", badge: v.count, badgeMore: v.more }], modelValue: "requests" },
    });
    const tab = tabs.find(".flare-filter-tab__badge");
    expect(tab.exists()).toBe(v.drawn);
    if (v.drawn) expect(tab.text()).toBe(v.text);
    tabs.unmount();

    const row = mount(FlareSettingsRow, {
      props: { item: { key: "requests", label: "新的朋友", kind: "navigation" as const, badge: v.count, badgeMore: v.more } },
    });
    const badge = row.find(".flare-settings__badge");
    expect(badge.exists()).toBe(v.drawn);
    if (v.drawn) expect(badge.text()).toBe(v.text);
    row.unmount();
  });

  it.each(vectors.cases.map((v) => [v.id, v] as const))("a navigation item's count badge reads %s", (_, v) => {
    const groups: readonly FlareNavigationGroup[] = [
      { id: "primary", items: [{ id: "contacts", label: "Contacts", icon: "people", badge: { kind: "count", count: v.count, more: v.more } }] },
    ];
    const navigation = mount(FlareAdaptiveNavigation, {
      attachTo: document.body,
      props: { groups, activeId: "contacts", responsiveMode: "desktop", presentation: "rail", label: "navigation" },
    });
    expect(navigation.get(".flare-adaptive-navigation__badge").text()).toBe(v.text);
    navigation.unmount();
  });
});
