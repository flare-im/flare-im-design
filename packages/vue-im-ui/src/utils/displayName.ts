import { flareDisplayNameFrom, flareIdTail, type FlareDisplayName, type FlareDisplayNameEntity } from "../shared/contracts/display-name";
import { resolveFlareMessage, translateFlare, type FlareLocale } from "../shared/i18n/messages";

/**
 * Whose words a name is written in: a translator — `useFlareI18n().t`, so a host override of `displayName.*` applies —
 * or the locale to read the kit's messages in. Without it, the runtime locale.
 */
export type FlareDisplayNameStrings = FlareLocale | ((key: string, params?: Record<string, string | number>) => string);

const ENTITY_KEYS: Readonly<Record<Exclude<FlareDisplayNameEntity, "person">, string>> = {
  group: "displayName.group",
  system: "displayName.system",
  ai: "displayName.ai",
  customer: "displayName.customer",
  channel: "displayName.channel",
  broadcast: "displayName.broadcast",
  temp: "displayName.temp",
};

/**
 * The text of a projected name (spec/display-name-vectors.json, the same on all four kits). `named` reads as it is;
 * `members` joins the non-blank names with `displayName.separator` and, when the group has more people than it names
 * besides the reader, adds `displayName.membersMore`, which gets `{names}`, `{total}` (the group's size, the reader
 * included) and `{others}` (total - names - 1, also `{count}` for the plural): Chinese counts the group 「张三、李四、王五等
 * 12 人」, English the others "Zhang San, Li Si, Wang Wu and 8 others". With no name left it reads as an unnamed group;
 * `unnamed` reads by entity — a person with an id tail 「用户 9876」, without one 「未知用户」, any other entity its own
 * word. A value the kit does not know reads as {@link flareDisplayNameFrom} makes it. Hosts call it where they hand a
 * name to a kit component, whose props stay strings.
 */
export function flareDisplayNameText(value: FlareDisplayName, strings?: FlareDisplayNameStrings): string {
  const name = flareDisplayNameFrom(value);
  const t = typeof strings === "function"
    ? strings
    : (key: string, params?: Record<string, string | number>) =>
      strings === undefined ? translateFlare(key, params) : resolveFlareMessage(strings, key, params);
  switch (name.kind) {
    case "named":
      return name.text;
    case "members": {
      const names = name.names.filter((each) => each.trim() !== "");
      if (names.length === 0) return t(ENTITY_KEYS.group);
      const joined = names.join(t("displayName.separator"));
      const others = name.total - names.length - 1;
      return others > 0 ? t("displayName.membersMore", { names: joined, total: name.total, others, count: others }) : joined;
    }
    case "unnamed": {
      if (name.entity !== "person") return t(ENTITY_KEYS[name.entity]);
      return name.idTail ? t("displayName.user", { idTail: name.idTail }) : t("displayName.unknownUser");
    }
  }
}

/** Who a quote says it quotes: the projected name when the quote carries one, a name, and the sender's id. */
export interface FlareQuoteSender {
  /** The core's projected name for the quoted message's sender (a `FlareDisplayName` on the wire), when there is one. */
  sender?: unknown;
  /** A name the host already holds for the sender. */
  senderName?: string | null;
  /** The quoted message's sender id. */
  senderId?: string | null;
}

/**
 * The sender a quote shows (spec/display-name-vectors.json `quoteSender`, the same on all four kits), never blank and
 * never an id: the projected `sender` written by {@link flareDisplayNameText} when the quote carries one; else
 * `senderName`, trimmed, when it is not blank; else the unnamed person of `senderId` — 「用户 9876」 with the tail of the
 * id (`flareIdTail`), 「未知用户」 without one. A projected sender that writes as blank text falls through the same way.
 * The message list's quote reads the three from the quote's `quotedSender`, `quotedSenderName` and `quotedSenderId`.
 */
export function flareQuoteSenderText(quote: FlareQuoteSender, strings?: FlareDisplayNameStrings): string {
  if (quote.sender !== undefined && quote.sender !== null) {
    const projected = flareDisplayNameText(quote.sender as FlareDisplayName, strings).trim();
    if (projected) return projected;
  }
  const name = typeof quote.senderName === "string" ? quote.senderName.trim() : "";
  if (name) return name;
  const idTail = flareIdTail(typeof quote.senderId === "string" ? quote.senderId : "");
  return flareDisplayNameText({ kind: "unnamed", entity: "person", idTail }, strings);
}
