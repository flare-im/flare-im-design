// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type { FlareSearchResultGroup } from "../../shared/contracts";
import FlareSearchResults from "./FlareSearchResults.vue";

const hosts: ReturnType<typeof mount>[] = [];
afterEach(() => hosts.splice(0).forEach(host => host.unmount()));

function mountResults(groups: FlareSearchResultGroup[]) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("en-US");
      return () => h(FlareSearchResults as Component, { groups, query: "ship" });
    },
  }), { attachTo: document.body });
  hosts.push(host);
  return host.findComponent(FlareSearchResults);
}

describe("FlareSearchResults", () => {
  it("keeps a late message match in the visible excerpt and the complete message in its accessible name", () => {
    const subtitle = '🙂前文'.repeat(100) + 'ship the release' + '，后文'.repeat(100);
    const results = mountResults([{ kind: 'message', label: 'Messages', items: [{ id: 'm', kind: 'message', title: 'Ivy', subtitle }] }]);
    const row = results.get('.flare-search-row');
    expect(row.get('.flare-search-row__sub').text()).toContain('ship');
    expect(row.get('.flare-search-row__sub').text().length).toBeLessThan(200);
    expect(row.get('.hit').text()).toBe('ship');
    expect(row.attributes('aria-label')).toBe(`Ivy, ${subtitle}`);
    expect(row.attributes('title')).toBe(subtitle);
  });

  it("moves through results and see-more, skips empty groups, and offers a route back to search", async () => {
    const results = mountResults([
      { kind: 'contact', label: 'Contacts', items: [], hasMore: true },
      { kind: 'message', label: 'Messages', items: [
        { id: 'm1', kind: 'message', title: 'One' },
        { id: 'm2', kind: 'message', title: 'Two' },
      ], hasMore: true },
    ]);
    const api = results.vm as unknown as { focusResult: (edge: 'first' | 'last') => boolean };
    const rows = results.findAll('.flare-search-row');
    expect(api.focusResult('first')).toBe(true);
    expect(document.activeElement).toBe(rows[0].element);
    await rows[0].trigger('keydown', { key: 'ArrowDown' });
    expect(document.activeElement).toBe(rows[1].element);
    await rows[1].trigger('keydown', { key: 'End' });
    expect(document.activeElement).toBe(results.findAll('.flare-search-more')[1].element);
    await results.findAll('.flare-search-more')[1].trigger('keydown', { key: 'Home' });
    expect(document.activeElement).toBe(rows[0].element);
    await rows[0].trigger('keydown', { key: 'ArrowUp' });
    expect(results.emitted('focusSearch')).toHaveLength(1);
    await rows[0].trigger('keydown', { key: 'ArrowDown', isComposing: true });
    expect(document.activeElement).toBe(rows[0].element);
  });

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
