import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { flarePluginMayRefresh } from "./plugin-refresh";
const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/plugin-refresh-vectors.json"), "utf8"));
describe('plugin refresh vectors', () => { for (const vector of table.pluginRefresh) it(vector.name, () => { expect(flarePluginMayRefresh(vector)).toBe(vector.expect); }); });
