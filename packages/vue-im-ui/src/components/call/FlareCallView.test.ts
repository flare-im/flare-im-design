// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { defineComponent, h, type Component, type VNode } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
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

describe("the peer on a one-to-one call", () => {
  it("names a muted peer's badge and draws none otherwise", () => {
    const muted = mountIn(FlareCallView as Component, { ...base, mode: "audio", peerMuted: true });
    expect(muted.get(".flare-call-view__muted").attributes("aria-label")).toBe("对方已静音");
    muted.unmount();
    const open = mountIn(FlareCallView as Component, { ...base, mode: "audio" });
    expect(open.find(".flare-call-view__muted").exists()).toBe(false);
    open.unmount();
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

describe("group call tiles", () => {
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
});
