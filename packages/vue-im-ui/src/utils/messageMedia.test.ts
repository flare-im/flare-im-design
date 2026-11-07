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
  it("offers a received voice attachment with its original filename and MIME", () => {
    const audio = {
      ...imageMessage("peer", {}),
      content: { contentType: "audio", audio: { audioId: "voice-1", fileName: "语音.wav", mimeType: "audio/wav" } },
    } as MessageLike;
    expect(listMessageMediaDownloadSources(audio)).toMatchObject([
      { kind: "audio", remoteFileId: "voice-1", fileId: "voice-1", displayFileName: "语音.wav", mimeType: "audio/wav" },
    ]);
    expect(hasDownloadableMessageMedia(audio)).toBe(true);
  });

  it("resolves typed audio source UUIDs without inventing a filename extension", () => {
    const audio = {
      ...imageMessage("peer", {}),
      content: { contentType: "audio", audio: { source: { uuid: "voice-2", mimeType: "audio/ogg" } } },
    } as MessageLike;
    expect(listMessageMediaDownloadSources(audio)).toMatchObject([
      { kind: "audio", remoteFileId: "voice-2", displayFileName: "audio", mimeType: "audio/ogg" },
    ]);
  });

  it("keeps recalled and peer-local voice sources unavailable for download", () => {
    const local = {
      ...imageMessage("peer", {}),
      content: { contentType: "audio", audio: { audioId: "/Users/me/private.wav", url: "file:///Users/me/private.wav" } },
    } as MessageLike;
    expect(listMessageMediaDownloadSources(local, { currentUserId: "me" })).toEqual([]);
    const recalled = { ...local, isRecalled: true, content: { contentType: "audio", audio: { audioId: "voice-3" } } } as MessageLike;
    expect(hasDownloadableMessageMedia(recalled)).toBe(false);
  });

  it("does not label a picture without an original filename as JPEG", () => {
    const [source] = listMessageMediaDownloadSources(imageMessage("ivy", { imageId: "stored-png", mimeType: "image/png" }));
    expect(source?.displayFileName).toBe("image");
    const [named] = listMessageMediaDownloadSources(imageMessage("ivy", { imageId: "stored-png", fileName: "receipt.png" }));
    expect(named?.displayFileName).toBe("receipt.png");
  });
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
