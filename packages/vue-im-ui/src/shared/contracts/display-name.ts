/**
 * A name as the core SDK projects it — a conversation's `title` and `lastSender`, a message's `sender`, a participant's
 * or a contact's `name` — camelCase on the wire. The SDKs carry no copy: a name that is not known stays structured
 * (an unnamed person with the tail of their id, a group named by its members) and every kit writes it with the same
 * table, spec/display-name-vectors.json. The text is `flareDisplayNameText` on `./utils`.
 *
 * Components keep string props: a host turns the projected value into text where it wires it into one.
 */

/** Where a named value came from. For tests and diagnostics only: every source reads the same. */
export type FlareDisplayNameSource = "alias" | "memberNickname" | "profile" | "snapshot" | "remark" | "name";

/** What an unnamed value is, after the conversation type (or a person). */
export type FlareDisplayNameEntity = "person" | "group" | "system" | "ai" | "customer" | "channel" | "broadcast" | "temp";

export type FlareDisplayName =
  /** A real name, drawn as it is. */
  | { kind: "named"; text: string; source?: FlareDisplayNameSource }
  /** A group without a name, by up to three of its named members (never the reader); `total` counts the reader. */
  | { kind: "members"; names: string[]; total: number }
  /** Nothing to call it by: what it is, and for a person the last four scalars of their id (`flareIdTail`). */
  | { kind: "unnamed"; entity: FlareDisplayNameEntity; idTail: string };

const SOURCES: ReadonlySet<string> = new Set<FlareDisplayNameSource>(["alias", "memberNickname", "profile", "snapshot", "remark", "name"]);
const ENTITIES: ReadonlySet<string> = new Set<FlareDisplayNameEntity>(["person", "group", "system", "ai", "customer", "channel", "broadcast", "temp"]);
const UNKNOWN_USER: FlareDisplayName = Object.freeze({ kind: "unnamed", entity: "person", idTail: "" });

/**
 * A wire value as a name the kit knows, never failing (spec/display-name-vectors.json): an unknown `entity` reads as
 * `person`; an unknown `kind`, a form missing its text, or a value that is not an object reads as an unnamed person
 * without an id tail (「未知用户」). A core newer than the kit therefore still draws something sensible.
 */
export function flareDisplayNameFrom(value: unknown): FlareDisplayName {
  if (!value || typeof value !== "object") return UNKNOWN_USER;
  const raw = value as Record<string, unknown>;
  switch (raw.kind) {
    case "named":
      if (typeof raw.text !== "string") return UNKNOWN_USER;
      return typeof raw.source === "string" && SOURCES.has(raw.source)
        ? { kind: "named", text: raw.text, source: raw.source as FlareDisplayNameSource }
        : { kind: "named", text: raw.text };
    case "members":
      return {
        kind: "members",
        names: Array.isArray(raw.names) ? raw.names.filter((each): each is string => typeof each === "string") : [],
        total: typeof raw.total === "number" && Number.isFinite(raw.total) ? Math.trunc(raw.total) : 0,
      };
    case "unnamed":
      return {
        kind: "unnamed",
        entity: typeof raw.entity === "string" && ENTITIES.has(raw.entity) ? (raw.entity as FlareDisplayNameEntity) : "person",
        idTail: typeof raw.idTail === "string" ? raw.idTail : "",
      };
    default:
      return UNKNOWN_USER;
  }
}

/**
 * The tail of an id the kits show for a person without a name: the id trimmed of surrounding white space, then its
 * last 4 Unicode scalars — not UTF-16 units, so an emoji is one — or the whole id when it has 4 or fewer; a blank id
 * gives "". The core SDK makes `idTail` with the same rule (spec/display-name-vectors.json `idTail`).
 */
export function flareIdTail(id: string): string {
  const scalars = Array.from(id.trim());
  return scalars.length > 4 ? scalars.slice(-4).join("") : scalars.join("");
}
