// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { describe, expect, it } from "vitest";
import { EllipsisHorizontalOutline } from "../../shared/icon-glyphs";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareIconButton from "./FlareIconButton.vue";

function mountButton(props: Record<string, unknown> = {}) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("en-US");
      return () => h(FlareIconButton as Component, { icon: EllipsisHorizontalOutline, ariaLabel: "More actions", ...props });
    },
  }));
  return host.get("button");
}

describe("FlareIconButton", () => {
  it("draws no dot unless asked", () => {
    const button = mountButton();

    expect(button.find(".flare-icon-button__dot").exists()).toBe(false);
    expect(button.attributes("aria-label")).toBe("More actions");
  });

  it("draws the red dot, and a screen reader hears it with the button's name", () => {
    const button = mountButton({ dot: true });

    expect(button.get(".flare-icon-button__dot").attributes("aria-hidden")).toBe("true");
    expect(button.attributes("aria-label")).toBe("More actions, New");
  });
});
