// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import {
  flareCallDurationLabel,
  flareCallRecordAction,
  flareCallRecordStatus,
  flareCallRecordTone,
  type FlareCallRecordFacts,
} from "../../shared/contracts/call";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareCallRecordCard from "./FlareCallRecordCard.vue";

interface CallRecordCase {
  id: string;
  input: FlareCallRecordFacts & { busy?: boolean };
  status: string;
  tone: string;
  action: string | null;
  actionEnabled: boolean;
  text: { zh: string; en: string };
}
const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/call-record-vectors.json"), "utf8")) as {
  duration: Array<{ seconds: number; label: string }>;
  cases: CallRecordCase[];
};

function render(props: InstanceType<typeof FlareCallRecordCard>["$props"], locale: "zh-CN" | "en-US" = "zh-CN") {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareCallRecordCard, props);
    },
  }));
}

describe("call record rules (spec/call-record-vectors.json)", () => {
  it("formats a call's length the way the table does", () => {
    expect(vectors.duration.length).toBeGreaterThanOrEqual(10);
    for (const row of vectors.duration) expect(flareCallDurationLabel(row.seconds), String(row.seconds)).toBe(row.label);
  });

  it("derives status, tone and action for every case", () => {
    expect(vectors.cases.length).toBeGreaterThanOrEqual(30);
    for (const row of vectors.cases) {
      const status = flareCallRecordStatus(row.input);
      expect(status, row.id).toBe(row.status);
      expect(flareCallRecordTone(status), row.id).toBe(row.tone);
      expect(flareCallRecordAction(row.input), row.id).toBe(row.action);
    }
  });
});

describe("FlareCallRecordCard", () => {
  it("renders every case's copy, tone and action in both languages", () => {
    for (const row of vectors.cases) {
      for (const [locale, text] of [["zh-CN", row.text.zh], ["en-US", row.text.en]] as const) {
        const wrapper = render(row.input, locale);
        const root = wrapper.get(".flare-call-record");
        expect(wrapper.get("[data-call-record-status]").text(), `${row.id} ${locale}`).toBe(text);
        expect(root.attributes("data-tone"), row.id).toBe(row.tone);
        expect(root.attributes("aria-label"), row.id).toContain(text);
        const button = wrapper.find("[data-call-record-action]");
        expect(button.exists(), row.id).toBe(row.action !== null);
        if (row.action) {
          expect(button.attributes("data-call-record-action"), row.id).toBe(row.action);
          expect(button.attributes("disabled") === undefined, row.id).toBe(row.actionEnabled);
        }
        wrapper.unmount();
      }
    }
  });

  it("names the media and keeps the icon out of the accessibility tree", () => {
    const voice = render({ media: "audio", scope: "single", state: "ended", endReason: "missed", viewerIsInitiator: false, canJoin: false, canCallBack: false });
    expect(voice.get(".flare-call-record").attributes("role")).toBe("group");
    expect(voice.get(".flare-call-record").attributes("aria-label")).toBe("语音通话，未接听");
    expect(voice.get(".flare-call-record__icon").attributes("aria-hidden")).toBe("true");
    const video = render({ media: "video", scope: "single", state: "ringing", viewerIsInitiator: true, canJoin: false, canCallBack: false }, "en-US");
    expect(video.get(".flare-call-record").attributes("aria-label")).toBe("Video call, Waiting for answer");
  });

  it("emits join and callBack from its one action, and nothing while busy", async () => {
    const join = render({ media: "video", scope: "group", state: "ongoing", joinedCount: 4, viewerIsInitiator: false, canJoin: true, canCallBack: false });
    await join.get("[data-call-record-action]").trigger("click");
    const joinCard = join.findComponent(FlareCallRecordCard);
    expect(joinCard.emitted("join")).toHaveLength(1);
    expect(joinCard.emitted("callBack")).toBeUndefined();
    expect(join.get("[data-call-record-action]").text()).toBe("加入");

    const callBack = render({ media: "audio", scope: "single", state: "ended", endReason: "completed", durationSeconds: 75, viewerIsInitiator: true, canJoin: false, canCallBack: true }, "en-US");
    await callBack.get("[data-call-record-action]").trigger("click");
    expect(callBack.findComponent(FlareCallRecordCard).emitted("callBack")).toHaveLength(1);
    expect(callBack.get("[data-call-record-action]").text()).toBe("Call back");

    const busy = render({ media: "audio", scope: "single", state: "ended", endReason: "missed", viewerIsInitiator: false, canJoin: false, canCallBack: true, busy: true });
    const button = busy.get("[data-call-record-action]");
    expect(button.attributes("aria-busy")).toBe("true");
    await button.trigger("click");
    expect(busy.findComponent(FlareCallRecordCard).emitted("callBack")).toBeUndefined();
  });

  it("keeps the record but drops the action when the plugin is unavailable", () => {
    const wrapper = render({ media: "audio", scope: "group", state: "ongoing", joinedCount: 2, viewerIsInitiator: false, canJoin: true, canCallBack: true, disabled: true });
    expect(wrapper.get("[data-call-record-status]").text()).toBe("群通话进行中 · 2 人");
    expect(wrapper.find("[data-call-record-action]").exists()).toBe(false);
    expect(wrapper.get(".flare-call-record").classes()).not.toContain("has-action");
  });
});
