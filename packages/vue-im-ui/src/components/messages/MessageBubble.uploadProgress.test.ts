// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { h } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import MessageBubble from "./MessageBubble.vue";

const hosts: ReturnType<typeof mount>[] = [];
afterEach(() => hosts.splice(0).forEach(host => host.unmount()));

function uploading(content: MessageLike["content"]) {
  const message: MessageLike = {
    serverId: "", clientMsgId: "client-1", senderId: "me", senderDisplayName: "Me", conversationSeq: 0,
    createdAt: 1_736_922_600_000, clientCreatedAt: 1_736_922_600_000, messageType: 1, content, status: "sending",
    isRecalled: false, isRead: false, timelineKey: "message-1", timelineSortTs: 1, attributes: {},
    localState: { sending: true, uploading: true, uploadProgress: 37 },
  };
  const host = mount(FlareUiProvider, {
    props: { layoutMode: "pc", themeMode: "light", locale: "zh-CN" },
    slots: { default: () => h(MessageBubble, { message, self: true, currentUserId: "me" }) },
  });
  hosts.push(host);
  return host;
}

describe("upload progress on a bubble", () => {
  it.each([
    [{ contentType: "image", image: { url: "data:image/png;base64,AA==" } }],
    [{ contentType: "video", video: { url: "" } }],
  ])("floats over the picture of %j", (content) => {
    const progress = uploading(content).get(".message-upload-progress");
    expect(progress.classes()).toContain("message-upload-progress--media");
    expect(progress.text()).toBe("37%");
  });

  it.each([
    [{ contentType: "file", file: { fileId: "data:application/octet-stream;name=a;size=2048;base64,AA==", fileName: "季度报表.xlsx", fileSize: 2048, url: "data:application/octet-stream;name=a;size=2048;base64,AA==" } }],
    [{ contentType: "audio", audio: { url: "", durationMs: 3000 } }],
  ])("sits under the body of %j so its name and size stay readable", (content) => {
    const host = uploading(content);
    const progress = host.get(".message-upload-progress");
    expect(progress.classes()).not.toContain("message-upload-progress--media");
    expect(progress.text()).toBe("37%");
    if (content.contentType === "file") expect(host.text()).toContain("2.0 KB");
  });
});
