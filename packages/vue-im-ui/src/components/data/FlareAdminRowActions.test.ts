// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h } from "vue";
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
  it("select emits key", async () => {
    const { list } = setup({ actions: actions(5) });
    await list.get('[data-row-action="a1"]').trigger("click");
    list.findComponent(NDropdown).vm.$emit("select", "a4");
    expect(list.emitted("select")).toEqual([["a1"], ["a4"]]);
  });
});
