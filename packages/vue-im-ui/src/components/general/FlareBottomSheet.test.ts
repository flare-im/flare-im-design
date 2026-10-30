// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, reactive, ref, type Component } from "vue";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import type { FlareAdaptiveContext } from "../../composables/useAdaptiveMode";
import FlareBottomSheet from "./FlareBottomSheet.vue";
import FlareModal from "./FlareModal.vue";
import { useFlareSheetOwnHeader } from "../../shared/sheetHeader";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => {
  host?.unmount();
  host = undefined;
  document.body.innerHTML = "";
  document.body.style.overflow = "";
});

function reset(): void {
  host?.unmount();
  host = undefined;
  document.body.innerHTML = "";
}

function mountSheet(props: Record<string, unknown>, bottomSheet?: boolean) {
  host = mount(defineComponent({
    setup() {
      if (bottomSheet !== undefined) useFlarePlatformProvider({ capabilities: { bottomSheet } });
      return () => h(FlareBottomSheet as Component, { open: true, title: "Notifications", ...props }, { default: () => h("button", "All messages") });
    },
  }), { attachTo: document.body });
}

function surface(): HTMLElement {
  return document.body.querySelector('[role="dialog"]') as HTMLElement;
}

describe("FlareBottomSheet presentation", () => {
  it("is a bottom sheet with a grip on phone form factors", async () => {
    mountSheet({}, true);
    await nextTick();
    expect(surface().dataset.flarePresentation).toBe("sheet");
    expect(surface().classList).toContain("flare-sheet");
    expect(surface().querySelector(".flare-sheet__grip")).not.toBeNull();
    expect(surface().getAttribute("aria-modal")).toBe("true");
    expect(surface().getAttribute("aria-label")).toBe("Notifications");
    // One shared scrim class across Sheet, Modal and Drawer.
    expect(surface().parentElement!.classList).toContain("flare-overlay-scrim");
  });

  it("hands the same content to FlareModal on pointer devices, keeping today's chrome (no close button)", async () => {
    mountSheet({ dialogWidth: "720px", maxHeight: "60vh" }, false);
    await nextTick();
    expect(host!.findComponent(FlareModal).exists()).toBe(true);
    expect(document.body.querySelectorAll('[role="dialog"]')).toHaveLength(1);
    expect(surface().dataset.flarePresentation).toBe("dialog");
    expect(surface().classList).toContain("flare-modal");
    expect(surface().querySelector(".flare-sheet__grip")).toBeNull();
    expect(surface().getAttribute("aria-label")).toBe("Notifications");
    expect(surface().querySelector(".flare-modal__title")?.textContent).toBe("Notifications");
    expect(surface().querySelector(".flare-modal__close")).toBeNull();
    expect(surface().style.maxHeight).toBe("60vh");
    expect(surface().style.getPropertyValue("--flare-modal-width")).toBe("720px");
    expect(surface().textContent).toContain("All messages");
    expect(surface().parentElement!.classList).toContain("flare-overlay-scrim");
  });

  it("offers the opt-in close control on phones and desktops, honoring the dismissal lock", async () => {
    for (const bottomSheet of [true, false]) {
      let closed = 0;
      mountSheet({ showClose: true, onClose: () => closed++ }, bottomSheet);
      await nextTick();
      const close = surface().querySelector('button[aria-label="关闭"]') as HTMLButtonElement;
      expect(close).not.toBeNull();
      close.click();
      expect(closed).toBe(1);
      reset();
      mountSheet({ showClose: true, dismissible: false, onClose: () => closed++ }, bottomSheet);
      await nextTick();
      const locked = surface().querySelector('button[aria-label="关闭"]') as HTMLButtonElement;
      expect(locked.disabled).toBe(true);
      locked.click();
      expect(closed).toBe(1);
      reset();
      mountSheet({ showClose: true, titleHidden: true }, bottomSheet);
      await nextTick();
      expect(surface().querySelector('button[aria-label="关闭"]')).not.toBeNull();
      expect(surface().querySelector(".flare-sheet__title,.flare-modal__title")).toBeNull();
      reset();
    }
  });

  it("honours an explicit sheet presentation on a pointer device, with the height cap", async () => {
    mountSheet({ presentation: "sheet", maxHeight: "40vh" }, false);
    await nextTick();
    expect(host!.findComponent(FlareModal).exists()).toBe(false);
    expect(surface().dataset.flarePresentation).toBe("sheet");
    expect(surface().style.maxHeight).toBe("40vh");
  });

  it("resolves auto once when it opens and keeps it until it closes", async () => {
    const isH5 = ref(true);
    const state = reactive({ open: true });
    host = mount(defineComponent({
      setup() {
        useFlarePlatformProvider({ adaptive: { isH5 } as unknown as FlareAdaptiveContext });
        return () => h(FlareBottomSheet as Component, { open: state.open, title: "Edit", onClose: () => { state.open = false; } }, {
          default: () => h("input", { class: "draft" }),
        });
      },
    }), { attachTo: document.body });
    await nextTick();
    const input = document.body.querySelector<HTMLInputElement>("input.draft")!;
    input.value = "half-typed";
    expect(surface().dataset.flarePresentation).toBe("sheet");

    // Crossing the breakpoint while open neither swaps the surface nor remounts the content.
    isH5.value = false;
    await nextTick();
    expect(surface().dataset.flarePresentation).toBe("sheet");
    expect(document.body.querySelector("input.draft")).toBe(input);
    expect(input.value).toBe("half-typed");

    // The next open reads the form factor again.
    state.open = false;
    await nextTick();
    state.open = true;
    await nextTick();
    expect(surface().dataset.flarePresentation).toBe("dialog");
  });

  it("registers one modal surface whichever branch shows: one Escape closes it and releases the lock", async () => {
    for (const bottomSheet of [true, false]) {
      const state = reactive({ open: true });
      const closed: string[] = [];
      host = mount(defineComponent({
        setup() {
          useFlarePlatformProvider({ capabilities: { bottomSheet } });
          return () => h(FlareBottomSheet as Component, { open: state.open, title: "Edit", onClose: () => { closed.push("sheet"); state.open = false; } }, {
            default: () => h("button", "Save"),
          });
        },
      }), { attachTo: document.body });
      await nextTick();
      expect(document.body.style.overflow).toBe("hidden");
      document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
      await nextTick();
      expect(closed, bottomSheet ? "sheet" : "dialog").toEqual(["sheet"]);
      expect(document.body.style.overflow).toBe("");
      reset();
    }
  });

  it("keeps a non-dismissible surface open for Escape and the scrim on both branches", async () => {
    for (const bottomSheet of [true, false]) {
      const closed: string[] = [];
      host = mount(defineComponent({
        setup() {
          useFlarePlatformProvider({ capabilities: { bottomSheet } });
          return () => h(FlareBottomSheet as Component, { open: true, title: "Busy", dismissible: false, onClose: () => closed.push("close") }, {
            default: () => h("button", "Wait"),
          });
        },
      }), { attachTo: document.body });
      await nextTick();
      document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
      (document.body.querySelector(".flare-overlay-scrim") as HTMLElement).click();
      await nextTick();
      expect(closed, bottomSheet ? "sheet" : "dialog").toEqual([]);
      reset();
    }
  });
});

describe("FlareBottomSheet fill", () => {
  // Sheet content with its own header row, like the kit LocationPicker and ContactPicker.
  const OwnHeader = defineComponent({
    setup() {
      useFlareSheetOwnHeader();
      return () => h("section", { class: "own-header" }, [h("header", "Location"), h("ul", "rows")]);
    },
  });
  function mountFill(props: Record<string, unknown>, bottomSheet: boolean, content: Component = OwnHeader) {
    host = mount(defineComponent({
      setup() {
        useFlarePlatformProvider({ capabilities: { bottomSheet } });
        return () => h(FlareBottomSheet as Component, { open: true, title: "Location", ...props }, { default: () => h(content) });
      },
    }), { attachTo: document.body });
  }

  it("takes its whole height cap and hands the content the rest, without a second title", async () => {
    mountFill({ fill: true, maxHeight: "90vh" }, true);
    await nextTick();
    expect(surface().classList).toContain("flare-sheet--fill");
    expect(surface().style.height).toBe("90vh");
    expect(surface().style.maxHeight).toBe("90vh");
    expect(surface().querySelector(".flare-sheet__fill > .own-header")).not.toBeNull();
    // The content brings its own header: the sheet's title stays the accessible name only.
    expect(surface().querySelector(".flare-sheet__title")).toBeNull();
    expect(surface().getAttribute("aria-label")).toBe("Location");
  });

  it("keeps its title for fill content without its own header", async () => {
    mountFill({ fill: true }, true, defineComponent({ setup: () => () => h("div", { class: "plain" }, "rows") }));
    await nextTick();
    expect(surface().querySelector(".flare-sheet__title")?.textContent).toBe("Location");
    expect(surface().style.height).toBe("72vh");
  });

  it("changes nothing without fill, even for content with its own header", async () => {
    mountFill({}, true);
    await nextTick();
    expect(surface().classList).not.toContain("flare-sheet--fill");
    expect(surface().style.height).toBe("");
    expect(surface().querySelector(".flare-sheet__fill")).toBeNull();
    expect(surface().querySelector(".flare-sheet__title")?.textContent).toBe("Location");
  });

  it("hands fill to FlareModal off the phone, with the heading hidden for own-header content", async () => {
    mountFill({ fill: true, maxHeight: "80vh" }, false);
    await nextTick();
    const modal = host!.findComponent(FlareModal);
    expect(modal.props("fill")).toBe(true);
    expect(modal.props("scrollable")).toBe(false);
    expect(modal.props("titleHidden")).toBe(true);
    expect(surface().style.height).toBe("80vh");
    expect(surface().querySelector(".flare-modal__title")).toBeNull();
    expect(surface().getAttribute("aria-label")).toBe("Location");
    expect(surface().querySelector(".flare-sheet__fill > .own-header")).not.toBeNull();
  });
});

describe("FlareBottomSheet and the platform back", () => {
  function mountWithBack(listen: boolean, bottomSheet: boolean) {
    const handlers: Array<() => boolean> = [];
    const adapter = {
      onNativeBack(handler: () => boolean) {
        handlers.push(handler);
        return () => handlers.splice(handlers.indexOf(handler), 1);
      },
    };
    const closed: string[] = [];
    host = mount(defineComponent({
      setup() {
        useFlarePlatformProvider({ adapter, capabilities: { nativeBack: true, bottomSheet } });
        const listeners = listen ? { onClose: () => closed.push("close") } : {};
        return () => h(FlareBottomSheet as Component, { open: true, title: "Row actions", ...listeners }, { default: () => h("button", "Mute") });
      },
    }), { attachTo: document.body });
    return { handlers, closed };
  }

  it("claims no back when the host does not listen to close, on either branch", async () => {
    for (const bottomSheet of [true, false]) {
      const { handlers } = mountWithBack(false, bottomSheet);
      await nextTick();
      expect(handlers, bottomSheet ? "sheet" : "dialog").toHaveLength(0);
      reset();
    }
  });

  it("claims exactly one back when the host listens, and that back closes it", async () => {
    for (const bottomSheet of [true, false]) {
      const { handlers, closed } = mountWithBack(true, bottomSheet);
      await nextTick();
      expect(handlers, bottomSheet ? "sheet" : "dialog").toHaveLength(1);
      handlers[0]();
      expect(closed).toEqual(["close"]);
      reset();
    }
  });
});
