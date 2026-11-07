// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { h } from "vue";
import { NButton, NConfigProvider } from "naive-ui";
import FlareAdminActions from "./FlareAdminActions.vue";

describe("FlareAdminActions", () => {
  it("groups native buttons without changing permissions, handlers or disabled state", async () => {
    const edit = vi.fn(),
      suspend = vi.fn();
    const host = mount(FlareAdminActions, {
      props: { label: "Application operations" },
      slots: {
        default: () => [
          h(
            NButton,
            { text: true, size: "small", type: "primary", onClick: edit },
            () => "Edit",
          ),
          h(
            NButton,
            {
              text: true,
              size: "small",
              type: "warning",
              disabled: true,
              onClick: suspend,
            },
            () => "Suspend",
          ),
        ],
      },
    });
    expect(edit).not.toHaveBeenCalled();
    expect(suspend).not.toHaveBeenCalled();
    expect(host.attributes("role")).toBe("group");
    expect(host.attributes("aria-label")).toBe("Application operations");
    expect(host.findAllComponents(NButton)).toHaveLength(2);
    await host.findAll("button")[0].trigger("click");
    await host.findAll("button")[1].trigger("click");
    expect(edit).toHaveBeenCalledOnce();
    expect(suspend).not.toHaveBeenCalled();
    host.unmount();
  });
  it("never synthesizes actions, confirmations or a tab stop for empty content", () => {
    const host = mount(FlareAdminActions);
    expect(host.find("button").exists()).toBe(false);
    expect(host.attributes("role")).toBeUndefined();
    expect(host.attributes("tabindex")).toBeUndefined();
    host.unmount();
  });
  it("aligns drawer action groups without adding a second layout or changing handlers", async () => {
    const save = vi.fn();
    const host = mount(FlareAdminActions, {
      props: { justify: "end" },
      slots: {
        default: () =>
          h(NButton, { size: "small", onClick: save }, () => "Save"),
      },
    });
    expect(host.classes()).toContain("flare-admin-actions--end");
    expect(host.findComponent(NButton).props("size")).toBe("small");
    await host.find("button").trigger("click");
    expect(save).toHaveBeenCalledOnce();
    await host.setProps({ justify: "start" });
    expect(host.classes()).not.toContain("flare-admin-actions--end");
    host.unmount();
  });
  it("uses native theme overrides with semantic light/dark text tokens, not a second palette", () => {
    const host = mount(FlareAdminActions);
    const theme = host.findComponent(NConfigProvider).props("themeOverrides")!;
    expect(host.findComponent(NConfigProvider).props("abstract")).toBe(true);
    expect(theme.Button!.textColorTextWarning).toBe(
      "var(--flare-color-warning-text)",
    );
    expect(theme.Button!.textColorTextError).toBe(
      "var(--flare-color-error-text)",
    );
    expect(theme.common).toBeUndefined();
    host.unmount();
  });
});
