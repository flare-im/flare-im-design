// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import SceneList from "./SceneList.vue";
import type { SceneEntry } from "../../shared/contracts/scenes";

// D17 — the scene panels used to draw their own rows, their own spinner and
// their own bordered buttons next to a settings card on the same screen.
const entry = (over: Partial<SceneEntry> = {}): SceneEntry => ({
  id: "d1",
  title: "iPhone 15",
  detail: "Shanghai · last seen 10:24",
  actions: [{ id: "revoke", label: "Sign out", destructive: true }],
  ...over,
});

function setup(props: Record<string, unknown>) {
  return mount(SceneList, { props: { title: "Devices", items: [], ...props } });
}

describe("SceneList", () => {
  it("renders rows through kit buttons, not hand-rolled ones", () => {
    const wrapper = setup({ items: [entry()] });
    const button = wrapper.get("button");
    expect(button.classes().join(" ")).toContain("flare-button");
    expect(button.classes().join(" ")).toContain("flare-button--danger");
    expect(wrapper.text()).toContain("Shanghai · last seen 10:24");
  });

  it("resolves its states through the shared pane: failure outranks loading outranks empty", () => {
    expect(setup({ items: [], loading: true }).find('[role="status"]').exists()).toBe(true);
    expect(setup({ items: [], emptyText: "No devices" }).text()).toContain("No devices");

    const failed = setup({ items: [], loading: false, error: "Network down", retryText: "Retry" });
    const alert = failed.get('[role="alert"]');
    expect(alert.text()).toContain("Network down");
    expect(alert.text()).toContain("Retry");
  });

  it("asks the host to reload from the failure banner", async () => {
    const wrapper = setup({ items: [], error: "Network down", retryText: "Retry" });
    await wrapper.get('[role="alert"] button').trigger("click");
    expect(wrapper.emitted("reload")).toHaveLength(1);
  });

  it("keeps a busy row's actions disabled and reports the row error", () => {
    const wrapper = setup({ items: [entry({ busy: true, error: "Could not sign out" })] });
    expect(wrapper.get("article button").attributes("disabled")).toBeDefined();
    expect(wrapper.get('article [role="alert"]').text()).toContain("Could not sign out");
  });

  it("forwards the action with the row id", async () => {
    const wrapper = setup({ items: [entry()] });
    await wrapper.get("article button").trigger("click");
    expect(wrapper.emitted("action")?.[0]).toEqual([{ id: "d1", action: "revoke" }]);
  });
});
