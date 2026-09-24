// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { flareRememberSearch } from "../../shared/contracts/search-panel";
import FlareRecentSearches from "./FlareRecentSearches.vue";

function mountRecent(items: string[]) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareRecentSearches as Component, { items });
    },
  }));
  return host.findComponent(FlareRecentSearches);
}

describe("FlareRecentSearches", () => {
  it("is a named section of terms with one way to forget them, and reports what was picked", async () => {
    const recent = mountRecent(["周屿", "发版协调"]);
    const section = recent.get("section");
    expect(recent.get(`#${section.attributes("aria-labelledby")}`).text()).toBe("最近搜索");
    expect(recent.findAll(".flare-recent-searches__term").map((term) => term.text())).toEqual(["周屿", "发版协调"]);
    await recent.findAll(".flare-recent-searches__term")[1].trigger("click");
    expect(recent.emitted("pick")).toEqual([["发版协调"]]);
    const clear = recent.get(".flare-recent-searches__head button");
    expect(clear.text()).toBe("清除");
    expect(clear.attributes("aria-label")).toBe("清除最近搜索");
    await clear.trigger("click");
    expect(recent.emitted("clear")).toHaveLength(1);
  });

  it("draws nothing without items, so the page's idle line shows instead", () => {
    expect(mountRecent([]).find("section").exists()).toBe(false);
  });
});

describe("flareRememberSearch", () => {
  it("keeps the newest first, moves a repeat to the front, trims, and forgets past the limit", () => {
    expect(flareRememberSearch(["a", "b"], "  c ")).toEqual(["c", "a", "b"]);
    expect(flareRememberSearch(["a", "b", "c"], "b")).toEqual(["b", "a", "c"]);
    expect(flareRememberSearch(["a", "b"], "   ")).toEqual(["a", "b"]);
    expect(flareRememberSearch(["a", "b", "c"], "d", 3)).toEqual(["d", "a", "b"]);
  });
});
