// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, nextTick, reactive } from "vue";
import {
  NButton,
  NCard,
  NDatePicker,
  NFormItem,
  NInput,
  NModal,
} from "naive-ui";
import FlareAdminModal from "./FlareAdminModal.vue";
import FlareAdminForm from "./FlareAdminForm.vue";
import FlareDrawer from "../general/FlareDrawer.vue";
import FlareAdminPopconfirm from "../scenes/FlareAdminPopconfirm.vue";

const hosts: ReturnType<typeof mount>[] = [];
const settle = async () => {
  await nextTick();
  await nextTick();
};
afterEach(() => {
  hosts.splice(0).forEach((host) => host.unmount());
  vi.restoreAllMocks();
});
describe("FlareAdminModal", () => {
  it("renders genuine Naive Modal/Card with the shared draft body and compact footer", async () => {
    const write = vi.fn();
    const host = mount(FlareAdminModal, {
      attachTo: document.body,
      props: { open: true, title: "Edit role", width: "600px" },
      slots: {
        default: () =>
          h(FlareAdminForm, { onSubmit: write }, () =>
            h(NFormItem, { label: "Name" }, () =>
              h(NInput, { value: "Unsaved role" }),
            ),
          ),
        footer: () =>
          h(NButton, { size: "small", disabled: true }, () => "Save"),
      },
    });
    hosts.push(host);
    await settle();
    expect(host.findComponent(NModal).exists()).toBe(true);
    expect(host.findComponent(NCard).exists()).toBe(true);
    const surface = document.querySelector<HTMLElement>(
      '[role="dialog"][aria-label="Edit role"]',
    )!;
    expect(surface).not.toBeNull();
    expect(surface.querySelector<HTMLInputElement>("input")?.value).toBe(
      "Unsaved role",
    );
    expect(
      surface
        .querySelector(".flare-admin-modal__footer button")
        ?.hasAttribute("disabled"),
    ).toBe(true);
    expect(document.activeElement).toBe(surface.querySelector("input"));
    expect(write).not.toHaveBeenCalled();
    expect(host.findComponent(NModal).props("trapFocus")).toBe(false); // Kit is the single stack owner.
  });
  it("keeps all close paths controlled and blocked while the host owns a write", async () => {
    const close = vi.fn();
    const host = mount(FlareAdminModal, {
      attachTo: document.body,
      props: { open: true, title: "Busy", dismissible: false, onClose: close },
      slots: { default: () => h(NInput, { value: "Keep me" }) },
    });
    hosts.push(host);
    await settle();
    host.findComponent(NModal).vm.$emit("update:show", false);
    document
      .querySelector(".flare-admin-modal input")!
      .dispatchEvent(
        new KeyboardEvent("keydown", { key: "Escape", bubbles: true }),
      );
    expect(close).not.toHaveBeenCalled();
    expect(host.findComponent(NModal).props("maskClosable")).toBe(false);
    expect(
      document
        .querySelector(".flare-admin-modal__header-actions button")
        ?.hasAttribute("disabled"),
    ).toBe(true);
    await host.setProps({ dismissible: true });
    host.findComponent(NModal).vm.$emit("update:show", false);
    expect(close).toHaveBeenCalledOnce();
  });
  it("closes only an edit modal above a detail drawer and returns focus to its opener", async () => {
    const state = reactive({ editing: false });
    const parentClose = vi.fn(),
      modalClose = vi.fn();
    const host = mount(
      defineComponent({
        setup: () => () => [
          h(
            FlareDrawer,
            { open: true, title: "User details", onClose: parentClose },
            () =>
              h(
                NButton,
                {
                  onClick: () => {
                    state.editing = true;
                  },
                },
                () => "Edit",
              ),
          ),
          h(
            FlareAdminModal,
            {
              open: state.editing,
              title: "Edit user",
              onClose: () => {
                modalClose();
                state.editing = false;
              },
            },
            () => h(NInput, { value: "Unsaved" }),
          ),
        ],
      }),
      { attachTo: document.body },
    );
    hosts.push(host);
    await settle();
    const opener = document.querySelector<HTMLButtonElement>(
      '[aria-label="User details"] .n-button',
    )!;
    opener.focus();
    opener.click();
    await settle();
    const input = document.querySelector<HTMLInputElement>(
      '[aria-label="Edit user"] input',
    )!;
    input.focus();
    input.dispatchEvent(
      new KeyboardEvent("keydown", {
        key: "Escape",
        bubbles: true,
        cancelable: true,
      }),
    );
    await settle();
    expect(modalClose).toHaveBeenCalledOnce();
    expect(parentClose).not.toHaveBeenCalled();
    expect(document.activeElement).toBe(opener);
    expect(document.body.style.overflow).toBe("hidden");
  });
  it("keeps native picker Escape in the modal instead of discarding the form", async () => {
    const close = vi.fn(),
      write = vi.fn(),
      popup = reactive({ open: true });
    const host = mount(FlareAdminModal, {
      attachTo: document.body,
      props: { open: true, title: "Schedule", onClose: close },
      slots: {
        default: () =>
          h(FlareAdminForm, {}, () =>
            h(NDatePicker, {
              show: popup.open,
              "onUpdate:show": (v: boolean) => {
                popup.open = v;
              },
              "onUpdate:value": write,
            }),
          ),
      },
    });
    hosts.push(host);
    await settle();
    const input = document.querySelector<HTMLInputElement>(
      '[aria-label="Schedule"] .n-date-picker input',
    )!;
    input.dispatchEvent(
      new KeyboardEvent("keydown", {
        key: "Escape",
        bubbles: true,
        cancelable: true,
      }),
    );
    expect(popup.open).toBe(false);
    expect(close).not.toHaveBeenCalled();
    expect(write).not.toHaveBeenCalled();
  });
  it("lets Popconfirm consume Escape without closing or submitting the underlying edit", async () => {
    const state = reactive({ confirm: false });
    const close = vi.fn(),
      write = vi.fn();
    const host = mount(
      defineComponent({
        setup: () => () => [
          h(
            FlareAdminModal,
            { open: true, title: "Edit", onClose: close },
            () =>
              h(
                NButton,
                {
                  onClick: () => {
                    state.confirm = true;
                  },
                },
                () => "Save",
              ),
          ),
          h(FlareAdminPopconfirm, {
            open: state.confirm,
            title: "Confirm",
            description: "Review",
            onConfirm: write,
            onCancel: () => {
              state.confirm = false;
            },
          }),
        ],
      }),
      { attachTo: document.body },
    );
    hosts.push(host);
    await settle();
    const save = document.querySelector<HTMLButtonElement>(
      ".flare-admin-modal__body button",
    )!;
    vi.spyOn(save, "getBoundingClientRect").mockReturnValue(
      new DOMRect(100, 100, 60, 32),
    );
    save.focus();
    save.click();
    await settle();
    const panel = document.querySelector<HTMLElement>(
      ".flare-admin-popconfirm",
    )!;
    expect(panel).not.toBeNull();
    panel.querySelector<HTMLButtonElement>("button")?.focus();
    panel.dispatchEvent(
      new KeyboardEvent("keydown", {
        key: "Escape",
        bubbles: true,
        cancelable: true,
      }),
    );
    await settle();
    expect(state.confirm).toBe(false);
    expect(close).not.toHaveBeenCalled();
    expect(write).not.toHaveBeenCalled();
  });
  it("resolves width presets, and an explicit width still wins", async () => {
    const host = mount(FlareAdminModal, {
      attachTo: document.body,
      props: { open: true, title: "Access point", size: "wide" },
      slots: { default: () => h(NInput, { value: "" }) },
    });
    hosts.push(host);
    await settle();
    const surface = () =>
      document.querySelector<HTMLElement>('[aria-label="Access point"]')!;
    expect(surface().style.getPropertyValue("--flare-admin-modal-width")).toBe(
      "920px",
    );
    await host.setProps({ size: "small" });
    expect(surface().style.getPropertyValue("--flare-admin-modal-width")).toBe(
      "480px",
    );
    await host.setProps({ width: "640px" });
    expect(surface().style.getPropertyValue("--flare-admin-modal-width")).toBe(
      "640px",
    );
  });
});
