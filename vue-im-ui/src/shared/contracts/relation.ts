/**
 * Contacts / relation contracts — pure logic shared by the four platforms.
 *
 * Two component families live here because they answer the same question from
 * opposite ends: `UnknownUserPlaceholder` renders an account the host cannot
 * describe, `RelationActionBar` renders what may still be done about one.
 * Neither performs I/O; the host owns the relation state and every command.
 */

// ---------------------------------------------------------------------------
// UnknownUserPlaceholder
// ---------------------------------------------------------------------------

/** Why the host cannot show a real profile. */
export type UnknownUserKind = "unknown" | "deactivated" | "blocked" | "unreachable";

/** `row` for list rows, `card` for a detail surface. */
export type UnknownUserDensity = "row" | "card";

/** Semantic icon key; each platform maps it to its own glyph source. */
export type UnknownUserIcon = "unknown" | "deactivated" | "blocked" | "unreachable";

/** Tone accompanies — never replaces — the icon and the title text. */
export type UnknownUserTone = "neutral" | "warning" | "danger";

export interface UnknownUserPresentation {
  kind: UnknownUserKind;
  icon: UnknownUserIcon;
  tone: UnknownUserTone;
}

const UNKNOWN_USER_KINDS: readonly UnknownUserKind[] = [
  "unknown",
  "deactivated",
  "blocked",
  "unreachable",
];

/**
 * Icon + tone for `kind`. An absent or unrecognised kind degrades to `unknown`
 * rather than rendering blank, so a stale host value can never blank the row.
 */
export function unknownUserPresentation(
  kind: UnknownUserKind | null | undefined,
): UnknownUserPresentation {
  const resolved: UnknownUserKind =
    kind != null && UNKNOWN_USER_KINDS.includes(kind) ? kind : "unknown";
  switch (resolved) {
    case "deactivated":
      return { kind: resolved, icon: "deactivated", tone: "neutral" };
    case "blocked":
      return { kind: resolved, icon: "blocked", tone: "danger" };
    case "unreachable":
      return { kind: resolved, icon: "unreachable", tone: "warning" };
    default:
      return { kind: "unknown", icon: "unknown", tone: "neutral" };
  }
}

/** Default budget for the diagnostic id line; long ids are middle-elided. */
export const UNKNOWN_USER_ID_MAX_LENGTH = 24;

/**
 * The user id as it appears in the diagnostic slot: trimmed, and middle-elided
 * to `maxLength` characters (ellipsis included) so a 64-char id never becomes
 * the widest thing on screen. Never used as the title.
 */
export function shortenUserId(
  userId: string | null | undefined,
  maxLength: number = UNKNOWN_USER_ID_MAX_LENGTH,
): string {
  const id = (userId ?? "").trim();
  const limit = maxLength < 8 ? 8 : maxLength;
  if (id.length <= limit) return id;
  const head = Math.ceil((limit - 1) / 2);
  const tail = limit - 1 - head;
  return `${id.slice(0, head)}…${id.slice(id.length - tail)}`;
}

// ---------------------------------------------------------------------------
// RelationActionBar
// ---------------------------------------------------------------------------

/** Relation between the viewer and the contact, as decided by the host. */
export type RelationState = "none" | "pendingOut" | "pendingIn" | "friends" | "blocked";

/** Commands the bar may ask the host to run. */
export type RelationAction =
  | "add"
  | "accept"
  | "reject"
  | "remove"
  | "block"
  | "unblock"
  | "message";

/** Capabilities the host can honour. Absent or false → the action is not rendered. */
export interface RelationCapabilities {
  add?: boolean;
  accept?: boolean;
  reject?: boolean;
  remove?: boolean;
  block?: boolean;
  unblock?: boolean;
  message?: boolean;
}

export interface RelationActionEntry {
  action: RelationAction;
  /** Exactly one entry per relation may be primary, and only when capable. */
  primary: boolean;
  /** Destructive entries render with the danger token, in the trailing group. */
  destructive: boolean;
}

type RelationRule = { action: RelationAction; primary: boolean; destructive: boolean };

/**
 * The full, ordered rule table. Capabilities filter it; they never reorder it,
 * so a button keeps its slot whichever switches the host flips.
 */
const RELATION_RULES: Record<RelationState, readonly RelationRule[]> = {
  none: [
    { action: "add", primary: true, destructive: false },
    { action: "block", primary: false, destructive: false },
  ],
  // pendingOut deliberately omits `add`: the request is already out, so the bar
  // shows a disabled "waiting" notice instead of a button that would re-send.
  pendingOut: [{ action: "block", primary: false, destructive: false }],
  pendingIn: [
    { action: "accept", primary: true, destructive: false },
    { action: "reject", primary: false, destructive: false },
    { action: "block", primary: false, destructive: false },
  ],
  friends: [
    { action: "message", primary: true, destructive: false },
    { action: "remove", primary: false, destructive: true },
    { action: "block", primary: false, destructive: true },
  ],
  // While blocked nothing else is offered — no message, no friend request.
  blocked: [{ action: "unblock", primary: true, destructive: false }],
};

function capabilityAllows(
  capabilities: RelationCapabilities | null | undefined,
  action: RelationAction,
): boolean {
  return capabilities?.[action] === true;
}

/**
 * Ordered, displayable actions for `relation` under `capabilities`.
 * The host owns the relation; the component owns nothing but this table.
 */
export function relationActions(
  relation: RelationState | null | undefined,
  capabilities: RelationCapabilities | null | undefined,
): RelationActionEntry[] {
  const rules = RELATION_RULES[(relation ?? "none") as RelationState] ?? RELATION_RULES.none;
  return rules
    .filter((rule) => capabilityAllows(capabilities, rule.action))
    .map((rule) => ({ action: rule.action, primary: rule.primary, destructive: rule.destructive }));
}

/**
 * True while an outgoing request is waiting: the bar shows a disabled primary
 * notice ("waiting for verification") in place of the add button, regardless of
 * capabilities, because it reports state rather than offering a command.
 */
export function relationShowsPending(relation: RelationState | null | undefined): boolean {
  return relation === "pendingOut";
}

/** Payload of the `action` event. */
export interface RelationActionPayload {
  action: RelationAction;
}
