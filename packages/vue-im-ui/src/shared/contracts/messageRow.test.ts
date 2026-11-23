import { describe, expect, it } from "vitest";
import { findMessage, resolveMessageId } from "./messageRow";

describe("resolveMessageId", () => {
  it("prefers server identity after acknowledgement and retains local identity before it", () => {
    expect(resolveMessageId({ clientMsgId: "c-1", serverId: "" })).toBe("c-1");
    expect(resolveMessageId({ clientMsgId: "c-1", serverId: "s-1" })).toBe("s-1");
  });

  it("falls back to the server id for rows created without a client id", () => {
    expect(resolveMessageId({ clientMsgId: "", serverId: "s-9" })).toBe("s-9");
  });
});

describe("findMessage", () => {
  const rows = [
    { clientMsgId: "c-1", serverId: "s-1", text: "acked" },
    { clientMsgId: "", serverId: "s-2", text: "system" },
  ];

  it("finds the row an intent names", () => {
    expect(findMessage(rows, "c-1")?.text).toBe("acked");
    expect(findMessage(rows, "s-2")?.text).toBe("system");
  });

  it("accepts canonical server IDs and rejects empty IDs", () => {
    expect(findMessage(rows, "s-1")?.text).toBe("acked");
    expect(findMessage(rows, "")).toBeUndefined();
  });
});
