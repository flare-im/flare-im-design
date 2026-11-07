// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { readFileSync } from "node:fs";
import { compileStyle, parse } from "@vue/compiler-sfc";
import { afterEach, describe, expect, it, vi } from "vitest";
import { h, nextTick, reactive } from "vue";
import { NForm, NFormItem, NInput, NDatePicker, NSelect } from "naive-ui";
import FlareAdminForm from "./FlareAdminForm.vue";
import FlareDrawer from "../general/FlareDrawer.vue";

const hosts: ReturnType<typeof mount>[] = [];
afterEach(() => {
  hosts.splice(0).forEach((host) => host.unmount());
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});
describe("FlareAdminForm", () => {
  it("wraps complete long feedback in structured native editors without truncating or changing the draft", () => {
    const feedback = JSON.stringify({ defaultValue: "a".repeat(900) });
    const host = mount(FlareAdminForm, {
      slots: {
        default: () =>
          h(NFormItem, { label: "Configuration", feedback }, () =>
            h(NInput, { value: "Unsaved JSON", type: "textarea" }),
          ),
      },
    });
    hosts.push(host);
    expect(host.get(".n-form-item-feedback").text()).toBe(feedback);
    expect(host.get("textarea").element.value).toBe("Unsaved JSON");
    // DOM simulators do not lay out text. The browser receipt checks scrollWidth;
    // compile the real scoped stylesheet here so the shared contract cannot drift.
    const source = readFileSync(
      "src/components/form/FlareAdminForm.vue",
      "utf8",
    );
    const css = compileStyle({
      source: parse(source).descriptor.styles[0].content,
      filename: "FlareAdminForm.vue",
      id: "data-v-form-feedback",
      scoped: true,
    });
    expect(css.errors).toEqual([]);
    expect(css.code).toMatch(
      /\.n-form-item-feedback-wrapper[^{]*,[^{]*\.n-form-item-feedback\s*\{[^}]*min-width: 0;[^}]*overflow-wrap: anywhere;/,
    );
    expect(css.code).not.toMatch(/text-overflow:\s*ellipsis/);
    expect(css.code).toMatch(
      /padding-block-end:\s*var\(--flare-size-spacing-sm\)/,
    );
  });
  for (const picker of [NDatePicker, NSelect]) {
    it(`keeps Escape inside the real ${picker.name} without closing the containing drawer`, async () => {
      const close = vi.fn(),
        write = vi.fn();
      const popup = reactive({ show: true });
      const host = mount(FlareDrawer, {
        attachTo: document.body,
        props: { open: true, title: "Editor", onClose: close },
        slots: {
          default: () =>
            h(FlareAdminForm, {}, () => [
              h(NFormItem, { label: "Native picker" }, () =>
                h(picker as typeof NSelect, {
                  show: popup.show,
                  "onUpdate:show": (show: boolean) => {
                    popup.show = show;
                  },
                  options: [{ label: "A", value: "a" }],
                  "onUpdate:value": write,
                }),
              ),
              h(NInput, { class: "ordinary-field", value: "Unsaved draft" }),
            ]),
        },
      });
      hosts.push(host);
      await nextTick();
      const surface = document.querySelector(
        '[data-flare-presentation="drawer"]',
      )!;
      const target = surface.querySelector(
        ".n-date-picker input, .n-select .n-base-selection-label",
      )!;
      target.dispatchEvent(
        new KeyboardEvent("keydown", {
          key: "Escape",
          bubbles: true,
          cancelable: true,
        }),
      );
      await nextTick();
      expect(close).not.toHaveBeenCalled();
      expect(write).not.toHaveBeenCalled();
      expect(popup.show).toBe(false);
      surface.querySelector(".ordinary-field input")!.dispatchEvent(
        new KeyboardEvent("keydown", {
          key: "Escape",
          bubbles: true,
          cancelable: true,
        }),
      );
      expect(close).toHaveBeenCalledOnce();
    });
  }
  it("preserves a teleported date panel's Escape instead of closing the underlying draft", async () => {
    const close = vi.fn(),
      write = vi.fn();
    const popup = reactive({ show: true });
    const host = mount(FlareDrawer, {
      attachTo: document.body,
      props: { open: true, title: "Dates", onClose: close },
      slots: {
        default: () =>
          h(FlareAdminForm, {}, () =>
            h(NDatePicker, {
              type: "datetime",
              show: popup.show,
              "onUpdate:show": (show: boolean) => {
                popup.show = show;
              },
              "onUpdate:value": write,
            }),
          ),
      },
    });
    hosts.push(host);
    await nextTick();
    await nextTick();
    const input = document.querySelector(".n-date-panel input");
    expect(input).not.toBeNull();
    (document.querySelector(".n-date-picker input") as HTMLElement).focus();
    (input as HTMLElement).focus();
    input!.dispatchEvent(
      new KeyboardEvent("keydown", {
        key: "Escape",
        bubbles: true,
        cancelable: true,
      }),
    );
    expect(close).not.toHaveBeenCalled();
    expect(write).not.toHaveBeenCalled();
    expect(popup.show).toBe(false);
  });
  it("uses the real Naive form and forwards native submit, disabled state, validation rules and feedback", async () => {
    const submit = vi.fn();
    const rules = { name: { required: true, message: "Required" } };
    const model = reactive({ name: "Draft" });
    const host = mount(FlareAdminForm, {
      attrs: { disabled: true, rules, model, onSubmit: submit },
      slots: {
        default: () =>
          h(
            NFormItem,
            { label: "Name", path: "name", feedback: "Keep this feedback" },
            () => h(NInput, { value: model.name }),
          ),
      },
    });
    hosts.push(host);
    expect(host.findComponent(NForm).props("disabled")).toBe(true);
    expect(host.findComponent(NForm).props("rules")).toEqual(rules);
    expect(host.text()).toContain("Keep this feedback");
    expect(host.get("input").attributes("disabled")).toBeDefined();
    await host.trigger("submit");
    expect(submit).toHaveBeenCalledOnce(); // The host's original submission guard still owns writes.
    expect(model.name).toBe("Draft");
    await host.setProps({ disabled: false });
    expect(host.findComponent(NForm).props("disabled")).toBe(false);
  });
  it("switches labels by actual container width without remounting fields or dropping a draft", async () => {
    let width = 720,
      resize = () => {};
    const disconnect = vi.fn();
    vi.stubGlobal(
      "ResizeObserver",
      class {
        constructor(callback: () => void) {
          resize = callback;
        }
        observe() {}
        disconnect = disconnect;
      },
    );
    vi.spyOn(HTMLElement.prototype, "clientWidth", "get").mockImplementation(
      () => width,
    );
    // A transitioning modal can remain visually scaled without changing layout.
    vi.spyOn(HTMLElement.prototype, "getBoundingClientRect").mockImplementation(
      () => new DOMRect(0, 0, 400, 700),
    );
    const host = mount(FlareAdminForm, {
      slots: {
        default: () =>
          h(NFormItem, { label: "Name" }, () =>
            h(NInput, { defaultValue: "Unsaved draft" }),
          ),
      },
    });
    hosts.push(host);
    await nextTick();
    const input = host.get("input").element;
    expect(host.findComponent(NForm).props("labelPlacement")).toBe("left");
    expect(host.findComponent(NForm).props("labelWidth")).toBe(128);
    width = 390;
    resize();
    await nextTick();
    expect(host.findComponent(NForm).props("labelPlacement")).toBe("top");
    expect(host.get("input").element).toBe(input);
    expect(input.value).toBe("Unsaved draft");
    host.unmount();
    hosts.pop();
    expect(disconnect).toHaveBeenCalledOnce();
  });
  it("keeps explicit top labels for quota grids and long structured editors", () => {
    const host = mount(FlareAdminForm, {
      props: { labelPlacement: "top" },
      attrs: { id: "form-id", "aria-label": "Plan" },
    });
    hosts.push(host);
    expect(host.findComponent(NForm).props("labelPlacement")).toBe("top");
    expect(host.findComponent(NForm).props("size")).toBe("small");
    expect(host.get("form").attributes("id")).toBe("form-id");
    expect(host.get("form").attributes("aria-label")).toBe("Plan");
    expect(host.find("button").exists()).toBe(false);
  });
});
