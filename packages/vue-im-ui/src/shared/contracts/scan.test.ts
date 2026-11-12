import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { flareScanMarkerBounds, flarePluginMayRefresh } from "./scan";
const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/scan-view-vectors.json"), "utf8"));
describe('scan view vectors', () => { for (const vector of table.markerBounds) it(vector.name, () => { const bounds = flareScanMarkerBounds({ id: 'code', corners: vector.corners }); for (const [key, value] of Object.entries(vector.expect)) expect(bounds[key as keyof typeof bounds]).toBeCloseTo(value as number); }); });
describe('plugin refresh vectors', () => { for (const vector of table.pluginRefresh) it(vector.name, () => { expect(flarePluginMayRefresh(vector)).toBe(vector.expect); }); });
