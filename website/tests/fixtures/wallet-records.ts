import { createApp, h, type App } from "vue";
import FlarePluginPage from "../../../packages/vue-im-ui/src/components/messages/FlarePluginPage.vue";
import { useFlareI18nProvider } from "../../../packages/vue-im-ui/src/shared/i18n/useFlareI18n";
import { useViewportProvider } from "../../../packages/vue-im-ui/src/composables/useViewport";
import type { FlarePluginPageViewModel } from "../../../packages/vue-im-ui/src/shared/contracts/plugin-ui";
import vectors from "../../../spec/wallet-record-vectors.json";

let app: App | undefined;
let requests: unknown[] = [];
export const recordCases = vectors.cases;
export function recordRequests() { return requests; }

/** Rust-resolved display fixtures; requests are recorded, never executed or filtered locally. */
export function mountRecordFixture(index: number, mode: "ready" | "loading" | "error" | "empty" | "readError" | "longAmount" = "ready") {
  app?.unmount();
  requests = [];
  const item = recordCases[index];
  let view = structuredClone({...item.view, data: item.sourceData}) as unknown as FlarePluginPageViewModel;
  if (mode === "empty") view.blocks = view.blocks?.map(block => block.kind === "rows" ? {...block, rows: []} : block);
  // A display-only overflow probe, distinct from the canonical resolved financial samples. It executes no action.
  if (mode === "longAmount") {
    const records = view.blocks?.find(block => block.kind === "rows");
    if (records?.kind === "rows" && records.rows[0]) records.rows[0].cells[0].text = "+123,456,789,012,345,678,901,234,567.89";
  }
  const host = document.createElement("div");
  host.style.cssText = "height:100vh;width:100%;background:var(--flare-color-bg-primary);color:var(--flare-color-text-primary)";
  document.body.style.margin = "0";
  document.body.replaceChildren(host);
  app = createApp({setup() {
    useFlareI18nProvider(item.locale as "zh-CN" | "en-US");
    useViewportProvider();
    return () => h(FlarePluginPage, {
      page: {pluginId: "flare.wallet", page: item.page},
      title: item.view.title,
      view: mode === "loading" || mode === "error" ? undefined : view,
      filters: item.filters,
      loading: mode === "loading",
      error: mode === "error" || mode === "readError" ? (item.locale === "zh-CN" ? "记录读取失败，请重试" : "Records could not be loaded. Try again.") : undefined,
      back: true,
      onRefresh: () => requests.push({kind: "refresh"}),
      onRetry: () => requests.push({kind: "retry"}),
      onFilter: filters => requests.push({kind: "filter", filters}),
      onLoadMore: cursor => requests.push({kind: "more", cursor}),
      onAction: (id, payload) => requests.push({kind: "action", id, payload}),
    });
  }});
  app.mount(host);
}
