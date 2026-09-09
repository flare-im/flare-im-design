<script setup>
import { computed, ref } from "vue";
import FlareUnknownUserPlaceholder from "@flare-im/vue-ui/components/contacts/FlareUnknownUserPlaceholder.vue";
import DemoStage from "./DemoStage.vue";

const kinds = ["unknown", "deactivated", "blocked", "unreachable"];
const kind = ref("unknown");
const density = ref("row");
const longId = ref(true);
const withDetail = ref(true);

const userId = computed(() =>
  longId.value ? "u_2AW1QQ2SKVWFEPJRXN0123456789abcdef" : "u_42",
);
const detail = computed(() => (withDetail.value ? "来自群成员列表" : ""));

// A list where two rows resolved and one did not — the point of the component.
const roster = [
  { id: "m1", name: "林晚舟", role: "群主" },
  { id: "m2", name: "赵启明", role: "成员" },
];
</script>

<template>
  <DemoStage>
    <div class="uup-demo">
      <div class="uup-demo__split">
        <div class="uup-demo__col">
          <div class="uup-demo__cap">受控示例</div>
          <div class="uup-demo__surface">
            <FlareUnknownUserPlaceholder
              :user-id="userId"
              :kind="kind"
              :density="density"
              :detail="detail"
            />
          </div>
        </div>
        <div class="uup-demo__col">
          <div class="uup-demo__cap">列表里的一行 · 未解析成员不再空白</div>
          <ul class="uup-demo__list">
            <li v-for="member in roster" :key="member.id" class="uup-demo__member">
              <span class="uup-demo__avatar" aria-hidden="true">{{ member.name.slice(0, 1) }}</span>
              <span class="uup-demo__member-body">
                <span class="uup-demo__member-name">{{ member.name }}</span>
                <span class="uup-demo__member-role">{{ member.role }}</span>
              </span>
            </li>
            <li class="uup-demo__member uup-demo__member--placeholder">
              <FlareUnknownUserPlaceholder user-id="u_2AW1QQ2SKVWFEPJRXN" kind="deactivated" />
            </li>
          </ul>
        </div>
      </div>

      <div class="uup-demo__grid">
        <div v-for="k in kinds" :key="k" class="uup-demo__cell">
          <div class="uup-demo__cap">{{ k }}</div>
          <FlareUnknownUserPlaceholder :user-id="userId" :kind="k" density="card" />
        </div>
      </div>

      <div class="uup-demo__controls">
        <label v-for="k in kinds" :key="k">
          <input v-model="kind" type="radio" :value="k" /> {{ k }}
        </label>
        <label><input v-model="density" type="radio" value="row" /> row</label>
        <label><input v-model="density" type="radio" value="card" /> card</label>
        <label><input v-model="longId" type="checkbox" /> 超长 ID</label>
        <label><input v-model="withDetail" type="checkbox" /> 宿主补充说明</label>
      </div>
      <p role="status">纯展示组件：无动作、无回调、无网络请求。ID 只出现在诊断位并强制 LTR。</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.uup-demo { width: 100%; min-width: 0; display: grid; gap: 16px; }
.uup-demo__split { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 20px; align-items: start; }
@media (max-width: 720px) { .uup-demo__split { grid-template-columns: 1fr; } }
.uup-demo__cap { margin-bottom: 8px; font-size: 12px; font-weight: 600; color: var(--flare-color-text-tertiary); }
.uup-demo__surface {
  padding: 12px 14px;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: 12px;
  background: var(--flare-color-bg-primary);
}
.uup-demo__list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 2px;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: 12px;
  background: var(--flare-color-bg-primary);
  overflow: hidden;
}
.uup-demo__member { display: flex; align-items: center; gap: 12px; padding: 8px 14px; min-height: 48px; }
.uup-demo__member--placeholder { border-top: 1px solid var(--flare-color-border-secondary); }
.uup-demo__avatar {
  display: grid;
  place-items: center;
  width: 44px;
  height: 44px;
  border-radius: 999px;
  background: var(--flare-color-bg-selected);
  color: var(--flare-color-primary);
  font-weight: 600;
  flex: none;
}
.uup-demo__member-body { display: grid; gap: 2px; min-width: 0; }
.uup-demo__member-name { font-weight: 600; font-size: 14px; }
.uup-demo__member-role { font-size: 12px; color: var(--flare-color-text-secondary); }
.uup-demo__grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 12px; }
.uup-demo__controls { display: flex; flex-wrap: wrap; gap: 8px 14px; align-items: center; font-size: 13px; }
p { font-size: 13px; overflow-wrap: anywhere; }
</style>
