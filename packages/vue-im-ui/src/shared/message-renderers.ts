import { inject, provide, type Component, type InjectionKey } from "vue";
import type { FlareMessageRegisteredSurface } from "./contracts/message-surface";

/**
 * A registered content renderer with options. `surface` names the surface of a content type the kit does not know
 * (spec/message-surface-vectors.json): `card` when the renderer draws its own shell, `bareMedia` when the media is the
 * surface. The kit already treats every custom and plugin content as a card, so a renderer for those needs none.
 */
export interface FlareMessageRendererEntry {
  component: Component;
  surface?: FlareMessageRegisteredSurface;
}

/**
 * Renderers by content key (`contentType:subtype`, `contentType`, or the view key). A value is the
 * component itself or a {@link FlareMessageRendererEntry}. The renderer receives the content view's
 * props plus `messageId` (the server id, else the client id), `conversationId` when known, `senderId`
 * and `senderName` (the display name the host gave the sender, trimmed; absent when it gave none — never
 * the id or a placeholder, so "X 的红包" needs no lookup by message id), and `selectionMode: true` while
 * its row is in multi-select (its controls must not respond then). spec dataTypes MessageRenderContext.
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
 * Whether the content being drawn sits in a row that is in multi-select. Kit content components (plugin cards,
 * red packets, polls) read it to stay inert, so a tap goes to the row and toggles its selection.
 */
const flareContentSelectionKey: InjectionKey<() => boolean> = Symbol("flare-content-selection");

export function provideFlareContentSelection(selecting: () => boolean): void {
  provide(flareContentSelectionKey, selecting);
}

/**
 * Inside a content renderer: whether its row is in multi-select right now (false outside a message row). A host
 * renderer that draws its own controls reads it to keep them inert; the `selectionMode` prop says the same.
 */
export function useFlareContentSelection(): () => boolean {
  return inject(flareContentSelectionKey, () => false);
}

/**
 * The quoted reply of a card message (C1: a card keeps its surface and draws the quote inside its shell, at the top).
 * The bubble provides it; a card shell that draws it (PluginView) claims it, so the bubble does not draw it again.
 */
export interface FlareMessageQuoteContext {
  /** The row's message is a card that replies to another message. */
  active: () => boolean;
  /** One-line summary of the quoted message. */
  preview: () => string;
  /** What a tap on the quote does, when it can reach the quoted message. */
  locate: () => (() => void) | undefined;
  /** A shell drew the quote. */
  claim: () => void;
}
const flareMessageQuoteKey: InjectionKey<FlareMessageQuoteContext | null> = Symbol("flare-message-quote");

export function provideFlareMessageQuote(context: FlareMessageQuoteContext | null): void {
  provide(flareMessageQuoteKey, context);
}

export function useFlareMessageQuote(): FlareMessageQuoteContext | null {
  return inject(flareMessageQuoteKey, null);
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
