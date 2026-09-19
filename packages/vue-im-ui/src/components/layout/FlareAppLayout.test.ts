// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import FlareAppLayout from "./FlareAppLayout.vue";

const slots = { navigation: "Rail", primary: "Conversations", default: "Chat", content: "Chat", detail: "Group details" };

/** happy-dom lays nothing out: give the layout's parent a width and the rail its 72 px. */
function stubWidths(container: number): void {
  Object.defineProperty(HTMLElement.prototype, "clientWidth", { configurable: true, get() { return container; } });
  Object.defineProperty(HTMLElement.prototype, "offsetWidth", { configurable: true, get() { return 72; } });
}
afterEach(() => {
  delete (HTMLElement.prototype as unknown as Record<string, unknown>).clientWidth;
  delete (HTMLElement.prototype as unknown as Record<string, unknown>).offsetWidth;
});

describe("FlareAppLayout", () => {
  it("shows one pane at a time with the rail when the list and a usable chat do not fit", async () => {
    stubWidths(700);
    const wrapper = mount(FlareAppLayout, {
      props: { paneMode: "dualPane", activePane: "primary" },
      slots,
      attachTo: document.body,
    });
    await wrapper.vm.$nextTick();
    const root = wrapper.get(".flare-app-layout");
    // On its own the layout is its own shell: 700 is a tablet.
    expect(root.attributes("data-responsive-mode")).toBe("tablet");
    expect(root.attributes("data-pane-mode")).toBe("singlePane");
    expect(wrapper.find(".flare-app-layout__navigation").exists()).toBe(true);
    expect(wrapper.text()).toContain("Conversations");
    expect(wrapper.text()).not.toContain("Chat");
    expect(wrapper.emitted("layoutChange")?.at(-1)).toEqual([{ paneMode: "singlePane", detailMode: "hidden" }]);
    await wrapper.setProps({ activePane: "content" });
    expect(wrapper.text()).toContain("Chat");
    expect(wrapper.text()).not.toContain("Conversations");
    wrapper.unmount();
  });

  it("keeps the list beside the chat once the chat gets its minimum width", async () => {
    stubWidths(752);
    const wrapper = mount(FlareAppLayout, {
      props: { paneMode: "dualPane", activePane: "primary" },
      slots,
      attachTo: document.body,
    });
    await wrapper.vm.$nextTick();
    expect(wrapper.get(".flare-app-layout").attributes("data-pane-mode")).toBe("dualPane");
    expect(wrapper.text()).toContain("Conversations");
    expect(wrapper.text()).toContain("Chat");
    expect(wrapper.emitted("layoutChange")?.at(-1)).toEqual([{ paneMode: "dualPane", detailMode: "hidden" }]);
    wrapper.unmount();
  });

  it("opens a requested inline detail as an overlay on tablet, whose grid has no detail column", async () => {
    stubWidths(800);
    const wrapper = mount(FlareAppLayout, {
      props: { paneMode: "triplePane", detailMode: "inline", hasDetail: true },
      slots,
      attachTo: document.body,
    });
    await wrapper.vm.$nextTick();
    const root = wrapper.get(".flare-app-layout");
    expect(root.attributes("data-pane-mode")).toBe("dualPane");
    expect(root.attributes("data-detail-mode")).toBe("overlay");
    expect(wrapper.find(".flare-app-layout__detail").exists()).toBe(false);
    expect(wrapper.get(".flare-app-layout__detail-overlay").text()).toContain("Group details");
  });
});
