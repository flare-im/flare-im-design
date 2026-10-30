// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import PluginRowsBlock from "./PluginRowsBlock.vue";
import FlareDataTable from "../../data/FlareDataTable.vue";
import type { FlarePluginStrings } from "../../../shared/contracts/plugin-ui";

describe("complete admin row presentation", () => {
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
