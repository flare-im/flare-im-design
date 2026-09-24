// @vitest-environment happy-dom
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, reactive, ref, type Component, type PropType } from "vue";
import { dismissTopFlareContextualLayer, useFlareContextualLayer } from "./useContextualLayer";
import { useFlarePlatformProvider } from "./platform/useFlarePlatform";
import { useFlareI18nProvider } from "./i18n/useFlareI18n";
import FlareBottomSheet from "../components/general/FlareBottomSheet.vue";

/**
 * 上下文层的规则在真 DOM 事实上跑一遍。happy-dom 有两个空缺要说清:
 *  - `getClientRects()` 对任何元素都返回一个零矩形(源码里标着 TODO),所以「藏起来」这个事实
 *    在这里量不到 —— 用例里按行内 display:none 打桩,真正的可见性证据在浏览器 spec 里;
 *  - 没有 `[hidden]` 的 UA 样式,所以隐藏对话框一律用行内 display:none(v-show 写的也是它)。
 */
const rects = vi.spyOn(Element.prototype, "getClientRects");
function hiddenByInlineStyle(el: Element | null): boolean {
  for (let node: Element | null = el; node; node = node.parentElement) {
    if ((node as HTMLElement).style?.display === "none") return true;
  }
  return false;
}
beforeEach(() => {
  rects.mockImplementation(function (this: Element) {
    return (hiddenByInlineStyle(this) ? [] : [{}]) as unknown as DOMRectList;
  });
});

const Layer = defineComponent({
  props: {
    active: { type: Boolean, default: true },
    busy: { type: Boolean, default: false },
    name: { type: String, default: "layer" },
    onDismiss: { type: Function as PropType<() => void>, default: undefined },
  },
  setup(props) {
    const root = ref<HTMLElement | null>(null);
    useFlareContextualLayer({
      active: () => props.active,
      root,
      dismissible: () => !props.busy,
      onDismiss: () => props.onDismiss?.(),
    });
    return () => h("div", { ref: root, class: `layer layer-${props.name}` }, [h("button", { type: "button", class: `key-${props.name}` }, "key")]);
  },
});

let host: ReturnType<typeof mount> | undefined;
let handlers: Array<() => boolean>;

function mountWith(render: () => unknown, nativeBack = true) {
  handlers = [];
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
      return render;
    },
  }), { attachTo: document.body });
  return host;
}

function escape(target: EventTarget = window, init: KeyboardEventInit = {}): KeyboardEvent {
  const event = new KeyboardEvent("keydown", { key: "Escape", bubbles: true, cancelable: true, ...init });
  target.dispatchEvent(event);
  return event;
}

afterEach(() => {
  host?.unmount();
  host = undefined;
  document.body.innerHTML = "";
});

describe("useFlareContextualLayer — Escape", () => {
  it("exits on Escape and consumes the key", () => {
    const dismissed = vi.fn();
    mountWith(() => h(Layer as Component, { onDismiss: dismissed }));
    const event = escape();
    expect(dismissed).toHaveBeenCalledTimes(1);
    expect(event.defaultPrevented).toBe(true);
  });

  it("leaves other keys and an IME composition alone", () => {
    const dismissed = vi.fn();
    mountWith(() => h(Layer as Component, { onDismiss: dismissed }));
    expect(escape(window, { key: "Enter" }).defaultPrevented).toBe(false);
    expect(escape(window, { isComposing: true }).defaultPrevented).toBe(false);
    expect(dismissed).not.toHaveBeenCalled();
  });

  it("swallows Escape while busy: consumed, nothing exits", () => {
    const dismissed = vi.fn();
    mountWith(() => h(Layer as Component, { busy: true, onDismiss: dismissed }));
    expect(escape().defaultPrevented).toBe(true);
    expect(dismissed).not.toHaveBeenCalled();
  });

  it("is not active without a listener: nothing consumed, no back claimed", () => {
    mountWith(() => h(Layer as Component, { active: false }));
    expect(escape().defaultPrevented).toBe(false);
    expect(handlers).toHaveLength(0);
  });

  it("gives way to a kit modal surface on top, and answers again once it closes", async () => {
    const dismissed = vi.fn();
    const state = reactive({ sheetOpen: true });
    mountWith(() => [
      h(Layer as Component, { onDismiss: dismissed }),
      h(FlareBottomSheet as Component, { open: state.sheetOpen, onClose: () => { state.sheetOpen = false; } }, { default: () => h("button", "Mute") }),
    ]);
    await nextTick();
    escape();
    expect(dismissed).not.toHaveBeenCalled();
    state.sheetOpen = false;
    await nextTick();
    escape();
    expect(dismissed).toHaveBeenCalledTimes(1);
  });

  it("gives way to a visible foreign aria-modal dialog, but not to one kept hidden in the DOM", () => {
    const dismissed = vi.fn();
    mountWith(() => h(Layer as Component, { onDismiss: dismissed }));
    const dialog = document.createElement("div");
    dialog.setAttribute("role", "dialog");
    dialog.setAttribute("aria-modal", "true");
    document.body.append(dialog);
    escape();
    expect(dismissed).not.toHaveBeenCalled();
    dialog.style.display = "none";
    escape();
    expect(dismissed).toHaveBeenCalledTimes(1);
  });

  it("leaves Escape to an editable control, but not to a select checkbox", () => {
    const dismissed = vi.fn();
    mountWith(() => [
      h(Layer as Component, { onDismiss: dismissed }),
      h("textarea", { class: "draft" }),
      h("input", { type: "checkbox", class: "tick" }),
      h("button", { type: "button", role: "checkbox", class: "select" }, "select"),
    ]);
    expect(escape(document.querySelector(".draft")!).defaultPrevented).toBe(false);
    expect(dismissed).not.toHaveBeenCalled();
    escape(document.querySelector(".select")!);
    expect(dismissed).toHaveBeenCalledTimes(1);
    escape(document.querySelector(".tick")!);
    expect(dismissed).toHaveBeenCalledTimes(2);
  });

  it("leaves Escape to a page that does not contain the layer", () => {
    const dismissed = vi.fn();
    mountWith(() => [
      h("section", { class: "flare-screen chat" }, [h(Layer as Component, { onDismiss: dismissed })]),
      h("section", { class: "flare-screen search" }, [h("button", { type: "button", class: "result" }, "result")]),
    ]);
    expect(escape(document.querySelector(".result")!).defaultPrevented).toBe(false);
    expect(dismissed).not.toHaveBeenCalled();
    // 同一页里的别的控件(页头的按钮)不是外页。
    escape(document.querySelector(".key-layer")!);
    expect(dismissed).toHaveBeenCalledTimes(1);
  });

  it("only the topmost visible layer answers; a hidden one is skipped", async () => {
    const first = vi.fn();
    const second = vi.fn();
    const state = reactive({ secondActive: true });
    mountWith(() => [
      h(Layer as Component, { name: "a", onDismiss: first }),
      h(Layer as Component, { name: "b", active: state.secondActive, onDismiss: second }),
    ]);
    escape();
    expect(second).toHaveBeenCalledTimes(1);
    expect(first).not.toHaveBeenCalled();
    // 上面那层藏起来(v-show):跳过它,下面那层接。
    document.querySelector<HTMLElement>(".layer-b")!.style.display = "none";
    escape();
    expect(first).toHaveBeenCalledTimes(1);
    document.querySelector<HTMLElement>(".layer-b")!.style.display = "";
    state.secondActive = false;
    await nextTick();
    escape();
    expect(first).toHaveBeenCalledTimes(2);
    expect(second).toHaveBeenCalledTimes(1);
  });

  it("listens on window, so a document listener that consumes the key wins regardless of registration order", () => {
    const dismissed = vi.fn();
    mountWith(() => h(Layer as Component, { onDismiss: dismissed }));
    // 一个不在 kit 栈里、也没有 aria-modal 的第三方层,注册得比本层晚,只 preventDefault。
    const foreign = (event: KeyboardEvent) => { if (event.key === "Escape") event.preventDefault(); };
    document.addEventListener("keydown", foreign);
    try {
      escape(document.body);
      expect(dismissed).not.toHaveBeenCalled();
    } finally {
      document.removeEventListener("keydown", foreign);
    }
    escape(document.body);
    expect(dismissed).toHaveBeenCalledTimes(1);
  });

  it("gives focus back to the control that had it before the layer went away with it", async () => {
    const state = reactive({ active: false });
    mountWith(() => [
      h("button", { type: "button", class: "opener" }, "more"),
      h(Layer as Component, { active: state.active }),
    ]);
    document.querySelector<HTMLElement>(".opener")!.focus();
    state.active = true;
    await nextTick();
    document.querySelector<HTMLElement>(".key-layer")!.focus();
    expect(document.activeElement?.className).toBe("key-layer");
    state.active = false;
    await nextTick();
    expect(document.activeElement?.className).toBe("opener");
  });
});

describe("useFlareContextualLayer — the platform back", () => {
  it("claims back while active; consumes it, busy consumes without exiting, hidden declines", async () => {
    const dismissed = vi.fn();
    const state = reactive({ busy: false });
    mountWith(() => h(Layer as Component, { busy: state.busy, onDismiss: dismissed }));
    expect(handlers).toHaveLength(1);
    expect(handlers[0]()).toBe(true);
    expect(dismissed).toHaveBeenCalledTimes(1);
    state.busy = true;
    await nextTick();
    expect(handlers[0]()).toBe(true);
    expect(dismissed).toHaveBeenCalledTimes(1);
    document.querySelector<HTMLElement>(".layer")!.style.display = "none";
    expect(handlers[0]()).toBe(false);
  });

  it("claims nothing when the platform has no native back", () => {
    mountWith(() => h(Layer as Component), false);
    expect(handlers).toHaveLength(0);
  });
});

describe("dismissTopFlareContextualLayer", () => {
  it("closes only a layer inside `within`, and reports a busy layer as consumed", async () => {
    const dismissed = vi.fn();
    const state = reactive({ busy: false });
    mountWith(() => [
      h("section", { class: "pane-a" }, [h("button", { type: "button" }, "a")]),
      h("section", { class: "pane-b" }, [h(Layer as Component, { busy: state.busy, onDismiss: dismissed })]),
    ]);
    expect(dismissTopFlareContextualLayer(document.querySelector(".pane-a"))).toBe(false);
    expect(dismissed).not.toHaveBeenCalled();
    expect(dismissTopFlareContextualLayer(document.querySelector(".pane-b"))).toBe(true);
    expect(dismissed).toHaveBeenCalledTimes(1);
    state.busy = true;
    await nextTick();
    expect(dismissTopFlareContextualLayer()).toBe(true);
    expect(dismissed).toHaveBeenCalledTimes(1);
  });

  it("reports nothing to close when there is no layer", () => {
    mountWith(() => h("div"));
    expect(dismissTopFlareContextualLayer()).toBe(false);
  });
});
