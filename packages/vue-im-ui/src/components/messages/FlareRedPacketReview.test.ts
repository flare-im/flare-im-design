// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareRedPacketReview from "./FlareRedPacketReview.vue";

function render(props: Record<string, unknown>, locale: "zh-CN" | "en-US" = "zh-CN") {
  const submits: number[] = [];
  const wrapper = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareRedPacketReview, { amount: "¥26.64", ...props, onSubmit: () => submits.push(1) });
    },
  }));
  return { wrapper, submits };
}

describe("FlareRedPacketReview", () => {
  it("draws the arch, the total, the kind line and the greeting, and sends with the red key", async () => {
    const { wrapper, submits } = render({ kindLabel: "拼手气红包 · 3 个", blessing: "恭喜发财，大吉大利" });
    expect(wrapper.find(".flare-packet-arch.is-compact").exists()).toBe(true);
    expect(wrapper.get("[data-review-amount]").text()).toBe("¥26.64");
    expect(wrapper.get(".flare-rp-review__kind").text()).toBe("拼手气红包 · 3 个");
    expect(wrapper.get(".flare-rp-review__blessing").text()).toBe("恭喜发财，大吉大利");
    const key = wrapper.get("[data-review-submit]");
    expect(key.text()).toBe("发红包");
    await key.trigger("click");
    expect(submits).toEqual([1]);
  });

  it("draws nothing for an absent kind line or greeting and localizes the key", () => {
    const { wrapper } = render({}, "en-US");
    expect(wrapper.find(".flare-rp-review__kind").exists()).toBe(false);
    expect(wrapper.find(".flare-rp-review__blessing").exists()).toBe(false);
    expect(wrapper.get("[data-review-submit]").text()).toBe("Send");
    expect(render({ submitLabel: "Pay" }).wrapper.get("[data-review-submit]").text()).toBe("Pay");
  });

  it("spins and locks while busy, and shows a failure above the key", async () => {
    const { wrapper, submits } = render({ busy: true, error: "余额不足" });
    const key = wrapper.get("[data-review-submit]");
    expect(key.attributes("disabled")).toBeDefined();
    expect(key.attributes("aria-busy")).toBe("true");
    await key.trigger("click");
    expect(submits).toEqual([]);
    const alert = wrapper.get('[role="alert"]');
    expect(alert.text()).toBe("余额不足");
    expect(alert.element.compareDocumentPosition(key.element) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
  });
});
