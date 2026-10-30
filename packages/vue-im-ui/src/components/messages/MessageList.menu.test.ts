// @vitest-environment happy-dom
import { flushPromises, mount } from "@vue/test-utils";
import { h, ref } from "vue";
import { describe, expect, it } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import MessageBubble from "./MessageBubble.vue";
import MessageList from "./MessageList.vue";
import MessageMenu from "./MessageMenu.vue";
import FlareActionMenu from "../general/FlareActionMenu.vue";
import type { MessageMenuConfig } from "../../shared/config/messageMenu";
import type { MessageActionAvailability } from "../../utils/messageActionAvailability";

const message: MessageLike = {
  serverId: "server-1", clientMsgId: "client-1", senderId: "ivy", senderDisplayName: "Ivy",
  conversationSeq: 1, createdAt: 1_736_922_600_000, clientCreatedAt: 1_736_922_600_000, messageType: 1,
  content: { contentType: "text", text: "Ship it" }, status: "read", isRecalled: false, isRead: true,
  timelineKey: "server:server-1", timelineSortTs: 1, attributes: {},
};

function bubbleActions(listeners: Record<string, () => void>) {
  const host = mount(FlareUiProvider, {
    props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
    slots: { default: () => h(MessageList, { messages: [message], currentUserId: "me", hasOlder: false, ...listeners }) },
  });
  const actions = host.findComponent(MessageBubble).props("menuConfig")?.actions ?? {};
  host.unmount();
  return actions;
}

describe("MessageList menu intents", () => {
  it("keeps the actions whose intent the host handles", () => {
    const actions = bubbleActions({ onReply: () => {}, onForward: () => {}, onReact: () => {} });
    expect(actions).toMatchObject({ reply: true, forward: true, react: true });
  });

  it("drops the actions nobody handles", () => {
    const actions = bubbleActions({ onReply: () => {} });
    expect(actions).toMatchObject({ reply: true, forward: false, react: false, pin: false, delete: false });
  });

  it("keeps an open menu alive and refreshes its actions when a pending row is acknowledged", async () => {
    const pending: MessageLike = {
      ...message,
      serverId: "",
      senderId: "me",
      conversationSeq: 0,
      status: "sending",
      timelineKey: "client:client-1",
      localState: { sending: true },
    };
    const rows = ref<readonly MessageLike[]>([pending]);
    const host = mount(FlareUiProvider, {
      props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
      slots: {
        default: () => h(MessageList, {
          messages: rows.value,
          currentUserId: "me",
          hasOlder: false,
          onEdit: () => {},
          onForward: () => {},
          onPin: () => {},
        }),
      },
    });
    const bubbleBeforeAck = host.findComponent(MessageBubble).vm.$.uid;
    const menuWrapper = host.findComponent(MessageMenu);
    const menuBeforeAck = menuWrapper.vm.$.uid;
    (menuWrapper.vm as unknown as { openMenu(): void }).openMenu();
    await flushPromises();
    expect(host.findComponent(FlareActionMenu).props("items").map((item: { id: string }) => item.id))
      .not.toContain("edit");

    rows.value = [{
      ...pending,
      serverId: "server-1",
      conversationSeq: 1,
      status: "sent",
      timelineKey: "server:server-1",
      localState: { sending: false },
    }];
    await flushPromises();

    expect(host.findComponent(MessageBubble).vm.$.uid).toBe(bubbleBeforeAck);
    expect(host.findComponent(MessageMenu).vm.$.uid).toBe(menuBeforeAck);
    expect(host.findComponent(FlareActionMenu).props("open")).toBe(true);
    expect(host.findComponent(FlareActionMenu).props("items").map((item: { id: string }) => item.id))
      .toEqual(expect.arrayContaining(["edit", "forward", "pin"]));
    host.unmount();
  });
});

describe("MessageList menu and the core's snapshot", () => {
  const forwardIds = (host: ReturnType<typeof mount>) =>
    host.findComponent(FlareActionMenu).props("items").map((item: { id: string }) => item.id);

  function mountWith(menuConfig: () => MessageMenuConfig) {
    return mount(FlareUiProvider, {
      props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
      slots: {
        default: () => h(MessageList, {
          messages: [message],
          currentUserId: "me",
          hasOlder: false,
          menuConfig: menuConfig(),
          onReply: () => {},
          onForward: () => {},
        }),
      },
    });
  }

  async function openMenu(host: ReturnType<typeof mount>) {
    const menu = host.findComponent(MessageMenu);
    (menu.vm as unknown as { openMenu(): void }).openMenu();
    await flushPromises();
    return menu.vm.$.uid;
  }

  it("narrows an open menu in place when the snapshot it reads arrives", async () => {
    const snapshots = ref<Record<string, Partial<MessageActionAvailability>>>({});
    const host = mountWith(() => ({ availability: (row) => snapshots.value[row.clientMsgId ?? ""] }));
    const menu = await openMenu(host);
    expect(forwardIds(host)).toEqual(expect.arrayContaining(["reply", "forward"]));

    snapshots.value = { "client-1": { canForward: false } };
    await flushPromises();
    expect(host.findComponent(FlareActionMenu).props("open")).toBe(true);
    expect(host.findComponent(MessageMenu).vm.$.uid).toBe(menu);
    expect(forwardIds(host)).not.toContain("forward");
    expect(forwardIds(host)).toContain("reply");
    host.unmount();
  });

  it("narrows an open menu in place when the host hands it a new config", async () => {
    const config = ref<MessageMenuConfig>({});
    const host = mountWith(() => config.value);
    const menu = await openMenu(host);
    expect(forwardIds(host)).toContain("forward");

    config.value = { availability: () => ({ canForward: false }) };
    await flushPromises();
    expect(host.findComponent(FlareActionMenu).props("open")).toBe(true);
    expect(host.findComponent(MessageMenu).vm.$.uid).toBe(menu);
    expect(forwardIds(host)).not.toContain("forward");

    config.value = {};
    await flushPromises();
    expect(forwardIds(host)).toContain("forward");
    expect(host.findComponent(FlareActionMenu).props("open")).toBe(true);
    host.unmount();
  });
});

describe("MessageList host actions", () => {
  const actions = [{ id: "report", label: "Report", icon: "warning", destructive: true }];

  it("offers host actions only when the host listens to action", () => {
    const mountWith = (listeners: Record<string, unknown>) => mount(FlareUiProvider, {
      props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
      slots: { default: () => h(MessageList, { messages: [message], currentUserId: "me", hasOlder: false, actions, ...listeners }) },
    });
    const silent = mountWith({ onReply: () => {} });
    expect(silent.findComponent(MessageBubble).props("actions")).toEqual([]);
    silent.unmount();
    const calls: unknown[][] = [];
    const handled = mountWith({ onAction: (...args: unknown[]) => calls.push(args) });
    const bubble = handled.findComponent(MessageBubble);
    expect(bubble.props("actions")).toEqual(actions);
    bubble.vm.$emit("action", "report", "client-1");
    expect(calls).toEqual([["report", "client-1"]]);
    handled.unmount();
  });
});

describe("MessageList reaction pills", () => {
  const reacted: MessageLike = { ...message, reactions: [{ emoji: "👍", count: 2, selected: true }, { emoji: "🎉", count: 1 }] };

  function mountList(listeners: Record<string, (...args: unknown[]) => void>) {
    return mount(FlareUiProvider, {
      props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
      slots: { default: () => h(MessageList, { messages: [reacted], currentUserId: "me", hasOlder: false, ...listeners }) },
    });
  }

  it("toggles the viewer's reaction when the host handles react", async () => {
    const calls: unknown[][] = [];
    const host = mountList({ onReact: (...args) => calls.push(args) });
    const pills = host.findAll(".message-reactions button");
    expect(pills.map((pill) => pill.attributes("aria-pressed"))).toEqual(["true", "false"]);
    await pills[1].trigger("click");
    expect(calls).toEqual([["client-1", "🎉"]]);
    host.unmount();
  });

  it("shows display-only pills when nobody handles react", () => {
    const host = mountList({ onReply: () => {} });
    expect(host.findAll(".message-reactions button")).toHaveLength(0);
    expect(host.findAll(".message-reactions span")).toHaveLength(2);
    host.unmount();
  });
});
