import { nextTick, type Ref } from "vue";
import { translateFlare } from "../../shared/i18n/messages";

export type MarkdownShortcutKey =
  | "bold" | "strike" | "italic" | "underline"
  | "ordered" | "bullet" | "quote"
  | "link" | "image" | "code" | "codeBlock" | "divider";

export interface UseMarkdownShortcutsOptions {
  value: Ref<string>;
  textarea: () => HTMLTextAreaElement | null;
  maxLength: () => number | undefined;
  blocked: () => boolean;
  insertAtCursor: (text: string) => void;
}

/** Plain-textarea Markdown formatting: wraps or prefixes the selection and keeps the caret sane. */
export function useMarkdownShortcuts(options: UseMarkdownShortcutsOptions) {
  function clamp(next: string): string {
    const max = options.maxLength();
    return max ? next.slice(0, max) : next;
  }
  function replaceSelection(before: string, after = before, fallback = ""): void {
    if (options.blocked()) return;
    const node = options.textarea();
    const source = options.value.value;
    const start = node?.selectionStart ?? source.length;
    const end = node?.selectionEnd ?? source.length;
    const selected = source.slice(start, end) || fallback;
    options.value.value = clamp(`${source.slice(0, start)}${before}${selected}${after}${source.slice(end)}`);
    void nextTick(() => {
      const cursorStart = Math.min(start + before.length, options.value.value.length);
      const cursorEnd = Math.min(cursorStart + selected.length, options.value.value.length);
      const target = options.textarea();
      target?.focus();
      target?.setSelectionRange(cursorStart, cursorEnd);
    });
  }
  function prefixSelection(prefix: string): void {
    if (options.blocked()) return;
    const node = options.textarea();
    const source = options.value.value;
    const start = node?.selectionStart ?? source.length;
    const end = node?.selectionEnd ?? source.length;
    const selected = source.slice(start, end) || "";
    const lineStart = source.lastIndexOf("\n", Math.max(0, start - 1)) + 1;
    options.value.value = clamp(`${source.slice(0, lineStart)}${prefix}${source.slice(lineStart, end)}${source.slice(end)}`);
    void nextTick(() => {
      const target = options.textarea();
      const offset = prefix.length;
      target?.focus();
      target?.setSelectionRange(start + offset, start + offset + selected.length);
    });
  }
  // With nothing selected a shortcut inserts sample text in the interface language, selected so the user types over it.
  const sample = (name: string) => translateFlare(`composer.sample.${name}`);
  function apply(key: MarkdownShortcutKey): void {
    if (options.blocked()) return;
    if (key === "bold") replaceSelection("**", "**", sample("bold"));
    else if (key === "strike") replaceSelection("~~", "~~", sample("strike"));
    else if (key === "italic") replaceSelection("*", "*", sample("italic"));
    else if (key === "underline") replaceSelection("<u>", "</u>", sample("underline"));
    else if (key === "ordered") prefixSelection("1. ");
    else if (key === "bullet") prefixSelection("- ");
    else if (key === "quote") prefixSelection("> ");
    else if (key === "link") replaceSelection("[", "](https://)", sample("link"));
    else if (key === "image") replaceSelection("![", "](https://)", sample("image"));
    else if (key === "code") replaceSelection("`", "`", sample("code"));
    else if (key === "codeBlock") replaceSelection("```\n", "\n```", sample("code"));
    else if (key === "divider") options.insertAtCursor("\n---\n");
  }
  function applyHeading(level: number | null): void {
    if (options.blocked() || !level) return;
    prefixSelection(`${"#".repeat(level)} `);
  }
  return { apply, applyHeading, replaceSelection, prefixSelection };
}
