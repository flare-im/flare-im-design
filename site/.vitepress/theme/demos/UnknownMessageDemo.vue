<script setup>
import { ref } from "vue";
import FlareUnknownMessage from "@flare-im/vue-ui/components/messages/FlareUnknownMessage.vue";
import DemoStage from "./DemoStage.vue";

const contentType = ref("flare.poll.v2");
const label = ref("");
const summary = ref("");
const withAction = ref(false);
const last = ref("尚未操作");

function preset(kind) {
  if (kind === "bare") {
    contentType.value = "flare.poll.v2";
    label.value = "";
    summary.value = "";
  } else if (kind === "labelled") {
    contentType.value = "flare.poll.v2";
    label.value = "投票";
    summary.value = "";
  } else {
    contentType.value = "flare.poll.v2";
    label.value = "投票";
    summary.value = "[投票] 周会时间改到周四下午三点";
  }
}
</script>

<template>
  <DemoStage>
    <div class="um-demo">
      <div class="um-demo__split">
        <div class="um-demo__col">
          <div class="um-demo__cap">对方发来 · 气泡内</div>
          <div class="um-demo__bubble">
            <FlareUnknownMessage
              :content-type="contentType"
              :label="label"
              :summary="summary"
              :action-text="withAction ? '了解如何升级' : ''"
              v-on="withAction ? { action: () => (last = 'action') } : {}"
            />
          </div>
        </div>
        <div class="um-demo__col">
          <div class="um-demo__cap">自己发出 · 主色气泡内继承前景色</div>
          <div class="um-demo__bubble um-demo__bubble--self">
            <FlareUnknownMessage
              :content-type="contentType"
              :label="label"
              :summary="summary"
              self
            />
          </div>
        </div>
      </div>

      <div class="um-demo__controls">
        <button type="button" @click="preset('bare')">只有类型</button>
        <button type="button" @click="preset('labelled')">宿主认识类型</button>
        <button type="button" @click="preset('summary')">发送端带兜底文案</button>
        <label><input v-model="withAction" type="checkbox" /> 宿主提供升级动作</label>
        <label>contentType <input v-model="contentType" type="text" /></label>
      </div>
      <p role="status">{{ last }}。原始类型始终在诊断行，不会当正文；本地演示，不触发 SDK。</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.um-demo { width: 100%; min-width: 0; display: grid; gap: 16px; }
.um-demo__split { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 20px; align-items: start; }
@media (max-width: 720px) { .um-demo__split { grid-template-columns: 1fr; } }
.um-demo__cap { margin-bottom: 8px; font-size: 12px; font-weight: 600; color: var(--flare-color-text-tertiary); }
.um-demo__bubble {
  max-width: 320px;
  padding: 10px 12px;
  border-radius: 16px 16px 16px 4px;
  background: var(--flare-color-bg-secondary);
}
.um-demo__bubble--self {
  border-radius: 16px 16px 4px 16px;
  background: var(--flare-color-primary);
  color: #fff;
}
.um-demo__controls { display: flex; flex-wrap: wrap; gap: 8px 14px; align-items: center; font-size: 13px; }
.um-demo__controls button { min-height: 40px; padding: 6px 12px; border: 1px solid var(--flare-color-border-primary); border-radius: 8px; background: var(--flare-color-bg-primary); color: inherit; }
.um-demo__controls input[type="text"] { min-height: 32px; padding: 4px 8px; border: 1px solid var(--flare-color-border-primary); border-radius: 8px; background: var(--flare-color-bg-primary); color: inherit; }
p { font-size: 13px; overflow-wrap: anywhere; }
</style>
