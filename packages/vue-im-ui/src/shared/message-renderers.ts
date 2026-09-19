import { inject, provide, type Component, type InjectionKey } from "vue";

export type FlareMessageRendererRegistry = Readonly<Record<string, Component>>;

const flareMessageRendererKey: InjectionKey<FlareMessageRendererRegistry> = Symbol("flare-message-renderers");

export function provideFlareMessageRenderers(renderers: FlareMessageRendererRegistry): void {
  provide(flareMessageRendererKey, renderers);
}

export function useFlareMessageRenderers(): FlareMessageRendererRegistry {
  return inject(flareMessageRendererKey, {});
}

