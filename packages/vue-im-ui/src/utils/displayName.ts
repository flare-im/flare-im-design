import { flareDisplayNameFrom, type FlareDisplayName, type FlareDisplayNameEntity } from "../shared/contracts/display-name";
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
