// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { expect, it, vi } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlareComposerAttachments } from "./useFlareComposerAttachments";

it("releases removed previews and ignores a send failure from a previous selection", async () => {
  const create = vi.spyOn(URL, "createObjectURL").mockReturnValueOnce("blob:first")
    .mockReturnValueOnce("blob:second").mockReturnValueOnce("blob:video");
  const revoke = vi.spyOn(URL, "revokeObjectURL").mockImplementation(() => {});
  let resolveSend!: (accepted: boolean) => void;
  const send = vi.fn(() => new Promise<boolean>(resolve => { resolveSend = resolve; }));
  let attachments!: ReturnType<typeof useFlareComposerAttachments>;
  const Probe = defineComponent({ setup() {
    attachments = useFlareComposerAttachments({ maxImages: 2, send });
    return () => null;
  } });
  const wrapper = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(Probe);
  } }));

  try {
    const pictures = ["a", "b", "c"].map(name => new File([], `${name}.png`, { type: "image/png" }));
    attachments.select(pictures);
    expect(attachments.previewProps.value).toMatchObject({ kind: "imageGroup", notice: expect.any(String) });
    expect(attachments.previewProps.value.items.map(item => item.name)).toEqual(["a.png", "b.png"]);
    attachments.previewEvents.remove(attachments.previewProps.value.items[0].id);
    expect(revoke).toHaveBeenCalledWith("blob:first");

    const inFlight = attachments.previewEvents.submit("old caption");
    expect(send).toHaveBeenCalledWith({ files: [pictures[1]], kind: "image", description: "old caption" });
    attachments.select([new File([], "clip.mp4", { type: "video/mp4" })]);
    resolveSend(false);
    await inFlight;

    expect(revoke).toHaveBeenCalledWith("blob:second");
    expect(attachments.previewProps.value).toMatchObject({ show: true, kind: "video", error: "", initialDescription: "" });

    attachments.select([new File([], "notes.txt"), new File([], "more.txt")]);
    expect(attachments.previewProps.value.items.map(item => item.name)).toEqual(["notes.txt"]);
    expect(attachments.previewProps.value.notice).toContain("第一个附件");
  } finally {
    wrapper.unmount();
    create.mockRestore();
    revoke.mockRestore();
  }
});
