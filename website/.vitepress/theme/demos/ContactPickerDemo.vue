<script setup>
import { ref } from "vue";
import { FlareContactPicker, FlareSegmentedControl } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 好友与群成员两组；自己在群成员里显示「（我）」。切到多选看确认键。
const mode = ref(0);
const picked = ref("");
const groups = [
  {
    id: "friends",
    entries: [
      { userId: "u1", name: "Ivy Chen", subtitle: "产品设计组" },
      { userId: "u2", name: "周屿", subtitle: "前端 · Web" },
      { userId: "u3", name: "Leo Wang", subtitle: "iOS 客户端" },
      { userId: "u4", name: "林晓", subtitle: "运营" },
    ],
  },
  {
    id: "groupMembers",
    entries: [
      { userId: "me", name: "许嘉", isSelf: true },
      { userId: "u1", name: "Ivy Chen", subtitle: "产品设计组" },
      { userId: "u5", name: "Mia Zhou", subtitle: "Android 客户端" },
    ],
  },
];
</script>
<template>
  <DemoStage>
    <FlareSegmentedControl v-model="mode" class="switch" :options="['单选', '多选']" />
    <div class="frame">
      <FlareContactPicker
        :groups="groups"
        :multiple="mode === 1"
        @select="(entries) => (picked = entries.map((e) => e.name).join('、'))"
        @cancel="picked = ''"
      />
    </div>
    <p v-if="picked" class="note">选择：{{ picked }}</p>
  </DemoStage>
</template>
<style scoped>
.switch { margin-bottom: 12px; }
.frame { max-width: 390px; height: 520px; overflow: hidden; border-radius: 14px; border: 1px solid var(--flare-color-border-secondary); }
.note { margin: 8px 0 0; font-size: 13px; color: var(--flare-color-text-secondary); }
</style>
