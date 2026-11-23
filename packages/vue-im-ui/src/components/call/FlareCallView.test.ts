// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { defineComponent, h, nextTick, ref, type Component, type VNode } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import FlareCallView from "./FlareCallView.vue";
import FlareGroupCallView from "./FlareGroupCallView.vue";

/** Slot functions by name, as `h` takes them. */
type SlotFns = Record<string, (scope: never) => VNode | VNode[]>;

function mountIn(component: Component, props: Record<string, unknown>, slots: SlotFns = {}) {
  return mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(component, props, slots);
  } }), { attachTo: document.body });
}

const base = { peerName: "周屿", state: "connected", durationLabel: "01:02" };

describe("failed call recovery", () => {
  for (const component of [FlareCallView, FlareGroupCallView]) {
    it(`${component.__name} disables media controls until the host has a media session, while hangup remains available`, async () => {
      const waiting = ref(true), hangup = vi.fn();
      const view = mount(defineComponent({setup(){useFlareI18nProvider('zh-CN');return()=>h(component as Component,{peerName:'周屿',title:'群',participants:[],mode:'audio',state:'connecting',controlsDisabled:waiting.value,onHangup:hangup});}}));
      const mic=()=>view.get('[role="switch"]');expect(mic().attributes('disabled')).toBeDefined();
      await view.findAll('button').find(b=>b.text()==='挂断')!.trigger('click');expect(hangup).toHaveBeenCalledOnce();
      waiting.value=false;await nextTick();expect(mic().attributes('disabled')).toBeUndefined();view.unmount();
    });
    it(`${component.__name} announces one failure and trades the control bar for close and call again`, async () => {
      const onHangup = vi.fn();
      const onClose = vi.fn();
      const onRecover = vi.fn();
      const view = mountIn(component as Component, {
        peerName: "周屿", title: "项目群", participants: [], mode: "video", state: "failed",
        statusDetail: "通话连接失败", onHangup, onClose, onRecover,
      });
      expect(view.text().match(/通话连接失败/g)).toHaveLength(1);
      // §3.3: no media keys on a failed call, only the two keys in their place.
      expect(view.find(".flare-call-controls").exists()).toBe(false);
      await view.get("[data-call-close]").trigger("click");
      expect(onClose).toHaveBeenCalledOnce();
      expect(onHangup).not.toHaveBeenCalled();
      const redial = view.get("[data-call-redial]");
      expect(redial.text()).toBe("重拨");
      expect(redial.classes()).toContain("flare-button--primary");
      await redial.trigger("click");
      expect(onRecover).toHaveBeenCalledOnce();
      view.unmount();
    });

    it(`${component.__name} offers call again only when the host can, under the host's label`, () => {
      const plain = mountIn(component as Component, { peerName: "周屿", participants: [], mode: "audio", state: "failed" });
      expect(plain.find("[data-call-close]").text()).toBe("关闭");
      expect(plain.find("[data-call-redial]").exists()).toBe(false);
      plain.unmount();
      const labelled = mountIn(component as Component, { peerName: "周屿", participants: [], mode: "audio", state: "failed", recoveryText: "再呼一次", onRecover: () => {} });
      expect(labelled.get("[data-call-redial]").text()).toBe("再呼一次");
      labelled.unmount();
    });

    it(`${component.__name} says the host's failure reason as the status itself, call.failed without one`, () => {
      const status = (view: ReturnType<typeof mountIn>) => view.findAll(component === FlareCallView ? ".flare-call-view__status" : ".flare-group-call__meta");
      const reason = mountIn(component as Component, { peerName: "周屿", participants: [], mode: "audio", state: "failed", statusDetail: "对方暂时无法接听" });
      expect(status(reason)).toHaveLength(1);
      expect(status(reason)[0]!.text()).toContain("对方暂时无法接听");
      expect(reason.text()).not.toContain("通话连接失败");
      reason.unmount();
      const plain = mountIn(component as Component, { peerName: "周屿", participants: [], mode: "audio", state: "failed" });
      expect(status(plain)).toHaveLength(1);
      expect(status(plain)[0]!.text()).toContain("通话连接失败");
      plain.unmount();
    });

    it(`${component.__name} draws minimize only while someone listens, and emits it`, async () => {
      const bare = mountIn(component as Component, { peerName: "周屿", participants: [], mode: "audio", state: "connected" });
      expect(bare.find('[aria-label="最小化"]').exists()).toBe(false);
      bare.unmount();
      const onMinimize = vi.fn();
      const wired = mountIn(component as Component, { peerName: "周屿", participants: [], mode: "audio", state: "connected", onMinimize });
      await wired.get('[aria-label="最小化"]').trigger("click");
      expect(onMinimize).toHaveBeenCalledOnce();
      // Outside a call window there is nothing to expand.
      expect(wired.find("[data-call-expand]").exists()).toBe(false);
      wired.unmount();
    });

    it(`${component.__name} preserves a distinct recovery explanation`, () => {
      const view = mountIn(component as Component, {
        peerName: "周屿", title: "项目群", participants: [], mode: "audio", state: "failed",
        statusDetail: "连接中断，请关闭后重新发起。", recoveryText: "关闭",
      });
      expect(view.text()).toContain("连接中断，请关闭后重新发起。");
      view.unmount();
    });
  }
});

describe("the end of a one-to-one call", () => {
  it("says it ended with the duration and leaves every control inert, hangup included", () => {
    const view = mountIn(FlareCallView as Component, { ...base, mode: "audio", state: "ended", durationLabel: "03:24" });
    expect(view.get(".flare-call-view__status").text()).toBe("通话已结束 · 03:24");
    expect(view.get(".flare-call-view__controls").attributes("inert")).toBeDefined();
    view.unmount();
    const bare = mountIn(FlareCallView as Component, { peerName: "周屿", mode: "audio", state: "ended" });
    expect(bare.get(".flare-call-view__status").text()).toBe("通话已结束");
    bare.unmount();
  });

  it("names the end-to-end encryption from the strings table", () => {
    const view = mountIn(FlareCallView as Component, { ...base, mode: "audio", encrypted: true });
    expect(view.get(".flare-call-view__secure").text()).toBe("端到端加密");
    view.unmount();
  });

  it("draws a reconnecting dot before the status", () => {
    const view = mountIn(FlareCallView as Component, { ...base, mode: "audio", state: "reconnecting" });
    expect(view.find(".flare-call-view__status .flare-call-view__dot").exists()).toBe(true);
    view.unmount();
  });
});

describe("the peer on a one-to-one call", () => {
  it("adds and removes the local preview as camera capture settles", async () => {
    const cameraReady = ref(false);
    const view = mount(defineComponent({ setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareCallView, { ...base, state: "connected", mode: "video" },
        cameraReady.value ? { localVideo: () => h("video", { class: "mine" }) } : {});
    } }));
    expect(view.find(".flare-call-view__local").exists()).toBe(false);
    cameraReady.value = true;
    await nextTick();
    expect(view.find(".flare-call-view__local .mine").exists()).toBe(true);
    expect(view.get(".flare-call-view").classes()).toContain("flare-call-view--preview");
    cameraReady.value = false;
    await nextTick();
    expect(view.find(".flare-call-view__local").exists()).toBe(false);
    expect(view.get(".flare-call-view").classes()).not.toContain("flare-call-view--preview");
    view.unmount();
  });
  it("says a muted peer in words after the status line (§12.17), and nothing otherwise", () => {
    const muted = mountIn(FlareCallView as Component, { ...base, mode: "audio", peerMuted: true });
    const status = muted.get(".flare-call-view__status");
    expect(status.get(".flare-call-view__muted").text()).toBe("对方已静音");
    expect(status.text()).toMatch(/^01:02\s*对方已静音$/);
    muted.unmount();
    const open = mountIn(FlareCallView as Component, { ...base, mode: "audio" });
    expect(open.find(".flare-call-view__muted").exists()).toBe(false);
    open.unmount();
  });

  it("moves name and status to the top bar only once the call is connected with the peer's video", () => {
    const video = () => h("video", { class: "theirs" });
    const ringing = mountIn(FlareCallView as Component, { ...base, mode: "video", state: "ringing" }, { video });
    expect(ringing.find(".flare-call-view__bar .flare-call-view__peer").exists()).toBe(false);
    expect(ringing.get(".flare-call-view__stage .flare-call-view__status").text()).toBe("对方响铃中…");
    ringing.unmount();
    const connected = mountIn(FlareCallView as Component, { ...base, mode: "video", peerMuted: true }, { video });
    expect(connected.find(".flare-call-view__stage .flare-call-view__peer").exists()).toBe(false);
    expect(connected.get(".flare-call-view__bar .flare-call-view__name").text()).toBe("周屿");
    expect(connected.get(".flare-call-view__bar .flare-call-view__muted").text()).toBe("对方已静音");
    connected.unmount();
  });

  it("rings a speaking peer's avatar, never while the peer is muted", () => {
    const speaking = mountIn(FlareCallView as Component, { ...base, mode: "audio", peerSpeaking: true });
    expect(speaking.get(".flare-call-view__avatar").classes()).toContain("is-speaking");
    speaking.unmount();
    const muted = mountIn(FlareCallView as Component, { ...base, mode: "audio", peerSpeaking: true, peerMuted: true });
    expect(muted.get(".flare-call-view__avatar").classes()).not.toContain("is-speaking");
    muted.unmount();
  });

  it("draws the host's camera as the corner preview in video calls only", () => {
    const localVideo = () => h("video", { class: "mine" });
    const video = mountIn(FlareCallView as Component, { ...base, mode: "video" }, { localVideo });
    expect(video.find(".flare-call-view__local .mine").exists()).toBe(true);
    // The peer block makes room below the preview.
    expect(video.get(".flare-call-view").classes()).toContain("flare-call-view--preview");
    video.unmount();
    const voice = mountIn(FlareCallView as Component, { ...base, mode: "audio" }, { localVideo });
    expect(voice.find(".flare-call-view__local").exists()).toBe(false);
    expect(voice.get(".flare-call-view").classes()).not.toContain("flare-call-view--preview");
    voice.unmount();
  });
});

describe("the picture in picture and the top bar of a video call (§3.3)", () => {
  const slots = { video: () => h("video", { class: "theirs" }), localVideo: () => h("video", { class: "mine" }) };
  const pointer = (type: string, x: number, y: number) => new PointerEvent(type, { bubbles: true, clientX: x, clientY: y, pointerId: 1 });

  it("swaps the two pictures on a tap and on Enter, without remounting either", async () => {
    const view = mountIn(FlareCallView as Component, { ...base, mode: "video" }, slots);
    const mine = view.get(".flare-call-view__local .mine").element;
    expect(view.get("[data-call-pip]").attributes("aria-label")).toBe("互换画面");
    view.get("[data-call-pip]").element.dispatchEvent(pointer("pointerdown", 300, 100));
    window.dispatchEvent(pointer("pointerup", 302, 101));
    await nextTick();
    expect(view.get(".flare-call-view__local").classes()).toContain("is-full");
    expect(view.get(".flare-call-view__video").classes()).toContain("is-pip");
    expect(view.get(".flare-call-view__local .mine").element).toBe(mine);
    await view.get("[data-call-pip]").trigger("keydown", { key: "Enter" });
    expect(view.get(".flare-call-view__local").classes()).toContain("is-pip");
    view.unmount();
  });

  it("follows a drag and snaps to the nearest corner on release", async () => {
    const view = mountIn(FlareCallView as Component, { ...base, mode: "video" }, slots);
    view.get(".flare-call-view").element.getBoundingClientRect = () =>
      ({ left: 0, top: 0, width: 400, height: 800, right: 400, bottom: 800, x: 0, y: 0, toJSON: () => ({}) }) as DOMRect;
    const pip = () => view.get("[data-call-pip]");
    expect(pip().classes()).toEqual(expect.arrayContaining(["is-top", "is-end"]));
    pip().element.dispatchEvent(pointer("pointerdown", 350, 100));
    window.dispatchEvent(pointer("pointermove", 60, 700));
    await nextTick();
    expect(pip().classes()).toContain("is-dragging");
    expect(pip().attributes("style")).toContain("translate(-290px, 600px)");
    window.dispatchEvent(pointer("pointerup", 60, 700));
    await nextTick();
    expect(pip().classes()).toEqual(expect.arrayContaining(["is-bottom", "is-start"]));
    expect(pip().classes()).not.toContain("is-dragging");
    // A drag is not a tap: the pictures stay where they were.
    expect(view.get(".flare-call-view__local").classes()).toContain("is-pip");
    view.unmount();
  });

  it("fades the top bar after 4 s of stillness and brings it back on a pointer move", async () => {
    vi.useFakeTimers();
    const media = window.matchMedia;
    window.matchMedia = ((query: string) => ({ matches: false, media: query })) as unknown as typeof window.matchMedia;
    try {
      const view = mountIn(FlareCallView as Component, { ...base, mode: "video" }, slots);
      vi.advanceTimersByTime(3999);
      await nextTick();
      expect(view.get(".flare-call-view").classes()).not.toContain("is-chrome-hidden");
      vi.advanceTimersByTime(1);
      await nextTick();
      expect(view.get(".flare-call-view").classes()).toContain("is-chrome-hidden");
      await view.get(".flare-call-view").trigger("pointermove");
      expect(view.get(".flare-call-view").classes()).not.toContain("is-chrome-hidden");
      view.unmount();
      // Voice calls keep their bar.
      const voice = mountIn(FlareCallView as Component, { ...base, mode: "audio" });
      vi.advanceTimersByTime(4000);
      await nextTick();
      expect(voice.get(".flare-call-view").classes()).not.toContain("is-chrome-hidden");
      voice.unmount();
    } finally {
      window.matchMedia = media;
      vi.useRealTimers();
    }
  });

  it("never fades the top bar under reduced motion", async () => {
    vi.useFakeTimers();
    const media = window.matchMedia;
    window.matchMedia = ((query: string) => ({ matches: query.includes("reduced-motion"), media: query })) as unknown as typeof window.matchMedia;
    try {
      const view = mountIn(FlareCallView as Component, { ...base, mode: "video" }, slots);
      vi.advanceTimersByTime(8000);
      await nextTick();
      expect(view.get(".flare-call-view").classes()).not.toContain("is-chrome-hidden");
      view.unmount();
    } finally {
      window.matchMedia = media;
      vi.useRealTimers();
    }
  });
});

describe("group call tiles", () => {
  it("name the local tile call.you and draw no encryption line unless asked", () => {
    const view = mountIn(FlareGroupCallView as Component, {
      mode: "audio", state: "connected",
      participants: [{ id: "me", name: "林晓", isSelf: true }, { id: "b", name: "B" }],
    });
    expect(view.findAll(".flare-group-call__label").map((n) => n.text())).toEqual(["我", "B"]);
    expect(view.find(".flare-group-call__secure").exists()).toBe(false);
    view.unmount();
  });

  it("ask the host for video only where the camera is on, and show the avatar elsewhere", () => {
    const asked: string[] = [];
    const tile = ({ participant }: { participant: { id: string } }) => {
      asked.push(participant.id);
      // No stream for c yet: an empty answer, so the kit shows the avatar.
      return participant.id === "a" ? h("video", { class: "stream" }) : [];
    };
    const view = mountIn(
      FlareGroupCallView as Component,
      {
        mode: "video",
        state: "connected",
        participants: [
          { id: "a", name: "A", speaking: true, muted: true },
          { id: "b", name: "B", cameraOff: true },
          { id: "c", name: "C" },
        ],
      },
      { tile },
    );
    expect(asked).toEqual(["a", "c"]);
    expect(view.findAll(".flare-group-call__stream .stream")).toHaveLength(1);
    expect(view.findAll(".flare-group-call__stream .im-avatar")).toHaveLength(2);
    // The video tile keeps its chrome: the speaking ring, the mute badge and the name over the stream.
    const streaming = view.findAll(".flare-group-call__tile")[0]!;
    expect(streaming.classes()).toContain("is-speaking");
    expect(streaming.find(".flare-group-call__mic").exists()).toBe(true);
    expect(streaming.get(".flare-group-call__pname").text()).toBe("A");
    view.unmount();
  });

  it("never ask the host in an audio call", () => {
    const asked: string[] = [];
    const tile = ({ participant }: { participant: { id: string } }) => {
      asked.push(participant.id);
      return h("video", { class: "stream" });
    };
    const view = mountIn(
      FlareGroupCallView as Component,
      { mode: "audio", state: "connected", participants: [{ id: "a", name: "A" }] },
      { tile },
    );
    expect(asked).toEqual([]);
    expect(view.findAll(".flare-group-call__stream .im-avatar")).toHaveLength(1);
    view.unmount();
  });
  it("enlarge a tapped tile over a strip of the others, restore on a second tap, and forget one who leaves", async () => {
    const people = ref([{ id: "a", name: "A" }, { id: "b", name: "B" }, { id: "c", name: "C" }]);
    const selected: string[] = [];
    const view = mount(defineComponent({ setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareGroupCallView, { mode: "video", state: "connected", participants: people.value, onSelectParticipant: (id: string) => selected.push(id) });
    } }), { attachTo: document.body });
    const grid = () => view.get(".flare-group-call__grid");
    const tile = (id: string) => view.get(`[data-participant="${id}"]`);
    expect(grid().classes()).not.toContain("is-focused");
    await tile("b").trigger("click");
    expect(grid().classes()).toContain("is-focused");
    expect(tile("b").classes()).toContain("is-main");
    expect(tile("b").attributes("aria-pressed")).toBe("true");
    expect(tile("a").classes()).not.toContain("is-main");
    // Another strip tile takes the main view; the main one tapped again restores the grid.
    await tile("c").trigger("click");
    expect(tile("c").classes()).toContain("is-main");
    await tile("c").trigger("click");
    expect(grid().classes()).not.toContain("is-focused");
    expect(selected).toEqual(["b", "c", "c"]);
    // The enlarged person leaves: the grid comes back and stays back when they rejoin.
    await tile("a").trigger("click");
    people.value = people.value.filter(p => p.id !== "a");
    await nextTick();
    expect(grid().classes()).not.toContain("is-focused");
    people.value = [{ id: "a", name: "A" }, ...people.value];
    await nextTick();
    expect(grid().classes()).not.toContain("is-focused");
    view.unmount();
  });

  it("draw add member only while the host listens to addMember", async () => {
    const people = [{ id: "a", name: "A" }];
    const bare = mountIn(FlareGroupCallView as Component, { mode: "audio", state: "connected", participants: people });
    expect(bare.findAll(".flare-call-controls .lbl").map(n => n.text())).not.toContain("加人");
    bare.unmount();
    const onAddMember = vi.fn();
    const wired = mountIn(FlareGroupCallView as Component, { mode: "audio", state: "connected", participants: people, onAddMember });
    await wired.findAll("button").find(b => b.text() === "加人")!.trigger("click");
    expect(onAddMember).toHaveBeenCalledOnce();
    wired.unmount();
  });

  it("count only the people who joined in the header, not those still being called", () => {
    const view = mountIn(FlareGroupCallView as Component, {
      mode: "audio", state: "connected", durationLabel: "08:41",
      participants: [{ id: "a", name: "A" }, { id: "b", name: "B" }, { id: "c", name: "C", calling: true }],
    });
    expect(view.get(".flare-group-call__meta").text()).toBe("2 人 · 08:41");
    view.unmount();
  });

  it("lay out up to 12 people: 3 as 2 over 1, 10–12 as 4×3 on PC and 3×4 on phones (§12.16)", () => {
    const people = (n: number) => Array.from({ length: n }, (_, i) => ({ id: `p${i}`, name: `P${i}` }));
    const grid = (n: number, phone = false) => {
      const view = mount(defineComponent({ setup() {
        useFlareI18nProvider("zh-CN");
        if (phone) useFlarePlatformProvider({ capabilities: { bottomSheet: true } });
        return () => h(FlareGroupCallView, { mode: "video", state: "connected", participants: people(n) });
      } }));
      const style = view.get(".flare-group-call__grid").attributes("style") ?? "";
      view.unmount();
      return [Number(/--flare-group-cols: (\d+)/.exec(style)?.[1]), Number(/--flare-group-rows: (\d+)/.exec(style)?.[1])];
    };
    expect(grid(1)).toEqual([1, 1]);
    expect(grid(3)).toEqual([2, 2]);
    expect(grid(6)).toEqual([3, 2]);
    expect(grid(6, true)).toEqual([2, 3]);
    expect(grid(9)).toEqual([3, 3]);
    for (const n of [10, 11, 12]) {
      expect(grid(n)).toEqual([4, 3]);
      expect(grid(n, true)).toEqual([3, 4]);
    }
  });

  it("never enlarge the only tile", async () => {
    const view = mountIn(FlareGroupCallView as Component, { mode: "audio", state: "connected", participants: [{ id: "a", name: "A" }] });
    await view.get("[data-participant=\"a\"]").trigger("click");
    expect(view.get(".flare-group-call__grid").classes()).not.toContain("is-focused");
    expect(view.get("[data-participant=\"a\"]").attributes("aria-pressed")).toBeUndefined();
    view.unmount();
  });
});
