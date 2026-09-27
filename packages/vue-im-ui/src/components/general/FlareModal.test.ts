// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, reactive, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import FlareModal from "./FlareModal.vue";
import FlareDatePicker from "../form/FlareDatePicker.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => {
  host?.unmount();
  host = undefined;
  document.body.innerHTML = "";
  document.body.style.overflow = "";
});

interface MountOptions {
  slots?: Record<string, () => unknown>;
  bottomSheet?: boolean;
  listen?: boolean;
}

function mountModal(props: Record<string, unknown>, options: MountOptions = {}) {
  const state = reactive<Record<string, unknown>>({ open: true, ...props });
  const events: string[] = [];
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("en-US");
      if (options.bottomSheet !== undefined) useFlarePlatformProvider({ capabilities: { bottomSheet: options.bottomSheet } });
      const listeners = options.listen === false ? {} : { onClose: () => events.push("close") };
      return () => h(FlareModal as Component, { ...state, ...listeners }, {
        default: () => h("input", { class: "field" }),
        ...options.slots,
      });
    },
  }), { attachTo: document.body });
  return { state, events };
}

const surface = () => document.body.querySelector('[role="dialog"]') as HTMLElement;
const closeButton = () => surface().querySelector<HTMLButtonElement>('[aria-label="Close"]');
const escape = () => document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
// 真键盘事件从获得焦点的元素出发、冒泡到 document,并且可取消 —— 捕获阶段的监听才先于冒泡的那些,preventDefault 才留得下痕迹。
const pressEscape = (from: Element) => from.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true, cancelable: true }));

describe("FlareModal DOM contract", () => {
  it("is a named, modal dialog surface stamped dialog over the shared scrim", async () => {
    mountModal({ title: "Rename group" });
    await nextTick();
    expect(surface().getAttribute("aria-modal")).toBe("true");
    expect(surface().getAttribute("aria-label")).toBe("Rename group");
    expect(surface().dataset.flarePresentation).toBe("dialog");
    expect(surface().querySelector("h2")?.textContent).toBe("Rename group");
    const scrim = surface().parentElement!;
    expect(scrim.classList).toContain("flare-overlay-scrim");
    expect(scrim.classList).toContain("flare-modal-scrim");
  });

  it("names itself from label when the title is hidden or absent, and falls back to a localized name", async () => {
    mountModal({ title: "Search", titleHidden: true });
    await nextTick();
    expect(surface().getAttribute("aria-label")).toBe("Search");
    expect(surface().querySelector("h2")).toBeNull();
    host!.unmount();
    document.body.innerHTML = "";

    mountModal({ label: "Global search" });
    await nextTick();
    expect(surface().getAttribute("aria-label")).toBe("Global search");
    host!.unmount();
    document.body.innerHTML = "";

    mountModal({});
    await nextTick();
    expect(surface().getAttribute("aria-label")).toBe("Dialog");
  });

  it("sets width, height cap and fixed-height mode through the surface's own style", async () => {
    mountModal({ title: "Search", width: "720px", maxHeight: "640px", fill: true });
    await nextTick();
    expect(surface().style.getPropertyValue("--flare-modal-width")).toBe("720px");
    expect(surface().style.maxHeight).toBe("640px");
    expect(surface().style.height).toBe("640px");
    expect(surface().classList).toContain("flare-modal--fill");
  });

  it("scrolls its body by default and hands the content a bounded box when not scrollable", async () => {
    mountModal({ title: "A" });
    await nextTick();
    expect(surface().querySelector(".flare-modal__body--fixed")).toBeNull();
    host!.unmount();
    document.body.innerHTML = "";
    mountModal({ title: "A", scrollable: false });
    await nextTick();
    expect(surface().querySelector(".flare-modal__body--fixed")).not.toBeNull();
  });

  it("draws header actions as chrome and a footer row after the body", async () => {
    mountModal({ title: "Edit" }, {
      slots: {
        actions: () => h("button", { class: "header-action" }, "Help"),
        footer: () => [h("button", { class: "cancel" }, "Cancel"), h("button", { class: "save" }, "Save")],
      },
    });
    await nextTick();
    const action = surface().querySelector(".header-action")!;
    expect(action.closest("[data-flare-overlay-chrome]")).not.toBeNull();
    const footer = surface().querySelector("footer.flare-modal__footer")!;
    expect([...footer.querySelectorAll("button")].map((b) => b.textContent)).toEqual(["Cancel", "Save"]);
    // The footer comes after the body in document (and focus) order.
    const body = surface().querySelector(".flare-modal__body")!;
    expect(body.compareDocumentPosition(footer) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
  });

  it("stacks the footer on the phone form factor", async () => {
    mountModal({ title: "Edit" }, { bottomSheet: true, slots: { footer: () => h("button", "Save") } });
    await nextTick();
    expect(surface().classList).toContain("flare-modal--compact");
  });
});

describe("FlareModal closing", () => {
  it("closes from its close button, Escape and the scrim, one close each", async () => {
    const { events } = mountModal({ title: "Edit" });
    await nextTick();
    closeButton()!.click();
    escape();
    surface().click();
    (surface().parentElement as HTMLElement).click();
    await nextTick();
    // A click inside the surface does not reach the scrim.
    expect(events).toEqual(["close", "close", "close"]);
  });

  it("leaves an Escape that closes an inner date popover to the picker: no close, and the next Escape closes", async () => {
    const { events } = mountModal({ title: "Search" }, {
      slots: { default: () => h(FlareDatePicker as Component, { placeholder: "From", modelValue: "2026-09-01" }) },
    });
    await nextTick();
    const trigger = surface().querySelector<HTMLButtonElement>("button.flare-dp__trigger")!;
    trigger.click();
    await nextTick();
    expect(surface().querySelector(".flare-dp__pop")).not.toBeNull();
    pressEscape(trigger);
    await nextTick();
    expect(surface().querySelector(".flare-dp__pop")).toBeNull();
    expect(events).toEqual([]);
    pressEscape(trigger);
    await nextTick();
    expect(events).toEqual(["close"]);
  });

  it("hides the close button when asked", async () => {
    mountModal({ title: "Edit", showClose: false });
    await nextTick();
    expect(closeButton()).toBeNull();
    expect(surface().querySelector("header")).not.toBeNull();
    host!.unmount();
    document.body.innerHTML = "";
    // No title, no actions and no close button: no header row at all.
    mountModal({ label: "Preview", showClose: false });
    await nextTick();
    expect(surface().querySelector("header")).toBeNull();
  });

  it("holds while busy or not dismissible: every way out is blocked and the close button is disabled", async () => {
    for (const lock of [{ busy: true }, { dismissible: false }]) {
      const { state, events } = mountModal({ title: "Saving", ...lock });
      await nextTick();
      expect(closeButton()!.disabled).toBe(true);
      if ("busy" in lock) expect(surface().getAttribute("aria-busy")).toBe("true");
      closeButton()!.click();
      escape();
      (surface().parentElement as HTMLElement).click();
      await nextTick();
      expect(events, JSON.stringify(lock)).toEqual([]);

      Object.assign(state, { busy: false, dismissible: true });
      await nextTick();
      expect(closeButton()!.disabled).toBe(false);
      escape();
      expect(events).toEqual(["close"]);
      host!.unmount();
      host = undefined;
      document.body.innerHTML = "";
    }
  });

  it("claims the platform back only when the host listens to close", async () => {
    for (const listen of [true, false]) {
      const handlers: Array<() => boolean> = [];
      const adapter = {
        onNativeBack(handler: () => boolean) {
          handlers.push(handler);
          return () => handlers.splice(handlers.indexOf(handler), 1);
        },
      };
      const events: string[] = [];
      host = mount(defineComponent({
        setup() {
          useFlareI18nProvider("en-US");
          useFlarePlatformProvider({ adapter, capabilities: { nativeBack: true } });
          const listeners = listen ? { onClose: () => events.push("close") } : {};
          return () => h(FlareModal as Component, { open: true, title: "Edit", ...listeners });
        },
      }), { attachTo: document.body });
      await nextTick();
      expect(handlers).toHaveLength(listen ? 1 : 0);
      if (listen) {
        handlers[0]();
        expect(events).toEqual(["close"]);
      }
      host.unmount();
      host = undefined;
      document.body.innerHTML = "";
    }
  });

  it("locks the page scroll while open and restores it when closed", async () => {
    const { state } = mountModal({ title: "Edit" });
    await nextTick();
    expect(document.body.style.overflow).toBe("hidden");
    state.open = false;
    await nextTick();
    expect(document.body.style.overflow).toBe("");
  });
});
