// @vitest-environment happy-dom
import { flushPromises, mount } from "@vue/test-utils";
import { h, nextTick, type Component } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import type { FlareActionItem } from "../../shared/contracts/action-menu";
import FlareActionMenu from "./FlareActionMenu.vue";

const items: FlareActionItem[] = [
  { id: "add-friend", label: "Add friend", icon: "person" },
  { id: "join-group", label: "Join group", enabled: false, disabledReason: "Only admins" },
  { id: "show-muted", label: "Show muted", pressed: true, badge: "3" },
  { id: "hidden", label: "Hidden", visible: false },
  { id: "blocked", label: "Blocked list", group: "danger", danger: true },
];

function mountMenu(props: Record<string, unknown>, layoutMode: "pc" | "h5" = "pc") {
  return mount(FlareUiProvider, {
    props: { themeMode: "light", locale: "en-US", layoutMode },
    slots: {
      default: () => h(FlareActionMenu as Component, { items, label: "New", ...props }, {
        default: () => h("button", { type: "button", class: "trigger" }, "+"),
      }),
    },
    attachTo: document.body,
  });
}

const menu = () => document.body.querySelector<HTMLElement>('[role="menu"]');
const menuItems = () => Array.from(document.body.querySelectorAll<HTMLElement>("[data-action-menu-item]"));

afterEach(() => {
  document.body.innerHTML = "";
});

describe("FlareActionMenu", () => {
  it("opens from its trigger as a named menu with a separator where the group changes", async () => {
    const host = mountMenu({});
    const trigger = host.get(".trigger");
    expect(trigger.attributes("aria-haspopup")).toBe("menu");
    expect(trigger.attributes("aria-expanded")).toBe("false");
    await trigger.trigger("click");
    await flushPromises();
    expect(menu()?.getAttribute("aria-label")).toBe("New");
    expect(trigger.attributes("aria-expanded")).toBe("true");
    expect(trigger.attributes("aria-controls")).toBe(menu()?.id);
    expect(menuItems().map((item) => item.dataset.actionId)).toEqual(["add-friend", "join-group", "show-muted", "blocked"]);
    const children = Array.from(menu()!.children).map((child) => child.getAttribute("role"));
    expect(children).toEqual(["menuitem", "menuitem", "menuitemcheckbox", "separator", "menuitem"]);
    expect(menuItems()[2]?.getAttribute("aria-checked")).toBe("true");
    expect(menuItems()[1]?.getAttribute("aria-disabled")).toBe("true");
    expect(menuItems()[1]?.textContent).toContain("Only admins");
    expect(menuItems()[2]?.textContent).toContain("3");
    host.unmount();
  });

  it("closes on select, returns focus to the trigger and reports the id; disabled items report nothing", async () => {
    const selected: string[] = [];
    const host = mountMenu({ onSelect: (id: string) => selected.push(id) });
    const trigger = host.get(".trigger");
    (trigger.element as HTMLElement).focus();
    await trigger.trigger("click");
    await flushPromises();
    menuItems()[1]?.click();
    await nextTick();
    expect(selected).toEqual([]);
    expect(menu()).not.toBeNull();
    menuItems()[0]?.click();
    await flushPromises();
    expect(selected).toEqual(["add-friend"]);
    expect(trigger.attributes("aria-expanded")).toBe("false");
    expect(document.activeElement).toBe(trigger.element);
    host.unmount();
  });

  it("moves focus with the arrow keys and closes on Escape", async () => {
    const host = mountMenu({});
    const trigger = host.get(".trigger");
    await trigger.trigger("click");
    await flushPromises();
    expect(document.activeElement).toBe(menuItems()[0]);
    menu()!.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true }));
    expect(document.activeElement).toBe(menuItems()[1]);
    menu()!.dispatchEvent(new KeyboardEvent("keydown", { key: "End", bubbles: true }));
    expect(document.activeElement).toBe(menuItems()[3]);
    menu()!.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true }));
    expect(document.activeElement).toBe(menuItems()[0]);
    menu()!.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }));
    await flushPromises();
    expect(trigger.attributes("aria-expanded")).toBe("false");
    expect(document.activeElement).toBe(trigger.element);
    host.unmount();
  });

  it("is a bottom sheet on phones", async () => {
    const host = mountMenu({}, "h5");
    await host.get(".trigger").trigger("click");
    await flushPromises();
    const sheet = document.body.querySelector('[role="dialog"]');
    // 面板叫什么仍然报给读屏,但不画成一行可见标题:底下每一条都是一句完整的动作,
    // 上面再写一遍「新建」只是把刚点的那颗按钮重复一次。
    expect(sheet?.getAttribute("aria-label")).toBe("New");
    expect(sheet?.querySelector(".flare-sheet__title")).toBeNull();
    expect(sheet?.querySelector('[role="menu"]')).not.toBeNull();
    host.unmount();
  });

  it("follows a controlled open state at a point and never opens without visible items", async () => {
    const updates: boolean[] = [];
    const point = mount(FlareUiProvider, {
      props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
      slots: {
        default: () => h(FlareActionMenu as Component, {
          items, label: "Row", open: true, x: 40, y: 60, trigger: "manual",
          "onUpdate:open": (open: boolean) => updates.push(open),
        }),
      },
      attachTo: document.body,
    });
    await flushPromises();
    expect(menu()?.getAttribute("aria-label")).toBe("Row");
    menu()!.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }));
    expect(updates).toEqual([false]);
    point.unmount();

    const empty = mountMenu({ items: [{ id: "hidden", label: "Hidden", visible: false }] });
    await empty.get(".trigger").trigger("click");
    await flushPromises();
    expect(menu()).toBeNull();
    empty.unmount();
  });
});
