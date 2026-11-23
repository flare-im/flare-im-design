<script setup lang="ts">
/** Two independent, directional moment visibility lists. The host owns every write. */
import { computed, getCurrentInstance, useId } from "vue";
import { PersonAddOutline } from "../../shared/icon-glyphs";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIcon from "../general/FlareIcon.vue";
import FlareSkeleton from "../general/FlareSkeleton.vue";
import { useFlareI18n } from "../../shared/i18n";
import type { FlareContactBrief, FlareMomentsVisibilityRuleKind } from "../../shared/contracts";

const props = defineProps<{ kind: FlareMomentsVisibilityRuleKind; members: FlareContactBrief[]; loading?: boolean }>();
const emit = defineEmits<{
  (e: "add"): void;
  (e: "remove", member: FlareContactBrief): void;
  (e: "selectMember", member: FlareContactBrief): void;
}>();
const { t } = useFlareI18n();
const id = useId();
const instance = getCurrentInstance();
const selectable = computed(() => !!instance?.vnode.props?.onSelectMember);
const isHideFrom = computed(() => props.kind === "hideFrom");
const title = computed(() => t(isHideFrom.value ? "momentsVisibility.hideFromTitle" : "momentsVisibility.muteTitle"));
const hint = computed(() => t(isHideFrom.value ? "momentsVisibility.hideFromHint" : "momentsVisibility.muteHint"));
</script>

<template>
  <section class="flare-moments-visibility" :class="`is-${kind}`" :aria-labelledby="`${id}-title`" :aria-describedby="`${id}-hint`" :aria-busy="!!loading">
    <header class="flare-moments-visibility__head">
      <FlareIcon :name="isHideFrom ? 'eye-off' : 'mute'" size="md" class="flare-moments-visibility__icon" />
      <div class="flare-moments-visibility__titles">
        <h2 :id="`${id}-title`" class="flare-moments-visibility__title">{{ title }}</h2>
        <p :id="`${id}-hint`" class="flare-moments-visibility__hint">{{ hint }}</p>
      </div>
      <FlareButton size="sm" variant="text" :icon="PersonAddOutline" :label="t('contactMatch.add')" :disabled="loading" :aria-label="`${t('contactMatch.add')} · ${title}`" @click="emit('add')" />
    </header>
    <div v-if="loading" class="flare-moments-visibility__body"><FlareSkeleton variant="text" :rows="2" /></div>
    <p v-else-if="!members.length" class="flare-moments-visibility__empty" role="status">{{ t('momentsVisibility.empty') }}</p>
    <ul v-else class="flare-moments-visibility__body">
      <li v-for="m in members" :key="m.userId" class="flare-moments-visibility__row">
        <component :is="selectable ? 'button' : 'div'" class="flare-moments-visibility__member" :class="{ 'is-interactive': selectable }" :type="selectable ? 'button' : undefined" @click="selectable && emit('selectMember', m)">
          <FlareAvatar :user-id="m.userId" :display-name="m.displayName" :avatar-url="m.avatarUrl" :size="32" />
          <span class="flare-moments-visibility__name" :title="m.displayName">{{ m.displayName }}</span>
        </component>
        <FlareButton size="sm" variant="quiet" :label="t('momentsVisibility.remove')" :aria-label="`${t('momentsVisibility.remove')} ${m.displayName}`" @click="emit('remove', m)" />
      </li>
    </ul>
  </section>
</template>

<style scoped>
.flare-moments-visibility {
  min-width: 0;
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-primary);
}
.flare-moments-visibility__head {
  display: flex;
  align-items: flex-start;
  gap: var(--flare-size-spacing-sm);
  padding: var(--flare-size-spacing-md);
}
.flare-moments-visibility__icon { flex: none; color: var(--flare-color-text-secondary); }
.is-hideFrom .flare-moments-visibility__icon { color: var(--flare-color-warning-text); }
.flare-moments-visibility__titles { flex: 1; min-width: 0; }
.flare-moments-visibility__title {
  margin: 0;
  font-size: var(--flare-size-font-size-lg);
  font-weight: var(--flare-size-font-weight-semibold);
  line-height: var(--flare-size-line-height-snug);
  color: var(--flare-color-text-primary);
  overflow-wrap: anywhere;
}
.flare-moments-visibility__hint {
  margin: var(--flare-size-spacing-xs) 0 0;
  font-size: var(--flare-size-font-size-sm);
  line-height: var(--flare-size-line-height-normal);
  color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
}
.flare-moments-visibility__body { padding: 0 var(--flare-size-spacing-md) var(--flare-size-spacing-sm); margin: 0; list-style: none; }
.flare-moments-visibility__row { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); min-height: var(--flare-size-layout-touch-target); }
.flare-moments-visibility__row + .flare-moments-visibility__row { border-top: 1px solid var(--flare-color-border-secondary); }
.flare-moments-visibility__member {
  flex: 1; min-width: 0; min-height: var(--flare-size-layout-touch-target);
  display: flex; align-items: center; gap: var(--flare-size-spacing-sm);
  padding: 0; text-align: start; color: inherit; background: none; border: 0;
}
.flare-moments-visibility__member.is-interactive { cursor: pointer; }
.flare-moments-visibility__member:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; border-radius: var(--flare-size-radius-md); }
.flare-moments-visibility__name { flex: 1; min-width: 0; font-size: var(--flare-size-font-size-lg); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.flare-moments-visibility__empty { margin: 0; padding: 0 var(--flare-size-spacing-md) var(--flare-size-spacing-md); font-size: var(--flare-size-font-size-md); line-height: var(--flare-size-line-height-normal); color: var(--flare-color-text-tertiary); }
</style>
