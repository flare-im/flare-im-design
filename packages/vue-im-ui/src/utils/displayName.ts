import type { FlareDisplayName, FlareDisplayNameEntity } from "../shared/contracts/display-name";
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
 * besides the reader, adds `displayName.membersMore` with N = total - names - 1 (「张三、李四等 8 人」, "Zhang San, Li Si
 * and 8 others"), and with no name left reads as an unnamed group; `unnamed` reads by entity — a person with an id tail
 * 「用户 9876」, without one 「未知用户」, any other entity its own word. Hosts call it where they hand a name to a kit
 * component, whose props stay strings.
 */
export function flareDisplayNameText(name: FlareDisplayName, strings?: FlareDisplayNameStrings): string {
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
      const others = (Number.isFinite(name.total) ? name.total : 0) - names.length - 1;
      return others > 0 ? t("displayName.membersMore", { names: joined, count: others }) : joined;
    }
    case "unnamed": {
      if (name.entity !== "person" && name.entity in ENTITY_KEYS) return t(ENTITY_KEYS[name.entity]);
      return name.idTail ? t("displayName.user", { idTail: name.idTail }) : t("displayName.unknownUser");
    }
  }
}
