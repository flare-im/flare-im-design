// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareActivityList, { type FlareActivityItem } from "./FlareActivityList.vue";

const items: FlareActivityItem[] = [
  { id: "a1", title: "林夏赞了你的动态", description: "周末去爬山", time: "3 分钟前", unread: true },
  { id: "a2", title: "何川评论了你", description: "带上我", time: "昨天", avatarUrl: "https://cdn.example.com/he.png" },
];

const mounted: Array<{ unmount(): void }> = [];
afterEach(() => { mounted.splice(0).forEach((wrapper) => wrapper.unmount()); });

function render(props: Record<string, unknown>, slots: Record<string, () => unknown> = {}) {
  const wrapper = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareActivityList as Component, { emptyText: "暂无互动", ...props }, slots);
    },
  }));
  mounted.push(wrapper);
  return wrapper;
}

/** The same contract as the Flutter kit's FlareActivityList: host-owned rows, rows are buttons only with `select`. */
describe("FlareActivityList", () => {
  it("draws each row's title, description, time and the unread dot", () => {
    const list = render({ items });
    const rows = list.findAll(".flare-activity-list__row");
    expect(rows).toHaveLength(2);
    expect(rows[0].get(".flare-activity-list__description").text()).toBe("周末去爬山");
    expect(rows[0].get(".flare-activity-list__time").text()).toBe("3 分钟前");
    expect(rows[0].classes()).toContain("is-unread");
    expect(rows[0].find("[data-shape='dot']").exists()).toBe(true);
    expect(rows[1].find("[data-shape='dot']").exists()).toBe(false);
    // A screen reader hears that the row is unread; the dot is the sighted half.
    expect(rows[0].get(".flare-activity-list__title").text()).toBe("林夏赞了你的动态，未读");
    expect(rows[1].get(".flare-activity-list__title").text()).toBe("何川评论了你");
  });

  it("restores the visible row offset and opener focus after returning from detail", () => {
    const list = render({ items, onSelect: () => {} }).getComponent(FlareActivityList);
    document.body.append(list.element);
    const node = list.element as HTMLElement;
    node.getBoundingClientRect = () => ({ top: 10 } as DOMRect);
    const row = list.get('[data-activity-id="a1"]').element as HTMLElement;
    let top = -2;
    row.getBoundingClientRect = () => ({ top, bottom: top + 70 } as DOMRect);
    node.scrollTop = 220;
    const position = list.vm.capturePosition();
    expect(position).toEqual({ scrollTop: 220, anchorId: "a1", anchorOffset: -12 });
    top = 38; // New notices or a toolbar resize have shifted the existing row.
    list.vm.restorePosition(position, "a1");
    expect(node.scrollTop).toBe(260); expect(document.activeElement).toBe(row);
    node.remove();
  });

  it("keeps the rows as text without a select listener", () => {
    const list = render({ items });
    expect(list.findAll("button")).toHaveLength(0);
  });

  it("makes every row a button that reports its id when the host takes select", async () => {
    const picked: string[] = [];
    const list = render({ items, onSelect: (id: string) => picked.push(id) });
    const buttons = list.findAll("button.flare-activity-list__row");
    expect(buttons).toHaveLength(2);
    await buttons[1].trigger("click");
    expect(picked).toEqual(["a2"]);
  });

  it("offers a descriptive empty state and reports its action without selecting an item", async () => {
    const actions: string[] = [];
    const list = render({ items: [], emptyDescription: "赞和回复会出现在这里", emptyActionText: "返回圈子", onEmptyAction: () => actions.push("back") });
    expect(list.text()).toContain("赞和回复会出现在这里");
    await list.get("button").trigger("click");
    expect(actions).toEqual(["back"]);
    expect(list.findComponent(FlareActivityList).emitted("select")).toBeUndefined();
  });
  it("keeps interactive row semantics while the host locks activity actions", async () => {
    const picked: string[] = [];
    const list = render({ items, density: "compact", disabled: true, onSelect: (id: string) => picked.push(id) });
    const row = list.get("button.flare-activity-list__row");
    expect(row.attributes("disabled")).toBeDefined();
    await row.trigger("click");
    expect(picked).toEqual([]);
  });
  it("shows the empty text with no items, and the footer after the rows", () => {
    const empty = render({ items: [] });
    expect(empty.text()).toContain("暂无互动");
    expect(empty.find(".flare-activity-list__rows").exists()).toBe(false);
    const withFooter = render({ items }, { footer: () => h("span", { class: "more" }, "加载更多") });
    expect(withFooter.get(".flare-activity-list__footer").text()).toBe("加载更多");
    expect(render({ items: [] }, { footer: () => h("span", "end") }).find(".flare-activity-list__footer").exists()).toBe(true);
  });
});
