<script setup lang="ts">
import { nextTick, onBeforeUnmount, onMounted, ref, watch } from "vue";
import { normalizeMarkdownText } from "../../utils/markdown";
import { resolveEmojiPackAssetUrlByKey } from "./ComposerEmojiStickerPopover/composerEmojiAssets";

const ZERO_WIDTH_SPACE = "\u200B";

type InlineMark = "bold" | "strike" | "italic" | "underline" | "code";
type RichBlockKind = "ordered" | "bullet" | "quote" | "codeBlock" | "divider";
type RichTokenKind = InlineMark | RichBlockKind | "link" | "image" | "emoji";
export type RichMarkdownFormatKey =
  | InlineMark
  | "ordered"
  | "bullet"
  | "quote"
  | "link"
  | "image"
  | "codeBlock"
  | "divider";
export type RichHeadingLevel = 1 | 2 | 3 | 4 | 5 | 6;
export type RichMarkdownFormatState = {
  inline: Record<InlineMark, boolean>;
  headingLevel: RichHeadingLevel | null;
};

type RichSegment =
  | { kind: "text"; text: string }
  | { kind: "styled"; token: string; label: string; marks: InlineMark[] }
  | { kind: "heading"; token: string; label: string; level: RichHeadingLevel; marks: InlineMark[] }
  | { kind: RichTokenKind; token: string; label: string; meta?: string };

const TOKEN_RE = /(\[!\[[^\]\n]*\]\([^)]+\)\]\([^)]+\)|!\[[^\]\n]*\]\([^)]+\)|\[[^\]\n]+\]\([^)]+\)|\*\*\*[^*\n]+?\*\*\*|\*\*[\s\S]+?\*\*|~~[\s\S]+?~~|<u>[\s\S]+?<\/u>|`[^`\n]+?`|\*[^*\n]+?\*|\[[a-z][a-z0-9_]*\])/gi;
const INLINE_MARKS: InlineMark[] = ["bold", "italic", "strike", "underline", "code"];
const INLINE_MARK_SET = new Set<InlineMark>(INLINE_MARKS);

const value = defineModel<string>({ default: "" });

const props = withDefaults(defineProps<{
  disabled?: boolean;
  formattingPreview?: boolean;
  maxLength?: number;
  placeholder?: string;
}>(), {
  disabled: false,
  formattingPreview: true,
  maxLength: undefined,
  placeholder: "",
});

const emit = defineEmits<{
  (event: "focus"): void;
  (event: "blur"): void;
  (event: "keydown", payload: KeyboardEvent): void;
  (event: "format-state-change", payload: RichMarkdownFormatState): void;
}>();

const editorRef = ref<HTMLElement | null>(null);
const activeInlineMarks = ref<InlineMark[]>([]);
const activeHeadingLevel = ref<RichHeadingLevel | null>(null);
const stickyInlineMode = ref(false);
const stickyHeadingMode = ref(false);
let savedRange: Range | null = null;

function isInlineMark(value: string): value is InlineMark {
  return INLINE_MARK_SET.has(value as InlineMark);
}

function sortedMarks(marks: Iterable<InlineMark>): InlineMark[] {
  const set = new Set(marks);
  return INLINE_MARKS.filter((mark) => set.has(mark));
}

function marksEqual(a: readonly InlineMark[], b: readonly InlineMark[]): boolean {
  if (a.length !== b.length) return false;
  return a.every((mark, index) => mark === b[index]);
}

function wrapMarkdownWithMarks(text: string, marks: readonly InlineMark[]): string {
  const normalized = sortedMarks(marks);
  const leading = /^\s*/.exec(text)?.[0] ?? "";
  const trailing = /\s*$/.exec(text)?.[0] ?? "";
  const bodyEnd = text.length - trailing.length;
  const body = text.slice(leading.length, bodyEnd);
  if (!body) return text;
  let out = body;
  if (normalized.includes("code")) out = `\`${out}\``;
  if (normalized.includes("italic") && normalized.includes("bold")) {
    out = `***${out}***`;
  } else {
    if (normalized.includes("italic")) out = `*${out}*`;
    if (normalized.includes("bold")) out = `**${out}**`;
  }
  if (normalized.includes("underline")) out = `<u>${out}</u>`;
  if (normalized.includes("strike")) out = `~~${out}~~`;
  return `${leading}${out}${trailing}`;
}

function formatState(): RichMarkdownFormatState {
  const active = new Set(activeInlineMarks.value);
  return {
    inline: {
      bold: active.has("bold"),
      strike: active.has("strike"),
      italic: active.has("italic"),
      underline: active.has("underline"),
      code: active.has("code"),
    },
    headingLevel: activeHeadingLevel.value,
  };
}

function emitFormatState(): void {
  emit("format-state-change", formatState());
}

function resetActiveFormatState(): void {
  const hadState = activeInlineMarks.value.length > 0 || activeHeadingLevel.value !== null;
  stickyInlineMode.value = false;
  stickyHeadingMode.value = false;
  activeInlineMarks.value = [];
  activeHeadingLevel.value = null;
  if (hadState) emitFormatState();
}

function setActiveInlineMarks(marks: Iterable<InlineMark>): void {
  const next = sortedMarks(marks);
  if (!marksEqual(next, activeInlineMarks.value)) {
    activeInlineMarks.value = next;
    emitFormatState();
  }
}

function setActiveHeadingLevel(level: RichHeadingLevel | null): void {
  if (activeHeadingLevel.value === level) return;
  activeHeadingLevel.value = level;
  emitFormatState();
}

function parseStyledToken(token: string): { label: string; marks: InlineMark[] } | null {
  let source = token;
  const marks: InlineMark[] = [];
  let changed = true;
  while (changed) {
    changed = false;
    if (/^\*\*\*[\s\S]+?\*\*\*$/.test(source)) {
      marks.push("bold", "italic");
      source = source.slice(3, -3);
      changed = true;
    } else if (/^\*\*[\s\S]+?\*\*$/.test(source)) {
      marks.push("bold");
      source = source.slice(2, -2);
      changed = true;
    } else if (/^~~[\s\S]+?~~$/.test(source)) {
      marks.push("strike");
      source = source.slice(2, -2);
      changed = true;
    } else if (/^<u>[\s\S]+?<\/u>$/i.test(source)) {
      marks.push("underline");
      source = source.replace(/^<u>/i, "").replace(/<\/u>$/i, "");
      changed = true;
    } else if (/^`[^`\n]+?`$/.test(source)) {
      marks.push("code");
      source = source.slice(1, -1);
      changed = true;
    } else if (/^\*[^*\n]+?\*$/.test(source)) {
      marks.push("italic");
      source = source.slice(1, -1);
      changed = true;
    }
  }
  const normalized = sortedMarks(marks);
  return normalized.length ? { label: source, marks: normalized } : null;
}

function parseToken(token: string): RichSegment | null {
  const emojiMatch = /^\[([a-z][a-z0-9_]*)\]$/.exec(token);
  if (emojiMatch) {
    return {
      kind: "emoji",
      token,
      label: emojiMatch[1],
    };
  }

  if (!props.formattingPreview) return null;

  const linkedImageMatch = /^\[!\[([^\]\n]*)\]\(([^)]+)\)\]\(([^)]+)\)$/.exec(token);
  if (linkedImageMatch) {
    return {
      kind: "image",
      token,
      label: linkedImageMatch[1]?.trim() || "Image",
      meta: linkedImageMatch[3]?.trim() || linkedImageMatch[2]?.trim(),
    };
  }

  const imageMatch = /^!\[([^\]\n]*)\]\(([^)]+)\)$/.exec(token);
  if (imageMatch) {
    return {
      kind: "image",
      token,
      label: imageMatch[1]?.trim() || "Image",
      meta: imageMatch[2]?.trim(),
    };
  }

  const linkMatch = /^\[([^\]\n]+)\]\(([^)]+)\)$/.exec(token);
  if (linkMatch) {
    return {
      kind: "link",
      token,
      label: linkMatch[1]?.trim() || "Link",
      meta: linkMatch[2]?.trim(),
    };
  }

  const styled = parseStyledToken(token);
  if (styled) {
    return { kind: "styled", token, label: styled.label, marks: styled.marks };
  }

  return null;
}

function parseRichTextLine(source: string): RichSegment[] {
  const out: RichSegment[] = [];
  if (props.formattingPreview) {
    const headingMatch = /^(#{1,6})\s+([\s\S]*)$/.exec(source);
    if (headingMatch) {
      const inner = headingMatch[2] ?? "";
      const styled = parseStyledToken(inner);
      out.push({
        kind: "heading",
        token: source,
        label: styled?.label ?? inner,
        level: headingMatch[1].length as RichHeadingLevel,
        marks: styled?.marks ?? [],
      });
      return out;
    }

    const dividerMatch = /^\s{0,3}---+\s*$/.exec(source);
    if (dividerMatch) {
      out.push({ kind: "divider", token: source, label: "Divider" });
      return out;
    }

    const orderedMatch = /^\s{0,3}(\d+)\.\s+([\s\S]+)$/.exec(source);
    if (orderedMatch) {
      out.push({ kind: "ordered", token: source, label: orderedMatch[2] || "List item", meta: `${orderedMatch[1]}.` });
      return out;
    }

    const bulletMatch = /^\s{0,3}[-*+]\s+([\s\S]+)$/.exec(source);
    if (bulletMatch) {
      out.push({ kind: "bullet", token: source, label: bulletMatch[1] || "List item", meta: "•" });
      return out;
    }

    const quoteMatch = /^\s{0,3}>\s?([\s\S]+)$/.exec(source);
    if (quoteMatch) {
      out.push({ kind: "quote", token: source, label: quoteMatch[1] || "Quote" });
      return out;
    }
  }

  let cursor = 0;
  TOKEN_RE.lastIndex = 0;
  for (const match of source.matchAll(TOKEN_RE)) {
    const token = match[0];
    const index = match.index ?? cursor;
    if (index > cursor) out.push({ kind: "text", text: source.slice(cursor, index) });
    const parsed = parseToken(token);
    out.push(parsed ?? { kind: "text", text: token });
    cursor = index + token.length;
  }
  if (cursor < source.length) out.push({ kind: "text", text: source.slice(cursor) });
  return out;
}

function parseRichText(source: string): RichSegment[] {
  if (!source.includes("\n")) return parseRichTextLine(source);
  const out: RichSegment[] = [];
  const lines = source.split("\n");
  for (let index = 0; index < lines.length; index += 1) {
    if (index > 0) out.push({ kind: "text", text: "\n" });
    const line = lines[index] ?? "";
    if (props.formattingPreview && /^\s{0,3}```/.test(line)) {
      const blockLines = [line];
      let endIndex = index;
      for (let cursor = index + 1; cursor < lines.length; cursor += 1) {
        blockLines.push(lines[cursor] ?? "");
        if (/^\s{0,3}```\s*$/.test(lines[cursor] ?? "")) {
          endIndex = cursor;
          break;
        }
      }
      if (endIndex > index) {
        const token = blockLines.join("\n");
        const body = blockLines.slice(1, -1).join("\n").trim();
        out.push({ kind: "codeBlock", token, label: body || "code" });
        index = endIndex;
        continue;
      }
    }
    out.push(...parseRichTextLine(line));
  }
  return out;
}

function appendPlainText(target: Node, text: string): void {
  const parts = text.split("\n");
  parts.forEach((part, index) => {
    if (index > 0) target.appendChild(document.createElement("br"));
    if (part) target.appendChild(document.createTextNode(part));
  });
}

function appendCaretAnchor(target: Node): void {
  target.appendChild(document.createTextNode(ZERO_WIDTH_SPACE));
}

type RichTokenSegment = Exclude<RichSegment, { kind: "text" }>;

function marksForSegment(segment: RichTokenSegment): InlineMark[] {
  if ("marks" in segment) return segment.marks;
  return isInlineMark(segment.kind) ? [segment.kind] : [];
}

function createTokenElement(segment: RichTokenSegment): HTMLElement {
  const tokenEl = document.createElement("span");
  tokenEl.className = `composer-md-token composer-md-token--${segment.kind}`;
  tokenEl.setAttribute("title", ("meta" in segment ? segment.meta : "") || segment.label);
  const marks = marksForSegment(segment);
  if (marks.length) {
    tokenEl.dataset.marks = marks.join(",");
    for (const mark of marks) tokenEl.classList.add(`composer-md-token--${mark}`);
  } else {
    tokenEl.dataset.kind = segment.kind;
  }

  if (segment.kind === "heading") {
    tokenEl.dataset.headingLevel = String(segment.level);
    tokenEl.classList.add(`composer-md-token--heading-${segment.level}`);
  } else {
    tokenEl.dataset.token = segment.token;
  }

  if (segment.kind === "emoji") {
    tokenEl.contentEditable = "false";
    tokenEl.classList.add("composer-md-token--emoji");
    const img = document.createElement("img");
    img.alt = segment.label;
    img.decoding = "async";
    img.loading = "lazy";
    tokenEl.appendChild(img);
    void resolveEmojiPackAssetUrlByKey(segment.label).then((url) => {
      if (url) img.src = url;
      else tokenEl.textContent = segment.token;
    });
    return tokenEl;
  }

  if (segment.kind === "link" || segment.kind === "image") {
    tokenEl.contentEditable = "false";
    const icon = document.createElement("span");
    icon.className = "composer-md-token__icon";
    icon.textContent = segment.kind === "image" ? "IMG" : "↗";
    const text = document.createElement("span");
    text.className = "composer-md-token__text";
    text.textContent = segment.label;
    tokenEl.append(icon, text);
    return tokenEl;
  }

  if (segment.kind === "ordered" || segment.kind === "bullet" || segment.kind === "quote" || segment.kind === "codeBlock" || segment.kind === "divider") {
    tokenEl.contentEditable = "false";
    const icon = document.createElement("span");
    icon.className = "composer-md-token__icon";
    icon.textContent =
      segment.kind === "ordered"
        ? (segment.meta || "1.")
        : segment.kind === "bullet"
          ? "•"
          : segment.kind === "quote"
            ? "❝"
            : segment.kind === "codeBlock"
              ? "{}"
              : "—";
    const text = document.createElement("span");
    text.className = "composer-md-token__text";
    text.textContent = segment.label;
    tokenEl.append(icon, text);
    return tokenEl;
  }

  tokenEl.textContent = segment.label;
  return tokenEl;
}

function appendSegment(target: Node, segment: RichSegment): void {
  if (segment.kind === "text") {
    appendPlainText(target, segment.text);
    return;
  }
  target.appendChild(createTokenElement(segment));
  appendCaretAnchor(target);
}

function renderValue(source: string): void {
  const editor = editorRef.value;
  if (!editor) return;
  const active = document.activeElement === editor;
  const segments = parseRichText(source);
  savedRange = null;
  editor.replaceChildren();
  for (const segment of segments) appendSegment(editor, segment);
  if (active) placeCaretAtEnd();
}

function cleanNodeText(node: Node): string {
  return (node.textContent ?? "").replaceAll(ZERO_WIDTH_SPACE, "");
}

function marksFromDataset(value: string | undefined): InlineMark[] {
  if (!value) return [];
  return sortedMarks(value.split(",").filter(isInlineMark));
}

function headingLevelFromDataset(value: string | undefined): RichHeadingLevel | null {
  const level = Number(value);
  return level >= 1 && level <= 6 ? (level as RichHeadingLevel) : null;
}

function serializeNode(node: Node): string {
  if (node.nodeType === Node.TEXT_NODE) {
    return cleanNodeText(node);
  }
  if (node.nodeName === "BR") return "\n";
  if (node instanceof HTMLElement) {
    const marks = marksFromDataset(node.dataset.marks);
    const headingLevel = headingLevelFromDataset(node.dataset.headingLevel);
    if (headingLevel) {
      const text = cleanNodeText(node);
      if (!text) return "";
      return `${"#".repeat(headingLevel)} ${wrapMarkdownWithMarks(text, marks)}`;
    }
    if (marks.length) {
      return wrapMarkdownWithMarks(cleanNodeText(node), marks);
    }
    const token = node.dataset.token;
    if (token) return token;
  }
  let out = "";
  node.childNodes.forEach((child) => {
    out += serializeNode(child);
  });
  return out;
}

function serializeEditor(): string {
  const editor = editorRef.value;
  return editor ? serializeNode(editor) : value.value;
}

function normalizeAdjacentMarkdown(source: string): string {
  return normalizeMarkdownText(source);
}

function placeCaretAtEnd(): void {
  const editor = editorRef.value;
  if (!editor || typeof window === "undefined") return;
  const selection = window.getSelection();
  const range = document.createRange();
  range.selectNodeContents(editor);
  range.collapse(false);
  selection?.removeAllRanges();
  selection?.addRange(range);
  rememberSelection();
}

function focus(): void {
  void nextTick(() => {
    const run = () => {
      editorRef.value?.focus({ preventScroll: true });
      placeCaretAtEnd();
    };
    if (typeof window === "undefined") run();
    else window.requestAnimationFrame(run);
  });
}

function selectedRange(): Range | null {
  const range = currentSelectedRange();
  return range ? range.cloneRange() : null;
}

function currentSelectedRange(): Range | null {
  const editor = editorRef.value;
  if (!editor || typeof window === "undefined") return null;
  const selection = window.getSelection();
  if (!selection || selection.rangeCount === 0) return null;
  const range = selection.getRangeAt(0);
  if (!isRangeInsideEditor(range)) return null;
  return range;
}

function isRangeInsideEditor(range: Range): boolean {
  const editor = editorRef.value;
  if (!editor) return false;
  return range.commonAncestorContainer === editor || editor.contains(range.commonAncestorContainer);
}

function rememberSelection(): void {
  const range = currentSelectedRange();
  if (range) savedRange = range.cloneRange();
}

function restoreRange(range: Range): void {
  if (!isRangeInsideEditor(range)) return;
  const selection = window.getSelection();
  selection?.removeAllRanges();
  selection?.addRange(range.cloneRange());
  rememberSelection();
}

function styledAncestor(node: Node | null): HTMLElement | null {
  const editor = editorRef.value;
  let current: Node | null = node;
  while (current && current !== editor) {
    if (current instanceof HTMLElement && current.dataset.marks) return current;
    current = current.parentNode;
  }
  return null;
}

function headingAncestor(node: Node | null): HTMLElement | null {
  const editor = editorRef.value;
  let current: Node | null = node;
  while (current && current !== editor) {
    if (current instanceof HTMLElement && current.dataset.headingLevel) return current;
    current = current.parentNode;
  }
  return null;
}

function isHeadingElement(node: Node | null): node is HTMLElement {
  return node instanceof HTMLElement && Boolean(node.dataset.headingLevel);
}

function previousMeaningfulSibling(node: Node | null): Node | null {
  let current = node;
  while (current && current.nodeType === Node.TEXT_NODE && !cleanNodeText(current)) {
    current = current.previousSibling;
  }
  return current;
}

function headingElementForRange(range: Range): HTMLElement | null {
  const ancestor = headingAncestor(range.startContainer);
  if (ancestor) return ancestor;
  if (range.startContainer instanceof HTMLElement && range.startOffset > 0) {
    const previous = previousMeaningfulSibling(range.startContainer.childNodes.item(range.startOffset - 1));
    if (isHeadingElement(previous)) return previous;
  }
  return null;
}

function formattedTextAncestor(node: Node | null): HTMLElement | null {
  return headingAncestor(node) ?? styledAncestor(node);
}

function marksForRange(range: Range): InlineMark[] {
  const node = range.startContainer;
  return marksFromDataset(formattedTextAncestor(node)?.dataset.marks);
}

function lineTextBeforeRange(range: Range): string {
  const editor = editorRef.value;
  if (!editor) return "";
  const before = document.createRange();
  before.selectNodeContents(editor);
  before.setEnd(range.startContainer, range.startOffset);
  const text = serializeFragment(before.cloneContents());
  return text.slice(text.lastIndexOf("\n") + 1);
}

function headingLevelForRange(range: Range): RichHeadingLevel | null {
  const ancestorLevel = headingLevelFromDataset(headingAncestor(range.startContainer)?.dataset.headingLevel);
  if (ancestorLevel) return ancestorLevel;
  const line = lineTextBeforeRange(range);
  const match = /(?:^|\n)(#{1,6})\s/.exec(line);
  return match ? (match[1].length as RichHeadingLevel) : null;
}

function caretBoundaryAfter(node: Node): Text {
  const next = node.nextSibling;
  if (next?.nodeType === Node.TEXT_NODE && !cleanNodeText(next)) {
    const text = next as Text;
    if (!text.data.includes(ZERO_WIDTH_SPACE)) text.data = ZERO_WIDTH_SPACE;
    return text;
  }
  const boundary = document.createTextNode(ZERO_WIDTH_SPACE);
  node.parentNode?.insertBefore(boundary, node.nextSibling);
  return boundary;
}

function moveCaretAfterAncestorIfMarksDiffer(marks: InlineMark[], sourceRange: Range | null): boolean {
  const range = sourceRange ?? currentSelectedRange();
  if (!range || !range.collapsed) return false;
  const ancestor = formattedTextAncestor(range.startContainer);
  if (!ancestor) return false;
  const current = marksFromDataset(ancestor.dataset.marks);
  if (marksEqual(current, marks)) return false;
  const boundary = caretBoundaryAfter(ancestor);
  const next = document.createRange();
  next.setStart(boundary, boundary.data.length);
  next.collapse(true);
  const selection = window.getSelection();
  selection?.removeAllRanges();
  selection?.addRange(next);
  rememberSelection();
  return true;
}

function moveCaretAfterHeadingIfLevelDiffers(level: RichHeadingLevel | null, range: Range | null): void {
  if (!range || !range.collapsed) return;
  const ancestor = headingElementForRange(range);
  if (!ancestor) return;
  const current = headingLevelFromDataset(ancestor.dataset.headingLevel);
  if (current === level) return;
  const boundary = ancestor.nextSibling?.nodeName === "BR"
    ? ancestor.nextSibling
    : document.createElement("br");
  if (!boundary.parentNode) ancestor.after(boundary);
  const next = document.createRange();
  next.setStartAfter(boundary);
  next.collapse(true);
  const selection = window.getSelection();
  selection?.removeAllRanges();
  selection?.addRange(next);
  rememberSelection();
}

function syncFormatStateFromSelection(): void {
  const range = currentSelectedRange();
  if (!range) return;
  if (!range.collapsed) {
    stickyInlineMode.value = false;
    stickyHeadingMode.value = false;
    setActiveInlineMarks(marksForRange(range));
    setActiveHeadingLevel(headingLevelForRange(range));
    return;
  }
  if (!stickyInlineMode.value) setActiveInlineMarks(marksForRange(range));
  if (!stickyHeadingMode.value) setActiveHeadingLevel(headingLevelForRange(range));
}

function fallbackEndRange(): Range | null {
  const editor = editorRef.value;
  if (!editor) return null;
  const range = document.createRange();
  range.selectNodeContents(editor);
  range.collapse(false);
  return range;
}

function commandRange(): Range | null {
  const current = selectedRange();
  if (current) return current;
  if (savedRange && isRangeInsideEditor(savedRange)) return savedRange.cloneRange();
  return fallbackEndRange();
}

function createFragmentFromText(text: string): DocumentFragment {
  const fragment = document.createDocumentFragment();
  for (const segment of parseRichText(text)) appendSegment(fragment, segment);
  return fragment;
}

function serializeFragment(fragment: DocumentFragment): string {
  let out = "";
  fragment.childNodes.forEach((child) => {
    out += serializeNode(child);
  });
  return out;
}

function serializeFragmentText(node: Node): string {
  if (node.nodeType === Node.TEXT_NODE) return cleanNodeText(node);
  if (node.nodeName === "BR") return "\n";
  let out = "";
  node.childNodes.forEach((child) => {
    out += serializeFragmentText(child);
  });
  return out;
}

function collectMarksFromNode(node: Node, out: Set<InlineMark>): void {
  if (node instanceof HTMLElement) {
    for (const mark of marksFromDataset(node.dataset.marks)) out.add(mark);
  }
  node.childNodes.forEach((child) => collectMarksFromNode(child, out));
}

function selectedMarkdown(range: Range): string {
  if (range.collapsed) return "";
  return serializeFragment(range.cloneContents());
}

function selectedPlainText(range: Range): string {
  if (range.collapsed) return "";
  return serializeFragmentText(range.cloneContents());
}

function selectedInlineMarks(range: Range): InlineMark[] {
  const marks = new Set<InlineMark>([...activeInlineMarks.value, ...marksForRange(range)]);
  collectMarksFromNode(range.cloneContents(), marks);
  return sortedMarks(marks);
}

function firstTextNode(node: Node): Text | null {
  if (node.nodeType === Node.TEXT_NODE && cleanNodeText(node)) return node as Text;
  for (const child of Array.from(node.childNodes)) {
    const match = firstTextNode(child);
    if (match) return match;
  }
  return null;
}

function firstInsertedTextNode(startMarker: Node, endMarker: Node): Text | null {
  let node = startMarker.nextSibling;
  while (node && node !== endMarker) {
    const match = firstTextNode(node);
    if (match) return match;
    node = node.nextSibling;
  }
  return null;
}

function replaceRangeWithMarkdown(range: Range, markdown: string, selectFirstText = false): void {
  const editor = editorRef.value;
  if (!editor || !markdown) return;
  editor.focus({ preventScroll: true });
  const startMarker = document.createTextNode(ZERO_WIDTH_SPACE);
  const endMarker = document.createTextNode(ZERO_WIDTH_SPACE);
  const fragment = createFragmentFromText(markdown);
  const container = document.createDocumentFragment();
  container.append(startMarker, fragment, endMarker);
  range.deleteContents();
  range.insertNode(container);

  const nextRange = document.createRange();
  const selectedTextNode = selectFirstText ? firstInsertedTextNode(startMarker, endMarker) : null;
  if (selectedTextNode) {
    nextRange.setStart(selectedTextNode, 0);
    nextRange.setEnd(selectedTextNode, selectedTextNode.textContent?.length ?? 0);
  } else {
    nextRange.setStartBefore(endMarker);
    nextRange.collapse(true);
  }
  const selection = window.getSelection();
  selection?.removeAllRanges();
  selection?.addRange(nextRange);
  startMarker.remove();
  endMarker.remove();
  rememberSelection();
  commitFromEditor();
}

function createFormattedTextElement(
  text: string,
  marks: readonly InlineMark[],
  headingLevel: RichHeadingLevel | null,
): HTMLElement {
  const tokenEl = document.createElement("span");
  tokenEl.className = "composer-md-token composer-md-token--styled";
  const normalizedMarks = sortedMarks(marks);
  if (normalizedMarks.length) {
    tokenEl.dataset.marks = normalizedMarks.join(",");
    for (const mark of normalizedMarks) tokenEl.classList.add(`composer-md-token--${mark}`);
  }
  if (headingLevel) {
    tokenEl.dataset.headingLevel = String(headingLevel);
    tokenEl.classList.add("composer-md-token--heading", `composer-md-token--heading-${headingLevel}`);
  }
  tokenEl.textContent = text;
  return tokenEl;
}

function isSameFormattedTextElement(
  node: HTMLElement | null,
  marks: readonly InlineMark[],
  headingLevel: RichHeadingLevel | null,
): node is HTMLElement {
  if (!node) return false;
  return marksEqual(marksFromDataset(node.dataset.marks), sortedMarks(marks))
    && headingLevelFromDataset(node.dataset.headingLevel) === headingLevel;
}

function fullySelectedFormattedAncestor(range: Range): HTMLElement | null {
  if (range.collapsed) return null;
  const startAncestor = formattedTextAncestor(range.startContainer);
  const endAncestor = formattedTextAncestor(range.endContainer);
  if (!startAncestor || startAncestor !== endAncestor) return null;
  const selected = selectedPlainText(range);
  return selected && selected === cleanNodeText(startAncestor) ? startAncestor : null;
}

function placeCaretAfterNode(node: Node): void {
  const nextRange = document.createRange();
  nextRange.setStartAfter(node);
  nextRange.collapse(true);
  const selection = window.getSelection();
  selection?.removeAllRanges();
  selection?.addRange(nextRange);
  rememberSelection();
}

function placeCaretAtTextEnd(node: Node): void {
  const nextRange = document.createRange();
  nextRange.selectNodeContents(node);
  nextRange.collapse(false);
  const selection = window.getSelection();
  selection?.removeAllRanges();
  selection?.addRange(nextRange);
  rememberSelection();
}

function selectNodeText(node: Node): void {
  const nextRange = document.createRange();
  nextRange.selectNodeContents(node);
  const selection = window.getSelection();
  selection?.removeAllRanges();
  selection?.addRange(nextRange);
  rememberSelection();
}

function replaceRangeWithFormattedText(
  range: Range,
  text: string,
  marks: readonly InlineMark[],
  headingLevel: RichHeadingLevel | null,
  selectInserted = false,
): void {
  const editor = editorRef.value;
  if (!editor || !text) return;
  editor.focus({ preventScroll: true });
  const ancestor = range.collapsed ? formattedTextAncestor(range.startContainer) : null;
  if (isSameFormattedTextElement(ancestor, marks, headingLevel)) {
    const textNode = document.createTextNode(text);
    range.insertNode(textNode);
    placeCaretAfterNode(textNode);
    commitFromEditor();
    return;
  }

  const tokenEl = createFormattedTextElement(text, marks, headingLevel);
  const replacementRange = range.cloneRange();
  const selectedAncestor = fullySelectedFormattedAncestor(range);
  if (selectedAncestor) replacementRange.selectNode(selectedAncestor);
  replacementRange.deleteContents();
  replacementRange.insertNode(tokenEl);
  if (selectInserted) selectNodeText(tokenEl);
  else placeCaretAtTextEnd(tokenEl);
  commitFromEditor();
}

function commitFromEditor(): void {
  const next = normalizeAdjacentMarkdown(serializeEditor());
  if (props.maxLength && next.length > props.maxLength) {
    value.value = next.slice(0, props.maxLength);
    renderValue(value.value);
    return;
  }
  value.value = next;
  if (!next) resetActiveFormatState();
}

function insertAtCursor(text: string): void {
  if (props.disabled || !text) return;
  const editor = editorRef.value;
  if (!editor) {
    value.value = props.maxLength ? `${value.value}${text}`.slice(0, props.maxLength) : `${value.value}${text}`;
    return;
  }
  const range = commandRange();
  if (!range) return;
  replaceRangeWithMarkdown(range, text);
}

function linesWithPrefix(text: string, prefix: (index: number) => string, fallback: string): string {
  const source = text || fallback;
  return source.split("\n").map((line, index) => `${prefix(index)}${line || fallback}`).join("\n");
}

function applyHeadingToLines(text: string, level: RichHeadingLevel | null, fallback = "Heading"): string {
  const prefix = level ? `${"#".repeat(level)} ` : "";
  const source = text || fallback;
  return source
    .split("\n")
    .map((line) => `${prefix}${line.replace(/^#{1,6}\s+/, "") || fallback}`)
    .join("\n");
}

function toggleInlineMark(mark: InlineMark, range: Range, selected: string): void {
  const hasSelection = selected.trim().length > 0;
  const current = hasSelection
    ? selectedInlineMarks(range)
    : (stickyInlineMode.value ? activeInlineMarks.value : marksForRange(range));
  const next = current.includes(mark)
    ? current.filter((item) => item !== mark)
    : [...current, mark];
  const sorted = sortedMarks(next);
  if (!hasSelection) {
    stickyInlineMode.value = true;
    setActiveInlineMarks(sorted);
    editorRef.value?.focus({ preventScroll: true });
    if (!moveCaretAfterAncestorIfMarksDiffer(sorted, range)) restoreRange(range);
    return;
  }
  stickyInlineMode.value = false;
  replaceRangeWithFormattedText(range, selectedPlainText(range), sorted, headingLevelForRange(range), true);
  setActiveInlineMarks(sorted);
}

function applyFormat(key: RichMarkdownFormatKey): void {
  if (props.disabled) return;
  const range = commandRange();
  if (!range) return;
  const selected = selectedMarkdown(range);
  const selectedText = selectedPlainText(range);
  const hasSelection = selected.trim().length > 0;
  const wrap = (before: string, after = before, fallback = "") => {
    stickyInlineMode.value = false;
    setActiveInlineMarks([]);
    replaceRangeWithMarkdown(range, `${before}${hasSelection ? selected : fallback}${after}`, !hasSelection);
  };

  if (isInlineMark(key)) toggleInlineMark(key, range, selected);
  else if (key === "link") replaceRangeWithMarkdown(range, `[${hasSelection ? selectedText : "Link"}](https://)`, !hasSelection);
  else if (key === "image") replaceRangeWithMarkdown(range, `![${hasSelection ? selectedText : "Image description"}](https://)`, !hasSelection);
  else if (key === "ordered") replaceRangeWithMarkdown(range, linesWithPrefix(selectedText, (index) => `${index + 1}. `, "List item"), !hasSelection);
  else if (key === "bullet") replaceRangeWithMarkdown(range, linesWithPrefix(selectedText, () => "- ", "List item"), !hasSelection);
  else if (key === "quote") replaceRangeWithMarkdown(range, linesWithPrefix(selectedText, () => "> ", "Quote"), !hasSelection);
  else if (key === "codeBlock") replaceRangeWithMarkdown(range, `\n\`\`\`\n${hasSelection ? selectedText : "code"}\n\`\`\`\n`, !hasSelection);
  else if (key === "divider") replaceRangeWithMarkdown(range, "\n---\n");
  else wrap("", "");
}

function applyHeadingLevel(level: RichHeadingLevel | null): void {
  if (props.disabled) return;
  const range = commandRange();
  if (!range) return;
  const selected = selectedMarkdown(range);
  const hasSelection = selected.trim().length > 0;
  if (!hasSelection) {
    stickyHeadingMode.value = true;
    setActiveHeadingLevel(level);
    editorRef.value?.focus({ preventScroll: true });
    moveCaretAfterHeadingIfLevelDiffers(level, range);
    return;
  }
  stickyHeadingMode.value = false;
  replaceRangeWithFormattedText(range, selectedPlainText(range), selectedInlineMarks(range), level, true);
  setActiveHeadingLevel(level);
}

function insertActiveText(data: string): void {
  const range = commandRange();
  if (!range) return;
  replaceRangeWithFormattedText(range, data, activeInlineMarks.value, activeHeadingLevel.value);
}

function insertPlainTextOutsideFormattedNode(range: Range, text: string): boolean {
  if (!range.collapsed) return false;
  const ancestor = formattedTextAncestor(range.startContainer);
  if (!ancestor) return false;
  const boundary = headingLevelFromDataset(ancestor.dataset.headingLevel)
    ? (ancestor.nextSibling?.nodeName === "BR" ? ancestor.nextSibling : document.createElement("br"))
    : null;
  if (boundary && !boundary.parentNode) ancestor.after(boundary);
  const textNode = document.createTextNode(text);
  (boundary ?? ancestor).after(textNode);
  placeCaretAfterNode(textNode);
  stickyInlineMode.value = false;
  stickyHeadingMode.value = false;
  setActiveInlineMarks([]);
  setActiveHeadingLevel(null);
  commitFromEditor();
  return true;
}

function insertPlainTextAtRange(range: Range, text: string): void {
  const textNode = document.createTextNode(text);
  range.deleteContents();
  range.insertNode(textNode);
  placeCaretAfterNode(textNode);
  stickyInlineMode.value = false;
  stickyHeadingMode.value = false;
  setActiveInlineMarks([]);
  setActiveHeadingLevel(null);
  commitFromEditor();
}

function onBeforeInput(event: InputEvent): void {
  if (props.disabled || event.isComposing) return;
  if (event.inputType !== "insertText" || !event.data) return;
  if (!activeInlineMarks.value.length && !activeHeadingLevel.value) {
    const range = commandRange();
    if (!range) return;
    if (insertPlainTextOutsideFormattedNode(range, event.data)) {
      event.preventDefault();
      return;
    }
    if (stickyInlineMode.value || stickyHeadingMode.value) {
      event.preventDefault();
      insertPlainTextAtRange(range, event.data);
      return;
    }
    return;
  }
  event.preventDefault();
  insertActiveText(event.data);
}

function onInput(): void {
  commitFromEditor();
  rememberSelection();
}

function onPaste(event: ClipboardEvent): void {
  const text = event.clipboardData?.getData("text/plain") ?? "";
  if (!text) return;
  event.preventDefault();
  insertAtCursor(text);
}

function onEditorFocus(): void {
  rememberSelection();
  emit("focus");
}

function onEditorBlur(): void {
  rememberSelection();
  emit("blur");
}

function onEditorKeyup(): void {
  rememberSelection();
  syncFormatStateFromSelection();
}

watch(
  () => value.value,
  (next) => {
    if (!next) resetActiveFormatState();
    if (serializeEditor() === next) return;
    renderValue(next);
  },
);

function onSelectionChange(): void {
  rememberSelection();
  syncFormatStateFromSelection();
}

onMounted(() => {
  renderValue(value.value);
  document.addEventListener("selectionchange", onSelectionChange);
});

onBeforeUnmount(() => {
  document.removeEventListener("selectionchange", onSelectionChange);
});

defineExpose({
  applyFormat,
  applyHeadingLevel,
  focus,
  insertAtCursor,
});
</script>

<template>
  <div class="composer-rich-markdown-input">
    <div
      ref="editorRef"
      class="composer-rich-markdown-input__editable"
      :class="{ 'composer-rich-markdown-input__editable--disabled': disabled }"
      role="textbox"
      aria-multiline="true"
      :aria-disabled="disabled"
      :contenteditable="disabled ? 'false' : 'true'"
      :data-placeholder="placeholder"
      spellcheck="false"
      autocorrect="off"
      autocapitalize="off"
      inputmode="text"
      @beforeinput="onBeforeInput"
      @input="onInput"
      @paste="onPaste"
      @focus="onEditorFocus"
      @blur="onEditorBlur"
      @mouseup="rememberSelection"
      @keyup="onEditorKeyup"
      @keydown="emit('keydown', $event)"
    />
  </div>
</template>
