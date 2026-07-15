<script setup>
import { reactive } from "vue";
import FlareReactionSummary from "flare-core-vue-im-ui/components/messages/FlareReactionSummary.vue";
import DemoStage from "./DemoStage.vue";
const state = reactive({
  reactions: [
    { emoji: "👍", count: 4, reactedBySelf: true, users: ["Ivy Chen", "Leo Wang", "你", "Mia Zhou"] },
    { emoji: "🎉", count: 2, users: ["Leo Wang", "Ada Li"] },
    { emoji: "❤️", count: 1, users: ["Mia Zhou"] },
  ],
});
function toggle(emoji) {
  const g = state.reactions.find((r) => r.emoji === emoji);
  if (!g) return;
  g.reactedBySelf = !g.reactedBySelf;
  g.count += g.reactedBySelf ? 1 : -1;
  if (g.count <= 0) state.reactions = state.reactions.filter((r) => r !== g);
}
</script>
<template>
  <DemoStage>
    <div class="stage">
      <div class="bubble">周五下午的设计评审，大家记得带上组件清单 👀</div>
      <FlareReactionSummary :reactions="state.reactions" @toggle="toggle" @add="() => {}" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.bubble {
  display: inline-block; padding: 10px 14px; border-radius: 14px 14px 14px 4px;
  background: var(--flare-color-bg-primary); color: var(--flare-color-text-primary);
  border: 1px solid var(--flare-color-border-primary); font-size: 14px; max-width: 320px;
}
</style>
