// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h } from "vue";
import { mount } from "@vue/test-utils";
import { FLARE_DEFAULT_LOCALE } from "./messages";
import { readStoredLocale, useFlareI18nProvider, type FlareI18nContext } from "./useFlareI18n";

afterEach(() => localStorage.clear());

describe("readStoredLocale", () => {
  it("is the default until the reader chooses", () => {
    expect(readStoredLocale()).toBe(FLARE_DEFAULT_LOCALE);
  });

  it("reads what the provider's setLocale stored", () => {
    let i18n: FlareI18nContext | undefined;
    const view = mount(defineComponent({
      setup() {
        i18n = useFlareI18nProvider("zh-CN");
        return () => h("div");
      },
    }));
    i18n?.setLocale("en-US");
    expect(readStoredLocale()).toBe("en-US");
    view.unmount();
  });

  it("honours a tag only the host registered, and reads blank as the default", () => {
    localStorage.setItem("flare-web-locale", " fr-FR ");
    expect(readStoredLocale()).toBe("fr-FR");
    localStorage.setItem("flare-web-locale", "   ");
    expect(readStoredLocale()).toBe(FLARE_DEFAULT_LOCALE);
  });
});
