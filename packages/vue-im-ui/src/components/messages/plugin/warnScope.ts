import { inject, provide, type InjectionKey } from "vue";

const KEY: InjectionKey<() => string> = Symbol("flare-plugin-warn-scope");

/** R3: FlarePluginPage names the plugin and page that its blocks' development warnings come from. */
export function provideFlarePluginWarnScope(scope: () => string): void {
  provide(KEY, scope);
}

/** A warning context led by "pluginId/page" on a plugin page (the bare `where` elsewhere). */
export function useFlarePluginWarnScope(): (where: string) => string {
  const scope = inject(KEY, () => "");
  return (where) => {
    const lead = scope();
    return lead ? `${lead} ${where}` : where;
  };
}
