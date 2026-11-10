// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import PluginRowsBlock from "./PluginRowsBlock.vue";
import FlareDataTable from "../../data/FlareDataTable.vue";
import type { FlarePluginStrings } from "../../../shared/contracts/plugin-ui";

describe("complete admin row presentation", () => {
  it("labels the primary amount in a receipt without duplicating it among secondary values", () => {
    const host = mount(PluginRowsBlock, { props: {
      layout: "list", labelRows: true, busy: false, strings: {} as FlarePluginStrings,
      block: {kind: "rows", source: "receipt", columns: [{label: "分录金额", format: "text"}, {label: "资金桶", format: "text"}], actions: [], rows: [{key: "entry", actions: [], cells: [{text: "-100.00"}, {text: "可用资金"}]}]},
    } });
    expect(host.get('[data-row-primary-label]').text()).toBe("分录金额");
    expect(host.get('[data-row-primary]').text()).toBe("-100.00");
    expect(host.get('[data-row-details]').text()).toBe("资金桶可用资金");
    host.unmount();
  });
  it("keeps all columns untruncated and draws host identities instead of raw references", () => {
    const host = mount(PluginRowsBlock, {
      props: {
        busy: false,
        strings: {} as FlarePluginStrings,
        block: {
          kind: "rows",
          source: "test",
          columns: [
            { label: "编号", format: "text" },
            { label: "用户", format: "text" },
            { label: "模板", format: "text" },
          ],
          actions: [],
          rows: [
            {
              key: "r",
              actions: [],
              cells: [
                { text: "long-request-reference" },
                {
                  text: "",
                  user: { name: "Alice", account: "alice.complete" },
                },
                { text: "完整的钱包开户审核模板名称" },
              ],
            },
          ],
        },
      },
    });
    expect(
      host
        .findComponent(FlareDataTable)
        .props("columns")
        .every((c: { ellipsis?: boolean }) => c.ellipsis === false),
    ).toBe(true);
    expect(host.text()).toContain("alice.complete");
    expect(host.text()).toContain("完整的钱包开户审核模板名称");
    expect(host.findAll(".is-ellipsis")).toHaveLength(0);
    host.unmount();
  });
});
