// @vitest-environment happy-dom
import { flushPromises, mount } from "@vue/test-utils";
import { h, nextTick, type Component } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import ImagePreviewModal from "../message-preview/ImagePreviewModal.vue";
import MessageList from "./MessageList.vue";

function message(id: string, minute: number, content: Record<string, unknown>): MessageLike {
  const createdAt = 1_736_922_600_000 + minute * 60_000;
  return {
    serverId: `server-${id}`, clientMsgId: `client-${id}`, senderId: "ivy", senderDisplayName: "Ivy",
    conversationSeq: minute, createdAt, clientCreatedAt: createdAt, messageType: 1,
    content: content as MessageLike["content"], status: "read", isRecalled: false, isRead: true,
    timelineKey: `server:server-${id}`, timelineSortTs: createdAt, attributes: {},
  };
}

const timeline = [
  message("1", 0, { contentType: "image", image: { source: { url: "https://cdn.example/1.jpg" }, description: "Sea" } }),
  message("2", 1, { contentType: "text", text: "Nice" }),
  message("3", 2, {
    contentType: "image_group",
    image_group: { images: [{ url: "https://cdn.example/2.jpg" }, { url: "https://cdn.example/3.jpg", description: "Hill" }] },
  }),
];

function mountList(messages: readonly MessageLike[]) {
  return mount(FlareUiProvider, {
    props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
    slots: { default: () => h(MessageList as Component, { currentUserId: "me", hasOlder: false, messages }) },
  });
}

const modal = () => document.body.querySelector<HTMLElement>(".image-preview-modal");
const position = () => modal()?.querySelector(".image-preview-modal__position [aria-hidden='true']")?.textContent?.trim();
const shownSrc = () => modal()?.querySelector<HTMLImageElement>(".image-preview-modal__img")?.getAttribute("src");
const pageKey = (name: string) => modal()?.querySelector<HTMLButtonElement>(`button[aria-label='${name}']`);

async function press(key: string) {
  document.dispatchEvent(new KeyboardEvent("keydown", { key, bubbles: true }));
  await nextTick();
}

afterEach(() => {
  document.body.innerHTML = "";
});

describe("MessageList image gallery", () => {
  it("opens the conversation's gallery at the tapped picture and pages through the rest", async () => {
    const host = mountList(timeline);
    await flushPromises();
    await host.findAll("button.fm-album__open")[0].trigger("click");
    await flushPromises();

    expect(position()).toBe("2 / 3");
    expect(modal()?.querySelector(".image-preview-modal__sr")?.textContent).toBe("2 of 3");
    expect(shownSrc()).toBe("https://cdn.example/2.jpg");
    // An album's picture is saved by the browser.
    expect(modal()?.querySelector("button[aria-label='Download image']")).not.toBeNull();

    pageKey("Next image")!.click();
    await flushPromises();
    expect(position()).toBe("3 / 3");
    expect(shownSrc()).toBe("https://cdn.example/3.jpg");
    expect(pageKey("Next image")!.disabled).toBe(true);

    await press("ArrowLeft");
    await press("ArrowLeft");
    await flushPromises();
    expect(position()).toBe("1 / 3");
    expect(shownSrc()).toBe("https://cdn.example/1.jpg");
    expect(pageKey("Previous image")!.disabled).toBe(true);
    // The image message's host offers no download here.
    expect(modal()?.querySelector("button[aria-label='Download image']")).toBeNull();

    await press("Escape");
    expect(modal()).toBeNull();
    host.unmount();
  });

  it("pages with a sideways swipe and ignores one that is too short or mostly vertical", async () => {
    const host = mountList(timeline);
    await flushPromises();
    await host.get("button.fm-img").trigger("click");
    await flushPromises();
    expect(position()).toBe("1 / 3");
    const viewport = modal()!.querySelector<HTMLElement>(".image-preview-modal__viewport")!;
    const swipe = async (dx: number, dy: number) => {
      viewport.dispatchEvent(new PointerEvent("pointerdown", { clientX: 200, clientY: 200, bubbles: true }));
      viewport.dispatchEvent(new PointerEvent("pointerup", { clientX: 200 + dx, clientY: 200 + dy, bubbles: true }));
      await flushPromises();
    };
    await swipe(-30, 0);
    expect(position()).toBe("1 / 3");
    await swipe(-90, 120);
    expect(position()).toBe("1 / 3");
    await swipe(-90, 10);
    expect(position()).toBe("2 / 3");
    await swipe(90, 0);
    expect(position()).toBe("1 / 3");
    host.unmount();
  });

  it("previews a picture alone when the list has no other picture to page to", async () => {
    const host = mountList([timeline[0]]);
    await flushPromises();
    await host.get("button.fm-img").trigger("click");
    await flushPromises();
    const preview = host.findAllComponents(ImagePreviewModal).find((modal) => modal.props("show"));
    expect(preview?.props("galleryCount")).toBe(1);
    expect(shownSrc()).toBe("https://cdn.example/1.jpg");
    expect(modal()?.querySelector(".image-preview-modal__position")).toBeNull();
    expect(modal()?.querySelector(".image-preview-modal__page")).toBeNull();
    host.unmount();
  });
});
