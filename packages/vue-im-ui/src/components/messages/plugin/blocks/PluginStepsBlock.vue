<script setup lang="ts">
import { computed } from "vue";
import FlareIcon from "../../../general/FlareIcon.vue";
import { useFlareI18nOptional } from "../../../../shared/i18n/useFlareI18n";
import { flarePluginStepState, type FlarePluginStepsBlock } from "../../../../shared/contracts/plugin-ui";

// A process in steps (vocabulary 2): 2 to 6 markers on a line, each done (a check), failed (a cross), current
// (the brand ring) or pending, with its label under it. The state is also said in words to assistive technology.
const props = defineProps<{ block: FlarePluginStepsBlock }>();
const { t } = useFlareI18nOptional();
const steps = computed(() => props.block.items.map((item) => ({ label: item.label, state: flarePluginStepState(item.state) })));
</script>

<template>
  <ol class="flare-plugin-steps" :style="{ '--flare-plugin-steps-count': String(steps.length) }">
    <li
      v-for="(step, index) in steps"
      :key="index"
      class="flare-plugin-steps__item"
      :class="`is-${step.state}`"
      :data-step-state="step.state"
      :aria-current="step.state === 'current' ? 'step' : undefined"
    >
      <span class="flare-plugin-steps__marker" aria-hidden="true">
        <FlareIcon v-if="step.state === 'done'" name="check" size="sm" />
        <FlareIcon v-else-if="step.state === 'failed'" name="close" size="sm" />
        <template v-else>{{ index + 1 }}</template>
      </span>
      <!-- §12.5: read as 「第 N 步，共 M 步：标签，状态」. -->
      <span class="flare-plugin-steps__spoken" data-step-position="true">{{ t("pluginView.stepPosition", { index: index + 1, count: steps.length }) }}</span>
      <span class="flare-plugin-steps__label">{{ step.label }}</span>
      <span class="flare-plugin-steps__spoken">{{ t(`pluginView.step.${step.state}`) }}</span>
    </li>
  </ol>
</template>

<style scoped>
.flare-plugin-steps {
  display: grid;
  grid-template-columns: repeat(var(--flare-plugin-steps-count), minmax(0, 1fr));
  margin: 0;
  padding: 0;
  list-style: none;
  min-width: 0;
}
.flare-plugin-steps__item {
  position: relative;
  display: grid;
  justify-items: center;
  gap: var(--flare-size-spacing-xs);
  min-width: 0;
  text-align: center;
}
/* The line to the previous marker, behind this one. */
.flare-plugin-steps__item + .flare-plugin-steps__item::before {
  content: "";
  position: absolute;
  top: calc(var(--flare-size-spacing-xl) / 2);
  right: 50%;
  width: 100%;
  border-top: 2px solid var(--flare-color-border-secondary);
}
.flare-plugin-steps__item.is-done + .flare-plugin-steps__item::before,
.flare-plugin-steps__item.is-done + .flare-plugin-steps__item.is-current::before {
  border-top-color: var(--flare-color-primary);
}
.flare-plugin-steps__marker {
  position: relative;
  z-index: 1;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: var(--flare-size-spacing-xl);
  height: var(--flare-size-spacing-xl);
  border: 2px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-full);
  box-sizing: border-box;
  background: var(--flare-color-bg-primary);
  color: var(--flare-color-text-tertiary);
  font-size: var(--flare-size-font-size-xs);
  font-variant-numeric: tabular-nums;
}
.is-current .flare-plugin-steps__marker { border-color: var(--flare-color-primary); color: var(--flare-color-primary-text); }
.is-done .flare-plugin-steps__marker { border-color: var(--flare-color-primary); background: var(--flare-color-primary); color: var(--flare-color-bg-primary); }
.is-failed .flare-plugin-steps__marker { border-color: var(--flare-color-error); background: var(--flare-color-error); color: var(--flare-color-bg-primary); }
.flare-plugin-steps__label {
  max-width: 100%;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
}
.is-current .flare-plugin-steps__label { color: var(--flare-color-text-primary); font-weight: var(--flare-size-font-weight-medium); }
.is-failed .flare-plugin-steps__label { color: var(--flare-color-error-text); }
.flare-plugin-steps__spoken {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}
@media (forced-colors: active) {
  .flare-plugin-steps__marker { border-color: CanvasText; }
}
</style>
