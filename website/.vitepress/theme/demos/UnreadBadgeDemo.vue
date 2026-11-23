<script setup>
import { FlareUnreadBadge } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// 角标的几种读法：普通计数、超过 99、服务端只数了一页（more）、免打扰（quiet）、无数字的圆点；为 0 时什么都不画。
const samples = [
  { label: "3", props: { count: 3 } },
  { label: "128", props: { count: 128 } },
  { label: "more", props: { count: 12, more: true } },
  { label: "quiet", props: { count: 5, quiet: true } },
  { label: "dot", props: { count: 0, dot: true } },
  { label: "0", props: { count: 0 } },
];
</script>

<template>
  <DemoStage>
    <ul class="badge-demo">
      <li v-for="sample in samples" :key="sample.label">
        <FlareUnreadBadge v-bind="sample.props" />
        <code>{{ sample.label }}</code>
      </li>
    </ul>
  </DemoStage>
</template>

<style scoped>
.badge-demo {
  display: flex;
  flex-wrap: wrap;
  gap: var(--flare-size-spacing-lg);
  margin: 0;
  padding: 0;
  list-style: none;
}
.badge-demo li {
  display: grid;
  justify-items: center;
  gap: var(--flare-size-spacing-xs);
  min-width: var(--flare-size-layout-touch-target);
}
.badge-demo code {
  font-size: var(--flare-size-font-size-xs);
  color: var(--flare-color-text-tertiary);
}
</style>
