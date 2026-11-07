// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { NButton, NPopover } from "naive-ui";
import FlareAdminHelp from "./FlareAdminHelp.vue";

describe("FlareAdminHelp", () => {
  it("keeps genuine Native help and bounds its virtual anchor inside a narrow viewport", async () => {
    vi.stubGlobal("innerWidth", 320);
    const host = mount(FlareAdminHelp, {
      attachTo: document.body,
      props: { label: "List help" },
      slots: { default: "Long read-only help" },
    });
    const button = host.findComponent(NButton);
    vi.spyOn(button.element, "getBoundingClientRect").mockReturnValue(
      new DOMRect(136, 208, 72, 32),
    );
    await button.trigger("click");
    const popover = host.findComponent(NPopover);
    expect(popover.props("width")).toBe(296);
    expect(popover.props("x")).toBe(160);
    expect(popover.props("y")).toBe(240);
    expect(popover.props("placement")).toBe("bottom");
    expect(button.props("size")).toBe("small");
    expect(host.find("input").exists()).toBe(false);
    host.unmount();
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });
  it("repositions on resize and releases only its own read-only listeners", async () => {
    vi.stubGlobal("innerWidth", 390);
    const remove = vi.spyOn(window, "removeEventListener");
    const host = mount(FlareAdminHelp, {
      attachTo: document.body,
      props: { label: "Help" },
    });
    const button = host.findComponent(NButton);
    vi.spyOn(button.element, "getBoundingClientRect").mockReturnValue(
      new DOMRect(290, 200, 60, 32),
    );
    await button.trigger("click");
    expect(host.findComponent(NPopover).props("x")).toBe(218);
    vi.stubGlobal("innerWidth", 320);
    window.dispatchEvent(new Event("resize"));
    await host.vm.$nextTick();
    expect(host.findComponent(NPopover).props("x")).toBe(160);
    host.unmount();
    expect(remove).toHaveBeenCalledWith("resize", expect.any(Function));
    expect(remove).toHaveBeenCalledWith("scroll", expect.any(Function), true);
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });
});
