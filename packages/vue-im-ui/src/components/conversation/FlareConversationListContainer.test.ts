// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import type { FlarePointerKind } from "../../shared/platform/contract";
import FlareConversationListContainer from "./FlareConversationListContainer.vue";

// Pull to refresh on touch and a refresh key on pointer devices (the Flutter container's onRefresh, plus the key the
// web needs): `refresh` only while bound and only over rows; `refreshing` holds the indicator and blocks a second ask.
const mounted: Array<{ unmount(): void }> = [];
afterEach(() => { mounted.splice(0).forEach((wrapper) => wrapper.unmount()); document.body.innerHTML = ""; });

function mountContainer(props: Record<string, unknown>, options: { pointer?: FlarePointerKind; filters?: boolean } = {}) {
  const wrapper = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      useFlarePlatformProvider({ capabilities: { pointer: options.pointer ?? "fine" } });
      return () => h(FlareConversationListContainer as Component, props, {
        default: () => h("ul", { class: "rows" }, [h("li", "row")]),
        ...(options.filters ? { filters: () => h("div", { class: "tabs" }, "tabs") } : {}),
      });
    },
  }), { attachTo: document.body });
  mounted.push(wrapper);
  return wrapper;
}

function touch(target: Element, type: string, y: number): void {
  const point = { identifier: 1, target, clientX: 50, clientY: y };
  const event = new Event(type, { bubbles: true, cancelable: true });
  Object.defineProperty(event, "touches", { value: type === "touchend" || type === "touchcancel" ? [] : [point] });
  Object.defineProperty(event, "changedTouches", { value: [point] });
  target.dispatchEvent(event);
}

describe("FlareConversationListContainer refresh", () => {
  it("emits refresh after a pull past the threshold at the top of the rows", async () => {
    const refreshes: number[] = [];
    const wrapper = mountContainer({ onRefresh: () => refreshes.push(1) }, { pointer: "coarse" });
    const body = wrapper.get(".flare-list-container__body").element;
    touch(body, "touchstart", 100);
    touch(body, "touchmove", 180);
    await wrapper.vm.$nextTick();
    expect(wrapper.get("[data-list-pull]").text()).toBe("下拉刷新");
    touch(body, "touchmove", 240);
    await wrapper.vm.$nextTick();
    expect(wrapper.get("[data-list-pull]").text()).toBe("松开刷新");
    touch(body, "touchend", 240);
    await wrapper.vm.$nextTick();
    expect(refreshes).toHaveLength(1);
    expect(wrapper.find("[data-list-pull]").exists()).toBe(false);
  });

  it("does not refresh for a short pull, a cancelled touch or while a refresh runs", async () => {
    const refreshes: number[] = [];
    const short = mountContainer({ onRefresh: () => refreshes.push(1) }, { pointer: "coarse" });
    const body = short.get(".flare-list-container__body").element;
    touch(body, "touchstart", 100);
    touch(body, "touchmove", 140);
    touch(body, "touchend", 140);
    touch(body, "touchstart", 100);
    touch(body, "touchmove", 260);
    touch(body, "touchcancel", 260);

    const running = mountContainer({ refreshing: true, onRefresh: () => refreshes.push(2) }, { pointer: "coarse" });
    expect(running.get("[data-list-pull]").text()).toBe("正在刷新");
    expect(running.get(".flare-list-container__body").attributes("aria-busy")).toBe("true");
    const runningBody = running.get(".flare-list-container__body").element;
    touch(runningBody, "touchstart", 100);
    touch(runningBody, "touchmove", 260);
    touch(runningBody, "touchend", 260);
    expect(refreshes).toEqual([]);
  });

  it("takes no gesture and draws no key without a refresh listener, or over a state of its own", async () => {
    const plain = mountContainer({});
    expect(plain.find("[data-list-refresh]").exists()).toBe(false);
    const body = plain.get(".flare-list-container__body").element;
    touch(body, "touchstart", 100);
    touch(body, "touchmove", 260);
    await plain.vm.$nextTick();
    expect(plain.find("[data-list-pull]").exists()).toBe(false);

    const loading = mountContainer({ state: { status: "loading" }, onRefresh: () => {} });
    expect(loading.find("[data-list-refresh]").exists()).toBe(false);
  });

  it("gives pointer devices a refresh key: at the end of the filters row, else in a row of its own", async () => {
    const refreshes: number[] = [];
    const withFilters = mountContainer({ onRefresh: () => refreshes.push(1) }, { filters: true });
    const key = withFilters.get(".flare-list-container__filters [data-list-refresh]");
    expect(key.attributes("aria-label")).toBe("刷新");
    await key.trigger("click");
    expect(refreshes).toEqual([1]);
    expect(withFilters.find(".flare-list-container__refresh").exists()).toBe(false);

    const own = mountContainer({ onRefresh: () => refreshes.push(2) });
    expect(own.find(".flare-list-container__refresh [data-list-refresh]").exists()).toBe(true);

    const busy = mountContainer({ refreshing: true, onRefresh: () => refreshes.push(3) });
    expect(busy.get("[data-list-refresh]").attributes("disabled")).toBeDefined();

    const touchOnly = mountContainer({ onRefresh: () => {} }, { pointer: "coarse" });
    expect(touchOnly.find("[data-list-refresh]").exists()).toBe(false);
  });
});
