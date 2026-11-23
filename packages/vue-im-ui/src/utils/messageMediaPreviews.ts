import type { FlareMediaResolveRequest } from "../shared/contracts/media";

/** This browser session's selected media, kept across the pending-to-sent message update. */
export function createMessageMediaPreviews() {
  const entries = new Map<string, { urls: string[]; serverId?: string }>();
  const clientsByServerId = new Map<string, string>();

  function release(clientMsgId: string) {
    const entry = entries.get(clientMsgId);
    if (!entry) return;
    for (const url of entry.urls) {
      if (url) URL.revokeObjectURL(url);
    }
    if (entry.serverId) clientsByServerId.delete(entry.serverId);
    entries.delete(clientMsgId);
  }

  return {
    retain(clientMsgId: string, files: readonly Blob[]) {
      if (!clientMsgId || !files.length) return;
      release(clientMsgId);
      entries.set(clientMsgId, { urls: files.map((file) => URL.createObjectURL(file)) });
      // Keep recent previews without holding selected files for the lifetime of an entire chat history.
      if (entries.size > 32) {
        const oldest = entries.keys().next().value;
        if (oldest) release(oldest);
      }
    },
    acknowledge(clientMsgId: string, serverId: string) {
      const entry = entries.get(clientMsgId);
      if (!entry || !serverId || entry.serverId === serverId) return;
      if (entry.serverId) clientsByServerId.delete(entry.serverId);
      entry.serverId = serverId;
      clientsByServerId.set(serverId, clientMsgId);
    },
    resolve({ kind, messageId, mediaIndex = 0, skipLocalPreview }: FlareMediaResolveRequest) {
      if (!messageId || !["image", "imageThumbnail", "imageGroupItem", "video"].includes(kind)) return undefined;
      const entry = entries.get(clientsByServerId.get(messageId) ?? messageId);
      const url = entry?.urls[mediaIndex];
      if (entry && url && skipLocalPreview) {
        URL.revokeObjectURL(url);
        entry.urls[mediaIndex] = "";
        return undefined;
      }
      return url || undefined;
    },
    release,
    clear() {
      for (const id of entries.keys()) release(id);
    },
  };
}
