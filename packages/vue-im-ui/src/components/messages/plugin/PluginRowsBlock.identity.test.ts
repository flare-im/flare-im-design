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
    expect(host.get('[data-row-primary]').text()).toBe("\u2212100.00");
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

describe("record rows (§5.8 of docs/plugin-experience.md)", () => {
  // §12.24: rows are records only by the block's icon; a signed first cell alone keeps the pageRows item.
  const signed = [
    { key: "in", actions: [], cells: [{ text: "+¥1.00" }, { text: "红包" }] },
    { key: "out", actions: [], cells: [{ text: "-¥5.00" }, { text: "转账" }] },
    { key: "task", actions: [], cells: [{ text: "写周报" }, { text: "" }] },
  ];
  const columns = [{ label: "金额", format: "text" as const }, { label: "业务", format: "text" as const }];
  it("keeps a signed amount without an icon a pageRows item: no circle, the R10 minus and income tone", () => {
    const host = mount(PluginRowsBlock, { props: {
      layout: "list", busy: false, strings: {} as FlarePluginStrings,
      block: { kind: "rows", source: "history", columns, actions: [], rows: signed },
    } });
    for (const key of ["in", "out", "task"]) {
      expect(host.find(`[data-row-key="${key}"] [data-row-icon]`).exists()).toBe(false);
      expect(host.get(`[data-row-key="${key}"]`).classes()).not.toContain("is-record");
    }
    // Core's "-¥5.00" is data; the row draws the minus sign (R10).
    expect(host.get('[data-row-key="out"] [data-row-primary]').text()).toBe("\u2212¥5.00");
    expect(host.get('[data-row-key="in"] [data-row-primary]').text()).toBe("+¥1.00");
    expect(host.get('[data-row-key="in"] [data-row-primary]').classes()).toContain("is-in");
    expect(host.get('[data-row-key="task"] [data-row-primary]').text()).toBe("写周报");
    host.unmount();
  });

  it("draws a block with an icon as records: an unknown icon falls back to the sign's glyph, the amount at the end", () => {
    const host = mount(PluginRowsBlock, { props: {
      layout: "list", busy: false, strings: {} as FlarePluginStrings,
      block: { kind: "rows", source: "history", columns, actions: [], rows: signed, icon: "not-a-kit-icon" },
    } });
    const icon = (key: string) => host.get(`[data-row-key="${key}"] [data-row-icon]`);
    expect(icon("in").classes()).toContain("is-in");
    expect(icon("out").classes()).toContain("is-out");
    expect(icon("in").attributes("data-icon")).toBe("arrow-down");
    expect(icon("out").attributes("data-icon")).toBe("send");
    expect(icon("task").attributes("data-icon")).toBe("refresh");
    expect(host.get('[data-row-key="out"]').classes()).toContain("is-record");
    expect(host.get('[data-row-key="out"] [data-row-title]').text()).toBe("转账");
    expect(host.get('[data-row-key="out"] .flare-plugin-rows__end [data-row-primary]').text()).toBe("\u2212¥5.00");
    expect(host.get('[data-row-key="in"] [data-row-value]').classes()).toContain("is-in");
    host.unmount();
  });

  it("draws no Tag for a completed (success) ledger status, but keeps other statuses and unsigned rows", () => {
    const host = mount(PluginRowsBlock, { props: {
      layout: "list", busy: false, strings: {} as FlarePluginStrings,
      block: { kind: "rows", source: "history", icon: "wallet", columns: [{ label: "金额", format: "text" }, { label: "业务", format: "text" }, { label: "状态", format: "text" }], actions: [], rows: [
        { key: "done", actions: [], cells: [{ text: "-¥5.00" }, { text: "转账" }, { text: "已完成", tone: "success" }] },
        { key: "pending", actions: [], cells: [{ text: "-¥2.00" }, { text: "提现" }, { text: "处理中", tone: "info" }] },
        { key: "opening", actions: [], cells: [{ text: "personal" }, { text: "开户" }, { text: "已通过", tone: "success" }] },
      ] },
    } });
    const tags = (key: string) => host.findAll(`[data-row-key="${key}"] [data-row-status]`).map((n) => n.text());
    expect(tags("done")).toEqual([]);
    expect(tags("pending")).toEqual(["处理中"]);
    expect(tags("opening")).toEqual(["已通过"]);
    // The status Tag sits under the amount, and the status is not part of the record's line.
    expect(host.find('[data-row-key="pending"] .flare-plugin-rows__end [data-row-status]').exists()).toBe(true);
    expect(host.get('[data-row-key="pending"] [data-row-title]').text()).toBe("提现");
    expect(host.find('[data-row-key="pending"] [data-row-line]').exists()).toBe(false);
    host.unmount();
  });
});
