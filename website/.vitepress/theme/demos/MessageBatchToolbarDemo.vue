<script setup>
import { computed, ref } from "vue";
import {
  FlareBottomSheet,
  FlareButton,
  FlareConversationHeader,
  FlareMessageBatchToolbar,
  FlareUiProvider,
} from "@flare-im/vue-ui/components";
import { createWebPlatformAdapter } from "@flare-im/vue-ui";
import DemoStage from "./DemoStage.vue";

// 这个 demo 也是浏览器门禁的靶子(website/tests/batch-toolbar.spec.ts):
//  - 第一个舞台是 app 里的用法(挂在输入框位置,任何宽度都换行);
//  - 第二个舞台是浮动形态(浮在时间线上,键横向滚、退出键钉在末端)—— 仓里没有别的宿主用它;
//  - 工具条按 `selecting` 用 v-if 挂载:它挂着就是「多选这层活着」,Escape / 平台返回 / 页头
//    返回箭头的第一下都由它自己收;退出后卸载,才有进入/退出可切;
//  - 页头、输入框、底部面板给门禁验证「返回先退多选」「输入框里的 Escape 归输入框」「面板在上时
//    Escape 归面板」;
//  - historyBack 适配器让平台返回在网页里有实体(浏览器返回),门禁才能按 goBack 断言。
const total = 8;
const ids = ref(["m1", "m2", "m3"]);
const selecting = ref(true);
const busy = ref(false);
// 五个能力全开,在 360px 的浮动条里才真的会溢出。
const capabilities = { forwardEach: true, forwardMerged: true, pin: true, pinSelf: true, delete: true };
const last = ref("");
const backs = ref(0);
const sheetOpen = ref(false);
const note = ref("");
const selectAll = () => { ids.value = Array.from({ length: total }, (_, index) => `m${index + 1}`); };
const identity = { id: "demo", title: "设计评审", kind: "group" };
const platform = { adapter: createWebPlatformAdapter({ historyBack: true }) };
const status = computed(() => {
  if (!selecting.value) return "已退出多选。";
  return last.value ? `最近一次操作:${last.value}` : "选择消息后在这里执行批量操作。";
});
</script>
<template>
  <DemoStage>
    <FlareUiProvider :platform="platform">
      <div class="demo">
        <div class="controls">
          <FlareButton variant="secondary" size="sm" :label="selecting ? '退出多选' : '进入多选'" @click="selecting = !selecting" />
          <FlareButton variant="secondary" size="sm" :label="busy ? '结束批量' : '模拟批量进行中'" @click="busy = !busy" />
          <FlareButton variant="secondary" size="sm" label="打开面板" @click="sheetOpen = true" />
          <span class="backs" data-demo-backs>返回次数 {{ backs }}</span>
        </div>

        <!-- 第一舞台:app 的用法 —— 页头 + 时间线位置的工具条,任何宽度都换行。 -->
        <section class="stage stage--inline" aria-label="换行形态">
          <FlareConversationHeader :identity="identity" show-back @back="backs++" @action="() => undefined" />
          <textarea class="draft" aria-label="草稿" placeholder="在这里输入时,Escape 先归输入框" v-model="note" />
          <FlareMessageBatchToolbar
            v-if="selecting"
            :selected-ids="ids"
            :total="total"
            :capabilities="capabilities"
            :busy="busy"
            @action="(event) => (last = event.action)"
            @select-all="selectAll"
            @clear-selection="ids = []"
            @exit="selecting = false"
          />
        </section>

        <!-- 第二舞台:浮动形态,360px 宽的时间线上五个键放不下,横向滚,退出键钉在末端。 -->
        <section class="stage stage--floating" aria-label="浮动形态">
          <FlareMessageBatchToolbar
            v-if="selecting"
            floating
            :selected-ids="ids"
            :total="total"
            :capabilities="capabilities"
            :busy="busy"
            @action="(event) => (last = event.action)"
            @select-all="selectAll"
            @clear-selection="ids = []"
            @exit="selecting = false"
          />
        </section>

        <p class="note" data-demo-status>{{ status }}</p>
        <FlareBottomSheet :open="sheetOpen" title="面板在上" @close="sheetOpen = false">
          <p class="sheet-body">面板开着时,Escape 关的是面板,不是多选。</p>
        </FlareBottomSheet>
      </div>
    </FlareUiProvider>
  </DemoStage>
</template>

<style scoped>
.demo { width: 100%; max-width: 560px; display: flex; flex-direction: column; gap: 14px; }
.controls { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; }
.backs { font-size: 13px; color: var(--flare-color-text-tertiary); }
.stage { position: relative; }
.stage--inline { display: flex; flex-direction: column; gap: 10px; }
.stage--floating { width: 360px; max-width: 100%; height: 140px; border-radius: 14px; background: var(--flare-color-bg-secondary); overflow: hidden; }
.draft { width: 100%; box-sizing: border-box; min-height: 56px; padding: 8px 10px; border: 1px solid var(--flare-color-border-primary); border-radius: 8px; background: var(--flare-color-bg-primary); color: var(--flare-color-text-primary); font: inherit; resize: vertical; }
.note { margin: 0; color: var(--flare-color-text-tertiary); font-size: 13px; }
.sheet-body { margin: 0; padding: 0 20px 20px; color: var(--flare-color-text-secondary); }
</style>
