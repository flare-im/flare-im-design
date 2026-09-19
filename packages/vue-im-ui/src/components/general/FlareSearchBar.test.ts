// @vitest-environment happy-dom
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { mount } from "@vue/test-utils";
import FlareSearchBar from "./FlareSearchBar.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";

// FR-098: every app wrote the same 300 ms timer around this bar, and none of them offered a way out
// of search. The bar owns both now: it searches once the typing settles, and cancels what is pending.

const wrappers: ReturnType<typeof mount>[] = [];

function setup(props: Record<string, unknown> = {}, listeners: Record<string, unknown> = {}) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareSearchBar as Component, { ...props, ...listeners });
    },
  }), { attachTo: document.body });
  wrappers.push(host);
  return host.findComponent(FlareSearchBar);
}

beforeEach(() => vi.useFakeTimers());
afterEach(() => {
  vi.useRealTimers();
  wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
  document.body.innerHTML = "";
});

describe("FlareSearchBar", () => {
  it("searches once the typing settles, not once per keystroke", async () => {
    const search = vi.fn();
    const bar = setup({ modelValue: "" }, { onSearch: search });
    const field = bar.get("input");

    for (const value of ["宇", "宇宙", "宇宙飞"]) {
      (field.element as HTMLInputElement).value = value;
      await field.trigger("input");
      vi.advanceTimersByTime(100);
    }
    expect(search).not.toHaveBeenCalled();

    vi.advanceTimersByTime(300);
    expect(search.mock.calls).toEqual([["宇宙飞"]]);
  });

  it("Return means now, and clearing searches for nothing", async () => {
    const search = vi.fn();
    const bar = setup({ modelValue: "宇宙" }, { onSearch: search });
    await bar.get("input").trigger("keydown.enter");
    expect(search.mock.calls).toEqual([["宇宙"]]);
    expect(bar.emitted("submit")).toHaveLength(1);

    await bar.get(".flare-search__clear").trigger("click");
    vi.advanceTimersByTime(300);
    // The clear searched once for nothing, and left nothing pending.
    expect(search.mock.calls).toEqual([["宇宙"], [""]]);
  });

  it("drops what is pending when it goes away", async () => {
    const search = vi.fn();
    const bar = setup({ modelValue: "" }, { onSearch: search });
    const field = bar.get("input");
    (field.element as HTMLInputElement).value = "宇宙";
    await field.trigger("input");
    expect(vi.getTimerCount()).toBe(1);

    wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
    // A closed search leaves no timer to wake up.
    expect(vi.getTimerCount()).toBe(0);
    vi.advanceTimersByTime(1000);
    expect(search).not.toHaveBeenCalled();
  });

  it("offers a way out of search only where leaving means something", async () => {
    expect(setup({ modelValue: "宇宙" }).find(".flare-search__cancel").exists()).toBe(false);
    const cancel = vi.fn();
    const bar = setup({ modelValue: "宇宙" }, { onCancel: cancel });
    await bar.get(".flare-search__cancel").trigger("click");
    expect(cancel).toHaveBeenCalledTimes(1);
  });

  it("stays a plain field for a host that does not search", async () => {
    const bar = setup({ modelValue: "" });
    const field = bar.get("input");
    (field.element as HTMLInputElement).value = "宇宙";
    await field.trigger("input");
    vi.advanceTimersByTime(1000);
    expect(bar.emitted("search")).toBeUndefined();
    expect(bar.emitted("update:modelValue")).toEqual([["宇宙"]]);
  });
});
