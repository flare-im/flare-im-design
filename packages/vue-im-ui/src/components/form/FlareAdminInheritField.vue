<script setup lang="ts">
/**
 * One setting that either follows the inherited default or carries its own value.
 * While inherited it shows the default read-only; switching "use default" off hands the
 * row to the custom control in the default slot. The host owns the value, the save and
 * what the default means. This only draws the choice.
 */
import { computed, useId } from "vue";
import { NSwitch } from "naive-ui";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    /** What the setting is called. Names the switch for assistive technology. */
    label: string;
    /** Whether the setting follows the inherited default. */
    inherited: boolean;
    /** The inherited value, as text. */
    inheritedValue: string;
    disabled?: boolean;
  }>(),
  { disabled: false },
);
const emit = defineEmits<{ "update:inherited": [value: boolean] }>();
defineSlots<{
  /** The control for a custom value; rendered only when the setting is not inherited. */
  default?(props: { disabled: boolean }): unknown;
  /** Sits beside the switch, e.g. a translations button. */
  extra?(): unknown;
}>();

const { t } = useFlareI18nOptional();
const valueId = `flare-admin-inherit-field-${useId()}`;
const switchLabel = computed(() => `${props.label} · ${t("inheritField.useDefault")}`);
</script>

<template>
  <div class="flare-admin-inherit-field" :data-inherited="inherited">
    <div class="flare-admin-inherit-field__value">
      <p v-if="inherited" :id="valueId" class="flare-admin-inherit-field__default">
        {{ t("inheritField.defaultValue", { value: inheritedValue }) }}
      </p>
      <slot v-else :disabled="disabled" />
    </div>
    <div class="flare-admin-inherit-field__switch">
      <NSwitch
        size="small"
        :value="inherited"
        :disabled="disabled"
        :aria-label="switchLabel"
        @update:value="(value: boolean) => emit('update:inherited', value)"
      />
      <span class="flare-admin-inherit-field__switch-text" aria-hidden="true">{{ t("inheritField.useDefault") }}</span>
      <slot name="extra" />
    </div>
  </div>
</template>

<style scoped>
.flare-admin-inherit-field {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--flare-size-spacing-xs) var(--flare-size-spacing-md);
  min-width: 0;
  max-width: 100%;
}
.flare-admin-inherit-field__value {
  flex: 1 1 auto;
  min-width: 0;
}
.flare-admin-inherit-field__default {
  margin: 0;
  overflow-wrap: anywhere;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-md);
  line-height: var(--flare-size-line-height-tight);
}
.flare-admin-inherit-field__switch {
  display: inline-flex;
  flex: none;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  max-width: 100%;
}
.flare-admin-inherit-field__switch-text {
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-caption-font-size);
  line-height: var(--flare-text-caption-line-height);
  white-space: nowrap;
}
</style>
