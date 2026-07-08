import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

type MultideviceScenario = {
  id: string;
  title: string;
  requires: string[];
  steps: string[];
  webEntrypoints: string[];
  flutterEntrypoints: string[];
  observables: string[];
};

type MultideviceManifest = {
  schema: string;
  version: string;
  clients: string[];
  scenarios: MultideviceScenario[];
};

const manifestPath = fileURLToPath(new URL("../../../../../../examples/multidevice_conformance.json", import.meta.url));

const manifest = JSON.parse(readFileSync(manifestPath, "utf8")) as MultideviceManifest;

describe("multi-device conformance manifest", () => {
  it("covers the shared Web and Flutter scenarios", () => {
    expect(manifest.schema).toBe("flare.im.examples.multidevice.conformance.v1");
    expect(manifest.clients).toEqual(["web", "flutter"]);

    const scenarioIds = manifest.scenarios.map((scenario) => scenario.id);
    expect(scenarioIds).toEqual([
      "message_fanout",
      "read_state_roaming",
      "draft_roaming",
      "device_kick",
      "typing_device_attribution",
    ]);
  });

  it("keeps every scenario executable by both client examples", () => {
    for (const scenario of manifest.scenarios) {
      expect(scenario.title.trim()).not.toBe("");
      expect(scenario.requires.length).toBeGreaterThan(0);
      expect(scenario.steps.length).toBeGreaterThan(1);
      expect(scenario.webEntrypoints.length).toBeGreaterThan(0);
      expect(scenario.flutterEntrypoints.length).toBeGreaterThan(0);
      expect(scenario.observables.length).toBeGreaterThan(0);
    }
  });
});
