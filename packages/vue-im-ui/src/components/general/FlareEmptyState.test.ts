// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { h } from "vue";
import { describe, expect, it, vi } from "vitest";
import FlareEmptyState from "./FlareEmptyState.vue";

describe("empty state host actions", () => {
  it("preserves nested keyboard activation without activating the placeholder", async () => {
    const action = vi.fn();
    const wrapper = mount(FlareEmptyState, {
      props: { title: "No conversation", onTap: () => {} },
      slots: { actions: () => h("button", { onClick: action }, "Create conversation") },
    });
    const event = new KeyboardEvent("keydown", { key: "Enter", bubbles: true, cancelable: true });
    wrapper.get("button").element.dispatchEvent(event);
    expect(event.defaultPrevented).toBe(false);
    await wrapper.get("button").trigger("click");
    expect(action).toHaveBeenCalledOnce();
    expect(wrapper.emitted("tap")).toBeUndefined();
    await wrapper.trigger("keydown", { key: "Enter" });
    expect(wrapper.emitted("tap")).toHaveLength(1);
    wrapper.unmount();
  });
});
