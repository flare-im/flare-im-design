// @vitest-environment happy-dom
import { mount, type VueWrapper } from "@vue/test-utils";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { defineComponent, h, nextTick, reactive, type Component } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import FlarePermissionTree from "./FlarePermissionTree.vue";
import type { FlarePermissionNode } from "./permission-tree";

const nodes: FlarePermissionNode[] = [
  {
    code: "users",
    name: "Users",
    children: [
      { code: "users.read", name: "View users" },
      { code: "users.write", name: "Edit users", description: "Rename, freeze" },
      {
        code: "users.admin",
        name: "User administration",
        children: [
          { code: "users.admin.delete", name: "Delete users" },
          { code: "users.admin.export", name: "Export users" },
        ],
      },
    ],
  },
  { code: "groups", name: "Groups", children: [{ code: "groups.read", name: "View groups" }] },
  { code: "billing", name: "Billing" },
];

function mountTree(props: Record<string, unknown> = {}, slots: Record<string, unknown> = {}, locale: "zh-CN" | "en-US" = "en-US") {
  const state = reactive<Record<string, unknown>>({ nodes, ...props });
  const Host = defineComponent({
    setup: () => () => h(FlareUiProvider as Component, { themeMode: "light", locale, layoutMode: "pc" }, {
      default: () => h(FlarePermissionTree as Component, { ...state }, slots),
    }),
  });
  const host = mount(Host, { attachTo: document.body });
  const set = async (patch: Record<string, unknown>) => {
    Object.assign(state, patch);
    await nextTick();
  };
  return { host, tree: host.findComponent(FlarePermissionTree), set };
}
const items = (tree: VueWrapper<unknown>) => tree.findAll("[role=treeitem]");
const codes = (tree: VueWrapper<unknown>) => items(tree).map((item) => item.attributes("data-code"));
const checkedEmits = (tree: VueWrapper<unknown>) => tree.emitted("update:checkedCodes") as string[][][] | undefined;

afterEach(() => {
  document.body.innerHTML = "";
});

describe("FlarePermissionTree", () => {
  it("is a named tree whose items carry level, position and a checked state derived from the leaves", () => {
    const { host, tree } = mountTree({ checkedCodes: ["users.read", "users.admin.delete", "users.admin.export"] });
    expect(tree.get("[role=tree]").attributes("aria-label")).toBe("Permissions");
    expect(codes(tree)).toEqual(["users", "users.read", "users.write", "users.admin", "users.admin.delete", "users.admin.export", "groups", "groups.read", "billing"]);
    const item = (code: string) => tree.get(`[data-code="${code}"]`);
    expect(item("users").attributes("aria-checked")).toBe("mixed");
    expect(item("users").attributes("aria-expanded")).toBe("true");
    expect(item("users").attributes("aria-level")).toBe("1");
    expect(item("users.admin").attributes("aria-checked")).toBe("true");
    expect(item("users.admin.export").attributes()).toMatchObject({ "aria-level": "3", "aria-posinset": "2", "aria-setsize": "2", "aria-checked": "true" });
    expect(item("users.admin.export").attributes("aria-expanded")).toBeUndefined();
    expect(item("billing").attributes("aria-checked")).toBe("false");
    expect(tree.get("[aria-live=polite]").text()).toBe("3 of 6 selected");
    // One tab stop: the first row.
    expect(items(tree).map((entry) => entry.attributes("tabindex"))).toEqual(["0", "-1", "-1", "-1", "-1", "-1", "-1", "-1", "-1"]);
    expect(tree.get('[data-code="users.write"]').text()).toContain("Rename, freeze");
    host.unmount();
  });

  it("toggles a leaf, checks and clears a whole group, and leaves a disabled leaf alone", async () => {
    const { host, tree, set } = mountTree({ checkedCodes: ["groups.read"], disabledCodes: ["users.write"] });
    await tree.get('[data-code="billing"]').trigger("click");
    expect(checkedEmits(tree)?.[0]).toEqual([["groups.read", "billing"]]);
    // Unbound, the tree keeps its own list, so the next change builds on the last one.
    await tree.get('[data-code="users"]').trigger("click");
    expect(checkedEmits(tree)?.[1]).toEqual([["groups.read", "billing", "users.read", "users.admin.delete", "users.admin.export"]]);
    await set({ checkedCodes: ["groups.read", "users.read", "users.admin.delete", "users.admin.export"] });
    // Every enabled leaf is on: the unchecked disabled leaf keeps the group mixed, yet the next
    // activation clears the enabled leaves instead of re-adding them.
    expect(tree.get('[data-code="users"]').attributes("aria-checked")).toBe("mixed");
    await tree.get('[data-code="users"]').trigger("click");
    expect(checkedEmits(tree)?.[2]).toEqual([["groups.read"]]);
    await set({ checkedCodes: ["groups.read", "users.read", "users.admin.delete", "users.admin.export"] });
    await tree.get('[data-code="users.admin"]').trigger("click");
    expect(checkedEmits(tree)?.[3]).toEqual([["groups.read", "users.read"]]);
    expect(tree.get('[data-code="users.write"]').attributes("aria-disabled")).toBe("true");
    await tree.get('[data-code="users.write"]').trigger("click");
    expect(checkedEmits(tree)).toHaveLength(4);
    host.unmount();
  });

  it("shows the state and ignores every toggle when read-only", async () => {
    const { host, tree } = mountTree({ readonly: true, checkedCodes: ["billing"] });
    expect(tree.text()).toContain("View only");
    expect(tree.get('[data-code="billing"]').attributes("aria-checked")).toBe("true");
    await tree.get('[data-code="billing"]').trigger("click");
    await tree.get('[data-code="users"]').trigger("keydown", { key: " " });
    expect(checkedEmits(tree)).toBeUndefined();
    host.unmount();
  });

  it("filters by name, code or description, keeps the ancestors of a match on screen, and says when nothing matches", async () => {
    const { host, tree } = mountTree();
    const input = tree.get("input[type=search]");
    await input.setValue("export");
    expect(codes(tree)).toEqual(["users", "users.admin", "users.admin.export"]);
    expect(tree.get('[data-code="users.admin.export"]').classes()).toContain("is-matched");
    expect(tree.get('[data-code="users"]').classes()).not.toContain("is-matched");
    await input.setValue("freeze");
    expect(codes(tree)).toEqual(["users", "users.write"]);
    await input.setValue("GROUPS.READ");
    expect(codes(tree)).toEqual(["groups", "groups.read"]);
    await input.setValue("nothing like this");
    expect(tree.find("[role=tree]").exists()).toBe(false);
    expect(tree.text()).toContain("No matching permissions");
    await input.setValue("");
    expect(codes(tree)).toHaveLength(9);
    host.unmount();
  });

  it("walks with the arrow keys, folds with left and right, toggles with Space, and starts folded on request", async () => {
    const { host, tree } = mountTree({ defaultExpanded: false });
    expect(codes(tree)).toEqual(["users", "groups", "billing"]);
    const item = (code: string) => tree.get(`[data-code="${code}"]`);
    (item("users").element as HTMLElement).focus();
    await item("users").trigger("keydown", { key: "ArrowRight" });
    expect(codes(tree)).toEqual(["users", "users.read", "users.write", "users.admin", "groups", "billing"]);
    expect(document.activeElement).toBe(item("users").element);
    await item("users").trigger("keydown", { key: "ArrowRight" });
    expect(document.activeElement).toBe(item("users.read").element);
    expect(item("users.read").attributes("tabindex")).toBe("0");
    expect(item("users").attributes("tabindex")).toBe("-1");
    await item("users.read").trigger("keydown", { key: "ArrowDown" });
    expect(document.activeElement).toBe(item("users.write").element);
    await item("users.write").trigger("keydown", { key: "ArrowLeft" });
    expect(document.activeElement).toBe(item("users").element);
    await item("users").trigger("keydown", { key: "ArrowLeft" });
    expect(codes(tree)).toEqual(["users", "groups", "billing"]);
    await item("users").trigger("keydown", { key: "End" });
    expect(document.activeElement).toBe(item("billing").element);
    await item("billing").trigger("keydown", { key: " " });
    expect(checkedEmits(tree)?.[0]).toEqual([["billing"]]);
    await item("billing").trigger("keydown", { key: "Home" });
    expect(document.activeElement).toBe(item("users").element);
    await item("users").trigger("keydown", { key: "Enter" });
    expect(checkedEmits(tree)?.[1]).toEqual([["billing", "users.read", "users.write", "users.admin.delete", "users.admin.export"]]);
    host.unmount();
  });

  it("expands and collapses everything from the bar, and folds a group from its chevron without toggling it", async () => {
    const { host, tree } = mountTree();
    const buttons = tree.findAll("button").filter((button) => ["Expand all", "Collapse all"].includes(button.text()));
    await buttons[1].trigger("click");
    expect(codes(tree)).toEqual(["users", "groups", "billing"]);
    await buttons[0].trigger("click");
    expect(codes(tree)).toHaveLength(9);
    await tree.get('[data-code="groups"] .flare-permission-tree__fold').trigger("click");
    expect(codes(tree)).toHaveLength(8);
    expect(checkedEmits(tree)).toBeUndefined();
    host.unmount();
  });

  it("renders a node through its slot with the derived state", () => {
    const { host, tree } = mountTree({ checkedCodes: ["groups.read"] }, {
      node: ({ node, state, depth }: { node: FlarePermissionNode; state: string; depth: number }) => h("i", { class: "custom" }, `${node.code}@${depth}:${state}`),
    });
    expect(tree.get('[data-code="groups"] .custom').text()).toBe("groups@0:checked");
    expect(tree.get('[data-code="users.read"] .custom').text()).toBe("users.read@1:none");
    host.unmount();
  });

  it("speaks the kit's Chinese under a Chinese kit", () => {
    const { host, tree } = mountTree({ readonly: true }, {}, "zh-CN");
    expect(tree.get("[role=tree]").attributes("aria-label")).toBe("权限");
    expect(tree.get("[aria-live=polite]").text()).toBe("已选 0 / 6 项");
    expect(tree.text()).toContain("仅可查看");
    expect(tree.get("input[type=search]").attributes("placeholder")).toBe("搜索权限");
    host.unmount();
  });

  it("stays responsive on a thousand nodes: mounting, toggling a module and searching", async () => {
    const big: FlarePermissionNode[] = Array.from({ length: 20 }, (_, module) => ({
      code: `m${module}`,
      name: `Module ${module}`,
      children: Array.from({ length: 7 }, (_, group) => ({
        code: `m${module}.g${group}`,
        name: `Group ${group}`,
        children: Array.from({ length: 6 }, (_, leaf) => ({ code: `m${module}.g${group}.p${leaf}`, name: `Permission ${leaf}` })),
      })),
    }));
    const started = performance.now();
    const { host, tree, set } = mountTree({ nodes: big });
    expect(items(tree)).toHaveLength(1000);
    await tree.get('[data-code="m3"]').trigger("click");
    const checked = checkedEmits(tree)?.[0][0] ?? [];
    expect(checked).toHaveLength(42);
    await set({ checkedCodes: checked });
    expect(tree.get('[data-code="m3"]').attributes("aria-checked")).toBe("true");
    expect(tree.get('[data-code="m3.g2"]').attributes("aria-checked")).toBe("true");
    await tree.get("input[type=search]").setValue("Permission 5");
    expect(items(tree)).toHaveLength(20 + 140 + 140);
    // A generous smoke budget: the per-node version of this took seconds, this is a few frames.
    expect(performance.now() - started).toBeLessThan(5000);
    host.unmount();
  });
});

describe("FlarePermissionTree in dark mode", () => {
  it("paints only with theme tokens, each of which dark mode redefines, and guards hover", () => {
    const source = readFileSync(resolve(__dirname, "FlarePermissionTree.vue"), "utf8");
    const tokens = readFileSync(resolve(__dirname, "../../../../../tokens/dist/tokens.css"), "utf8");
    const dark = /\[data-flare-theme="dark"\]\s*\{([^}]*)\}/.exec(tokens)?.[1] ?? "";
    const style = source.slice(source.indexOf("<style"));
    const colours = [...new Set([...style.matchAll(/var\((--flare-color-[\w-]+)\)/g)].map((match) => match[1]))];
    expect(colours.length).toBeGreaterThan(5);
    for (const token of colours) expect(dark, `${token} has no dark value`).toContain(`${token}:`);
    expect(source).not.toMatch(/#[0-9a-fA-F]{3,8}\b|\brgba?\(|\bhsla?\(/);
    for (const match of style.matchAll(/:hover/g)) {
      const before = style.slice(0, match.index);
      expect(before.lastIndexOf("@media (hover: hover)")).toBeGreaterThan(before.lastIndexOf("\n}\n"));
    }
  });
});
