// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareChatHeader from "./ChatConversationHeader.vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";

let host: ReturnType<typeof mount>;
afterEach(() => { host?.unmount(); });

function mountHeader(props: Record<string, unknown>, slots?: Record<string, () => unknown>) {
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("en-US");
    return () => h(FlareChatHeader as Component, props, slots);
  } }));
  return host.findComponent(FlareChatHeader);
}

describe("FlareChatHeader", () => {
  it("renders title / subtitle / avatar / presence from props like the native kits", () => {
    const header = mountHeader({ title: "Ivy Chen", subtitle: "Design review", presence: "online", avatarUserId: "ivy" });
    expect(header.find(".im-chat-header__title").text()).toBe("Ivy Chen");
    const subtitle = header.find(".im-chat-header__subtitle");
    expect(subtitle.text()).toBe("Design review");
    expect(subtitle.classes()).toContain("im-chat-header__subtitle--online");
    const avatar = header.findComponent(FlareAvatar);
    expect(avatar.props("userId")).toBe("ivy");
    expect(avatar.props("presence")).toBe("online");
    expect(avatar.find(".im-avatar__status").attributes("data-presence")).toBe("online");
  });

  it("shows trailing actions only for events the host listens to, with stable emits", async () => {
    const header = mountHeader({ title: "Ivy", onSearch: () => {}, onDetails: () => {} });
    expect(header.find('[aria-label="Search messages"]').exists()).toBe(true);
    expect(header.find('[aria-label="Details"]').exists()).toBe(true);
    expect(header.find('[aria-label="Call"]').exists()).toBe(false);
    await header.find('[aria-label="Search messages"]').trigger("click");
    await header.find('[aria-label="Details"]').trigger("click");
    expect(header.emitted("search")).toHaveLength(1);
    expect(header.emitted("details")).toHaveLength(1);
    expect(header.emitted("call")).toBeUndefined();
  });

  it("emits call and hides the back button by default", async () => {
    const header = mountHeader({ title: "Ivy", onCall: () => {} });
    expect(header.find(".im-chat-header__back").exists()).toBe(false);
    await header.find('[aria-label="Call"]').trigger("click");
    expect(header.emitted("call")).toHaveLength(1);
  });

  it("honours showBack and the deprecated back alias", async () => {
    const header = mountHeader({ showBack: true });
    await header.find(".im-chat-header__back").trigger("click");
    expect(header.emitted("back")).toHaveLength(1);
    host.unmount();
    const legacy = mountHeader({ back: true });
    expect(legacy.find(".im-chat-header__back").exists()).toBe(true);
  });

  it("lets slots override the default identity and actions", () => {
    const header = mountHeader(
      { title: "Ignored", onSearch: () => {} },
      { identity: () => h("b", { class: "custom-idy" }, "Custom"), actions: () => h("i", { class: "custom-act" }) },
    );
    expect(header.find(".custom-idy").exists()).toBe(true);
    expect(header.find(".im-chat-header__title").exists()).toBe(false);
    expect(header.find(".custom-act").exists()).toBe(true);
    expect(header.find('[aria-label="Search messages"]').exists()).toBe(false);
  });
});
