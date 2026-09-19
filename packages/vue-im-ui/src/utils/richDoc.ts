import { safeExternalUrl } from "../shared/contracts/url-safety";

/**
 * A rich-text message as it is drawn: the RichDoc v2 document the core stores (`docJson`, flare-proto
 * `RichTextContent.doc_json`) read into blocks and runs. The rule is shared with the three native kits
 * and written down in `spec/rich-doc-vectors.json`, which states it in this very shape.
 */
export type FlareRichMark = "bold" | "italic" | "underline" | "strike" | "spoiler";

export interface FlareRichRun {
  text: string;
  /** The known marks the run carries, once each, in the order of {@link FLARE_RICH_MARKS}. */
  marks?: FlareRichMark[];
  /** Inline code. */
  code?: true;
  /** The href of the innermost link around the run that `safeExternalUrl` accepts, as written. */
  link?: string;
  /** A mention: the user id it names, possibly empty. */
  mention?: string;
  /** An emoji: its pack key, possibly empty. */
  emoji?: string;
}

export type FlareRichBlock =
  | { kind: "paragraph"; runs: FlareRichRun[] }
  | { kind: "heading"; level: 1 | 2 | 3 | 4 | 5 | 6; runs: FlareRichRun[] }
  | { kind: "quote"; blocks: FlareRichBlock[] }
  | { kind: "code"; language?: string; text: string }
  | { kind: "list"; ordered: boolean; items: FlareRichBlock[][] }
  | { kind: "divider" };

export const FLARE_RICH_MARKS: readonly FlareRichMark[] = ["bold", "italic", "underline", "strike", "spoiler"];
/** The core's own limits (`rich_doc_v2/validate.rs`): no node deeper, no more nodes. */
export const FLARE_RICH_DOC_MAX_DEPTH = 64;
export const FLARE_RICH_DOC_MAX_NODES = 10_000;

type Node = Record<string, unknown>;

const asNode = (value: unknown): Node | null =>
  value !== null && typeof value === "object" && !Array.isArray(value) ? (value as Node) : null;
const childrenOf = (node: Node): unknown[] => (Array.isArray(node.children) ? node.children : []);
const nonEmpty = (value: unknown): string => (typeof value === "string" ? value : "");

/** Whether the tree stays inside the core's depth and node limits. Counted before anything is read. */
function withinLimits(root: Node): boolean {
  let nodes = 1;
  const stack: Array<[unknown, number]> = childrenOf(root).map((child) => [child, 1]);
  while (stack.length) {
    const [value, depth] = stack.pop()!;
    if (depth > FLARE_RICH_DOC_MAX_DEPTH) return false;
    nodes += 1;
    if (nodes > FLARE_RICH_DOC_MAX_NODES) return false;
    const node = asNode(value);
    if (node) for (const child of childrenOf(node)) stack.push([child, depth + 1]);
  }
  return true;
}

function readRuns(inlines: unknown[], link: string | undefined, out: FlareRichRun[] = []): FlareRichRun[] {
  const push = (run: FlareRichRun) => out.push(link === undefined ? run : { ...run, link });
  for (const value of inlines) {
    const node = asNode(value);
    if (!node) continue;
    switch (node.type) {
      case "text": {
        const text = nonEmpty(node.text);
        if (!text) break;
        const named = new Set(
          (Array.isArray(node.marks) ? node.marks : []).map((mark) => asNode(mark)?.type),
        );
        const marks = FLARE_RICH_MARKS.filter((mark) => named.has(mark));
        push(marks.length ? { text, marks } : { text });
        break;
      }
      case "inline_code": {
        const text = nonEmpty(node.text);
        if (text) push({ text, code: true });
        break;
      }
      case "hard_break":
        push({ text: "\n" });
        break;
      case "mention": {
        const userId = nonEmpty(node.user_id);
        const text = nonEmpty(node.text);
        if (userId || text) push({ text: text || `@${userId}`, mention: userId });
        break;
      }
      case "emoji": {
        const key = nonEmpty(node.key);
        const text = nonEmpty(node.text);
        if (key || text) push({ text: text || `:${key}:`, emoji: key });
        break;
      }
      case "link": {
        const href = nonEmpty(node.href);
        readRuns(childrenOf(node), href && safeExternalUrl(href) !== null ? href : link, out);
        break;
      }
      case "custom_inline":
        break;
      default: {
        const text = nonEmpty(node.text);
        if (text) push({ text });
      }
    }
  }
  return out;
}

function readBlocks(values: unknown[], out: FlareRichBlock[] = []): FlareRichBlock[] {
  for (const value of values) {
    const node = asNode(value);
    if (!node) continue;
    switch (node.type) {
      case "paragraph": {
        const runs = readRuns(childrenOf(node), undefined);
        if (runs.length) out.push({ kind: "paragraph", runs });
        break;
      }
      case "heading": {
        const runs = readRuns(childrenOf(node), undefined);
        if (!runs.length) break;
        const raw = typeof node.level === "number" && Number.isFinite(node.level) ? Math.trunc(node.level) : 1;
        out.push({ kind: "heading", level: Math.min(6, Math.max(1, raw)) as 1 | 2 | 3 | 4 | 5 | 6, runs });
        break;
      }
      case "quote": {
        const blocks = readBlocks(childrenOf(node));
        if (blocks.length) out.push({ kind: "quote", blocks });
        break;
      }
      case "code_block": {
        const text = childrenOf(node)
          .map((child) => {
            const inline = asNode(child);
            if (inline?.type === "text") return nonEmpty(inline.text);
            return inline?.type === "hard_break" ? "\n" : "";
          })
          .join("");
        if (!text) break;
        const language = nonEmpty(node.language);
        out.push(language ? { kind: "code", language, text } : { kind: "code", text });
        break;
      }
      case "bullet_list":
      case "ordered_list": {
        const items = childrenOf(node)
          .map(asNode)
          .filter((child): child is Node => child?.type === "list_item")
          .map((item) => readBlocks(childrenOf(item)))
          .filter((blocks) => blocks.length > 0);
        if (items.length) out.push({ kind: "list", ordered: node.type === "ordered_list", items });
        break;
      }
      case "divider":
        out.push({ kind: "divider" });
        break;
      case "custom_block":
        readBlocks(childrenOf(node), out);
        break;
      default:
        break;
    }
  }
  return out;
}

/**
 * What a covered spoiler run draws in place of `text`: every code point that is not whitespace becomes
 * U+3000 IDEOGRAPHIC SPACE, so the words are in neither the rendered text nor a copy until revealed.
 */
export function flareRichSpoilerCover(text: string): string {
  return Array.from(text, (character) => (/\s/.test(character) ? character : "\u3000")).join("");
}

/**
 * The blocks a rich-text body draws for `input` — the document object or its JSON text — or `null`
 * when it is not a drawable RichDoc v2 document, and the body shows the message's plain text instead.
 */
export function parseRichDoc(input: unknown): FlareRichBlock[] | null {
  let value = input;
  if (typeof input === "string") {
    try {
      value = JSON.parse(input);
    } catch {
      return null;
    }
  }
  const root = asNode(value);
  if (!root || root.type !== "doc" || root.version !== 2 || !Array.isArray(root.children)) return null;
  if (!withinLimits(root)) return null;
  return readBlocks(root.children);
}
