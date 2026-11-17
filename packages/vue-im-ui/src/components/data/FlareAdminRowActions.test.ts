// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, nextTick } from "vue";
import { NButton, NDropdown } from "naive-ui";
import FlareAdminRowActions from "./FlareAdminRowActions.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";

const hosts: ReturnType<typeof mount>[] = [];
afterEach(() => {
  hosts.splice(0).forEach((host) => host.unmount());
  document.body.innerHTML = "";
});
function actions(count: number, extra: Record<string, unknown> = {}) {
  return Array.from({ length: count }, (_, index) => ({
    key: `a${index + 1}`,
    label: `Action ${index + 1}`,
    ...(index === 1 ? extra : {}),
  }));
}
function setup(props: Record<string, unknown>) {
  const host = mount(
    defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () => h(FlareAdminRowActions as never, props);
      },
    }),
    { attachTo: document.body },
  );
  hosts.push(host);
  return { host, list: host.findComponent(FlareAdminRowActions) };
}

describe("FlareAdminRowActions", () => {
  it("three actions stay inline", () => {
    const { list } = setup({ actions: actions(3), max: 3 });
    expect(list.findAllComponents(NButton)).toHaveLength(3);
    expect(list.findComponent(NDropdown).exists()).toBe(false);
    expect(list.text()).not.toContain("更多");
  });
  it("extra actions collapse into more", () => {
    const { list } = setup({ actions: actions(5), max: 3 });
    const inline = list.findAll("[data-row-action]");
    expect(inline).toHaveLength(2);
    const menu = list.findComponent(NDropdown);
    expect(menu.exists()).toBe(true);
    expect(menu.props("options")).toHaveLength(3);
    expect(list.text()).toContain("更多");
  });
  it("danger action is marked", () => {
    const { list } = setup({ actions: actions(3, { danger: true }) });
    const marked = list.findAll(".flare-admin-row-actions__danger");
    expect(marked).toHaveLength(1);
    expect(marked[0].text()).toBe("Action 2");
  });
  it("the more trigger is a menu button that says whose actions it holds", async () => {
    const { list } = setup({ actions: actions(5), label: "Order 42" });
    const trigger = list.get("[data-row-action-more]");
    expect(trigger.attributes("aria-haspopup")).toBe("menu");
    expect(trigger.attributes("aria-expanded")).toBe("false");
    // The visible word stays inside the name.
    expect(trigger.attributes("aria-label")).toBe("「Order 42」的更多操作");
    list.findComponent(NDropdown).vm.$emit("update:show", true);
    await nextTick();
    expect(list.get("[data-row-action-more]").attributes("aria-expanded")).toBe("true");
    list.findComponent(NDropdown).vm.$emit("update:show", false);
    await nextTick();
    expect(list.get("[data-row-action-more]").attributes("aria-expanded")).toBe("false");
    // Without a row name the visible word names it.
    const { list: plain } = setup({ actions: actions(5) });
    expect(plain.get("[data-row-action-more]").attributes("aria-label")).toBeUndefined();
  });
  it("an action in flight spins where it is drawn", () => {
    const inline = setup({ actions: actions(5, { loading: true }) }).list;
    expect(inline.findAllComponents(NButton)[1].props("loading")).toBe(true);
    expect(inline.findAllComponents(NButton)[0].props("loading")).toBeFalsy();
    const more = inline.findAllComponents(NButton).find((key) => key.attributes("data-row-action-more") !== undefined)!;
    expect(more.props("loading")).toBe(false);
    // In the menu, "more" spins and is not opened meanwhile.
    const folded = setup({
      actions: actions(5).map((action, index) => (index === 3 ? { ...action, loading: true } : action)),
    }).list;
    const busy = folded.findAllComponents(NButton).find((key) => key.attributes("data-row-action-more") !== undefined)!;
    expect(busy.props("loading")).toBe(true);
    expect(busy.attributes("disabled")).toBeDefined();
    expect(folded.findComponent(NDropdown).props("disabled")).toBe(true);
  });
  it("a menu of disabled actions is not offered", () => {
    const { list } = setup({
      actions: actions(5).map((action, index) => (index >= 2 ? { ...action, disabled: true } : action)),
    });
    expect(list.get("[data-row-action-more]").attributes("disabled")).toBeDefined();
    const open = setup({ actions: actions(5) }).list;
    expect(open.get("[data-row-action-more]").attributes("disabled")).toBeUndefined();
  });
  it("select emits key", async () => {
    const { list } = setup({ actions: actions(5) });
    await list.get('[data-row-action="a1"]').trigger("click");
    list.findComponent(NDropdown).vm.$emit("select", "a4");
    expect(list.emitted("select")).toEqual([["a1"], ["a4"]]);
  });
});
