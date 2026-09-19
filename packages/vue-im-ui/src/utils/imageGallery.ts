import type { FlareMediaResolveRequest } from "../shared/contracts/media";
import { resolveMessageId, type MessageLike } from "../shared/contracts/messageRow";
import { asRecord, readArray, readString } from "./contentData";
import { normalizeToContentElem, pickNestedPayload } from "./contentElem";
import {
  imageGroupItemRequest,
  imageGroupItemThumbnailRequest,
  imageMessagePayload,
  imageSourceRequest,
  imageThumbnailRequest,
} from "./imageRequests";

/**
 * A conversation's image gallery: the pictures a full-screen preview opened from a timeline pages through. The rule
 * is shared with the three native kits (`spec/image-gallery-vectors.json`).
 */
export interface FlareImageGalleryItem {
  /** The message (`resolveMessageId`) the picture belongs to. */
  messageId: string;
  /** The picture's place in its own message. */
  index: number;
  /** An image message's picture, or one picture of an album. */
  kind: "image" | "imageGroupItem";
  /** The picture's payload as the message carries it. */
  image: Record<string, unknown>;
}

/**
 * Every picture of every image and album message in `messages` (timeline order, oldest first), skipping recalled
 * messages and pictures with nothing to load — no address and no stored media id.
 */
export function flareImageGalleryItems(messages: readonly MessageLike[]): FlareImageGalleryItem[] {
  const items: FlareImageGalleryItem[] = [];
  for (const message of messages) {
    if (message.isRecalled) continue;
    const content = normalizeToContentElem(message.content);
    if (content?.contentType === "image") {
      const image = imageMessagePayload(content);
      const item: FlareImageGalleryItem = { messageId: resolveMessageId(message), index: 0, kind: "image", image };
      if (flareImageGalleryRequest(item)) items.push(item);
    } else if (content?.contentType === "image_group") {
      const nested = pickNestedPayload(content, "image_group");
      const album = Object.keys(nested).length ? nested : (content as Record<string, unknown>);
      readArray(album, "images").forEach((raw, index) => {
        const item: FlareImageGalleryItem = { messageId: resolveMessageId(message), index, kind: "imageGroupItem", image: asRecord(raw) };
        if (flareImageGalleryRequest(item)) items.push(item);
      });
    }
  }
  return items;
}

/** Where a gallery of `items` starts for a tap on the picture at `index` of message `messageId`; null when it is not in it. */
export function flareImageGalleryStart(items: readonly FlareImageGalleryItem[], messageId: string, index: number): number | null {
  const at = items.findIndex((item) => item.messageId === messageId && item.index === index);
  return at < 0 ? null : at;
}

/** What the preview loads for `item`: its full-size picture, else its thumbnail; null when there is nothing to load. */
export function flareImageGalleryRequest(item: FlareImageGalleryItem): FlareMediaResolveRequest | null {
  return item.kind === "image"
    ? imageSourceRequest(item.image, item.messageId) ?? imageThumbnailRequest(item.image, item.messageId)
    : imageGroupItemRequest(item.image, item.index, item.messageId) ??
        imageGroupItemThumbnailRequest(item.image, item.index, item.messageId);
}

/** The picture's description, as its body names it. */
export function flareImageGalleryAlt(item: FlareImageGalleryItem): string {
  return item.kind === "image"
    ? readString(item.image, "description", "caption", "title")
    : readString(item.image, "description", "title");
}
