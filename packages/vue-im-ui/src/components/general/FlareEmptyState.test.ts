// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { h } from "vue";
import { describe, expect, it, vi } from "vitest";
import FlareEmptyState from "./FlareEmptyState.vue";

describe("empty state host actions", () => {
  it('names a loading status and keeps an interactive placeholder as a button', async () => {
    const wrapper = mount(FlareEmptyState, { props: { title: 'Loading contacts', loading: true } });
    expect(wrapper.attributes('role')).toBe('status');
    expect(wrapper.attributes('aria-label')).toBe('Loading contacts');
    await wrapper.setProps({ onTap: () => {} });
    expect(wrapper.attributes('role')).toBe('button');
    expect(wrapper.attributes('aria-label')).toBeUndefined();
    wrapper.unmount();
  });

  it('reports the shared retry button once without activating a tappable placeholder', async () => {
    const wrapper = mount(FlareEmptyState, { props: { title: 'Failed', actionText: 'Retry', onTap: () => {} } });
    try {
      await wrapper.get('button').trigger('click');
      expect(wrapper.emitted('action')).toHaveLength(1);
      expect(wrapper.emitted('tap')).toBeUndefined();
    } finally { wrapper.unmount(); }
  });
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

describe("compact empty state (R8 in-block)", () => {
  it("draws compact only when asked", () => {
    const plain = mount(FlareEmptyState, { props: { title: "暂无记录" } });
    expect(plain.classes()).not.toContain("is-compact");
    const compact = mount(FlareEmptyState, { props: { title: "暂无记录", icon: "clock", compact: true } });
    expect(compact.classes()).toContain("is-compact");
    expect(compact.get(".flare-empty__title").text()).toBe("暂无记录");
    plain.unmount();
    compact.unmount();
  });
});
