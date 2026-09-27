import { computed, reactive, watch, type ComputedRef } from "vue";
import type { MessageMenuConfig, MessageMenuResolveContext } from "../../shared/config/messageMenu";
import { resolveMessageId, type MessageLike } from "../../shared/contracts/messageRow";
import type { MessageMediaDownloadUiState } from "../../shared/contracts/media";
import { listMessageMediaDownloadSources, type MessageMediaDownloadSource } from "../../utils/messageMedia";

/**
 * What the host does for a message list's pictures, videos and files. The kit never touches the SDK: these are the
 * three calls it needs, each keyed by the source's `fileId` (the stored file's id, else its address) — the key the
 * core records a save under when the host passes no `downloadKey`.
 */
export interface MessageMediaSaveHost {
  /** Saves `source` to this device; rejects when it could not (the host says why). */
  save(source: MessageMediaDownloadSource, message: MessageLike): Promise<void>;
  /** Whether `key` is saved on this device and still there. Asked once per key when its message shows up. */
  isSaved(key: string): Promise<boolean>;
  /**
   * Shows the saved file of `key` — in the file manager, or wherever the platform can say it is. False when the file
   * is gone: its key becomes a download again.
   */
  reveal(key: string, source: MessageMediaDownloadSource, message: MessageLike): Promise<boolean>;
}

export interface MessageMediaSaves {
  /** For `FlareMessageList`'s `mediaDownloadStates`. */
  states: ComputedRef<Record<string, MessageMediaDownloadUiState>>;
  /** For `FlareMessageList`'s `menuConfig`: the menu offers "show in folder" for a saved file, else a download. */
  menuConfig: MessageMenuConfig;
  /** For `FlareMessageList`'s `mediaAction` event. */
  onMediaAction(messageId: string, action: "download" | "openFolder"): Promise<void>;
}

/**
 * A message list's save keys: a download until the file is saved, then its folder; a folder whose file is gone is a
 * download again, and the next save makes it a folder once more. Messages that carry the same file share the state.
 * An album keeps its own save flow (one key cannot stand for its pictures).
 */
export function useMessageMediaSaves(options: {
  messages: () => readonly MessageLike[];
  host: MessageMediaSaveHost;
  /** The signed-in user: a local path in their own message may be the save source. */
  currentUserId?: () => string | undefined;
}): MessageMediaSaves {
  const saved = reactive(new Set<string>());
  const downloading = reactive(new Set<string>());
  const asked = new Set<string>();

  function sourceOf(message: MessageLike): MessageMediaDownloadSource | undefined {
    const sources = listMessageMediaDownloadSources(message, { currentUserId: options.currentUserId?.() });
    return sources.length === 1 ? sources[0] : undefined;
  }

  const states = computed(() => {
    const out: Record<string, MessageMediaDownloadUiState> = {};
    for (const message of options.messages()) {
      const key = sourceOf(message)?.fileId;
      if (!key) continue;
      if (downloading.has(key)) out[resolveMessageId(message)] = "downloading";
      else if (saved.has(key)) out[resolveMessageId(message)] = "openFolder";
    }
    return out;
  });

  // One question per key, one at a time: a long history must not fan out a lookup per row at once.
  let queue: Promise<void> = Promise.resolve();
  watch(
    () => options.messages().map((message) => sourceOf(message)?.fileId ?? "").filter(Boolean),
    (keys) => {
      for (const key of keys) {
        if (asked.has(key)) continue;
        asked.add(key);
        queue = queue.then(async () => {
          if (saved.has(key) || downloading.has(key)) return;
          if (await options.host.isSaved(key).catch(() => false)) saved.add(key);
        });
      }
    },
    { immediate: true },
  );

  function find(messageId: string): { message: MessageLike; source: MessageMediaDownloadSource } | undefined {
    const message = options.messages().find((m) => resolveMessageId(m) === messageId);
    const source = message ? sourceOf(message) : undefined;
    return message && source ? { message, source } : undefined;
  }

  async function download(message: MessageLike, source: MessageMediaDownloadSource): Promise<void> {
    const key = source.fileId;
    if (downloading.has(key)) return;
    downloading.add(key);
    try {
      await options.host.save(source, message);
      saved.add(key);
    } catch {
      // The host said why; the key stays a download.
    } finally {
      downloading.delete(key);
    }
  }

  async function onMediaAction(messageId: string, action: "download" | "openFolder"): Promise<void> {
    const hit = find(messageId);
    if (!hit) return;
    const { message, source } = hit;
    if (action === "download" || !saved.has(source.fileId)) {
      await download(message, source);
      return;
    }
    if (!(await options.host.reveal(source.fileId, source, message).catch(() => true))) {
      saved.delete(source.fileId);
    }
  }

  const menuConfig: MessageMenuConfig = {
    resolveMediaAction: (ctx: MessageMenuResolveContext) =>
      states.value[resolveMessageId(ctx.message)] === "openFolder" ? "openMediaFolder" : "downloadMedia",
  };

  return { states, menuConfig, onMediaAction };
}
