// @vitest-environment happy-dom
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, reactive, type Component } from "vue";
import { useFlareI18nProvider } from "../i18n/useFlareI18n";
import ConversationHeader from "../../components/messages/ConversationHeader.vue";
import FlareBottomSheet from "../../components/general/FlareBottomSheet.vue";
import FlareScreen from "../../components/layout/FlareScreen.vue";
import FlareResponsiveLayout from "../../components/layout/FlareResponsiveLayout.vue";
import FlareMessageBatchToolbar from "../../components/messages/FlareMessageBatchToolbar.vue";
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

/**
 * 多选是一层上下文层(shared/useContextualLayer.ts):kit 的返回控件先关它,平台返回也先到它 ——
 * 不管谁最后认领。认领顺序的洞是真实的:useFlareNativeBack 按认领时间「最后认领者赢」,响应式布局
 * 跨断点 resize 时会重新认领、压到工具条上面;从前那样返回键会直接切回列表,选择态被丢在后面。
 */
describe("kit back controls and the multi-select layer", () => {
  let host: ReturnType<typeof mount> | undefined;
  // happy-dom 没有布局:clientWidth 恒 0、ResizeObserver 从不触发。布局要靠宽度决定栏数,
  // 所以这里给它一个能读到的宽度,并把观察者的回调抓在手里 —— 触发它就是一次真实的 resize。
  const realObserver = globalThis.ResizeObserver;
  // happy-dom 把 clientWidth 定义在 HTMLElement.prototype 上,盖它就得盖在同一层。
  const realClientWidth = Object.getOwnPropertyDescriptor(HTMLElement.prototype, "clientWidth");
  let resize: ((width: number) => void) | undefined;
  beforeEach(() => {
    Object.defineProperty(HTMLElement.prototype, "clientWidth", { configurable: true, get: () => 1200 });
    globalThis.ResizeObserver = class {
      constructor(private readonly callback: ResizeObserverCallback) {}
      // 只抓布局自己的观察者(页头也有一个,量的是紧凑模式)。
      observe(target: Element): void {
        if (!target.classList.contains("flare-rl")) return;
        resize = (width) => this.callback([{ target, contentRect: { width } } as ResizeObserverEntry], this as unknown as ResizeObserver);
      }
      unobserve(): void {}
      disconnect(): void {}
    } as unknown as typeof ResizeObserver;
  });
  afterEach(() => {
    host?.unmount();
    host = undefined;
    document.body.innerHTML = "";
    globalThis.ResizeObserver = realObserver;
    if (realClientWidth) Object.defineProperty(HTMLElement.prototype, "clientWidth", realClientWidth);
    else delete (HTMLElement.prototype as { clientWidth?: number }).clientWidth;
    resize = undefined;
  });

  function mountSelection(state: { selecting: boolean }) {
    const handlers: Array<() => boolean> = [];
    const events: string[] = [];
    const adapter = {
      onNativeBack(handler: () => boolean) {
        handlers.push(handler);
        return () => handlers.splice(handlers.indexOf(handler), 1);
      },
    };
    const toolbar = () => (state.selecting
      ? h(FlareMessageBatchToolbar as Component, {
          selectedIds: ["a"], total: 3, capabilities: { delete: true },
          onExit: () => { events.push("exit"); state.selecting = false; },
        })
      : null);
    host = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        useFlarePlatformProvider({ adapter, capabilities: { nativeBack: true } });
        return () => h(FlareResponsiveLayout as Component, {
          activePane: "chat",
          onPaneChange: (pane: string) => events.push(`pane:${pane}`),
        }, {
          list: () => h("div", "list"),
          chat: () => [
            h(ConversationHeader as Component, { identity: { id: "ivy", title: "Ivy", kind: "direct" }, showBack: true, onBack: () => events.push("header") }),
            toolbar(),
          ],
        });
      },
    }), { attachTo: document.body });
    return { handlers, events };
  }

  it("the header's arrow leaves the selection first, then the page", async () => {
    const state = reactive({ selecting: true });
    const { events } = mountSelection(state);
    await nextTick();
    const arrow = host!.get('[aria-label="返回"]');
    await arrow.trigger("click");
    await nextTick();
    expect(events).toEqual(["exit"]);
    expect(host!.findAll(".flare-batch-toolbar")).toHaveLength(0);
    await host!.get('[aria-label="返回"]').trigger("click");
    expect(events).toEqual(["exit", "header"]);
  });

  it("the platform back reaches the selection even after a later claimant re-claimed it", async () => {
    const state = reactive({ selecting: true });
    const { handlers, events } = mountSelection(state);
    // 双栏:布局不认领(它在 setup 里先按 0 宽认领、挂载后量到宽度才放手),页头与工具条认领。
    await nextTick();
    expect(handlers).toHaveLength(2);
    const before = new Set(handlers);
    // 窗口缩到单栏:布局这时才认领 —— 它的 watch 在重渲染之前跑,所以它是 resize 之后第一个新认领者;
    // 单栏重挂载的页头与工具条排在它后面。从前布局这一下返回会直接切回列表,选择态被丢在后面。
    resize!(400);
    await nextTick();
    const layoutBack = handlers.find((handler) => !before.has(handler));
    expect(layoutBack).toBeDefined();
    expect(layoutBack!()).toBe(true);
    await nextTick();
    expect(events).toEqual(["exit"]);
    // 选择退出之后,同一下返回才是布局自己的:切回列表。
    layoutBack!();
    expect(events).toEqual(["exit", "pane:list"]);
  });
});
