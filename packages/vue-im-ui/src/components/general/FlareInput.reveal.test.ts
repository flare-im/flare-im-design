// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareInput from "./FlareInput.vue";

// FR-045: a masked field the person can unmask. Five apps each built their own toggle — a checkbox on
// Flutter, an icon button beside the field on Android — with their own words; the field owns it now.
describe("a secure input the person can unmask", () => {
  it("masks until the reveal key is pressed, and names what the key does", async () => {
    const wrapper = mount(FlareInput, { props: { modelValue: "hunter2", secure: true, revealable: true } });
    const field = () => wrapper.get("input.flare-input__el");
    const key = () => wrapper.get("button.flare-input__reveal");

    expect(field().attributes("type")).toBe("password");
    expect(key().attributes("aria-label")).toBe("显示密码");
    expect(key().attributes("aria-pressed")).toBe("false");

    await key().trigger("click");
    expect(field().attributes("type")).toBe("text");
    expect(key().attributes("aria-label")).toBe("隐藏密码");
    expect(key().attributes("aria-pressed")).toBe("true");

    await key().trigger("click");
    expect(field().attributes("type")).toBe("password");
  });

  it("is drawn only for a secure field that asked for it, and never on a disabled one", () => {
    const cases: Array<[Record<string, unknown>, boolean]> = [
      [{ secure: true, revealable: true }, true],
      [{ secure: true }, false],
      [{ revealable: true }, false],
      [{ secure: true, revealable: true, disabled: true }, false],
      [{ secure: true, revealable: true, multiline: true }, false],
    ];
    for (const [props, drawn] of cases) {
      const wrapper = mount(FlareInput, { props: { modelValue: "hunter2", ...props } });
      expect(wrapper.find("button.flare-input__reveal").exists(), JSON.stringify(props)).toBe(drawn);
    }
  });
});
