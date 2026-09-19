// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, type Component } from "vue";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import FlareBottomSheet from "./FlareBottomSheet.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => { host?.unmount(); host = undefined; document.body.innerHTML = ""; });

function mountSheet(props: Record<string, unknown>, bottomSheet?: boolean) {
  host = mount(defineComponent({
    setup() {
      if (bottomSheet !== undefined) useFlarePlatformProvider({ capabilities: { bottomSheet } });
      return () => h(FlareBottomSheet as Component, { open: true, title: "Notifications", ...props }, { default: () => h("button", "All messages") });
    },
  }), { attachTo: document.body });
}

function surface(): HTMLElement {
  return document.body.querySelector(".flare-sheet") as HTMLElement;
}

describe("FlareBottomSheet presentation", () => {
  it("is a bottom sheet with a grip on phone form factors and a dialog on pointer devices", async () => {
    mountSheet({}, true);
    await nextTick();
    expect(surface().dataset.flarePresentation).toBe("sheet");
    expect(surface().querySelector(".flare-sheet__grip")).not.toBeNull();
    host!.unmount();
    mountSheet({}, false);
    await nextTick();
    expect(surface().dataset.flarePresentation).toBe("dialog");
    expect(surface().classList).toContain("flare-sheet--dialog");
    expect(surface().querySelector(".flare-sheet__grip")).toBeNull();
    expect(surface().getAttribute("role")).toBe("dialog");
    expect(surface().getAttribute("aria-label")).toBe("Notifications");
  });

  it("honours an explicit presentation, and a drawer ignores the height cap", async () => {
    mountSheet({ presentation: "drawer", maxHeight: "40vh" }, true);
    await nextTick();
    expect(surface().dataset.flarePresentation).toBe("drawer");
    expect(surface().style.maxHeight).toBe("");
    expect(document.body.querySelector(".flare-sheet-scrim--drawer")).not.toBeNull();
  });
});
