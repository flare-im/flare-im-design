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
            ],
            actions: [{ id: "adjust", input }],
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
