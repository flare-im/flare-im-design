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
  it("keeps the pill by default and drops it only for the quiet appearance", () => {
    // 默认必须是药丸:全仓另外 7 处调用点(全局搜索、加好友、加群、发起聊天、群成员…)
    // 都是浮在内容之上的搜索,把默认翻成 quiet 会把它们一起抹平。
    expect(setup({ readOnly: true, placeholder: "搜索" }).get(".flare-search").classes()).not.toContain("is-quiet");
    expect(setup({ readOnly: true, placeholder: "搜索", appearance: "quiet" }).get(".flare-search").classes()).toContain("is-quiet");
    // 可输入形态也要跟着走,否则同一个外观在两种形态下不一致。
    expect(setup({ appearance: "quiet" }).get(".flare-search").classes()).toContain("is-quiet");
  });

  it("keeps the affordance in quiet: the magnifier and the placeholder text stay", () => {
    // 去掉的只有那块底色。没有放大镜和占位文字,一条不画边框的搜索就认不出来是搜索了。
    const quiet = setup({ readOnly: true, placeholder: "搜索", appearance: "quiet" });
    expect(quiet.find(".flare-search__ico").exists()).toBe(true);
    expect(quiet.get(".flare-search__text").text()).toBe("搜索");
  });
  // 拼音还没变成字的时候不是查询词:停顿 300ms 就会拿 "zhou" 去搜。model 仍然逐键跟随,
  // 搜索等到上屏(compositionend)才开始计时。
  it("never searches for an IME's half-typed text, and searches once the composition ends", async () => {
    const searched: string[] = [];
    const updates: string[] = [];
    const bar = setup({ modelValue: "" }, { onSearch: (q: string) => searched.push(q), "onUpdate:modelValue": (v: string) => updates.push(v) });
    const input = bar.get("input");
    const el = input.element as HTMLInputElement;
    el.value = "zhou";
    el.dispatchEvent(new InputEvent("input", { bubbles: true, isComposing: true }));
    vi.advanceTimersByTime(1000);
    expect(updates).toEqual(["zhou"]);
    expect(searched).toEqual([]);
    el.value = "周";
    el.dispatchEvent(new CompositionEvent("compositionend", { bubbles: true, data: "周" }));
    vi.advanceTimersByTime(299);
    expect(searched).toEqual([]);
    vi.advanceTimersByTime(1);
    expect(searched).toEqual(["周"]);
  });
  // Safari / Firefox 的顺序是 compositionend 在前、再补一个同样文字的 input:那是同一次上屏,不是第二次。
  // 防抖为 0 时最看得出来 —— 改前一次上屏搜两遍。
  it("searches once per committed composition whatever order the engine reports it in", () => {
    const searched: string[] = [];
    const bar = setup({ modelValue: "", debounce: 0 }, { onSearch: (q: string) => searched.push(q) });
    const el = bar.get("input").element as HTMLInputElement;
    el.value = "周";
    el.dispatchEvent(new CompositionEvent("compositionend", { bubbles: true, data: "周" }));
    el.dispatchEvent(new InputEvent("input", { bubbles: true, isComposing: false }));
    expect(searched).toEqual(["周"]);
    // 之后的输入照常搜索。
    el.value = "周屿";
    el.dispatchEvent(new InputEvent("input", { bubbles: true, isComposing: false }));
    expect(searched).toEqual(["周", "周屿"]);
  });

  it("can be told to take the caret back", () => {
    const bar = setup({ modelValue: "" });
    (bar.vm as unknown as { focus: () => void }).focus();
    expect(document.activeElement).toBe(bar.get("input").element);
  });
});
