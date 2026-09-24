<script setup>
import { computed, ref } from "vue";
import { FlareMyInvitePanel } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// The host fetched the code, the stats and a keyset page of invitees; every action is an
// intent it performs. Copy / share / regenerate are logged here instead of executed.
const DAY = 24 * 60 * 60 * 1000;
function page(from, count) {
  return Array.from({ length: count }, (_, i) => ({
    userId: `u${from + i}`,
    displayName: ["林晚", "Ann Lee", "周舟", "Bob", "Chen Yu"][(from + i) % 5],
    joinedAt: Date.now() - (from + i) * 3 * DAY,
  }));
}

const loading = ref(false);
const showProfiles = ref(true);
const canRegenerate = ref(true);
const cooling = ref(false);
const regenerating = ref(false);
const invitees = ref(page(0, 3));
const hasMore = ref(true);
const loadingMore = ref(false);
const last = ref("尚未操作");

const code = computed(() => (loading.value ? "" : "AB12CD"));
const stats = computed(() => (loading.value ? null : { direct: 5, l2: 12, l3: 40, total: 57 }));
const regenerateAvailableAt = computed(() => (cooling.value ? Date.now() + 2 * 60 * 60 * 1000 : null));

function copy(c) { last.value = `copy：${c}`; }
function share(url) { last.value = `share：${url}`; }
function regenerate() {
  last.value = "regenerate";
  regenerating.value = true;
  setTimeout(() => { regenerating.value = false; cooling.value = true; }, 900);
}
function loadMore() {
  last.value = "loadMore";
  loadingMore.value = true;
  setTimeout(() => {
    invitees.value = [...invitees.value, ...page(invitees.value.length, 2)];
    hasMore.value = invitees.value.length < 7;
    loadingMore.value = false;
  }, 900);
}
function select(id) { last.value = `select：${id}`; }
function emptyOut() { invitees.value = []; hasMore.value = false; }
function reset() {
  loading.value = false; showProfiles.value = true; canRegenerate.value = true; cooling.value = false;
  regenerating.value = false; invitees.value = page(0, 3); hasMore.value = true; loadingMore.value = false;
  last.value = "尚未操作";
}
</script>

<template>
  <DemoStage>
    <div class="my-invite-demo">
      <FlareMyInvitePanel
        :code="code"
        :share-url="code ? `https://flare.example/r/t1/${code}` : ''"
        :stats="stats"
        :max-depth-shown="3"
        :invitees="invitees"
        :show-profiles="showProfiles"
        :has-more="hasMore"
        :loading-more="loadingMore"
        :loading="loading"
        :can-regenerate="canRegenerate"
        :regenerate-available-at="regenerateAvailableAt"
        :regenerating="regenerating"
        @copy="copy"
        @share="share"
        @regenerate="regenerate"
        @load-more="loadMore"
        @select="select"
      />
      <div class="my-invite-demo__controls">
        <label><input v-model="loading" type="checkbox" /> 加载态</label>
        <label><input v-model="showProfiles" type="checkbox" /> 显示下级资料（关＝只显示人数）</label>
        <label><input v-model="canRegenerate" type="checkbox" /> 允许重新生成</label>
        <label><input v-model="cooling" type="checkbox" /> 冷却中（2 小时）</label>
        <button type="button" @click="emptyOut">清空下级（空态）</button>
        <button type="button" @click="reset">重置演示</button>
      </div>
      <p role="status">{{ last }}。本地模拟，不触发 SDK，也不写剪贴板。</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.my-invite-demo { width: 100%; min-width: 0; display: grid; gap: 16px; max-width: 520px; }
.my-invite-demo__controls { display: flex; flex-wrap: wrap; gap: 8px 14px; align-items: center; font-size: 13px; }
.my-invite-demo__controls button {
  min-height: 40px;
  padding: 6px 12px;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: 8px;
  background: var(--flare-color-bg-primary);
  color: inherit;
}
p { font-size: 13px; overflow-wrap: anywhere; }
</style>
