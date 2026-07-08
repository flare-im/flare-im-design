import { inject, provide, type InjectionKey } from "vue";
import { useFlareCoreClient } from "flare-core-vue-im-ui/composables";
import { createProductionAppClient } from "../infrastructure/sdk/createProductionAppClient";
import { devMediaHttpBaseUrl } from "../runtime/mediaProxy";
import {
  appTransportSelectorTlsCaCertPath,
  appTransportSelectorRuntimeStatus,
  isAppTransportSelectorEnabled,
} from "../infrastructure/transport/appTransportSelector";

export type FlareSdkContext = ReturnType<typeof useFlareCoreClient>;

export const flareSdkKey: InjectionKey<FlareSdkContext> = Symbol("flare-sdk");

let flareSdkSingleton: FlareSdkContext | null = null;

export function getFlareSdkSingleton(): FlareSdkContext | null {
  return flareSdkSingleton;
}

export function provideFlareSdk(): FlareSdkContext {
  const nativeTransportSelectionEnabled = isAppTransportSelectorEnabled();
  const sdk = useFlareCoreClient({
    createClient: createProductionAppClient,
    env: import.meta.env as Record<string, string | undefined>,
    defaultHttpUrl: devMediaHttpBaseUrl(),
    defaultTlsCaCertPath: appTransportSelectorTlsCaCertPath(),
    nativeTransportSelectionEnabled,
    runtimeStatus: nativeTransportSelectionEnabled ? appTransportSelectorRuntimeStatus() : "browser-wasm",
  });
  flareSdkSingleton = sdk;
  provide(flareSdkKey, sdk);
  return sdk;
}

export function useFlareSdk(): FlareSdkContext {
  const sdk = inject(flareSdkKey);
  if (!sdk) {
    throw new Error("Flare SDK context is missing. Mount provideFlareSdk() in App.vue.");
  }
  return sdk;
}
