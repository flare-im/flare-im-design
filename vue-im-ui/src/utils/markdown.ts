import MarkdownIt from "markdown-it";

const md = new MarkdownIt({
  html: false,
  linkify: true,
  breaks: true,
});

const defaultLinkOpen = md.renderer.rules.link_open;
md.renderer.rules.link_open = (tokens, idx, options, env, self) => {
  const token = tokens[idx];
  token.attrSet("target", "_blank");
  token.attrSet("rel", "noopener noreferrer");
  return defaultLinkOpen ? defaultLinkOpen(tokens, idx, options, env, self) : self.renderToken(tokens, idx, options);
};

const defaultImage = md.renderer.rules.image;
md.renderer.rules.image = (tokens, idx, options, env, self) => {
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
      return label ? `[图片] ${label}` : "[图片]";
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
