// @vitest-environment happy-dom
import { flushPromises, mount } from "@vue/test-utils";
import { h, type Component } from "vue";
import { describe, expect, it } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import MessageContentView from "./MessageContentView.vue";
import MessageList from "./MessageList.vue";

// A poll's options and a task's checkbox are controls in a timeline only when the host takes the intent (R9-B8):
// `vote` with the option's index, `taskToggle` with the done state asked for. Without a listener, and while
// selecting, they are read-only.
function message(id: string, minute: number, content: Record<string, unknown>): MessageLike {
  const createdAt = 1_736_922_600_000 + minute * 60_000;
  return {
    serverId: `server-${id}`, clientMsgId: `client-${id}`, senderId: "ivy", senderDisplayName: "Ivy",
    conversationSeq: minute, createdAt, clientCreatedAt: createdAt, messageType: 1,
    content: content as MessageLike["content"], status: "read", isRecalled: false, isRead: true,
    timelineKey: `server:server-${id}`, timelineSortTs: createdAt, attributes: {},
  };
}

const poll = message("1", 0, { contentType: "vote", vote: { title: "Friday dinner", options: ["Hotpot", "BBQ", "Sushi"] } });
const task = message("2", 1, { contentType: "task", task: { title: "Send the weekly report", done: false } });

function mountList(props: Record<string, unknown>) {
  return mount(FlareUiProvider, {
    props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
    slots: { default: () => h(MessageList as Component, { currentUserId: "me", hasOlder: false, messages: [poll, task], ...props }) },
  });
}

describe("MessageList poll and task intents", () => {
  it("draws polls and tasks read-only when nobody takes the intent", async () => {
    const host = mountList({});
    await flushPromises();
    expect(host.findAll(".fm-vote button.opt")).toHaveLength(0);
    expect(host.findAll(".fm-vote .opt")).toHaveLength(3);
    expect(host.find(".fm-task button.box").exists()).toBe(false);
    expect(host.get(".fm-task .box").attributes("aria-disabled")).toBe("true");
    host.unmount();
  });

  it("hands the host the message and the option, and the done state asked for", async () => {
    const calls: unknown[][] = [];
    const host = mountList({
      onVote: (...args: unknown[]) => calls.push(["vote", ...args]),
      onTaskToggle: (...args: unknown[]) => calls.push(["taskToggle", ...args]),
    });
    await flushPromises();
    const options = host.findAll(".fm-vote button.opt");
    expect(options).toHaveLength(3);
    await options[2].trigger("click");
    await host.get(".fm-task button.box").trigger("click");
    expect(calls).toEqual([["vote", "client-1", 2], ["taskToggle", "client-2", true]]);
    host.unmount();
  });

  it("turns the controls off while selecting", async () => {
    const host = mountList({ multiSelectMode: true, onVote: () => {}, onTaskToggle: () => {} });
    await flushPromises();
    expect(host.findAll(".fm-vote button.opt")).toHaveLength(0);
    expect(host.find(".fm-task button.box").exists()).toBe(false);
    host.unmount();
  });

  it("gives a body outside a list the same intents", async () => {
    const votes: number[] = [];
    const done: boolean[] = [];
    const wrap = (content: MessageLike["content"], listeners: Record<string, unknown>) =>
      mount(FlareUiProvider, {
        props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
        slots: { default: () => h(MessageContentView as Component, { content, ...listeners }) },
      });
    const pollBody = wrap(poll.content, { onVote: (index: number) => votes.push(index) });
    await pollBody.findAll("button.opt")[0].trigger("click");
    const doneTask = wrap({ contentType: "task", task: { title: "Book the room", done: true } } as MessageLike["content"], {
      onTaskToggle: (value: boolean) => done.push(value),
    });
    await doneTask.get("button.box").trigger("click");
    expect(votes).toEqual([0]);
    expect(done).toEqual([false]);
    expect(wrap(poll.content, {}).findAll("button.opt")).toHaveLength(0);
  });
});
