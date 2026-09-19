// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareConversationList from "./FlareConversationList.vue";

const item = (index: number) => ({ id: `c-${index}`, title: `Conversation ${index}`, preview: "Message", time: "now" });

function mountList(items: ReturnType<typeof item>[], props: Record<string, unknown> = {}) {
  const host = mount(defineComponent({ setup() {
    useFlareI18nProvider("en-US");
    return () => h(FlareConversationList as Component, { items, ...props }, { item: () => h("div", { "data-row": "" }, "row") });
  } }));
  return host.findComponent(FlareConversationList);
}

describe("FlareConversationList virtualization", () => {
  it("keeps short lists complete", () => {
    const wrapper = mountList(Array.from({ length: 10 }, (_, index) => item(index)));
    expect(wrapper.findAll("[data-row]")).toHaveLength(10);
  });

  it("bounds a 1k item DOM window", () => {
    const wrapper = mountList(Array.from({ length: 1000 }, (_, index) => item(index)), { overscan: 8 });
    expect(wrapper.findAll("[data-row]").length).toBeLessThanOrEqual(16);
    expect(wrapper.find("[aria-hidden=true]").exists()).toBe(true);
  });

  it("keeps the same DOM bound for 10k conversations", () => {
    const wrapper = mountList(Array.from({ length: 10000 }, (_, index) => item(index)), { overscan: 8 });
    expect(wrapper.findAll("[data-row]").length).toBeLessThanOrEqual(16);
    expect(wrapper.find("[aria-hidden=true]").exists()).toBe(true);
  });

  it("renders conversations in host order", () => {
    const rows = [item(1), { ...item(2), pinned: true }, item(3)];
    const host = mount(defineComponent({ setup() {
      useFlareI18nProvider("en-US");
      return () => h(FlareConversationList as Component, { items: rows }, { item: ({ item: row }: { item: { id: string } }) => h("div", { "data-row": row.id }) });
    } }));
    expect(host.findAll("[data-row]").map((node) => node.attributes("data-row"))).toEqual(["c-1", "c-2", "c-3"]);
  });

  it("keeps window spacers out of flex shrinking", () => {
    const wrapper = mountList(Array.from({ length: 1000 }, (_, index) => item(index)), { overscan: 8 });
    expect(wrapper.findAll(".im-conv-list__spacer").length).toBeGreaterThan(0);
  });

  it("renders package-owned section labels without changing row slots", () => {
    const wrapper = mountList([], {
      sections: [
        { id: "pinned", label: "Pinned", items: [item(1)] },
        { id: "all", label: "All", items: [item(2), item(3)] },
      ],
    });
    expect(wrapper.findAll("[data-row]")).toHaveLength(3);
    expect(wrapper.findAll(".im-conv-list__section").map((node) => node.text())).toEqual(["Pinned", "All"]);
  });
});
