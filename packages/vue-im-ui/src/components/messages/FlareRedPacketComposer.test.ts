// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, reactive } from "vue";
import { describe, expect, it } from "vitest";
import {
  flareRedPacketAmountMinor,
  sanitizeRedPacketAmount,
  sanitizeRedPacketCount,
  type FlareRedPacketKind,
} from "../../shared/contracts/red-packet";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareRedPacketComposer from "./FlareRedPacketComposer.vue";

interface ComposerVector {
  id: string;
  kinds: FlareRedPacketKind[];
  kind: FlareRedPacketKind;
  amountLabel: "total" | "each" | "amount";
  showsCount: boolean;
  showsRecipient: boolean;
}
const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/red-packet-vectors.json"), "utf8")) as {
  amountInput: { id: string; input: string; output: string }[];
  amountInputExponent: { id: string; exponent: number; input: string; output: string }[];
  amountMinor: { id: string; input: string; exponent: number; minor: string | null }[];
  amountPlaceholder: { cases: { exponent: number; placeholder: string }[] };
  countInput: { id: string; input: string; output: number }[];
  composer: ComposerVector[];
};

interface ComposerModel {
  kinds: FlareRedPacketKind[];
  kind: FlareRedPacketKind;
  amount: string;
  count: number;
  greeting: string;
  total: string;
  error?: string;
  busy?: boolean;
  locked?: boolean;
  submitLabel?: string;
  currencyExponent?: number;
}

function mountComposer(initial: Partial<ComposerModel> = {}, locale: "zh-CN" | "en-US" = "zh-CN") {
  const model = reactive<ComposerModel>({
    kinds: ["lucky", "normal", "exclusive"],
    kind: "lucky",
    amount: "",
    count: 0,
    greeting: "",
    total: "¥0.00",
    ...initial,
  });
  const submits: number[] = [];
  const wrapper = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareRedPacketComposer, {
        kinds: model.kinds,
        total: model.total,
        error: model.error,
        busy: model.busy,
        locked: model.locked,
        submitLabel: model.submitLabel,
        ...(model.currencyExponent === undefined ? {} : { currencyExponent: model.currencyExponent }),
        kind: model.kind,
        "onUpdate:kind": (v: FlareRedPacketKind) => { model.kind = v; },
        amount: model.amount,
        "onUpdate:amount": (v: string) => { model.amount = v; },
        count: model.count,
        "onUpdate:count": (v: number) => { model.count = v; },
        greeting: model.greeting,
        "onUpdate:greeting": (v: string) => { model.greeting = v; },
        onSubmit: () => submits.push(1),
      }, { recipient: () => h("button", { class: "pick-member" }, "选择成员") });
    },
  }));
  return { wrapper, model, submits };
}

const label = (wrapper: ReturnType<typeof mount>, id: string) => wrapper.get(`label[for="${id}"]`).text();

describe("red packet input filters", () => {
  it.each(vectors.amountInput.map((v) => [v.id, v] as const))("amount %s", (_id, v) => {
    expect(sanitizeRedPacketAmount(v.input)).toBe(v.output);
  });
  it.each(vectors.countInput.map((v) => [v.id, v] as const))("count %s", (_id, v) => {
    expect(sanitizeRedPacketCount(v.input)).toBe(v.output);
  });
  it.each(vectors.amountInputExponent.map((v) => [v.id, v] as const))("amount with the currency exponent %s", (_id, v) => {
    expect(sanitizeRedPacketAmount(v.input, v.exponent)).toBe(v.output);
  });
  it.each(vectors.amountMinor.map((v) => [v.id, v] as const))("amount in minor units %s", (_id, v) => {
    expect(flareRedPacketAmountMinor(v.input, v.exponent)).toBe(v.minor);
  });
});

describe("FlareRedPacketComposer currencyExponent", () => {
  it.each(vectors.amountPlaceholder.cases.map((v) => [v.exponent, v] as const))(
    "asks for the currency's decimals at exponent %s",
    async (_exponent, v) => {
      const { wrapper } = mountComposer({ currencyExponent: v.exponent });
      await nextTick();
      const input = wrapper.get(".flare-rp-composer__input");
      expect(input.attributes("placeholder")).toBe(v.placeholder);
      expect(input.attributes("inputmode")).toBe(v.exponent === 0 ? "numeric" : "decimal");
    },
  );

  it("keeps whole numbers for a currency without a minor unit and three decimals for one with three", async () => {
    const { wrapper, model } = mountComposer({ currencyExponent: 0 });
    await nextTick();
    const input = wrapper.get<HTMLInputElement>(".flare-rp-composer__input");
    input.element.value = "12.5";
    await input.trigger("input");
    expect(model.amount).toBe("125");
    expect(input.element.value).toBe("125");

    model.currencyExponent = 3;
    await nextTick();
    input.element.value = "1.23456";
    await input.trigger("input");
    expect(model.amount).toBe("1.234");
  });

  it("trims what was typed when the currency changes to fewer decimals", async () => {
    const { model } = mountComposer({ currencyExponent: 3, amount: "1.234" });
    await nextTick();
    model.currencyExponent = 2;
    await nextTick();
    expect(model.amount).toBe("1.23");
    model.currencyExponent = 0;
    await nextTick();
    expect(model.amount).toBe("123");
  });
});

describe("FlareRedPacketComposer", () => {
  const LABELS = { total: "Total", each: "Amount each", amount: "Amount" } as const;
  it.each(vectors.composer.map((v) => [v.id, v] as const))("follows the shared composer vector %s", async (_id, v) => {
    const { wrapper } = mountComposer({ kinds: v.kinds, kind: v.kind }, "en-US");
    await nextTick();
    const amountId = wrapper.get('input[inputmode="decimal"]').attributes("id")!;
    expect(label(wrapper, amountId)).toBe(LABELS[v.amountLabel]);
    expect(wrapper.find('input[inputmode="numeric"]').exists()).toBe(v.showsCount);
    expect(wrapper.find(".flare-rp-composer__recipient").exists()).toBe(v.showsRecipient);
    expect(wrapper.find('[role="tablist"]').exists()).toBe(v.kinds.length > 1);
  });

  it("relabels the amount per kind and shows count or recipient accordingly", async () => {
    const { wrapper, model } = mountComposer();
    const amountId = wrapper.get('input[inputmode="decimal"]').attributes("id")!;
    expect(label(wrapper, amountId)).toBe("总金额");
    expect(wrapper.find('input[inputmode="numeric"]').exists()).toBe(true);
    expect(wrapper.find(".pick-member").exists()).toBe(false);

    const segments = wrapper.findAll('[role="tab"]');
    expect(segments.map((s) => s.text())).toEqual(["拼手气红包", "普通红包", "专属红包"]);
    await segments[1].trigger("click");
    expect(model.kind).toBe("normal");
    expect(label(wrapper, amountId)).toBe("单个金额");

    await segments[2].trigger("click");
    expect(model.kind).toBe("exclusive");
    expect(label(wrapper, amountId)).toBe("金额");
    expect(wrapper.find('input[inputmode="numeric"]').exists()).toBe(false);
    // A fieldset: a named group, and one switch that locks the host's picker with the form.
    expect(wrapper.get(".flare-rp-composer__recipient").element.tagName).toBe("FIELDSET");
    expect(wrapper.find(".pick-member").exists()).toBe(true);
  });

  it("in a 1:1 chat hides the kind switch and the count, snaps a stale kind and asks for 金额", async () => {
    const { wrapper, model } = mountComposer({ kinds: ["normal"], kind: "lucky" });
    await nextTick();
    expect(wrapper.find('[role="tablist"]').exists()).toBe(false);
    expect(model.kind).toBe("normal");
    expect(label(wrapper, wrapper.get('input[inputmode="decimal"]').attributes("id")!)).toBe("金额");
    expect(wrapper.find('input[inputmode="numeric"]').exists()).toBe(false);
  });

  it("filters the amount as it is typed and writes the filtered text back to the field", async () => {
    const { wrapper, model } = mountComposer({ amount: "8.88" });
    const input = wrapper.get<HTMLInputElement>('input[inputmode="decimal"]');
    input.element.value = "8.88a";
    await input.trigger("input");
    expect(model.amount).toBe("8.88");
    expect(input.element.value).toBe("8.88");
    input.element.value = "12.345";
    await input.trigger("input");
    expect(model.amount).toBe("12.34");
  });

  it("keeps the count numeric and shows an empty field for zero", async () => {
    const { wrapper, model } = mountComposer();
    const input = wrapper.get<HTMLInputElement>('input[inputmode="numeric"]');
    expect(input.element.value).toBe("");
    expect(input.attributes("placeholder")).toBe("填写个数");
    input.element.value = "1x0";
    await input.trigger("input");
    expect(model.count).toBe(10);
    expect(input.element.value).toBe("10");
  });

  it("uses the default greeting as the placeholder and passes the greeting through as typed", async () => {
    const { wrapper, model } = mountComposer();
    const input = wrapper.get<HTMLInputElement>(".flare-rp-composer__greeting");
    expect(input.attributes("placeholder")).toBe("恭喜发财，大吉大利");
    expect(input.attributes("aria-label")).toBe("祝福语");
    input.element.value = "新年快乐";
    await input.trigger("input");
    expect(model.greeting).toBe("新年快乐");
  });

  it("draws the host total and error, and submits through the kit button", async () => {
    const { wrapper, submits } = mountComposer({ total: "¥8.88", error: "单个红包金额不可超过 200 元" });
    expect(wrapper.get(".flare-rp-composer__total").text()).toBe("¥8.88");
    expect(wrapper.get('[role="alert"]').text()).toBe("单个红包金额不可超过 200 元");
    expect(wrapper.get('input[inputmode="decimal"]').attributes("aria-invalid")).toBe("true");
    const button = wrapper.get(".flare-rp-composer__submit button");
    expect(button.text()).toBe("塞钱进红包");
    await button.trigger("click");
    expect(submits).toHaveLength(1);
  });

  it("locks every field and the button while busy", async () => {
    const { wrapper, submits } = mountComposer({ busy: true, submitLabel: "Prepare" });
    expect(wrapper.get("fieldset").attributes("disabled")).toBeDefined();
    const button = wrapper.get(".flare-rp-composer__submit button");
    expect(button.attributes("disabled")).toBeDefined();
    expect(button.attributes("aria-busy")).toBe("true");
    await button.trigger("click");
    expect(submits).toHaveLength(0);
    expect(wrapper.get(".flare-rp-composer").attributes("aria-busy")).toBe("true");
  });

  it("localizes its labels", () => {
    const { wrapper } = mountComposer({}, "en-US");
    expect(wrapper.findAll('[role="tab"]').map((s) => s.text())).toEqual(["Lucky packet", "Red packet", "Exclusive packet"]);
    expect(wrapper.get(".flare-rp-composer__submit button").text()).toBe("Put money in");
    expect(wrapper.get('[role="tablist"]').attributes("aria-label")).toBe("Packet type");
  });

  it("tints the selected kind with the red packet accent, not the brand", () => {
    const { wrapper } = mountComposer();
    const segmented = wrapper.get('[role="tablist"]');
    expect(segmented.attributes("style")).toContain("--flare-segmented-accent: var(--flare-color-red-packet-accent)");
  });

  it("locked: read-only fields, a fixed kind and an inert button, without progress", async () => {
    const { wrapper, model, submits } = mountComposer({ locked: true, kind: "exclusive", amount: "8.88" });
    for (const input of wrapper.findAll("input")) {
      expect(input.attributes("readonly")).toBeDefined();
      expect(input.attributes("disabled")).toBeUndefined();
    }
    expect(wrapper.get(".flare-rp-composer__set").attributes("disabled")).toBeDefined();
    expect(wrapper.get(".flare-rp-composer__recipient").attributes("disabled")).toBeDefined();
    await wrapper.findAll('[role="tab"]')[0].trigger("click");
    expect(model.kind).toBe("exclusive");
    const button = wrapper.get(".flare-rp-composer__submit button");
    expect(button.attributes("disabled")).toBeDefined();
    expect(button.attributes("aria-busy")).toBe("false");
    expect(button.find(".flare-button__spinner").exists()).toBe(false);
    await button.trigger("click");
    expect(submits).toHaveLength(0);
    expect(wrapper.get(".flare-rp-composer").attributes("aria-busy")).toBeUndefined();
  });
});
