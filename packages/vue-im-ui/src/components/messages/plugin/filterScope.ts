import { inject, provide, type InjectionKey } from "vue";

/** §5.8: whether the page's filters narrow its records, and the key that sets them all back to all. */
export interface FlarePluginFilterScope {
  active: () => boolean;
  clear: () => void;
}
const KEY: InjectionKey<FlarePluginFilterScope> = Symbol("flare-plugin-filter-scope");

export function provideFlarePluginFilterScope(scope: FlarePluginFilterScope): void {
  provide(KEY, scope);
}

/** The plugin page's filters, or none outside a page. */
export function useFlarePluginFilterScope(): FlarePluginFilterScope | undefined {
  return inject(KEY, undefined);
}
