import { describe, expect, it } from "vitest";
import { defaultMessageLifecycle, lifecycleToMessageStatus } from "./message-lifecycle";

describe("MessageLifecycle visual projection", () => {
  it("keeps the default acknowledged message in sent state", () => {
    expect(lifecycleToMessageStatus(defaultMessageLifecycle)).toBe("sent");
  });

  it("keeps transfer failure visible as failed", () => {
    expect(lifecycleToMessageStatus({ ...defaultMessageLifecycle, transfer: "failed" })).toBe("failed");
  });

  it("projects five receipt states: delivery without a read is still sent", () => {
    expect(lifecycleToMessageStatus({ ...defaultMessageLifecycle, send: "sending" })).toBe("sending");
    expect(lifecycleToMessageStatus({ ...defaultMessageLifecycle, delivery: "delivered" })).toBe("sent");
    expect(lifecycleToMessageStatus({ ...defaultMessageLifecycle, delivery: "partiallyDelivered" })).toBe("sent");
    expect(lifecycleToMessageStatus({ ...defaultMessageLifecycle, read: "read" })).toBe("read");
  });
});
