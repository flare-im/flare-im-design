import MarkdownIt from "markdown-it";

// Locally-typed markdown-it renderer surface. The `@types/markdown-it` default-export
// shape resolves inconsistently across consumers (ESM vs CJS `export =`, differing
// `@types` versions in a monorepo), which can make `md.renderer` type-check-invisible in
// a strict downstream app even though it exists at runtime. Typing the small slice we use
// keeps this file compiling under any consumer's module resolution.
type MdToken = { attrSet(name: string, value: string): void };
type MdRuleSelf = { renderToken(tokens: MdToken[], idx: number, options: unknown): string };
type MdRenderRule = (
  tokens: MdToken[],
  idx: number,
  options: unknown,
  env: unknown,
  self: MdRuleSelf,
) => string;
type MdRenderer = { rules: Record<string, MdRenderRule | undefined> };

const md = new MarkdownIt({
  html: false,
  linkify: true,
  breaks: true,
});

const renderer = (md as unknown as { renderer: MdRenderer }).renderer;

const defaultLinkOpen = renderer.rules.link_open;
renderer.rules.link_open = (tokens, idx, options, env, self) => {
  const token = tokens[idx];
  token.attrSet("target", "_blank");
  token.attrSet("rel", "noopener noreferrer");
  return defaultLinkOpen ? defaultLinkOpen(tokens, idx, options, env, self) : self.renderToken(tokens, idx, options);
};

const defaultImage = renderer.rules.image;
renderer.rules.image = (tokens, idx, options, env, self) => {
  const token = tokens[idx];
  token.attrSet("loading", "lazy");
  token.attrSet("decoding", "async");
  return defaultImage ? defaultImage(tokens, idx, options, env, self) : self.renderToken(tokens, idx, options);
};

const MARKDOWN_PATTERNS = [
  /^#{1,6}\s+/m,
  /^\s{0,3}[-*+]\s+/m,
  /^\d+\.\s+/m,
  /^\s{0,3}---+\s*$/m,
  /```[\s\S]*?```/,
  /!\[[^\]\n]*\]\([^)]+\)/,
  /\[[^\]\n]+\]\([^)]+\)/,
  /\*\*.*?\*\*/,
  /(^|[^\w])__[^_\n]+?__(?=$|[^\w])/,
  /~~.*?~~/,
  /<u>[\s\S]+?<\/u>/i,
  /`[^`\n]+?`/,
  /\*.*?\*/,
  /(^|[^\w])_[^_\n]+?_(?=$|[^\w])/,
  /^>\s+/m,
  /^\|.*\|.*$/m,
];

import { translateFlare } from "../shared/i18n/messages";

export function isMarkdown(content: string): boolean {
  const text = normalizeMarkdownText(content).trim();
  if (!text) return false;
  return MARKDOWN_PATTERNS.some((pattern) => pattern.test(text));
}

export function normalizeMarkdownText(content: string): string {
  let next = content.replace(/\r\n?/g, "\n");
  let previous = "";
  while (previous !== next) {
    previous = next;
    next = next
      .replace(/\*\*\*([^*\n]+?)\*\*\*\*\*\*([^*\n]+?)\*\*\*/g, "***$1$2***")
      .replace(/\*\*([^*\n]+?)\*\*\*\*([^*\n]+?)\*\*/g, "**$1$2**")
      .replace(/__([^_\n]+?)____([^_\n]+?)__/g, "__$1$2__")
      .replace(/~~([^~\n]+?)~~~~([^~\n]+?)~~/g, "~~$1$2~~")
      .replace(/<u>([\s\S]+?)<\/u><u>([\s\S]+?)<\/u>/gi, "<u>$1$2</u>")
      .replace(/`([^`\n]+?)``([^`\n]+?)`/g, "`$1$2`");
  }
  return next;
}

export function renderMarkdown(content: string): string {
  return md
    .render(normalizeMarkdownText(content))
    .replace(/&lt;u&gt;/gi, "<u>")
    .replace(/&lt;\/u&gt;/gi, "</u>");
}

export function markdownToPlainText(content: string): string {
  let text = normalizeMarkdownText(content);
  text = text
    .replace(/```(?:[^\n`]*)\n?([\s\S]*?)```/g, "$1")
    .replace(/!\[([^\]\n]*)\]\([^)]+\)/g, (_match, alt: string) => {
      const label = alt.trim();
      return label ? translateFlare("preview.imageNamed", { label }) : translateFlare("preview.image");
    })
    .replace(/\[([^\]\n]+)\]\([^)]+\)/g, "$1")
    .replace(/^#{1,6}\s+/gm, "")
    .replace(/^\s{0,3}>\s?/gm, "")
    .replace(/^\s{0,3}(?:[-*+]|\d+\.)\s+/gm, "")
    .replace(/^\s{0,3}---+\s*$/gm, " ")
    .replace(/<u>([\s\S]+?)<\/u>/gi, "$1")
    .replace(/\*\*\*([\s\S]+?)\*\*\*/g, "$1")
    .replace(/___([\s\S]+?)___/g, "$1")
    .replace(/\*\*([\s\S]+?)\*\*/g, "$1")
    .replace(/(^|[^\w])__([^_\n]+?)__(?=$|[^\w])/g, "$1$2")
    .replace(/~~([\s\S]+?)~~/g, "$1")
    .replace(/`([^`\n]+?)`/g, "$1")
    .replace(/\*([^*\n]+?)\*/g, "$1")
    .replace(/(^|[^\w])_([^_\n]+?)_(?=$|[^\w])/g, "$1$2")
    .replace(/[ \t]+\n/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
  return text;
}

export function countWords(text: string): number {
  return markdownToPlainText(text).trim().split(/\s+/).filter((word) => word.length > 0).length;
}

export function estimateReadingTime(text: string): number {
  const wordsPerMinute = 200;
  return Math.max(1, Math.ceil(countWords(text) / wordsPerMinute));
}
