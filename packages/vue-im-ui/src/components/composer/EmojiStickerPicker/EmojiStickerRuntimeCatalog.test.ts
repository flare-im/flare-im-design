import { afterEach, describe, expect, it } from "vitest";
import {
  COMPOSER_EMOJI_ITEMS,
  clearComposerEmojiAssetRegistrations,
  hasEmojiPackAssetKey,
  registerComposerEmojiAssets,
  resolveEmojiPackAssetUrlByKey,
  resolveEmojiPackPreviewUrlByKey,
} from "../ComposerEmojiStickerPopover/composerEmojiAssets";
import {
  COMPOSER_STICKER_PACKS,
  clearComposerStickerPackRegistrations,
  registerComposerStickerPacks,
  resolveStickerPreviewUrlByPackageAndId,
  resolveStickerUrlByPackageAndId,
} from "../ComposerEmojiStickerPopover/composerStickers";

afterEach(() => {
  clearComposerEmojiAssetRegistrations();
  clearComposerStickerPackRegistrations();
});

describe("runtime emoji and sticker catalog", () => {
  it("adds and overrides user emoji with separate animation and preview sources", async () => {
    registerComposerEmojiAssets([
      { key: "user_wave", url: "https://cdn.example/user-wave.webp", previewUrl: "blob:user-wave-preview" },
      { key: "alien", url: "https://cdn.example/alien.webp", previewUrl: "blob:alien-preview" },
    ]);

    expect(hasEmojiPackAssetKey("user_wave")).toBe(true);
    expect(await resolveEmojiPackAssetUrlByKey("user_wave")).toBe("https://cdn.example/user-wave.webp");
    expect(await resolveEmojiPackPreviewUrlByKey("user_wave")).toBe("blob:user-wave-preview");
    expect(COMPOSER_EMOJI_ITEMS.filter((item) => item.key === "alien")).toHaveLength(1);
  });

  it("adds a complete user sticker pack and keeps its protocol ids", async () => {
    registerComposerStickerPacks([{
      packageId: "my_pack",
      title: "My Pack",
      stickers: [{ stickerId: "party", url: "https://cdn.example/party.webp", previewUrl: "blob:party-preview" }],
    }]);

    expect(COMPOSER_STICKER_PACKS.find((pack) => pack.packageId === "my_pack")?.items.map((item) => item.stickerId)).toEqual(["party"]);
    expect(await resolveStickerUrlByPackageAndId("my_pack", "party")).toBe("https://cdn.example/party.webp");
    expect(await resolveStickerPreviewUrlByPackageAndId("my_pack", "party")).toBe("blob:party-preview");
  });
});
