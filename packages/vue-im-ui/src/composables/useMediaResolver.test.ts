// @vitest-environment happy-dom
import { describe, expect, it } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h, ref } from "vue";
import type { FlareMediaResolveRequest } from "../shared/contracts/media";
import { useFlareMediaProvider, useResolvedMediaUrl } from "./useMediaResolver";

describe("useResolvedMediaUrl", () => {
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
