<script setup lang="ts">
import { computed, nextTick, ref, useId, watch } from 'vue';
import type { FlareMentionCandidate } from '../../shared/contracts';
import FlareAvatar from '../conversation/FlareAvatar.vue';
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
const props = withDefaults(defineProps<{
  candidates: FlareMentionCandidate[];
  allowEveryone?: boolean;
  searchPlaceholder?: string;
  everyoneLabel?: string;
  emptyText?: string;
}>(), { allowEveryone: false });
const { t } = useFlareI18n();
const strings = computed(() => ({
  searchPlaceholder: props.searchPlaceholder ?? t("mentionPicker.searchPlaceholder"),
  everyoneLabel: props.everyoneLabel ?? t("mentionPicker.everyone"),
  emptyText: props.emptyText ?? t("mentionPicker.empty"),
}));
const emit = defineEmits<{ select: [candidate: FlareMentionCandidate]; close: [] }>();
const query = ref('');
const list = ref<HTMLElement>();
const listId = `flare-mention-${useId()}`;
const results = computed(() => {
  const all: FlareMentionCandidate[] = props.allowEveryone
    ? [{ id: '__all__', name: strings.value.everyoneLabel, isEveryone: true }, ...props.candidates]
    : props.candidates;
  const q = query.value.trim().toLocaleLowerCase();
  return all.filter(c => `${c.name} ${c.detail ?? ''}`.toLocaleLowerCase().includes(q));
});
// Combobox: focus stays in the search field; the arrows move the highlighted person and Enter picks
// it, so "@", a few letters and Enter mentions someone without leaving the keyboard.
const activeIndex = ref(0);
watch(results, () => { activeIndex.value = 0; });
const activeId = computed(() => (results.value.length ? `${listId}-${activeIndex.value}` : undefined));
function highlight(index: number) {
  activeIndex.value = index;
  void nextTick(() => list.value?.querySelector<HTMLElement>(`#${activeId.value}`)?.scrollIntoView({ block: 'nearest' }));
}
function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape') { event.preventDefault(); emit('close'); return; }
  // An IME commit also sends Enter; it confirms the typed letters, not a person.
  if (event.isComposing || event.keyCode === 229) return;
  const count = results.value.length;
  if (!count) return;
  if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
    event.preventDefault();
    highlight((activeIndex.value + (event.key === 'ArrowDown' ? 1 : -1) + count) % count);
  } else if (event.key === 'Enter') {
    event.preventDefault();
    emit('select', results.value[activeIndex.value]);
  }
}
</script>
<template>
  <section class="flare-mention" :aria-label="strings.searchPlaceholder">
    <input
      v-model="query"
      class="flare-mention__search"
      type="search"
      role="combobox"
      aria-expanded="true"
      aria-autocomplete="list"
      :aria-controls="listId"
      :aria-activedescendant="activeId"
      :aria-label="strings.searchPlaceholder"
      :placeholder="strings.searchPlaceholder"
      @keydown="onKeydown"
    />
    <div :id="listId" ref="list" class="flare-mention__list" role="listbox" :aria-label="strings.searchPlaceholder">
      <div
        v-for="(candidate, index) in results"
        :id="`${listId}-${index}`"
        :key="candidate.id"
        class="flare-mention__person"
        :class="{ 'is-active': index === activeIndex }"
        role="option"
        :aria-selected="index === activeIndex"
        @mousedown.prevent
        @mousemove="activeIndex = index"
        @click="emit('select', candidate)"
      >
        <FlareAvatar :user-id="candidate.id" :display-name="candidate.name" :avatar-url="candidate.avatarUrl" :size="32" />
        <span class="flare-mention__copy"><strong>{{ candidate.name }}</strong><small v-if="candidate.detail">{{ candidate.detail }}</small></span>
      </div>
      <p v-if="!results.length" role="status">{{ strings.emptyText }}</p>
    </div>
  </section>
</template>
<style scoped>
.flare-mention { width: 320px; max-width: 100%; min-width: 0; overflow: hidden; border: 1px solid var(--flare-color-border-primary); border-radius: var(--flare-size-radius-card); background: var(--flare-color-bg-primary); color: var(--flare-color-text-primary); }
.flare-mention__search { box-sizing: border-box; width: 100%; min-height: 48px; padding: 12px; border: 0; border-bottom: 1px solid var(--flare-color-border-primary); background: transparent; color: inherit; font: inherit; }
.flare-mention__list { max-height: 280px; overflow-y: auto; padding: 4px; }
.flare-mention__person { display: flex; align-items: center; gap: 12px; width: 100%; min-height: 48px; padding: 8px; border: 0; border-radius: 8px; background: transparent; color: inherit; text-align: start; font: inherit; cursor: pointer; }
.flare-mention__person.is-active { background: var(--flare-color-bg-selected); }
/* 焦点用它本来就有的那条下划线加重表示,不画框。原来是 2px 实色 outline 配 offset -2px,
   等于沿着整条输入框的四边画一个实心紫色矩形 —— 而面板一开就自动聚焦,这个框是常驻的。
   行和按钮继续用那圈 outline:它们是小目标,框得住;一条整宽的文本域框不住。 */
.flare-mention__search:focus-visible {
  outline: none;
  border-block-end-color: var(--flare-color-border-selected);
  box-shadow: inset 0 -1px 0 var(--flare-color-border-selected);
}
.flare-mention__copy { display: grid; gap: 2px; min-width: 0; }
.flare-mention__copy strong { font-size: 14px; font-weight: 500; }
.flare-mention__copy small { font-size: 12px; color: var(--flare-color-text-secondary); }
.flare-mention__copy strong, .flare-mention__copy small { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
p { padding: 16px; color: var(--flare-color-text-secondary); }
</style>
