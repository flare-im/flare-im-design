<script setup>
import { ref, computed, onMounted } from "vue";
import { useData } from "vitepress";
import { flarePresets, applyFlareTheme } from "../../../../tokens/theme.js";
import DemoIcon from "./DemoIcon.vue";
import { tint } from "./tint.js";
import FlareMessageBubble from "flare-core-vue-im-ui/components/messages/MessageBubble.vue";
import DemoStage from "./DemoStage.vue";

// The homepage signature: a whole IM surface, composed from the kit and
// re-themed live. Everything below is driven by the same tokens the four
// platform packages consume. Content is localized off the active VitePress locale.
const { lang } = useData();
const en = computed(() => lang.value.startsWith("en"));

const stage = ref(null);
const active = ref("violet");
function usePreset(name) {
  active.value = name;
  if (stage.value) applyFlareTheme(flarePresets[name], stage.value);
}
onMounted(() => usePreset("violet"));

const T = computed(() =>
  en.value
    ? {
        theme: "Theme", search: "Search", online: "Online", today: "Today",
        placeholder: "Message…",
        caption: "One token source drives four platforms — change the theme by editing a single variable source, and Vue / Flutter / iOS / Android all recolor.",
        rooms: [
          { id: "r1", n: "Ivy Chen", i: "IC", c: "#6D5DF6", p: "The new mockups are up", t: "14:30", u: 0, on: true },
          { id: "r2", n: "Design Team", i: "D", c: "#22C55E", p: "Kai: schedule updated", t: "13:05", u: 2 },
          { id: "r3", n: "Henry Ford", i: "HF", c: "#7C3AED", p: "Got it, will handle it", t: "Yesterday", u: 0 },
        ],
        thread: [
          { id: 1, kind: "date", text: "Today" },
          { id: 2, self: false, ini: "I", c: "#6D5DF6", text: "The new mockups are up — mind a look at the interactions?", time: "14:30" },
          { id: 3, self: true, text: "Sure, I'll go through them this afternoon", time: "14:31" },
          { id: 4, self: true, text: "Direction looks right to me", time: "14:32", read: true },
        ],
      }
    : {
        theme: "主题", search: "搜索", online: "在线", today: "今天",
        placeholder: "发送消息…",
        caption: "同一份 tokens 驱动四端 —— 换主题只改一个变量源，Vue / Flutter / iOS / Android 同步变色。",
        rooms: [
          { id: "r1", n: "Ivy Chen", i: "IC", c: "#6D5DF6", p: "新版设计稿已经上传啦", t: "14:30", u: 0, on: true },
          { id: "r2", n: "产品设计群", i: "产", c: "#22C55E", p: "Kai: 排期已更新", t: "13:05", u: 2 },
          { id: "r3", n: "Henry Ford", i: "HF", c: "#7C3AED", p: "收到，稍后处理", t: "昨天", u: 0 },
        ],
        thread: [
          { id: 1, kind: "date", text: "今天" },
          { id: 2, self: false, ini: "I", c: "#6D5DF6", text: "新版设计稿已经上传啦，帮忙看下交互细节～", time: "14:30" },
          { id: 3, self: true, text: "收到，我下午过一遍给你反馈", time: "14:31" },
          { id: 4, self: true, text: "整体方向没问题", time: "14:32", read: true },
        ],
      },
);
// soft pastel identity, keyed stably so a person keeps their tint across locales
const ivy = tint("Ivy Chen");
const rooms = computed(() => T.value.rooms.map((r) => ({ ...r, av: tint(r.n) })));
const thread = computed(() =>
  T.value.thread.map((m) => (m.self || m.kind ? m : { ...m, av: ivy })),
);

// Real message objects for the kit MessageBubble (the hero renders the shipped
// component, re-themed live by the same tokens the four platforms consume).
const bubbleThread = computed(() =>
  T.value.thread
    .filter((m) => !m.kind)
    .map((m, i) => ({
      row: {
        serverId: String(m.id),
        clientMsgId: String(m.id),
        senderId: m.self ? "me" : "ivy",
        senderDisplayName: m.self ? "" : "Ivy Chen",
        conversationSeq: m.id,
        createdAt: Date.now() + i,
        clientCreatedAt: Date.now() + i,
        messageType: 1,
        content: { contentType: "text", text: { text: m.text } },
        status: m.read ? 4 : 2,
        isRecalled: false,
        isRead: true,
        timelineKey: String(m.id),
        timelineSortTs: Date.now() + i,
      },
      self: !!m.self,
    })),
);
</script>

<template>
  <div class="showcase">
    <div class="chips">
      <span class="lead">{{ T.theme }}</span>
      <button
        v-for="(v, name) in flarePresets" :key="name"
        class="chip" :class="{ on: active === name }"
        @click="usePreset(name)"
      >
        <span class="dot" :style="{ background: v.primary }" />{{ name }}
      </button>
    </div>

    <div ref="stage" class="window">
      <div class="chrome"><i /><i /><i /></div>
      <div class="panes">
        <aside class="rail">
          <div class="search"><DemoIcon name="search" :size="15" /><span>{{ T.search }}</span></div>
          <button v-for="r in rooms" :key="r.id" class="room" :class="{ on: r.on }">
            <span class="av" :style="{ background: r.av.bg, color: r.av.fg }">{{ r.i }}</span>
            <span class="rmeta">
              <span class="l1"><b>{{ r.n }}</b><em>{{ r.t }}</em></span>
              <span class="l2"><span class="pv">{{ r.p }}</span><i v-if="r.u" class="badge">{{ r.u }}</i></span>
            </span>
          </button>
        </aside>

        <section class="chat">
          <header>
            <span class="av sm" :style="{ background: ivy.bg, color: ivy.fg }">IC</span>
            <span class="ht"><b>Ivy Chen</b><em>{{ T.online }}</em></span>
            <span class="hacts">
              <DemoIcon name="call" :size="17" />
              <DemoIcon name="video" :size="17" />
              <DemoIcon name="moreHoriz" :size="17" />
            </span>
          </header>

          <div class="canvas">
            <div class="date">{{ T.today }}</div>
            <DemoStage>
              <FlareMessageBubble
                v-for="(b, i) in bubbleThread"
                :key="i"
                :message="b.row"
                current-user-id="me"
                :self="b.self"
                conversation-type="single"
                :group-start="true"
                :group-end="true"
              />
            </DemoStage>
          </div>

          <footer>
            <DemoIcon name="mic" :size="19" />
            <DemoIcon name="plus" :size="19" />
            <span class="field">{{ T.placeholder }}</span>
            <DemoIcon name="emoji" :size="19" />
            <span class="send"><DemoIcon name="send" :size="16" /></span>
          </footer>
        </section>
      </div>
    </div>

    <p class="cap">{{ T.caption }}</p>
  </div>
</template>

<style scoped>
.showcase { display: flex; flex-direction: column; gap: 16px; }

.chips { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; }
.lead { font-size: 13px; color: var(--vp-c-text-3); margin-right: 2px; }
.chip { display: inline-flex; align-items: center; gap: 6px; padding: 4px 11px; border: 1px solid var(--vp-c-divider); border-radius: 999px; background: var(--vp-c-bg-soft); font-size: 12px; color: var(--vp-c-text-2); cursor: pointer; text-transform: capitalize; transition: border-color .15s, color .15s; }
.chip:hover { border-color: var(--vp-c-brand-1); }
.chip.on { border-color: var(--vp-c-brand-1); color: var(--vp-c-text-1); }
.dot { width: 10px; height: 10px; border-radius: 50%; }

.window { border: 1px solid var(--flare-color-border-primary); border-radius: 14px; overflow: hidden; background: var(--flare-color-bg-primary); box-shadow: 0 18px 48px rgba(0, 0, 0, .1); }
.chrome { display: flex; gap: 6px; padding: 10px 14px; border-bottom: 1px solid var(--flare-color-border-secondary); background: var(--flare-color-bg-secondary); }
.chrome i { width: 9px; height: 9px; border-radius: 50%; background: var(--flare-color-border-primary); }
.panes { display: flex; height: 372px; }

.rail { flex: 0 0 232px; display: flex; flex-direction: column; gap: 2px; padding: 10px; border-right: 1px solid var(--flare-color-border-secondary); background: var(--flare-color-bg-secondary); }
.search { display: flex; align-items: center; gap: 7px; padding: 7px 10px; margin-bottom: 6px; border-radius: 9px; background: var(--flare-color-bg-tertiary); color: var(--flare-color-text-tertiary); font-size: 13px; }
.room { display: flex; align-items: center; gap: 10px; padding: 9px 10px; border: none; border-radius: 10px; background: none; cursor: pointer; text-align: left; }
.room.on { background: var(--flare-color-bg-selected); }
.rmeta { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 3px; }
.l1, .l2 { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.l1 b { font-size: 13.5px; font-weight: 600; color: var(--flare-color-text-primary); }
.l1 em, .l2 .pv { font-style: normal; color: var(--flare-color-text-tertiary); }
.l1 em { font-size: 11px; flex: none; }
.l2 .pv { font-size: 12px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.badge { font-style: normal; flex: none; background: var(--flare-color-primary); color: #fff; font-size: 10px; font-weight: 600; min-width: 17px; height: 17px; border-radius: 999px; display: flex; align-items: center; justify-content: center; padding: 0 5px; }

.av { width: 38px; height: 38px; border-radius: 50%; flex: none; font-weight: 600; font-size: 12px; display: flex; align-items: center; justify-content: center; }
.av.sm { width: 32px; height: 32px; }
.av.xs { width: 26px; height: 26px; font-size: 11px; }

.chat { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.chat header { display: flex; align-items: center; gap: 10px; padding: 0 14px; height: 56px; border-bottom: 1px solid var(--flare-color-border-secondary); }
.ht { flex: 1; display: flex; flex-direction: column; }
.ht b { font-size: 14px; font-weight: 600; color: var(--flare-color-text-primary); }
.ht em { font-style: normal; font-size: 11px; color: var(--flare-color-success); }
.hacts { display: flex; gap: 14px; color: var(--flare-color-text-secondary); }

/* Pinned to the bottom like a real thread: when the viewport is too short the
   oldest message is clipped, never the newest. */
.canvas { flex: 1; min-height: 0; display: flex; flex-direction: column; justify-content: flex-end; gap: 8px; padding: 16px; background: var(--flare-color-bg-secondary); overflow: hidden; }
.date { align-self: center; font-size: 11px; color: var(--flare-color-text-tertiary); background: var(--flare-color-bg-tertiary); padding: 3px 11px; border-radius: 999px; }
.line { display: flex; gap: 8px; align-items: flex-end; }
.line.self { justify-content: flex-end; }
.bubble { max-width: 74%; padding: 9px 14px; border-radius: 16px 16px 16px 4px; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-secondary); box-shadow: 0 2px 10px rgba(0, 0, 0, .05); color: var(--flare-color-text-primary); font-size: 15px; line-height: 1.45; display: flex; flex-direction: column; align-items: flex-start; }
.bubble.self { background: var(--flare-color-bubble-self); border-color: transparent; color: #fff; border-radius: 16px 16px 4px 16px; align-items: flex-end; }
.meta { display: flex; align-items: center; gap: 3px; font-size: 11px; margin-top: 3px; color: var(--flare-color-text-tertiary); }
.bubble.self .meta { color: rgba(255, 255, 255, .8); }

.chat footer { display: flex; align-items: center; gap: 10px; padding: 10px 14px; border-top: 1px solid var(--flare-color-border-secondary); color: var(--flare-color-text-secondary); }
.field { flex: 1; padding: 8px 12px; border-radius: 11px; background: var(--flare-color-bg-secondary); color: var(--flare-color-text-tertiary); font-size: 13.5px; }
.send { width: 32px; height: 32px; border-radius: 50%; flex: none; background: var(--flare-color-primary); color: #fff; display: flex; align-items: center; justify-content: center; }

.cap { margin: 0; font-size: 13px; color: var(--vp-c-text-3); }

@media (max-width: 720px) {
  .rail { display: none; }
  .panes { height: 420px; }
  .bubble { max-width: 82%; }
}
</style>
