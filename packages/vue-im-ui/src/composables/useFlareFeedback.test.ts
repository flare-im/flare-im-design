// @vitest-environment happy-dom
import { flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import FlareUiProvider from "../design-system/provider/FlareUiProvider.vue";
import { createFlareFeedback, FLARE_TOAST_LIMIT, useFlareConfirm, useFlareToast } from "./useFlareFeedback";

afterEach(() => vi.useRealTimers());

describe("a caught error is a toast by itself", () => {
  it("reads as danger with the error's own words (FR-067)", () => {
    const feedback = createFlareFeedback();
    feedback.toast(new Error("网络连接已断开"));
    expect(feedback.toasts.value).toMatchObject([{ message: "网络连接已断开", tone: "danger" }]);
  });

  it("still takes a string or options unchanged", () => {
    const feedback = createFlareFeedback();
    feedback.toast("已复制");
    feedback.toast({ message: "已发送", tone: "success" });
    expect(feedback.toasts.value.map((t) => [t.message, t.tone])).toEqual([["已复制", "info"], ["已发送", "success"]]);
  });
});

describe("confirm presenter", () => {
  it("resolves true on accept and false on cancel", async () => {
    const feedback = createFlareFeedback();
    const accepted = feedback.confirm({ title: "Delete", description: "Gone for good" });
    await feedback.accept();
    expect(await accepted).toBe(true);
    const cancelled = feedback.confirm({ title: "Delete", description: "Gone for good" });
    feedback.cancel();
    expect(await cancelled).toBe(false);
    expect(feedback.confirmRequest.value).toBeNull();
  });

  it("keeps the dialog open with the error when the action fails, then retries", async () => {
    const feedback = createFlareFeedback();
    const action = vi.fn().mockRejectedValueOnce(new Error("network down")).mockResolvedValueOnce(undefined);
    const result = feedback.confirm({ title: "Recall", description: "Recall for everyone", action });
    await feedback.accept();
    expect(feedback.confirmRequest.value).toMatchObject({ busy: false, error: "network down" });
    await feedback.accept();
    expect(await result).toBe(true);
    expect(action).toHaveBeenCalledTimes(2);
  });

  it("does not let a second request replace a running action", async () => {
    const feedback = createFlareFeedback();
    let finish = () => {};
    void feedback.confirm({ title: "A", description: "a", action: () => new Promise<void>((resolve) => { finish = resolve; }) });
    const pending = feedback.accept();
    expect(await feedback.confirm({ title: "B", description: "b" })).toBe(false);
    finish();
    await pending;
  });
});

describe("toast presenter", () => {
  it("auto-dismisses, keeps danger longer, and bounds the queue", () => {
    vi.useFakeTimers();
    const feedback = createFlareFeedback();
    feedback.toast("Saved");
    feedback.toast({ message: "Send failed", tone: "danger" });
    vi.advanceTimersByTime(4000);
    expect(feedback.toasts.value.map((entry) => entry.message)).toEqual(["Send failed"]);
    vi.advanceTimersByTime(2000);
    expect(feedback.toasts.value).toHaveLength(0);
    for (let index = 0; index < FLARE_TOAST_LIMIT + 2; index += 1) feedback.toast({ message: `t${index}`, duration: 0 });
    expect(feedback.toasts.value.map((entry) => entry.message)).toEqual(["t2", "t3", "t4"]);
  });

  it("runs a toast action once and removes the toast", () => {
    const feedback = createFlareFeedback();
    const onAction = vi.fn();
    feedback.toast({ message: "Deleted", actionLabel: "Undo", onAction, duration: 0 });
    feedback.runToastAction(feedback.toasts.value[0].id);
    feedback.runToastAction(1);
    expect(onAction).toHaveBeenCalledTimes(1);
    expect(feedback.toasts.value).toHaveLength(0);
  });
});

describe("FlareUiProvider presentation", () => {
  it("renders the requested toast and confirmation for any descendant", async () => {
    let confirm: ReturnType<typeof useFlareConfirm> | undefined;
    let toast: ReturnType<typeof useFlareToast> | undefined;
    const Child = defineComponent({ setup() { confirm = useFlareConfirm(); toast = useFlareToast(); return () => h("div"); } });
    const host = mount(FlareUiProvider, { props: { themeMode: "light", locale: "en-US" }, slots: { default: () => h(Child) }, attachTo: document.body });
    toast?.({ message: "Copied", duration: 0 });
    void confirm?.({ title: "Delete conversation", description: "Messages on this device are removed.", target: "Design Team" });
    await flushPromises();
    expect(host.find(".flare-ui-provider__toasts").text()).toContain("Copied");
    expect(document.body.textContent).toContain("Delete conversation");
    host.unmount();
  });

  it("explains the missing provider instead of failing later", () => {
    const Orphan = defineComponent({ setup() { useFlareToast(); return () => h("div"); } });
    expect(() => mount(Orphan)).toThrow(/FlareUiProvider/);
  });
});
