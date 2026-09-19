// @vitest-environment happy-dom
import { afterEach, describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { h, nextTick } from "vue";
import FlareChatWorkspace from "./FlareChatWorkspace.vue";

afterEach(() => vi.unstubAllGlobals());
describe("canonical chat workspace geometry", () => {
  it("measures the composer, exposes tail spacing and disconnects its observer", async () => {
    let measure = () => {};
    const disconnect = vi.fn();
    vi.stubGlobal("ResizeObserver", class {
      constructor(callback: () => void) { measure = callback; }
      observe() {}
      disconnect = disconnect;
    });
    const wrapper = mount(FlareChatWorkspace, {
      props: { composerPlacement: "overlay", label: "Chat" },
      slots: {
        timeline: ({ bottomInset }: { bottomInset: number }) => h("output", String(bottomInset)),
        composer: () => h("textarea"),
      },
    });
    await nextTick();
    const composer = wrapper.get(".flare-chat-workspace__composer").element;
    vi.spyOn(composer, "getBoundingClientRect").mockReturnValue({ height: 200 } as DOMRect);
    measure();
    await nextTick();
    expect(wrapper.attributes("style")).toContain("--flare-workspace-composer-height: 200px");
    expect(wrapper.get("output").text()).toBe("36");
    await wrapper.setProps({ selectionMode: true });
    expect(wrapper.get("output").text()).toBe("84");
    wrapper.unmount();
    expect(disconnect).toHaveBeenCalled();
  });
  it("does not reserve a phantom composer for a timeline-only workspace", () => {
    const wrapper = mount(FlareChatWorkspace, { slots: { timeline: "Empty" } });
    expect(wrapper.find(".flare-chat-workspace__composer").exists()).toBe(false);
    expect(wrapper.attributes("style")).toContain("0px");
    wrapper.unmount();
  });
});
