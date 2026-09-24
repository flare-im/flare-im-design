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

  // 工具条挂着 = 多选这层活着:它自己收 Escape。但只在宿主真的听 @exit 时 —— 没人听的工具条
  // 既不吞键也不认领返回,不会变成键盘陷阱。
  it("owns Escape while a host listens for exit, and stays silent otherwise", () => {
    const escape = () => {
      const event = new KeyboardEvent("keydown", { key: "Escape", bubbles: true, cancelable: true });
      window.dispatchEvent(event);
      return event;
    };
    const listened = setup({ selectedIds: ["a"], total: 4, capabilities: everything, onExit: () => undefined });
    expect(escape().defaultPrevented).toBe(true);
    expect(listened.emitted("exit")).toHaveLength(1);
    listened.vm.$.appContext.app.unmount();
    wrappers.splice(0).forEach((wrapper) => wrapper.unmount());

    const silent = setup({ selectedIds: ["a"], total: 4, capabilities: everything });
    expect(escape().defaultPrevented).toBe(false);
    expect(silent.emitted("exit")).toBeUndefined();

    const busy = setup({ selectedIds: ["a"], total: 4, capabilities: everything, busy: true, onExit: () => undefined });
    expect(escape().defaultPrevented).toBe(true);
    expect(busy.emitted("exit")).toBeUndefined();
  });

  // 退出键是这一流里最后一个键(三端原生同序),包在一层能被浮动条钉住的壳里,并把它的快捷键说出来。
  it("keeps the exit key last in the strip, wrapped so the floating bar can pin it", () => {
    const wrapper = setup({ selectedIds: ["a"], total: 4, capabilities: everything, floating: true });
    const last = wrapper.get(".flare-batch-toolbar__actions > :last-child");
    expect(last.classes()).toContain("flare-batch-toolbar__exit");
    const exit = last.get("button");
    expect(exit.attributes("aria-label")).toBe("退出多选");
    expect(exit.attributes("aria-keyshortcuts")).toBe("Escape");
    expect(wrapper.get(".flare-batch-toolbar__meta").attributes("aria-live")).toBe("polite");
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
