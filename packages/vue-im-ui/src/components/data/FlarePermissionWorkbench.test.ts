// @vitest-environment happy-dom
import { afterEach, describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { NButton, NCheckbox, NInput, NRadioGroup } from "naive-ui";
import FlarePermissionWorkbench from "./FlarePermissionWorkbench.vue";
import source from "./FlarePermissionWorkbench.vue?raw";
import {
  filterPermissionWorkbench,
  permissionWorkbenchChanges,
  permissionWorkbenchItems,
  togglePermissionWorkbench,
  type FlarePermissionGroup,
} from "./permission-workbench";
const groups: FlarePermissionGroup[] = [
  {
    key: "im",
    label: "IM operations",
    menus: [
      {
        key: "users",
        label: "Users",
        actions: [
          { key: "create", label: "Create user" },
          { key: "freeze", label: "Freeze user" },
        ],
      },
    ],
  },
  {
    key: "access",
    label: "Access",
    menus: [
      {
        key: "staff",
        label: "Employees",
        disabled: true,
        actions: [{ key: "staff-create", label: "Create employee" }],
      },
    ],
  },
];
const hosts: ReturnType<typeof mount>[] = [];
afterEach(() => hosts.splice(0).forEach((host) => host.unmount()));
function surface(props = {}) {
  const host = mount(FlarePermissionWorkbench, {
    props: { groups, checkedKeys: [], baselineKeys: [], ...props },
  });
  hosts.push(host);
  return host;
}
describe("permission workbench", () => {
  it("uses genuine Naive controls with menus collapsed and directories never selectable", () => {
    const host = surface();
    expect(host.findComponent(NInput).exists()).toBe(true);
    expect(host.findAllComponents(NCheckbox)).toHaveLength(1);
    expect(host.findComponent(NCheckbox).text()).toBe("Users");
    expect(host.get("[aria-expanded]").attributes("aria-expanded")).toBe(
      "false",
    );
    expect(host.find(".flare-permission-workbench__actions").exists()).toBe(
      false,
    );
  });
  it("opens only requested buttons and emits one explicit key, never a parent or sibling grant", async () => {
    const host = surface();
    await host.get("[aria-expanded]").trigger("click");
    expect(host.findAllComponents(NCheckbox)).toHaveLength(3);
    host.findAllComponents(NCheckbox)[1].vm.$emit("update:checked", true);
    expect(host.emitted("update:checkedKeys")).toEqual([[["create"]]]);
    expect(host.emitted("reset")).toBeUndefined();
  });
  it("keeps disabled menus and their buttons immutable even on late toggle callbacks", async () => {
    const host = surface({ disabled: true });
    host.findComponent(NCheckbox).vm.$emit("update:checked", true);
    expect(host.emitted("update:checkedKeys")).toBeUndefined();
    expect(togglePermissionWorkbench(groups, [], "staff-create", true)).toEqual(
      [],
    );
    expect(
      togglePermissionWorkbench(groups, [], "not-registered", true),
    ).toEqual([]);
  });
  it("exposes unavailable menus and buttons as disabled to assistive technology", async () => {
    const host = surface({ disabled: true });
    await host.get("[aria-expanded]").trigger("click");
    expect(host.findAll('[role="checkbox"]')).toHaveLength(3);
    for (const checkbox of host.findAll('[role="checkbox"]')) {
      expect(checkbox.attributes("aria-disabled")).toBe("true");
    }
  });
  it("searches across groups and opens matching actions without checking them", async () => {
    const host = surface();
    host.findComponent(NInput).vm.$emit("update:value", "Freeze");
    await host.vm.$nextTick();
    expect(host.findAllComponents(NCheckbox).map((x) => x.text())).toEqual([
      "Users",
      "Freeze user",
    ]);
    expect(host.emitted("update:checkedKeys")).toBeUndefined();
  });
  it("shows empty search/filter states rather than retaining unrelated menus", async () => {
    const host = surface();
    host.findComponent(NInput).vm.$emit("update:value", "not-found");
    await host.vm.$nextTick();
    expect(host.findAllComponents(NCheckbox)).toHaveLength(0);
    expect(host.find(".n-empty").exists()).toBe(true);
    expect(
      host.find(".flare-permission-workbench__mobile-groups").exists(),
    ).toBe(false);
  });
  it("removes a stale phone group label when undo empties the changed filter", async () => {
    const host = surface({ checkedKeys: ["users", "create"] });
    host.findComponent(NRadioGroup).vm.$emit("update:value", "changed");
    await host.vm.$nextTick();
    expect(
      host.find(".flare-permission-workbench__mobile-groups").exists(),
    ).toBe(true);
    await host.setProps({ checkedKeys: [] });
    expect(
      host.find(".flare-permission-workbench__mobile-groups").exists(),
    ).toBe(false);
    expect(host.findAllComponents(NCheckbox)).toHaveLength(0);
    expect(host.emitted("update:checkedKeys")).toBeUndefined();
  });
  it("keeps menu ancestors in selected/changed modes but not unselected sibling buttons", () => {
    const selected = filterPermissionWorkbench(
      groups,
      "",
      "selected",
      ["create"],
      [],
    );
    expect(selected[0].menus[0].key).toBe("users");
    expect(selected[0].menus[0].actions.map((x) => x.key)).toEqual(["create"]);
    const changes = filterPermissionWorkbench(
      groups,
      "",
      "changed",
      ["create"],
      ["freeze"],
    );
    expect(changes[0].menus[0].actions.map((x) => x.key)).toEqual([
      "create",
      "freeze",
    ]);
  });
  it("calculates additions/removals against immutable baseline, not current filter", async () => {
    const host = surface({
      checkedKeys: ["users", "create"],
      baselineKeys: ["users", "freeze"],
    });
    expect(
      permissionWorkbenchChanges(
        groups,
        ["users", "create"],
        ["users", "freeze"],
      ).map((x) => [x.key, x.added]),
    ).toEqual([
      ["create", true],
      ["freeze", false],
    ]);
    host.findComponent(NInput).vm.$emit("update:value", "not-found");
    await host.vm.$nextTick();
    expect(host.get(".flare-permission-workbench__summary").text()).toContain(
      "Create user",
    );
    expect(host.get(".flare-permission-workbench__summary").text()).toContain(
      "Freeze user",
    );
  });
  it("reset is an explicit host event and never silently drops unknown/partial grants", async () => {
    const reset = vi.fn();
    const host = surface({ checkedKeys: ["users"], onReset: reset });
    const button = host
      .findAllComponents(NButton)
      .find((x) => x.text().includes("撤销") || x.text().includes("Undo"))!;
    await button.trigger("click");
    expect(reset).toHaveBeenCalledOnce();
    expect(host.emitted("update:checkedKeys")).toBeUndefined();
  });
  it("counts only selectable menus/buttons and labels standalone actions correctly", () => {
    const list = permissionWorkbenchItems([
      {
        key: "other",
        label: "Other",
        menus: [
          { key: "action", label: "Collect", kind: "button", actions: [] },
        ],
      },
    ]);
    expect(list).toHaveLength(1);
    expect(list[0].kind).toBe("button");
    expect(permissionWorkbenchItems(groups)).toHaveLength(5);
  });
  it("display filter and group navigation are read-only UI changes", async () => {
    const host = surface();
    host.findComponent(NRadioGroup).vm.$emit("update:value", "changed");
    await host.vm.$nextTick();
    expect(host.findAllComponents(NCheckbox)).toHaveLength(0);
    expect(host.emitted("update:checkedKeys")).toBeUndefined();
  });
  it("uses bounded local scroll and phone group selection without a second save bar", () => {
    expect(source).toContain("max-height: 65dvh");
    expect(source).toContain(
      "grid-template-columns: 148px minmax(0, 1fr) 190px",
    );
    expect(source).toContain("grid-template-columns: minmax(0, 1fr)");
    expect(source).toContain("overflow-wrap: anywhere");
    expect(source).not.toMatch(/fetch\(|localStorage|submitRole|grantRole/);
  });
});
