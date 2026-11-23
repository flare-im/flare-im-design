<script setup lang="ts">
// Label / value fields (a view's own fields, a fields block). R3 of docs/plugin-experience.md: a toned or unmapped
// value is the kit Tag (unmapped reads pluginView.unknownStatus, never raw); reference fields fold into one
// References group after the others, each with a copy key.
import { computed } from "vue";
import FlareUserIdentity from "../../data/FlareUserIdentity.vue";
import FlareDescriptionList from "../../data/FlareDescriptionList.vue";
import FlareTag from "../../general/FlareTag.vue";
import FlareIconButton from "../../general/FlareIconButton.vue";
import { flareIcons } from "../../../shared/icons";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";
import { flarePluginSplitReferences, flarePluginStatusDraw } from "../../../shared/contracts/plugin-experience";
import { useFlarePluginWarnScope } from "./warnScope";
import type { FlarePluginField } from "../../../shared/contracts/plugin-ui";

defineOptions({ inheritAttrs: false });
const props = defineProps<{ fields: ReadonlyArray<FlarePluginField>; listClass?: string }>();
const { t } = useFlareI18nOptional();
const split = computed(() => flarePluginSplitReferences(props.fields));
const warnAt = useFlarePluginWarnScope();
const drawn = computed(() => split.value.main.map((field) => ({ field, status: flarePluginStatusDraw(field, warnAt(`field:${field.label}`)) })));
const references = computed(() => split.value.references.map((field, index) => ({ key: String(index), slot: `item-${index}`, label: field.label, value: field.value, monospace: true })));
/** The copy key of a reference line (its accessible name: pluginView.copyReference with the field's label). */
function copy(text: string): void {
  void navigator.clipboard?.writeText(text).catch(() => undefined);
}
</script>

<template>
  <dl v-bind="$attrs" class="flare-plugin-fields" :class="listClass">
    <div v-for="({ field, status }, index) in drawn" :key="index" class="flare-plugin-fields__row">
      <dt>{{ field.label }}</dt>
      <dd>
        <FlareUserIdentity v-if="field.user" :user="field.user" />
        <FlareTag
          v-else-if="status.draw === 'tag'"
          :label="status.unknown ? t('pluginView.unknownStatus') : status.text"
          :tone="status.tone"
          :data-tone="status.tone"
          :data-unknown="status.unknown ? 'true' : undefined"
          data-status-tag="true"
        /><template v-else>{{ field.value }}</template>
      </dd>
    </div>
  </dl>
  <details v-if="references.length" class="flare-plugin-references" data-references="true">
    <summary class="flare-plugin-references__title">{{ t("pluginView.references") }}</summary>
    <FlareDescriptionList :items="references" :columns="1">
      <template v-for="item in references" #[item.slot]>
        <span class="flare-plugin-references__value">{{ item.value }}</span>
        <FlareIconButton
          class="flare-plugin-references__copy"
          :icon="flareIcons.copy"
          :ariaLabel="t('pluginView.copyReference', { label: item.label })"
          size="sm"
          shape="square"
          data-reference-copy="true"
          @click="copy(item.value)"
        />
      </template>
    </FlareDescriptionList>
  </details>
</template>

<style scoped>
.flare-plugin-fields { display: grid; gap: var(--flare-size-spacing-xs); margin: 0; font-size: var(--flare-size-font-size-md); }
.flare-plugin-fields__row { display: grid; grid-template-columns: minmax(4em, 1fr) minmax(0, 2fr); gap: var(--flare-size-spacing-md); }
.flare-plugin-fields dt { color: var(--flare-color-text-secondary); }
.flare-plugin-fields dd { margin: 0; color: var(--flare-color-text-primary); overflow-wrap: anywhere; }
.flare-plugin-references { min-width: 0; }
.flare-plugin-references__title {
  min-height: var(--flare-size-layout-touch-target-min);
  display: flex;
  align-items: center;
  cursor: pointer;
  font-size: var(--flare-size-font-size-md);
  font-weight: var(--flare-size-font-weight-semibold);
  color: var(--flare-color-text-secondary);
}
.flare-plugin-references :deep(.flare-description-list__text) { display: inline-flex; align-items: center; gap: var(--flare-size-spacing-xs); min-width: 0; }
.flare-plugin-references__value { min-width: 0; overflow-wrap: anywhere; }
.flare-plugin-references__copy { flex: none; }
.flare-plugin-references__title:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
</style>
