// @vitest-environment happy-dom
import { mount, enableAutoUnmount, flushPromises } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../../shared/i18n/useFlareI18n";
import ContentView from "./ContentView.vue";

enableAutoUnmount(afterEach);
function mountContent(content: Record<string, unknown>, extra: Record<string, unknown> = {}) {
  const host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(ContentView, { content, isSelf: false, ...extra });
  } }), { attachTo: document.body });
  return host;
}
// Media views resolve their URLs through the async media resolver; settle it first.
async function mountMedia(content: Record<string, unknown>, extra: Record<string, unknown> = {}) {
  const host = mountContent(content, extra);
  await flushPromises();
  await flushPromises();
  return host;
}

// One body per content type: the timeline views are adapters over the contract bodies
// (Flare*Message), so the rendered root must be the body's own class.
describe("timeline content bodies are the contract bodies", () => {
  it("system → FlareSystemMessage pill", () => {
    const w = mountContent({ contentType: "system", data: { body: "张三 加入了群聊" } });
    expect(w.find(".fm-sys").text()).toBe("张三 加入了群聊");
  });
  it("location → FlareLocationMessage, coordinates link out with a safe rel", () => {
    const w = mountContent({ contentType: "location", data: { title: "望京 SOHO", address: "北京市朝阳区", latitude: 39.9968, longitude: 116.4809 } });
    expect(w.find(".fm-loc").exists()).toBe(true);
    const a = w.get("a.im-location");
    expect(a.attributes("href")).toContain("maps.google.com");
    expect(a.attributes("rel")).toBe("noopener noreferrer");
    expect(w.text()).toContain("望京 SOHO");
  });
  it("card → FlareContactMessage with the payload subtitle", () => {
    const w = mountContent({ contentType: "card", data: { title: "Ivy Chen", subtitle: "设计", cardType: "user", id: "u2" } });
    expect(w.find(".fm-contact").exists()).toBe(true);
    expect(w.text()).toContain("Ivy Chen");
    expect(w.text()).toContain("设计");
  });
  it("link_card → FlareLinkCardMessage; only http(s) becomes an anchor", () => {
    const ok = mountContent({ contentType: "link_card", data: { url: "https://www.example.com/docs?x=1", title: "Docs", description: "Guide" } });
    expect(ok.find(".fm-link").exists()).toBe(true);
    expect(ok.get("a.im-link-card").attributes("rel")).toBe("noopener noreferrer");
    expect(ok.text()).toContain("example.com/docs?x=1");
    const bad = mountContent({ contentType: "link_card", data: { url: "javascript:alert(1)", title: "x" } });
    expect(bad.find("a").exists()).toBe(false);
    expect(bad.find(".fm-link").exists()).toBe(true);
  });
  it("sticker → FlareStickerMessage, plain content (no button) in the timeline", () => {
    const w = mountContent({ contentType: "sticker", data: { url: "https://cdn.example.com/s.webp" } });
    expect(w.find("div.fm-sticker").exists()).toBe(true);
    expect(w.find("button.fm-sticker").exists()).toBe(false);
  });
  it("emoji → FlareEmojiMessage bracket fallback for an unknown pack key", () => {
    const w = mountContent({ contentType: "emoji", data: { key: "no_such_pack_key_xyz" } });
    expect(w.find(".fm-emoji").exists()).toBe(true);
    expect(w.text()).toContain("[");
  });
});

describe("media bodies: File / Image / Video", () => {
  it("file → FlareFileMessage embedded; the host download lifecycle drives the action", async () => {
    const w = await mountMedia(
      { contentType: "file", data: { fileName: "设计规范 v2.pdf", fileSize: 2_517_000, url: "https://cdn.example.com/a.pdf" } },
      { mediaAction: "download", mediaState: "downloading" },
    );
    const root = w.get(".fm-file");
    expect(root.classes()).toContain("fm-file--embedded");
    expect(root.classes()).toContain("fm-file--downloading");
    expect(w.text()).toContain("设计规范 v2.pdf");
    expect(w.text()).toContain("下载中");
    const action = w.get("button.dl");
    expect((action.element as HTMLButtonElement).disabled).toBe(true);
    expect(action.attributes("aria-label")).toBe("下载中");
    expect(w.find(".bar").exists()).toBe(true);
  });
  it("file → idle with a host action emits media-action; size · ext is the meta line", async () => {
    const w = await mountMedia(
      { contentType: "file", data: { fileName: "report.PDF", fileSize: 2_517_000, url: "https://cdn.example.com/a.pdf" } },
      { mediaAction: "download" },
    );
    expect(w.text()).toContain("2.4 MB · PDF");
    await w.get("button.dl").trigger("click");
    const content = w.findComponent(ContentView);
    expect(content.emitted("media-action")?.[0]).toEqual(["download"]);
  });
  it("file → without a host media action there is no download affordance", async () => {
    const w = await mountMedia({ contentType: "file", data: { fileName: "a.pdf", fileSize: 10, url: "https://cdn.example.com/a.pdf" } });
    expect(w.find(".fm-file").exists()).toBe(true);
    expect(w.find("button.dl").exists()).toBe(false);
  });
  it("image → FlareImageMessage in flexible mode, GIF badge and caption", async () => {
    const w = await mountMedia({ contentType: "image", data: { url: "https://cdn.example.com/a.gif", mimeType: "image/gif", description: "动图" } });
    const img = w.get(".fm-img");
    expect(img.classes()).toContain("fm-img--flex");
    expect(w.get(".fm-img img").attributes("src")).toBe("https://cdn.example.com/a.gif");
    expect(w.get(".fm-img .badge").text()).toBe("GIF");
    expect(w.get(".im-media-caption").text()).toBe("动图");
  });
  it("image → a failed load becomes a retry placeholder; the next tap retries instead of opening", async () => {
    const w = await mountMedia({ contentType: "image", data: { url: "https://cdn.example.com/broken.png" } });
    await w.get(".fm-img img").trigger("error");
    expect(w.find(".fm-img img").exists()).toBe(false);
    expect(w.get(".fm-img").text()).toContain("点按重试");
    await w.get(".fm-img").trigger("click");
    expect(w.find(".fm-img img").exists()).toBe(true);
    expect(w.find(".preview-modal__body").exists()).toBe(false);
  });
  it("task → FlareTaskMessage embedded inside the business card; the box is a read-only checkbox", () => {
    const w = mountContent({ contentType: "task", data: { title: "整理评审结论并同步", status: "done", assignee: "Ivy" } });
    const root = w.get(".business-message-view--task .fm-task");
    expect(root.classes()).toContain("fm-task--embedded");
    const box = w.get(".fm-task .box");
    expect(box.element.tagName).toBe("SPAN");
    expect(box.attributes("role")).toBe("checkbox");
    expect(box.attributes("aria-checked")).toBe("true");
    expect(w.text()).toContain("整理评审结论并同步");
    expect(w.text()).toContain("done");
  });
  it("video → FlareVideoMessage with the poster and an mm:ss duration from the payload", async () => {
    const w = await mountMedia({ contentType: "video", data: { url: "https://cdn.example.com/a.mp4", coverUrl: "https://cdn.example.com/c.jpg", durationMs: 42_000 } });
    const video = w.get(".fm-video");
    expect(video.classes()).toContain("fm-video--flex");
    expect((video.element as HTMLButtonElement).disabled).toBe(false);
    expect(w.get(".fm-video img").attributes("src")).toBe("https://cdn.example.com/c.jpg");
    expect(w.get(".fm-video .dur").text()).toBe("00:42");
  });
});
