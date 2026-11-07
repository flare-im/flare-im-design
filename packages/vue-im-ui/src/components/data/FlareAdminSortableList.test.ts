// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, ref, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareAdminSortableList, { type FlareAdminSortableItem } from "./FlareAdminSortableList.vue";
import FlareActionMenu from "../general/FlareActionMenu.vue";

let host: ReturnType<typeof mount>;
afterEach(() => host?.unmount());

const start: FlareAdminSortableItem[] = [
  { id: "image", label: "图片" },
  { id: "file", label: "文件" },
  { id: "plugin:flare.redpacket.send", label: "红包" },
];

function mountList(props: Record<string, unknown> = {}) {
  const items = ref<FlareAdminSortableItem[]>([...start]);
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareAdminSortableList as Component, {
        label: "面板项",
        items: items.value,
        "onUpdate:items": (next: FlareAdminSortableItem[]) => { items.value = next; },
        ...props,
      }, {
        item: ({ item }: { item: FlareAdminSortableItem }) => h("span", { class: "name" }, item.label),
        trailing: ({ item }: { item: FlareAdminSortableItem }) => h("input", { type: "checkbox", "aria-label": `显示${item.label}` }),
      });
    },
  }), { attachTo: document.body });
  const list = host.findComponent(FlareAdminSortableList);
  const order = () => items.value.map((item) => item.id);
  const live = () => list.get('[aria-live="polite"]').text();
  return { list, items, order, live };
}

describe("FlareAdminSortableList", () => {
  it("draws each row with its handle, content, trailing slot and menu, in order", () => {
    const { list } = mountList();
    expect(list.get("ol").attributes("aria-label")).toBe("面板项");
    expect(list.findAll(".name").map((name) => name.text())).toEqual(["图片", "文件", "红包"]);
    expect(list.findAll(".flare-admin-sortable__handle").map((handle) => handle.attributes("aria-label")))
      .toEqual(["调整「图片」的位置", "调整「文件」的位置", "调整「红包」的位置"]);
    expect(list.findAll('input[type="checkbox"]')).toHaveLength(3);
    expect(list.text()).toContain("Alt+↑");
  });

  it("moves a row with Alt+↑ / Alt+↓ on its handle, keeps the handle focused and announces the position", async () => {
    const { list, order, live } = mountList();
    await list.get('[data-sortable-handle="image"]').trigger("keydown", { key: "ArrowDown", altKey: true });
    await nextTick();
    expect(order()).toEqual(["file", "image", "plugin:flare.redpacket.send"]);
    expect(live()).toBe("「图片」已移到第 2 位，共 3 项");
    expect(document.activeElement?.getAttribute("data-sortable-handle")).toBe("image");
    await list.get('[data-sortable-handle="image"]').trigger("keydown", { key: "ArrowUp", altKey: true });
    expect(order()).toEqual(["image", "file", "plugin:flare.redpacket.send"]);
    // Plain arrows and moves past either end do nothing.
    await list.get('[data-sortable-handle="image"]').trigger("keydown", { key: "ArrowDown" });
    await list.get('[data-sortable-handle="image"]').trigger("keydown", { key: "ArrowUp", altKey: true });
    expect(order()).toEqual(["image", "file", "plugin:flare.redpacket.send"]);
  });

  it("offers move up / down / to top per row, disabled at the ends", async () => {
    const { list, order } = mountList();
    const menus = list.findAllComponents(FlareActionMenu);
    const enabled = (index: number) =>
      (menus[index]!.props("items") as { id: string; enabled?: boolean }[]).map((item) => [item.id, item.enabled]);
    expect(enabled(0)).toEqual([["up", false], ["down", true], ["top", false]]);
    expect(enabled(2)).toEqual([["up", true], ["down", false], ["top", true]]);
    menus[2]!.vm.$emit("select", "top");
    await nextTick();
    expect(order()).toEqual(["plugin:flare.redpacket.send", "image", "file"]);
  });

  it("drops a dragged row onto another row's place", async () => {
    const { list, order, live } = mountList();
    const rows = () => list.findAll(".flare-admin-sortable__row");
    await rows()[2]!.trigger("dragstart", { dataTransfer: { setData() {}, effectAllowed: "" } });
    await rows()[0]!.trigger("dragover");
    expect(rows()[0]!.classes()).toContain("is-drop-target");
    await rows()[0]!.trigger("drop");
    expect(order()).toEqual(["plugin:flare.redpacket.send", "image", "file"]);
    expect(live()).toBe("「红包」已移到第 1 位，共 3 项");
    expect(list.find(".is-drop-target").exists()).toBe(false);
  });

  it("is read-only when disabled", async () => {
    const { list, order } = mountList({ disabled: true });
    expect(list.find(".flare-admin-sortable__handle").exists()).toBe(false);
    expect(list.findAllComponents(FlareActionMenu)).toHaveLength(0);
    expect(list.get("li").attributes("draggable")).toBe("false");
    await list.findAll("li")[1]!.trigger("drop");
    expect(order()).toEqual(["image", "file", "plugin:flare.redpacket.send"]);
  });
});
