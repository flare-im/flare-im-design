import type { ComputedRef, InjectionKey, Ref } from "vue";

/** What a rich-text body shares with the runs it draws: whether its spoilers are revealed, and their name. */
export interface FlareRichDocSpoilers {
  revealed: Ref<boolean>;
  label: ComputedRef<string>;
}

export const FLARE_RICH_DOC_SPOILERS: InjectionKey<FlareRichDocSpoilers> = Symbol("flareRichDocSpoilers");
