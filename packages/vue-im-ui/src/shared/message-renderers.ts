import { inject, provide, type Component, type InjectionKey } from "vue";

/**
 * A registered content renderer with options. `bare` draws the content the way the timeline draws a
 * lone picture: no bubble surface and no bubble padding, while the row keeps its avatar, name, time,
 * selection and menu. Use it for content that brings its own surface (a red packet card).
 */
export interface FlareMessageRendererEntry {
  component: Component;
  bare?: boolean;
}

/**
 * Renderers by content key (`contentType:subtype`, `contentType`, or the view key). A value is the
 * component itself or a {@link FlareMessageRendererEntry}. The renderer receives the content view's
 * props plus `messageId` (the server id, else the client id) and `conversationId` when known.
 */
export type FlareMessageRendererRegistry = Readonly<Record<string, Component | FlareMessageRendererEntry>>;

const flareMessageRendererKey: InjectionKey<FlareMessageRendererRegistry> = Symbol("flare-message-renderers");

export function provideFlareMessageRenderers(renderers: FlareMessageRendererRegistry): void {
  provide(flareMessageRendererKey, renderers);
}

export function useFlareMessageRenderers(): FlareMessageRendererRegistry {
  return inject(flareMessageRendererKey, {});
}

function isEntry(value: Component | FlareMessageRendererEntry): value is FlareMessageRendererEntry {
  return typeof value === "object" && value !== null && "component" in value;
}

/** The registered renderer for a content's keys, most specific first, as an entry. */
export function resolveFlareMessageRenderer(
  registry: FlareMessageRendererRegistry,
  keys: ReadonlyArray<string>,
): FlareMessageRendererEntry | undefined {
  for (const key of keys) {
    const value = key ? registry[key] : undefined;
    if (value) return isEntry(value) ? value : { component: value };
  }
  return undefined;
}

/**
 * The conversation the timeline shows, handed to content renderers by the message list so a row
 * does not have to carry it.
 */
const flareRenderConversationKey: InjectionKey<() => string | undefined> = Symbol("flare-render-conversation");

export function provideFlareRenderConversation(conversationId: () => string | undefined): void {
  provide(flareRenderConversationKey, conversationId);
}

export function useFlareRenderConversation(): () => string | undefined {
  return inject(flareRenderConversationKey, () => undefined);
}
