// @vitest-environment happy-dom
import { h } from "vue";
import FlareScreen from "../layout/FlareScreen.vue";
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareSettingsList from "./FlareSettingsList.vue";

describe("FlareSettingsList groups", () => {
  it("omits empty sections and names each remaining group with its heading", () => {
    const host = mount(FlareSettingsList, { props: { sections: [
      { title: "Empty", items: [] },
      { title: "Account", items: [{ key: "name", label: "Name" }] },
    ] } });
    expect(host.findAll("h2").map(el => el.text())).toEqual(["Account"]);
    expect(host.get('[role="group"]').attributes("aria-labelledby")).toBe(host.get("h2").attributes("id"));
    host.unmount();
  });

  it("retains a section's explanation even when it has no available rows", () => {
    const host = mount(FlareSettingsList, { props: { sections: [{ items: [], footer: "No choices are available." }] } });
    expect(host.get('.flare-settings__footer').text()).toBe("No choices are available.");
    expect(host.find('.flare-settings__group').exists()).toBe(false);
    host.unmount();
  });

  it("keeps heading IDs distinct across lists on the same page", () => {
    const props = { sections: [{ title: "Account", items: [{ key: "name", label: "Name" }] }] };
    const page = mount({ components: { FlareSettingsList }, data: () => ({ props }), template: '<div><FlareSettingsList v-bind="props" /><FlareSettingsList v-bind="props" /></div>' });
    const ids = page.findAll('h2').map(el => el.attributes('id'));
    expect(new Set(ids).size).toBe(2);
    page.unmount();
  });

  it("keeps selected choices and read-only rows on their existing action contracts", async () => {
    const current = { key: "system", label: "System", kind: "action" as const, current: true };
    const host = mount(FlareSettingsList, { props: { surface: "flush", sections: [{ items: [current, { key: "id", label: "ID", kind: "value" }] }] } });
    expect(host.get('button[aria-current="true"]').text()).toBe("System");
    await host.get('button').trigger('click');
    expect(host.emitted('select')).toEqual([[current]]);
    expect(host.findAll('button')).toHaveLength(1);
    host.unmount();
  });
});

it("omits a duplicate page heading while retaining the accessible group name and row intents", async () => {
  const row = { key: "remark", label: "Remark", kind: "navigation" as const };
  const host = mount(FlareScreen, { props: { title: "Profile", layout: "detail" }, slots: { default: () => h(FlareSettingsList, { sections: [{ title: "Profile", items: [row] }] }) } });
  expect(host.findAll("h1,h2").map(el => el.text())).toEqual(["Profile"]);
  const group = host.get('[role="group"]');
  expect(group.attributes("aria-label")).toBe("Profile");
  expect(group.attributes("aria-labelledby")).toBeUndefined();
  await host.get(".flare-settings__row").trigger("click");
  expect(host.getComponent(FlareSettingsList).emitted("select")).toEqual([[row]]);
  host.unmount();
});
