<script setup lang="ts">
import { computed, ref } from "vue";
import { FlareUiProvider, FlarePluginPage, FlareButton, FlareIcon, type FlarePluginPageActionPayload, type FlarePluginPageViewModel } from "@flare-im/vue-ui";
import fixture from "../../../../spec/account-view-vectors.json";
const dark = ref(false), narrow = ref(true), empty = ref(false), fail = ref(false), loading = ref(false);
const stack = ref(["wallet"]), filters = ref<Record<string, unknown>>({});
const current = computed(() => stack.value.at(-1)!);
const view = computed<FlarePluginPageViewModel>(() => {
  const base = JSON.parse(JSON.stringify(fixture.view)) as FlarePluginPageViewModel;
  const rows = base.blocks!.find(block => block.kind === "rows")!;
  if (rows.kind === "rows") {
    const label = ({ send: "发出红包", claim: "收到红包", refund: "红包退回", deposit: "入账" } as Record<string, string>)[String(filters.value.kind)];
    rows.rows = empty.value ? [] : rows.rows.filter(row => !label || row.badge?.text === label);
  }
  if (current.value !== "wallet") {
    base.title = ({ history: "交易记录", sent: "我发出的红包", received: "我收到的红包", packet: "红包详情" } as Record<string, string>)[current.value];
    base.fields = []; base.actions = []; base.blocks = [rows];
    if (current.value === "history") base.inputs = [{ id: "kind", kind: "select", label: "交易类型", choices: [{ value: "send", label: "发出" }, { value: "claim", label: "收到" }, { value: "refund", label: "退回" }, { value: "deposit", label: "入账" }] }];
    if (current.value === "sent" && rows.kind === "rows") rows.rows = rows.rows.filter(row => row.badge?.text === "发出红包");
    if (current.value === "received" && rows.kind === "rows") rows.rows = rows.rows.filter(row => row.badge?.text === "收到红包");
    if (current.value === "packet") { base.fields = [{ label: "内容", value: "这是详情导航的示例页面" }, { label: "状态", value: "仅供预览" }]; base.blocks = []; }
  }
  return base;
});
function action(id: string, _payload: FlarePluginPageActionPayload) { stack.value = [...stack.value, id === "open" ? "packet" : id]; filters.value = {}; }
function back() { stack.value = stack.value.slice(0, -1); filters.value = {}; }
async function refresh() { loading.value = true; await new Promise(resolve => setTimeout(resolve, 400)); loading.value = false; fail.value = false; }
</script>
<template>
  <FlareUiProvider :theme-mode="dark ? 'dark' : 'light'" locale="zh-CN">
    <main class="wallet-preview">
      <header class="wallet-preview__toolbar"><a href="/plugin-cards.html"><FlareIcon name="chevron-left" :size="16" />消息卡片</a><div><FlareButton variant="quiet" size="sm" :label="narrow ? '桌面' : '窄屏'" @click="narrow = !narrow" /><FlareButton variant="quiet" size="sm" :label="dark ? '浅色' : '深色'" @click="dark = !dark" /><FlareButton variant="quiet" size="sm" :label="empty ? '有记录' : '空钱包'" @click="empty = !empty" /><FlareButton variant="quiet" size="sm" :label="fail ? '恢复' : '模拟故障'" @click="fail = !fail" /></div></header>
      <p class="wallet-preview__notice">组件库预览 · 以下余额与账单均为虚构示例</p>
      <section class="wallet-preview__screen" :class="{ 'is-narrow': narrow }">
        <FlarePluginPage :key="current" :page="{ pluginId: 'example', page: current }" :title="view.title" :appearance="current === 'packet' ? 'document' : 'account'" :view="view" :filters="filters" :refreshing="loading" :error="fail ? '账单暂时无法更新，已保留当前记录。' : undefined" :back="stack.length > 1" @back="back" @refresh="refresh" @retry="refresh" @filter="filters = $event" @action="action" />
      </section>
    </main>
  </FlareUiProvider>
</template>
<style scoped>
.wallet-preview { display: flex; flex-direction: column; height: 100dvh; background: var(--flare-color-bg-secondary); color: var(--flare-color-text-primary); font: var(--flare-size-font-size-md)/var(--flare-size-line-height-normal) -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
.wallet-preview__toolbar { display: flex; align-items: center; justify-content: space-between; gap: var(--flare-size-spacing-sm); flex: none; padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg); background: var(--flare-color-bg-primary); border-bottom: 1px solid var(--flare-color-border-secondary); }
.wallet-preview__toolbar a { display: inline-flex; align-items: center; color: var(--flare-color-text-secondary); text-decoration: none; white-space: nowrap; }
.wallet-preview__toolbar > div { display: flex; gap: var(--flare-size-spacing-xs); }
.wallet-preview__notice { margin: var(--flare-size-spacing-sm); text-align: center; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary); }
.wallet-preview__screen { flex: 1; min-height: 0; width: min(100%, 820px); margin-inline: auto; background: var(--flare-color-bg-secondary); border: 1px solid var(--flare-color-border-secondary); border-radius: var(--flare-size-radius-lg) var(--flare-size-radius-lg) 0 0; overflow: hidden; }
.wallet-preview__screen.is-narrow { width: min(100%, 390px); }
@media (max-width: 599px) { .wallet-preview__toolbar { padding-inline: var(--flare-size-spacing-xs); flex-wrap: wrap; } .wallet-preview__notice { font-size: var(--flare-size-font-size-xs); } }
</style>
<style>html,body,#app { margin:0; min-height:100%; } * { box-sizing:border-box; }</style>
