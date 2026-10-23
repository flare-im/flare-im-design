<script setup>
import { computed, ref } from "vue";
import { FlarePluginView, FlareSegmentedControl } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 核心 SDK 解析好的五种办公插件卡片；点选项或按钮只回传动作 id 和载荷，这里在本地模拟宿主的结果。
const op = (id, label, extra = {}) => ({ id, label, target: { kind: "operation", operation: id }, input: {}, ...extra });
const now = Date.now();
const users = {
  u1: { name: "Ivy Chen" },
  u2: { name: "周屿" },
  u3: { name: "Leo Wang" },
};
const poll = (voted) => ({
  available: true,
  title: "周五团建去哪儿？",
  fields: [],
  actions: [op("close", "结束投票", { style: "danger", confirm: "结束后不能再投票，确定结束吗？" })],
  blocks: [
    {
      kind: "choices",
      options: voted
        ? [{ index: 0, label: "爬山", selected: false, count: 3, percent: 30 }, { index: 1, label: "桌游", selected: true, count: 6, percent: 60 }, { index: 2, label: "烧烤", selected: false, count: 1, percent: 10 }]
        : [{ index: 0, label: "爬山", selected: false }, { index: 1, label: "桌游", selected: false }, { index: 2, label: "烧烤", selected: false }],
      multiple: false, voted, closed: false, showResults: voted, total: voted ? 10 : undefined, inputName: "selection",
      action: op("vote", "投票"),
    },
    { kind: "time", label: "截止", atMs: now + 5 * 3_600_000, countdown: true },
  ],
});
const samples = {
  投票: poll(false),
  接龙: {
    available: true, title: "周末读书会报名", fields: [], detail: true,
    actions: [op("join", "参与接龙", { style: "primary", form: ["line"] })],
    blocks: [
      { kind: "text", text: "每人写一本想读的书，周日晚上截止。", maxLines: 3, style: "body" },
      { kind: "entries", items: [{ index: 1, text: "《三体》", userId: "u1" }, { index: 2, text: "《活着》", userId: "u2" }, { index: 3, text: "《百年孤独》", userId: "u3" }], numbered: true, total: 12, more: true },
    ],
    inputs: [{ id: "line", kind: "textarea", label: "接龙内容", required: true, maxLength: 200, placeholder: "写下你的内容" }],
  },
  任务: {
    available: true, title: "整理 Q4 需求文档", fields: [], actions: [op("complete", "完成", { style: "primary" })],
    blocks: [
      { kind: "status", label: "状态", text: "进行中", tone: "info" },
      { kind: "people", groups: [{ label: "负责人", userIds: ["u1", "u2", "u3"], count: 3 }] },
      { kind: "progress", label: "完成进度", value: 1, total: 3, percent: 33 },
      { kind: "time", label: "截止", atMs: now + 3 * 86_400_000, countdown: false },
    ],
  },
  日程: {
    available: true, title: "产品评审会", fields: [], actions: [op("cancel", "取消日程", { style: "danger", confirm: "取消后所有人都会收到通知。" })],
    blocks: [
      { kind: "time", label: "时间", atMs: now + 3_600_000, endMs: now + 2 * 3_600_000, countdown: false },
      { kind: "fields", fields: [{ label: "地点", value: "3 楼大会议室" }] },
      { kind: "choices", options: [{ index: 0, label: "接受", selected: false, count: 5, percent: 83 }, { index: 1, label: "待定", selected: false, count: 1, percent: 17 }, { index: 2, label: "拒绝", selected: false, count: 0, percent: 0 }], multiple: false, voted: false, closed: false, showResults: true, total: 6, inputName: "response", action: op("rsvp", "回复") },
    ],
  },
  公告: {
    available: true, title: "关于国庆假期安排的通知", fields: [], actions: [op("confirm", "确认已读", { style: "primary" })],
    blocks: [
      { kind: "text", text: "各位同事：\n10 月 1 日至 7 日放假，8 日正常上班。\n值班安排见附件，请按时确认。\n如有冲突请联系行政。\n祝大家假期愉快！", maxLines: 3, style: "body" },
      { kind: "progress", label: "已确认", value: 8, total: 20, percent: 40 },
      { kind: "people", groups: [{ label: "已确认", userIds: ["u1", "u2"], count: 8, tone: "success" }, { label: "未确认", userIds: ["u3"], count: 12, tone: "warning" }] },
    ],
  },
};
// Protocol v2: end and cancel live in the card's ⋯ menu; a stopped plugin says why; a forwarded copy is read-only.
samples["菜单"] = { ...poll(false), actions: [], menuActions: [op("close", "结束投票", { style: "danger", confirm: "结束后不能再投票，确定结束吗？", placement: "menu" }), op("cancel", "取消投票", { style: "danger", confirm: "取消后投票作废，确定取消吗？", placement: "menu" })] };
// A multiple choice capped at two: once two are ticked the others wait; a ledger's lines carry their kind as a badge.
samples["多选上限"] = {
  available: true, title: "周末活动（最多两项）", fields: [], actions: [],
  blocks: [{
    kind: "choices",
    options: [{ index: 0, label: "爬山", selected: false }, { index: 1, label: "看展", selected: false }, { index: 2, label: "露营", selected: false }, { index: 3, label: "桌游", selected: false }],
    multiple: true, voted: false, closed: false, showResults: false, inputName: "selection", maxSelections: 2, action: op("vote", "投票"),
  }],
};
samples["徽标"] = {
  available: true, title: "红包明细", fields: [], actions: [],
  blocks: [{
    kind: "entries", numbered: false, total: 3, more: false,
    items: [
      { index: 1, text: "+¥2.30", userId: "u1", badge: { text: "收到红包", tone: "success" } },
      { index: 2, text: "-¥10.00", userId: "u2", badge: { text: "发出红包", tone: "neutral" } },
      { index: 3, text: "+¥3.00", badge: { text: "红包退回", tone: "warning" } },
    ],
  }],
};
samples["已停用"] = { available: false, unavailableReason: "disabled", title: "周五团建去哪儿？", fields: [], actions: [] };
samples["副本"] = { ...poll(true), actions: [], unavailableReason: "unbound_copy", blocks: poll(true).blocks.map((block) => (block.kind === "choices" ? { ...block, action: undefined } : block)) };
const names = Object.keys(samples);
const pick = ref(0);
const voted = ref(false);
const busyActionId = ref(undefined);
const log = ref("");
const view = computed(() => (pick.value === 0 && voted.value ? poll(true) : samples[names[pick.value]]));
function onAction(id, payload) {
  log.value = `action(${id}, ${JSON.stringify(payload)})`;
  busyActionId.value = id;
  setTimeout(() => {
    busyActionId.value = undefined;
    if (id === "vote") voted.value = true;
  }, 600);
}
</script>
<template>
  <DemoStage>
    <FlareSegmentedControl v-model="pick" class="switch" :options="names" />
    <FlarePluginView
      :view="view"
      icon="plugin"
      display-name="投票"
      viewer-id="u2"
      :busy-action-id="busyActionId"
      :resolve-user="(id) => users[id]"
      @action="onAction"
      @open-detail="log = 'openDetail()'"
    />
    <p v-if="log" class="note">{{ log }}</p>
  </DemoStage>
</template>
<style scoped>
.switch { margin-bottom: 12px; }
.note { margin: 8px 0 0; font-size: 13px; color: var(--flare-color-text-secondary); }
</style>
