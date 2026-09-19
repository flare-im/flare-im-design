// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareWorkspaceFrame from "./FlareWorkspaceFrame.vue";
import type { FlareWorkspaceState } from "../../shared/contracts/application";

// DoD 18 — the frame that carries contacts, settings, search and media used to
// forward straight to the layout with no state at all. Same matrix as the
// Flutter / Compose / iOS suites.
function setup(state: FlareWorkspaceState, listeners: Record<string, unknown> = {}) {
  return mount(FlareWorkspaceFrame, {
    // No shell and no measured width: the frame lays out as a desktop.
    props: { hasDetail: true, state, ...listeners },
    slots: {
      primary: '<p class="primary">primary content</p>',
      default: '<p class="content">content pane</p>',
      detail: '<p class="detail">detail content</p>',
    },
  });
}

describe("FlareWorkspaceFrame", () => {
  it("shows the host content in all three panes when ready", () => {
    const wrapper = setup({});
    expect(wrapper.find(".primary").exists()).toBe(true);
    expect(wrapper.find(".content").exists()).toBe(true);
    expect(wrapper.find(".detail").exists()).toBe(true);
  });

  it("announces a loading pane instead of leaving it blank", () => {
    const wrapper = setup({ content: { status: "loading" } });
    expect(wrapper.find(".content").exists()).toBe(false);
    const live = wrapper.get('[role="status"]');
    expect(live.attributes("aria-live")).toBe("polite");
    // Generic copy: this frame is not only the inbox.
    expect(live.text()).not.toContain("会话");
  });

  it("explains an empty pane and offers the next step the host can service", async () => {
    const silent = setup({ content: { status: "empty", message: "还没有设备", actionLabel: "添加设备" } });
    expect(silent.text()).toContain("还没有设备");
    expect(silent.find("button").exists()).toBe(false);

    const wrapper = setup(
      { content: { status: "empty", message: "还没有设备", description: "在手机上登录后会出现在这里", actionLabel: "添加设备" } },
      { onEmptyAction: () => {} },
    );
    expect(wrapper.text()).toContain("在手机上登录后会出现在这里");
    await wrapper.get("button").trigger("click");
    expect(wrapper.emitted("emptyAction")?.[0]).toEqual(["content"]);
  });

  it("names a failure and offers a labelled retry", async () => {
    const wrapper = setup(
      { content: { status: "failure", message: "网络不可用", actionLabel: "重试" } },
      { onRetry: () => {} },
    );
    const alert = wrapper.get('[role="alert"]');
    expect(alert.text()).toContain("网络不可用");
    await alert.get("button").trigger("click");
    expect(wrapper.emitted("retry")?.[0]).toEqual(["content"]);
  });

  it("keeps the banner above panes that still read fine", async () => {
    const wrapper = setup(
      { banner: { tone: "warning", message: "当前处于离线状态", actionLabel: "重新连接" } },
      { onBannerAction: () => {} },
    );
    expect(wrapper.text()).toContain("当前处于离线状态");
    expect(wrapper.find(".content").exists()).toBe(true);
    await wrapper.get(".flare-workspace-frame__banner button").trigger("click");
    expect(wrapper.emitted("bannerAction")).toHaveLength(1);
  });

  it("keeps panes independent: one failure never blanks the others", () => {
    const wrapper = setup({ primary: { status: "failure", message: "列表加载失败" }, detail: { status: "empty" } });
    expect(wrapper.text()).toContain("列表加载失败");
    expect(wrapper.find(".content").exists()).toBe(true);
    expect(wrapper.find(".detail").exists()).toBe(false);
  });
});
