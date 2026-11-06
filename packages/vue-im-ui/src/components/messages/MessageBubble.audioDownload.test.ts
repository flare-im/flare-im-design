// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { h } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import MessageBubble from "./MessageBubble.vue";

const hosts: ReturnType<typeof mount>[] = [];
afterEach(() => hosts.splice(0).forEach(host => host.unmount()));

function voice(state: "idle" | "downloading" | "openFolder" = "idle", locale = "zh-CN") {
  const action = vi.fn();
  const message: MessageLike = {
    serverId: "voice-server", clientMsgId: "voice-client", senderId: "peer", senderDisplayName: "Peer", conversationSeq: 7,
    createdAt: 1_736_922_600_000, clientCreatedAt: 1_736_922_600_000, messageType: 4,
    content: { contentType: "audio", audio: { audioId: "voice-file", fileName: "recording.wav", mimeType: "audio/wav", durationMs: 2200 } },
    status: "read", isRecalled: false, isRead: true, timelineKey: "server:voice-server", timelineSortTs: 1,
  };
  const host = mount(FlareUiProvider, {
    props: { layoutMode: "pc", themeMode: "light", locale },
    slots: { default: () => h(MessageBubble, {
      message, self: false, currentUserId: "me", mediaDownloadState: state,
      menuConfig: { resolveMediaAction: () => state === "openFolder" ? "openMediaFolder" : "downloadMedia" },
      onMediaAction: action,
    }) },
  });
  hosts.push(host);
  return { host, action };
}

describe("voice message download action", () => {
  it.each([["zh-CN", "下载语音"], ["en-US", "Download audio"]])("has an accessible localized download button in %s", async (locale, label) => {
    const { host, action } = voice("idle", locale);
    await host.get(`button[aria-label="${label}"]`).trigger("click");
    expect(action).toHaveBeenCalledWith("voice-client", "download");
  });

  it("disables duplicate downloads while saving", () => {
    const { host } = voice("downloading");
    expect(host.get("button.message-media-hover-action").attributes("disabled")).toBeDefined();
  });

  it("changes the action to the existing saved-file folder action", async () => {
    const { host, action } = voice("openFolder");
    await host.get("button.message-media-hover-action--folder").trigger("click");
    expect(action).toHaveBeenCalledWith("voice-client", "openFolder");
  });
});
