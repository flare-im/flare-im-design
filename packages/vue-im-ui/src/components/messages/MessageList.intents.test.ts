// @vitest-environment happy-dom
import { flushPromises, mount } from "@vue/test-utils";
import { h, type Component } from "vue";
import { describe, expect, it, vi } from "vitest";
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

describe("MessageList host intents", () => {
  it("reports file drops when enabled and suppresses navigation on blocked drops", async () => {
    const file = new File(["hello"], "notes.txt", { type: "text/plain" });
    const dataTransfer = { types: ["Files"], files: [file] };
    const onFilesDrop = vi.fn();
    const host = mountList({ fileDropEnabled: true, onFilesDrop });
    const timeline = host.get(".message-list-root");
    await timeline.trigger("dragenter", { dataTransfer });
    expect(host.get(".message-list__drop-hint").text()).toBe("Drop to add attachments");
    await timeline.trigger("drop", { dataTransfer });
    expect(host.find(".message-list__drop-hint").exists()).toBe(false);
    expect(onFilesDrop).toHaveBeenCalledExactlyOnceWith([file]);
    host.unmount();

    const blocked = mountList({ fileDropEnabled: true, fileDropBlocked: true, onFilesDrop });
    const blockedTimeline = blocked.get(".message-list-root");
    await blockedTimeline.trigger("dragenter", { dataTransfer });
    const drop = Object.assign(new Event("drop", { bubbles: true, cancelable: true }), { dataTransfer });
    blockedTimeline.element.dispatchEvent(drop);
    expect(drop.defaultPrevented).toBe(true);
    expect(blocked.find(".message-list__drop-hint").exists()).toBe(false);
    expect(onFilesDrop).toHaveBeenCalledTimes(1);
    blocked.unmount();
  });

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
    expect(calls).toEqual([["vote", "server-1", 2], ["taskToggle", "server-2", true]]);
    host.unmount();
  });

  it("turns the controls off while selecting", async () => {
    const host = mountList({ multiSelectMode: true, onVote: () => {}, onTaskToggle: () => {} });
    await flushPromises();
    expect(host.findAll(".fm-vote button.opt")).toHaveLength(0);
    expect(host.find(".fm-task button.box").exists()).toBe(false);
    host.unmount();
  });

  it("opens a file card's body through openFile only when the host listens, and keeps the download key", async () => {
    const file = message("3", 2, { contentType: "file", file: { fileName: "spec.pdf", fileSize: 2048, url: "https://cdn.example.com/spec.pdf" } });
    const quiet = mountList({ messages: [file] });
    await flushPromises();
    expect(quiet.find(".fm-file button.main").exists()).toBe(false);
    quiet.unmount();

    const opened: string[] = [];
    const host = mountList({ messages: [file], onOpenFile: (id: string) => opened.push(id) });
    await flushPromises();
    await host.get(".fm-file button.main").trigger("click");
    expect(opened).toEqual(["server-3"]);
    host.unmount();

    const selecting = mountList({ messages: [file], multiSelectMode: true, onOpenFile: () => opened.push("selecting") });
    await flushPromises();
    expect(selecting.find(".fm-file button.main").exists()).toBe(false);
    selecting.unmount();
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
