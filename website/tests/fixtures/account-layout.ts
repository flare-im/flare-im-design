import { createApp, h, type App } from "vue";
import FlarePluginPage from "../../../packages/vue-im-ui/src/components/messages/FlarePluginPage.vue";
import { useFlareI18nProvider } from "../../../packages/vue-im-ui/src/shared/i18n/useFlareI18n";
import { useViewportProvider } from "../../../packages/vue-im-ui/src/composables/useViewport";
import type { FlarePluginPageActionPayload, FlarePluginPageViewModel } from "../../../packages/vue-im-ui/src/shared/contracts/plugin-ui";
import vectors from "../../../spec/account-layout-vectors.json";

let app: App | undefined;
export const emittedLayoutActions: Array<{ id: string; payload: FlarePluginPageActionPayload }> = [];

/** Fictional display data rendered by the production Kit. No SDK or financial request. */
export function mountAccountLayoutFixture(index: number, state = "loaded", width?: number | null) {
  app?.unmount();
  emittedLayoutActions.length = 0;
  const item = vectors.cases[index];
  const host = document.createElement("div");
  host.style.cssText = "height:100vh;width:100%;background:var(--flare-color-bg-primary);color:var(--flare-color-text-primary)";
  document.body.style.margin = "0";
  document.body.replaceChildren(host);
  app = createApp({ setup() {
    useFlareI18nProvider(item.locale as "zh-CN" | "en-US");
    useViewportProvider();
    return () => h(FlarePluginPage, {
      page: { pluginId: "fixture.wallet", page: item.page }, title: item.view.title,
      ...(width === undefined ? {} : { contentMaxWidth: width }),
      ...(state === "loading" ? { loading: true } : state === "error" ? { error: "Please try again" } : {
        view: { ...item.view, ...(state === "unavailable" ? { available: false, unavailableReason: "feature_disabled" } : {}), ...(state === "document" ? { presentation: undefined } : {}) } as unknown as FlarePluginPageViewModel,
      }),
      back: true, onRefresh: () => undefined,
      onAction: (id: string, payload: FlarePluginPageActionPayload) => emittedLayoutActions.push({ id, payload }),
    });
  } });
  app.mount(host);
}
