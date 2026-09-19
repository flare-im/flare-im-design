import { describe, expect, it } from "vitest";
import {
  MESSAGE_CONTENT_KINDS,
  messageContentKindFromWire,
  resolveMessageContentContract,
} from "./message-content-contract";

describe("message content contract", () => {
  it("covers every RC presentation kind", () => {
    expect(MESSAGE_CONTENT_KINDS).toHaveLength(26);
    expect(new Set(MESSAGE_CONTENT_KINDS).size).toBe(MESSAGE_CONTENT_KINDS.length);
  });

  it("keeps lifecycle treatments out of the wire contract", () => {
    expect(resolveMessageContentContract("readOnce").wireType).toBeUndefined();
    expect(resolveMessageContentContract("burnAfterRead").capabilities.has("openOnce")).toBe(true);
  });

  it("maps protocol content to a default renderer without redefining it", () => {
    expect(messageContentKindFromWire("image_group")).toBe("multiImage");
    expect(messageContentKindFromWire("quote")).toBe("reply");
    expect(messageContentKindFromWire("unknown")).toBeUndefined();
  });
});
