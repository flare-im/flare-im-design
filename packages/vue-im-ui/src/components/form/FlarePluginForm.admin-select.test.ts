// @vitest-environment happy-dom
import { mount, flushPromises } from "@vue/test-utils";
import { afterEach, expect, it } from "vitest";
import { h } from "vue";
import FlarePluginForm from "./FlarePluginForm.vue";
import FlareSelect from "./FlareSelect.vue";
import FlarePluginView from "../messages/FlarePluginView.vue";
import type { FlarePluginInput, FlarePluginViewModel } from "../../shared/contracts/plugin-ui";

const hosts: ReturnType<typeof mount>[] = [];
afterEach(() => {
  hosts.splice(0).forEach((host) => host.unmount());
  document.body.innerHTML = "";
});
const mode: FlarePluginInput = {
  id: "mode", kind: "select", label: "调整方式", required: true, default: "increase",
  choices: [
    { value: "increase", label: "增加金额" },
    { value: "decrease", label: "减少金额" },
    { value: "target", label: "设定目标余额" },
  ],
};

it("admin dropdowns keep the default and submit the three original values with exact money text", async () => {
  const host = mount(FlarePluginForm, {
    props: {
      selectPresentation: "dropdown", inputs: [mode, { id: "amount", kind: "text", label: "金额", default: "0.00" }],
    },
    attachTo: document.body,
  });
  hosts.push(host);
  expect(host.find('[role="radio"]').exists()).toBe(false);
  const select = host.findComponent(FlareSelect);
  expect(select.props("modelValue")).toBe("increase");
  expect(select.props("menuPlacement")).toBe("inline");
  for (const choice of mode.choices!) {
    await host.get('button[aria-haspopup="listbox"]').trigger("click");
    expect(host.findAll('[role="option"]').map((o) => o.text())).toEqual(mode.choices!.map((o) => o.label));
    await host.findAll('[role="option"]').find((o) => o.text() === choice.label)!.trigger("click");
    await host.get("[data-form-submit]").trigger("click");
  }
  expect(host.emitted("submit")).toEqual([
    [{ mode: "increase", amount: "0.00" }],
    [{ mode: "decrease", amount: "0.00" }],
    [{ mode: "target", amount: "0.00" }],
  ]);
  await host.setProps({ busy: true });
  expect(select.props("disabled")).toBe(true);
  await host.get("[data-form-submit]").trigger("click");
  expect(host.emitted("submit")).toHaveLength(3);
});

it("dropdowns retain required and withdrawn-choice validation", async () => {
  const host = mount(FlarePluginForm, { props: { selectPresentation: "dropdown", inputs: [{ ...mode, default: undefined }] } });
  hosts.push(host);
  await host.get("[data-form-submit]").trigger("click");
  expect(host.emitted("submit")).toBeUndefined();
  const select = host.findComponent(FlareSelect);
  select.vm.$emit("update:modelValue", "decrease");
  await flushPromises();
  await host.setProps({ inputs: [{ ...mode, default: undefined, choices: mode.choices!.filter((c) => c.value !== "decrease") }] });
  await host.get("[data-form-submit]").trigger("click");
  expect(host.emitted("submit")).toBeUndefined();
});

it.each([
  { label: "ordinary table", rowsLayout: "table", actionsPlacement: "footer", dropdown: false },
  { label: "console toolbar", rowsLayout: "table", actionsPlacement: "rows", dropdown: true },
] as const)("$label row forms keep their host presentation and original action context", async ({ rowsLayout, actionsPlacement, dropdown }) => {
  const action = { id: "edit", label: "Edit", form: ["mode"] };
  const input = { walletId: "wallet-a", expectedRevision: "2" };
  const row = { key: "a", cells: [{ text: "Primary" }], actions: [{ id: "edit", input }] };
  const view: FlarePluginViewModel = {
    available: true, title: "Records", fields: [], actions: [], inputs: [mode],
    blocks: [{ kind: "rows", source: "wallets", columns: [{ label: "Wallet", format: "text" }], actions: [action], rows: [row] }],
  };
  const host = mount(FlarePluginView, {
    props: { view, rowsLayout, actionsPlacement, embedded: true }, attachTo: document.body,
    slots: { rows: ({ run }: any) => h("button", { onClick: () => run(action, row, input) }, "Open") },
  });
  hosts.push(host);
  await host.get("button").trigger("click");
  await flushPromises();
  const form = host.findComponent(FlarePluginForm);
  if (dropdown) {
    expect(form.findComponent(FlareSelect).exists()).toBe(true);
    expect(form.find('[role="radio"]').exists()).toBe(false);
  } else {
    expect(form.find('[role="radio"]').exists()).toBe(true);
    expect(form.findComponent(FlareSelect).exists()).toBe(false);
  }
  form.vm.$emit("submit", { mode: "target" });
  expect(host.emitted("action")?.[0]).toEqual(["edit", { row: { key: "a", input }, formValues: { mode: "target" } }]);
});
