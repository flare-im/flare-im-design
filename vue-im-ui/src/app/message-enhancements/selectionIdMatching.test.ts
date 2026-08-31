import { describe, expect, it } from "vitest";
import { messageHasId, messageStableId } from "./types";

// 已同步的消息两个 id 都有——这正是两套优先级会分叉的场景。
const synced = { serverId: "srv-1", clientMsgId: "cli-1" } as never;
const localOnly = { serverId: "", clientMsgId: "cli-2" } as never;

describe("选中集的 id 匹配", () => {
  it("菜单发出的 clientMsgId 也要能匹配上已同步的消息", () => {
    // buildMessageMenuOptions 的 messageKey 是 clientMsgId 优先，
    // 而 messageStableId 是 serverId 优先。只认后者的话，多选后
    // 转发预览恒为 0 条、确认按钮禁用。
    expect(messageStableId(synced)).toBe("srv-1");
    expect(messageHasId(synced, "cli-1")).toBe(true);
    expect(messageHasId(synced, "srv-1")).toBe(true);
  });

  it("本地消息只有 clientMsgId 时同样匹配", () => {
    expect(messageHasId(localOnly, "cli-2")).toBe(true);
  });

  it("不匹配别的消息", () => {
    expect(messageHasId(synced, "srv-2")).toBe(false);
    expect(messageHasId(synced, "cli-2")).toBe(false);
  });

  it("空 id 不匹配任何消息——否则空串会命中缺 serverId 的本地消息", () => {
    expect(messageHasId(localOnly, "")).toBe(false);
    expect(messageHasId(synced, "")).toBe(false);
  });
});
