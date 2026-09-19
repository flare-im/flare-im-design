// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { h, nextTick, type Component } from "vue";
import { describe, expect, it, vi } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import MessageList from "./MessageList.vue";

/**
 * A quote names the quoted message by the id the core knows it by. For a message this device sent
 * that is not the id the row is drawn with (the client id survives the send acknowledgement), so a
 * list that matched only the row id told the reader a message on screen did not exist (FR-114).
 */
function message(id: string, senderId: string, minute: number, content?: MessageLike["content"]): MessageLike {
  const createdAt = 1_736_922_600_000 + minute * 60_000;
  return {
    serverId: `server-${id}`, clientMsgId: `client-${id}`, senderId, senderDisplayName: senderId,
    conversationSeq: minute, createdAt, clientCreatedAt: createdAt, messageType: 1,
    content: content ?? { contentType: "text", text: `message ${id}` }, status: "read",
    isRecalled: false, isRead: true, timelineKey: `server:server-${id}`, timelineSortTs: createdAt, attributes: {},
  };
}

/** A reply to `quotedId`, the way the core stores one: a quote body carrying the quoted core id. */
function quoteOf(id: string, quotedId: string, minute: number): MessageLike {
  return message(id, "me", minute, {
    contentType: "quote",
    quote: {
      quotedMessageId: quotedId,
      quotedSenderId: "me",
      quotedTextPreview: "message 2",
      currentContent: { contentType: "text", text: "back to this" },
    },
  } as unknown as MessageLike["content"]);
}

function mountList(props: Record<string, unknown> = {}, listeners: Record<string, unknown> = {}) {
  const messages = [message("1", "ivy", 0), message("2", "me", 1), quoteOf("3", "server-2", 2)];
  const host = mount(FlareUiProvider, {
    props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
    slots: { default: () => h(MessageList as Component, { currentUserId: "me", messages, ...props, ...listeners }) },
  });
  return { host, messages };
}

describe("MessageList locating a quoted message", () => {
  it("finds a row by the core's id for it, not only the id it is drawn with", async () => {
    const { host } = mountList();
    const list = host.findComponent(MessageList as Component);
    const api = list.vm as unknown as { scrollToMessage(id: string, smooth?: boolean): Promise<boolean> };
    // The row is drawn as `client-2`; the quote names it `server-2`.
    expect(await api.scrollToMessage("server-2", false)).toBe(true);
    expect(await api.scrollToMessage("client-2", false)).toBe(true);
    expect(await api.scrollToMessage("server-404", false)).toBe(false);
    host.unmount();
  });

  it("shows a quoted message it is drawing itself, and asks the host only for one it does not have", async () => {
    const onLocateMessage = vi.fn();
    const { host } = mountList({}, { onLocateMessage });
    const quote = host.get(".im-quote__source--clickable");
    await quote.trigger("click");
    await nextTick();
    // The list has that message: it jumps there itself rather than asking the host to page history.
    expect(onLocateMessage).not.toHaveBeenCalled();
    host.unmount();

    const missing = mount(FlareUiProvider, {
      props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
      slots: {
        default: () => h(MessageList as Component, {
          currentUserId: "me",
          messages: [message("1", "ivy", 0), quoteOf("3", "server-gone", 2)],
          onLocateMessage,
        }),
      },
    });
    await missing.get(".im-quote__source--clickable").trigger("click");
    expect(onLocateMessage).toHaveBeenCalledWith("server-gone");
    missing.unmount();
  });

  it("draws a quote nothing can reach as text rather than a control", async () => {
    const missing = mount(FlareUiProvider, {
      props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
      slots: {
        default: () => h(MessageList as Component, {
          currentUserId: "me",
          messages: [message("1", "ivy", 0), quoteOf("3", "server-gone", 2)],
        }),
      },
    });
    expect(missing.find(".im-quote__source--clickable").exists()).toBe(false);
    expect(missing.get(".im-quote__source").text()).toContain("message 2");
    missing.unmount();
  });
});
