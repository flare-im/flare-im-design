// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, reactive, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import FlareDrawer from "./FlareDrawer.vue";
import FlareSelect from "../form/FlareSelect.vue";

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

interface MountOptions {
  slots?: Record<string, () => unknown>;
  bottomSheet?: boolean;
  nativeBack?: boolean;
}

function mountDrawer(props: Record<string, unknown>, options: MountOptions = {}) {
  const state = reactive<Record<string, unknown>>({ open: true, ...props });
  const events: string[] = [];
  const handlers: Array<() => boolean> = [];
  const adapter = {
    onNativeBack(handler: () => boolean) {
      handlers.push(handler);
      return () => handlers.splice(handlers.indexOf(handler), 1);
    },
  };
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("en-US");
      useFlarePlatformProvider({ adapter, capabilities: { nativeBack: options.nativeBack ?? false, bottomSheet: options.bottomSheet ?? false } });
      return () => h(FlareDrawer as Component, {
        ...state,
        onClose: () => events.push("close"),
        onBack: () => events.push("back"),
      }, {
        default: () => h("button", { class: "row" }, "Row"),
        ...options.slots,
      });
    },
  }), { attachTo: document.body });
  return { state, events, handlers };
}

const surface = () => document.body.querySelector('[role="dialog"]') as HTMLElement;
const button = (label: string) => surface().querySelector<HTMLButtonElement>(`[aria-label="${label}"]`);
const escape = () => document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
// 真键盘事件从获得焦点的元素出发、冒泡到 document,并且可取消 —— 捕获阶段的监听才先于冒泡的那些,preventDefault 才留得下痕迹。
const pressEscape = (from: Element) => from.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true, cancelable: true }));

describe("FlareDrawer DOM contract", () => {
  it("is a named, modal dialog surface stamped drawer, docked to the inline end over the shared scrim", async () => {
    mountDrawer({ title: "Group details" });
    await nextTick();
    expect(surface().getAttribute("aria-modal")).toBe("true");
    expect(surface().getAttribute("aria-label")).toBe("Group details");
    expect(surface().dataset.flarePresentation).toBe("drawer");
    expect(surface().dataset.flarePlacement).toBe("end");
    expect(surface().classList).toContain("flare-drawer--end");
    expect(surface().querySelector("h2")?.textContent).toBe("Group details");
    const scrim = surface().parentElement!;
    expect(scrim.classList).toContain("flare-overlay-scrim");
    expect(scrim.classList).toContain("flare-drawer-scrim--end");
  });

  it("docks to the start edge when asked", async () => {
    mountDrawer({ title: "Filters", placement: "start" });
    await nextTick();
    expect(surface().dataset.flarePlacement).toBe("start");
    expect(surface().classList).toContain("flare-drawer--start");
    expect(surface().parentElement!.classList).toContain("flare-drawer-scrim--start");
  });

  it("names itself from label, then a localized fallback", async () => {
    mountDrawer({ label: "Settings", showClose: false });
    await nextTick();
    expect(surface().getAttribute("aria-label")).toBe("Settings");
    // Page content that brings its own header: no title, no actions, no close → no header row.
    expect(surface().querySelector("header")).toBeNull();
    reset();
    mountDrawer({});
    await nextTick();
    expect(surface().getAttribute("aria-label")).toBe("Side panel");
  });

  it("takes a per-instance width through its own style and is full width on the phone form factor", async () => {
    mountDrawer({ title: "A", width: "360px" });
    await nextTick();
    expect(surface().style.getPropertyValue("--flare-drawer-width")).toBe("360px");
    expect(surface().classList).not.toContain("flare-drawer--compact");
    reset();
    mountDrawer({ title: "A" }, { bottomSheet: true });
    await nextTick();
    expect(surface().classList).toContain("flare-drawer--compact");
  });

  it("draws header actions as chrome and a sticky footer after the body", async () => {
    mountDrawer({ title: "Profile" }, {
      slots: {
        actions: () => h("button", { class: "edit" }, "Edit"),
        footer: () => h("button", { class: "save" }, "Save"),
      },
    });
    await nextTick();
    expect(surface().querySelector(".edit")!.closest("[data-flare-overlay-chrome]")).not.toBeNull();
    expect(surface().querySelector("footer.flare-drawer__footer .save")).not.toBeNull();
  });

  it("gives initial focus to the content, not to the header buttons", async () => {
    mountDrawer({ title: "Details", showBack: true });
    await nextTick();
    await nextTick();
    expect(document.activeElement).toBe(surface().querySelector(".row"));
  });
});

describe("FlareDrawer navigation and closing", () => {
  it("closes from the close button, Escape and the scrim", async () => {
    const { events } = mountDrawer({ title: "Details" });
    await nextTick();
    button("Close")!.click();
    escape();
    surface().click();
    (surface().parentElement as HTMLElement).click();
    await nextTick();
    expect(events).toEqual(["close", "close", "close"]);
  });

  it("with showBack, the back button, Escape and the platform back go back one page; the scrim still closes", async () => {
    const { events, handlers } = mountDrawer({ title: "Members", showBack: true }, { nativeBack: true });
    await nextTick();
    expect(handlers).toHaveLength(1);
    button("Back")!.click();
    escape();
    handlers[0]();
    await nextTick();
    expect(events).toEqual(["back", "back", "back"]);
    (surface().parentElement as HTMLElement).click();
    button("Close")!.click();
    expect(events).toEqual(["back", "back", "back", "close", "close"]);
  });

  it("leaves an Escape that closes an inner Select popover to the Select: no back, and the next Escape goes back", async () => {
    const { events } = mountDrawer({ title: "Privacy", showBack: true }, {
      slots: {
        default: () => h(FlareSelect as Component, {
          title: "Profile visibility",
          options: [{ value: "all", label: "Everyone" }, { value: "friends", label: "Friends" }],
          modelValue: "all",
        }),
      },
    });
    await nextTick();
    const trigger = surface().querySelector<HTMLButtonElement>("button.flare-select__trigger")!;
    trigger.click();
    await nextTick();
    expect(trigger.getAttribute("aria-expanded")).toBe("true");
    pressEscape(trigger);
    await nextTick();
    expect(trigger.getAttribute("aria-expanded")).toBe("false");
    expect(events).toEqual([]);
    pressEscape(trigger);
    await nextTick();
    expect(events).toEqual(["back"]);
  });

  it("follows showBack as it changes while open: the platform back closes on the root page", async () => {
    const { state, events, handlers } = mountDrawer({ title: "Settings" }, { nativeBack: true });
    await nextTick();
    handlers.at(-1)!();
    expect(events).toEqual(["close"]);
    state.showBack = true;
    await nextTick();
    handlers.at(-1)!();
    expect(events).toEqual(["close", "back"]);
  });

  it("blocks every way out while not dismissible and disables the header buttons", async () => {
    const { state, events, handlers } = mountDrawer({ title: "Saving", showBack: true, dismissible: false }, { nativeBack: true });
    await nextTick();
    expect(button("Back")!.disabled).toBe(true);
    expect(button("Close")!.disabled).toBe(true);
    button("Back")!.click();
    button("Close")!.click();
    escape();
    handlers.at(-1)!();
    (surface().parentElement as HTMLElement).click();
    await nextTick();
    expect(events).toEqual([]);
    state.dismissible = true;
    await nextTick();
    escape();
    expect(events).toEqual(["back"]);
  });

  it("moves focus to the heading when the host swaps pages inside it", async () => {
    const { state } = mountDrawer({ title: "Settings" });
    await nextTick();
    await nextTick();
    expect(document.activeElement).toBe(surface().querySelector(".row"));
    // The host pushes a page: back appears and the title changes.
    state.showBack = true;
    state.title = "Privacy";
    await nextTick();
    await nextTick();
    expect(document.activeElement).toBe(surface().querySelector("h2"));
    expect(document.activeElement?.textContent).toBe("Privacy");
  });

  it("leaves focus alone when only the title changes and focus is still inside", async () => {
    const { state } = mountDrawer({ title: "Members (3)" });
    await nextTick();
    await nextTick();
    const row = surface().querySelector(".row");
    expect(document.activeElement).toBe(row);
    state.title = "Members (4)";
    await nextTick();
    await nextTick();
    expect(document.activeElement).toBe(row);
  });

  it("locks the page scroll while open and restores it when closed", async () => {
    const { state } = mountDrawer({ title: "Details" });
    await nextTick();
    expect(document.body.style.overflow).toBe("hidden");
    state.open = false;
    await nextTick();
    expect(document.body.style.overflow).toBe("");
  });
});
