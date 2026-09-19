// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it, vi } from "vitest";
import FlareContactItem from "./FlareContactItem.vue";
import FlareContactList from "./FlareContactList.vue";

const people = [
  { id: "u1", name: "Ann", signature: "Design" },
  { id: "u2", name: "Bob" },
];

const FOCUSABLE = "button, [href], input, select, textarea, [tabindex]:not([tabindex='-1'])";

describe("FlareContactList selection", () => {
  it("renders each selectable row as one checkbox named by the contact and toggles from anywhere on the row", async () => {
    const wrapper = mount(FlareContactList, {
      props: { items: people, indexed: false, selectable: true, selectedIds: ["u2"], onSelect: () => {} },
      attachTo: document.body,
    });
    const rows = wrapper.findAll(".flare-contact-item");
    expect(rows).toHaveLength(2);
    for (const row of rows) {
      // The checkbox is the row's only focus stop.
      expect(row.element.querySelectorAll(FOCUSABLE)).toHaveLength(1);
    }
    const boxes = wrapper.findAll("[role=checkbox]");
    expect(boxes.map((box) => box.attributes("aria-label"))).toEqual(["Ann", "Bob"]);
    expect(boxes.map((box) => box.attributes("aria-checked"))).toEqual(["false", "true"]);

    // A tap on the name (not the box) toggles through the row label; `select` stays silent.
    await rows[0].get(".flare-contact-item__name").trigger("click");
    await boxes[1].trigger("click");
    expect(wrapper.emitted("toggleSelect")).toEqual([["u1"], ["u2"]]);
    expect(wrapper.emitted("select")).toBeUndefined();
    // The host owns the selection: nothing flips until selectedIds changes.
    expect(wrapper.findAll("[role=checkbox]").map((box) => box.attributes("aria-checked"))).toEqual(["false", "true"]);
    await wrapper.setProps({ selectedIds: ["u1"] });
    expect(wrapper.findAll("[role=checkbox]").map((box) => box.attributes("aria-checked"))).toEqual(["true", "false"]);
    wrapper.unmount();
  });

  it("keeps trailing content focusable and its clicks away from the row", async () => {
    const rowClick = vi.fn();
    const action = vi.fn();
    const wrapper = mount(FlareContactList, {
      props: { items: people, indexed: false, onSelect: () => {} },
      slots: {
        trailing: ({ item }: { item: { id: string; name: string } }) => h("button", { class: "remove", onClick: () => action(item.id) }, `Remove ${item.name}`),
      },
      attachTo: document.body,
    });
    const firstRow = wrapper.get(".flare-contact-item");
    firstRow.element.addEventListener("click", rowClick);
    const remove = firstRow.get("button.remove");
    expect(remove.text()).toBe("Remove Ann");
    // Row button + trailing button: two separate focus stops.
    expect(firstRow.element.querySelectorAll(FOCUSABLE)).toHaveLength(2);

    await remove.trigger("click");
    expect(action).toHaveBeenCalledWith("u1");
    expect(rowClick).not.toHaveBeenCalled();
    expect(wrapper.emitted("select")).toBeUndefined();

    await firstRow.get("button.flare-contact-item__main").trigger("click");
    expect(wrapper.emitted("select")).toEqual([[people[0]]]);
    wrapper.unmount();
  });

  it("renders display-only rows when nobody handles select", () => {
    const wrapper = mount(FlareContactList, { props: { items: people, indexed: false } });
    expect(wrapper.find("button").exists()).toBe(false);
    expect(wrapper.findAll(".flare-contact-item__main")).toHaveLength(2);
  });

  it("toggles a standalone selectable item without a payload", async () => {
    const wrapper = mount(FlareContactItem, {
      props: { item: people[0], selectable: true, selected: true, showPresence: true },
      attachTo: document.body,
    });
    const box = wrapper.get("[role=checkbox]");
    expect(box.attributes("aria-checked")).toBe("true");
    await wrapper.get(".flare-contact-item__sig").trigger("click");
    expect(wrapper.emitted("toggleSelect")).toEqual([[]]);
    expect(wrapper.emitted("select")).toBeUndefined();
    wrapper.unmount();
  });
});

describe("FlareContactList index", () => {
  const contacts = [
    { id: "c1", name: "周屿" }, { id: "c2", name: "Ann" }, { id: "c3", name: "林夏" },
    { id: "c4", name: "8号机" }, { id: "c5", name: "陆遥" }, { id: "c6", name: "李" },
  ];

  it("groups Chinese names by pinyin initial, A to Z with # last, names in pinyin order", () => {
    const wrapper = mount(FlareContactList, { props: { items: contacts } });
    const heads = wrapper.findAll(".flare-contact-list__head").map((head) => head.text());
    expect(heads).toEqual(["A", "L", "Z", "#"]);
    const lGroup = wrapper.findAll('[role="group"]')[1];
    expect(lGroup.findAll(".flare-contact-item__name").map((name) => name.text())).toEqual(["李", "林夏", "陆遥"]);
    wrapper.unmount();
  });

  it("offers the index as named buttons that scroll within this list only", async () => {
    const page = mount(defineComponent({
      render: () => h("div", [h(FlareContactList, { items: contacts, class: "first" }), h(FlareContactList, { items: contacts, class: "second" })]),
    }), { attachTo: document.body });
    const [first, second] = page.findAllComponents(FlareContactList);
    const index = first.get("nav.flare-contact-list__idx");
    expect(index.attributes("aria-label")).toBe("联系人索引");
    const buttons = index.findAll("button");
    expect(buttons.map((button) => button.attributes("aria-label"))).toEqual(["跳到 A", "跳到 L", "跳到 Z", "跳到 #"]);
    const ids = page.findAll(".flare-contact-list__head").map((head) => head.attributes("id"));
    expect(new Set(ids).size).toBe(ids.length);
    const scrolled = vi.fn();
    (first.get('[data-index-letter="Z"]').element as HTMLElement).scrollIntoView = scrolled;
    (second.get('[data-index-letter="Z"]').element as HTMLElement).scrollIntoView = () => { throw new Error("jumped into the other list"); };
    await buttons[2].trigger("click");
    expect(scrolled).toHaveBeenCalledTimes(1);
    page.unmount();
  });
});

describe("FlareContactList empty slot", () => {
  it("draws the kit's own empty state when the host gives none", () => {
    const wrapper = mount(FlareContactList, { props: { items: [] } });
    expect(wrapper.find(".flare-empty").exists()).toBe(true);
  });

  it("lets the host replace it, for a directory that is empty for a reason only the host knows", () => {
    const wrapper = mount(FlareContactList, {
      props: { items: [] },
      slots: { empty: '<p class="host-empty">没有匹配的联系人，换个筛选条件试试</p>' },
    });
    expect(wrapper.find(".host-empty").text()).toContain("换个筛选条件");
    expect(wrapper.find(".flare-empty").exists()).toBe(false);
  });

  it("shows neither once there is someone to list", () => {
    const wrapper = mount(FlareContactList, {
      props: { items: people },
      slots: { empty: '<p class="host-empty">nothing</p>' },
    });
    expect(wrapper.find(".host-empty").exists()).toBe(false);
    expect(wrapper.find(".flare-empty").exists()).toBe(false);
  });
});
