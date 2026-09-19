// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { mount } from "@vue/test-utils";
import FlareMessageBatchToolbar from "./FlareMessageBatchToolbar.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";

const wrappers: ReturnType<typeof mount>[] = [];

function setup(props: Record<string, unknown> = {}) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareMessageBatchToolbar as Component, props);
    },
  }), { attachTo: document.body });
  wrappers.push(host);
  return host.findComponent(FlareMessageBatchToolbar);
}

const everything = { forwardEach: true, forwardMerged: true, pin: true, pinSelf: true, delete: true };

afterEach(() => wrappers.splice(0).forEach(wrapper => wrapper.unmount()));

describe("FlareMessageBatchToolbar", () => {
  it("owns the floating presentation and draws the actions the host declares, in the contract's order", () => {
    const wrapper = setup({ selectedIds: ["a", "b"], total: 4, floating: true, capabilities: everything });

    expect(wrapper.classes()).toContain("flare-batch-toolbar--floating");
    expect(wrapper.findAll(".flare-batch-toolbar__actions .flare-batch-btn").slice(2, -1).map((b) => b.attributes("aria-label")))
      .toEqual(["逐条转发", "合并转发", "置顶", "仅自己置顶", "删除"]);

    const fewer = setup({ selectedIds: ["a"], total: 4, capabilities: { forwardEach: true, delete: true } });
    expect(fewer.text()).not.toContain("置顶");
    expect(fewer.text()).not.toContain("合并转发");
  });

  it("reports one action with the ids it was given", async () => {
    const wrapper = setup({ selectedIds: ["a", "b"], total: 4, capabilities: everything });

    await wrapper.get('[aria-label="置顶"]').trigger("click");
    await wrapper.get('[aria-label="合并转发"]').trigger("click");
    expect(wrapper.emitted("action")).toEqual([
      [{ action: "pin", ids: ["a", "b"] }],
      [{ action: "forwardMerged", ids: ["a", "b"] }],
    ]);
    expect(wrapper.emitted("pin")).toBeUndefined();
  });

  it("keeps selecting and clearing the selection separate from the actions", async () => {
    const wrapper = setup({ selectedIds: ["a"], total: 4, capabilities: everything });
    await wrapper.get('[aria-label="全选"]').trigger("click");
    await wrapper.get('[aria-label="清除选择"]').trigger("click");
    await wrapper.get('[aria-label="退出多选"]').trigger("click");
    expect(wrapper.emitted("selectAll")).toHaveLength(1);
    expect(wrapper.emitted("clearSelection")).toHaveLength(1);
    expect(wrapper.emitted("exit")).toHaveLength(1);
    expect(wrapper.emitted("action")).toBeUndefined();
  });

  it("disables what the selection or a running batch does not allow, and still draws it", () => {
    const one = setup({ selectedIds: ["a"], total: 4, capabilities: everything });
    expect(one.get('[aria-label="合并转发"]').attributes("disabled")).toBeDefined();
    expect(one.get('[aria-label="逐条转发"]').attributes("disabled")).toBeUndefined();

    const busy = setup({ selectedIds: ["a", "b"], total: 4, busy: true, capabilities: everything });
    for (const label of ["逐条转发", "合并转发", "置顶", "仅自己置顶", "删除", "全选", "清除选择", "退出多选"]) {
      expect(busy.get(`[aria-label="${label}"]`).attributes("disabled"), label).toBeDefined();
    }

    const empty = setup({ selectedIds: [], total: 0, capabilities: everything });
    expect(empty.get('[aria-label="全选"]').attributes("disabled")).toBeDefined();
    expect(empty.get('[aria-label="删除"]').attributes("disabled")).toBeDefined();
  });
});
