// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareResponsiveLayout from "./FlareResponsiveLayout.vue";

const slots = { list: "Conversations", chat: "Chat", detail: "Group details" };

/** happy-dom lays nothing out: give the layout its width. */
function stubWidth(width: number): void {
  Object.defineProperty(HTMLElement.prototype, "clientWidth", { configurable: true, get() { return width; } });
}
afterEach(() => {
  delete (HTMLElement.prototype as unknown as Record<string, unknown>).clientWidth;
});

async function mountAt(width: number, props: Record<string, unknown> = {}) {
  stubWidth(width);
  const reports: unknown[] = [];
  const wrapper = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareResponsiveLayout as Component, {
        activePane: "chat", ...props, onLayoutChange: (layout: unknown) => reports.push(layout),
      }, { list: () => slots.list, chat: () => slots.chat, detail: () => slots.detail });
    },
  }), { attachTo: document.body });
  await wrapper.vm.$nextTick();
  return Object.assign(wrapper, { reports });
}

// The same rule as AppLayout (spec/application-layout-vectors.json `panes`): a 320 list beside a 360 chat.
describe("FlareResponsiveLayout", () => {
  it("shows one pane below a list and a usable chat, and says so", async () => {
    const wrapper = await mountAt(679, { hasDetail: true });
    expect(wrapper.get(".flare-rl").attributes("data-pane-mode")).toBe("singlePane");
    expect(wrapper.text()).toContain("Chat");
    expect(wrapper.text()).not.toContain("Conversations");
    expect(wrapper.reports).toEqual([{ paneMode: "singlePane", detailMode: "route" }]);
    wrapper.unmount();
  });

  it("puts the list beside the chat from 680, where the old 720 floor kept one pane", async () => {
    const wrapper = await mountAt(680);
    expect(wrapper.get(".flare-rl").attributes("data-pane-mode")).toBe("dualPane");
    expect(wrapper.text()).toContain("Conversations");
    expect(wrapper.text()).toContain("Chat");
    expect(wrapper.reports).toEqual([{ paneMode: "dualPane", detailMode: "hidden" }]);
    wrapper.unmount();
  });

  it("adds the detail inline once it fits beside a usable chat, from 980", async () => {
    const two = await mountAt(979, { hasDetail: true });
    expect(two.get(".flare-rl").attributes("data-pane-mode")).toBe("dualPane");
    expect(two.find(".flare-rl__detail").exists()).toBe(false);
    two.unmount();
    const three = await mountAt(980, { hasDetail: true });
    expect(three.get(".flare-rl").attributes("data-pane-mode")).toBe("triplePane");
    expect(three.get(".flare-rl__detail").text()).toContain("Group details");
    expect(three.reports).toEqual([{ paneMode: "triplePane", detailMode: "inline" }]);
    three.unmount();
  });

  it("grows only the chat with the text", async () => {
    const wrapper = await mountAt(1039, { textScale: 2 });
    expect(wrapper.get(".flare-rl").attributes("data-pane-mode")).toBe("singlePane");
    wrapper.unmount();
    const wide = await mountAt(1040, { textScale: 2 });
    expect(wide.get(".flare-rl").attributes("data-pane-mode")).toBe("dualPane");
    wide.unmount();
  });
});
