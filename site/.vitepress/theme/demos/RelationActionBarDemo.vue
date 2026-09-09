<script setup>
import { computed, ref } from "vue";
import FlareRelationActionBar from "@flare-im/vue-ui/components/contacts/FlareRelationActionBar.vue";
import DemoStage from "./DemoStage.vue";

const relations = ["none", "pendingOut", "pendingIn", "friends", "blocked"];
const capKeys = ["add", "accept", "reject", "remove", "block", "unblock", "message"];

const relation = ref("none");
const caps = ref({
  add: true, accept: true, reject: true, remove: true, block: true, unblock: true, message: true,
});
const busy = ref(false);
const error = ref("");
const failNext = ref(false);
const last = ref("尚未操作");

// Host reducer: the relation only moves after the "SDK" confirms.
const nextRelation = {
  add: "pendingOut",
  accept: "friends",
  reject: "none",
  remove: "none",
  block: "blocked",
  unblock: "none",
};

function run({ action }) {
  last.value = `action：${action}`;
  busy.value = true;
  setTimeout(() => {
    if (failNext.value) {
      // The failure reason stays until dismissed; the relation does not move.
      error.value = `${action} 失败：对方设置了好友验证，请稍后再试`;
    } else if (action !== "message") {
      relation.value = nextRelation[action] ?? relation.value;
    }
    busy.value = false;
  }, 700);
}

function reset() {
  relation.value = "none";
  caps.value = { add: true, accept: true, reject: true, remove: true, block: true, unblock: true, message: true };
  busy.value = false;
  error.value = "";
  failNext.value = false;
  last.value = "尚未操作";
}

const summary = computed(() => `relation=${relation.value}${busy.value ? " · busy" : ""}`);
</script>

<template>
  <DemoStage>
    <div class="rab-demo">
      <div class="rab-demo__phone">
        <div class="rab-demo__profile">
          <span class="rab-demo__avatar" aria-hidden="true">林</span>
          <span class="rab-demo__name">林晚舟</span>
          <span class="rab-demo__sub">设计中心 · 移动端</span>
        </div>
        <FlareRelationActionBar
          :relation="relation"
          :capabilities="caps"
          :busy="busy"
          :error="error"
          @action="run"
          @dismiss-error="error = ''"
        />
      </div>

      <div class="rab-demo__matrix">
        <div v-for="r in relations" :key="r" class="rab-demo__cell">
          <div class="rab-demo__cap">{{ r }}</div>
          <FlareRelationActionBar :relation="r" :capabilities="caps" />
        </div>
      </div>

      <div class="rab-demo__controls">
        <label v-for="r in relations" :key="r">
          <input v-model="relation" type="radio" :value="r" /> {{ r }}
        </label>
      </div>
      <div class="rab-demo__controls">
        <label v-for="k in capKeys" :key="k"><input v-model="caps[k]" type="checkbox" /> {{ k }}</label>
        <label><input v-model="busy" type="checkbox" /> busy</label>
        <label><input v-model="failNext" type="checkbox" /> 下次失败</label>
        <button type="button" @click="reset">重置演示</button>
      </div>
      <p role="status">{{ last }}。{{ summary }}。本地模拟，不触发 SDK。</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.rab-demo { width: 100%; min-width: 0; display: grid; gap: 16px; }
.rab-demo__phone {
  max-width: 380px;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: 14px;
  background: var(--flare-color-bg-primary);
  overflow: hidden;
}
.rab-demo__profile { display: grid; justify-items: center; gap: 4px; padding: 24px 16px; }
.rab-demo__avatar {
  display: grid;
  place-items: center;
  width: 64px;
  height: 64px;
  border-radius: 999px;
  background: var(--flare-color-bg-selected);
  color: var(--flare-color-primary);
  font-size: 24px;
  font-weight: 600;
}
.rab-demo__name { font-size: 18px; font-weight: 600; }
.rab-demo__sub { font-size: 13px; color: var(--flare-color-text-secondary); }
.rab-demo__matrix { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 12px; }
.rab-demo__cell {
  border: 1px solid var(--flare-color-border-primary);
  border-radius: 12px;
  background: var(--flare-color-bg-primary);
  overflow: hidden;
}
.rab-demo__cap { padding: 8px 14px 0; font-size: 12px; font-weight: 600; color: var(--flare-color-text-tertiary); }
.rab-demo__controls { display: flex; flex-wrap: wrap; gap: 8px 14px; align-items: center; font-size: 13px; }
.rab-demo__controls button {
  min-height: 40px;
  padding: 6px 12px;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: 8px;
  background: var(--flare-color-bg-primary);
  color: inherit;
}
p { font-size: 13px; overflow-wrap: anywhere; }
</style>
