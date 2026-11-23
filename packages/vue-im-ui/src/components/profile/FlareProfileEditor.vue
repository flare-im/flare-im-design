<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { useScreenLayout } from "../../shared/screenLayout";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIcon from "../general/FlareIcon.vue";
import FlareInput from "../general/FlareInput.vue";
import FlareFormField from "../form/FlareFormField.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareProfileDraft, FlareUserProfile } from "../../shared/contracts";

const props = withDefaults(defineProps<{ user: FlareUserProfile; busy?: boolean; draft?: FlareProfileDraft }>(), { busy: false });
const emit = defineEmits<{
  (e: "save", payload: FlareProfileDraft): void;
  (e: "update:draft", value: FlareProfileDraft | undefined): void;
  (e: "cancel"): void;
  (e: "pickAvatar"): void;
}>();

const { t } = useFlareI18n();
const { detail } = useScreenLayout();
const initial = (): FlareProfileDraft => ({ name: props.user.name, signature: props.user.signature ?? '' });
const value = ref<FlareProfileDraft>({ ...(props.draft ?? initial()) });
function update(patch: Partial<FlareProfileDraft>) {
  value.value = { ...value.value, ...patch };
  emit('update:draft', { ...value.value });
}
const name = computed({ get: () => value.value.name, set: name => update({ name }) });
const signature = computed({ get: () => value.value.signature, set: signature => update({ signature }) });
const dirty = computed(() => name.value !== props.user.name || signature.value !== (props.user.signature ?? ''));
watch(() => props.draft, draft => { value.value = { ...(draft ?? initial()) }; }, { deep: true });
watch(() => props.user.id, () => { value.value = initial(); emit('update:draft', undefined); });
function save() {
  if (props.busy || !name.value.trim() || !dirty.value) return;
  emit("save", { name: name.value, signature: signature.value });
}
</script>

<template>
  <div class="flare-profile-editor" :class="{ 'is-detail': detail }">
    <button type="button" class="flare-profile-editor__avatar" :disabled="busy" :aria-label="t('profileEditor.changeAvatar')" @click="emit('pickAvatar')">
      <FlareAvatar :user-id="user.id" :display-name="name || user.name" :avatar-url="user.avatarUrl" :size="48" />
      <span class="flare-profile-editor__avatar-label">{{ t('profileEditor.changeAvatar') }}</span>
      <FlareIcon class="flare-profile-editor__cam" name="camera" size="md" />
    </button>
    <FlareFormField :label="t('profileEditor.nickname')" :counter="`${name.length}/24`">
      <FlareInput v-model="name" :placeholder="t('profileEditor.nicknamePlaceholder')" :max-length="24" :show-count="false" :disabled="busy" clearable @submit="save" />
    </FlareFormField>
    <FlareFormField :label="t('profileEditor.bio')" :counter="`${signature.length}/60`">
      <FlareInput v-model="signature" :placeholder="t('profileEditor.bioPlaceholder')" :disabled="busy" multiline :max-length="60" :show-count="false" />
    </FlareFormField>
    <div class="flare-profile-editor__actions">
      <span v-if="dirty" class="flare-profile-editor__unsaved" role="status">{{ t('profileEditor.unsaved') }}</span>
      <FlareButton size="sm" variant="secondary" :block="!detail" :disabled="busy" :label="t('profileEditor.cancel')" @click="emit('cancel')" />
      <FlareButton
        size="sm"
        :block="!detail"
        :label="t('profileEditor.save')"
        :loading="busy"
        :disabled="!name.trim() || busy || !dirty"
        @click="save"
      />
    </div>
  </div>
</template>

<style scoped>
.flare-profile-editor {
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-md);
  width: 100%;
  max-width: var(--flare-size-layout-primary-pane-max-width);
  min-width: 0;
  margin-inline: auto;
  padding: var(--flare-size-spacing-md);
}
.flare-profile-editor__avatar {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  width: 100%;
  min-width: 0;
  margin: 0 0 var(--flare-size-spacing-xs);
  padding: var(--flare-size-spacing-md);
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-elevated);
  color: var(--flare-color-text-primary);
  font: inherit;
  text-align: start;
  cursor: pointer;
}
.flare-profile-editor__avatar-label {
  flex: 1;
  min-width: 0;
  font-size: var(--flare-size-font-size-lg);
  overflow-wrap: anywhere;
}
.flare-profile-editor__avatar:hover:not(:disabled) { background: var(--flare-color-bg-hover); }
.flare-profile-editor__avatar:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
}
.flare-profile-editor__avatar:disabled { cursor: wait; opacity: var(--flare-opacity-disabled); }
.flare-profile-editor__cam { flex: none; color: var(--flare-color-text-tertiary); }
.flare-profile-editor__actions {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  margin-top: var(--flare-size-spacing-xs);
  padding-bottom: env(safe-area-inset-bottom, 0px);
}
.flare-profile-editor__unsaved { flex: none; margin-inline-end: auto; color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); }
.flare-profile-editor.is-detail { max-width: none; margin: 0; padding: 0; }
.flare-profile-editor.is-detail .flare-profile-editor__actions { justify-content: flex-end; gap: var(--flare-size-spacing-sm); }
</style>
