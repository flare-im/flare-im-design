<script setup>
import { ref } from "vue";
import { FlarePluginPage } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// A plugin's page contribution (the red packet wallet) in the kit page host: the balance and escrow fields, the
// ledger's rows with their kind as a badge, the kind filter tabs, a row action and load more. The host fetches and
// invokes; here timers stand in for the core SDK (pluginPage merges the next page and keeps data).
const props = defineProps({ previewState: { type: String, default: "loaded" } });
const page = { pluginId: "flare.redpacket", page: "flare.redpacket.wallet" };
const KINDS = {
  send: { text: "发出红包", tone: "neutral" },
  claim: { text: "收到红包", tone: "success" },
  refund: { text: "红包退回", tone: "warning" },
  deposit: { text: "入账", tone: "info" },
};
const DAY = 86_400_000;
const now = Date.now();
const ledger = [
  ["l1", "claim", "+¥2.30", "Ivy Chen", now - 2 * 3_600_000, "p1"],
  ["l2", "send", "-¥10.00", "产品设计组", now - DAY, "p2"],
  ["l3", "refund", "+¥3.00", "", now - 2 * DAY, "p3"],
  ["l4", "claim", "+¥0.88", "周屿", now - 3 * DAY, "p4"],
  ["l5", "deposit", "+¥20.00", "", now - 4 * DAY, null],
  ["l6", "send", "-¥5.00", "Leo Wang", now - 5 * DAY, "p6"],
  ["l7", "claim", "+¥1.66", "Leo Wang", now - 6 * DAY, "p7"],
];
const row = ([key, kind, amount, who, at, packetId]) => ({
  key,
  cells: [{ text: amount }, { text: who }, { text: String(at), timeMs: at }],
  actions: packetId ? [{ id: "open", input: { packetId } }] : [],
  badge: KINDS[kind],
});
function view(kind, pages) {
  const lines = ledger.filter((line) => !kind || line[1] === kind);
  const shown = lines.slice(0, pages * 4);
  return {
    available: true,
    title: "钱包",
    fields: [{ label: "可用余额", value: "¥128.60" }, { label: "托管中", value: "¥6.00" }],
    actions: [{ id: "history", label: "全部明细" }],
    blocks: [
      { kind: "note", text: "托管中的金额在红包领完或 24 小时后退回时结算。", tone: "info" },
      {
        kind: "rows",
        source: "flare.redpacket.wallet",
        columns: [{ label: "金额", format: "text" }, { label: "对方", format: "text" }, { label: "时间", format: "time" }],
        rows: shown.map(row),
        actions: [{ id: "open", label: "查看" }],
        emptyText: "还没有明细",
        filters: ["kind"],
      },
    ],
    inputs: [{
      id: "kind",
      kind: "select",
      label: "类型",
      choices: [{ value: "send", label: "发出" }, { value: "claim", label: "收到" }, { value: "refund", label: "退回" }, { value: "deposit", label: "入账" }],
    }],
    nextCursor: lines.length > shown.length ? `page-${pages + 1}` : undefined,
    data: { currency: "CNY" },
  };
}
const filters = ref({});
const pages = ref(1);
const current = ref(props.previewState === "loading" || props.previewState === "error" ? undefined : view(undefined, 1));
const loading = ref(props.previewState === "loading");
const error = ref(props.previewState === "error" ? "加载失败，请稍后再试" : "");
const refreshing = ref(props.previewState === "refreshing");
const loadingMore = ref(false);
const busyActionId = ref(undefined);
const lastAction = ref("");
const after = (ms, run) => setTimeout(run, ms);
function reload() {
  refreshing.value = true;
  after(600, () => { refreshing.value = false; pages.value = 1; current.value = view(filters.value.kind, 1); });
}
function retry() {
  error.value = "";
  loading.value = true;
  after(600, () => { loading.value = false; current.value = view(filters.value.kind, 1); });
}
function loadMore() {
  loadingMore.value = true;
  after(600, () => { loadingMore.value = false; pages.value += 1; current.value = view(filters.value.kind, pages.value); });
}
function filter(values) {
  filters.value = values;
  reload();
}
function invoke(id, payload) {
  busyActionId.value = id;
  after(400, () => {
    busyActionId.value = undefined;
    lastAction.value = payload.row ? `${id} · ${payload.row.input.packetId}` : id;
  });
}
</script>
<template>
  <DemoStage>
    <div class="frame">
      <FlarePluginPage
        :page="page"
        title="钱包"
        back
        :view="current"
        :filters="filters"
        :loading="loading"
        :error="error || undefined"
        :refreshing="refreshing"
        :loading-more="loadingMore"
        :busy-action-id="busyActionId"
        @back="() => {}"
        @refresh="reload"
        @retry="retry"
        @load-more="loadMore"
        @filter="filter"
        @action="invoke"
      />
    </div>
    <p v-if="lastAction" class="note">invokePageAction: {{ lastAction }}</p>
  </DemoStage>
</template>
<style scoped>
.frame { height: 600px; max-width: 390px; border: 1px solid var(--flare-color-border-primary); border-radius: 14px; overflow: hidden; }
.note { margin: var(--flare-size-spacing-sm) 0 0; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); }
</style>
