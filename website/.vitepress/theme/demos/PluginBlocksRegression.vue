<script setup>
import { FlarePluginUpgradeNotice, FlarePluginView } from "@flare-im/vue-ui/components";
// The visual gate of the plugin vocabulary 2 blocks (docs/plugin-components.md): every new block in one card, and
// the three forms of the upgrade notice. Fixed data and a fixed clock-free timeline, so captures are stable.
const op = (id, label, extra = {}) => ({ id, label, ...extra });
const AT = Date.UTC(2025, 0, 14, 6, 0);
const blocks = {
  available: true,
  title: "本周看板",
  fields: [],
  actions: [],
  blocks: [
    { kind: "hero", label: "可用余额", value: "¥128.60", amount: true, subtitle: "托管中 ¥6.00", tone: "brand", actions: [op("recharge", "充值", { style: "primary" }), op("withdraw", "提现")] },
    { kind: "stats", items: [
      { label: "进行中", value: "12", trend: { text: "+3", direction: "up" } },
      { label: "成员", value: "12345", format: { kind: "count", count: 12345 }, tone: "success" },
      { label: "用时", value: "7500000 ms", format: { kind: "duration", ms: 7_500_000 }, trend: { text: "-5%", direction: "down" } },
    ] },
    { kind: "banner", tone: "warning", text: "为保障资金安全，请先完成实名认证。", action: op("verify", "去认证") },
    { kind: "section", label: "趋势", collapsed: false, blocks: [
      { kind: "chart", chartKind: "bar", series: [
        { label: "完成", points: ["一", "二", "三", "四", "五"].map((d, i) => ({ label: `周${d}`, value: [3, 5, 2, 8, 6][i], text: String([3, 5, 2, 8, 6][i]) })) },
        { label: "新增", points: ["一", "二", "三", "四", "五"].map((d, i) => ({ label: `周${d}`, value: [4, 2, 6, 3, 5][i], text: String([4, 2, 6, 3, 5][i]) })) },
      ] },
      { kind: "chart", chartKind: "line", series: [{ points: [1, 4, 2, 6, 5].map((v, i) => ({ label: `D${i + 1}`, value: v, text: String(v) })) }] },
      { kind: "chart", chartKind: "donut", series: [{ points: [{ label: "Ivy", value: 12, text: "12" }, { label: "周屿", value: 9, text: "9" }, { label: "Leo", value: 7, text: "7" }] }] },
    ] },
    { kind: "section", label: "已折叠", collapsed: true, blocks: [{ kind: "text", text: "Hidden", style: "body" }] },
    { kind: "steps", items: [{ label: "提交资料", state: "done" }, { label: "人工审核", state: "current" }, { label: "补充材料", state: "failed" }, { label: "完成", state: "pending" }] },
    { kind: "image", asset: "cover.png", aspect: "16:9", alt: "封面" },
    { kind: "qr", value: "flare://pay/u2/abc123", label: "扫码向周屿付款", caption: "长按保存", valuePath: "/code" },
    { kind: "timeline", items: [
      { atMs: AT, title: "收到红包 +¥2.30", detail: "Ivy Chen", status: { text: "已入账", tone: "success" } },
      { atMs: AT - 86_400_000, title: "发出红包 -¥10.00", detail: "产品设计组" },
    ] },
  ],
};
const placeholder = { available: false, unavailableReason: "upgrade_required", minBuild: 41020, title: "任务看板", fields: [], actions: [] };
const resolveImage = () => undefined;
</script>
<template>
  <main id="plugin-blocks-regression" class="fixture" data-vr-ready="true">
    <FlarePluginView :view="blocks" icon="plugin" :resolve-image="resolveImage" :on-qr-refresh="() => {}" @action="() => {}" />
    <FlarePluginView :view="placeholder" :upgrade-status="{ available: true, build: 41020 }" :on-update="() => {}" />
    <FlarePluginView :view="placeholder" :upgrade-status="{ available: false }" />
    <div class="entry"><span>任务看板</span><FlarePluginUpgradeNotice variant="entry" /></div>
    <div class="page"><FlarePluginUpgradeNotice variant="page" title="任务看板" :status="{ available: true }" :on-update="() => {}" /></div>
  </main>
</template>
<style scoped>
.fixture { display: grid; gap: 16px; justify-items: start; width: 420px; padding: 16px; background: var(--flare-color-bg-secondary); }
.entry { display: flex; align-items: center; justify-content: space-between; width: 100%; padding: 12px; border-radius: 12px; background: var(--flare-color-bg-primary); box-sizing: border-box; }
.page { width: 100%; border-radius: 12px; background: var(--flare-color-bg-primary); }
</style>
