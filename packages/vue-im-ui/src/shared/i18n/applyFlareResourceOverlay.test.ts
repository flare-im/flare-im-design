// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { computed, defineComponent, h, nextTick } from "vue";
import {
  COMPOSER_EMOJI_ITEMS,
  clearComposerEmojiAssetRegistrations,
  hasEmojiPackAssetKey,
  resolveEmojiPackAssetUrlByKey,
} from "../../components/composer/ComposerEmojiStickerPopover/composerEmojiAssets";
import {
  COMPOSER_STICKER_PACKS,
  clearComposerStickerPackRegistrations,
} from "../../components/composer/ComposerEmojiStickerPopover/composerStickers";
import { createNaiveThemeOverrides } from "../../design-system/theme/im-theme";
import { flareColorVariable, setFlareResourceColors } from "../../design-system/theme/resource-colors";
import { applyFlareResourceOverlay } from "./applyFlareResourceOverlay";
import { flareMessages, listFlareLocales, registerFlareMessages, resolveFlareMessage } from "./messages";
import { useFlareI18n, useFlareI18nOptional, useFlareI18nProvider } from "./useFlareI18n";

const SCHEMA = "flare.resource.v1";
const strings = (locales: Record<string, Record<string, unknown>>) => ({
  id: "strings",
  kind: "strings",
  packVersion: 1,
  contentJson: JSON.stringify({ schema: SCHEMA, kind: "strings", locales }),
});
const tokens = (content: Record<string, unknown>) => ({
  id: "tokens",
  kind: "tokens",
  packVersion: 1,
  contentJson: JSON.stringify({ schema: SCHEMA, kind: "tokens", ...content }),
});
const emoji = (packs: unknown[]) => ({
  id: "emoji",
  kind: "emoji",
  packVersion: 1,
  contentJson: JSON.stringify({ schema: SCHEMA, kind: "emoji", packs }),
});

const stylesheet = () => document.getElementById("flare-resource-overlay")?.textContent ?? "";

beforeEach(() => {
  registerFlareMessages("zh-CN", {
    overlayTest: { hello: "你好 {name}", title: "标题", plural: { other: "{count} 条" } },
  });
  registerFlareMessages("en-US", { overlayTest: { hello: "Hello {name}", title: "Title" } });
});

afterEach(() => {
  delete flareMessages["zh-CN"].overlayTest;
  delete flareMessages["en-US"].overlayTest;
  setFlareResourceColors({ light: {}, dark: {} });
  clearComposerEmojiAssetRegistrations();
  clearComposerStickerPackRegistrations();
});

describe("applyFlareResourceOverlay: copy", () => {
  it("replaces copy in the language each entry is written for", () => {
    const result = applyFlareResourceOverlay([
      strings({ "zh-CN": { "overlayTest.title": "新标题" }, en: { "overlayTest.title": "New title" } }),
    ]);
    expect(resolveFlareMessage("zh-CN", "overlayTest.title")).toBe("新标题");
    expect(resolveFlareMessage("en-US", "overlayTest.title")).toBe("New title");
    expect(result.strings).toBe(2);
  });

  it("leaves out what the rules refuse and keeps the rest", () => {
    applyFlareResourceOverlay([
      strings({
        "zh-CN": {
          "overlayTest.hello": "你好",
          "overlayTest.title": "新标题",
          "overlayTest.missing": "无",
          "overlayTest.plural": "一条",
        },
      }),
    ]);
    expect(resolveFlareMessage("zh-CN", "overlayTest.hello", { name: "A" })).toBe("你好 A");
    expect(resolveFlareMessage("zh-CN", "overlayTest.title")).toBe("新标题");
    expect(resolveFlareMessage("zh-CN", "overlayTest.missing")).toBe("overlayTest.missing");
    expect(resolveFlareMessage("zh-CN", "overlayTest.plural", { count: 3 })).toBe("3 条");
  });

  it("does not make a language out of a pack", () => {
    const before = listFlareLocales();
    applyFlareResourceOverlay([strings({ ja: { "overlayTest.title": "タイトル" } })]);
    expect(listFlareLocales()).toEqual(before);
    expect(resolveFlareMessage("zh-CN", "overlayTest.title")).toBe("标题");
  });

  it("reports a broken pack and does not throw", () => {
    const result = applyFlareResourceOverlay([{ id: "x", kind: "strings", packVersion: 1, contentJson: "{" }]);
    expect(result).toEqual({ strings: 0, colors: 0, emoji: 0, stickerPacks: 0, ignoredPacks: 1 });
  });
});

describe("applyFlareResourceOverlay: what is on screen follows", () => {
  it("re-renders a mounted component that translated through the provider", async () => {
    const Reader = defineComponent({
      setup() {
        const { t } = useFlareI18n();
        const label = computed(() => t("overlayTest.title"));
        return () => h("span", `${t("overlayTest.title")}|${label.value}`);
      },
    });
    const host = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () => h(Reader);
      },
    }));
    expect(host.text()).toBe("标题|标题");

    applyFlareResourceOverlay([strings({ "zh-CN": { "overlayTest.title": "新标题" } })]);
    await nextTick();

    expect(host.text()).toBe("新标题|新标题");
    host.unmount();
  });

  it("re-renders a leaf with no provider above it", async () => {
    const host = mount(defineComponent({
      setup() {
        const { t } = useFlareI18nOptional();
        return () => h("span", t("overlayTest.title"));
      },
    }));
    expect(host.text()).toBe("标题");

    registerFlareMessages("zh-CN", { overlayTest: { title: "新标题" } });
    await nextTick();

    expect(host.text()).toBe("新标题");
    host.unmount();
  });

  it("moves the Naive theme, which reads colours as values", () => {
    const primary = computed(() => createNaiveThemeOverrides("light").common?.primaryColor);
    const builtIn = primary.value;

    applyFlareResourceOverlay([tokens({ colors: { primary: "#112233" } })]);

    expect(primary.value).toBe("#112233");
    expect(primary.value).not.toBe(builtIn);
    expect(createNaiveThemeOverrides("dark").common?.primaryColor).not.toBe("#112233");
  });
});

describe("applyFlareResourceOverlay: colours", () => {
  it("names a colour by its native field and writes the custom property", () => {
    expect(flareColorVariable("primary")).toBe("--flare-color-primary");
    expect(flareColorVariable("messageStatusReadOnOutgoing")).toBe("--flare-color-message-status-read-on-outgoing");
    expect(flareColorVariable("avatarTintBlueBg")).toBe("--flare-color-avatar-tint-blue-bg");
  });

  it("writes light and dark under their own selectors and ignores what is not open", () => {
    const result = applyFlareResourceOverlay([
      tokens({
        colors: { primary: "#112233", nope: "#112233" },
        dark: { bgPrimary: "#44556677" },
        sizes: { spacing: { md: "#000000" } },
      }),
    ]);
    const css = stylesheet();
    expect(css).toContain(':root:not([data-flare-theme="dark"])');
    expect(css).toMatch(/--flare-color-primary: #112233 !important;\n\}\n\[data-flare-theme="dark"\]/);
    expect(css).toContain("--flare-color-bg-primary: #44556677 !important;");
    expect(css).not.toContain("nope");
    expect(css).not.toContain("spacing");
    expect(result.colors).toBe(2);
  });

  it("takes the stylesheet away when nothing is left", () => {
    applyFlareResourceOverlay([tokens({ colors: { primary: "#112233" } })]);
    expect(stylesheet()).not.toBe("");
    applyFlareResourceOverlay([]);
    expect(document.getElementById("flare-resource-overlay")).toBeNull();
  });
});

describe("applyFlareResourceOverlay: emoji", () => {
  it("adds to the catalog and leaves what ships with the kit alone", async () => {
    const alienBefore = await resolveEmojiPackAssetUrlByKey("alien");
    const result = applyFlareResourceOverlay([
      emoji([
        {
          id: "acme",
          title: "Acme",
          stickers: [{ stickerId: "wave", url: "https://cdn.example/wave.webp" }],
          emoji: [
            { key: "acme_wave", url: "https://cdn.example/e.webp" },
            { key: "alien", url: "https://cdn.example/alien.webp" },
          ],
        },
        { id: "classic", title: "Mine", stickers: [{ stickerId: "001", url: "https://cdn.example/s.webp" }] },
      ]),
    ]);

    expect(result.emoji).toBe(1);
    expect(result.stickerPacks).toBe(1);
    expect(hasEmojiPackAssetKey("acme_wave")).toBe(true);
    expect(await resolveEmojiPackAssetUrlByKey("alien")).toBe(alienBefore);
    expect(COMPOSER_EMOJI_ITEMS.filter((item) => item.key === "alien")).toHaveLength(1);
    expect(COMPOSER_STICKER_PACKS.find((pack) => pack.packageId === "acme")?.items.map((item) => item.stickerId)).toEqual(["wave"]);
    expect(COMPOSER_STICKER_PACKS.find((pack) => pack.packageId === "classic")?.title).toBe("Classic");
  });
});
