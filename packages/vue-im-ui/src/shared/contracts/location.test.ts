import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  flareLocationCoordinateLabel,
  flareLocationDistanceLabel,
  flareLocationMapLinks,
  flareLocationPreviewSize,
  flareLocationProviderFrom,
  flareLocationWebMapUrl,
  type FlareLocationProvider,
  type FlareLocationValue,
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
interface ProviderFromVector { id: string; input: unknown; output: FlareLocationProvider }
interface WebMapUrlVector {
  id: string;
  input: { latitude?: number; longitude?: number; title?: string; provider?: FlareLocationProvider };
  provider?: FlareLocationProvider;
  output: string | null;
}

const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/location-vectors.json"), "utf8")) as {
  links: LinkVector[];
  label: LabelVector[];
  distance: DistanceVector[];
  previewSize: PreviewSizeVector[];
  providerFrom: ProviderFromVector[];
  webMapUrl: WebMapUrlVector[];
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

  it.each(vectors.providerFrom.map((v) => [v.id, v] as const))("providerFrom: %s", (_, v) => {
    expect(flareLocationProviderFrom(v.input)).toBe(v.output);
  });

  it.each(vectors.webMapUrl.map((v) => [v.id, v] as const))("webMapUrl: %s", (_, v) => {
    expect(flareLocationWebMapUrl(v.input, v.provider)).toBe(v.output);
  });

  it("takes the location value a timeline reports, whose missing coordinate is NaN", () => {
    const none: FlareLocationValue = { latitude: Number.NaN, longitude: Number.NaN, title: "位置", address: "" };
    expect(flareLocationWebMapUrl(none, "amap")).toBeNull();
    const tapped: FlareLocationValue = { latitude: 39.9087, longitude: 116.3975, title: "天安门广场", address: "", provider: "osm" };
    expect(flareLocationWebMapUrl(tapped, "amap")).toBe(
      flareLocationMapLinks({ latitude: 39.9087, longitude: 116.3975, title: "天安门广场", provider: "amap" })?.web,
    );
  });

  it("opens nothing for a coordinate JSON cannot carry", () => {
    expect(flareLocationMapLinks({ latitude: Number.NaN, longitude: 10 })).toBeNull();
    expect(flareLocationMapLinks({ latitude: 10, longitude: Number.POSITIVE_INFINITY })).toBeNull();
    expect(flareLocationDistanceLabel(Number.NaN)).toBeNull();
  });
});
