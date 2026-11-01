// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import type { FlareLocale } from "../../../../shared/i18n/messages";
import { useFlareI18nProvider } from "../../../../shared/i18n/useFlareI18n";
import QuoteView from "./QuoteView.vue";

type QuoteSenderCase = { id: string; sender?: unknown; senderName?: string; senderId?: string; text: Record<FlareLocale, string> };
const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../../../spec/display-name-vectors.json"), "utf8")) as {
  quoteSender: QuoteSenderCase[];
};
const locales = ["zh-CN", "en-US"] as const;

/** A quote as the core stores it, with the sender fields a case gives. */
function render(locale: FlareLocale, v: QuoteSenderCase, quotedMessageId = "srv-9") {
  const quote: Record<string, unknown> = { quotedMessageId, quotedTextPreview: "上一条消息", currentContent: { contentType: "text", text: "回复" } };
  if (v.sender !== undefined) quote.quotedSender = v.sender;
  if (v.senderName !== undefined) quote.quotedSenderName = v.senderName;
  if (v.senderId !== undefined) quote.quotedSenderId = v.senderId;
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(QuoteView, { content: { contentType: "quote", quote } as never, isSelf: false });
    },
  }));
}

/** The quote's sender line (spec/display-name-vectors.json `quoteSender`): never blank and never the sender's id. */
describe("QuoteView's sender", () => {
  it.each(vectors.quoteSender.flatMap((v) => locales.map((locale) => [`${v.id} ${locale}`, v, locale] as const)))(
    "%s",
    (_, v, locale) => {
      for (const quoted of ["srv-9", ""]) {
        // Both forms: the button that locates the quoted message, and the plain strip without an id.
        const view = render(locale, v, quoted);
        expect(view.get(".im-quote__source span").text()).toBe(v.text[locale]);
        // An id longer than its tail never shows whole.
        const id = v.senderId?.trim() ?? "";
        if (Array.from(id).length > 4) expect(view.get(".im-quote__source").text()).not.toContain(id);
        view.unmount();
      }
    },
  );
});
