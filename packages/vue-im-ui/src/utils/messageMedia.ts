import { resolveMessageId, type MessageLike } from "../shared/contracts/messageRow";
import { asRecord, readArray, readString } from "./contentData";
import {
  normalizeToContentElem,
  pickNestedPayload,
  type ContentElem,
} from "./contentElem";
import {
  isInlineBrowserMediaUrl,
  isLocalMediaPath,
  mediaPathFromId,
  readMediaLocalPath,
} from "./mediaResolveRequest";
import { safeDownloadFileName } from "./browserDownload";
import { messageContentTypeForUi } from "./messageContent";

export type MessageMediaDownloadKind = "image" | "video" | "file";

export interface MessageMediaDownloadSource {
  kind: MessageMediaDownloadKind;
  fileId: string;
  downloadKey: string;
  displayFileName: string;
  mimeType?: string;
  sourcePath?: string;
  sourceHttpUrl?: string;
  remoteFileId?: string;
  browserUrl?: string;
}

function messageKey(message: MessageLike): string {
  return resolveMessageId(message) || message.timelineKey;
}

function payloadFor(content: ContentElem, key: string): Record<string, unknown> {
  const nested = pickNestedPayload(content, key);
  return Object.keys(nested).length ? nested : content;
}

function httpUrl(value: string): string {
  const v = value.trim();
  return v.startsWith("http://") || v.startsWith("https://") ? v : "";
}

function remoteFileIdFromValue(value: string): string {
  const v = value.trim();
  if (!v || isInlineBrowserMediaUrl(v) || httpUrl(v) || isLocalMediaPath(v)) {
    return "";
  }
  return v;
}

function localPathFromValue(value: string): string {
  const v = value.trim();
  if (!v || isInlineBrowserMediaUrl(v) || !isLocalMediaPath(v)) return "";
  return mediaPathFromId(v);
}

function descriptorFromFields(input: {
  message: MessageLike;
  ownMessage: boolean;
  kind: MessageMediaDownloadKind;
  index: number;
  payload: Record<string, unknown>;
  source?: Record<string, unknown>;
  idKeys: string[];
  fallbackName: string;
}): MessageMediaDownloadSource | null {
  const source = input.source ?? {};
  const id =
    readString(source, ...input.idKeys) ||
    readString(input.payload, ...input.idKeys);
  const directUrl =
    readString(source, "url", "downloadUrl", "localPreviewUrl") ||
    readString(input.payload, "url", "downloadUrl", "localPreviewUrl");
  // A path on this device is only a source for what this device sent: in someone else's message it is
  // text they chose, and saving it would copy one of this device's own files into the download folder.
  const sourcePath = input.ownMessage
    ? readMediaLocalPath(source, input.payload) || localPathFromValue(id) || localPathFromValue(directUrl)
    : "";
  const sourceHttpUrl = httpUrl(directUrl);
  const browserUrl = directUrl && !sourcePath && !localPathFromValue(directUrl) ? directUrl : "";
  const remoteFileId = sourcePath ? "" : remoteFileIdFromValue(id);
  const fileId = remoteFileId || sourceHttpUrl || sourcePath || browserUrl;
  if (!fileId) return null;
  const displayFileName = safeDownloadFileName(
    readString(source, "fileName", "name", "title") ||
      readString(input.payload, "fileName", "name", "title") ||
      input.fallbackName,
  );
  const stableSourceKey = remoteFileId || sourceHttpUrl || sourcePath || browserUrl;
  return {
    kind: input.kind,
    fileId,
    downloadKey: [
      "message-media",
      messageKey(input.message),
      input.kind,
      input.index,
      stableSourceKey,
    ].join(":"),
    displayFileName,
    mimeType:
      readString(source, "mimeType") ||
      readString(input.payload, "mimeType"),
    ...(sourcePath ? { sourcePath } : {}),
    ...(sourceHttpUrl ? { sourceHttpUrl } : {}),
    ...(remoteFileId ? { remoteFileId } : {}),
    ...(browserUrl ? { browserUrl } : {}),
  };
}

export interface MessageMediaDownloadOptions {
  /**
   * The signed-in user. A local file path in a message is used as the save source only when the
   * message is this user's own (a picture still uploading, say); without it no local path is used.
   */
  currentUserId?: string;
}

export function listMessageMediaDownloadSources(
  message: MessageLike,
  options: MessageMediaDownloadOptions = {},
): MessageMediaDownloadSource[] {
  const content = normalizeToContentElem(message.content);
  if (!content || message.isRecalled) return [];
  const ownMessage = Boolean(options.currentUserId) && message.senderId === options.currentUserId;
  const type = messageContentTypeForUi(content.contentType);
  if (type === "image") {
    const payload = payloadFor(content, "image");
    return [
      descriptorFromFields({
        message,
        ownMessage,
        kind: "image",
        index: 0,
        payload,
        source: asRecord(payload.source),
        idKeys: ["fileId", "imageId", "id", "uuid"],
        fallbackName: "image.jpg",
      }),
    ].filter(Boolean) as MessageMediaDownloadSource[];
  }
  if (type === "video") {
    const payload = payloadFor(content, "video");
    return [
      descriptorFromFields({
        message,
        ownMessage,
        kind: "video",
        index: 0,
        payload,
        source: asRecord(payload.source),
        idKeys: ["fileId", "videoId", "id", "uuid"],
        fallbackName: "video.mp4",
      }),
    ].filter(Boolean) as MessageMediaDownloadSource[];
  }
  if (type === "file") {
    const payload = payloadFor(content, "file");
    return [
      descriptorFromFields({
        message,
        ownMessage,
        kind: "file",
        index: 0,
        payload,
        idKeys: ["fileId", "id", "uuid"],
        fallbackName: "file",
      }),
    ].filter(Boolean) as MessageMediaDownloadSource[];
  }
  if (type === "image_group") {
    const payload = payloadFor(content, "image_group");
    return readArray(payload, "images")
      .map((item, index) =>
        descriptorFromFields({
          message,
          ownMessage,
          kind: "image",
          index,
          payload: asRecord(item),
          source: asRecord(asRecord(item).source),
          idKeys: ["fileId", "imageId", "id", "uuid"],
          fallbackName: `image-${index + 1}.jpg`,
        }),
      )
      .filter(Boolean) as MessageMediaDownloadSource[];
  }
  return [];
}

export function hasDownloadableMessageMedia(
  message: MessageLike,
  options: MessageMediaDownloadOptions = {},
): boolean {
  return listMessageMediaDownloadSources(message, options).length > 0;
}
