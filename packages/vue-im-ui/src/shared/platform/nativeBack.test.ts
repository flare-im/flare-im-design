// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, reactive, type Component } from "vue";
import { useFlareI18nProvider } from "../i18n/useFlareI18n";
import ConversationHeader from "../../components/messages/ConversationHeader.vue";
import FlareBottomSheet from "../../components/general/FlareBottomSheet.vue";
import FlareScreen from "../../components/layout/FlareScreen.vue";
import { createHistoryBackListener, createWebPlatformAdapter, detectWebCapabilities, type FlareHistoryWindow } from "./web-adapter";
import { useFlarePlatformProvider } from "./useFlarePlatform";

/** A linear history with synchronous popstate, the part of `window` the listener uses. */
function fakeWindow(initialState: Record<string, unknown> = { position: 3 }) {
  const entries: unknown[] = [initialState];
  let index = 0;
  let leftPage = false;
  const listeners: Array<() => void> = [];
  const timers: Array<() => void> = [];
  const history = {
    get state() { return entries[index]; },
    pushState(state: unknown) {
      entries.splice(index + 1);
      entries.push(state);
      index += 1;
    },
    back() {
      if (index === 0) { leftPage = true; return; }
      index -= 1;
      listeners.forEach((listener) => listener());
    },
  };
  const win = {
    history,
    addEventListener: (_type: string, listener: () => void) => { listeners.push(listener); },
    setTimeout: (callback: () => void) => { timers.push(callback); return 0; },
  } as unknown as FlareHistoryWindow;
  return {
    win,
    entries,
    get index() { return index; },
    get leftPage() { return leftPage; },
    runTimers: () => timers.splice(0).forEach((callback) => callback()),
  };
}

describe("browser back as the platform back", () => {
  it("is off unless the host asks for it", () => {
    expect(detectWebCapabilities(createWebPlatformAdapter()).nativeBack).toBe(false);
    expect(detectWebCapabilities(createWebPlatformAdapter({ historyBack: true })).nativeBack).toBe(true);
  });

  it("closes the newest layer first and marks history again for the layers still open", () => {
    const page = fakeWindow();
    const listen = createHistoryBackListener(page.win);
    const closed: string[] = [];
    const releaseChat = listen(() => { closed.push("chat"); releaseChat(); return true; });
    expect(page.entries).toEqual([{ position: 3 }, { position: 3, flareNativeBack: true }]);
    const releaseSheet = listen(() => { closed.push("sheet"); releaseSheet(); return true; });
    expect(page.entries).toHaveLength(2);

    page.win.history.back();
    page.runTimers();
    expect(closed).toEqual(["sheet"]);
    expect(page.index).toBe(1);

    page.win.history.back();
    page.runTimers();
    expect(closed).toEqual(["sheet", "chat"]);
    expect(page.index).toBe(0);
    expect(page.leftPage).toBe(false);
  });

  it("lets one back leave the page after a layer closed on its own", () => {
    const page = fakeWindow();
    const listen = createHistoryBackListener(page.win);
    let called = false;
    const release = listen(() => { called = true; return true; });
    release();
    page.win.history.back();
    expect(called).toBe(false);
    expect(page.leftPage).toBe(true);
  });

  it("ignores arriving on a marked entry and leaves an unmarked one alone", () => {
    const page = fakeWindow();
    const listen = createHistoryBackListener(page.win);
    let calls = 0;
    listen(() => { calls += 1; return true; });
    page.win.history.pushState({ position: 4 }, "");
    page.win.history.back();
    expect(calls).toBe(0);
    expect(page.index).toBe(1);
  });
});

describe("kit layers and the platform back", () => {
  let host: ReturnType<typeof mount> | undefined;
  afterEach(() => { host?.unmount(); host = undefined; document.body.innerHTML = ""; });

  function mountLayers(state: { sheetOpen: boolean; showBack: boolean }, nativeBack = true) {
    const handlers: Array<() => boolean> = [];
    const events: string[] = [];
    const adapter = {
      onNativeBack(handler: () => boolean) {
        handlers.push(handler);
        return () => handlers.splice(handlers.indexOf(handler), 1);
      },
    };
    host = mount(defineComponent({
      setup() {
        useFlareI18nProvider("en-US");
        useFlarePlatformProvider({ adapter, capabilities: { nativeBack } });
        return () => [
          h(ConversationHeader as Component, { identity: { id: "ivy", title: "Ivy", kind: "direct" }, showBack: state.showBack, onBack: () => events.push("header") }),
          h(FlareScreen as Component, { title: "Search", back: true }),
          h(FlareBottomSheet as Component, { open: state.sheetOpen, onClose: () => { events.push("sheet"); state.sheetOpen = false; } }, { default: () => h("button", "Mute") }),
        ];
      },
    }), { attachTo: document.body });
    return { handlers, events };
  }

  it("routes back to the open sheet, then to the header's back control", async () => {
    const state = reactive({ sheetOpen: false, showBack: true });
    const { handlers, events } = mountLayers(state);
    // The screen shows a back button but nobody listens to it, so it claims nothing.
    expect(handlers).toHaveLength(1);
    state.sheetOpen = true;
    await nextTick();
    expect(handlers).toHaveLength(2);

    expect(handlers.at(-1)!()).toBe(true);
    await nextTick();
    expect(events).toEqual(["sheet"]);
    expect(handlers).toHaveLength(1);

    handlers.at(-1)!();
    expect(events).toEqual(["sheet", "header"]);
    state.showBack = false;
    await nextTick();
    expect(handlers).toHaveLength(0);
  });

  it("claims nothing when the platform has no native back", async () => {
    const state = reactive({ sheetOpen: true, showBack: true });
    const { handlers } = mountLayers(state, false);
    await nextTick();
    expect(handlers).toHaveLength(0);
  });
});
