// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h, reactive } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type { FlarePluginViewModel } from "../../shared/contracts/plugin-ui";
import FlarePluginDetailSheet from "./FlarePluginDetailSheet.vue";
import FlarePluginView from "./FlarePluginView.vue";

enableAutoUnmount(afterEach);
afterEach(() => { document.body.innerHTML = ""; });

const detail: FlarePluginViewModel = {
  available: true,
  title: "接龙全部条目",
  fields: [],
  actions: [],
  blocks: [{ kind: "entries", items: [{ index: 1, text: "《三体》", userId: "u_alice01" }], numbered: true, total: 1, more: false }],
};

function render(props: Record<string, unknown>) {
  const state = reactive<Record<string, unknown>>({ open: true, title: "周末读书会报名", ...props });
  let retries = 0;
  let closes = 0;
  const pages: string[] = [];
  const wrapper = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlarePluginDetailSheet as never, {
        ...state,
        onRetry: () => { retries += 1; },
        onClose: () => { closes += 1; },
        onLoadMore: (cursor: string) => pages.push(cursor),
      });
    },
  }), { attachTo: document.body });
  return { wrapper, state, pages, retries: () => retries, closes: () => closes };
}
const root = () => document.body.querySelector(".flare-plugin-detail") as HTMLElement;

describe("FlarePluginDetailSheet", () => {
  it("spins while loading under the card's title", async () => {
    render({ loading: true });
    await flushPromises();
    expect(root().dataset.state).toBe("loading");
    expect(document.body.textContent).toContain("周末读书会报名");
    expect(document.body.textContent).toContain("加载中");
  });

  it("shows the host's error with a retry key", async () => {
    const sheet = render({ error: "加载失败，请稍后再试" });
    await flushPromises();
    expect(root().dataset.state).toBe("error");
    expect(root().querySelector("[role=alert]")!.textContent).toBe("加载失败，请稍后再试");
    (root().querySelector("[data-detail-retry]") as HTMLButtonElement).click();
    expect(sheet.retries()).toBe(1);
  });

  it("renders the detail view embedded, titled by the view", async () => {
    const sheet = render({ loading: true });
    sheet.state.loading = false;
    sheet.state.view = detail;
    await flushPromises();
    expect(root().dataset.state).toBe("loaded");
    expect(root().querySelector(".flare-plugin-view")!.classList).toContain("is-embedded");
    expect(root().textContent).toContain("《三体》");
    expect(document.body.textContent).toContain("接龙全部条目");
  });

  it("hands the detail's action error, form errors, members and settle token to the embedded view", async () => {
    const members = [{ userId: "u_alice01", name: "Alice" }];
    const formErrors = [{ input: "line", issue: "duplicateItem" }];
    const sheet = render({ view: detail, busyActionId: "join", actionError: "提交失败", formErrors, members, settleToken: 3 });
    await flushPromises();
    const view = sheet.wrapper.findComponent(FlarePluginView);
    expect(view.props("busyActionId")).toBe("join");
    expect(view.props("error")).toBe("提交失败");
    expect(view.props("formErrors")).toEqual(formErrors);
    expect(view.props("members")).toEqual(members);
    expect(view.props("settleToken")).toBe(3);
    // The action's failure shows inside the sheet, under the view; the sheet stays loaded (no retry key).
    expect(root().dataset.state).toBe("loaded");
    expect(root().textContent).toContain("提交失败");
    expect(root().querySelector("[data-detail-retry]")).toBeNull();
  });
});

type PagingExpect = { loadMore?: boolean; enabled?: boolean; spinning?: boolean; emit?: string | null };
type PagingStep = PagingExpect & { tap?: boolean; host?: { nextCursor?: string | null; actionError?: string; loadingMore?: boolean } };
const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/plugin-view-vectors.json"), "utf8")) as {
  views: Array<{ id: string; view: FlarePluginViewModel }>;
  detailPaging: Array<{ name: string; view: string; nextCursor: string | null; loadingMore: boolean; expect: PagingExpect; steps?: PagingStep[] }>;
};

describe("FlarePluginDetailSheet paging (spec/plugin-view-vectors.json detailPaging)", () => {
  const key = () => document.body.querySelector("[data-detail-load-more]") as HTMLButtonElement | null;
  async function check(sheet: ReturnType<typeof render>, fact: PagingExpect, emittedBefore: number): Promise<void> {
    if (fact.loadMore !== undefined) expect(Boolean(key()), "load more shown").toBe(fact.loadMore);
    if (fact.enabled !== undefined) expect(key()!.disabled, "load more disabled").toBe(!fact.enabled);
    if (fact.spinning !== undefined) expect(key()!.classList.contains("is-loading"), "spinning").toBe(fact.spinning);
    if (fact.emit !== undefined) expect(sheet.pages.slice(emittedBefore)).toEqual(fact.emit === null ? [] : [fact.emit]);
  }

  it.each(vectors.detailPaging.map((c) => [c.name, c] as const))("%s", async (_, c) => {
    const base = vectors.views.find((v) => v.id === c.view)!.view;
    const viewWith = (cursor: string | null) => (cursor === null ? { ...base } : { ...base, nextCursor: cursor });
    const sheet = render({ view: viewWith(c.nextCursor), loadingMore: c.loadingMore });
    await flushPromises();
    const { emit: initialEmit, ...initial } = c.expect;
    await check(sheet, initial, 0);
    if (initialEmit !== undefined) {
      key()!.click();
      await flushPromises();
      expect(sheet.pages).toEqual(initialEmit === null ? [] : [initialEmit]);
    }
    for (const step of c.steps ?? []) {
      const before = sheet.pages.length;
      if (step.tap) { key()!.click(); await flushPromises(); }
      if (step.host) {
        if ("nextCursor" in step.host) sheet.state.view = viewWith(step.host.nextCursor ?? null);
        if (step.host.actionError !== undefined) sheet.state.actionError = step.host.actionError;
        if (step.host.loadingMore !== undefined) sheet.state.loadingMore = step.host.loadingMore;
        await flushPromises();
      }
      await check(sheet, step, before);
    }
  });

  it("forgets the asked page when the host settles, so the same page can be asked again", async () => {
    const base = vectors.views.find((v) => v.id === "solitaire-more")!.view;
    const sheet = render({ view: { ...base, nextCursor: "page-2" }, settleToken: 0 });
    await flushPromises();
    key()!.click();
    await flushPromises();
    expect(key()!.disabled).toBe(true);
    sheet.state.settleToken = 1;
    await flushPromises();
    expect(key()!.disabled).toBe(false);
    key()!.click();
    await flushPromises();
    expect(sheet.pages).toEqual(["page-2", "page-2"]);
  });
});
