import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { flarePluginAfterReturn, flarePluginDoneTarget, flarePluginMayRefresh, flarePluginPageKind, type FlarePluginPageKind, type FlarePluginReturnEvent } from "./plugin-refresh";
import type { FlarePluginViewModel } from "./plugin-ui";
const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/plugin-refresh-vectors.json"), "utf8"));
describe('plugin refresh vectors', () => { for (const vector of table.pluginRefresh) it(vector.name, () => { expect(flarePluginMayRefresh(vector)).toBe(vector.expect); }); });

describe("afterReturn vectors (R4)", () => {
  for (const vector of table.afterReturn as Array<{ name: string; event: FlarePluginReturnEvent; origin?: boolean; expect: { refresh: boolean; reason?: string; page: string } }>)
    it(vector.name, () => { expect(flarePluginAfterReturn(vector.event, vector.origin ?? false)).toEqual(vector.expect); });
});

describe("doneTarget vectors (§12.1)", () => {
  for (const vector of table.doneTarget as Array<{ name: string; stack: FlarePluginPageKind[]; expect: { target: number | null } }>)
    it(vector.name, () => { expect(flarePluginDoneTarget(vector.stack)).toBe(vector.expect.target); });
});

describe("page kinds for doneTarget", () => {
  const base: FlarePluginViewModel = { title: "", available: true, fields: [], actions: [], inputs: [], blocks: [] } as unknown as FlarePluginViewModel;
  it("reads a result block, an account layout and a document archetype", () => {
    expect(flarePluginPageKind(undefined)).toBe("task");
    expect(flarePluginPageKind({ ...base, blocks: [{ kind: "result", state: "completed", title: "ok" } as never] })).toBe("result");
    expect(flarePluginPageKind({ ...base, presentation: { renderer: "account", props: { layout: "wallet" }, actions: {} } })).toBe("overview");
    expect(flarePluginPageKind({ ...base, presentation: { renderer: "account", props: { layout: "flow" }, actions: {} } })).toBe("task");
    expect(flarePluginPageKind({ ...base, presentation: { renderer: "account", props: {}, actions: {} } })).toBe("records");
    expect(flarePluginPageKind({ ...base, actions: [{ id: "go", label: "Go", style: "primary" }] })).toBe("task");
  });
});
