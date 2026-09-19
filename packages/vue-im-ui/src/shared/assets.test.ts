import { afterEach, describe, expect, it } from "vitest";
import { flareAssetUrl, setFlareAssetBaseUrl } from "./assets";

describe("kit asset base", () => {
  afterEach(() => setFlareAssetBaseUrl(undefined));

  it("serves from /flare-im-ui-assets by default", () => {
    expect(flareAssetUrl("emoji/grinning_face.webp")).toBe("/flare-im-ui-assets/emoji/grinning_face.webp");
  });

  it("follows a sub-path or CDN base set by the host", () => {
    setFlareAssetBaseUrl("/app/flare-im-ui-assets/");
    expect(flareAssetUrl("/stickers/classic/a.webp")).toBe("/app/flare-im-ui-assets/stickers/classic/a.webp");
    setFlareAssetBaseUrl("https://cdn.example.com/kit");
    expect(flareAssetUrl("emoji/x.webp")).toBe("https://cdn.example.com/kit/emoji/x.webp");
  });
});
