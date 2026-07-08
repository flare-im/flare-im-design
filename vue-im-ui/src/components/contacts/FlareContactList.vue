<script setup lang="ts">
import { computed } from "vue";
import FlareContactItem from "./FlareContactItem.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import type { FlareContact } from "../../shared/contracts";

const props = withDefaults(
  defineProps<{ items: FlareContact[]; indexed?: boolean; loading?: boolean }>(),
  { indexed: true, loading: false },
);
const emit = defineEmits<{ (e: "select", c: FlareContact): void }>();

function letter(c: FlareContact): string {
  const k = (c.indexKey ?? c.name.trim().charAt(0) ?? "#").toUpperCase();
  return k >= "A" && k <= "Z" ? k : "#";
}
const groups = computed<[string, FlareContact[]][]>(() => {
  const map = new Map<string, FlareContact[]>();
  for (const c of props.items) {
    const l = letter(c);
    (map.get(l) ?? map.set(l, []).get(l)!).push(c);
  }
  return [...map.entries()].sort((a, b) => a[0].localeCompare(b[0]));
});
function jump(l: string) {
  document.getElementById(`flare-grp-${l}`)?.scrollIntoView({ behavior: "smooth", block: "start" });
}
</script>

<template>
  <div class="flare-contact-list">
    <FlareEmptyState v-if="!items.length && !loading" title="还没有联系人" />
    <div v-else class="flare-contact-list__scroll">
      <div v-for="[l, people] in groups" :key="l">
        <div :id="`flare-grp-${l}`" class="flare-contact-list__head">{{ l }}</div>
        <FlareContactItem
          v-for="p in people"
          :key="p.id"
          :item="p"
          @select="emit('select', p)"
        />
      </div>
    </div>
    <div v-if="indexed && groups.length > 1" class="flare-contact-list__idx">
      <span v-for="[l] in groups" :key="l" @click="jump(l)">{{ l }}</span>
    </div>
  </div>
</template>

<style scoped>
.flare-contact-list { position: relative; height: 100%; }
.flare-contact-list__scroll { height: 100%; overflow-y: auto; }
.flare-contact-list__head {
  position: sticky;
  top: 0;
  padding: 4px 14px;
  font-size: 12px;
  font-weight: 600;
  color: var(--flare-color-text-tertiary);
  background: var(--flare-color-bg-secondary);
}
.flare-contact-list__idx {
  position: absolute;
  right: 2px;
  top: 50%;
  transform: translateY(-50%);
  display: flex;
  flex-direction: column;
  gap: 2px;
  font-size: 10px;
  font-weight: 600;
  color: var(--flare-color-primary);
}
.flare-contact-list__idx span { cursor: pointer; padding: 0 2px; }
</style>
