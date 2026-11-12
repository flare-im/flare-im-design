// @vitest-environment happy-dom
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, nextTick, type Component } from "vue";
import { mount } from "@vue/test-utils";
import FlareInAppNotificationHost from "./FlareInAppNotificationHost.vue";
import { createFlareInAppNotifications, type FlareInAppNotifications } from "../../composables/useFlareInAppNotifications";
import { IN_APP_NOTIFICATION_DURATION_MS, type FlareInAppNotification } from "../../shared/contracts/in-app-notification";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";

const wrappers: ReturnType<typeof mount>[] = [];

function setup(notifications: FlareInAppNotifications, onOpen = vi.fn(), locale = "en-US") {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareInAppNotificationHost as Component, { notifications, onOpen });
    },
  }), { attachTo: document.body });
  wrappers.push(host);
  return host;
}

const alice: FlareInAppNotification = { collapseId: "c:a", conversationId: "a", messageId: "m1", title: "Alice", body: "are you free?", count: 3, channel: "mentions" };
const bob: FlareInAppNotification = { collapseId: "c:b", conversationId: "b", title: "Bob", body: "lunch", channel: "urgent" };
const banner = () => document.body.querySelector(".flare-in-app-banner") as HTMLElement | null;
const slot = () => document.body.querySelector(".flare-in-app-host__slot") as HTMLElement | null;

beforeEach(() => { vi.useFakeTimers(); });
afterEach(() => {
  wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
  document.body.innerHTML = "";
  vi.useRealTimers();
});

describe("FlareInAppNotificationHost", () => {
  it("shows the banner with its tag and count and announces it once", async () => {
    const notifications = createFlareInAppNotifications();
    setup(notifications);
    notifications.present(alice);
    await nextTick();
    expect(banner()?.textContent).toContain("Alice");
    expect(banner()?.textContent).toContain("[Mention]");
    expect(banner()?.textContent).toContain("[3 messages]");
    expect(banner()?.classList.contains("is-mentions")).toBe(true);
    expect(document.body.querySelector('[role="status"]')?.textContent).toBe("New message, Alice, [Mention], [3 messages], are you free?");
  });

  it("speaks Chinese with the kit's count", async () => {
    const notifications = createFlareInAppNotifications();
    setup(notifications, vi.fn(), "zh-CN");
    notifications.present(alice);
    await nextTick();
    expect(banner()?.textContent).toContain("[有人@我]");
    expect(banner()?.textContent).toContain("[3条]");
  });

  it("dismisses after the kit's time and then shows the next one", async () => {
    const notifications = createFlareInAppNotifications();
    setup(notifications);
    notifications.present(alice);
    notifications.present(bob);
    await nextTick();
    vi.advanceTimersByTime(IN_APP_NOTIFICATION_DURATION_MS - 1);
    expect(notifications.current.value?.collapseId).toBe("c:a");
    vi.advanceTimersByTime(1);
    await nextTick();
    expect(notifications.current.value?.collapseId).toBe("c:b");
  });

  it("starts the time over when the banner is replaced in place", async () => {
    const notifications = createFlareInAppNotifications();
    setup(notifications);
    notifications.present(alice);
    await nextTick();
    vi.advanceTimersByTime(3000);
    notifications.present({ ...alice, body: "still there?", count: 4 });
    await nextTick();
    vi.advanceTimersByTime(3000);
    expect(notifications.current.value?.body).toBe("still there?");
    vi.advanceTimersByTime(1000);
    await nextTick();
    expect(notifications.current.value).toBeNull();
  });

  it("stops the time while the banner is pressed", async () => {
    const notifications = createFlareInAppNotifications();
    setup(notifications);
    notifications.present(alice);
    await nextTick();
    slot()?.dispatchEvent(new Event("pointerdown", { bubbles: true }));
    await nextTick();
    vi.advanceTimersByTime(IN_APP_NOTIFICATION_DURATION_MS * 2);
    expect(notifications.current.value?.collapseId).toBe("c:a");
    slot()?.dispatchEvent(new Event("pointerup", { bubbles: true }));
    await nextTick();
    vi.advanceTimersByTime(IN_APP_NOTIFICATION_DURATION_MS);
    await nextTick();
    expect(notifications.current.value).toBeNull();
  });

  it("opens the conversation and takes the banner away", async () => {
    const onOpen = vi.fn();
    const notifications = createFlareInAppNotifications();
    setup(notifications, onOpen);
    notifications.present(alice);
    await nextTick();
    (document.body.querySelector(".flare-in-app-banner__open") as HTMLElement).click();
    expect(onOpen).toHaveBeenCalledWith("a", "m1");
    expect(notifications.current.value).toBeNull();
  });

  it("dismisses with the close key and with Escape", async () => {
    const notifications = createFlareInAppNotifications();
    setup(notifications);
    notifications.present(alice);
    notifications.present(bob);
    await nextTick();
    (document.body.querySelector(".flare-in-app-banner__close") as HTMLElement).click();
    expect(notifications.current.value?.collapseId).toBe("c:b");
    await nextTick();
    vi.runOnlyPendingTimers();
    notifications.present(alice);
    await nextTick();
    banner()?.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }));
    expect(notifications.current.value).toBeNull();
  });
});
