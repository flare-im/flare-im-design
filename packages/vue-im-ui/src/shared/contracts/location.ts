/**
 * Location presentation contracts (spec LocationMessage / LocationPicker). Coordinates are WGS-84 as the
 * message stores them; geocoding, nearby search and the static map belong to the host (the Social geo
 * proxy), which the picker reaches through its callbacks. The link, coordinate and distance rules are
 * the shared table in spec/location-vectors.json, read by all four kits' tests.
 */

/** The map service a tenant configured; it decides which web map a card opens. */
export type FlareLocationProvider = "osm" | "amap";

export interface FlareLocationCoordinate {
  latitude: number;
  longitude: number;
}

/** What a reverse geocode answers for a coordinate. */
export interface FlareLocationAddress {
  title: string;
  address: string;
}

/** A place the picker lists and sends: a nearby POI, a search result or the current location. */
export interface FlareLocationPlace extends FlareLocationCoordinate {
  id: string;
  title: string;
  address: string;
  /** Distance from the centre the search was made around, in metres, when the host knows it. */
  distanceM?: number;
}

/** A location message as a timeline reports it to the host (`locationOpen`). */
export interface FlareLocationValue extends FlareLocationCoordinate {
  title: string;
  address: string;
  snapshotUrl?: string;
  provider?: FlareLocationProvider;
}

/** The id of the picker's first row, the coordinate the device reported. */
export const FLARE_LOCATION_CURRENT_ID = "current";

/** Zoom of the web map a card opens on OpenStreetMap. */
export const FLARE_LOCATION_OSM_ZOOM = 17;

/** The three default places a card can open: by provider on the web, Apple Maps, and a `geo:` URI. */
export interface FlareLocationMapLinks {
  web: string;
  apple: string;
  geo: string;
}

/** Whether a coordinate can be drawn and opened: finite, latitude -90..90, longitude -180..180. */
export function isValidFlareLocation(latitude: number, longitude: number): boolean {
  return Number.isFinite(latitude) && Number.isFinite(longitude)
    && latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
}

/** One coordinate in a link: 6 decimals, trailing zeros and a trailing point dropped, never "-0". */
export function formatFlareLocationCoordinate(value: number): string {
  let text = value.toFixed(6);
  if (text.includes(".")) text = text.replace(/0+$/, "").replace(/\.$/, "");
  return text === "-0" ? "0" : text;
}

/** UTF-8 percent-encoding that keeps only A-Z a-z 0-9 - . _ ~ (encodeURIComponent also keeps ! ' ( ) *). */
export function encodeFlareLocationTitle(title: string): string {
  return encodeURIComponent(title).replace(/[!'()*]/g, (ch) => `%${ch.charCodeAt(0).toString(16).toUpperCase()}`);
}

/**
 * The default places a card opens when the host takes no `open`: `web` by provider (osm when omitted),
 * `apple` and `geo`. Null for a coordinate that is not valid. Vue opens `web`.
 */
export function flareLocationMapLinks(input: {
  latitude: number;
  longitude: number;
  title?: string;
  provider?: FlareLocationProvider;
}): FlareLocationMapLinks | null {
  if (!isValidFlareLocation(input.latitude, input.longitude)) return null;
  const lat = formatFlareLocationCoordinate(input.latitude);
  const lng = formatFlareLocationCoordinate(input.longitude);
  const title = (input.title ?? "").trim();
  const name = title ? encodeFlareLocationTitle(title) : "";
  const web = input.provider === "amap"
    ? `https://uri.amap.com/marker?position=${lng},${lat}${name ? `&name=${name}` : ""}&coordinate=wgs84&callnative=0`
    : `https://www.openstreetmap.org/?mlat=${lat}&mlon=${lng}#map=${FLARE_LOCATION_OSM_ZOOM}/${lat}/${lng}`;
  return {
    web,
    apple: `http://maps.apple.com/?ll=${lat},${lng}&q=${name || `${lat},${lng}`}`,
    geo: `geo:${lat},${lng}?q=${lat},${lng}${name ? `(${name})` : ""}`,
  };
}

/**
 * The map service a `chat.location` config value names: the string `amap` (trimmed, any case) is AMap, anything
 * else — `osm`, an unknown name, blank, null, not a string — is OpenStreetMap (spec/location-vectors.json
 * `providerFrom`; the same on all four kits).
 */
export function flareLocationProviderFrom(value: unknown): FlareLocationProvider {
  return typeof value === "string" && value.trim().toLowerCase() === "amap" ? "amap" : "osm";
}

/**
 * The web map a host opens for a location message: the `web` link of {@link flareLocationMapLinks} for `provider`
 * when given, else the location's own, else osm. Null without a coordinate to open — one of the pair missing or not
 * finite, out of range, or exactly 0, 0, which the wire writes for "none" (spec/location-vectors.json `webMapUrl`).
 */
export function flareLocationWebMapUrl(
  location: {
    latitude?: number | null;
    longitude?: number | null;
    title?: string;
    provider?: FlareLocationProvider;
  },
  provider?: FlareLocationProvider,
): string | null {
  const { latitude, longitude } = location;
  if (latitude === null || latitude === undefined || longitude === null || longitude === undefined) return null;
  if (latitude === 0 && longitude === 0) return null;
  return flareLocationMapLinks({
    latitude,
    longitude,
    title: location.title,
    provider: provider ?? location.provider ?? "osm",
  })?.web ?? null;
}

function fixed5(value: number): string {
  const text = value.toFixed(5);
  return text === "-0.00000" ? "0.00000" : text;
}

/** The coordinate line shown where there is no map: "39.90870, 116.39750"; null when not valid. */
export function flareLocationCoordinateLabel(latitude: number, longitude: number): string | null {
  return isValidFlareLocation(latitude, longitude) ? `${fixed5(latitude)}, ${fixed5(longitude)}` : null;
}

/**
 * The size LocationPicker asks previewUrl for, in device pixels: the map area's logical size times the screen
 * scale clamped to 1..2, rounded (spec/location-vectors.json previewSize; the same on all four platforms).
 */
export function flareLocationPreviewSize(width: number, height: number, scale: number): { width: number; height: number } {
  const factor = Math.min(2, Math.max(1, Number.isFinite(scale) ? scale : 1));
  return { width: Math.round(width * factor), height: Math.round(height * factor) };
}

/** A POI row's distance: "120m" below a kilometre, else "1.2km"; null when missing, negative or not finite. */
export function flareLocationDistanceLabel(distanceM: number | null | undefined): string | null {
  if (distanceM === null || distanceM === undefined || !Number.isFinite(distanceM) || distanceM < 0) return null;
  const metres = Math.round(distanceM);
  return metres < 1000 ? `${metres}m` : `${(distanceM / 1000).toFixed(1)}km`;
}
