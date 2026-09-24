// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, ref } from "vue";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { setFlareRuntimeLocale } from "../../shared/i18n/messages";
import FlareInviteCodeField from "./FlareInviteCodeField.vue";

type Props = Partial<InstanceType<typeof FlareInviteCodeField>["$props"]>;

function mountField(initial: Props = {}, locale = "en-US") {
  const value = ref(initial.modelValue ?? "");
  const state = ref<Props>({ ...initial });
  const checks: string[] = [];
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () =>
        h(FlareInviteCodeField, {
          ...state.value,
          modelValue: value.value,
          "onUpdate:modelValue": (next: string) => { value.value = next; },
          onCheck: (code: string) => { checks.push(code); },
        });
    },
  }));
  return { host, value, state, checks, field: () => host.findComponent(FlareInviteCodeField) };
}

async function type(host: ReturnType<typeof mount>, text: string) {
  const input = host.get("input");
  (input.element as HTMLInputElement).value = text;
  await input.trigger("input");
  await nextTick();
}

describe("FlareInviteCodeField", () => {
  beforeEach(() => { vi.useFakeTimers(); });
  afterEach(() => { vi.useRealTimers(); });

  it("renders nothing at all in off mode", () => {
    const { host } = mountField({ mode: "off", modelValue: "AB12CD" });
    expect(host.find("input").exists()).toBe(false);
    expect(host.text()).toBe("");
  });

  it("is optional by default and required in required mode", () => {
    const optional = mountField({ mode: "optional" });
    expect(optional.host.get("input").attributes("aria-required")).toBeUndefined();
    expect(optional.host.text()).toContain("Optional");
    const required = mountField({ mode: "required" });
    expect(required.host.get("input").attributes("aria-required")).toBe("true");
    expect(required.host.get("label").text()).toContain("*");
  });

  it("normalizes what is typed the way the server reads it and caps at the length", async () => {
    const { host, value } = mountField();
    await type(host, " ab-o1 li9z ");
    expect(value.value).toBe("AB0111");
    // A seventh character neither moves the model nor stays in the element.
    await type(host, "AB01117");
    await nextTick();
    expect(value.value).toBe("AB0111");
    expect((host.get("input").element as HTMLInputElement).value).toBe("AB0111");
    expect(host.get(".flare-input__field").classes()).toContain("is-monospace");
  });

  it("asks for one check about 400 ms after a complete code, never for a partial one", async () => {
    const { host, checks } = mountField();
    await type(host, "AB1");
    vi.advanceTimersByTime(1000);
    expect(checks).toEqual([]);
    await type(host, "AB12C");
    await type(host, "AB12CD");
    vi.advanceTimersByTime(399);
    expect(checks).toEqual([]);
    vi.advanceTimersByTime(1);
    expect(checks).toEqual(["AB12CD"]);
    // Re-typing the same complete code does not ask again.
    await type(host, "AB12CD");
    vi.advanceTimersByTime(500);
    expect(checks).toEqual(["AB12CD"]);
    // Changing it does.
    await type(host, "AB12CE");
    vi.advanceTimersByTime(400);
    expect(checks).toEqual(["AB12CD", "AB12CE"]);
  });

  it("applies a deep-link prefill once, then checks it like a paste", async () => {
    const { host, value, checks, state } = mountField({ prefill: "ab12cd" });
    await nextTick();
    expect(value.value).toBe("AB12CD");
    expect((host.get("input").element as HTMLInputElement).value).toBe("AB12CD");
    vi.advanceTimersByTime(400);
    expect(checks).toEqual(["AB12CD"]);
    // Clearing afterwards is respected: the prefill is not re-applied.
    await type(host, "");
    state.value = { ...state.value, prefill: "zz99zz" };
    await nextTick();
    expect(value.value).toBe("");
  });

  it("walks the state vector: checking, inviter on valid, kit text on invalid, host error wins", async () => {
    const { host, state, field } = mountField({ modelValue: "AB12CD", checking: true });
    expect(host.get("[role=status]").text()).toBe("Checking invite code…");
    expect(field().classes()).toContain("flare-invite-code--checking");

    state.value = { checking: false, checkResult: { valid: true, inviterDisplayName: "A**n" } };
    await nextTick();
    expect(host.get("[role=status]").text()).toBe("Inviter: A**n");
    expect(field().classes()).toContain("flare-invite-code--valid");

    state.value = { checkResult: { valid: false } };
    await nextTick();
    expect(host.find("[role=status]").exists()).toBe(false);
    expect(host.get(".flare-form-field__error").text()).toBe("Invalid invite code");
    expect(host.get("input").attributes("aria-invalid")).toBe("true");

    state.value = { checkResult: { valid: true, inviterDisplayName: "Ann" }, error: "Please enter your invite code" };
    await nextTick();
    expect(host.get(".flare-form-field__error").text()).toBe("Please enter your invite code");
    expect(host.find("[role=status]").exists()).toBe(false);
  });

  it("does not show a verdict that belongs to another code", async () => {
    const { host, state } = mountField({ modelValue: "AB1", checkResult: { valid: true, inviterDisplayName: "Ann" } });
    expect(host.find("[role=status]").exists()).toBe(false);
    state.value = { checkResult: { valid: false } };
    await nextTick();
    expect(host.find(".flare-form-field__error").exists()).toBe(false);
  });

  it("is inert while disabled and never asks for a check", async () => {
    const { host, checks } = mountField({ modelValue: "AB12CD", disabled: true, error: "boom" });
    expect(host.get("input").attributes("disabled")).toBeDefined();
    vi.advanceTimersByTime(1000);
    expect(checks).toEqual([]);
  });

  it("renders from the runtime locale in a host without a provider", () => {
    setFlareRuntimeLocale("zh-CN");
    const wrapper = mount(FlareInviteCodeField, { props: { modelValue: "", mode: "required" } });
    expect(wrapper.get("label").text()).toContain("邀请码");
  });
});
