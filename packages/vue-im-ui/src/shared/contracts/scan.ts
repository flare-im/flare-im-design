import type { FlareScanPoint } from "../../utils/scanHitGate";
export type FlareScanViewState = "preparing" | "live" | "lowLight" | "locked" | "choosing" | "paused" | "imageDecoding" | "imageError" | "noCodeInImage" | "permissionUndetermined" | "denied" | "restricted" | "noCamera" | "insecureContext" | "cameraBusy" | "cameraError";
export type FlareScanSheetPhase = "loading" | "slow" | "ready" | "acting" | "done" | "pending" | "failed" | "offlineWaiting" | "unknown";
export interface FlareScanMarker { id: string; corners: FlareScanPoint[]; label?: string }
export interface FlareScanCapabilities { live: boolean; album: boolean; paste: boolean; myCode: boolean; torch: boolean }
export interface FlareScanInput { id: string; kind: string; label: string; maxLen: number }
export interface FlareScanAction { id: string; label: string; primary?: boolean; inputs?: FlareScanInput[] }
export interface FlareScanHeader { title: string; subtitle?: string; avatarUrl?: string }
export interface FlareScanFact { label: string; value: string }
export type FlareQrPhase = "loading" | "ready" | "offline" | "refreshing" | "failed";

/** Marker hit rectangles always stay inside the preview, including malformed decoder data. */
export function flareScanMarkerBounds(marker: FlareScanMarker) {
  const points = marker.corners.filter(point => Number.isFinite(point.x) && Number.isFinite(point.y));
  if (!points.length) return { left: 0, top: 0, width: 1, height: 1 };
  const clamp = (value: number) => Math.max(0, Math.min(1, value));
  const left = clamp(Math.min(...points.map(point => point.x)));
  const top = clamp(Math.min(...points.map(point => point.y)));
  return { left, top, width: Math.max(0, clamp(Math.max(...points.map(point => point.x))) - left), height: Math.max(0, clamp(Math.max(...points.map(point => point.y))) - top) };
}

/** A visible, quiet page may refresh; a form must never lose an in-progress edit. */
export function flarePluginMayRefresh(state: { visible: boolean; foreground: boolean; loading: boolean; refreshing: boolean; busy: boolean; interaction: boolean }): boolean {
  return state.visible && state.foreground && !state.loading && !state.refreshing && !state.busy && !state.interaction;
}
