// @vitest-environment happy-dom
import { enableAutoUnmount, mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, ref } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type { FlareContactPickerEntry, FlareContactPickerGroup } from "../../shared/contracts/contact-picker";
import FlareContactPicker from "./FlareContactPicker.vue";

enableAutoUnmount(afterEach);

const ME: FlareContactPickerEntry = { userId: "u0", name: "林晓", isSelf: true };
const IVY: FlareContactPickerEntry = { userId: "u1", name: "Ivy Chen", subtitle: "设计组" };
const ZHOU: FlareContactPickerEntry = { userId: "u2", name: "周屿", subtitle: "产品" };
const GROUPS: FlareContactPickerGroup[] = [
  { id: "friends", entries: [IVY, ZHOU] },
  { id: "groupMembers", entries: [ME, IVY] },
];

function render(props: Record<string, unknown>, locale: "zh-CN" | "en-US" = "zh-CN") {
  const selections: FlareContactPickerEntry[][] = [];
  let cancels = 0;
  const wrapper = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareContactPicker, {
        groups: GROUPS,
        onSelect: (entries: FlareContactPickerEntry[]) => selections.push(entries),
        onCancel: () => { cancels += 1; },
        ...props,
      });
    },
  }), { attachTo: document.body });
  return { wrapper, selections, cancels: () => cancels };
}
const names = (wrapper: ReturnType<typeof render>["wrapper"]) =>
  wrapper.findAll(".flare-contact-picker__row").map((row) => row.attributes("data-user-id"));

describe("FlareContactPicker", () => {
  it("shows a tab per group, the friends first, and switches", async () => {
    const picker = render({});
    const tabs = picker.wrapper.findAll('[role="tab"]');
    expect(tabs.map((tab) => tab.text())).toEqual(["好友", "群成员"]);
    expect(names(picker.wrapper)).toEqual(["u1", "u2"]);
    await tabs[1].trigger("click");
    expect(names(picker.wrapper)).toEqual(["u0", "u1"]);
    expect(picker.wrapper.get('[data-user-id="u0"]').text()).toContain("林晓（我）");
  });

  it("draws no tabs for a single group and keeps a host label", () => {
    const picker = render({ groups: [{ id: "colleagues", label: "同事", entries: [IVY] }] });
    expect(picker.wrapper.find('[role="tab"]').exists()).toBe(false);
    expect(picker.wrapper.get(".flare-contact-picker__list").attributes("aria-label")).toBe("同事");
  });

  it("answers one tap with that person in single mode", async () => {
    const picker = render({});
    await picker.wrapper.get('[data-user-id="u2"]').trigger("click");
    expect(picker.selections).toEqual([[ZHOU]]);
  });

  it("searches names and subtitles, and says when nothing matches", async () => {
    const picker = render({});
    const input = picker.wrapper.get(".flare-contact-picker__search input");
    await input.setValue("设计");
    expect(names(picker.wrapper)).toEqual(["u1"]);
    await input.setValue("ivy");
    expect(names(picker.wrapper)).toEqual(["u1"]);
    await input.setValue("没有这个人");
    expect(names(picker.wrapper)).toEqual([]);
    expect(picker.wrapper.text()).toContain("没有联系人");
  });

  it("hides the search when the host turns it off, and shows the empty state for an empty group", () => {
    const picker = render({ searchable: false, groups: [{ id: "friends", entries: [] }] });
    expect(picker.wrapper.find(".flare-contact-picker__search").exists()).toBe(false);
    expect(picker.wrapper.text()).toContain("没有联系人");
  });

  it("toggles rows in multiple mode and answers from the confirm key", async () => {
    const picker = render({ multiple: true });
    const confirm = () => picker.wrapper.get(".flare-contact-picker__head-end button");
    expect(confirm().attributes("disabled")).toBeDefined();
    await picker.wrapper.get('[data-user-id="u1"]').trigger("click");
    await picker.wrapper.get('[data-user-id="u2"]').trigger("click");
    await picker.wrapper.get('[data-user-id="u2"]').trigger("click");
    await picker.wrapper.get('[data-user-id="u1"]').trigger("click");
    await picker.wrapper.get('[data-user-id="u2"]').trigger("click");
    expect(picker.wrapper.get('[data-user-id="u2"]').attributes("aria-checked")).toBe("true");
    expect(picker.selections).toEqual([]);
    expect(confirm().text()).toBe("确定 (1)");
    await confirm().trigger("click");
    expect(picker.selections).toEqual([[ZHOU]]);
  });

  it("spins the tapped row while the host sends and takes no other tap, then forgets it", async () => {
    const sending = ref(false);
    const selections: FlareContactPickerEntry[][] = [];
    // The host sets sending from select, as a chat does while it sends the card.
    const live = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () => h(FlareContactPicker, {
          groups: GROUPS,
          sending: sending.value,
          onSelect: (entries: FlareContactPickerEntry[]) => {
            selections.push(entries);
            sending.value = true;
          },
        });
      },
    }), { attachTo: document.body });
    const row = (id: string) => live.get(`[data-user-id="${id}"]`);
    await row("u2").trigger("click");
    await nextTick();
    expect(selections).toEqual([[ZHOU]]);
    expect(row("u2").attributes("aria-busy")).toBe("true");
    expect(row("u2").attributes("aria-selected")).toBe("true");
    expect(row("u2").find(".flare-contact-picker__spinner").exists()).toBe(true);
    expect(row("u1").attributes("disabled")).toBeDefined();
    expect(row("u1").find(".flare-contact-picker__spinner").exists()).toBe(false);
    await row("u1").trigger("click");
    expect(selections).toEqual([[ZHOU]]);
    // Cancel and the search stay with the host's sheet.
    expect(live.get(".flare-contact-picker__cancel").attributes("disabled")).toBeUndefined();

    sending.value = false;
    await nextTick();
    expect(row("u2").attributes("aria-busy")).toBeUndefined();
    expect(row("u2").find(".flare-contact-picker__spinner").exists()).toBe(false);
    expect(row("u1").attributes("disabled")).toBeUndefined();
    await row("u1").trigger("click");
    expect(selections).toEqual([[ZHOU], [IVY]]);
    live.unmount();
  });

  it("spins the confirm key in multiple mode and keeps the choice for a retry", async () => {
    const sending = ref(false);
    const selections: FlareContactPickerEntry[][] = [];
    const live = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () => h(FlareContactPicker, {
          groups: GROUPS,
          multiple: true,
          sending: sending.value,
          onSelect: (entries: FlareContactPickerEntry[]) => selections.push(entries),
        });
      },
    }), { attachTo: document.body });
    const confirm = () => live.get(".flare-contact-picker__head-end button");
    await live.get('[data-user-id="u1"]').trigger("click");
    sending.value = true;
    await nextTick();
    expect(confirm().attributes("aria-busy")).toBe("true");
    expect(confirm().attributes("disabled")).toBeDefined();
    expect(live.find(".flare-contact-picker__spinner").exists()).toBe(false);
    await live.get('[data-user-id="u2"]').trigger("click");
    expect(live.get('[data-user-id="u2"]').attributes("aria-checked")).toBe("false");
    sending.value = false;
    await nextTick();
    expect(live.get('[data-user-id="u1"]').attributes("aria-checked")).toBe("true");
    await confirm().trigger("click");
    expect(selections).toEqual([[IVY]]);
    live.unmount();
  });

  it("renders only the rows in view for a long list", () => {
    const many = Array.from({ length: 500 }, (_, i) => ({ userId: `u${i}`, name: `联系人 ${i}` }));
    const picker = render({ groups: [{ id: "friends", entries: many }] });
    const rendered = picker.wrapper.findAll(".flare-contact-picker__row").length;
    expect(rendered).toBeGreaterThan(0);
    expect(rendered).toBeLessThan(40);
  });

  it("cancels, and speaks English", async () => {
    const picker = render({}, "en-US");
    expect(picker.wrapper.text()).toContain("Choose a contact");
    expect(picker.wrapper.findAll('[role="tab"]').map((tab) => tab.text())).toEqual(["Friends", "Group members"]);
    await picker.wrapper.get(".flare-contact-picker__cancel").trigger("click");
    expect(picker.cancels()).toBe(1);
  });
});
