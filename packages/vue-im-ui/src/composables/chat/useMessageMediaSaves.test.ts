// @vitest-environment happy-dom
//
// 一条消息的下载键：没保存是下载，保存后是文件夹；文件夹指向的文件被删了，点它就回到下载，再下载又是文件夹。
// 同一个文件的几条消息共用状态；进会话时每个文件只问一次宿主「保存过没有」。
import { describe, expect, it, vi } from "vitest";
import { effectScope, nextTick, ref } from "vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import { useMessageMediaSaves, type MessageMediaSaveHost } from "./useMessageMediaSaves";

function fileMessage(id: string, fileId: string): MessageLike {
  return {
    messageId: id,
    clientMsgId: id,
    timelineKey: id,
    conversationId: "c1",
    senderId: "peer",
    createdAt: 1,
    clientCreatedAt: 1,
    content: { contentType: "file", file: { fileId, fileName: "合同.pdf", fileSize: 8704 } },
  } as unknown as MessageLike;
}

const flush = async () => {
  for (let i = 0; i < 5; i += 1) await Promise.resolve();
  await nextTick();
};

function setup(host: Partial<MessageMediaSaveHost>, messages = [fileMessage("m1", "f1")]) {
  const list = ref(messages);
  const full: MessageMediaSaveHost = {
    save: vi.fn(async () => undefined),
    isSaved: vi.fn(async () => false),
    reveal: vi.fn(async () => true),
    ...host,
  };
  const scope = effectScope();
  const saves = scope.run(() => useMessageMediaSaves({ messages: () => list.value, host: full }))!;
  return { saves, host: full, list, scope };
}

describe("useMessageMediaSaves", () => {
  it("turns the key into a folder once the save lands", async () => {
    let finish: () => void = () => undefined;
    const { saves } = setup({ save: vi.fn(() => new Promise<void>((resolve) => (finish = resolve))) });
    expect(saves.states.value.m1).toBeUndefined();

    const pending = saves.onMediaAction("m1", "download");
    await flush();
    expect(saves.states.value.m1).toBe("downloading");
    finish();
    await pending;
    expect(saves.states.value.m1).toBe("openFolder");
  });

  it("stays a download when the save fails", async () => {
    const { saves } = setup({ save: vi.fn(async () => Promise.reject(new Error("offline"))) });
    await saves.onMediaAction("m1", "download");
    expect(saves.states.value.m1).toBeUndefined();
  });

  it("shows an already saved file as a folder when its message shows up", async () => {
    const { saves, host } = setup({ isSaved: vi.fn(async (key: string) => key === "f1") });
    await flush();
    expect(host.isSaved).toHaveBeenCalledWith("f1");
    expect(saves.states.value.m1).toBe("openFolder");
  });

  it("reveals a saved file, and goes back to a download when it is gone", async () => {
    const reveal = vi.fn(async () => true);
    const { saves } = setup({ isSaved: vi.fn(async () => true), reveal });
    await flush();

    await saves.onMediaAction("m1", "openFolder");
    expect(reveal).toHaveBeenCalledTimes(1);
    expect(saves.states.value.m1).toBe("openFolder");

    reveal.mockResolvedValueOnce(false);
    await saves.onMediaAction("m1", "openFolder");
    expect(saves.states.value.m1).toBeUndefined();

    // Downloaded again: a folder once more.
    await saves.onMediaAction("m1", "download");
    expect(saves.states.value.m1).toBe("openFolder");
  });

  it("shares the state between messages that carry the same file and asks once per file", async () => {
    const { saves, host, list } = setup({}, [fileMessage("m1", "f1"), fileMessage("m2", "f1")]);
    await flush();
    await saves.onMediaAction("m1", "download");
    expect(saves.states.value).toEqual({ m1: "openFolder", m2: "openFolder" });

    list.value = [...list.value, fileMessage("m3", "f1")];
    await flush();
    expect(host.isSaved).toHaveBeenCalledTimes(1);
    expect(saves.states.value.m3).toBe("openFolder");
  });

  it("offers the folder in the message menu for a saved file", async () => {
    const { saves } = setup({ isSaved: vi.fn(async (key: string) => key === "f1") }, [
      fileMessage("m1", "f1"),
      fileMessage("m2", "f2"),
    ]);
    await flush();
    const ctx = (message: MessageLike) => ({ message }) as never;
    expect(saves.menuConfig.resolveMediaAction?.(ctx(fileMessage("m1", "f1")))).toBe("openMediaFolder");
    expect(saves.menuConfig.resolveMediaAction?.(ctx(fileMessage("m2", "f2")))).toBe("downloadMedia");
    // A folder key pressed for a file that is not saved downloads it.
    await saves.onMediaAction("m2", "openFolder");
    expect(saves.menuConfig.resolveMediaAction?.(ctx(fileMessage("m2", "f2")))).toBe("openMediaFolder");
  });
});
