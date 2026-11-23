// @vitest-environment happy-dom
import { describe, expect, it, vi } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h, ref } from "vue";
import type { FlareMediaResolveRequest } from "../shared/contracts/media";
import { useFlareMediaProvider, useResolvedMediaUrl } from "./useMediaResolver";
import { createMessageMediaPreviews } from "../utils/messageMediaPreviews";

describe("useResolvedMediaUrl", () => {
  it("keeps an outgoing album image across acknowledgement and uses the network after its local copy is released", async () => {
    const cache = createMessageMediaPreviews();
    cache.retain("client", [new Blob(["first"]), new Blob(["second"])]);
    const request = ref<FlareMediaResolveRequest>({ kind: "imageGroupItem", messageId: "client", mediaIndex: 1 });
    const localUrl = cache.resolve(request.value);
    expect(localUrl).toMatch(/^blob:/);
    expect(localUrl).not.toBe(cache.resolve({ ...request.value, mediaIndex: 0 }));
    const remote = vi.fn(async () => "https://cdn.example/sent-image");
    const Probe = defineComponent({
      setup() {
        const resolved = useResolvedMediaUrl(request);
        return () => h("img", { src: resolved.url.value, "data-loading": String(resolved.loading.value),
          onError: () => resolved.fallbackFromLocal(resolved.url.value) });
      },
    });
    const Host = defineComponent({
      setup() {
        useFlareMediaProvider((next) => cache.resolve(next) || remote());
        return () => h(Probe);
      },
    });
    const view = mount(Host);
    expect(view.get("img").attributes("src")).toBe(localUrl);
    cache.acknowledge("client", "server");
    request.value = { ...request.value, messageId: "server", fileId: "uploaded" };
    await view.vm.$nextTick();
    expect(view.get("img").attributes()).toMatchObject({ src: localUrl, "data-loading": "false" });
    expect(remote).not.toHaveBeenCalled();
    await view.get("img").trigger("error");
    await flushPromises();
    expect(view.get("img").attributes("src")).toBe("https://cdn.example/sent-image");
    expect(cache.resolve({ ...request.value, mediaIndex: 0 })).toMatch(/^blob:/);
    view.unmount();

    const reopened = mount(Host);
    await flushPromises();
    expect(reopened.get("img").attributes("src")).toBe("https://cdn.example/sent-image");
    expect(remote).toHaveBeenCalledTimes(2);
    reopened.unmount();
    cache.clear();
  });

  it("uses the network when the Tauri cache no longer contains a video", async () => {
    const assetUrl = "asset://localhost/sent-video.mp4";
    const resolve = vi.fn((request: FlareMediaResolveRequest) =>
      request.skipLocalPreview ? "https://cdn.example/sent-video.mp4" : assetUrl,
    );
    const Probe = defineComponent({
      setup() {
        const resolved = useResolvedMediaUrl(ref({ kind: "video", fileId: "uploaded" }));
        return () => h("video", {
          src: resolved.url.value,
          onError: () => resolved.fallbackFromLocal(resolved.url.value),
        });
      },
    });
    const Host = defineComponent({
      setup() {
        useFlareMediaProvider(resolve);
        return () => h(Probe);
      },
    });
    const view = mount(Host);
    expect(view.get("video").attributes("src")).toBe(assetUrl);
    await view.get("video").trigger("error");
    expect(resolve).toHaveBeenLastCalledWith({ kind: "video", fileId: "uploaded", skipLocalPreview: true });
    expect(view.get("video").attributes("src")).toBe("https://cdn.example/sent-video.mp4");
    view.unmount();
  });

  it("resolves once per request content, not once per request object", async () => {
    const calls: string[] = [];
    const request = ref<FlareMediaResolveRequest | null>({ kind: "image", fileId: "f1", messageId: "m1" });
    let resolved: ReturnType<typeof useResolvedMediaUrl> | undefined;
    const Probe = defineComponent({
      setup() {
        resolved = useResolvedMediaUrl(request);
        return () => h("i");
      },
    });
    const Host = defineComponent({
      setup() {
        useFlareMediaProvider(async (next) => {
          calls.push(next.fileId ?? "");
          return `https://cdn.example/${next.fileId}?sig=${calls.length}`;
        });
        return () => h(Probe);
      },
    });
    const view = mount(Host);
    await flushPromises();
    expect(resolved!.url.value).toBe("https://cdn.example/f1?sig=1");

    // A timeline refresh hands over an equal request in a new object: the picture stays, nothing is fetched again.
    request.value = { kind: "image", fileId: "f1", messageId: "m1" };
    await flushPromises();
    expect(calls).toEqual(["f1"]);
    expect(resolved!.url.value).toBe("https://cdn.example/f1?sig=1");

    // A different file does resolve again.
    request.value = { kind: "image", fileId: "f2", messageId: "m1" };
    await flushPromises();
    expect(calls).toEqual(["f1", "f2"]);
    expect(resolved!.url.value).toBe("https://cdn.example/f2?sig=2");
    view.unmount();
  });
});
