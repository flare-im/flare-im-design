// @vitest-environment happy-dom
import { flushPromises, mount } from "@vue/test-utils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider, type FlareLocale } from "../../shared/i18n/useFlareI18n";
import FlareDescriptionList from "./FlareDescriptionList.vue";
import {
  descriptionColumns,
  descriptionIsEmpty,
  descriptionSpan,
  descriptionText,
  type FlareDescriptionItem,
} from "./description-list";

const user: FlareDescriptionItem[] = [
  { key: "userId", label: "用户 ID", value: "u_10086", monospace: true, copyable: true },
  { key: "status", label: "状态", value: "正常" },
  { key: "nickname", label: "昵称", value: "" },
  { key: "mobile", label: "手机号", value: null },
  { key: "friends", label: "好友数", value: 0 },
  { key: "note", label: "备注", value: "第一行\n第二行", span: 2 },
];

function mountList(props: Record<string, unknown>, slots: Record<string, unknown> = {}, locale: FlareLocale = "zh-CN") {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareDescriptionList as Component, props, slots);
    },
  }));
  return host.findComponent(FlareDescriptionList);
}

afterEach(() => vi.unstubAllGlobals());

describe("description-list rules", () => {
  it("treats only a missing value as not set — zero is a value", () => {
    expect([null, undefined, "", "  ", Number.NaN].map(descriptionIsEmpty)).toEqual([true, true, true, true, true]);
    expect([0, "0", "false", "—x"].map(descriptionIsEmpty)).toEqual([false, false, false, false]);
    expect(descriptionText(0)).toBe("0");
    expect(descriptionText(null)).toBe("");
  });

  it("keeps the columns between one and four and a span within them", () => {
    expect([undefined, 0, -1, 1, 2, 3.7, 4, 9, Number.NaN].map((value) => descriptionColumns(value as number))).toEqual([2, 1, 1, 1, 2, 3, 4, 4, 1]);
    expect(descriptionSpan({ key: "a", label: "a" }, 3)).toBe(1);
    expect(descriptionSpan({ key: "a", label: "a", span: 2 }, 3)).toBe(2);
    expect(descriptionSpan({ key: "a", label: "a", span: 5 }, 3)).toBe(3);
    expect(descriptionSpan({ key: "a", label: "a", span: 0 }, 3)).toBe(1);
    expect(descriptionSpan({ key: "a", label: "a", span: 2 }, 1)).toBe(1);
  });
});

describe("FlareDescriptionList", () => {
  it("is a real description list: one dt and one dd per line, in order", () => {
    const list = mountList({ items: user });
    const groups = list.findAll("dl > div");
    expect(groups).toHaveLength(user.length);
    for (const [index, group] of groups.entries()) {
      expect(group.findAll("dt")).toHaveLength(1);
      expect(group.findAll("dd")).toHaveLength(1);
      expect(group.get("dt").text()).toBe(user[index].label);
    }
    expect(groups[0].get("dd").text()).toContain("u_10086");
    expect(groups[4].get("dd").text()).toBe("0");
  });

  it("says not set for an empty value — a dash on screen, words for a screen reader", () => {
    const list = mountList({ items: user });
    for (const index of [2, 3]) {
      const value = list.findAll("dd")[index];
      expect(value.get(".flare-description-list__empty").text()).toBe("—");
      expect(value.get(".flare-description-list__empty").attributes("aria-hidden")).toBe("true");
      expect(value.get(".flare-description-list__spoken").text()).toBe("未设置");
      expect(value.text()).not.toMatch(/null|undefined/);
    }
    expect(mountList({ items: [{ key: "a", label: "Email", value: null }] }, {}, "en-US").get(".flare-description-list__spoken").text()).toBe("Not set");
  });

  it("lays out the host's columns and clamps each line's span to them", () => {
    const list = mountList({ items: user, columns: 3 });
    expect(list.attributes("style")).toContain("--flare-description-list-columns: 3");
    const spans = list.findAll(".flare-description-list__item").map((item) => item.attributes("style"));
    expect(spans[0]).toContain("--flare-description-list-span: 1");
    expect(spans[5]).toContain("--flare-description-list-span: 2");
    expect(mountList({ items: user, columns: 1 }).findAll(".flare-description-list__item")[5].attributes("style")).toContain("--flare-description-list-span: 1");
  });

  it("puts labels beside or above their values, and names the list only when asked", () => {
    const beside = mountList({ items: user });
    expect(beside.classes()).toContain("flare-description-list--label-start");
    expect(beside.attributes("role")).toBeUndefined();
    expect(beside.attributes("aria-label")).toBeUndefined();
    const above = mountList({ items: user, labelPlacement: "top", label: "账号信息", appearance: "card" });
    expect(above.classes()).toEqual(expect.arrayContaining(["flare-description-list--label-top", "flare-description-list--card"]));
    expect(above.attributes("role")).toBe("group");
    expect(above.attributes("aria-label")).toBe("账号信息");
  });

  it("sets identifiers in the monospaced face", () => {
    const list = mountList({ items: user });
    expect(list.findAll(".flare-description-list__text")[0].classes()).toContain("is-monospace");
    expect(list.findAll(".flare-description-list__text")[1].classes()).not.toContain("is-monospace");
  });

  it("renders a line through its item slot with the item and value in scope", () => {
    const list = mountList({ items: user }, {
      "item-status": ({ item, value }: { item: FlareDescriptionItem; value: unknown }) => h("mark", { "data-key": item.key }, String(value)),
    });
    const mark = list.get("mark");
    expect(mark.text()).toBe("正常");
    expect(mark.attributes("data-key")).toBe("status");
  });

  it("copies an identifier and reports whether the clipboard took it", async () => {
    const writeText = vi.fn().mockResolvedValueOnce(undefined).mockRejectedValueOnce(new Error("denied"));
    vi.stubGlobal("navigator", { clipboard: { writeText } });
    const list = mountList({ items: user });
    const keys = list.findAll(".flare-description-list__copy");
    // Only the line that asked for it, and never on an empty value.
    expect(keys).toHaveLength(1);
    expect(keys[0].attributes("aria-label")).toBe("复制用户 ID");
    await keys[0].trigger("click");
    await flushPromises();
    await keys[0].trigger("click");
    await flushPromises();
    expect(writeText).toHaveBeenCalledWith("u_10086");
    expect(list.emitted("copy")).toEqual([["userId", true], ["userId", false]]);
  });

  it("draws no copy key on a value that is not set, and reports a missing clipboard as not copied", async () => {
    expect(mountList({ items: [{ key: "a", label: "A", value: "", copyable: true }] }).find(".flare-description-list__copy").exists()).toBe(false);
    vi.stubGlobal("navigator", {});
    const list = mountList({ items: [{ key: "a", label: "A", value: "x", copyable: true }] });
    await list.get(".flare-description-list__copy").trigger("click");
    expect(list.emitted("copy")).toEqual([["a", false]]);
  });
});
