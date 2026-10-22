// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../../shared/i18n/useFlareI18n";
import FlareLocationMessage from "./FlareLocationMessage.vue";
import FlareContactMessage from "./FlareContactMessage.vue";

const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../../spec/location-vectors.json"), "utf8")) as {
  links: Array<{ id: string; input: { latitude: number; longitude: number; title?: string; provider?: "osm" | "amap" }; web: string | null }>;
};

function render(component: unknown, props: Record<string, unknown>) {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(component as never, props);
    },
  }));
}

describe("FlareLocationMessage", () => {
  it("draws the static map when there is one", () => {
    const card = render(FlareLocationMessage, { latitude: 39.9087, longitude: 116.3975, title: "天安门广场", address: "北京市东城区", snapshotUrl: "https://geo.example/map.png" });
    expect(card.get("img").attributes("src")).toBe("https://geo.example/map.png");
    expect(card.find("[data-placeholder]").exists()).toBe(false);
    expect(card.text()).toContain("天安门广场");
    expect(card.text()).toContain("北京市东城区");
  });

  it("credits OpenStreetMap on its static map, and not AMap's", () => {
    const osm = render(FlareLocationMessage, { latitude: 39.9087, longitude: 116.3975, title: "天安门广场", snapshotUrl: "https://geo.example/map.png", provider: "osm" });
    expect(osm.get("[data-map-attribution]").text()).toBe("© OpenStreetMap contributors");
    const amap = render(FlareLocationMessage, { latitude: 39.9087, longitude: 116.3975, title: "天安门广场", snapshotUrl: "https://geo.example/map.png", provider: "amap" });
    expect(amap.find("[data-map-attribution]").exists()).toBe(false);
    // The drawn texture is not OpenStreetMap data, so it carries no credit.
    const bare = render(FlareLocationMessage, { latitude: 39.9087, longitude: 116.3975, title: "天安门广场", provider: "osm" });
    expect(bare.find("[data-map-attribution]").exists()).toBe(false);
  });

  it("draws the map texture and centre pin without a picture, and when the picture fails", async () => {
    const bare = render(FlareLocationMessage, { latitude: 39.9087, longitude: 116.3975, title: "天安门广场" });
    expect(bare.find("img").exists()).toBe(false);
    expect(bare.find("[data-placeholder] .flare-location-map__pin").exists()).toBe(true);
    // No address: the coordinate line stands in, so the card has no blank second line.
    expect(bare.text()).toContain("39.90870, 116.39750");
    const broken = render(FlareLocationMessage, { latitude: 39.9087, longitude: 116.3975, title: "天安门广场", snapshotUrl: "https://geo.example/404.png" });
    await broken.get("img").trigger("error");
    expect(broken.find("img").exists()).toBe(false);
    expect(broken.find("[data-placeholder]").exists()).toBe(true);
  });

  it.each(vectors.links.map((v) => [v.id, v] as const))("links to the web map by provider: %s", (_, v) => {
    const card = render(FlareLocationMessage, { ...v.input, title: v.input.title ?? "" });
    if (v.web === null) {
      expect(card.find("a").exists()).toBe(false);
      expect(card.get(".fm-loc").attributes("role")).toBe("group");
    } else {
      const link = card.get("a.fm-loc");
      expect(link.attributes("href")).toBe(v.web);
      expect(link.attributes("target")).toBe("_blank");
      expect(link.attributes("rel")).toBe("noopener noreferrer");
    }
  });

  it("is a button that hands the tap to a host that listens", async () => {
    let opened = 0;
    const card = render(FlareLocationMessage, { latitude: 31.2304, longitude: 121.4737, title: "人民广场", provider: "amap", onOpen: () => { opened += 1; } });
    expect(card.find("a").exists()).toBe(false);
    await card.get("button.fm-loc").trigger("click");
    expect(opened).toBe(1);
    expect(card.get("button.fm-loc").attributes("aria-label")).toBe("人民广场, 31.23040, 121.47370");
  });
});

describe("FlareContactMessage", () => {
  it("reports the user id to a host that listens, and only displays otherwise", async () => {
    const ids: string[] = [];
    const card = render(FlareContactMessage, { name: "周屿", subtitle: "产品设计组", userId: "u_4f3a91", onOpen: (id: string) => ids.push(id) });
    await card.get("button.fm-contact").trigger("click");
    expect(ids).toEqual(["u_4f3a91"]);
    expect(card.text()).not.toContain("u_4f3a91");
    const plain = render(FlareContactMessage, { name: "周屿", userId: "u_4f3a91" });
    expect(plain.find("button").exists()).toBe(false);
    expect(plain.find(".chev").exists()).toBe(false);
  });
});
