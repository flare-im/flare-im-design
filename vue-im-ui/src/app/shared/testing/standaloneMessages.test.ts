import { describe, expect, it } from "vitest";
import { createSSRApp, h, type Component } from "vue";
import { renderToString } from "@vue/server-renderer";

// Import the components directly (not via the full barrel, which pulls in
// SDK-coupled modules unresolvable in the test env). Barrel-export correctness
// is covered by `vue-tsc`, which type-checks index.ts.
import FlareTextMessage from "../../../components/messages/standalone/FlareTextMessage.vue";
import FlareImageMessage from "../../../components/messages/standalone/FlareImageMessage.vue";
import FlareVideoMessage from "../../../components/messages/standalone/FlareVideoMessage.vue";
import FlareVoiceMessage from "../../../components/messages/standalone/FlareVoiceMessage.vue";
import FlareFileMessage from "../../../components/messages/standalone/FlareFileMessage.vue";
import FlareLocationMessage from "../../../components/messages/standalone/FlareLocationMessage.vue";
import FlareContactMessage from "../../../components/messages/standalone/FlareContactMessage.vue";
import FlareLinkCardMessage from "../../../components/messages/standalone/FlareLinkCardMessage.vue";
import FlareVoteMessage from "../../../components/messages/standalone/FlareVoteMessage.vue";
import FlareTaskMessage from "../../../components/messages/standalone/FlareTaskMessage.vue";
import FlareStickerMessage from "../../../components/messages/standalone/FlareStickerMessage.vue";
import FlareEmojiMessage from "../../../components/messages/standalone/FlareEmojiMessage.vue";
import FlareSystemMessage from "../../../components/messages/standalone/FlareSystemMessage.vue";

const render = (c: Component, props: Record<string, unknown> = {}) =>
  renderToString(createSSRApp({ render: () => h(c, props) }));

describe("standalone per-type message components", () => {
  it("all 13 are exported from the package barrel", () => {
    for (const c of [
      FlareTextMessage, FlareImageMessage, FlareVideoMessage, FlareVoiceMessage,
      FlareFileMessage, FlareLocationMessage, FlareContactMessage, FlareLinkCardMessage,
      FlareVoteMessage, FlareTaskMessage, FlareStickerMessage, FlareEmojiMessage,
      FlareSystemMessage,
    ]) {
      expect(c).toBeTruthy();
    }
  });

  it("text renders its body and linkifies a bare URL", async () => {
    const html = await render(FlareTextMessage, { text: "see flare.im now" });
    expect(html).toContain("see");
    expect(html).toContain("<a");
  });

  it("file shows name / size / ext", async () => {
    const html = await render(FlareFileMessage, { name: "spec.pdf", size: "2.4 MB", ext: "PDF" });
    expect(html).toContain("spec.pdf");
    expect(html).toContain("2.4 MB");
    expect(html).toContain("PDF");
  });

  it("location shows title and address", async () => {
    const html = await render(FlareLocationMessage, { title: "HQ", address: "Beijing" });
    expect(html).toContain("HQ");
    expect(html).toContain("Beijing");
  });

  it("contact derives initials from the name", async () => {
    const html = await render(FlareContactMessage, { name: "Ivy Chen", subtitle: "@ivy" });
    expect(html).toContain("IC");
    expect(html).toContain("Ivy Chen");
  });

  it("vote renders each option with its percentage", async () => {
    const html = await render(FlareVoteMessage, {
      title: "When?",
      options: [{ text: "Thu", pct: 62 }, { text: "Fri", pct: 38 }],
    });
    expect(html).toContain("Thu");
    expect(html).toContain("62%");
    expect(html).toContain("Fri");
  });

  it("task strikes through the title when done", async () => {
    const html = await render(FlareTaskMessage, { title: "Sync notes", done: true });
    expect(html).toContain("Sync notes");
    expect(html).toContain("done");
  });

  it("sticker / emoji render their glyph", async () => {
    expect(await render(FlareStickerMessage, { emoji: "🐱" })).toContain("🐱");
    expect(await render(FlareEmojiMessage, { emoji: "🎉" })).toContain("🎉");
  });

  it("system renders its text", async () => {
    expect(await render(FlareSystemMessage, { text: "recalled a message" })).toContain(
      "recalled a message",
    );
  });

  it("media bodies mount without an SDK/media resolver", async () => {
    // the point of the standalone layer: no SDK coupling
    expect(await render(FlareImageMessage)).toContain("<svg");
    expect(await render(FlareVideoMessage, { duration: "00:42" })).toContain("00:42");
    expect(await render(FlareVoiceMessage, { seconds: 7 })).toContain("7");
  });
});
