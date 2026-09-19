<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareCheckbox from "../form/FlareCheckbox.vue";
import type { FlareContact } from "../../shared/contracts";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    item: FlareContact;
    showPresence?: boolean;
    /** Picker row: a leading checkbox, and a tap toggles instead of selecting. */
    selectable?: boolean;
    /** Checked state of a selectable row. */
    selected?: boolean;
  }>(),
  { showPresence: false, selectable: false, selected: false },
);
const emit = defineEmits<{ (e: "select"): void; (e: "toggleSelect"): void }>();
// A row is drawn inside lists a host may mount without the provider, so the words are optional.
const { t } = useFlareI18nOptional();
// Only a relationship worth saying something about gets a tag: "none" is what most rows are.
const relationTag = computed(() => {
  const relation = props.item.relation;
  return relation && relation !== "none" ? t(`relationTag.${relation}`) : "";
});

// A plain row is a button only when someone handles `select`; otherwise it is display-only.
const instance = getCurrentInstance();
const interactive = computed(() => Boolean(instance?.vnode.props?.onSelect));
</script>

<template>
  <div class="flare-contact-item" :class="{ 'is-selectable': selectable }">
    <!-- The checkbox is the row's one focus stop, named by the contact; the whole row is its label. -->
    <FlareCheckbox
      v-if="selectable"
      class="flare-contact-item__main"
      :model-value="selected"
      :aria-label="item.name"
      @update:model-value="emit('toggleSelect')"
    >
      <FlareAvatar :user-id="item.id" :display-name="item.name" :avatar-url="item.avatarUrl" :size="40" :presence="showPresence ? item.presence : undefined" />
      <span class="flare-contact-item__body">
        <span class="flare-contact-item__name">{{ item.name }}</span>
        <span v-if="item.signature" class="flare-contact-item__sig">{{ item.signature }}</span>
      </span>
    </FlareCheckbox>
    <component
      :is="interactive ? 'button' : 'div'"
      v-else
      :type="interactive ? 'button' : undefined"
      class="flare-contact-item__main"
      :class="{ 'is-interactive': interactive }"
      @click="interactive && emit('select')"
    >
      <FlareAvatar :user-id="item.id" :display-name="item.name" :avatar-url="item.avatarUrl" :size="40" :presence="showPresence ? item.presence : undefined" />
      <span class="flare-contact-item__body">
        <span class="flare-contact-item__name">{{ item.name }}</span>
        <span v-if="item.signature" class="flare-contact-item__sig">{{ item.signature }}</span>
      </span>
    </component>
    <span v-if="relationTag" class="flare-contact-item__relation">{{ relationTag }}</span>
    <!-- Row-end content (a status, an action): its own focus stops, and its clicks never reach the row. -->
    <div v-if="$slots.trailing" class="flare-contact-item__trailing" @click.stop><slot name="trailing" /></div>
  </div>
</template>

<style scoped>
.flare-contact-item {
  display: flex;
  align-items: center;
  width: 100%;
  border-radius: var(--flare-size-radius-lg);
}
.flare-contact-item__main {
  box-sizing: border-box;
  flex: 1;
  min-width: 0;
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  padding: var(--flare-size-spacing-sm) 14px;
  border: 0;
  background: transparent;
  color: inherit;
  text-align: left;
  font: inherit;
  border-radius: var(--flare-size-radius-lg);
  transition: background var(--flare-transition-fast);
}
.flare-contact-item__main.is-interactive,
.flare-contact-item.is-selectable .flare-contact-item__main { cursor: pointer; }
.flare-contact-item__main.is-interactive:hover,
.flare-contact-item__main.is-interactive:focus-visible,
.flare-contact-item.is-selectable .flare-contact-item__main:hover {
  background: var(--flare-color-bg-hover);
}
.flare-contact-item__main.is-interactive:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: -2px;
}
/* A selectable row is the kit checkbox: its label wraps avatar + text and takes the row width so the text can truncate. */
.flare-contact-item.is-selectable .flare-contact-item__main {
  display: flex;
  gap: var(--flare-size-spacing-md);
}
.flare-contact-item.is-selectable :deep(.flare-checkbox__label) {
  flex: 1;
  min-width: 0;
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md);
}
.flare-contact-item__body {
  display: flex;
  flex-direction: column;
  min-width: 0;
}
.flare-contact-item__name {
  color: var(--flare-color-text-primary);
  font-size: var(--flare-size-font-size-lg);
  font-weight: 500;
}
.flare-contact-item__sig {
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-tertiary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 240px;
}
/* The relationship, said once and quietly: it is context for the name, not an action. */
.flare-contact-item__relation {
  flex: none;
  align-self: center;
  padding: 2px 8px;
  border-radius: var(--flare-size-radius-full);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-sm);
  white-space: nowrap;
}
.flare-contact-item__trailing {
  flex: none;
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  padding-inline-end: 14px;
}
@media (prefers-reduced-motion: reduce) { .flare-contact-item__main { transition: none; } }
</style>
