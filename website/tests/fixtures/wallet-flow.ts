import { createApp, h, type App } from "vue";
import FlarePluginPage from "../../../packages/vue-im-ui/src/components/messages/FlarePluginPage.vue";
import { useFlareI18nProvider } from "../../../packages/vue-im-ui/src/shared/i18n/useFlareI18n";
import { useViewportProvider } from "../../../packages/vue-im-ui/src/composables/useViewport";
import type { FlarePluginPageViewModel } from "../../../packages/vue-im-ui/src/shared/contracts/plugin-ui";
import type { FlarePluginPageActionPayload } from "../../../packages/vue-im-ui/src/shared/contracts/plugin-ui";
import vectors from "../../../spec/wallet-flow-vectors.json";
import cards from "../../../spec/wallet-card-vectors.json";

let app: App | undefined;
export const cases = vectors.cases;
export const emittedWalletActions: Array<{id: string; payload: FlarePluginPageActionPayload}> = [];

/** Production components with Rust-resolved display data; no financial requests. */
export function mountWalletFixture(index: number) {
  mountWalletView(cases[index]);
}
export function mountMultipleWalletFixture() {
  mountWalletView(cards.cases[0]);
}
function mountWalletView(item: {locale: string; page: string; view: unknown}) {
  app?.unmount();
  emittedWalletActions.length = 0;
  const host = document.createElement("div");
  host.style.cssText = "height:100vh;width:100%;background:var(--flare-color-bg-primary);color:var(--flare-color-text-primary)";
  document.body.style.margin = "0";
  document.body.replaceChildren(host);
  app = createApp({ setup() {
    useFlareI18nProvider(item.locale as "zh-CN" | "en-US");
    useViewportProvider();
    return () => h(FlarePluginPage, {
      page: { pluginId: "flare.wallet", page: item.page },
      view: item.view as unknown as FlarePluginPageViewModel,
      back: true,
      onRefresh: () => undefined,
      onAction: (id: string, payload: FlarePluginPageActionPayload) => emittedWalletActions.push({id, payload}),
    });
  } });
  app.mount(host);
}
