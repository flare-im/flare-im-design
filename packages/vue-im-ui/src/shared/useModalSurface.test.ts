// @vitest-environment happy-dom
//
// 这些用例盯的是「每张模态各写一遍」留下的三个真缺陷:
//  1. 滚动锁被别的浮层清掉 —— 面板还开着,背后的页面却又能滚了;
//  2. 一次 Escape 关掉两层 —— 两张面各听各的 document,都以为自己在最上面;
//  3. 写死 `Teleport to="body"` —— 宿主把浮层限定到某个容器时它逃出去。
// 三条都跨组件,所以用真的组件两两叠起来验,而不是单测那个 composable。
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, ref, type Component } from "vue";
import { useFlareI18nProvider } from "./i18n/useFlareI18n";
import { provideFlareOverlayContainer } from "./useOverlayContainer";
import FlareBottomSheet from "../components/general/FlareBottomSheet.vue";
import FlareCommandPalette from "../components/general/FlareCommandPalette.vue";
import VideoPlayerModal from "../components/message-preview/VideoPlayerModal.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => {
  host?.unmount();
  host = undefined;
  document.body.innerHTML = "";
  document.body.style.overflow = "";
});

/** 一张底部面板,上面再叠一个全屏播放器 —— 从前分属两套实现的那一对。 */
function mountStack(overlayContainer?: string) {
  const sheetOpen = ref(true);
  const videoOpen = ref(true);
  const closed: string[] = [];
  host = mount(
    defineComponent({
      setup() {
        useFlareI18nProvider("en-US");
        if (overlayContainer) provideFlareOverlayContainer(overlayContainer);
        return () => [
          h(
            FlareBottomSheet as Component,
            {
              open: sheetOpen.value,
              title: "Sheet",
              onClose: () => {
                closed.push("sheet");
                sheetOpen.value = false;
              },
            },
            { default: () => h("button", "Sheet action") },
          ),
          h(VideoPlayerModal as Component, {
            show: videoOpen.value,
            videoSrc: "https://example.test/clip.mp4",
            "onUpdate:show": (value: boolean) => {
              if (value) return;
              closed.push("video");
              videoOpen.value = false;
            },
          }),
        ];
      },
    }),
    { attachTo: document.body },
  );
  return { sheetOpen, videoOpen, closed };
}

describe("modal surfaces share one stack", () => {
  it("keeps the scroll lock while any surface is still open, then restores the prior value", async () => {
    // 宿主自己本来就锁着的情况:还回去的必须是这个值,不是空串。
    document.body.style.overflow = "auto";
    const { sheetOpen, videoOpen } = mountStack();
    await nextTick();
    expect(document.body.style.overflow).toBe("hidden");

    // 关掉上面那层:面板还开着,锁不能跟着没。
    videoOpen.value = false;
    await nextTick();
    expect(document.body.style.overflow).toBe("hidden");

    sheetOpen.value = false;
    await nextTick();
    expect(document.body.style.overflow).toBe("auto");
  });

  it("gives Escape to the topmost surface only, one layer per press", async () => {
    const { closed } = mountStack();
    await nextTick();

    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
    await nextTick();
    expect(closed).toEqual(["video"]);

    // 上面那层走了,下面这张才轮到。
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
    await nextTick();
    expect(closed).toEqual(["video", "sheet"]);
  });

  it("teleports into the container the host provided, not into body", async () => {
    const container = document.createElement("div");
    container.id = "overlay-host";
    document.body.appendChild(container);
    mountStack("#overlay-host");
    await nextTick();

    expect(container.querySelector(".flare-sheet")).not.toBeNull();
    expect(container.querySelector(".video-player-modal")).not.toBeNull();
    // 浮层不该直接挂在 body 下面。
    expect(document.body.querySelector(":scope > .video-player-modal")).toBeNull();
  });
});

describe("modal surfaces trap Tab", () => {
  it("wraps focus from the last control back to the first", async () => {
    host = mount(
      defineComponent({
        setup() {
          useFlareI18nProvider("en-US");
          return () =>
            h(FlareCommandPalette as Component, {
              open: true,
              query: "",
              label: "Commands",
              placeholder: "Find",
              emptyText: "None",
              groups: [{ id: "g", label: "Message", commands: [{ id: "reply", label: "Reply" }, { id: "copy", label: "Copy" }] }],
            });
        },
      }),
      { attachTo: document.body },
    );
    await nextTick();

    const input = document.body.querySelector("input") as HTMLInputElement;
    const buttons = Array.from(document.body.querySelectorAll("button"));
    expect(document.activeElement).toBe(input);

    buttons[buttons.length - 1].focus();
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Tab", bubbles: true }));
    await nextTick();
    expect(document.activeElement).toBe(input);
  });
});
