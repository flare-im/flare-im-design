/**
 * A–Z index letters for contact lists.
 *
 * Latin names (accented or full-width included) index by their first letter. A Chinese name indexes
 * by the pinyin initial of its first character, read through the engine's pinyin collation instead
 * of a pinyin table: each letter's boundary is the first character of that letter in pinyin order,
 * so a character belongs to the last boundary that sorts at or before it. Polyphonic surnames follow
 * the collation's reading (曾 indexes under C); a host that knows better passes `indexKey`. Anything
 * else, and every Chinese name on an engine without pinyin collation, goes to "#".
 */

const PINYIN_LETTERS = "ABCDEFGHJKLMNOPQRSTWXYZ";
const PINYIN_BOUNDARIES = "吖八嚓哒妸发旮哈讥咔垃妈拏喔妑七呥仨他穵夕丫帀";
/** Characters with a single reading. The boundary table is used only when they all index right. */
const SENTINELS: ReadonlyArray<readonly [string, string]> = [
  ["林", "L"], ["周", "Z"], ["陈", "C"], ["欧", "O"], ["马", "M"], ["他", "T"], ["日", "R"], ["大", "D"],
];

export const CONTACT_INDEX_OTHER = "#";

let pinyinCollator: Intl.Collator | null | undefined;

function initialWith(collator: Intl.Collator, character: string): string {
  let letter = CONTACT_INDEX_OTHER;
  for (let index = 0; index < PINYIN_BOUNDARIES.length; index += 1) {
    if (collator.compare(PINYIN_BOUNDARIES[index], character) > 0) break;
    letter = PINYIN_LETTERS[index];
  }
  return letter;
}

function pinyin(): Intl.Collator | null {
  if (pinyinCollator !== undefined) return pinyinCollator;
  try {
    const collator = new Intl.Collator("zh-Hans-u-co-pinyin");
    pinyinCollator = SENTINELS.every(([character, letter]) => initialWith(collator, character) === letter) ? collator : null;
  } catch {
    pinyinCollator = null;
  }
  return pinyinCollator;
}

/** The index letter of a contact: `indexKey` when the host gives one, otherwise the name. */
export function contactIndexLetter(name: string, indexKey?: string): string {
  const first = Array.from((indexKey ?? name).trim())[0] ?? "";
  const latin = first.normalize("NFKD").replace(/\p{M}/gu, "").toUpperCase();
  if (/^[A-Z]$/.test(latin)) return latin;
  if (!indexKey && /^\p{Script=Han}$/u.test(first)) {
    const collator = pinyin();
    return collator ? initialWith(collator, first) : CONTACT_INDEX_OTHER;
  }
  return CONTACT_INDEX_OTHER;
}

/** Name order inside an index group: pinyin order for Chinese where the engine has it. */
export function compareContactNames(left: string, right: string): number {
  return (pinyin() ?? new Intl.Collator(undefined, { sensitivity: "base" })).compare(left, right);
}

/** Letters in list order: A to Z, then "#". */
export function compareContactIndexLetters(left: string, right: string): number {
  if (left === right) return 0;
  if (left === CONTACT_INDEX_OTHER) return 1;
  if (right === CONTACT_INDEX_OTHER) return -1;
  return left < right ? -1 : 1;
}
