/**
 * The network and line diagnostics page: what a person, or the support desk reading over their shoulder, sees
 * about the access directory. The host hands in what `access.getStatus` and `access.listAccessPoints` return; these
 * rules turn it into the page's state, notices and rows, so every app reads a line the same way. Rules and their
 * table: `spec/access-diagnostics-vectors.json`, run by all four kits.
 *
 * - recovering: every line failed, or there is no usable manifest; it outranks a warning and keeps it on screen;
 * - warning: the page has something to flag (the server disagrees about the access point, the manifest expired);
 * - normal: nothing to flag, on a line or not;
 * - latency reads good below 150 ms, poor above 400 ms and fair in between, on the whole milliseconds shown.
 */
export const FLARE_ACCESS_RTT_GOOD_BELOW_MS = 150;
export const FLARE_ACCESS_RTT_POOR_ABOVE_MS = 400;

/** The connection diagnostics of `access.getStatus`: only what the page reads. */
export interface FlareAccessConnectAck {
  /** The access point the server reports for the connection. */
  accessPointId?: string | null;
  /** The server reports a different access point than the client chose. */
  accessPointMismatch?: boolean;
}

/** `access.getStatus.recovering`: there only while every line has failed. */
export interface FlareAccessRecovering {
  /** Bootstrap rounds so far. */
  rounds: number;
  /** When the next round starts; missing while the device has no network. */
  nextRoundAtMs?: number | null;
}

/** What `access.getStatus` returns, as far as the page reads it. The SDK's result fits as it arrives. */
export interface FlareAccessStatus {
  /** The directory holds a usable manifest. */
  loaded: boolean;
  serial?: number | null;
  /** seed, https:<mirror base>, wellKnown:<apId>, recovery, development or none. */
  source?: string | null;
  /** Past its expiry: still connectable. */
  stale?: boolean;
  developmentMode?: boolean;
  regionId?: string | null;
  /** The access point of the current connection. */
  accessPointId?: string | null;
  protocol?: string | null;
  connectAck?: FlareAccessConnectAck | null;
  recovering?: FlareAccessRecovering | null;
}

/** One line of `access.listAccessPoints`. */
export interface FlareAccessPoint {
  accessPointId: string;
  regionId?: string | null;
  host?: string | null;
  /** active, draining, disabled or unknown; any other string reads unknown. */
  status: string;
  rttMs?: number | null;
  /** closed, open or halfOpen. */
  breaker: string;
  pinned: boolean;
  current: boolean;
}

export type FlareAccessDiagnosticsState = "normal" | "recovering" | "warning";
export type FlareAccessDiagnosticsTone = "success" | "warning" | "danger" | "neutral";
export type FlareAccessManifestState = "valid" | "stale" | "none";
export type FlareAccessRttGrade = "good" | "fair" | "poor";
export type FlareAccessPointState = "active" | "draining" | "disabled" | "unknown";
export type FlareAccessBreakerState = "open" | "halfOpen";
export type FlareAccessPinAction = "pin" | "unpin";
export type FlareAccessSourceKind = "seed" | "mirror" | "wellKnown" | "recovery" | "development" | "none" | "unknown";

/** A line at the top of the page. */
export type FlareAccessNoticeText =
  | "healthy"
  | "notConnected"
  | "serviceUnavailable"
  | "waitingForNetwork"
  | "accessPointMismatch"
  | "manifestStale";

export interface FlareAccessNotice {
  text: FlareAccessNoticeText;
  tone: FlareAccessDiagnosticsTone;
  pulse: boolean;
}

export interface FlareAccessRtt {
  /** Whole milliseconds to show; null when unknown. */
  shownMs: number | null;
  grade: FlareAccessRttGrade | null;
}

export interface FlareAccessSource {
  kind: FlareAccessSourceKind;
  /** A mirror's host, a well-known access point, or an unknown source as it arrived. */
  detail: string | null;
}

/** One row of the line list. */
export interface FlareAccessPointRow extends FlareAccessRtt {
  accessPointId: string;
  host: string | null;
  current: boolean;
  pinned: boolean;
  status: FlareAccessPointState;
  statusTone: FlareAccessDiagnosticsTone;
  breaker: FlareAccessBreakerState | null;
  breakerTone: FlareAccessDiagnosticsTone | null;
  pin: FlareAccessPinAction | null;
}

export interface FlareAccessRegion {
  /** null for lines without a region: no heading. */
  regionId: string | null;
  accessPoints: FlareAccessPointRow[];
}

/** What the page shows for one status and list. */
export interface FlareAccessDiagnosticsModel {
  state: FlareAccessDiagnosticsState;
  notices: FlareAccessNotice[];
  manifest: FlareAccessManifestState;
  /** The current line's latency, from its row. */
  rttMs: number | null;
  rttGrade: FlareAccessRttGrade | null;
  /** What the server reports while it disagrees with the client. */
  reportedAccessPointId: string | null;
  recoveryRounds: number | null;
  regions: FlareAccessRegion[];
}

/** A one-line answer to one of the page's actions. */
export interface FlareAccessFeedback<Text extends string> {
  text: Text;
  tone: FlareAccessDiagnosticsTone;
}

export type FlareAccessRefreshText = "adopted" | "upToDate" | "failed" | "skipped";
export type FlareAccessImportText =
  | "adopted"
  | "unchanged"
  | "rollback"
  | "expired"
  | "wrongApp"
  | "developmentMode"
  | "untrusted"
  | "malformed"
  | "rejected";
export type FlareAccessExportText = "copied" | "failed";

const GRADE_TONE: Record<FlareAccessRttGrade, FlareAccessDiagnosticsTone> = { good: "success", fair: "warning", poor: "danger" };

/** The tone a latency grade is drawn in. */
export function flareAccessRttTone(grade: FlareAccessRttGrade): FlareAccessDiagnosticsTone {
  return GRADE_TONE[grade];
}

/** The latency to show and its grade; unknown (missing, negative, not finite) has neither. */
export function flareAccessRtt(rttMs: number | null | undefined): FlareAccessRtt {
  if (typeof rttMs !== "number" || !Number.isFinite(rttMs) || rttMs < 0) return { shownMs: null, grade: null };
  const shownMs = Math.round(rttMs);
  if (shownMs < FLARE_ACCESS_RTT_GOOD_BELOW_MS) return { shownMs, grade: "good" };
  return { shownMs, grade: shownMs > FLARE_ACCESS_RTT_POOR_ABOVE_MS ? "poor" : "fair" };
}

/** The protocol's name on screen; a protocol the kit does not know is shown as it arrives. */
export function flareAccessProtocolLabel(protocol: string | null | undefined): string | null {
  if (protocol === "quic") return "QUIC";
  if (protocol === "ws") return "WebSocket";
  return protocol ?? null;
}

/** `https:<base>` and `wellKnown:<apId>` read apart; the plain sources are their own kinds. */
export function flareAccessSource(source: string | null | undefined): FlareAccessSource {
  if (source === null || source === undefined || source === "none") return { kind: "none", detail: null };
  if (source === "seed" || source === "recovery" || source === "development") return { kind: source, detail: null };
  if (source.startsWith("https:")) {
    const base = source.slice("https:".length);
    const authority = base.slice(base.indexOf("://") + 3);
    return { kind: "mirror", detail: authority.split("/")[0] };
  }
  if (source.startsWith("wellKnown:")) return { kind: "wellKnown", detail: source.slice("wellKnown:".length) };
  return { kind: "unknown", detail: source };
}

const POINT_STATE: Record<string, { status: FlareAccessPointState; tone: FlareAccessDiagnosticsTone }> = {
  active: { status: "active", tone: "success" },
  draining: { status: "draining", tone: "warning" },
  disabled: { status: "disabled", tone: "neutral" },
};
const UNKNOWN_STATE = { status: "unknown", tone: "neutral" } as const;

/** One line's row: a pin needs an active line that is not cooling down; a pinned line can always be let go. */
export function flareAccessPointRow(point: FlareAccessPoint): FlareAccessPointRow {
  const { status, tone } = POINT_STATE[point.status] ?? UNKNOWN_STATE;
  const breaker: FlareAccessBreakerState | null = point.breaker === "open" || point.breaker === "halfOpen" ? point.breaker : null;
  let pin: FlareAccessPinAction | null = null;
  if (point.pinned) pin = "unpin";
  else if (status === "active" && breaker !== "open") pin = "pin";
  return {
    ...flareAccessRtt(point.rttMs),
    accessPointId: point.accessPointId,
    host: point.host ?? null,
    current: point.current,
    pinned: point.pinned,
    status,
    statusTone: tone,
    breaker,
    breakerTone: breaker === null ? null : breaker === "open" ? "danger" : "warning",
    pin,
  };
}

function regionsOf(accessPoints: readonly FlareAccessPoint[]): FlareAccessRegion[] {
  const regions = new Map<string | null, FlareAccessRegion>();
  for (const point of accessPoints) {
    const regionId = point.regionId ?? null;
    let region = regions.get(regionId);
    if (!region) regions.set(regionId, (region = { regionId, accessPoints: [] }));
    region.accessPoints.push(flareAccessPointRow(point));
  }
  return [...regions.values()];
}

function noticesOf(status: FlareAccessStatus, state: FlareAccessDiagnosticsState, warnings: FlareAccessNotice[]): FlareAccessNotice[] {
  if (state === "recovering") {
    const offline = status.recovering && (status.recovering.nextRoundAtMs === null || status.recovering.nextRoundAtMs === undefined);
    const lead: FlareAccessNotice = offline
      ? { text: "waitingForNetwork", tone: "warning", pulse: false }
      : { text: "serviceUnavailable", tone: "warning", pulse: true };
    return [lead, ...warnings];
  }
  if (state === "warning") return warnings;
  return [status.accessPointId ? { text: "healthy", tone: "success", pulse: false } : { text: "notConnected", tone: "neutral", pulse: false }];
}

/** What the page shows. `status` is null until the host has read one. */
export function flareAccessDiagnostics(
  status: FlareAccessStatus | null | undefined,
  accessPoints: readonly FlareAccessPoint[],
): FlareAccessDiagnosticsModel {
  const regions = regionsOf(accessPoints);
  const current = accessPoints.find((point) => point.current);
  const { shownMs, grade } = flareAccessRtt(current?.rttMs);
  const base = { rttMs: shownMs, rttGrade: grade, regions };
  if (!status) return { ...base, state: "normal", notices: [], manifest: "none", reportedAccessPointId: null, recoveryRounds: null };

  const mismatch = status.connectAck?.accessPointMismatch === true;
  const warnings: FlareAccessNotice[] = [];
  if (mismatch) warnings.push({ text: "accessPointMismatch", tone: "warning", pulse: false });
  if (status.stale) warnings.push({ text: "manifestStale", tone: "warning", pulse: false });

  const recovering = Boolean(status.recovering) || !status.loaded;
  const state: FlareAccessDiagnosticsState = recovering ? "recovering" : warnings.length ? "warning" : "normal";
  return {
    ...base,
    state,
    notices: noticesOf(status, state, warnings),
    manifest: !status.loaded ? "none" : status.stale ? "stale" : "valid",
    reportedAccessPointId: mismatch ? status.connectAck?.accessPointId ?? null : null,
    recoveryRounds: status.recovering ? status.recovering.rounds : null,
  };
}

/** What `access.refresh` answered, in the page's words; nothing for an outcome the kit does not know. */
export function flareAccessRefreshFeedback(outcome: string | null | undefined): FlareAccessFeedback<FlareAccessRefreshText> | null {
  switch (outcome) {
    case "adopted": return { text: "adopted", tone: "success" };
    case "upToDate": return { text: "upToDate", tone: "success" };
    case "failed":
    case "oldValues": return { text: "failed", tone: "warning" };
    case "skipped": return { text: "skipped", tone: "neutral" };
    default: return null;
  }
}

function rejectionText(code: string | null | undefined): FlareAccessImportText {
  switch (code) {
    case "rollback": return "rollback";
    case "expired": return "expired";
    case "wrongBootstrapId": return "wrongApp";
    case "developmentMode": return "developmentMode";
    case "badSignature":
    case "unknownKey":
    case "revoked":
    case "wrongPayloadType": return "untrusted";
    case "malformedEnvelope":
    case "invalidPayload":
    case "tooLarge": return "malformed";
    default: return code?.startsWith("keyCert.") ? "untrusted" : "rejected";
  }
}

/** What `access.importRecovery` answered: its `outcome`, and its `code` when rejected. */
export function flareAccessImportFeedback(
  outcome: string | null | undefined,
  code?: string | null,
): FlareAccessFeedback<FlareAccessImportText> | null {
  switch (outcome) {
    case "adopted": return { text: "adopted", tone: "success" };
    case "unchanged": return { text: "unchanged", tone: "neutral" };
    case "rejected": return { text: rejectionText(code), tone: "danger" };
    default: return null;
  }
}

/** The host's word on the clipboard: copied or failed. */
export function flareAccessExportFeedback(outcome: string | null | undefined): FlareAccessFeedback<FlareAccessExportText> | null {
  if (outcome === "copied") return { text: "copied", tone: "success" };
  if (outcome === "failed") return { text: "failed", tone: "danger" };
  return null;
}
