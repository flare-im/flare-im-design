// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, nextTick, type Component } from "vue";
import type { ContentElem } from "./contentElem";
import { flareForwardRecordView, flareForwardSenderInitial } from "./forwardRecord";
import { useFlareI18nProvider } from "../shared/i18n/useFlareI18n";
import { provideFlareContentSelection } from "../shared/message-renderers";
import ForwardView from "../components/messages/MessagesView/views/ForwardView.vue";

interface CardFacts {
  title: string;
  subtitle: string | null;
  previews: { sender: string; text: string }[];
  more: string | null;
  hint: string;
  label: string;
  drawerTitle: string;
}
interface Vector {
  id: string;
  platforms: string[];
  input: ContentElem;
  expect: { layout: "empty" | "single" | "card"; text?: { zh: string; en: string }; zh?: CardFacts; en?: CardFacts };
}
const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../spec/message-forward-vectors.json"), "utf8")) as {
  cases: Vector[];
  senderInitials: { platforms: string[]; cases: { senderName: string; initial: string }[] };
};
const cases = table.cases.filter((v) => v.platforms.includes("vue"));
const LOCALES = { zh: "zh-CN", en: "en-US" } as const;

let host: ReturnType<typeof mount> | undefined;
afterEach(() => {
  host?.unmount();
  host = undefined;
  document.body.innerHTML = "";
});

function mountRecord(content: ContentElem, locale: string, selecting = false) {
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      provideFlareContentSelection(() => selecting);
      return () => h(ForwardView as Component, { content, isSelf: false });
    },
  }), { attachTo: document.body });
}

describe("flareForwardRecordView", () => {
  it.each(cases.flatMap((v) => (["zh", "en"] as const).map((lang) => [v.id, lang, v] as const)))(
    "follows the shared vector %s (%s)",
    (_id, lang, v) => {
      const view = flareForwardRecordView(v.input, LOCALES[lang]);
      expect(view.layout).toBe(v.expect.layout);
      const facts = v.expect[lang];
      if (!facts) return;
      const { title, subtitle, previews, more, hint, label, drawerTitle } = view;
      expect({ title, subtitle, previews, more, hint, label, drawerTitle }).toEqual(facts);
    },
  );
});

describe("flareForwardSenderInitial", () => {
  const initials = table.senderInitials.platforms.includes("vue") ? table.senderInitials.cases : [];
  it.each(initials.map((c) => [c.senderName, c.initial] as const))("reads %j as %s", (senderName, initial) => {
    expect(flareForwardSenderInitial({ sourceSenderName: senderName })).toBe(initial);
  });
});

describe("ForwardView", () => {
  it.each(cases.flatMap((v) => (["zh", "en"] as const).map((lang) => [v.id, lang, v] as const)))(
    "draws the shared vector %s (%s)",
    async (_id, lang, v) => {
      mountRecord(v.input, LOCALES[lang]);
      await nextTick();
      if (v.expect.layout === "empty") {
        expect(host!.get(".im-fwd-empty").text()).toBe(v.expect.text![lang]);
        return;
      }
      if (v.expect.layout === "single") {
        expect(host!.get(".im-fwd-single").text()).toContain(v.expect.text![lang]);
        expect(host!.find(".im-fwd-card").exists()).toBe(false);
        return;
      }
      const facts = v.expect[lang]!;
      const card = host!.get(".im-fwd-card");
      expect(card.attributes("aria-label")).toBe(facts.label);
      expect(card.get(".im-fwd-card__title").text()).toBe(facts.title);
      expect(card.find(".im-fwd-card__sub").exists() ? card.get(".im-fwd-card__sub").text() : null).toBe(facts.subtitle);
      expect(card.findAll(".im-fwd-card__line").map((line) => ({
        sender: line.get(".im-fwd-card__sender").text().replace(/:$/, ""),
        text: line.get(".im-fwd-card__snippet").text(),
      }))).toEqual(facts.previews);
      expect(card.find(".im-fwd-card__ellipsis").exists() ? card.get(".im-fwd-card__ellipsis").text() : null).toBe(facts.more);
      expect(card.get(".im-fwd-card__hint").text()).toBe(facts.hint);
    },
  );

  it("draws an unnamed sender's avatar as \"?\" in the drawer, not the first character of \"unknown sender\"", async () => {
    const record = cases.find((v) => v.id === "four-items-one-more")!;
    mountRecord(record.input, "zh-CN");
    await nextTick();
    await host!.get(".im-fwd-card").trigger("click");
    await nextTick();
    const avatars = Array.from(document.body.querySelectorAll(".im-fwd-item__avatar")).map((el) => el.textContent?.trim());
    expect(avatars).toEqual(["林", "?", "周", "林"]);
  });

  it("is inert while its row is in multi-select", async () => {
    const card = cases.find((v) => v.expect.layout === "card")!;
    mountRecord(card.input, "zh-CN", true);
    await nextTick();
    expect(host!.get(".im-fwd-card").attributes("disabled")).toBeDefined();
  });
});
