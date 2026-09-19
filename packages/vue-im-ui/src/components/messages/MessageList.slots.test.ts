// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { h, type Component } from "vue";
import { describe, expect, it } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import MessageList from "./MessageList.vue";

function message(id: string, senderId: string, minute: number): MessageLike {
  const createdAt = 1_736_922_600_000 + minute * 60_000;
  return {
    serverId: `server-${id}`, clientMsgId: `client-${id}`, senderId, senderDisplayName: senderId,
    conversationSeq: minute, createdAt, clientCreatedAt: createdAt, messageType: 1,
    content: { contentType: "text", text: `message ${id}` }, status: "read", isRecalled: false, isRead: true,
    timelineKey: `server:server-${id}`, timelineSortTs: createdAt, attributes: {},
  };
}

function mountList(props: Record<string, unknown>, slots: Record<string, (scope?: Record<string, unknown>) => unknown> = {}) {
  return mount(FlareUiProvider, {
    props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
    slots: { default: () => h(MessageList as Component, { currentUserId: "me", hasOlder: false, ...props }, slots) },
  });
}

const timeline = [message("1", "ivy", 0), message("2", "me", 1), message("3", "ivy", 2), message("4", "me", 3), message("5", "ivy", 4)];

describe("MessageList timeline slots", () => {
  it("draws the unread divider above the first unread message and counts messages from others", () => {
    const host = mountList({ messages: timeline, unreadFromId: "client-3" });
    const divider = host.get(".flare-unread-divider");
    expect(divider.attributes("role")).toBe("separator");
    expect(divider.text()).toContain("2");
    const texts = host.get(".message-list-content").text();
    expect(texts.indexOf("message 2")).toBeLessThan(texts.indexOf(divider.text()));
    expect(texts.indexOf(divider.text())).toBeLessThan(texts.indexOf("message 3"));
    host.unmount();
  });

  it("starts a new sender run below the divider", () => {
    const run = [message("1", "ivy", 0), message("2", "ivy", 1), message("3", "ivy", 2)];
    const host = mountList({ messages: run, unreadFromId: "client-2" });
    const positions = host.findAllComponents({ name: "MessageBubble" }).map((bubble) => bubble.props("groupPosition"));
    expect(positions).toEqual(["single", "first", "last"]);
    host.unmount();
  });

  it("starts a new sender run after a date separator", () => {
    // Two messages from the same sender one minute apart, on either side of local midnight.
    const lateNight = new Date(2025, 0, 14, 23, 59, 30).getTime();
    const at = (id: string, ts: number): MessageLike => ({ ...message(id, "ivy", 0), createdAt: ts, clientCreatedAt: ts, timelineSortTs: ts });
    const host = mountList({ messages: [at("1", lateNight), at("2", lateNight + 60_000)] });
    expect(host.findAll(".flare-date-pill, .im-date-pill, [data-date-pill]").length + host.findAllComponents({ name: "FlareDatePill" }).length).toBeGreaterThan(0);
    const positions = host.findAllComponents({ name: "MessageBubble" }).map((bubble) => bubble.props("groupPosition"));
    expect(positions).toEqual(["single", "single"]);
    host.unmount();
  });

  it("draws no divider without a matching id and lets the host replace it", () => {
    const none = mountList({ messages: timeline, unreadFromId: "missing" });
    expect(none.find(".flare-unread-divider").exists()).toBe(false);
    none.unmount();
    const custom = mountList(
      { messages: timeline, unreadFromId: "client-5" },
      { "unread-divider": (scope) => h("p", { class: "host-divider" }, `new ${scope?.count}`) },
    );
    expect(custom.get(".host-divider").text()).toBe("new 1");
    expect(custom.find(".flare-unread-divider").exists()).toBe(false);
    custom.unmount();
  });

  it("renders header and footer inside the timeline and the empty slot only without messages", () => {
    const slots = {
      header: () => h("p", { class: "host-header" }, "start"),
      footer: () => h("p", { class: "host-footer" }, "Ivy is typing"),
      empty: () => h("p", { class: "host-empty" }, "No messages yet"),
    };
    const filled = mountList({ messages: timeline }, slots);
    const content = filled.get(".message-list-content");
    expect(content.find(".host-header").exists()).toBe(true);
    expect(content.find(".host-footer").exists()).toBe(true);
    expect(content.text().indexOf("start")).toBeLessThan(content.text().indexOf("message 1"));
    expect(content.text().indexOf("message 5")).toBeLessThan(content.text().indexOf("Ivy is typing"));
    expect(filled.find(".host-empty").exists()).toBe(false);
    filled.unmount();
    const empty = mountList({ messages: [] }, slots);
    expect(empty.get(".message-list-empty .host-empty").text()).toBe("No messages yet");
    empty.unmount();
  });
});
