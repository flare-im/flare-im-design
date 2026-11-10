// @vitest-environment happy-dom
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, nextTick, reactive, type VNode } from "vue";
import { NDatePicker, NForm, NFormItem, NSelect } from "naive-ui";
import FlareAdminList from "../data/FlareAdminList.vue";
import FlarePluginForm from "./FlarePluginForm.vue";
import FlareSelect from "./FlareSelect.vue";
import FlareAdminEntitySelect from "./FlareAdminEntitySelect.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type { FlarePluginInput } from "../../shared/contracts/plugin-ui";

enableAutoUnmount(afterEach);
afterEach(() => {
  document.body.innerHTML = "";
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});
type Layout = {
  fields: VNode[];
  submit: () => void;
  reset: () => void;
  invalid: boolean;
};
type FieldScope = {
  input: FlarePluginInput;
  value: unknown;
  setValue: (value: unknown) => void;
  disabled: boolean;
  error?: string;
  controlId: string;
  labelId: string;
  describedBy?: string;
};
function measuredFields() {
  vi.stubGlobal(
    "ResizeObserver",
    class {
      observe() {}
      disconnect() {}
    },
  );
  const original = HTMLElement.prototype.getBoundingClientRect;
  vi.spyOn(HTMLElement.prototype, "getBoundingClientRect").mockImplementation(
    function (this: HTMLElement) {
      if (
        this.classList.contains("flare-admin-list") ||
        this.classList.contains("flare-admin-list__fields")
      )
        return new DOMRect(0, 0, 800, 300);
      if (this.classList.contains("flare-admin-list__field")) {
        const index = Array.from(this.parentElement!.children).indexOf(this);
        return new DOMRect(
          (index % 2) * 300,
          Math.floor(index / 2) * 44,
          290,
          32,
        );
      }
      return original.call(this);
    },
  );
}
const inputs: FlarePluginInput[] = [
  { id: "query", kind: "text", label: "查询", maxLength: 3 },
  {
    id: "status",
    kind: "select",
    label: "状态",
    choices: [{ value: "active", label: "进行中" }],
  },
  {
    id: "count",
    kind: "number",
    label: "数量",
    min: 0,
    max: 10,
    required: true,
  },
  { id: "walletId", kind: "text", label: "钱包", required: true },
  { id: "amount", kind: "text", label: "金额" },
];
function setup(fieldSlots: Record<string, (scope: FieldScope) => VNode> = {}) {
  measuredFields();
  const state = reactive({
    values: {
      query: "",
      status: "",
      count: 2,
      walletId: "cash",
      amount: "900719925474099301",
    },
    errors: [] as Array<{ input: string; issue: string }>,
    busy: false,
    selections: {
      walletId: {
        options: [{ value: "cash", label: "余额钱包", disabled: false }],
        remote: false,
        loading: false,
      },
    },
  });
  const submitted: Record<string, unknown>[] = [];
  let resets = 0;
  let controls: Layout | undefined;
  const wrapper = mount(
    defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () =>
          h(
            FlarePluginForm as never,
            {
              inputs,
              presentation: "filters",
              ...state,
              onSubmit: (values: Record<string, unknown>) =>
                submitted.push(values),
              onCancel: () => {
                resets++;
              },
            },
            {
              ...fieldSlots,
              layout: (layout: Layout) => {
                controls = layout;
                return h(
                  FlareAdminList,
                  {
                    label: "配置",
                    columns: [{ key: "name", title: "名称" }],
                    rows: [],
                    rowKey: "id",
                    disabled: state.busy,
                    filtersInvalid: layout.invalid,
                    onSearch: layout.submit,
                    onReset: layout.reset,
                  },
                  {
                    filters: () =>
                      layout.fields.map((field) => h(field as never)),
                  },
                );
              },
            },
          );
      },
    }),
    { attachTo: document.body },
  );
  return {
    wrapper,
    state,
    submitted,
    resets: () => resets,
    controls: () => {
      expect(
        controls,
        "the layout slot receives the same form controller",
      ).toBeDefined();
      return controls!;
    },
  };
}
function field(wrapper: ReturnType<typeof setup>["wrapper"], id: string) {
  return wrapper.get(`[data-input-id="${id}"]`);
}

describe("FlarePluginForm layout slot / native query fields", () => {
  it("uses one teleported date-time control and submits its complete timestamp", async () => {
    const submitted: Record<string, unknown>[] = [];
    const wrapper = mount(FlarePluginForm, {
      props: {
        presentation: "filters",
        inputs: [{ id: "fromMs", kind: "datetime", label: "Created from" }],
        values: {},
        errors: [],
        busy: false,
        onSubmit: (v: Record<string, unknown>) => submitted.push(v),
      },
      slots: {
        layout: (layout: Layout) =>
          h(
            "div",
            layout.fields.map((field) => h(field as never)),
          ),
      },
    });
    const picker = wrapper.getComponent(NDatePicker);
    expect(picker.props("type")).toBe("datetime");
    picker.vm.$emit("update:value", 1794153600000);
    await nextTick();
    (wrapper.vm as unknown as { submit: () => void }).submit();
    expect(submitted).toEqual([{ fromMs: 1794153600000 }]);
  });
  it("renders one native field per declared input with real row folding and no nested form or duplicate footer", async () => {
    const { wrapper, controls } = setup();
    await nextTick();
    const list = wrapper.getComponent(FlareAdminList);
    expect(controls().fields).toHaveLength(5);
    expect(wrapper.findAllComponents(NForm)).toHaveLength(1);
    expect(wrapper.findAllComponents(NFormItem)).toHaveLength(5);
    expect(wrapper.findAll("form")).toHaveLength(1);
    expect(
      wrapper
        .find("form form, fieldset, [data-form-submit], [data-form-cancel]")
        .exists(),
    ).toBe(false);
    expect(list.findAll(".flare-admin-list__field")).toHaveLength(5);
    expect(list.findAll(".is-folded")).toHaveLength(3);
    const before = field(wrapper, "amount").get("input").element;
    await list.get(".flare-admin-list__expand").trigger("click");
    expect(list.findAll(".is-folded")).toHaveLength(0);
    expect(field(wrapper, "amount").get("input").element).toBe(before);
    expect((before as HTMLInputElement).value).toBe("900719925474099301");
  });

  it("uses typed validation and query reset restores controlled values before asking the host to reset", async () => {
    const h = setup();
    const controls = h.controls();
    await h.wrapper
      .getComponent(FlareAdminList)
      .get(".flare-admin-list__expand")
      .trigger("click");
    await field(h.wrapper, "query").get("input").setValue("four");
    controls.submit();
    await nextTick();
    expect(h.submitted).toEqual([]);
    expect(h.wrapper.text()).toContain("超出长度");
    await field(h.wrapper, "query").get("input").setValue("abc");
    const status = h.wrapper
      .findAllComponents(NSelect)
      .find((select) => select.attributes("aria-label") === "状态")!;
    expect(status.props("options")).toEqual([
      { value: "", label: "全部" },
      { value: "active", label: "进行中" },
    ]);
    expect(h.wrapper.findComponent(FlareSelect).exists()).toBe(false);
    status.vm.$emit("update:value", "active");
    await field(h.wrapper, "count").get("input").setValue("");
    controls.submit();
    expect(h.submitted).toEqual([]);
    await field(h.wrapper, "count").get("input").setValue("0");
    controls.submit();
    expect(h.submitted).toEqual([
      {
        query: "abc",
        status: "active",
        count: 0,
        walletId: "cash",
        amount: "900719925474099301",
      },
    ]);
    expect(h.wrapper.getComponent(FlareAdminEntitySelect).props("remote")).toBe(
      false,
    );
    controls.reset();
    await nextTick();
    expect(h.resets()).toBe(1);
    expect(
      (field(h.wrapper, "query").get("input").element as HTMLInputElement)
        .value,
    ).toBe("");
    expect(
      (field(h.wrapper, "count").get("input").element as HTMLInputElement)
        .value,
    ).toBe("2");
    await field(h.wrapper, "query").get("input").setValue("xyz");
    controls.reset();
    await nextTick();
    expect(h.resets()).toBe(2);
    expect(
      (field(h.wrapper, "query").get("input").element as HTMLInputElement)
        .value,
    ).toBe("");
    expect(h.state.values.query).toBe("");
    expect(h.submitted).toHaveLength(1);
    h.state.values = { ...h.state.values, query: "new" };
    await flushPromises();
    expect(
      (field(h.wrapper, "query").get("input").element as HTMLInputElement)
        .value,
    ).toBe("new");
  });

  it("keeps failed values and current reference guards while busy disables both controller operations", async () => {
    const h = setup();
    const controls = h.controls();
    await field(h.wrapper, "query").get("input").setValue("abc");
    h.state.errors = [{ input: "query", issue: "duplicateItem" }];
    await nextTick();
    expect(
      (field(h.wrapper, "query").get("input").element as HTMLInputElement)
        .value,
    ).toBe("abc");
    expect(h.wrapper.text()).toContain("不能重复");
    h.state.selections.walletId.options[0].disabled = true;
    await nextTick();
    controls.submit();
    expect(h.submitted).toEqual([]);
    expect(
      (field(h.wrapper, "amount").get("input").element as HTMLInputElement)
        .value,
    ).toBe("900719925474099301");
    h.state.selections.walletId.options[0].disabled = false;
    h.state.busy = true;
    await nextTick();
    controls.submit();
    controls.reset();
    expect(h.submitted).toEqual([]);
    expect(h.resets()).toBe(0);
    expect(
      field(h.wrapper, "query").get("input").attributes("disabled"),
    ).toBeDefined();
    expect(h.wrapper.find(".n-alert, .flare-status-banner").exists()).toBe(
      false,
    );
  });

  it("prefers a field-specific control while keeping native labels, required validation and guarded draft writes", async () => {
    let current: FieldScope | undefined;
    const customInput = (scope: FieldScope, marker: string) =>
      h("input", {
        id: scope.controlId,
        "aria-labelledby": scope.labelId,
        "aria-describedby": scope.describedBy,
        "data-custom-field": marker,
        value: String(scope.value ?? ""),
        disabled: scope.disabled,
        onInput: (event: Event) =>
          scope.setValue((event.target as HTMLInputElement).value),
      });
    const form = setup({
      field: (scope) => customInput(scope, "generic"),
      "field-walletId": (scope) => {
        current = scope;
        return customInput(scope, "wallet");
      },
    });
    await nextTick();
    const list = form.wrapper.getComponent(FlareAdminList);
    expect(form.wrapper.findAllComponents(NFormItem)).toHaveLength(5);
    expect(list.findAll(".flare-admin-list__field")).toHaveLength(5);
    expect(list.findAll(".is-folded")).toHaveLength(3);
    expect(form.wrapper.findAll('[data-custom-field="wallet"]')).toHaveLength(
      1,
    );
    expect(form.wrapper.findAll('[data-custom-field="generic"]')).toHaveLength(
      4,
    );
    expect(form.wrapper.findAll(".flare-admin-list__field input")).toHaveLength(
      5,
    );
    expect(form.wrapper.findComponent(FlareAdminEntitySelect).exists()).toBe(
      false,
    );
    expect(form.wrapper.findComponent(FlareSelect).exists()).toBe(false);
    await list.get(".flare-admin-list__expand").trigger("click");
    const input = form.wrapper.get('[data-custom-field="wallet"]');
    expect(input.element.closest(".n-form-item")).not.toBeNull();
    expect(current?.input.id).toBe("walletId");
    expect(current?.value).toBe("cash");
    expect(current?.controlId).toBeTruthy();
    expect(current?.labelId).toBeTruthy();
    expect(form.wrapper.get(`[id="${current!.labelId}"]`).text()).toContain(
      "钱包",
    );
    await input.setValue("");
    form.controls().submit();
    await nextTick();
    expect(form.submitted).toEqual([]);
    expect(current?.error).toBe("必填");
    expect(current?.describedBy).toBeTruthy();
    for (const id of current!.describedBy!.split(/\s+/))
      expect(form.wrapper.find(`[id="${id}"]`).exists()).toBe(true);
    expect(field(form.wrapper, "walletId").text()).toContain("必填");
    await input.setValue("cash");
    form.controls().submit();
    expect(form.submitted).toHaveLength(1);
    expect(form.submitted[0].walletId).toBe("cash");
    const earlierSetValue = current!.setValue;
    form.state.busy = true;
    await nextTick();
    expect(current?.disabled).toBe(true);
    expect(input.attributes("disabled")).toBeDefined();
    earlierSetValue("");
    await nextTick();
    expect(current?.value).toBe("cash");
    form.controls().submit();
    expect(form.submitted).toHaveLength(1);
    expect(form.wrapper.findAllComponents(NFormItem)).toHaveLength(5);
  });

  it("reveals an invalid advanced query field without remounting controls or hiding feedback in an inert row", async () => {
    const form = setup();
    await nextTick();
    const list = form.wrapper.getComponent(FlareAdminList);
    expect(list.findAll(".is-folded")).toHaveLength(3);
    const wallet = field(form.wrapper, "walletId").element;
    expect(wallet.closest(".is-folded")).not.toBeNull();
    const amount = field(form.wrapper, "amount").get("input").element;
    form.state.errors = [{ input: "walletId", issue: "required" }];
    await flushPromises();
    expect(form.controls().invalid).toBe(true);
    expect(list.props("filtersInvalid")).toBe(true);
    expect(
      list.get(".flare-admin-list__expand").attributes("aria-expanded"),
    ).toBe("true");
    expect(list.findAll(".is-folded")).toHaveLength(0);
    expect(field(form.wrapper, "walletId").element).toBe(wallet);
    expect(wallet.closest("[inert]")).toBeNull();
    expect(field(form.wrapper, "walletId").text()).toContain("必填");
    expect(field(form.wrapper, "amount").get("input").element).toBe(amount);
    expect((amount as HTMLInputElement).value).toBe("900719925474099301");
    expect(form.submitted).toEqual([]);
  });
});
