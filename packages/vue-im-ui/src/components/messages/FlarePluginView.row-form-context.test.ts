// @vitest-environment happy-dom
import { mount, flushPromises } from "@vue/test-utils";
import { afterEach, expect, it } from "vitest";
import { h } from "vue";
import FlarePluginView from "./FlarePluginView.vue";
import FlarePluginForm from "../form/FlarePluginForm.vue";
import type { FlarePluginViewModel } from "../../shared/contracts/plugin-ui";

const hosts: ReturnType<typeof mount>[] = [];
afterEach(() => {
  hosts.splice(0).forEach((w) => w.unmount());
  document.body.innerHTML = "";
});
it("keeps the selected row and balance visible without adding context to the command", async () => {
  const action = { id: "adjust", label: "Adjust", form: ["amount"] };
  const input = { walletId: "wallet-a", expectedRevision: "2" };
  const createdAt = 1795061271232;
  const view: FlarePluginViewModel = {
    available: true,
    title: "Wallets",
    fields: [],
    actions: [],
    inputs: [{ id: "amount", kind: "text", label: "Amount" }],
    blocks: [
      {
        kind: "rows",
        source: "wallets",
        columns: [
          { label: "Wallet", format: "text" },
          { label: "Balance", format: "text" },
          { label: "Created", format: "time" },
        ],
        actions: [action],
        rows: [
          {
            key: "a",
            cells: [
              { text: "Primary" },
              {
                text: "12.34",
                format: {
                  kind: "money",
                  minor: "1234",
                  assetId: "cny",
                  scale: 2,
                },
              },
              { text: String(createdAt), timeMs: createdAt },
            ],
            actions: [{ id: "adjust", input }],
          },
        ],
      },
    ],
  };
  const wrapper = mount(FlarePluginView, {
    props: {
      view,
      embedded: true,
      formatTime: (ms) => (ms === createdAt ? "2026/11/19 12:07:51" : "Unexpected timestamp"),
    },
    attachTo: document.body,
    slots: {
      rows: ({ run, block }: any) =>
        h(
          "button",
          { onClick: () => run(action, block.rows[0], input) },
          "Open",
        ),
    },
  });
  hosts.push(wrapper);
  await wrapper.get("button").trigger("click");
  await flushPromises();
  const context = document.querySelector('[data-row-form-context="true"]')!;
  expect(context.textContent).toContain("Primary");
  expect(context.textContent).toContain("12.34");
  expect(context.textContent).toContain("2026/11/19 12:07:51");
  expect(context.textContent).not.toContain(String(createdAt));
  const updated = structuredClone(view);
  (updated.blocks![0] as any).rows[0].cells[1].text = "99.99";
  await wrapper.setProps({ view: updated });
  expect(context.textContent).toContain("12.34");
  expect(context.textContent).not.toContain("99.99");
  wrapper.findComponent(FlarePluginForm).vm.$emit("submit", { amount: "5" });
  expect(wrapper.emitted("action")?.[0]).toEqual([
    "adjust",
    { row: { key: "a", input }, formValues: { amount: "5" } },
  ]);
});
it("opens a row's form from the values the view resolved for that row", async () => {
  const action = { id: "setGroup", label: "设置", form: ["label", "amount"] };
  const input = { conversationId: "g2", expectedRevision: 4 };
  const view: FlarePluginViewModel = {
    available: true,
    title: "群签到",
    fields: [],
    actions: [],
    inputs: [
      { id: "label", kind: "text", label: "备注名" },
      { id: "amount", kind: "text", label: "每次奖励金额" },
    ],
    blocks: [
      {
        kind: "rows",
        source: "groups",
        columns: [{ label: "群", format: "text" }],
        actions: [action],
        rows: [
          {
            key: "g2",
            cells: [{ text: "验收 g2" }],
            actions: [{ id: "setGroup", input, values: { label: "验收 g2", amount: "50" } }],
          },
        ],
      },
    ],
  };
  const wrapper = mount(FlarePluginView, {
    props: { view, embedded: true },
    attachTo: document.body,
    slots: {
      rows: ({ run, block }: any) =>
        h("button", { onClick: () => run(action, block.rows[0], input) }, "Open"),
    },
  });
  hosts.push(wrapper);
  await wrapper.get("button").trigger("click");
  await flushPromises();
  const form = wrapper.findComponent(FlarePluginForm);
  expect(form.props("values")).toEqual({ label: "验收 g2", amount: "50" });
  form.vm.$emit("submit", { label: "验收 g2", amount: "50" });
  expect(wrapper.emitted("action")?.[0]).toEqual([
    "setGroup",
    { row: { key: "g2", input }, formValues: { label: "验收 g2", amount: "50" } },
  ]);
});

it("sends a page action's bound values as its input, with and without a form", async () => {
  const values = { missionId: "m1", baseRevision: null };
  const view: FlarePluginViewModel = {
    available: true,
    title: "任务",
    fields: [],
    inputs: [{ id: "name", kind: "text", label: "名称" }],
    actions: [
      { id: "basics", label: "基本信息", form: ["name"], values },
      { id: "publish", label: "发布", values },
      { id: "add", label: "新建" },
    ],
  };
  const wrapper = mount(FlarePluginView, { props: { view, embedded: true }, attachTo: document.body });
  hosts.push(wrapper);
  await wrapper.get('button[data-action-id="publish"]').trigger("click");
  await wrapper.get('button[data-action-id="add"]').trigger("click");
  await wrapper.get('button[data-action-id="basics"]').trigger("click");
  await flushPromises();
  wrapper.findComponent(FlarePluginForm).vm.$emit("submit", { name: "签到" });
  expect(wrapper.emitted("action")).toEqual([
    ["publish", { input: values }],
    ["add", {}],
    ["basics", { input: values, formValues: { name: "签到" } }],
  ]);
});

it("sends a page action's bound values from its inline form", async () => {
  const values = { missionId: "m1", baseRevision: null };
  const sent: unknown[] = [];
  const view: FlarePluginViewModel = {
    available: true,
    title: "任务",
    fields: [],
    inputs: [{ id: "name", kind: "text", label: "名称" }],
    actions: [{ id: "basics", label: "保存", form: ["name"], values }],
  };
  const wrapper = mount(FlarePluginView, {
    props: { view, embedded: true, inlineFormActionId: "basics", onAction: (...args: unknown[]) => sent.push(args) },
    attachTo: document.body,
  });
  hosts.push(wrapper);
  wrapper.getComponent(FlarePluginForm).vm.$emit("submit", { name: "签到" });
  await flushPromises();
  expect(sent).toEqual([["basics", { input: values, formValues: { name: "签到" } }]]);
});
