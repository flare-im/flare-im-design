// @vitest-environment happy-dom
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, ref } from "vue";
import { FLARE_LOAD_MORE_ROOT_MARGIN, useFlareLoadMoreWhenVisible } from "./useFlareLoadMoreWhenVisible";

/** An IntersectionObserver the test drives: `show(true)` reports every observed target as intersecting. */
class FakeObserver {
  static all: FakeObserver[] = [];
  targets: Element[] = [];
  disconnected = false;
  constructor(public callback: IntersectionObserverCallback, public options: IntersectionObserverInit = {}) {
    FakeObserver.all.push(this);
  }
  observe(target: Element): void { this.targets.push(target); }
  unobserve(): void {}
  disconnect(): void { this.disconnected = true; }
  takeRecords(): IntersectionObserverEntry[] { return []; }
  show(intersecting: boolean): void {
    this.callback(this.targets.map((target) => ({ target, isIntersecting: intersecting }) as IntersectionObserverEntry), this as unknown as IntersectionObserver);
  }
}
const live = () => FakeObserver.all.filter((observer) => !observer.disconnected);

beforeEach(() => {
  FakeObserver.all = [];
  vi.stubGlobal("IntersectionObserver", FakeObserver);
});
afterEach(() => {
  vi.unstubAllGlobals();
  document.body.innerHTML = "";
});

function mountSentinel(onVisible: () => void, options: Parameters<typeof useFlareLoadMoreWhenVisible>[2] = {}, scroller = false) {
  return mount(defineComponent({
    setup() {
      const target = ref<HTMLElement | null>(null);
      useFlareLoadMoreWhenVisible(target, onVisible, options);
      return () => h("div", { class: "scroller", style: scroller ? "overflow-y: auto; height: 100px" : undefined }, [
        h("div", { class: "rows" }),
        h("div", { ref: target, class: "sentinel" }),
      ]);
    },
  }), { attachTo: document.body });
}

describe("useFlareLoadMoreWhenVisible", () => {
  it("asks for more when the target comes within 400px, and not when it leaves", async () => {
    const onVisible = vi.fn();
    const wrapper = mountSentinel(onVisible);
    await nextTick();
    expect(live()).toHaveLength(1);
    expect(live()[0].options.rootMargin).toBe(FLARE_LOAD_MORE_ROOT_MARGIN);
    expect(FLARE_LOAD_MORE_ROOT_MARGIN).toBe("400px");
    expect(live()[0].targets[0]).toBe(wrapper.get(".sentinel").element);
    live()[0].show(false);
    expect(onVisible).not.toHaveBeenCalled();
    live()[0].show(true);
    expect(onVisible).toHaveBeenCalledTimes(1);
    wrapper.unmount();
  });

  it("takes the host's margin and the nearest scrolling ancestor as the root", async () => {
    const wrapper = mountSentinel(() => {}, { rootMargin: "120px" }, true);
    await nextTick();
    expect(live()[0].options.rootMargin).toBe("120px");
    expect(live()[0].options.root).toBe(wrapper.get(".scroller").element);
    wrapper.unmount();
  });

  it("observes nothing while disabled, and observes afresh when enabled again", async () => {
    const onVisible = vi.fn();
    const enabled = ref(false);
    const wrapper = mountSentinel(onVisible, { enabled });
    await nextTick();
    expect(live()).toHaveLength(0);
    enabled.value = true;
    await nextTick();
    expect(live()).toHaveLength(1);
    live()[0].show(true);
    expect(onVisible).toHaveBeenCalledTimes(1);
    // A page is loading, then arrives: a target still within reach asks again.
    enabled.value = false;
    await nextTick();
    expect(live()).toHaveLength(0);
    enabled.value = true;
    await nextTick();
    live()[0].show(true);
    expect(onVisible).toHaveBeenCalledTimes(2);
    wrapper.unmount();
  });

  it("accepts a getter for enabled", async () => {
    const onVisible = vi.fn();
    const hasMore = ref(true);
    const wrapper = mountSentinel(onVisible, { enabled: () => hasMore.value });
    await nextTick();
    expect(live()).toHaveLength(1);
    hasMore.value = false;
    await nextTick();
    expect(live()).toHaveLength(0);
    wrapper.unmount();
  });

  it("disconnects when the component goes away", async () => {
    const wrapper = mountSentinel(() => {});
    await nextTick();
    const observer = live()[0];
    wrapper.unmount();
    expect(observer.disconnected).toBe(true);
  });

  it("does nothing without IntersectionObserver", async () => {
    vi.stubGlobal("IntersectionObserver", undefined);
    const onVisible = vi.fn();
    const wrapper = mountSentinel(onVisible);
    await nextTick();
    expect(FakeObserver.all).toHaveLength(0);
    expect(onVisible).not.toHaveBeenCalled();
    wrapper.unmount();
  });
});
