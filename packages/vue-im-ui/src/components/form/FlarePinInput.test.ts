// @vitest-environment happy-dom
// Spec PinInput: six cells over one numeric input; typing advances, the sixth digit or Enter when full emits complete,
// paste keeps digits only, Backspace clears the last cell, a new error clears and shakes.
import { enableAutoUnmount, mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, ref } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import FlarePinInput from "./FlarePinInput.vue";

enableAutoUnmount(afterEach);

function render(initial = "", error = false) {
  const value = ref(initial);
  const failed = ref(error);
  const completes: string[] = [];
  const wrapper = mount(defineComponent({
    setup() {
      return () => h(FlarePinInput, {
        modelValue: value.value,
        label: "支付密码",
        error: failed.value,
        "onUpdate:modelValue": (next: string) => { value.value = next; },
        onComplete: (pin: string) => completes.push(pin),
      });
    },
  }), { attachTo: document.body });
  return { wrapper, value, failed, completes, input: () => wrapper.get("input") };
}
const active = (wrapper: ReturnType<typeof render>["wrapper"]) => wrapper.findAll(".flare-pin__cell").findIndex((cell) => cell.classes().includes("is-active"));

describe("FlarePinInput", () => {
  it("is one named numeric field that reads progress, never the digits", () => {
    const { wrapper, input } = render();
    expect(wrapper.findAll(".flare-pin__cell")).toHaveLength(6);
    expect(input().attributes("aria-label")).toBe("支付密码");
    expect(input().attributes("inputmode")).toBe("numeric");
    expect(input().attributes("type")).toBe("password");
    expect(document.activeElement).toBe(input().element);
  });

  it("advances the active cell as digits are typed and emits complete on the sixth", async () => {
    const { wrapper, value, completes, input } = render();
    await input().trigger("focus");
    await input().setValue("12");
    expect(value.value).toBe("12");
    expect(active(wrapper)).toBe(2);
    expect(wrapper.findAll(".flare-pin__dot")).toHaveLength(2);
    expect(completes).toEqual([]);
    await input().setValue("123456");
    expect(completes).toEqual(["123456"]);
    // pinInput.progress: the label and how many digits are in, never the digits.
    const progress = wrapper.get(".flare-pin__progress").text();
    expect(progress).toContain("支付密码");
    expect(progress).toContain("6");
    expect(progress).not.toContain("123456");
  });

  it("keeps digits only from a paste and completes at once", async () => {
    const { value, completes, input } = render();
    await input().setValue("12a3 45-67");
    expect(value.value).toBe("123456");
    expect(completes).toEqual(["123456"]);
  });

  it("clears the last cell on Backspace and completes on Enter only when full", async () => {
    const { wrapper, value, completes, input } = render("123456");
    await input().setValue("12345");
    expect(value.value).toBe("12345");
    expect(wrapper.findAll(".flare-pin__dot")).toHaveLength(5);
    await input().trigger("keydown", { key: "Enter" });
    expect(completes).toEqual([]);
    await input().setValue("123456");
    await input().trigger("keydown", { key: "Enter" });
    expect(completes).toEqual(["123456", "123456"]);
  });

  it("clears the value and shakes once when an error turns on", async () => {
    const { wrapper, value, failed } = render("123456");
    failed.value = true;
    await nextTick();
    expect(value.value).toBe("");
    expect(wrapper.get("[data-pin]").classes()).toContain("is-shaking");
    expect(wrapper.get("input").attributes("aria-invalid")).toBe("true");
  });
});
