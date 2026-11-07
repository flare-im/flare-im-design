import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  FLARE_ACCESS_RTT_GOOD_BELOW_MS,
  FLARE_ACCESS_RTT_POOR_ABOVE_MS,
  flareAccessDiagnostics,
  flareAccessExportFeedback,
  flareAccessImportFeedback,
  flareAccessPointRow,
  flareAccessProtocolLabel,
  flareAccessRefreshFeedback,
  flareAccessRtt,
  flareAccessRttTone,
  flareAccessSource,
  type FlareAccessPoint,
  type FlareAccessStatus,
} from "./accessDiagnostics";

/**
 * The shared diagnostics table (`spec/access-diagnostics-vectors.json`): what the host read in, what the page shows
 * out. The Flutter, SwiftUI and Compose kits run the same file.
 */
type Feedback = { text: string | null; tone: string | null };
const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../spec/access-diagnostics-vectors.json"), "utf8")) as {
  thresholds: { rttGoodBelowMs: number; rttPoorAboveMs: number };
  rtt: { rttMs: number | null; shownMs: number | null; grade: string | null }[];
  protocols: { protocol: string | null; label: string | null }[];
  sources: { source: string | null; kind: string; detail: string | null }[];
  refresh: ({ outcome: string | null } & Feedback)[];
  import: ({ outcome: string | null; code: string | null } & Feedback)[];
  export: ({ outcome: string | null } & Feedback)[];
  points: { name: string; point: FlareAccessPoint; expect: Record<string, string | null> }[];
  cases: {
    name: string;
    status: FlareAccessStatus | null;
    accessPoints: FlareAccessPoint[];
    expect: {
      state: string;
      notices: { text: string; tone: string; pulse: boolean }[];
      manifest: string;
      rttMs?: number;
      rttGrade?: string;
      reportedAccessPointId?: string;
      recoveryRounds?: number;
      regions: { regionId: string | null; accessPoints: string[] }[];
    };
  }[];
};

const said = (feedback: { text: string; tone: string } | null): Feedback => ({ text: feedback?.text ?? null, tone: feedback?.tone ?? null });

describe("what the diagnostics page shows", () => {
  it("uses the shared thresholds", () => {
    expect(FLARE_ACCESS_RTT_GOOD_BELOW_MS).toBe(table.thresholds.rttGoodBelowMs);
    expect(FLARE_ACCESS_RTT_POOR_ABOVE_MS).toBe(table.thresholds.rttPoorAboveMs);
    expect(table.cases.length).toBeGreaterThanOrEqual(14);
  });

  for (const vector of table.cases) {
    it(vector.name, () => {
      const model = flareAccessDiagnostics(vector.status, vector.accessPoints);
      expect({
        state: model.state,
        notices: model.notices,
        manifest: model.manifest,
        rttMs: model.rttMs,
        rttGrade: model.rttGrade,
        reportedAccessPointId: model.reportedAccessPointId,
        recoveryRounds: model.recoveryRounds,
        regions: model.regions.map((region) => ({
          regionId: region.regionId,
          accessPoints: region.accessPoints.map((row) => row.accessPointId),
        })),
      }).toEqual({
        rttMs: null,
        rttGrade: null,
        reportedAccessPointId: null,
        recoveryRounds: null,
        ...vector.expect,
      });
    });
  }

  for (const vector of table.points) {
    it(`row: ${vector.name}`, () => {
      const row = flareAccessPointRow(vector.point);
      expect({ status: row.status, statusTone: row.statusTone, breaker: row.breaker, breakerTone: row.breakerTone, pin: row.pin }).toEqual(vector.expect);
    });
  }

  it("grades latency on the whole milliseconds it shows", () => {
    for (const { rttMs, shownMs, grade } of table.rtt) expect(flareAccessRtt(rttMs), String(rttMs)).toEqual({ shownMs, grade });
    expect(flareAccessRtt(Number.NaN)).toEqual({ shownMs: null, grade: null });
    expect(flareAccessRtt(Number.POSITIVE_INFINITY)).toEqual({ shownMs: null, grade: null });
    expect([flareAccessRttTone("good"), flareAccessRttTone("fair"), flareAccessRttTone("poor")]).toEqual(["success", "warning", "danger"]);
  });

  it("names the protocol", () => {
    for (const { protocol, label } of table.protocols) expect(flareAccessProtocolLabel(protocol)).toBe(label);
  });

  it("reads the manifest's source", () => {
    for (const { source, kind, detail } of table.sources) expect(flareAccessSource(source), String(source)).toEqual({ kind, detail });
  });

  it("answers a refresh", () => {
    for (const { outcome, text, tone } of table.refresh) expect(said(flareAccessRefreshFeedback(outcome)), String(outcome)).toEqual({ text, tone });
  });

  it("answers an import", () => {
    for (const { outcome, code, text, tone } of table.import) {
      expect(said(flareAccessImportFeedback(outcome, code)), `${outcome} ${code}`).toEqual({ text, tone });
    }
  });

  it("answers an export", () => {
    for (const { outcome, text, tone } of table.export) expect(said(flareAccessExportFeedback(outcome)), String(outcome)).toEqual({ text, tone });
  });
});
