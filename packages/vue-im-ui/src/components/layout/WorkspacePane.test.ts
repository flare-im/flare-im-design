// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import WorkspacePane from "./WorkspacePane.vue";

// DoD 18 — one pane, four outcomes. These are the rules both
// FlareConversationWorkspace and FlareWorkspaceFrame now inherit.
function setup(props: Record<string, unknown> = {}) {
  return mount(WorkspacePane, {
    props: { emptyText: "Nothing here yet", failureText: "Could not load", loadingText: "Loading", ...props },
    slots: { default: '<p class="host">host content</p>' },
  });
}

describe("WorkspacePane", () => {
  it("renders host content when ready, and for a status it does not know", () => {
    expect(setup({ state: { status: "ready" } }).find(".host").exists()).toBe(true);
    // An unrecognised status must never blank the pane.
    expect(setup({ state: { status: "reticulating" } }).find(".host").exists()).toBe(true);
    expect(setup({ state: undefined }).find(".host").exists()).toBe(true);
  });

  it("announces the skeleton to a screen reader instead of drawing silence", () => {
    const wrapper = setup({ state: { status: "loading" } });
    expect(wrapper.find(".host").exists()).toBe(false);
    const live = wrapper.get('[role="status"]');
    expect(live.attributes("aria-live")).toBe("polite");
    expect(live.text()).toContain("Loading");
  });

  it("falls back to the kit text only when the host left the message blank", () => {
    expect(setup({ state: { status: "empty" } }).text()).toContain("Nothing here yet");
    expect(setup({ state: { status: "empty", message: "No devices" } }).text()).toContain("No devices");
    expect(setup({ state: { status: "empty", message: "   " } }).text()).toContain("Nothing here yet");
  });

  it("offers the empty next step only with a label and a host handler", async () => {
    const withoutHandler = setup({ state: { status: "empty", actionLabel: "Add a device" } });
    expect(withoutHandler.text()).not.toContain("Add a device");

    const wrapper = setup({ state: { status: "empty", actionLabel: "Add a device", description: "Sign in on your phone" }, hasEmptyAction: true });
    expect(wrapper.text()).toContain("Sign in on your phone");
    const button = wrapper.get("button");
    expect(button.text()).toContain("Add a device");
    await button.trigger("click");
    expect(wrapper.emitted("emptyAction")).toHaveLength(1);
  });

  it("reports a failure as an alert and only offers retry the host can service", async () => {
    const noLabel = setup({ state: { status: "failure", message: "Network down" }, hasRetry: true });
    expect(noLabel.get('[role="alert"]').text()).toContain("Network down");
    expect(noLabel.find("button").exists()).toBe(false);

    const wrapper = setup({ state: { status: "failure", message: "Network down", actionLabel: "Retry" }, hasRetry: true });
    await wrapper.get("button").trigger("click");
    expect(wrapper.emitted("retry")).toHaveLength(1);
  });
});
