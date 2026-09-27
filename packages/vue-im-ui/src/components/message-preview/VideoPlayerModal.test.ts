// @vitest-environment happy-dom
//
// 视频播放器的下载键：与图片预览一致，只在宿主接了 download 时出现；下载中显示百分比。
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import VideoPlayerModal from "./VideoPlayerModal.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => {
  host?.unmount();
  host = undefined;
  document.body.innerHTML = "";
});

function mountPlayer(extra: Record<string, unknown>) {
  host = mount(
    defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () =>
          h(VideoPlayerModal as Component, {
            show: true,
            videoSrc: "https://example.test/clip.mp4",
            ...extra,
          });
      },
    }),
    { attachTo: document.body },
  );
}

const downloadKey = () => document.querySelector<HTMLButtonElement>('button[aria-label="下载视频"]');

describe("VideoPlayerModal download key", () => {
  it("is absent when nobody handles download", () => {
    mountPlayer({});
    expect(downloadKey()).toBeNull();
  });

  it("emits download when the host handles it", async () => {
    let saves = 0;
    mountPlayer({ onDownload: () => (saves += 1) });
    downloadKey()?.click();
    expect(saves).toBe(1);
  });

  it("shows the progress instead of the key while downloading", () => {
    mountPlayer({ onDownload: () => undefined, downloading: true, progressPct: 42 });
    expect(downloadKey()).toBeNull();
    expect(document.querySelector(".video-player-modal__progress")?.textContent).toBe("42%");
  });
});

const folderKey = () => document.querySelector<HTMLButtonElement>('button[aria-label="在文件夹中显示"]');

describe("VideoPlayerModal saved video", () => {
  it("shows the video in its folder instead of downloading it again", () => {
    let saves = 0;
    let reveals = 0;
    mountPlayer({ saved: true, onDownload: () => (saves += 1), onReveal: () => (reveals += 1) });
    expect(downloadKey()).toBeNull();
    folderKey()?.click();
    expect(reveals).toBe(1);
    expect(saves).toBe(0);
  });

  it("keeps the download key when nobody handles reveal", () => {
    mountPlayer({ saved: true, onDownload: () => undefined });
    expect(folderKey()).toBeNull();
    expect(downloadKey()).not.toBeNull();
  });
});
