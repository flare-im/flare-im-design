import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { markdownToPlainText } from "./markdown";
import { setFlareRuntimeLocale } from "../shared/i18n/messages";

/**
 * The shared markdown table (`spec/markdown-preview-vectors.json`): what a markdown message reads as in a
 * conversation row, a reply strip or a quote. Vue is the reference implementation — it has applied this to
 * every preview since before the native kits existed — and the three native kits answer to the same file.
 */
const table = JSON.parse(
  readFileSync(resolve(__dirname, "../../../../spec/markdown-preview-vectors.json"), "utf8"),
) as { cases: { id: string; markdown: string; expected: Record<string, string> }[] };

describe("markdown read as one plain line", () => {
  for (const vector of table.cases) {
    for (const locale of ["zh-CN", "en-US"]) {
      it(`${vector.id} reads the same in ${locale}`, () => {
        setFlareRuntimeLocale(locale as "zh-CN" | "en-US");
        try {
          expect(markdownToPlainText(vector.markdown)).toBe(vector.expected[locale]);
        } finally {
          setFlareRuntimeLocale("zh-CN");
        }
      });
    }
  }
});
