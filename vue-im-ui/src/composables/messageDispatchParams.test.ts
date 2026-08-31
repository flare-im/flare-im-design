import { describe, expect, it } from "vitest";
import {
  DEFAULT_MARK_COLOR,
  MARK_TYPE_IMPORTANT,
  buildMessageDispatchParams,
} from "./useFlareCoreClient";

const base = { conversationId: "1A0000000000000000", messageId: "m-1" };

describe("buildMessageDispatchParams", () => {
  it("默认带上 markType，否则标记类操作会被核心侧拒绝", () => {
    // 核心侧用 json_i32 取这个字段，缺了直接 INVALID_PARAMETER：
    // "missing or invalid JSON field: markType"。
    const params = buildMessageDispatchParams(base);
    expect(params.markType).toBe(MARK_TYPE_IMPORTANT);
  });

  it("markType 必须是数字而不是字符串", () => {
    // json_i32 不接受字符串；写成 "1" 同样会被拒。
    expect(typeof buildMessageDispatchParams(base).markType).toBe("number");
  });

  it("默认带上 color，标记契约要求它是非空字符串", () => {
    // mark_by_message_id 三个必填：messageId + markType(i32) + color(string)。
    // 少任何一个都是 INVALID_PARAMETER，且此前两个都缺，修好一个才暴露下一个。
    const params = buildMessageDispatchParams(base);
    expect(params.color).toBe(DEFAULT_MARK_COLOR);
    expect(typeof params.color).toBe("string");
    expect(String(params.color)).not.toBe("");
  });

  it("调用方可以覆盖 markType", () => {
    expect(buildMessageDispatchParams({ ...base, markType: 3 }).markType).toBe(3);
  });

  it("jsonParams 优先级最高，便于在 SDK Lab 里试别的取值", () => {
    const params = buildMessageDispatchParams({ ...base, jsonParams: { markType: 4 } });
    expect(params.markType).toBe(4);
  });
});
