<script setup lang="ts">
import { computed, ref } from 'vue';
import type { FlareMentionCandidate } from '../../shared/contracts';
import FlareAvatar from '../conversation/FlareAvatar.vue';
const props = withDefaults(defineProps<{
  candidates: FlareMentionCandidate[];
  allowEveryone?: boolean;
  searchPlaceholder?: string;
  everyoneLabel?: string;
  emptyText?: string;
}>(), { allowEveryone: false, searchPlaceholder: '搜索成员', everyoneLabel: '所有人', emptyText: '没有匹配的成员' });
const emit = defineEmits<{ select: [candidate: FlareMentionCandidate]; close: [] }>();
const query = ref('');
const root = ref<HTMLElement>();
const results = computed(() => {
  const all: FlareMentionCandidate[] = props.allowEveryone
    ? [{ id: '__all__', name: props.everyoneLabel, isEveryone: true }, ...props.candidates]
    : props.candidates;
  const q = query.value.trim().toLocaleLowerCase();
  return all.filter(c => `${c.name} ${c.detail ?? ''}`.toLocaleLowerCase().includes(q));
});
function move(event: KeyboardEvent) {
  if (event.key === 'Escape') { event.preventDefault(); emit('close'); return; }
  if (event.key !== 'ArrowDown' && event.key !== 'ArrowUp') return;
  const buttons = Array.from(root.value?.querySelectorAll<HTMLButtonElement>('.flare-mention__person') ?? []);
  if (!buttons.length) return;
  event.preventDefault();
  const index = buttons.indexOf(event.target as HTMLButtonElement);
  const next = index < 0 ? (event.key === 'ArrowDown' ? 0 : buttons.length - 1)
    : (index + (event.key === 'ArrowDown' ? 1 : -1) + buttons.length) % buttons.length;
  buttons[next].focus();
}
</script>
<template>
  <section ref="root" class="flare-mention" :aria-label="searchPlaceholder" @keydown="move">
    <input v-model="query" class="flare-mention__search" type="search" :aria-label="searchPlaceholder" :placeholder="searchPlaceholder" />
    <div class="flare-mention__list">
      <button v-for="candidate in results" :key="candidate.id" class="flare-mention__person" type="button" @click="emit('select', candidate)">
        <FlareAvatar :user-id="candidate.id" :display-name="candidate.name" :avatar-url="candidate.avatarUrl" :size="32" />
        <span class="flare-mention__copy"><strong>{{ candidate.name }}</strong><small v-if="candidate.detail">{{ candidate.detail }}</small></span>
      </button>
      <p v-if="!results.length" role="status">{{ emptyText }}</p>
    </div>
  </section>
</template>
<style scoped>
.flare-mention { width: 320px; max-width: 100%; min-width: 0; overflow: hidden; border: 1px solid var(--flare-color-border-primary); border-radius: 12px; background: var(--flare-color-bg-primary); color: var(--flare-color-text-primary); }
.flare-mention__search { box-sizing: border-box; width: 100%; min-height: 48px; padding: 12px; border: 0; border-bottom: 1px solid var(--flare-color-border-primary); background: transparent; color: inherit; font: inherit; }
.flare-mention__list { max-height: 280px; overflow-y: auto; padding: 4px; }
.flare-mention__person { display: flex; align-items: center; gap: 12px; width: 100%; min-height: 48px; padding: 8px; border: 0; border-radius: 8px; background: transparent; color: inherit; text-align: start; font: inherit; cursor: pointer; }
.flare-mention__person:hover, .flare-mention__person:focus-visible { background: var(--flare-color-bg-selected); }
.flare-mention__person:focus-visible, .flare-mention__search:focus-visible { outline: 2px solid var(--flare-color-primary); outline-offset: -2px; }
.flare-mention__copy { display: grid; gap: 2px; min-width: 0; }
.flare-mention__copy strong { font-size: 14px; font-weight: 500; }
.flare-mention__copy small { font-size: 12px; color: var(--flare-color-text-secondary); }
.flare-mention__copy strong, .flare-mention__copy small { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
p { padding: 16px; color: var(--flare-color-text-secondary); }
</style>
