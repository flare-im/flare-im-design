import { expect, it, vi } from "vitest";
import { displayTextFromStoredPreview } from "./messagePreview";
it("delegates only system catalog keys and preserves parameters and the fallback", () => {
  const resolveSystemText = vi.fn(() => "Translated event");
  const inner = { k: "im.preview.notification", a: { ik: "social.event", p: { name: "Alice" }, fb: "fallback" } };
  expect(displayTextFromStoredPreview(JSON.stringify({ k: "im.preview.quote", a: { inner } }), "en-US", { resolveSystemText })).toBe("Translated event");
  expect(resolveSystemText).toHaveBeenCalledWith("social.event", { name: "Alice" }, "fallback");
  expect(displayTextFromStoredPreview(JSON.stringify({ k: "im.preview.user_text", a: { t: "hello" } }), "en-US", { resolveSystemText })).toBe("hello");
  expect(resolveSystemText).toHaveBeenCalledTimes(1);
  expect(displayTextFromStoredPreview(JSON.stringify(inner), "en-US")).toBe("fallback");
});
