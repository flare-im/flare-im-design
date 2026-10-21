// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, reactive, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import FlareRedPacketPayConfirm from "./FlareRedPacketPayConfirm.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => {
  host?.unmount();
  host = undefined;
  document.body.innerHTML = "";
  document.body.style.overflow = "";
});

function mountPay(props: Record<string, unknown> = {}, bottomSheet = true) {
  const state = reactive<Record<string, unknown>>({
    open: true,
    amount: "¥5.00",
    methodLabel: "钱包（余额 ¥12.00）",
    ...props,
  });
  const events: string[] = [];
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      useFlarePlatformProvider({ capabilities: { bottomSheet } });
      return () => h(FlareRedPacketPayConfirm as Component, {
        ...state,
        onConfirm: () => events.push("confirm"),
        onCancel: () => events.push("cancel"),
      });
    },
  }), { attachTo: document.body });
  return { state, events };
}

const surface = () => document.body.querySelector<HTMLElement>('[role="dialog"]')!;
const buttons = () => Array.from(surface().querySelectorAll<HTMLButtonElement>(".flare-rp-pay__actions button"));

describe("FlareRedPacketPayConfirm", () => {
  it("is a bottom panel on the phone form factor with the amount large and the method row", async () => {
    mountPay();
    await nextTick();
    expect(surface().dataset.flarePresentation).toBe("sheet");
    expect(surface().getAttribute("aria-label")).toBe("确认付款");
    expect(surface().querySelector(".flare-rp-pay__amount")!.textContent).toBe("¥5.00");
    expect(surface().querySelector(".flare-rp-pay__method")!.textContent).toContain("支付方式");
    expect(surface().querySelector(".flare-rp-pay__method-value")!.textContent).toBe("钱包（余额 ¥12.00）");
    expect(buttons().map((b) => b.textContent?.trim())).toEqual(["确认支付", "取消"]);
  });

  it("hands the same content to a centered modal elsewhere", async () => {
    mountPay({}, false);
    await nextTick();
    expect(surface().dataset.flarePresentation).toBe("dialog");
    expect(surface().querySelector(".flare-rp-pay__amount")!.textContent).toBe("¥5.00");
  });

  it("confirms and cancels", async () => {
    const { events } = mountPay();
    await nextTick();
    buttons()[0].click();
    buttons()[1].click();
    surface().parentElement!.click();
    expect(events).toEqual(["confirm", "cancel", "cancel"]);
  });

  it("cannot confirm with an insufficient balance and says why", async () => {
    const { events } = mountPay({ insufficient: true });
    await nextTick();
    expect(buttons()[0].disabled).toBe(true);
    expect(surface().querySelector('[role="alert"]')!.textContent).toBe("余额不足");
    buttons()[0].click();
    expect(events).toEqual([]);
  });

  it("locks every way out while the payment is in flight", async () => {
    const { events } = mountPay({ busy: true });
    await nextTick();
    expect(buttons().every((b) => b.disabled)).toBe(true);
    expect(buttons()[0].getAttribute("aria-busy")).toBe("true");
    surface().parentElement!.click();
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
    expect(events).toEqual([]);
  });

  it("does not show the insufficient notice when the balance covers it", async () => {
    mountPay();
    await nextTick();
    expect(surface().querySelector('[role="alert"]')).toBeNull();
  });
});
