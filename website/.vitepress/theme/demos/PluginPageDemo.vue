<script setup>
import { ref } from "vue";
import { FlarePluginPage } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// A plugin's page contribution (the red packet wallet) in the kit page host: the same document renderer as the
// detail sheet, pull to refresh on touch, a refresh key on pointer devices, load more while there is a next page.
// The host fetches; here a timer stands in for it.
const props = defineProps({ previewState: { type: String, default: "loaded" } });
const users = { u1: { name: "Ivy Chen" }, u2: { name: "周屿" }, u3: { name: "Leo Wang" } };
const row = (index, text, userId) => ({ index, text, userId });
const page = (rows, nextCursor) => ({
  available: true,
  title: "钱包",
  fields: [],
  actions: [{ id: "sent", label: "我发出的" }, { id: "received", label: "我收到的" }],
  blocks: [
    { kind: "fields", fields: [{ label: "可用余额", value: "¥128.60" }, { label: "红包托管中", value: "¥6.00" }, { label: "发出合计", value: "¥52.00" }, { label: "收到合计", value: "¥36.40" }] },
    { kind: "entries", numbered: false, total: rows.length, more: false, items: rows },
    { kind: "note", text: "单个红包上限 ¥200，最多 100 份，24 小时未领完自动退回。" },
  ],
  nextCursor,
});
const first = [row(1, "收到红包 +¥2.30", "u1"), row(2, "发出红包 -¥10.00", "u2"), row(3, "红包退回 +¥3.00", "u3")];
const view = ref(props.previewState === "loading" || props.previewState === "error" ? undefined : page(first, "page-2"));
const loading = ref(props.previewState === "loading");
const error = ref(props.previewState === "error" ? "加载失败，请稍后再试" : "");
const refreshing = ref(props.previewState === "refreshing");
const loadingMore = ref(false);
function refresh() {
  refreshing.value = true;
  setTimeout(() => { refreshing.value = false; view.value = page(first, "page-2"); }, 700);
}
function retry() {
  error.value = "";
  loading.value = true;
  setTimeout(() => { loading.value = false; view.value = page(first, "page-2"); }, 700);
}
function loadMore() {
  loadingMore.value = true;
  setTimeout(() => {
    loadingMore.value = false;
    view.value = page([...first, row(4, "收到红包 +¥0.88", "u2"), row(5, "发出红包 -¥5.00", "u1")], undefined);
  }, 700);
}
</script>
<template>
  <DemoStage>
    <div class="frame">
      <FlarePluginPage
        title="钱包"
        back
        :view="view"
        :loading="loading"
        :error="error || undefined"
        :refreshing="refreshing"
        :loading-more="loadingMore"
        :resolve-user="(id) => users[id]"
        viewer-id="u2"
        @back="() => {}"
        @refresh="refresh"
        @retry="retry"
        @load-more="loadMore"
      />
    </div>
  </DemoStage>
</template>
<style scoped>
.frame { height: 560px; max-width: 390px; border: 1px solid var(--flare-color-border-primary); border-radius: 14px; overflow: hidden; }
</style>
