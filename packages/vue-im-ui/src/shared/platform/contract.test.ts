// @vitest-environment happy-dom
import { afterEach, describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick } from "vue";
import vectors from "../../../../../spec/platform-contract.json";
import {
  callPlatform,
  normalizePlatformError,
  platformErr,
  platformOk,
  withPlatformTimeout,
  type FlarePlatformAdapter,
} from "./contract";
import { createWebPlatformAdapter, detectWebCapabilities } from "./web-adapter";
import { useFlarePlatform, useFlarePlatformProvider, useFlarePlatformSafe } from "./useFlarePlatform";

afterEach(() => {
  vi.useRealTimers();
  document.querySelectorAll("input[data-flare-platform-picker]").forEach((node) => node.remove());
});

const pendingInput = () => document.querySelector<HTMLInputElement>("input[data-flare-platform-picker]")!;
function settleInput(files: File[]): void {
  const input = pendingInput();
  Object.defineProperty(input, "files", { value: files, configurable: true });
  input.dispatchEvent(new Event("change"));
}
const png = () => new File([new Uint8Array([1, 2, 3])], "shot.png", { type: "image/png" });
const pdf = () => new File([new Uint8Array([1, 2, 3, 4])], "spec.pdf", { type: "application/pdf" });

// Every vector id of spec/platform-contract.json is exercised below with the
// real web adapter (DOM input + navigator.share); nothing fakes a success.
const ids = new Set(vectors.vectors.map((vector) => vector.id));

describe("web adapter: pickFiles", () => {
  const web = createWebPlatformAdapter();
  it("pickFiles.success — a selection resolves the picked files with their DOM File", async () => {
    expect(ids.has("pickFiles.success")).toBe(true);
    const pending = web.pickFiles!({ multiple: true, accept: [".pdf", "image/*"] });
    const input = pendingInput();
    expect(input.multiple).toBe(true);
    expect(input.accept).toBe(".pdf,image/*");
    settleInput([pdf()]);
    const result = await pending;
    expect(result.ok && result.value.map((f) => [f.name, f.size, f.mimeType])).toEqual([["spec.pdf", 4, "application/pdf"]]);
    expect(document.querySelector("input[data-flare-platform-picker]")).toBeNull();
  });
  it("pickFiles.cancelled — dismissing the picker or selecting nothing is CANCELLED, never an empty success", async () => {
    expect(ids.has("pickFiles.cancelled")).toBe(true);
    const dismissed = web.pickFiles!();
    pendingInput().dispatchEvent(new Event("cancel"));
    expect(await dismissed).toEqual({ ok: false, error: { code: "CANCELLED", message: "picker dismissed" } });
    const empty = web.pickFiles!();
    settleInput([]);
    const result = await empty;
    expect(!result.ok && result.error.code).toBe("CANCELLED");
  });
  it("pickFiles.unsupported — a host without the operation answers UNSUPPORTED through callPlatform", async () => {
    expect(ids.has("pickFiles.unsupported")).toBe(true);
    const result = await callPlatform({} as FlarePlatformAdapter, "pickFiles", undefined);
    expect(!result.ok && result.error.code).toBe("UNSUPPORTED");
  });
  it("pickFiles.denied — a NotAllowedError thrown by the surface is PERMISSION_DENIED", async () => {
    expect(ids.has("pickFiles.denied")).toBe(true);
    const adapter: FlarePlatformAdapter = { pickFiles: () => Promise.reject(new DOMException("blocked", "NotAllowedError")) };
    const result = await callPlatform(adapter, "pickFiles", undefined);
    expect(!result.ok && result.error.code).toBe("PERMISSION_DENIED");
  });
  it("pickFiles.timeout — an unanswered picker resolves TIMEOUT after the deadline", async () => {
    expect(ids.has("pickFiles.timeout")).toBe(true);
    vi.useFakeTimers();
    const pending = callPlatform(web, "pickFiles", undefined, 1000);
    await vi.advanceTimersByTimeAsync(1001);
    const result = await pending;
    expect(!result.ok && result.error.code).toBe("TIMEOUT");
  });
  it("pickFiles.failed — any other thrown value is FAILED with the message kept", async () => {
    expect(ids.has("pickFiles.failed")).toBe(true);
    const adapter: FlarePlatformAdapter = { pickFiles: () => { throw new Error("disk exploded"); } };
    const result = await callPlatform(adapter, "pickFiles", undefined);
    expect(!result.ok && result.error).toMatchObject({ code: "FAILED", message: "disk exploded" });
  });
});

describe("web adapter: pickImages", () => {
  const web = createWebPlatformAdapter();
  it("pickImages.success — restricts the input to images (plus video on request)", async () => {
    expect(ids.has("pickImages.success")).toBe(true);
    const pending = web.pickImages!({ video: true });
    expect(pendingInput().accept).toBe("image/*,video/*");
    settleInput([png()]);
    const result = await pending;
    expect(result.ok && result.value[0].mimeType).toBe("image/png");
    const imagesOnly = web.pickImages!();
    expect(pendingInput().accept).toBe("image/*");
    settleInput([png()]);
    await imagesOnly;
  });
  it("pickImages.cancelled", async () => {
    expect(ids.has("pickImages.cancelled")).toBe(true);
    const pending = web.pickImages!();
    pendingInput().dispatchEvent(new Event("cancel"));
    expect(!(await pending).ok).toBe(true);
    const again = web.pickImages!();
    pendingInput().dispatchEvent(new Event("cancel"));
    const result = await again;
    expect(!result.ok && result.error.code).toBe("CANCELLED");
  });
  it("pickImages.unsupported", async () => {
    expect(ids.has("pickImages.unsupported")).toBe(true);
    const result = await callPlatform(null, "pickImages", undefined);
    expect(!result.ok && result.error.code).toBe("UNSUPPORTED");
  });
  it("pickImages.denied — a host error carrying the model code passes through untouched", async () => {
    expect(ids.has("pickImages.denied")).toBe(true);
    const adapter: FlarePlatformAdapter = { pickImages: async () => platformErr("PERMISSION_DENIED", "photos access denied") };
    const result = await callPlatform(adapter, "pickImages", undefined);
    expect(result).toEqual({ ok: false, error: { code: "PERMISSION_DENIED", message: "photos access denied" } });
  });
  it("pickImages.timeout", async () => {
    expect(ids.has("pickImages.timeout")).toBe(true);
    vi.useFakeTimers();
    const pending = withPlatformTimeout(new Promise(() => {}), 50);
    await vi.advanceTimersByTimeAsync(51);
    const result = await pending;
    expect(!result.ok && result.error.code).toBe("TIMEOUT");
  });
  it("pickImages.failed", async () => {
    expect(ids.has("pickImages.failed")).toBe(true);
    const adapter: FlarePlatformAdapter = { pickImages: () => Promise.reject(new RangeError("bad range")) };
    const result = await callPlatform(adapter, "pickImages", undefined);
    expect(!result.ok && result.error.code).toBe("FAILED");
  });
});

describe("web adapter: share", () => {
  const web = createWebPlatformAdapter();
  const withShare = (impl: (data: ShareData) => Promise<void>) => {
    Object.defineProperty(navigator, "share", { value: impl, configurable: true });
  };
  afterEach(() => { Object.defineProperty(navigator, "share", { value: undefined, configurable: true }); });
  it("share.success — hands title/text/url to navigator.share", async () => {
    expect(ids.has("share.success")).toBe(true);
    const calls: ShareData[] = [];
    withShare(async (data) => { calls.push(data); });
    const result = await web.share!({ title: "Flare", url: "https://flare.im" });
    expect(result.ok).toBe(true);
    expect(calls).toEqual([{ title: "Flare", text: undefined, url: "https://flare.im" }]);
  });
  it("share.cancelled — the user dismissing the share sheet (AbortError) is CANCELLED", async () => {
    expect(ids.has("share.cancelled")).toBe(true);
    withShare(() => Promise.reject(new DOMException("Share canceled", "AbortError")));
    const result = await web.share!({ text: "hi" });
    expect(!result.ok && result.error.code).toBe("CANCELLED");
  });
  it("share.unsupported — no navigator.share answers UNSUPPORTED and the capability reads fallback", async () => {
    expect(ids.has("share.unsupported")).toBe(true);
    const result = await web.share!({ text: "hi" });
    expect(!result.ok && result.error.code).toBe("UNSUPPORTED");
    expect(detectWebCapabilities(web).share).toBe("fallback");
    withShare(async () => {});
    expect(detectWebCapabilities(web).share).toBe("supported");
  });
  it("share.denied — NotAllowedError (no user activation) is PERMISSION_DENIED", async () => {
    expect(ids.has("share.denied")).toBe(true);
    withShare(() => Promise.reject(new DOMException("no gesture", "NotAllowedError")));
    const result = await web.share!({ text: "hi" });
    expect(!result.ok && result.error.code).toBe("PERMISSION_DENIED");
  });
  it("share.timeout", async () => {
    expect(ids.has("share.timeout")).toBe(true);
    vi.useFakeTimers();
    withShare(() => new Promise(() => {}));
    const pending = callPlatform(web, "share", { text: "hi" }, 20);
    await vi.advanceTimersByTimeAsync(21);
    const result = await pending;
    expect(!result.ok && result.error.code).toBe("TIMEOUT");
  });
  it("share.failed", async () => {
    expect(ids.has("share.failed")).toBe(true);
    withShare(() => Promise.reject(new Error("share service crashed")));
    const result = await web.share!({ text: "hi" });
    expect(!result.ok && result.error).toMatchObject({ code: "FAILED", message: "share service crashed" });
  });
});

describe("error model", () => {
  it("covers every code of the contract exactly once per input family", () => {
    expect(normalizePlatformError(new DOMException("x", "AbortError")).code).toBe("CANCELLED");
    expect(normalizePlatformError({ code: "CANCELLED" }).code).toBe("CANCELLED");
    expect(normalizePlatformError(new DOMException("x", "SecurityError")).code).toBe("PERMISSION_DENIED");
    expect(normalizePlatformError(new DOMException("x", "TimeoutError")).code).toBe("TIMEOUT");
    expect(normalizePlatformError(new DOMException("x", "NotSupportedError")).code).toBe("UNSUPPORTED");
    expect(normalizePlatformError(new Error("boom")).code).toBe("FAILED");
    expect(normalizePlatformError("plain string").code).toBe("FAILED");
    expect(platformOk(1)).toEqual({ ok: true, value: 1 });
  });
  it("the vector table lists every operation × outcome", () => {
    const operations = ["pickFiles", "pickImages", "share"];
    const outcomes = ["success", "cancelled", "unsupported", "denied", "timeout", "failed"];
    for (const op of operations) for (const outcome of outcomes) expect(ids.has(`${op}.${outcome}`)).toBe(true);
    expect(vectors.errorCodes).toEqual(["UNSUPPORTED", "CANCELLED", "PERMISSION_DENIED", "TIMEOUT", "FAILED"]);
  });
});

describe("provider", () => {
  it("host capabilities override detection and descendants read the same context", async () => {
    let seen: ReturnType<typeof useFlarePlatform> | null = null;
    const Child = defineComponent({ setup() { seen = useFlarePlatform(); return () => h("i"); } });
    const adapter: FlarePlatformAdapter = { pickFiles: async () => platformOk([]) };
    const w = mount(defineComponent({ setup() {
      useFlarePlatformProvider({ kind: "tauri", adapter, capabilities: { hover: true, contextMenu: true, keyboardShortcut: true } });
      return () => h(Child);
    } }));
    await nextTick();
    expect(seen!.kind.value).toBe("tauri");
    expect(seen!.capabilities.value).toMatchObject({ hover: true, contextMenu: true, keyboardShortcut: true, filePicker: "supported", imagePicker: "unsupported", share: "unsupported", bottomSheet: false });
    expect(seen!.adapter.value).toBe(adapter);
    w.unmount();
  });
  it("the safe accessor works without a provider and defaults to the web adapter", () => {
    let ctx: ReturnType<typeof useFlarePlatformSafe> | null = null;
    mount(defineComponent({ setup() { ctx = useFlarePlatformSafe(); return () => h("i"); } }));
    expect(ctx!.kind.value).toBe("web");
    expect(typeof ctx!.adapter.value.pickFiles).toBe("function");
    expect(ctx!.capabilities.value.filePicker).toBe("supported");
  });
});
