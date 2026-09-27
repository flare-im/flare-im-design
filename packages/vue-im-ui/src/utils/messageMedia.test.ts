import { describe, expect, it } from "vitest";
import type { MessageLike } from "../shared/contracts/messageRow";
import { hasDownloadableMessageMedia, listMessageMediaDownloadSources } from "./messageMedia";

function imageMessage(senderId: string, image: Record<string, unknown>): MessageLike {
  return {
    serverId: "server-1", clientMsgId: "client-1", senderId, senderDisplayName: senderId,
    conversationSeq: 3, createdAt: 1, clientCreatedAt: 1, messageType: 2,
    content: { contentType: "image", image } as MessageLike["content"], status: "read",
    isRecalled: false, isRead: true, timelineKey: "server:server-1", timelineSortTs: 1,
  };
}

describe("listMessageMediaDownloadSources", () => {
  it("saves your own not-yet-uploaded picture from the file on this device", () => {
    const [source] = listMessageMediaDownloadSources(
      imageMessage("me", { imageId: "/Users/me/Pictures/cat.png", url: "file:///Users/me/Pictures/cat.png" }),
      { currentUserId: "me" },
    );
    expect(source).toMatchObject({ sourcePath: "/Users/me/Pictures/cat.png" });
    expect(source?.remoteFileId).toBeUndefined();
  });

  it("never takes a local path from someone else's message as the save source", () => {
    const planted = imageMessage("mallory", {
      imageId: "/Users/me/Library/Application Support/flare/flare.db",
      url: "file:///Users/me/Library/Application%20Support/flare/flare.db",
    });
    expect(listMessageMediaDownloadSources(planted, { currentUserId: "me" })).toEqual([]);
    expect(listMessageMediaDownloadSources(planted)).toEqual([]);
    expect(hasDownloadableMessageMedia(planted, { currentUserId: "me" })).toBe(false);
  });

  it("still saves someone else's picture by its file id", () => {
    const [source] = listMessageMediaDownloadSources(
      imageMessage("ivy", { imageId: "11111111-2222-3333-4444-555555555555", url: "https://cdn.example/a.png?sig=1" }),
      { currentUserId: "me" },
    );
    expect(source).toMatchObject({
      remoteFileId: "11111111-2222-3333-4444-555555555555",
      sourceHttpUrl: "https://cdn.example/a.png?sig=1",
    });
    expect(source?.sourcePath).toBeUndefined();
  });
});
