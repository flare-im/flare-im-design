import type { InjectionKey, Ref } from "vue";

export interface PreviewContext {
  viewport: Ref<"mobile" | "desktop">;
  presentation: Ref<"isolated" | "chat" | "chat-footer" | "list" | "overlay" | "workspace">;
}

export const previewContextKey: InjectionKey<PreviewContext> = Symbol("flare-doc-preview");
