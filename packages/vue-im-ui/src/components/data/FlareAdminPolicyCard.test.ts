// @vitest-environment happy-dom
import { afterEach, describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { h } from "vue";
import { NButton, NCard, NSwitch } from "naive-ui";
import cardSource from "./FlareAdminPolicyCard.vue?raw";
import gridSource from "./FlareAdminCardGrid.vue?raw";
import FlareAdminPolicyCard from "./FlareAdminPolicyCard.vue";
import FlareAdminCardGrid from "./FlareAdminCardGrid.vue";

const hosts: ReturnType<typeof mount>[] = [];
afterEach(() => hosts.splice(0).forEach((host) => host.unmount()));
describe("compact administrative cards", () => {
  it("uses genuine Naive Card and keeps the host title, value, source and actions without description prose", async () => {
    const edit = vi.fn(),
      toggle = vi.fn();
    const host = mount(FlareAdminPolicyCard, {
      props: {
        title: "Open registration",
        density: "compact",
        description: "Registration policy details",
        source: "Inherited",
        sourceDetail: "Scheduled",
      },
      slots: {
        control: () =>
          h(NSwitch, {
            value: true,
            disabled: true,
            "aria-label": "Open registration",
            "onUpdate:value": toggle,
          }),
        actions: () =>
          h(NButton, { size: "small", onClick: edit }, () => "Edit"),
      },
    });
    hosts.push(host);
    expect(host.findComponent(NCard).exists()).toBe(true);
    expect(host.attributes("aria-label")).toBe("Open registration");
    expect(host.get("h3").attributes("title")).toBe(
      "Registration policy details",
    );
    expect(host.find(".flare-admin-policy-card__description").exists()).toBe(
      false,
    );
    expect(host.text()).toContain("Inherited");
    expect(host.text()).toContain("Scheduled");
    expect(host.findComponent(NSwitch).props("value")).toBe(true);
    await host.findComponent(NSwitch).trigger("click");
    expect(toggle).not.toHaveBeenCalled();
    await host.findComponent(NButton).trigger("click");
    expect(edit).toHaveBeenCalledOnce();
  });
  it("keeps regular descriptions and paused state explicit for existing consumers", () => {
    const host = mount(FlareAdminPolicyCard, {
      props: {
        title: "Notification",
        description: "Visible help",
        paused: true,
        sourceDetail: "Paused",
      },
    });
    hosts.push(host);
    expect(host.get(".flare-admin-policy-card__description").text()).toBe(
      "Visible help",
    );
    expect(host.classes()).toContain("flare-admin-policy-card--paused");
    expect(host.text()).toContain("Paused");
  });
  it("does not invent an action, switch, footer or write when only a title is given", () => {
    const host = mount(FlareAdminPolicyCard, {
      props: { title: "Read only", density: "compact" },
    });
    hosts.push(host);
    expect(host.find("footer").exists()).toBe(false);
    expect(host.findComponent(NButton).exists()).toBe(false);
    expect(host.findComponent(NSwitch).exists()).toBe(false);
    expect(host.emitted()).toEqual({});
  });
  it("composes cards in an adaptive compact grid, with no duplicate controls", () => {
    const host = mount(FlareAdminCardGrid, {
      props: { density: "compact" },
      slots: {
        default: () => [
          h(FlareAdminPolicyCard, { title: "One", density: "compact" }),
          h(FlareAdminPolicyCard, { title: "Two", density: "compact" }),
        ],
      },
    });
    hosts.push(host);
    expect(host.classes()).toContain("flare-admin-card-grid--compact");
    expect(host.findAllComponents(NCard)).toHaveLength(2);
    expect(host.findAll("h3").map((node) => node.text())).toEqual([
      "One",
      "Two",
    ]);
  });
  it("keeps long labels wrapping and grid columns bounded by the available width", () => {
    const card = cardSource;
    const grid = gridSource;
    expect(card).toContain("overflow-wrap: anywhere");
    expect(card).toContain("max-width: 60%");
    expect(card).toContain("min-height: 32px");
    expect(grid).toContain("repeat(auto-fill, minmax(min(100%, 260px), 1fr))");
  });
});
