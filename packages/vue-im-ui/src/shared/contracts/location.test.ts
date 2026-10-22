import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  flareLocationCoordinateLabel,
  flareLocationDistanceLabel,
  flareLocationMapLinks,
  flareLocationPreviewSize,
  type FlareLocationProvider,
} from "./location";

interface LinkVector {
  id: string;
  input: { latitude: number; longitude: number; title?: string; provider?: FlareLocationProvider };
  web: string | null;
  apple: string | null;
  geo: string | null;
}
interface LabelVector { id: string; input: { latitude: number; longitude: number }; output: string | null }
interface DistanceVector { id: string; input: number | null; output: string | null }
interface PreviewSizeVector { id: string; input: { width: number; height: number; scale: number }; output: { width: number; height: number } }

const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/location-vectors.json"), "utf8")) as {
  links: LinkVector[];
  label: LabelVector[];
  distance: DistanceVector[];
  previewSize: PreviewSizeVector[];
};

describe("location vectors (spec/location-vectors.json)", () => {
  it.each(vectors.links.map((v) => [v.id, v] as const))("links: %s", (_, v) => {
    const links = flareLocationMapLinks(v.input);
    expect(links?.web ?? null).toBe(v.web);
    expect(links?.apple ?? null).toBe(v.apple);
    expect(links?.geo ?? null).toBe(v.geo);
  });

  it.each(vectors.label.map((v) => [v.id, v] as const))("label: %s", (_, v) => {
    expect(flareLocationCoordinateLabel(v.input.latitude, v.input.longitude)).toBe(v.output);
  });

  it.each(vectors.distance.map((v) => [v.id, v] as const))("distance: %s", (_, v) => {
    expect(flareLocationDistanceLabel(v.input)).toBe(v.output);
  });

  it.each(vectors.previewSize.map((v) => [v.id, v] as const))("previewSize: %s", (_, v) => {
    expect(flareLocationPreviewSize(v.input.width, v.input.height, v.input.scale)).toEqual(v.output);
  });

  it("opens nothing for a coordinate JSON cannot carry", () => {
    expect(flareLocationMapLinks({ latitude: Number.NaN, longitude: 10 })).toBeNull();
    expect(flareLocationMapLinks({ latitude: 10, longitude: Number.POSITIVE_INFINITY })).toBeNull();
    expect(flareLocationDistanceLabel(Number.NaN)).toBeNull();
  });
});
