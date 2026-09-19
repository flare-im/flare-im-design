import type { FlareMediaResolveRequest } from "../shared/contracts/media";
import type { ContentElem } from "./contentElem";
import { pickNestedPayload } from "./contentElem";
import { asRecord, readString } from "./contentData";
import { buildMediaResolveRequest, readMediaLocalPath } from "./mediaResolveRequest";

// How the timeline asks the host's media resolver for a picture: an image message's picture, or one picture of an
// album. The picture bodies and the conversation's gallery build the same requests, so a picture the gallery shows
// is the picture its body drew.

/** An image message's picture payload: the nested `image` record, else the content itself. */
export function imageMessagePayload(content: ContentElem): Record<string, unknown> {
  const nested = pickNestedPayload(content, "image");
  return Object.keys(nested).length ? nested : (content as Record<string, unknown>);
}

/** The full-size picture of an image message. */
export function imageSourceRequest(payload: Record<string, unknown>, messageId?: string): FlareMediaResolveRequest | null {
  const source = asRecord(payload.source);
  return buildMediaResolveRequest({
    kind: "image",
    messageId,
    url: readString(source, "url", "localPreviewUrl", "downloadUrl") || readString(payload, "url", "localPreviewUrl", "downloadUrl"),
    id: readString(source, "imageId", "fileId", "id", "uuid") || readString(payload, "imageId", "fileId", "id", "uuid"),
    localPath: readMediaLocalPath(source, payload),
    mimeType: readString(source, "mimeType") || readString(payload, "mimeType"),
    fileName: readString(payload, "fileName", "title"),
  });
}

/** The thumbnail of an image message, else its full-size picture. */
export function imageThumbnailRequest(payload: Record<string, unknown>, messageId?: string): FlareMediaResolveRequest | null {
  const source = asRecord(payload.source);
  const thumbnail = asRecord(payload.thumbnail);
  return buildMediaResolveRequest({
    kind: "imageThumbnail",
    messageId,
    url:
      readString(thumbnail, "url", "localPreviewUrl", "downloadUrl") ||
      readString(payload, "thumbnailUrl", "localPreviewUrl", "snapshotUrl") ||
      readString(source, "url", "localPreviewUrl", "downloadUrl") ||
      readString(payload, "url", "localPreviewUrl", "downloadUrl"),
    id:
      readString(thumbnail, "imageId", "fileId", "id", "uuid") ||
      readString(payload, "thumbnailId", "thumbnailFileId", "thumbnailUuid") ||
      readString(source, "imageId", "fileId", "id", "uuid") ||
      readString(payload, "imageId", "fileId", "id", "uuid"),
    localPath: readMediaLocalPath(thumbnail, payload) || readMediaLocalPath(source, payload),
    mimeType: readString(thumbnail, "mimeType") || readString(source, "mimeType"),
    fileName: readString(payload, "fileName", "title"),
  });
}

/** The name a picture of an album is saved under. */
export function imageGroupItemFileName(image: Record<string, unknown>, index: number): string {
  return (
    readString(image, "fileName", "title") ||
    readString(asRecord(image.source), "fileName", "name", "title") ||
    `image-${index + 1}`
  );
}

/** The full-size picture at `index` of an album. */
export function imageGroupItemRequest(image: Record<string, unknown>, index: number, messageId?: string): FlareMediaResolveRequest | null {
  const source = asRecord(image.source);
  return buildMediaResolveRequest({
    kind: "imageGroupItem",
    messageId,
    url: readString(source, "url", "localPreviewUrl", "downloadUrl") || readString(image, "url", "localPreviewUrl", "downloadUrl"),
    id: readString(source, "imageId", "fileId", "id", "uuid") || readString(image, "imageId", "fileId", "id", "uuid"),
    localPath: readMediaLocalPath(source, image),
    mimeType: readString(source, "mimeType") || readString(image, "mimeType"),
    fileName: imageGroupItemFileName(image, index),
  });
}

/** The thumbnail of the picture at `index` of an album, else its full-size picture. */
export function imageGroupItemThumbnailRequest(image: Record<string, unknown>, index: number, messageId?: string): FlareMediaResolveRequest | null {
  const source = asRecord(image.source);
  const thumbnail = asRecord(image.thumbnail);
  const fullUrl = readString(source, "url", "localPreviewUrl", "downloadUrl") || readString(image, "url", "localPreviewUrl", "downloadUrl");
  const fullId = readString(source, "imageId", "fileId", "id", "uuid") || readString(image, "imageId", "fileId", "id", "uuid");
  return buildMediaResolveRequest({
    kind: "imageThumbnail",
    messageId,
    url: readString(thumbnail, "url", "localPreviewUrl", "downloadUrl") || readString(image, "thumbnailUrl", "snapshotUrl") || fullUrl,
    id: readString(thumbnail, "imageId", "fileId", "id", "uuid") || fullId,
    localPath: readMediaLocalPath(thumbnail, image),
    mimeType: readString(thumbnail, "mimeType") || readString(source, "mimeType") || readString(image, "mimeType"),
    fileName: imageGroupItemFileName(image, index),
  });
}
