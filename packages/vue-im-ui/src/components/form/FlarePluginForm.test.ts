// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h, reactive } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type { FlarePluginFormError, FlarePluginInput } from "../../shared/contracts/plugin-ui";
import FlarePluginForm from "./FlarePluginForm.vue";
import FlareSelect from "./FlareSelect.vue";

enableAutoUnmount(afterEach);
afterEach(() => { document.body.innerHTML = ""; });

const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/plugin-view-vectors.json"), "utf8")) as {
  form: {
    inputs: FlarePluginInput[];
    initial: { options: { rows: number; canAdd: boolean; canRemove: boolean }; counters: Record<string, string> };
    cases: Array<{ name: string; values: Record<string, unknown>; clientErrors: FlarePluginFormError[]; submitted: Record<string, unknown> | null }>;
    hostErrors: Array<{ error: FlarePluginFormError; zh: string }>;
    shownPerInput: Record<string, string>;
  };
};
const { inputs } = vectors.form;
const members = [
  { userId: "u_alice01", name: "Alice" },
  { userId: "u_bob0002", name: "Bob" },
  { userId: "u_carol003", name: "Carol" },
];

function render(props: Record<string, unknown> = {}) {
  const state = reactive<Record<string, unknown>>({ inputs, members, ...props });
  const submits: Array<Record<string, unknown>> = [];
  let cancels = 0;
  const wrapper = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlarePluginForm as never, {
        ...state,
        onSubmit: (values: Record<string, unknown>) => submits.push(values),
        onCancel: () => { cancels += 1; },
      });
    },
  }), { attachTo: document.body });
  return { wrapper, state, submits, cancels: () => cancels };
}
const field = (wrapper: ReturnType<typeof render>["wrapper"], id: string) => wrapper.get(`[data-input-id="${id}"]`);
const errorOf = (wrapper: ReturnType<typeof render>["wrapper"], id: string) => {
  const node = wrapper.find(`[data-input-id="${id}"] .flare-form-field__error`);
  return node.exists() ? node.text() : null;
};

describe("FlarePluginForm (spec/plugin-view-vectors.json → form)", () => {
  it("compact filters preserve validation, typed values and the host-owned reset", async () => {
    const { wrapper, submits, cancels } = render({
      presentation: "filters", cancelLabel: "重置", submitLabel: "筛选",
      inputs: [
        { id: "status", kind: "select", label: "状态", choices: [{ value: "active", label: "进行中" }, { value: "ended", label: "已结束" }] },
        { id: "query", kind: "text", label: "查询", maxLength: 3 },
      ],
    });
    expect(wrapper.findAll("input[type=radio]")).toHaveLength(0);
    const select = wrapper.findComponent(FlareSelect);
    expect(select.props("options")[0]).toEqual({ value: "", label: "全部" });
    select.vm.$emit("update:modelValue", "active");
    await field(wrapper, "query").get("input").setValue("four");
    await wrapper.get("[data-form-submit]").trigger("click");
    expect(submits).toEqual([]);
    expect(errorOf(wrapper, "query")).toBe("超出长度");
    await field(wrapper, "query").get("input").setValue("abc");
    await wrapper.get("[data-form-submit]").trigger("click");
    expect(submits).toEqual([{ status: "active", query: "abc" }]);
    expect(wrapper.get("[data-form-cancel]").text()).toBe("重置");
    await wrapper.get("[data-form-cancel]").trigger("click");
    expect(cancels()).toBe(1);
  });

  it("compact filters keep native controls and submit/reset disabled during a request", async () => {
    const { wrapper, submits, cancels } = render({
      presentation: "filters", busy: true,
      inputs: [{ id: "status", kind: "select", label: "状态", choices: [{ value: "active", label: "进行中" }] }],
    });
    expect(wrapper.findComponent(FlareSelect).props("disabled")).toBe(true);
    await wrapper.get("[data-form-submit]").trigger("click");
    await wrapper.get("[data-form-cancel]").trigger("click");
    expect(submits).toEqual([]);
    expect(cancels()).toBe(0);
  });

  it("draws every input kind, with counters and the option rows' limits", () => {
    const { wrapper } = render();
    for (const input of inputs) expect(wrapper.find(`[data-input-id="${input.id}"]`).exists()).toBe(true);
    for (const [id, counter] of Object.entries(vectors.form.initial.counters)) expect(field(wrapper, id).get(".flare-form-field__hint").text()).toBe(counter);
    const options = field(wrapper, "options");
    expect(options.findAll("[data-option-row]")).toHaveLength(vectors.form.initial.options.rows);
    expect(options.get("[data-option-add]").attributes("disabled") === undefined).toBe(vectors.form.initial.options.canAdd);
    expect(options.findAll("[data-option-remove]").every((b) => b.attributes("disabled") !== undefined)).toBe(!vectors.form.initial.options.canRemove);
    expect(field(wrapper, "visibility").findAll("input[type=radio], [role=radio]").length).toBeGreaterThan(0);
  });

  it("shows nothing before an edit or a submit attempt, then every client issue", async () => {
    const { wrapper, submits } = render();
    for (const input of inputs) expect(errorOf(wrapper, input.id)).toBeNull();
    await wrapper.get("[data-form-submit]").trigger("click");
    expect(submits).toEqual([]);
    const empty = vectors.form.cases.find((c) => c.name === "empty")!;
    for (const input of inputs) {
      const issue = empty.clientErrors.find((e) => e.input === input.id);
      expect(errorOf(wrapper, input.id), input.id).toBe(issue ? "必填" : null);
    }
  });

  it("checks an input as soon as it is edited", async () => {
    const { wrapper } = render();
    await field(wrapper, "title").get("input").setValue("一二三四五六七八九十十一");
    expect(errorOf(wrapper, "title")).toBe("超出长度");
    expect(errorOf(wrapper, "deadline")).toBeNull();
    await field(wrapper, "title").get("input").setValue("团建");
    expect(errorOf(wrapper, "title")).toBeNull();
  });

  it.each(vectors.form.cases.filter((c) => c.submitted).map((c) => [c.name, c] as const))("submits the cleaned values: %s", async (_, v) => {
    const { wrapper, submits } = render({ values: v.values });
    await wrapper.get("[data-form-submit]").trigger("click");
    expect(submits).toEqual([v.submitted]);
  });

  it("shows the host's errors under their inputs until the input is edited", async () => {
    const { wrapper, state } = render({ values: vectors.form.cases.find((c) => c.name === "valid")!.values });
    state.errors = vectors.form.hostErrors.map((e) => e.error);
    await flushPromises();
    for (const [id, shown] of Object.entries(vectors.form.shownPerInput)) expect(errorOf(wrapper, id), id).toBe(shown);
    await field(wrapper, "title").get("input").setValue("新的标题");
    expect(errorOf(wrapper, "title")).toBeNull();
    expect(errorOf(wrapper, "limit")).toBe("超出范围");
  });

  it("adds and removes option rows inside their limits", async () => {
    const { wrapper, submits } = render();
    const options = () => field(wrapper, "options");
    for (let i = 0; i < 5; i += 1) await options().get("[data-option-add]").trigger("click");
    expect(options().findAll("[data-option-row]")).toHaveLength(5);
    expect(options().get("[data-option-add]").attributes("disabled")).toBeDefined();
    await options().findAll("[data-option-remove]")[0].trigger("click");
    expect(options().findAll("[data-option-row]")).toHaveLength(4);
    const rows = options().findAll("[data-option-row] input");
    await rows[0].setValue(" 爬山 ");
    await rows[2].setValue("桌游");
    await field(wrapper, "title").get("input").setValue("团建");
    void submits;
    expect(errorOf(wrapper, "options")).toBeNull();
  });

  it("picks members through the kit contact picker, one at a time when max is 1", async () => {
    const { wrapper } = render();
    await field(wrapper, "owner").get("[data-members-choose]").trigger("click");
    await flushPromises();
    const picker = document.body.querySelector(".flare-contact-picker") as HTMLElement;
    expect(picker).not.toBeNull();
    const row = [...picker.querySelectorAll("button, [role=option], li")].find((n) => n.textContent?.includes("Carol")) as HTMLElement;
    row.click();
    await flushPromises();
    expect(field(wrapper, "owner").get("[data-members-chosen]").text()).toBe("Carol");
  });

  it("locks while busy and reports cancel", async () => {
    const busy = render({ busy: true, error: "提交失败" });
    expect(busy.wrapper.get("[data-form-submit]").attributes("disabled")).toBeDefined();
    expect(busy.wrapper.get("[role=alert]").text()).toBe("提交失败");
    const idle = render({ submitLabel: "参与接龙" });
    expect(idle.wrapper.get("[data-form-submit]").text()).toBe("参与接龙");
    await idle.wrapper.get("[data-form-cancel]").trigger("click");
    expect(idle.cancels()).toBe(1);
  });
});
