// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type { FlareSearchResultGroup } from "../../shared/contracts";
import FlareSearchResults from "./FlareSearchResults.vue";

function mountResults(groups: FlareSearchResultGroup[]) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("en-US");
      return () => h(FlareSearchResults as Component, { groups, query: "ship" });
    },
  }));
  return host.findComponent(FlareSearchResults);
}

describe("FlareSearchResults", () => {
  it("keeps every hit in one conversation as its own row and emits its target", async () => {
    const results = mountResults([
      { kind: "contact", label: "Contacts", items: [{ id: "ivy", kind: "contact", title: "Ivy" }] },
      {
        kind: "message",
        label: "Messages",
        items: [
          { id: "ivy", kind: "message", title: "Ivy", subtitle: "ship it", target: { conversationId: "c-1", messageId: "ivy" } },
          { id: "m-2", kind: "message", title: "Ivy", subtitle: "shipping today", target: { conversationId: "c-1", messageId: "m-2" } },
        ],
      },
    ]);
    const rows = results.findAll(".flare-search-row");
    expect(rows).toHaveLength(3);
    await rows[2].trigger("click");
    expect(results.emitted("open")?.[0]?.[0]).toMatchObject({ kind: "message", target: { conversationId: "c-1", messageId: "m-2" } });
  });
  // 搜索接口只收 limit、不回总数:宿主多取一条就知道「还有」,但不知道有多少。给不出 total 时
  // 「查看全部 N 条」从来画不出来;hasMore 画一条不带数的「查看更多」,有 total 时 total 优先。
  it("offers a countless see-more row for a truncated group, and the counted one when the total is known", async () => {
    const item = (id: string) => ({ id, kind: "contact" as const, title: id });
    const results = mountResults([
      { kind: "contact", label: "Contacts", items: [item("a")], hasMore: true },
      { kind: "group", label: "Groups", items: [{ id: "g", kind: "group", title: "g" }], total: 9, hasMore: true },
      { kind: "message", label: "Messages", items: [{ id: "m", kind: "message", title: "m" }] },
    ]);
    const more = results.findAll(".flare-search-more");
    expect(more.map((row) => row.text())).toEqual(["See more", "View all 9"]);
    await more[0].trigger("click");
    expect(results.emitted("viewAll")?.[0]).toEqual(["contact"]);
  });
});
