// @vitest-environment happy-dom
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h, reactive } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import type { FlarePluginActionPayload, FlarePluginViewModel } from "../../shared/contracts/plugin-ui";
import FlarePluginPage from "./FlarePluginPage.vue";
import FlarePluginView from "./FlarePluginView.vue";

enableAutoUnmount(afterEach);
afterEach(() => { document.body.innerHTML = ""; });

// A wallet page as the red packet plugin declares it: fields, a recent list, an action and a next page.
const wallet: FlarePluginViewModel = {
  available: true,
  title: "钱包",
  fields: [],
  actions: [{ id: "history", label: "全部明细" }],
  blocks: [
    { kind: "fields", fields: [{ label: "可用余额", value: "¥12.30" }, { label: "红包托管中", value: "¥3.00" }] },
    { kind: "entries", items: [{ index: 1, text: "-¥3.00", userId: "u_alice01" }], numbered: false, total: 1, more: false },
  ],
  nextCursor: "page-2",
};

function render(props: Record<string, unknown>, { pointer = "fine" as "fine" | "coarse", refresh = true } = {}) {
  const state = reactive<Record<string, unknown>>({ title: "钱包", back: true, ...props });
  const events: Array<[string, ...unknown[]]> = [];
  const wrapper = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      useFlarePlatformProvider({ capabilities: { pointer } });
      return () => h(FlarePluginPage as never, {
        ...state,
        onBack: () => events.push(["back"]),
        ...(refresh ? { onRefresh: () => events.push(["refresh"]) } : {}),
        onRetry: () => events.push(["retry"]),
        onLoadMore: (cursor: string) => events.push(["loadMore", cursor]),
        onAction: (id: string, payload: FlarePluginActionPayload) => events.push(["action", id, payload]),
      });
    },
  }), { attachTo: document.body });
  return { wrapper, state, events };
}

function touch(el: Element, type: string, y: number) {
  const event = new Event(type, { bubbles: true, cancelable: true }) as Event & { touches: Array<{ clientY: number }> };
  Object.defineProperty(event, "touches", { value: type === "touchend" ? [] : [{ clientY: y }] });
  el.dispatchEvent(event);
}

describe("FlarePluginPage", () => {
  it("spins on the first load under the host's title, then draws the view with the shared renderer", async () => {
    const page = render({ loading: true });
    await flushPromises();
    expect(page.wrapper.get(".flare-plugin-page").attributes("data-state")).toBe("loading");
    expect(page.wrapper.text()).toContain("加载中");
    page.state.loading = false;
    page.state.view = wallet;
    await flushPromises();
    const view = page.wrapper.getComponent(FlarePluginView);
    expect(view.props("embedded")).toBe(true);
    expect(page.wrapper.get("h1").text()).toBe("钱包");
    expect(page.wrapper.text()).toContain("¥12.30");
  });

  it("shows a failed first load with a retry key, and a failed refresh as a banner above the view", async () => {
    const page = render({ error: "加载失败" });
    await flushPromises();
    expect(page.wrapper.get("[role=alert]").text()).toBe("加载失败");
    await page.wrapper.get("[data-page-retry]").trigger("click");
    expect(page.events).toEqual([["retry"]]);
    page.state.view = wallet;
    await flushPromises();
    expect(page.wrapper.find("[data-page-retry]").exists()).toBe(false);
    expect(page.wrapper.text()).toContain("加载失败");
    expect(page.wrapper.text()).toContain("¥12.30");
  });

  it("loads the next page once per cursor", async () => {
    const page = render({ view: wallet });
    await flushPromises();
    await page.wrapper.get("[data-page-load-more]").trigger("click");
    await page.wrapper.get("[data-page-load-more]").trigger("click");
    expect(page.events).toEqual([["loadMore", "page-2"]]);
    page.state.view = { ...wallet, nextCursor: undefined };
    await flushPromises();
    expect(page.wrapper.find("[data-page-load-more]").exists()).toBe(false);
  });

  it("has a refresh key on pointer devices and only when the host refreshes", async () => {
    const page = render({ view: wallet });
    await flushPromises();
    await page.wrapper.get("[data-page-refresh]").trigger("click");
    expect(page.events).toEqual([["refresh"]]);
    const none = render({ view: wallet }, { refresh: false });
    await flushPromises();
    expect(none.wrapper.find("[data-page-refresh]").exists()).toBe(false);
    const touchPage = render({ view: wallet }, { pointer: "coarse" });
    await flushPromises();
    expect(touchPage.wrapper.find("[data-page-refresh]").exists()).toBe(false);
  });

  it("refreshes on a pull past the threshold, not on a short one", async () => {
    const page = render({ view: wallet }, { pointer: "coarse" });
    await flushPromises();
    const scroller = page.wrapper.get(".flare-plugin-page__scroll").element;
    touch(scroller, "touchstart", 100);
    touch(scroller, "touchmove", 140);
    await flushPromises();
    expect(page.wrapper.get("[data-page-pull]").text()).toBe("下拉刷新");
    touch(scroller, "touchend", 140);
    expect(page.events).toEqual([]);
    touch(scroller, "touchstart", 100);
    touch(scroller, "touchmove", 260);
    await flushPromises();
    expect(page.wrapper.get("[data-page-pull]").text()).toBe("松开刷新");
    touch(scroller, "touchend", 260);
    expect(page.events).toEqual([["refresh"]]);
    page.state.refreshing = true;
    await flushPromises();
    expect(page.wrapper.get("[data-page-pull]").text()).toBe("正在刷新");
  });

  it("passes the page's actions through and goes back", async () => {
    const page = render({ view: wallet });
    await flushPromises();
    await page.wrapper.get("[data-action-id=history]").trigger("click");
    await page.wrapper.get(".flare-screen__back").trigger("click");
    expect(page.events).toEqual([["action", "history", {}], ["back"]]);
  });

  it("draws no back key unless asked", async () => {
    const page = render({ view: wallet, back: false });
    await flushPromises();
    expect(page.wrapper.find(".flare-screen__back").exists()).toBe(false);
  });
});
