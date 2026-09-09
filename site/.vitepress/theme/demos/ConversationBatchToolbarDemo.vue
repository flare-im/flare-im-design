<script setup>
import { computed, ref } from "vue";
import FlareConversationBatchToolbar from "@flare-im/vue-ui/components/conversation/FlareConversationBatchToolbar.vue";
import DemoStage from "./DemoStage.vue";

const rows = [
  { id: "c1", title: "设计评审 · 移动端周会" },
  { id: "c2", title: "Flare 发布协调" },
  { id: "c3", title: "客服值班（长标题会在窄屏换行而不是被挤出屏幕）" },
  { id: "c4", title: "张伟" },
];
const selected = ref(["c1", "c2", "c3"]);
const caps = ref({ markRead: true, mute: true, archive: true, delete: true });
const busy = ref(false);
const result = ref(null);
const maxSelection = ref(null);
const last = ref("尚未操作");
const capKeys = ["markRead", "mute", "archive", "delete"];

function toggle(id) {
  const next = new Set(selected.value);
  next.has(id) ? next.delete(id) : next.add(id);
  selected.value = [...next];
}

// The host owns busy and the outcome: it sets busy before dispatching and writes
// a result that keeps the successes while every failure stays individually recoverable.
function run({ action, ids }) {
  last.value = `action：${action} × ${ids.length}`;
  busy.value = true;
  setTimeout(() => {
    const failed = ids
      .filter((id) => id === "c3")
      .map((id) => ({ id, title: rows.find((r) => r.id === id).title, reason: "没有该会话的管理权限" }));
    const succeeded = ids.filter((id) => !failed.some((f) => f.id === id));
    result.value = { succeeded, failed };
    selected.value = failed.map((f) => f.id);
    busy.value = false;
  }, 700);
}

function retry(ids) {
  last.value = `retryFailed × ${ids.length}`;
  busy.value = true;
  setTimeout(() => {
    result.value = { succeeded: ids, failed: [] };
    selected.value = [];
    busy.value = false;
  }, 700);
}

function reset() {
  selected.value = ["c1", "c2", "c3"];
  caps.value = { markRead: true, mute: true, archive: true, delete: true };
  busy.value = false;
  result.value = null;
  maxSelection.value = null;
  last.value = "尚未操作";
}

const summary = computed(() => {
  if (!result.value) return "无上一次结果";
  return `上一次：成功 ${result.value.succeeded.length} 项，失败 ${result.value.failed.length} 项`;
});
</script>

<template>
  <DemoStage>
    <div class="cbt-demo">
      <ul class="cbt-demo__list">
        <li v-for="row in rows" :key="row.id">
          <label class="cbt-demo__row">
            <input type="checkbox" :checked="selected.includes(row.id)" @change="toggle(row.id)" />
            <span class="cbt-demo__row-title">{{ row.title }}</span>
          </label>
        </li>
      </ul>

      <FlareConversationBatchToolbar
        :selected-ids="selected"
        :capabilities="caps"
        :busy="busy"
        :result="result"
        :max-selection="maxSelection"
        @action="run"
        @retry-failed="retry"
        @clear-selection="selected = []"
        @dismiss-result="result = null"
      />

      <div class="cbt-demo__controls">
        <label v-for="k in capKeys" :key="k"><input v-model="caps[k]" type="checkbox" /> {{ k }}</label>
        <label><input v-model="busy" type="checkbox" /> busy</label>
        <label><input type="checkbox" :checked="maxSelection === 2" @change="maxSelection = maxSelection === 2 ? null : 2" /> 上限 2 项</label>
        <button type="button" @click="reset">重置演示</button>
      </div>
      <p role="status">{{ last }}。{{ summary }}。本地模拟，不触发 SDK，删除也不做二次确认。</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.cbt-demo { width: 100%; min-width: 0; display: grid; gap: 16px; }
.cbt-demo__list { display: grid; gap: 6px; margin: 0; padding: 0; list-style: none; }
.cbt-demo__row {
  display: flex;
  align-items: center;
  gap: 10px;
  min-height: 48px;
  padding: 8px 12px;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: 12px;
  background: var(--flare-color-bg-primary);
  cursor: pointer;
}
.cbt-demo__row-title { min-width: 0; overflow-wrap: anywhere; }
.cbt-demo__controls { display: flex; flex-wrap: wrap; gap: 8px 14px; align-items: center; font-size: 13px; }
.cbt-demo__controls button { min-height: 40px; padding: 6px 12px; border: 1px solid var(--flare-color-border-primary); border-radius: 8px; background: var(--flare-color-bg-primary); color: inherit; }
p { font-size: 13px; overflow-wrap: anywhere; }
</style>
