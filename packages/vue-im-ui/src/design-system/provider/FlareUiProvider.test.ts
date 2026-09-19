// @vitest-environment happy-dom
import { describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, ref } from "vue";
import FlareUiProvider from "./FlareUiProvider.vue";
import { useFlareI18n, useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlareConfig } from "../../shared/useFlareConfig";
import { flareAssetUrl } from "../../shared/assets";

/** Reads what the provider hands down: language, one string, the size default and the theme. */
const Reader = defineComponent({
  setup() {
    const { t, locale } = useFlareI18n();
    const config = useFlareConfig();
    return () => h("span", `${locale.value}|${t("common.retry")}|${config.size.value}|${config.isDark.value ? "dark" : "light"}`);
  },
});

function mountProvider(props: Record<string, unknown>, wrap?: () => void) {
  return mount(defineComponent({
    setup() {
      wrap?.();
      return () => h(FlareUiProvider, props, { default: () => h(Reader) });
    },
  }), { attachTo: document.body });
}

describe("FlareUiProvider", () => {
  it("follows the host's language when the bound locale changes", async () => {
    const locale = ref<"zh-CN" | "en-US">("zh-CN");
    const host = mount(defineComponent({
      setup: () => () => h(FlareUiProvider, { locale: locale.value }, { default: () => h(Reader) }),
    }), { attachTo: document.body });
    expect(host.text()).toContain("zh-CN|重试");
    locale.value = "en-US";
    await host.vm.$nextTick();
    await host.vm.$nextTick();
    expect(host.text()).toContain("en-US|Retry");
    host.unmount();
  });

  it("inherits a language the host already provides instead of resetting it", () => {
    // Without `locale`, a provider under a host i18n context keeps the host's language (§4c).
    const host = mountProvider({}, () => { useFlareI18nProvider("en-US"); });
    expect(host.text()).toContain("en-US|Retry");
    host.unmount();
  });

  it("passes the control size and theme mode down as the config surface", async () => {
    const host = mountProvider({ size: "lg", themeMode: "dark" });
    expect(host.text()).toContain("|lg|dark");
    await host.setProps({});
    host.unmount();
  });

  it("switches the theme through the config surface", async () => {
    const Toggler = defineComponent({
      setup() {
        const config = useFlareConfig();
        return () => h("button", { onClick: () => config.toggleTheme() }, config.isDark.value ? "dark" : "light");
      },
    });
    const host = mount(defineComponent({
      setup: () => () => h(FlareUiProvider, { themeMode: "light" }, { default: () => h(Toggler) }),
    }), { attachTo: document.body });
    expect(host.get("button").text()).toBe("light");
    await host.get("button").trigger("click");
    expect(host.get("button").text()).toBe("dark");
    host.unmount();
  });

  it("sets the asset root for emoji and sticker files", async () => {
    const host = mountProvider({ assetBaseUrl: "/cdn/flare-assets" });
    expect(flareAssetUrl("emoji/smile.webp")).toBe("/cdn/flare-assets/emoji/smile.webp");
    host.unmount();
    const plain = mountProvider({});
    expect(flareAssetUrl("emoji/smile.webp")).toBe("/flare-im-ui-assets/emoji/smile.webp");
    plain.unmount();
  });
});
