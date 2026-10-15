// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, nextTick, ref, type Component } from "vue";
import { mount } from "@vue/test-utils";
import { FlareDangerConfirm, FlareDrawer, FlareUiProvider } from "../../admin";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => {
  host?.unmount();
  host = undefined;
  document.body.innerHTML = "";
});
async function setup() {
  const open = ref(false),
    drawer = ref(true);
  host = mount(
    defineComponent({
      setup() {
        return () =>
          h(
            FlareUiProvider as Component,
            { locale: "zh-CN" },
            {
              default: () => [
                h(
                  FlareDrawer as Component,
                  {
                    open: drawer.value,
                    title: "Review request",
                    onClose: () => {
                      drawer.value = false;
                    },
                  },
                  {
                    default: () =>
                      h(
                        "button",
                        {
                          class: "review-trigger",
                          onClick: () => {
                            open.value = true;
                          },
                        },
                        "Review",
                      ),
                  },
                ),
                h(FlareDangerConfirm as Component, {
                  open: open.value,
                  title: "Confirm review",
                  description: "Controlled test only",
                  target: "Request A",
                  onCancel: () => {
                    open.value = false;
                  },
                }),
              ],
            },
          );
      },
    }),
    { attachTo: document.body },
  );
  await nextTick();
  document.querySelector<HTMLButtonElement>(".review-trigger")!.click();
  await nextTick();
  await nextTick();
  return { open, drawer };
}
describe("public admin drawer and confirmation share one modal stack", () => {
  it("does not intercept Tab in the middle of the top confirmation", async () => {
    await setup();
    const modal = document.querySelector<HTMLElement>(
      '[data-flare-presentation="dialog"]',
    )!;
    const cancel = modal.querySelector<HTMLButtonElement>(
      ".flare-danger-confirm__actions button",
    )!;
    cancel.focus();
    const event = new KeyboardEvent("keydown", {
      key: "Tab",
      bubbles: true,
      cancelable: true,
    });
    cancel.dispatchEvent(event);
    expect(event.defaultPrevented).toBe(false);
    expect(modal.contains(document.activeElement)).toBe(true);
  });
  it("wraps only the top confirmation and restores the drawer trigger after cancel", async () => {
    const state = await setup(),
      modal = document.querySelector<HTMLElement>(
        '[data-flare-presentation="dialog"]',
      )!;
    const keys = modal.querySelectorAll<HTMLButtonElement>(
      ".flare-danger-confirm__actions button",
    );
    keys[1].focus();
    const event = new KeyboardEvent("keydown", {
      key: "Tab",
      bubbles: true,
      cancelable: true,
    });
    keys[1].dispatchEvent(event);
    expect(event.defaultPrevented).toBe(true);
    expect(modal.contains(document.activeElement)).toBe(true);
    keys[0].click();
    await nextTick();
    await nextTick();
    expect(state.open.value).toBe(false);
    expect(state.drawer.value).toBe(true);
    expect(document.activeElement?.className).toBe("review-trigger");
  });
  it("Escape cancels the confirmation without also closing its underlying drawer", async () => {
    const state = await setup();
    document.dispatchEvent(
      new KeyboardEvent("keydown", {
        key: "Escape",
        bubbles: true,
        cancelable: true,
      }),
    );
    await nextTick();
    expect(state.open.value).toBe(false);
    expect(state.drawer.value).toBe(true);
  });
});
