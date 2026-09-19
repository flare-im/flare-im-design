// @vitest-environment happy-dom
import { afterEach, describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import ConversationHeader from "./ConversationHeader.vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";

let host: ReturnType<typeof mount>;
afterEach(() => {
  host?.unmount();
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

function mountHeader(props: Record<string, unknown>) {
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("en-US");
      return () => h(ConversationHeader as Component, props);
    },
  }), { attachTo: document.body });
  return host.findComponent(ConversationHeader);
}

describe("FlareConversationHeader", () => {
  it.each([true, false])("measures the stable outer width (borderBoxSize: %s)", async (hasBorderBoxSize) => {
    let notify: ResizeObserverCallback;
    const observe = vi.fn();
    const disconnect = vi.fn();
    vi.stubGlobal("ResizeObserver", class {
      constructor(callback: ResizeObserverCallback) { notify = callback; }
      observe = observe;
      disconnect = disconnect;
    });
    const header = mountHeader({ identity: { id: "ivy", title: "Ivy Chen", kind: "direct" } });
    expect(observe).toHaveBeenCalledWith(header.element, { box: "border-box" });
    let outerWidth = 586;
    vi.spyOn(header.element, "getBoundingClientRect").mockImplementation(() => new DOMRect(0, 0, outerWidth, 65));
    const resize = async (contentWidth: number) => {
      notify!([{
        target: header.element,
        contentRect: new DOMRect(0, 0, contentWidth, 65),
        borderBoxSize: hasBorderBoxSize ? [{ inlineSize: outerWidth, blockSize: 65 }] : [],
        contentBoxSize: [{ inlineSize: contentWidth, blockSize: 65 }],
        devicePixelContentBoxSize: [],
      }], {} as ResizeObserver);
      await nextTick();
    };
    for (const contentWidth of [554, 570, 554, 570]) {
      await resize(contentWidth);
      expect(header.classes()).not.toContain("flare-conversation-header--compact");
    }
    outerWidth = 559;
    await resize(543);
    expect(header.classes()).toContain("flare-conversation-header--compact");
  });

  it("renders an opinionated identity with avatar and semantic subtitle", () => {
    const header = mountHeader({
      identity: { id: "ivy", title: "Ivy Chen", kind: "direct", presence: "online" },
    });
    expect(header.get("h2").text()).toBe("Ivy Chen");
    expect(header.get("p").text()).toBe("Online");
    expect(header.findComponent(FlareAvatar).props()).toMatchObject({ userId: "ivy", presence: "online" });
  });

  it("shows default primary, Plus, and More actions", () => {
    const header = mountHeader({ identity: { id: "room", title: "Product room", kind: "group" } });
    expect(header.find('[data-header-action="search"]').exists()).toBe(true);
    expect(header.find('[data-header-menu="add"]').exists()).toBe(true);
    // Details is the only overflow action by default, so the More button opens it directly.
    expect(header.find('[data-header-menu="more"]').exists()).toBe(false);
    expect(header.get('[data-header-action="details"]').attributes("aria-label")).toBe("Details");
  });

  it("keeps a More menu when more than one action overflows", async () => {
    const header = mountHeader({
      identity: { id: "room", title: "Product room", kind: "group" },
      actions: [{ id: "report", label: "Report", icon: "report", placement: "overflow" }],
    });
    expect(header.find('[data-header-action="details"]').exists()).toBe(false);
    const more = header.get('[data-header-menu="more"]');
    await more.trigger("click");
    await nextTick();
    expect(document.body.textContent).toContain("Report");
    expect(document.body.textContent).toContain("Details");
  });

  it("emits the sole overflow action from the More button", async () => {
    const header = mountHeader({ identity: { id: "room", title: "Product room", kind: "group" } });
    await header.get('[data-header-action="details"]').trigger("click");
    expect(header.emitted("action")?.[0]?.[0]).toMatchObject({ id: "details" });
  });

  it("makes the whole identity block the target of a capability-filtered identity action", async () => {
    const header = mountHeader({
      identity: {
        id: "ivy",
        title: "Ivy Chen",
        presence: "online",
        action: { id: "profile", label: "Open profile", icon: "person" },
      },
      capabilities: { availableActionIds: ["profile"] },
    });
    const identity = header.get('[data-header-action="identity"]');
    expect(identity.element.tagName).toBe("BUTTON");
    expect(identity.attributes("aria-label")).toBe("Ivy Chen, Open profile");
    expect(identity.findComponent(FlareAvatar).exists()).toBe(true);
    expect(identity.text()).toContain("Ivy Chen");
    expect(identity.text()).toContain("Online");
    await identity.trigger("click");
    expect(header.emitted("action")?.[0]?.[0]).toMatchObject({ id: "profile" });
    const filtered = mountHeader({
      identity: { id: "ivy", title: "Ivy Chen", action: { id: "profile", label: "Open profile" } },
      capabilities: { availableActionIds: ["search"] },
    });
    expect(filtered.find('[data-header-action="identity"]').exists()).toBe(false);
    expect(filtered.get("h2").text()).toBe("Ivy Chen");
  });

  it("renders toggle actions with their pressed state", () => {
    const header = mountHeader({
      identity: { id: "room", title: "Product room", kind: "group" },
      capabilities: { availableActionIds: ["search", "details"] },
      actions: [
        { id: "search", label: "Search messages", icon: "search", placement: "primary", pressed: true },
        { id: "details", label: "Conversation details", icon: "info", placement: "primary", pressed: false },
      ],
    });
    const search = header.get('[data-header-action="search"]');
    expect(search.attributes("aria-pressed")).toBe("true");
    expect(search.classes()).toContain("is-pressed");
    expect(header.get('[data-header-action="details"]').attributes("aria-pressed")).toBe("false");
  });

  it("honours capability filtering, hidden actions, and disabled custom actions", () => {
    const header = mountHeader({
      identity: { id: "room", title: "Product room", kind: "group" },
      capabilities: { availableActionIds: ["search", "share", "details", "task"] },
      actions: [
        { id: "search", label: "Find", visible: false },
        { id: "task", label: "Create task", icon: "check", enabled: false, disabledReason: "Read only", order: 1 },
      ],
    });
    expect(header.find('[data-header-action="search"]').exists()).toBe(false);
    const task = header.get('[data-header-action="task"]');
    expect(task.attributes("disabled")).toBeDefined();
    expect(task.attributes("aria-label")).toContain("Read only");
    expect(header.find('[data-header-action="audioCall"]').exists()).toBe(false);
  });

  it("emits the resolved action and restores menu trigger focus when closed", async () => {
    const header = mountHeader({
      identity: { id: "room", title: "Product room", kind: "group" },
      capabilities: { availableActionIds: ["search", "addMember", "details"] },
    });
    await header.get('[data-header-action="search"]').trigger("click");
    expect(header.emitted("action")?.[0]?.[0]).toMatchObject({ id: "search" });

    const add = header.get<HTMLButtonElement>('[data-header-menu="add"]');
    await add.trigger("click");
    await nextTick();
    expect(document.body.textContent).toContain("Add member");
    await add.trigger("click");
    await nextTick();
    expect(document.activeElement).toBe(add.element);
  });

  it("hides the back button by default and emits back when shown", async () => {
    const plain = mountHeader({ identity: { id: "ivy", title: "Ivy Chen", kind: "direct" } });
    expect(plain.find("[aria-label='Back']").exists()).toBe(false);
    host.unmount();
    const withBack = mountHeader({ identity: { id: "ivy", title: "Ivy Chen", kind: "direct" }, showBack: true });
    await withBack.get("[aria-label='Back']").trigger("click");
    expect(withBack.emitted("back")).toHaveLength(1);
  });
});
