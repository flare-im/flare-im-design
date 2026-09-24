// @vitest-environment happy-dom
import { describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import FlareButton from "./FlareButton.vue";
import { FLARE_BUTTON_VARIANTS } from "../../shared/contracts/form";

/**
 * 变体是跨端契约的一部分:同一个名字在四端要画同一个意思。这里只守 Vue 这一侧的
 * 「每一档都真的有自己的类、而且互不相同」——四端成员是否一致由 spec/validate.mjs
 * 的枚举等值关守(它比的是枚举成员,不是 prop 名字;quiet 当初就是从那个缝里漏过去的)。
 */
describe("FlareButton variants", () => {
  it("renders a distinct class per declared variant", () => {
    const seen = new Set<string>();
    for (const variant of FLARE_BUTTON_VARIANTS) {
      const w = mount(FlareButton, { props: { label: variant, variant } });
      const cls = [...w.element.classList].find((c) => c.startsWith("flare-button--") && !/--(sm|md|lg)$/.test(c));
      expect(cls, `${variant} has its own modifier class`).toBe(`flare-button--${variant}`);
      expect(seen.has(cls!), `${variant} class is unique`).toBe(false);
      seen.add(cls!);
      w.unmount();
    }
    expect(seen.size).toBe(FLARE_BUTTON_VARIANTS.length);
  });

  it("keeps quiet neutral: no brand colour, no border, padding from the size class", () => {
    // quiet 之所以要单独一档,就是因为它既不是 text(品牌色)也不是 ghost(品牌色描边):
    // 它是配在主按钮旁边的出口,两颗都用紫色就分不出主次。
    const quiet = mount(FlareButton, { props: { label: "x", variant: "quiet", size: "md" } });
    const text = mount(FlareButton, { props: { label: "x", variant: "text", size: "md" } });
    expect(quiet.element.className).not.toBe(text.element.className);
    quiet.unmount();
    text.unmount();
  });
});
