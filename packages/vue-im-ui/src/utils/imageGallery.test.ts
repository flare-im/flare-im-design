import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import type { MessageLike } from "../shared/contracts/messageRow";
import { flareImageGalleryItems, flareImageGalleryRequest, flareImageGalleryStart } from "./imageGallery";

/** The shared table (`spec/image-gallery-vectors.json`); the three native kits read the same file. */
const table = JSON.parse(
  readFileSync(resolve(__dirname, "../../../../spec/image-gallery-vectors.json"), "utf8"),
) as {
  cases: {
    id: string;
    messages: { id: string; kind: string; images?: string[]; recalled?: boolean }[];
    items: string[];
    opens: { message: string; index: number; start: number | null }[];
  }[];
};

/** A picture as the core carries it: an address, a stored media id, or nothing to load. */
function picture(ref: string): Record<string, unknown> {
  if (!ref) return {};
  return ref.startsWith("https://") ? { url: ref } : { imageId: ref };
}

function message(raw: { id: string; kind: string; images?: string[]; recalled?: boolean }): MessageLike {
  const refs = raw.images ?? [];
  const content =
    raw.kind === "image" ? { contentType: "image", image: picture(refs[0] ?? "") }
    : raw.kind === "imageGroup" ? { contentType: "image_group", image_group: { images: refs.map(picture) } }
    : raw.kind === "sticker" ? { contentType: "sticker", sticker: { url: "https://cdn.example/s.webp" } }
    : raw.kind === "video" ? { contentType: "video", video: { url: "https://cdn.example/v.mp4" } }
    : { contentType: "text", text: "see you tomorrow" };
  return {
    serverId: `server-${raw.id}`, clientMsgId: raw.id, senderId: "u", senderDisplayName: "U",
    conversationSeq: 1, createdAt: 1, clientCreatedAt: 1, messageType: 1, content, status: "read",
    isRecalled: raw.recalled === true, isRead: true, timelineKey: `client:${raw.id}`, timelineSortTs: 1, attributes: {},
  } as MessageLike;
}

describe("a conversation's image gallery", () => {
  it("reads the whole shared table", () => {
    expect(table.cases.length).toBeGreaterThanOrEqual(4);
  });

  for (const c of table.cases) {
    it(c.id, () => {
      const items = flareImageGalleryItems(c.messages.map(message));
      expect(items.map((item) => `${item.messageId}#${item.index}`)).toEqual(c.items);
      for (const open of c.opens) {
        expect(flareImageGalleryStart(items, open.message, open.index), `${open.message}#${open.index}`).toBe(open.start);
      }
    });
  }

  it("asks the resolver for the full-size picture, else its thumbnail", () => {
    const [album, thumbOnly] = flareImageGalleryItems([
      message({ id: "a", kind: "imageGroup", images: ["img-7"] }),
      { ...message({ id: "t", kind: "image" }), content: { contentType: "image", image: { thumbnail: { url: "https://cdn.example/t.jpg" } } } } as MessageLike,
    ]);
    expect(flareImageGalleryRequest(album)).toMatchObject({ kind: "imageGroupItem", messageId: "a", fileId: "img-7" });
    expect(flareImageGalleryRequest(thumbOnly)).toMatchObject({ kind: "imageThumbnail", messageId: "t", url: "https://cdn.example/t.jpg" });
  });
});
