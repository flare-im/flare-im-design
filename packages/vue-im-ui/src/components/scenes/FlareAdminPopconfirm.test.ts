// @vitest-environment happy-dom
import { mount, flushPromises } from "@vue/test-utils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { NPopconfirm, NInput } from "naive-ui";
import FlareAdminPopconfirm from "./FlareAdminPopconfirm.vue";

const hosts: ReturnType<typeof mount>[] = [];
afterEach(() => {
  hosts.splice(0).forEach((host) => host.unmount());
  document.body.innerHTML = "";
  vi.restoreAllMocks();
});
async function setup(extra = {}, container = document.body) {
  const button = document.createElement("button");
  button.textContent = "Suspend";
  container.append(button);
  vi.spyOn(button, "getBoundingClientRect").mockReturnValue(
    new DOMRect(120, 100, 80, 32),
  );
  const host = mount(FlareAdminPopconfirm, {
    attachTo: document.body,
    props: {
      open: false,
      requestKey: 1,
      title: "Suspend application",
      description: "Check this operation",
      target: "Org · App (201)",
      ...extra,
    },
  });
  hosts.push(host);
  button.click();
  await host.setProps({ open: true });
  await flushPromises();
  return { host, button, native: host.findComponent(NPopconfirm) };
}
describe("FlareAdminPopconfirm", () => {
  it("uses real native Popconfirm at the invoking button, with compact native controls and no scrim", async () => {
    const { host, native } = await setup();
    expect(native.props("trigger")).toBe("manual");
    expect(native.props("show")).toBe(true);
    expect(native.props("y")).toBe(132);
    expect(native.props("positiveButtonProps")).toMatchObject({
      size: "small",
      type: "error",
    });
    expect(
      document.querySelector(".flare-admin-popconfirm")?.textContent,
    ).toContain("Org · App (201)");
    expect(document.querySelector(".flare-overlay-scrim")).toBeNull();
    expect(host.emitted("confirm")).toBeUndefined();
    native.props("onPositiveClick")!(new MouseEvent("click"));
    expect(host.emitted("confirm")?.[0]).toEqual([{ reason: "" }, 1]);
  });
  it("outside click and cancel only emit cancellation for the owned generation", async () => {
    const { host, native } = await setup();
    native.props("onClickoutside")!(new MouseEvent("click"));
    expect(host.emitted("cancel")).toEqual([[1]]);
    expect(host.emitted("confirm")).toBeUndefined();
  });
  it("busy prevents dismissing or double dispatch, and keeps native loading feedback", async () => {
    const { host, native } = await setup();
    await host.setProps({ busy: true });
    native.props("onPositiveClick")!(new MouseEvent("click"));
    native.props("onNegativeClick")!(new MouseEvent("click"));
    expect(host.emitted("confirm")).toBeUndefined();
    expect(host.emitted("cancel")).toBeUndefined();
    expect(native.props("positiveButtonProps")).toMatchObject({
      loading: true,
      disabled: true,
    });
    expect(native.props("negativeButtonProps")).toMatchObject({
      disabled: true,
    });
  });
  it("keeps reason, UTF-8 and length validation, and resets only for a new question", async () => {
    const { host, native } = await setup({
      reason: { label: "Audit reason", maxLength: 200, maxBytes: 6 },
    });
    expect(native.props("positiveButtonProps")!.disabled).toBe(true);
    const input = host.findComponent(NInput);
    input.vm.$emit("update:value", "汉汉汉");
    await flushPromises();
    expect(native.props("positiveButtonProps")!.disabled).toBe(true);
    native.props("onPositiveClick")!(new MouseEvent("click"));
    expect(host.emitted("confirm")).toBeUndefined();
    input.vm.$emit("update:value", "  audit  ");
    await host.setProps({ error: "Check and retry" });
    expect(input.props("value")).toBe("  audit  ");
    native.props("onPositiveClick")!(new MouseEvent("click"));
    expect(host.emitted("confirm")?.[0]).toEqual([{ reason: "audit" }, 1]);
    await host.setProps({ requestKey: 2 });
    await flushPromises();
    expect(input.props("value")).toBe("");
  });
  it("consumes Escape before an underlying drawer and restores focus after cancellation", async () => {
    const drawer = document.createElement("section");
    drawer.dataset.flarePresentation = "drawer";
    document.body.append(drawer);
    const bubble = vi.fn();
    document.addEventListener("keydown", bubble);
    const { host, button, native } = await setup({}, drawer);
    expect(native.props("to")).toBe(drawer);
    const focused = document.activeElement;
    expect(
      document.querySelector(".flare-admin-popconfirm")?.contains(focused),
    ).toBe(true);
    focused!.dispatchEvent(
      new KeyboardEvent("keydown", {
        key: "Escape",
        bubbles: true,
        cancelable: true,
      }),
    );
    expect(host.emitted("cancel")).toEqual([[1]]);
    expect(bubble).not.toHaveBeenCalled();
    await host.setProps({ open: false });
    expect(document.activeElement).toBe(button);
    document.removeEventListener("keydown", bubble);
  });
  it("does not confirm when an anchor disappears and closes only while idle", async () => {
    const { host, button } = await setup();
    button.remove();
    window.dispatchEvent(new Event("resize"));
    expect(host.emitted("cancel")).toEqual([[1]]);
    expect(host.emitted("confirm")).toBeUndefined();
  });
  it("removes capture listeners on disposal rather than intercepting later drawer Escape", async () => {
    const { host } = await setup();
    host.unmount();
    hosts.pop();
    const event = new KeyboardEvent("keydown", {
      key: "Escape",
      bubbles: true,
      cancelable: true,
    });
    document.dispatchEvent(event);
    expect(event.defaultPrevented).toBe(false);
  });
  it("allows an optional empty reason and tags late native callbacks with their original generation", async () => {
    const { host, native } = await setup({
      reason: { label: "Optional reason", optional: true },
    });
    const oldPositive = native.props("onPositiveClick")!;
    const oldNegative = native.props("onNegativeClick")!;
    await host.setProps({ requestKey: 2 });
    await flushPromises();
    oldPositive(new MouseEvent("click"));
    oldNegative(new MouseEvent("click"));
    expect(host.emitted("confirm")?.[0]).toEqual([{ reason: "" }, 1]);
    expect(host.emitted("cancel")?.[0]).toEqual([1]);
    native.props("onPositiveClick")!(new MouseEvent("click"));
    expect(host.emitted("confirm")?.[1]).toEqual([{ reason: "" }, 2]);
  });
  it("keeps a pending confirmation visible if its trigger disappears, without emitting a replay", async () => {
    const { host, button, native } = await setup();
    await host.setProps({ busy: true });
    button.remove();
    window.dispatchEvent(new Event("resize"));
    native.props("onClickoutside")!(new MouseEvent("click"));
    document.dispatchEvent(
      new KeyboardEvent("keydown", {
        key: "Escape",
        bubbles: true,
        cancelable: true,
      }),
    );
    expect(native.props("show")).toBe(true);
    expect(host.emitted("confirm")).toBeUndefined();
    expect(host.emitted("cancel")).toBeUndefined();
  });
  it("does not consume Escape from a separate newer drawer while this write is pending", async () => {
    const { host } = await setup();
    await host.setProps({ busy: true });
    const later = document.createElement("section");
    later.dataset.flarePresentation = "drawer";
    const field = document.createElement("input");
    later.append(field);
    document.body.append(later);
    field.focus();
    const event = new KeyboardEvent("keydown", {
      key: "Escape",
      bubbles: true,
      cancelable: true,
    });
    field.dispatchEvent(event);
    expect(event.defaultPrevented).toBe(false);
    expect(host.emitted("cancel")).toBeUndefined();
    expect(host.emitted("confirm")).toBeUndefined();
  });
});
