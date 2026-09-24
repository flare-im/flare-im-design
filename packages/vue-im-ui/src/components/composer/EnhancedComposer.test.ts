// @vitest-environment happy-dom
import { afterEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, nextTick, reactive, type Component } from "vue";
import { mount, flushPromises } from "@vue/test-utils";
import Composer from "./EnhancedComposer.vue";
import FlareGlyph from "../general/FlareGlyph.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";

const wrappers: ReturnType<typeof mount>[] = [];
function setup(props: Record<string, unknown> = {}) {
  const host = mount(defineComponent({
    setup() { useFlareI18nProvider("zh-CN"); return () => h(Composer as Component, props); },
  }), { attachTo: document.body });
  wrappers.push(host);
  return host.findComponent(Composer);
}
async function openVoiceFromMore(wrapper: ReturnType<typeof setup>) {
  await wrapper.get('[aria-label="更多"]').trigger("click");
  const voice = wrapper.findAll(".flare-action-panel__tile").find((tile) => tile.text().includes("语音"));
  if (!voice) throw new Error("Expected the default voice action");
  await voice.trigger("click");
}
afterEach(() => { wrappers.splice(0).forEach(w => w.unmount()); vi.unstubAllGlobals(); vi.restoreAllMocks(); });

describe("FlareComposer interaction boundaries", () => {
  it("keeps an offline draft editable while blocking keyboard and button sends", async () => {
    const wrapper = setup({ modelValue: "未发送的草稿", sendBlocked: true });
    expect(wrapper.get("textarea").attributes("disabled")).toBeUndefined();
    expect(wrapper.get('[aria-label="发送"]').attributes("disabled")).toBeDefined();
    await wrapper.get("textarea").trigger("keydown", { key: "Enter" });
    expect(wrapper.emitted("send")).toBeUndefined();
    expect(wrapper.props("modelValue")).toBe("未发送的草稿");
  });
  it("makes a muted draft read-only without deleting it", async () => {
    const wrapper = setup({ modelValue: "保留草稿", readOnly: true, statusHint: "你已被禁言" });
    expect(wrapper.get("textarea").attributes("disabled")).toBeDefined();
    await wrapper.vm.insertAtCursor("禁止插入");
    expect(wrapper.emitted("update:modelValue")).toBeUndefined();
    expect(wrapper.text()).toContain("你已被禁言");
  });
  it("treats an empty action configuration as empty, and suppresses disabled actions", async () => {
    const empty = setup({ activePanel: "more", actions: [] });
    expect(empty.findAll(".flare-action-panel__tile")).toHaveLength(0);
    expect(empty.text()).toContain("暂无可用内容");
    const wrapper = setup({ activePanel: "more", actions: [{ id: "custom", label: "企业审批", enabled: false, disabledReason: "无权限" }] });
    await wrapper.get(".flare-action-panel__tile").trigger("click");
    expect(wrapper.emitted("build")).toBeUndefined();
  });
  it("opens the default more actions in uncontrolled simple mode", async () => {
    const wrapper = setup({ sendVoiceHandler: vi.fn() });
    await wrapper.get('[aria-label="更多"]').trigger("click");
    expect(wrapper.findAll(".flare-action-panel__tile")).toHaveLength(6);
    expect(wrapper.text()).toContain("图片");
    expect(wrapper.text()).toContain("文件");
    // composer 自己就能拾取视频,所以「+」里给得出这一格。
    expect(wrapper.text()).toContain("视频");
  });
  it("offers voice only when a recording has somewhere to go", async () => {
    const silent = setup();
    expect(silent.find('.composer-toolbar [aria-label="语音"]').exists()).toBe(false);
    await silent.get('[aria-label="更多"]').trigger("click");
    expect(silent.findAll(".flare-action-panel__tile").map((tile) => tile.attributes("data-action-id"))).toEqual(["image", "video", "file", "location", "contact"]);
    const listening = setup({ onSendVoice: vi.fn() });
    expect(listening.find('.composer-toolbar [aria-label="语音"]').exists()).toBe(true);
  });
  it("keeps kit glyphs on host actions that bring no icon", async () => {
    const wrapper = setup({ activePanel: "more", actions: [{ id: "file", label: "文件" }, { id: "video", label: "视频" }] });
    const tiles = wrapper.findAll(".flare-action-panel__tile");
    expect(tiles.map((tile) => tile.attributes("data-action-id"))).toEqual(["file", "video"]);
    expect(wrapper.findAllComponents(FlareGlyph).map((glyph) => glyph.props("icon"))).toEqual(["file", "video"]);
  });
  it("gives both toolbar presentations the same base actions, and only expanded the inline enlarge button", () => {
    // 基础动作在窄屏和宽屏是同一排：换个屏幕宽度不该少掉 @ / 图片 / 富文本三个入口。
    const base = ["表情", "@", "图片", "富文本", "更多", "发送"];
    const minimal = setup();
    expect(minimal.findAll(".composer-toolbar button").map((button) => button.attributes("aria-label"))).toEqual(base);
    const withVoice = setup({ sendVoiceHandler: vi.fn() });
    expect(withVoice.findAll(".composer-toolbar button").map((button) => button.attributes("aria-label")))
      .toEqual(["表情", "@", "语音", "图片", "富文本", "更多", "发送"]);
    // expanded 只多那个「放大输入框」——窄屏上它在输入框自己的角上，不进工具条。
    const expanded = setup({ toolbarPresentation: "expanded", sendVoiceHandler: vi.fn() });
    const expandedLabels = expanded.findAll(".composer-toolbar button").map((button) => button.attributes("aria-label"));
    expect(expandedLabels).toHaveLength(8);
    expect(expandedLabels.slice(1)).toEqual(["表情", "@", "语音", "图片", "富文本", "更多", "发送"]);
    expect(minimal.find(".composer-expand").exists()).toBe(false);
    expect(expanded.find(".composer-expand").exists()).toBe(true);
  });
  // 文本样式是 kit 自己的菜单(手机上底部面板、桌面锚定菜单),不再是浏览器画的 <select>:
  // 触发器上是短记号(P / H2),菜单里每一项是一句完整的名字,当前那一项打勾。
  it("presents paragraph and heading levels as one compact text-style control", async () => {
    const wrapper = setup({ richMode: true, toolbarPresentation: "expanded" });
    const trigger = wrapper.get('.composer-heading-select');
    expect(trigger.element.tagName).toBe('BUTTON');
    expect(trigger.attributes('aria-label')).toBe('文本样式');
    expect(trigger.attributes('aria-haspopup')).toBe('menu');
    expect(trigger.attributes('title')).toBe('正文');
    expect(trigger.get('.composer-heading-select__value').text()).toBe('P');
    expect(wrapper.find('select').exists()).toBe(false);
    await trigger.trigger('click');
    await flushPromises();
    const items = Array.from(document.body.querySelectorAll<HTMLElement>('[data-action-menu-item]'));
    expect(items.map((item) => item.textContent?.trim())).toEqual([
      '正文', '标题 1', '标题 2', '标题 3', '标题 4', '标题 5', '标题 6',
    ]);
    expect(items.map((item) => item.getAttribute('role'))).toEqual(Array(7).fill('menuitemcheckbox'));
    expect(items[0]?.getAttribute('aria-checked')).toBe('true');
  });
  // 文本样式菜单锚定后传送到 body,在 composer 根之外:点它的一项不能被当成「点到了别处」,
  // 否则正开着的表情面板会被关掉、宿主收到一次 toggle-panel(null)。
  it("picking a text style from the menu does not close an open panel", async () => {
    const wrapper = setup({ richMode: true, toolbarPresentation: "expanded", activePanel: "emoji" });
    await wrapper.get(".composer-heading-select").trigger("click");
    await flushPromises();
    const item = document.body.querySelector<HTMLElement>('[data-action-menu-item="heading-2"]') ?? document.body.querySelectorAll<HTMLElement>("[data-action-menu-item]")[2];
    expect(item).toBeTruthy();
    item!.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true }));
    item!.click();
    await flushPromises();
    expect(wrapper.emitted("toggle-panel")).toBeUndefined();
    // 对照:真点到别处,面板照关。
    document.body.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true }));
    await flushPromises();
    expect(wrapper.emitted("toggle-panel")).toEqual([[null]]);
  });
  it("keeps context, input, and actions inside one explicit composer surface", () => {
    const wrapper = setup({
      replySender: "Ivy Chen",
      replyPreview: "Review the surface contract",
      uploadItems: [{ id: "asset-1", name: "review.png", progress: 0.42, state: "uploading" }],
      toolbarPresentation: "expanded",
    });
    const surface = wrapper.get('[data-flare-surface-owner="composer"]');
    expect(surface.find(".composer-reply-strip").exists()).toBe(true);
    expect(surface.find(".composer-upload-strip").exists()).toBe(true);
    expect(surface.find(".composer-editor-area .composer-input-layer").exists()).toBe(true);
    expect(surface.find(".composer-editor-area .composer-toolbar").exists()).toBe(true);
    expect(wrapper.get("footer").attributes("aria-busy")).toBe("true");
  });
  it("exposes upload recovery actions without transferring upload ownership to the host layout", async () => {
    const wrapper = setup({
      uploadItems: [{ id: "asset-1", name: "failed.mov", progress: 0.6, state: "failed" }],
    });
    await wrapper.get('[aria-label="重试上传"]').trigger("click");
    await wrapper.get('[aria-label="移除附件"]').trigger("click");
    expect(wrapper.emitted("retry-upload")).toEqual([["asset-1"]]);
    expect(wrapper.emitted("remove-upload")).toEqual([["asset-1"]]);
  });
  it("separates disabled, read-only, send-blocked, and uploading semantics", () => {
    const wrapper = setup({
      readOnly: true,
      sendBlocked: true,
      uploadItems: [{ id: "asset-1", name: "file.pdf" }],
    });
    const root = wrapper.get("footer");
    expect(root.classes()).toEqual(expect.arrayContaining([
      "composer--disabled",
      "composer--read-only",
      "composer--send-blocked",
      "composer--uploading",
    ]));
    expect(root.attributes("aria-busy")).toBe("true");
    // Disabled / read-only live on the control that has a widget role — the
    // editable textbox. A <footer> is not a widget, so aria-disabled /
    // aria-readonly on it are invalid ARIA (axe `aria-allowed-attr`).
    expect(root.attributes("aria-disabled")).toBeUndefined();
    expect(root.attributes("aria-readonly")).toBeUndefined();
    expect(wrapper.get("textarea").attributes("disabled")).toBeDefined();
  });
  it("keeps a file drag inside the existing surface and blocks drops in read-only mode", async () => {
    const props = reactive({ fileDropEnabled: true, readOnly: false });
    const wrapper = setup(props);
    const file = new File(["image"], "review.png", { type: "image/png" });
    const dataTransfer = { types: ["Files"], files: [file], dropEffect: "none" };
    await wrapper.get("footer").trigger("dragenter", { dataTransfer });
    expect(wrapper.get('[data-flare-surface-owner="composer"]').classes()).toContain("composer-field--drag-over");
    await wrapper.get("footer").trigger("drop", { dataTransfer });
    expect(wrapper.emitted("files-drop")).toEqual([[[file]]]);
    expect(wrapper.find(".composer-drop-hint").exists()).toBe(false);
    props.readOnly = true;
    await nextTick();
    await wrapper.get("footer").trigger("dragenter", { dataTransfer });
    await wrapper.get("footer").trigger("drop", { dataTransfer });
    expect(wrapper.emitted("files-drop")).toHaveLength(1);
    expect(wrapper.find(".composer-drop-hint").exists()).toBe(false);
  });
  it("filters paginated actions and removes hidden search filters", async () => {
    const actions = Array.from({ length: 10 }, (_, index) => ({ id: `action-${index}`, label: index === 9 ? "文件" : `动作 ${index}` }));
    const props = reactive({ activePanel: "more", moreSearchVisible: true, actions });
    const wrapper = setup(props);
    expect(wrapper.findAll(".flare-action-panel__tile")).toHaveLength(8);
    await wrapper.get('[aria-label="第 2 页"]').trigger("click");
    expect(wrapper.text()).toContain("文件");
    await wrapper.get(".composer-panel-search").setValue("文件");
    expect(wrapper.findAll(".flare-action-panel__tile")).toHaveLength(1);
    expect(wrapper.find(".composer-pages").exists()).toBe(false);
    props.moreSearchVisible = false;
    await nextTick();
    expect(wrapper.findAll(".flare-action-panel__tile")).toHaveLength(8);
  });
  it("typing @ at the start of a word opens the member picker, and the pick replaces the @", async () => {
    const props = reactive({
      modelValue: "",
      mentionCandidates: [{ userId: "u1", label: "Ivy" }],
      "onUpdate:modelValue": (next: string) => { props.modelValue = next; },
    });
    const wrapper = setup(props);
    // One keystroke at a time, as typing does.
    await wrapper.get("textarea").setValue("hi ");
    await wrapper.get("textarea").setValue("hi @");
    await nextTick();
    expect(wrapper.find(".composer-mention-menu").exists()).toBe(true);
    expect(document.activeElement).toBe(wrapper.get(".flare-mention__search").element);
    const ivy = wrapper.findAll(".flare-mention__person").find((person) => person.text().includes("Ivy"));
    if (!ivy) throw new Error("Expected Ivy in the member picker");
    await ivy.trigger("click");
    await nextTick();
    expect(props.modelValue).toBe("hi @Ivy ");
    expect(wrapper.find(".composer-mention-menu").exists()).toBe(false);
  });
  it("leaves an @ inside a word, or without a roster, as plain text", async () => {
    const withRoster = reactive({
      modelValue: "",
      mentionCandidates: [{ userId: "u1", label: "Ivy" }],
      "onUpdate:modelValue": (next: string) => { withRoster.modelValue = next; },
    });
    const inWord = setup(withRoster);
    await inWord.get("textarea").setValue("mail a");
    await inWord.get("textarea").setValue("mail a@");
    await nextTick();
    expect(inWord.find(".composer-mention-menu").exists()).toBe(false);

    const noRoster = reactive({ modelValue: "", "onUpdate:modelValue": (next: string) => { noRoster.modelValue = next; } });
    const direct = setup(noRoster);
    await direct.get("textarea").setValue("@");
    await nextTick();
    expect(direct.find(".composer-mention-menu").exists()).toBe(false);
  });
  it("reports user-input for the user's own edits, not for a restored draft or the clear after sending", async () => {
    const props = reactive({ modelValue: "", "onUpdate:modelValue": (next: string) => { props.modelValue = next; } });
    const wrapper = setup(props);
    props.modelValue = "恢复的草稿";
    await nextTick();
    expect(wrapper.emitted("user-input")).toBeUndefined();
    await wrapper.get("textarea").setValue("恢复的草稿，");
    await wrapper.vm.insertAtCursor("继续");
    expect(wrapper.emitted("user-input")).toEqual([["恢复的草稿，"], ["恢复的草稿，继续"]]);
    await wrapper.get('[aria-label="发送"]').trigger("click");
    await nextTick();
    expect(wrapper.emitted("send")).toEqual([["恢复的草稿，继续"]]);
    expect(props.modelValue).toBe("");
    expect(wrapper.emitted("user-input")).toHaveLength(2);
  });
  it("puts the caret in the input when the host starts a reply or an edit", async () => {
    const props = reactive({ replySender: "", replyPreview: "", editing: false, editPreview: "" });
    const wrapper = setup(props);
    const toolbarButton = document.createElement("button");
    document.body.append(toolbarButton);
    toolbarButton.focus();
    props.replySender = "陈默";
    props.replyPreview = "安装包已上传";
    await flushPromises();
    await new Promise((resolve) => setTimeout(resolve, 20));
    expect(document.activeElement).toBe(wrapper.get("textarea").element);
    toolbarButton.focus();
    props.replySender = "";
    props.replyPreview = "";
    await flushPromises();
    expect(document.activeElement).toBe(toolbarButton);
    props.editing = true;
    props.editPreview = "原文";
    await flushPromises();
    await new Promise((resolve) => setTimeout(resolve, 20));
    expect(document.activeElement).toBe(wrapper.get("textarea").element);
    toolbarButton.remove();
  });
  it("leaves the member picker closed when the host restores a draft that ends in @", async () => {
    const props = reactive({
      modelValue: "",
      mentionCandidates: [{ userId: "u1", label: "Ivy" }],
      "onUpdate:modelValue": (next: string) => { props.modelValue = next; },
    });
    const wrapper = setup(props);
    props.modelValue = "hi @";
    await nextTick();
    await nextTick();
    expect(wrapper.find(".composer-mention-menu").exists()).toBe(false);
  });
  it("opens @ search even with an empty roster, and Escape dismisses it", async () => {
    const wrapper = setup({ toolbarPresentation: "expanded" });
    await wrapper.get('[aria-label="@"]').trigger("click");
    expect(wrapper.find(".composer-mention-menu").exists()).toBe(true);
    await wrapper.get(".flare-mention__search").setValue("Nobody");
    expect(wrapper.text()).toContain("暂无可用内容");
    await wrapper.get(".flare-mention__search").trigger("keydown", { key: "Escape" });
    expect(wrapper.find(".composer-mention-menu").exists()).toBe(false);
  });
  it("does not acquire or leak a microphone after the panel was dismissed", async () => {
    let resolveStream!: (stream: MediaStream) => void;
    const stop = vi.fn();
    const getUserMedia = vi.fn(() => new Promise<MediaStream>(resolve => { resolveStream = resolve; }));
    vi.stubGlobal("navigator", { mediaDevices: { getUserMedia } });
    vi.stubGlobal("MediaRecorder", class {});
    const wrapper = setup({ onSendVoice: vi.fn() });
    await openVoiceFromMore(wrapper);
    await wrapper.get('[aria-label="开始录音"]').trigger("click");
    await wrapper.get('[aria-label="返回键盘并删除录音"]').trigger("click");
    resolveStream({ getTracks: () => [{ stop }] } as unknown as MediaStream);
    await flushPromises();
    expect(stop).toHaveBeenCalledOnce();
    expect(wrapper.emitted("send-voice")).toBeUndefined();
  });
  it("records to a preview and only sends after explicit confirmation", async () => {
    let now = 1000;
    vi.spyOn(Date, "now").mockImplementation(() => now);
    const stop = vi.fn();
    vi.stubGlobal("navigator", { mediaDevices: { getUserMedia: async () => ({ getTracks: () => [{ stop }] }) } });
    vi.stubGlobal("MediaRecorder", class {
      static isTypeSupported() { return true; }
      mimeType = "audio/webm";
      state = "inactive";
      ondataavailable: ((event: { data: Blob }) => void) | null = null;
      onstop: (() => void) | null = null;
      start() { this.state = "recording"; }
      pause() { this.state = "paused"; }
      resume() { this.state = "recording"; }
      requestData() { this.ondataavailable?.({ data: new Blob(["recording"]) }); }
      stop() { this.state = "inactive"; this.onstop?.(); }
    });
    vi.spyOn(URL, "createObjectURL").mockReturnValue("blob:preview");
    vi.spyOn(URL, "revokeObjectURL").mockImplementation(() => {});
    const send = vi.fn();
    const wrapper = setup({ modelValue: "文字草稿", sendVoiceHandler: send });
    await openVoiceFromMore(wrapper);
    await wrapper.get('[aria-label="开始录音"]').trigger("click");
    await flushPromises();
    now = 2000;
    await wrapper.get('[aria-label="暂停录音"]').trigger("click");
    expect(wrapper.get("audio").attributes("src")).toBe("blob:preview");
    expect(send).not.toHaveBeenCalled();
    expect(stop).not.toHaveBeenCalled();
    now = 8000;
    await wrapper.get('[aria-label="继续录音"]').trigger("click");
    now = 9000;
    await wrapper.get('[aria-label="暂停录音"]').trigger("click");
    await wrapper.get('.composer-voice-inline [aria-label="发送"]').trigger("click");
    await flushPromises();
    expect(send).toHaveBeenCalledOnce();
    expect(send.mock.calls[0][0].durationMs).toBe(2000);
    expect(stop).toHaveBeenCalledOnce();
    expect(wrapper.props("modelValue")).toBe("文字草稿");
    expect(wrapper.find("audio").exists()).toBe(false);
  });
  it("discards late recorder callbacks after returning to keyboard", async () => {
    const stopTrack = vi.fn();
    let recorder: any;
    vi.stubGlobal("navigator", { mediaDevices: { getUserMedia: async () => ({ getTracks: () => [{ stop: stopTrack }] }) } });
    vi.stubGlobal("MediaRecorder", class {
      state = "inactive"; mimeType = "audio/webm";
      ondataavailable: any; onstop: any;
      constructor() { recorder = this; }
      start() { this.state = "recording"; }
      stop() { this.state = "inactive"; }
    });
    const wrapper = setup({ modelValue: "保留文字", toolbarPresentation: "expanded", sendVoiceHandler: vi.fn() });
    await wrapper.get('[aria-label="语音"]').trigger("click");
    await wrapper.get('[aria-label="开始录音"]').trigger("click");
    await flushPromises();
    await wrapper.get('[aria-label="返回键盘并删除录音"]').trigger("click");
    recorder.ondataavailable({ data: new Blob(["late data"]) });
    recorder.onstop();
    await wrapper.get('[aria-label="语音"]').trigger("click");
    expect(stopTrack).toHaveBeenCalledOnce();
    expect(wrapper.find("audio").exists()).toBe(false);
    expect(wrapper.get("time").text()).toBe("00:00");
    expect(wrapper.props("modelValue")).toBe("保留文字");
  });
  it("retains the finalized clip when upload fails and retries the same blob", async () => {
    let now = 1000;
    vi.spyOn(Date, "now").mockImplementation(() => now);
    vi.stubGlobal("navigator", { mediaDevices: { getUserMedia: async () => ({ getTracks: () => [{ stop: vi.fn() }] }) } });
    vi.stubGlobal("MediaRecorder", class {
      state = "inactive"; mimeType = "audio/webm";
      ondataavailable: any; onstop: any;
      start() { this.state = "recording"; }
      pause() { this.state = "paused"; }
      requestData() { this.ondataavailable({ data: new Blob(["clip"]) }); }
      stop() { this.state = "inactive"; this.onstop(); }
    });
    vi.spyOn(URL, "createObjectURL").mockReturnValue("blob:retry");
    vi.spyOn(URL, "revokeObjectURL").mockImplementation(() => {});
    const send = vi.fn().mockRejectedValueOnce(new Error("offline")).mockResolvedValueOnce(undefined);
    const wrapper = setup({ sendVoiceHandler: send });
    await openVoiceFromMore(wrapper);
    await wrapper.get('[aria-label="开始录音"]').trigger("click");
    await flushPromises(); now = 2500;
    await wrapper.get('[aria-label="暂停录音"]').trigger("click");
    await wrapper.get('.composer-voice-inline [aria-label="发送"]').trigger("click");
    await flushPromises();
    expect(wrapper.find("audio").exists()).toBe(true);
    await wrapper.get('.composer-voice-inline [aria-label="发送"]').trigger("click");
    await flushPromises();
    expect(send).toHaveBeenCalledTimes(2);
    expect(send.mock.calls[1][0].blob).toBe(send.mock.calls[0][0].blob);
    expect(wrapper.find("audio").exists()).toBe(false);
  });
  it("shows the media-panel slot whenever the emoji or sticker panel is active", async () => {
    const mountWithPicker = (props: Record<string, unknown>) => {
      const host = mount(defineComponent({
        setup() {
          useFlareI18nProvider("zh-CN");
          return () => h(Composer as Component, props, { "media-panel": () => h("div", { class: "picker-slot" }, "picker") });
        },
      }), { attachTo: document.body });
      wrappers.push(host);
      return host.findComponent(Composer);
    };
    const uncontrolled = mountWithPicker({});
    expect(uncontrolled.find(".picker-slot").exists()).toBe(false);
    await uncontrolled.get('[aria-label="表情"]').trigger("click");
    expect(uncontrolled.emitted("toggle-panel")?.at(-1)).toEqual(["emoji"]);
    expect(uncontrolled.find(".picker-slot").exists()).toBe(true);

    const controlled = reactive<Record<string, unknown>>({ activePanel: "sticker" });
    const wrapper = mountWithPicker(controlled);
    expect(wrapper.find(".picker-slot").exists()).toBe(true);
    controlled.activePanel = "more";
    await nextTick();
    expect(wrapper.find(".picker-slot").exists()).toBe(false);
  });
  it("dismisses transient panels on a conversation change", async () => {
    const props = reactive({ conversationKey: "a", toolbarPresentation: "expanded", sendVoiceHandler: vi.fn() });
    const wrapper = setup(props);
    await wrapper.get('[aria-label="语音"]').trigger("click");
    expect(wrapper.find(".composer-voice-inline").exists()).toBe(true);
    props.conversationKey = "b";
    await nextTick();
    expect(wrapper.find(".composer-voice-inline").exists()).toBe(false);
  });
  it("shares the diagonal resize state between layouts and preserves the draft on collapse", async () => {
    const wrapper = setup({ modelValue: "展开前的草稿", targetName: "Ivy Chen", toolbarPresentation: "expanded" });
    expect(wrapper.get("textarea").attributes("placeholder")).toBe("发送给 Ivy Chen");
    const mobile = wrapper.get(".composer-field-expand");
    const desktop = wrapper.get(".composer-expand");
    expect(mobile.attributes("aria-expanded")).toBe("false");
    await mobile.trigger("click");
    expect(wrapper.emitted("toggle-panel")).toBeUndefined();
    expect(mobile.attributes("aria-expanded")).toBe("true");
    expect(desktop.attributes("aria-expanded")).toBe("true");
    expect(mobile.get("path").attributes("d")).toBe(desktop.get("path").attributes("d"));
    await wrapper.get("textarea").trigger("keydown", { key: "Escape" });
    expect(mobile.attributes("aria-expanded")).toBe("false");
    expect(wrapper.props("modelValue")).toBe("展开前的草稿");
  });
  it("closes an active panel only once when resizing the input", async () => {
    const wrapper = setup({ activePanel: "more", toolbarPresentation: "expanded" });
    await wrapper.get(".composer-expand").trigger("click");
    expect(wrapper.emitted("toggle-panel")).toEqual([[null]]);
  });
  it("never submits on the legacy keyCode 229 IME signal either", async () => {
    // Some Android / Windows keyboards report a composition only through
    // keyCode 229 and leave `isComposing` false.
    const wrapper = setup();
    await wrapper.get("textarea").setValue("你好");
    await wrapper.get("textarea").trigger("keydown", { key: "Enter", keyCode: 229 });
    expect(wrapper.emitted("send")).toBeUndefined();

    await wrapper.get("textarea").trigger("keydown", { key: "Enter" });
    expect(wrapper.emitted("send")?.[0]).toEqual(["你好"]);
  });

  it("never submits during IME composition", async () => {
    const wrapper = setup({ modelValue: "拼音输入" });
    await wrapper.get("textarea").trigger("keydown", { key: "Enter", isComposing: true });
    expect(wrapper.emitted("send")).toBeUndefined();
    await nextTick();
  });
});
