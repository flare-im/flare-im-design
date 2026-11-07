// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, nextTick, ref, type Component } from "vue";
import { useFlareI18nProvider, type FlareLocale } from "../../shared/i18n/useFlareI18n";
import FlareFilterBar from "./FlareFilterBar.vue";
import FlareFormField from "../form/FlareFormField.vue";
import FlareInput from "./FlareInput.vue";

const wrappers: ReturnType<typeof mount>[] = [];
afterEach(() => {
  wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
  document.body.innerHTML = "";
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

function mountBar(props: Record<string, unknown> = {}, slots: Record<string, () => unknown> = {}, locale: FlareLocale = "zh-CN") {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareFilterBar as Component, props, {
        default: () => [
          h(FlareFormField as Component, { label: "会话" }, () => h(FlareInput as Component, { modelValue: "c_1" })),
          h(FlareFormField as Component, { label: "发送者" }, () => h(FlareInput as Component, { modelValue: "" })),
        ],
        ...slots,
      });
    },
  }), { attachTo: document.body });
  wrappers.push(host);
  return host.findComponent(FlareFilterBar);
}

const keys = (bar: ReturnType<typeof mountBar>) => bar.findAll(".flare-filter-bar__actions button").map((key) => key.text());
const enter = (target: Element, init: KeyboardEventInit = {}) => {
  const event = new KeyboardEvent("keydown", { key: "Enter", bubbles: true, cancelable: true, ...init });
  target.dispatchEvent(event);
  return event;
};

function mockRows(columns: () => number) {
  let resize: () => void = () => {};
  vi.stubGlobal('ResizeObserver', class { constructor(callback: () => void) { resize = callback; } observe() {} disconnect() {} });
  const original = HTMLElement.prototype.getBoundingClientRect;
  vi.spyOn(HTMLElement.prototype, 'getBoundingClientRect').mockImplementation(function (this: HTMLElement) {
    if (this.classList.contains('flare-filter-bar__overflow-fields')) return new DOMRect(0, 0, columns() * 216, 200);
    if (this.classList.contains('flare-filter-bar__cell')) {
      const index = Array.from(this.parentElement!.children).indexOf(this);
      return new DOMRect((index % columns()) * 216, Math.floor(index / columns()) * 68, 200, 52);
    }
    return original.call(this);
  });
  return () => resize();
}

describe('FlareFilterBar measured one-row mode', () => {
  it('folds only actual overflow, mounts each field once, and preserves values across toggle', async () => {
    const resize = mockRows(() => 2);
    const bar = mountBar({ collapseOverflow: true, size: 'sm' }, {
      more: () => h(FlareFormField as Component, { label: '账号' }, () => h(FlareInput as Component, { modelValue: 'alice' })),
    });
    await nextTick();
    resize(); await nextTick();
    expect(bar.findAll('input')).toHaveLength(3);
    const cells = bar.findAll('.flare-filter-bar__cell');
    expect(cells.filter(cell => cell.classes().includes('is-folded'))).toHaveLength(1);
    expect(cells[2].attributes('aria-hidden')).toBe('true');
    expect(cells[2].attributes('inert')).toBeDefined();
    expect(bar.get('.flare-filter-bar__viewport').attributes('style')).toContain('52px');
    await bar.get('.flare-filter-bar__toggle').trigger('click');
    expect(bar.find('.is-folded').exists()).toBe(false);
    expect(bar.get('.flare-filter-bar__toggle').attributes('aria-expanded')).toBe('true');
    await bar.get('.flare-filter-bar__toggle').trigger('click');
    expect((bar.findAll('input')[2].element as HTMLInputElement).value).toBe('alice');
  });

  it('hides the expand affordance when all fields fit and responds to real resize observations', async () => {
    let columns = 4;
    const resize = mockRows(() => columns);
    const bar = mountBar({ collapseOverflow: true });
    await nextTick();
    expect(bar.get('.flare-filter-bar__toggle').classes()).toContain('is-unneeded');
    expect(bar.get('.flare-filter-bar__toggle').attributes('aria-hidden')).toBe('true');
    columns = 1; resize(); await nextTick();
    expect(bar.get('.flare-filter-bar__toggle').classes()).not.toContain('is-unneeded');
    expect(bar.findAll('.is-folded')).toHaveLength(1);
    columns = 4; resize(); await nextTick();
    expect(bar.get('.flare-filter-bar__toggle').classes()).toContain('is-unneeded');
    expect(bar.find('.is-folded').exists()).toBe(false);
  });

  it('keeps keyboard focus visible if a narrower container would fold its field', async () => {
    let columns = 4;
    const resize = mockRows(() => columns);
    const bar = mountBar({ collapseOverflow: true });
    await nextTick();
    const input = bar.findAll('input')[1].element as HTMLInputElement;
    input.focus();
    columns = 1; resize(); await nextTick();
    expect(document.activeElement).toBe(input);
    expect(bar.get('.flare-filter-bar__toggle').attributes('aria-expanded')).toBe('true');
    expect(bar.find('.is-folded').exists()).toBe(false);
  });

  it('blocks search and reset while the host write scope is locked', async () => {
    mockRows(() => 1);
    const bar = mountBar({ collapseOverflow: true, disabled: true });
    await nextTick();
    enter(bar.get('input').element);
    await bar.get('.flare-filter-bar__search').trigger('click');
    await bar.get('.flare-filter-bar__reset').trigger('click');
    expect(bar.emitted('search')).toBeUndefined();
    expect(bar.emitted('reset')).toBeUndefined();
  });
});

describe("FlareFilterBar", () => {
  it("is a named search landmark with the fields, then Search and Reset", () => {
    const bar = mountBar({ hint: "至少填写会话、发送者或消息 ID 之一" });
    expect(bar.attributes("role")).toBe("search");
    expect(bar.attributes("aria-label")).toBe("查询条件");
    expect(bar.get(`#${bar.attributes("aria-describedby")}`).text()).toBe("至少填写会话、发送者或消息 ID 之一");
    expect(bar.findAll(".flare-form-field")).toHaveLength(2);
    expect(keys(bar)).toEqual(["查询", "重置"]);
    // Not a form: a host button in `actions` must never submit anything by accident.
    expect(bar.find("form").exists()).toBe(false);
    expect(mountBar({}, {}, "en-US").attributes("aria-label")).toBe("Filters");
  });

  it("says when: Search and Reset are the host's to run", async () => {
    const bar = mountBar({ label: "消息检索", searchText: "检索", resettable: true });
    expect(bar.attributes("aria-label")).toBe("消息检索");
    await bar.get(".flare-filter-bar__search").trigger("click");
    await bar.get(".flare-filter-bar__reset").trigger("click");
    expect(bar.emitted("search")).toHaveLength(1);
    expect(bar.emitted("reset")).toHaveLength(1);
    expect(mountBar({ resettable: false }).find(".flare-filter-bar__reset").exists()).toBe(false);
  });

  it("searches on Enter in a one-line field, and only there", () => {
    const bar = mountBar({}, { actions: () => h("button", { type: "button", class: "host-key" }, "导出") });
    const input = bar.get("input").element;
    const event = enter(input);
    expect(event.defaultPrevented).toBe(true);
    expect(bar.emitted("search")).toHaveLength(1);

    // A button keeps its Enter (it activates the button), and so does the host's own key.
    enter(bar.get(".host-key").element);
    enter(bar.get(".flare-filter-bar__reset").element);
    expect(bar.emitted("search")).toHaveLength(1);
  });

  it("leaves Enter to a control that acts on it: a handled key, an open combobox, a composition, a textarea", () => {
    const bar = mountBar({}, {
      more: () => h(FlareFormField as Component, { label: "备注" }, () => h("textarea", { class: "note" })),
    });
    const input = bar.get("input").element as HTMLInputElement;
    // A control upstream that already handled the key.
    input.addEventListener("keydown", (event) => event.preventDefault(), { once: true });
    enter(input);
    // An open combobox picks with Enter.
    input.setAttribute("aria-expanded", "true");
    enter(input);
    input.removeAttribute("aria-expanded");
    // An IME commit, and a modified Enter.
    enter(input, { isComposing: true });
    enter(input, { shiftKey: true });
    expect(bar.emitted("search")).toBeUndefined();
  });

  it("waits while the host runs a query: the key shows progress, Enter does not queue a second one", () => {
    const bar = mountBar({ loading: true });
    const key = bar.get(".flare-filter-bar__search");
    expect(key.attributes("aria-busy")).toBe("true");
    expect(key.attributes("disabled")).toBeDefined();
    enter(bar.get("input").element);
    expect(bar.emitted("search")).toBeUndefined();
  });

  it("folds the less used fields behind a disclosure that says how many hold a value", async () => {
    const expanded = ref(false);
    const host = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () => h(FlareFilterBar as Component, {
          expanded: expanded.value,
          "onUpdate:expanded": (value: boolean) => (expanded.value = value),
          moreActiveCount: 2,
        }, {
          default: () => h(FlareFormField as Component, { label: "会话" }, () => h(FlareInput as Component, { modelValue: "" })),
          more: () => [
            h(FlareFormField as Component, { label: "消息类型" }, () => h(FlareInput as Component, { modelValue: "1" })),
            h(FlareFormField as Component, { label: "频道" }, () => h(FlareInput as Component, { modelValue: "ch" })),
          ],
        });
      },
    }), { attachTo: document.body });
    wrappers.push(host);
    const toggle = () => host.get(".flare-filter-bar__toggle");
    expect(host.findAll(".flare-form-field")).toHaveLength(1);
    expect(toggle().text()).toBe("更多条件（2）");
    expect(toggle().attributes("aria-expanded")).toBe("false");
    expect(toggle().attributes("aria-controls")).toBeUndefined();

    await toggle().trigger("click");
    await nextTick();
    expect(expanded.value).toBe(true);
    expect(host.findAll(".flare-form-field")).toHaveLength(3);
    expect(toggle().text()).toBe("收起条件");
    expect(toggle().attributes("aria-expanded")).toBe("true");
    const region = host.get(`#${toggle().attributes("aria-controls")}`);
    expect(region.findAll(".flare-form-field")).toHaveLength(2);

    await toggle().trigger("click");
    await nextTick();
    expect(expanded.value).toBe(false);
    expect(host.findAll(".flare-form-field")).toHaveLength(1);
  });

  it("draws no disclosure without folded fields, and a plain one when none of them hold a value", () => {
    expect(mountBar().find(".flare-filter-bar__toggle").exists()).toBe(false);
    const bar = mountBar({}, { more: () => h("span", "x") });
    expect(bar.get(".flare-filter-bar__toggle").text()).toBe("更多条件");
  });

  it("puts the keys at the end of the last row: two cells on a grid of columns, the whole row on one column", async () => {
    const bar = mountBar();
    const actions = bar.get(".flare-filter-bar__actions");
    // happy-dom lays nothing out, so the grid reads as one column.
    expect(actions.attributes("style")).toContain("grid-column: 1 / -1");
  });
});
