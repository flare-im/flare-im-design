<script setup lang="ts">
import { computed } from "vue";
import FlareButton from "../../general/FlareButton.vue";
import FlareIcon from "../../general/FlareIcon.vue";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";
import { flarePluginChoiceCap, type FlarePluginChoicesBlock } from "../../../shared/contracts/plugin-ui";

// A choices block (spec/plugin-view-vectors.json → rules.choices, rules.maxSelections). Presentational: PluginView
// owns the draft, the optimistic marks, the cap and the submit; this draws the options as buttons (single) or
// checkboxes (multiple) while `interactive`, and as read-only rows with result bars otherwise. An option the cap
// holds back stays in the list, dimmed and aria-disabled, so the reader can still find it.
const props = defineProps<{
  block: FlarePluginChoicesBlock;
  /** The indices drawn as chosen: the optimistic submit, the multiple draft or the view's selection. */
  selected: ReadonlyArray<number>;
  interactive: boolean;
  submitEnabled: boolean;
  submitLoading: boolean;
  /** Indices the cap disables (the draft is full and does not hold them). */
  capped?: ReadonlyArray<number>;
}>();
const emit = defineEmits<{ (e: "pick", index: number): void; (e: "submit"): void }>();
const { t } = useFlareI18nOptional();

const chosen = computed(() => new Set(props.selected));
const held = computed(() => new Set(props.capped ?? []));
const footer = computed(() => {
  const parts: string[] = [];
  const cap = flarePluginChoiceCap(props.block);
  if (cap !== undefined && props.block.action && !props.block.closed) parts.push(t("pluginView.maxSelections", { n: cap }));
  if (props.block.closed) parts.push(t("pluginView.ended"));
  // `total` is only the denominator of the shares — a voter count or the sum of the counts — so it is never drawn:
  // "N 票" belongs to the options, and how many took part is the plugin's own row (poll v2 §6).
  return parts.join(" · ");
});
const percentOf = (percent: number | undefined) => Math.min(100, Math.max(0, percent ?? 0));
</script>

<template>
  <div class="flare-plugin-choices" :class="{ 'is-results': block.showResults }" :role="block.multiple ? 'group' : undefined">
    <component
      :is="interactive ? 'button' : 'div'"
      v-for="option in block.options"
      :key="option.index"
      class="flare-plugin-choices__option"
      :class="{ 'is-selected': chosen.has(option.index), 'is-interactive': interactive, 'is-capped': interactive && held.has(option.index) }"
      :type="interactive ? 'button' : undefined"
      :role="interactive && block.multiple ? 'checkbox' : undefined"
      :aria-checked="interactive && block.multiple ? chosen.has(option.index) : undefined"
      :aria-pressed="interactive && !block.multiple ? chosen.has(option.index) : undefined"
      :aria-disabled="interactive && held.has(option.index) ? 'true' : undefined"
      :data-option-index="option.index"
      @click="interactive && !held.has(option.index) && emit('pick', option.index)"
    >
      <span
        v-if="block.showResults"
        class="flare-plugin-choices__bar"
        :style="{ width: `${percentOf(option.percent)}%` }"
        aria-hidden="true"
        data-choice-bar="true"
      />
      <span
        v-if="block.multiple && interactive"
        class="flare-plugin-choices__box"
        :class="{ 'is-on': chosen.has(option.index) }"
        aria-hidden="true"
      >
        <FlareIcon v-if="chosen.has(option.index)" name="check" :size="12" />
      </span>
      <span class="flare-plugin-choices__label">{{ option.label }}</span>
      <FlareIcon
        v-if="chosen.has(option.index) && !(block.multiple && interactive)"
        class="flare-plugin-choices__check"
        name="check"
        :size="16"
        data-choice-check="true"
        aria-hidden="true"
      />
      <span v-if="!interactive && chosen.has(option.index)" class="flare-plugin-choices__spoken">{{ t("pluginView.selected") }}</span>
      <span v-if="block.showResults" class="flare-plugin-choices__result">
        <span class="flare-plugin-choices__percent" data-choice-percent="true">{{ option.percent ?? 0 }}%</span>
        <span class="flare-plugin-choices__votes" data-choice-votes="true">{{ t("pluginView.votes", { count: option.count ?? 0 }) }}</span>
      </span>
    </component>
    <FlareButton
      v-if="interactive && block.multiple && block.action"
      class="flare-plugin-choices__submit"
      :label="block.action.label"
      :variant="block.action.style === 'danger' ? 'danger' : 'primary'"
      size="sm"
      appearance="text"
      :loading="submitLoading"
      :disabled="!submitEnabled || submitLoading"
      data-choices-submit="true"
      @click="emit('submit')"
    />
    <p v-if="footer" class="flare-plugin-choices__footer" data-choices-footer="true">{{ footer }}</p>
  </div>
</template>

<style scoped>
.flare-plugin-choices { display: grid; gap: var(--flare-size-spacing-xs); min-width: 0; }
.flare-plugin-choices__option {
  position: relative;
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  min-height: var(--flare-size-layout-touch-target);
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-2sm);
  box-sizing: border-box;
  overflow: hidden;
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-primary);
  color: var(--flare-color-text-primary);
  font: inherit;
  text-align: start;
}
.flare-plugin-choices__option.is-interactive { cursor: pointer; }
.flare-plugin-choices__option.is-interactive:hover { border-color: var(--flare-color-border-hover); }
.flare-plugin-choices__option.is-interactive:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-plugin-choices__option.is-interactive:disabled { cursor: default; }
/* Held back by the cap: still listed and focusable, dimmed like a disabled control. */
.flare-plugin-choices__option.is-capped { cursor: default; opacity: var(--flare-opacity-disabled); }
.flare-plugin-choices__option.is-capped:hover { border-color: var(--flare-color-border-secondary); }
.flare-plugin-choices__option.is-selected { border-color: var(--flare-color-border-selected); }
.flare-plugin-choices__bar {
  position: absolute;
  inset-block: 0;
  inset-inline-start: 0;
  background: color-mix(in srgb, var(--flare-color-primary) 14%, transparent);
  transition: width var(--flare-component-motion-fast);
}
.flare-plugin-choices__box {
  position: relative;
  flex: none;
  display: grid;
  place-items: center;
  width: var(--flare-size-icon-size-sm);
  height: var(--flare-size-icon-size-sm);
  box-sizing: border-box;
  border: 1.5px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-xs);
  color: var(--flare-color-bg-primary);
}
.flare-plugin-choices__box.is-on { background: var(--flare-color-primary); border-color: var(--flare-color-primary); }
.flare-plugin-choices__label {
  position: relative;
  flex: 1;
  min-width: 0;
  font-size: var(--flare-size-font-size-md);
  overflow-wrap: anywhere;
}
.flare-plugin-choices__check { position: relative; flex: none; color: var(--flare-color-primary-text); }
.flare-plugin-choices__result {
  position: relative;
  flex: none;
  display: inline-flex;
  gap: var(--flare-size-spacing-xs);
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
  font-variant-numeric: tabular-nums;
}
.flare-plugin-choices__spoken { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); white-space: nowrap; }
.flare-plugin-choices__submit { justify-self: start; margin-top: var(--flare-size-spacing-xs); }
.flare-plugin-choices__footer { margin: 0; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary); }
@media (prefers-reduced-motion: reduce) {
  .flare-plugin-choices__bar { transition: none; }
}
</style>
