// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import MessageMeta from "./MessageMeta.vue";
import MessageStatus from "./MessageStatus.vue";

function mountWithI18n(component: Component, props: Record<string, unknown>) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(component, props);
    },
  }));
  return host.findComponent(component);
}

describe("MessageStatus", () => {
  it("uses one shared compact geometry for delivered and read", () => {
    const delivered = mountWithI18n(MessageStatus, { status: "delivered" });
    const read = mountWithI18n(MessageStatus, { status: "read" });
    expect(delivered.find("svg.message-double-check").exists()).toBe(true);
    expect(read.find("svg.message-double-check").exists()).toBe(true);
    expect(read.attributes("aria-label")).toBe("已读");
  });

  it("emits resend only from the failed control", async () => {
    const wrapper = mountWithI18n(MessageStatus, {
      status: "failed",
      onResend: () => {},
    });
    await wrapper.find("button").trigger("click");
    expect(wrapper.emitted("resend")).toHaveLength(1);
  });

  it("keeps failed passive without a resend listener", () => {
    const wrapper = mountWithI18n(MessageStatus, { status: "failed" });
    expect(wrapper.find("button").exists()).toBe(false);
    expect(wrapper.attributes("aria-label")).toBe("发送失败");
  });

  it("maps the outgoing tone contract to the tokenized CSS class", () => {
    const sent = mountWithI18n(MessageStatus, { status: "sent", tone: "onOutgoing" });
    const read = mountWithI18n(MessageStatus, { status: "read", tone: "onOutgoing" });
    const failed = mountWithI18n(MessageStatus, { status: "failed", tone: "onOutgoing" });

    expect(sent.classes()).toContain("message-status--on-outgoing");
    expect(read.classes()).toContain("message-status--on-outgoing");
    expect(failed.classes()).toContain("message-status--failed");
    expect(sent.classes()).not.toContain("message-status--onOutgoing");
  });
});

describe("MessageMeta", () => {
  it("composes timestamp, edited, ephemeral, and receipt regions", () => {
    const wrapper = mountWithI18n(MessageMeta, {
      timestamp: "14:32",
      edited: true,
      ephemeral: "burnAfterRead",
      status: "read",
    });
    expect(wrapper.text()).toContain("14:32");
    expect(wrapper.text()).toContain("已编辑");
    expect(wrapper.text()).toContain("阅后即焚");
    expect(wrapper.findComponent(MessageStatus).exists()).toBe(true);
  });

  it("does not expose an outgoing receipt when status is absent", () => {
    const wrapper = mountWithI18n(MessageMeta, { timestamp: "14:32" });
    expect(wrapper.findComponent(MessageStatus).exists()).toBe(false);
  });

  it("uses the outgoing metadata color class for time and receipts", () => {
    const wrapper = mountWithI18n(MessageMeta, {
      timestamp: "14:32",
      status: "read",
      tone: "onOutgoing",
    });

    expect(wrapper.classes()).toContain("message-meta-row--on-outgoing");
    expect(wrapper.classes()).not.toContain("message-meta-row--onOutgoing");
    expect(wrapper.findComponent(MessageStatus).classes()).toContain("message-status--on-outgoing");
  });
});
