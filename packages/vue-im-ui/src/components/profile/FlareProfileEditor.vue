<script setup lang="ts">
import { ref } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIcon from "../general/FlareIcon.vue";
import FlareInput from "../general/FlareInput.vue";
import FlareFormField from "../form/FlareFormField.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareUserProfile } from "../../shared/contracts";

const props = withDefaults(defineProps<{ user: FlareUserProfile; busy?: boolean }>(), { busy: false });
const emit = defineEmits<{
  (e: "save", payload: { name: string; signature: string }): void;
  (e: "cancel"): void;
  (e: "pickAvatar"): void;
}>();

const { t } = useFlareI18n();
const name = ref(props.user.name);
const signature = ref(props.user.signature ?? "");
</script>

<template>
  <div class="flare-profile-editor">
    <button type="button" class="flare-profile-editor__avatar" :aria-label="t('profileEditor.changeAvatar')" @click="emit('pickAvatar')">
      <FlareAvatar :user-id="user.id" :display-name="name || user.name" :avatar-url="user.avatarUrl" :size="80" />
      <span class="flare-profile-editor__cam" aria-hidden="true"><FlareIcon name="camera" :size="16" /></span>
    </button>
    <FlareFormField :label="t('profileEditor.nickname')">
      <FlareInput v-model="name" :placeholder="t('profileEditor.nicknamePlaceholder')" :max-length="24" clearable />
    </FlareFormField>
    <FlareFormField :label="t('profileEditor.bio')">
      <FlareInput v-model="signature" :placeholder="t('profileEditor.bioPlaceholder')" multiline :max-length="60" />
    </FlareFormField>
    <div class="flare-profile-editor__actions">
      <FlareButton variant="secondary" block :label="t('profileEditor.cancel')" @click="emit('cancel')" />
      <FlareButton
        block
        :label="t('profileEditor.save')"
        :loading="busy"
        :disabled="!name.trim() || busy"
        @click="emit('save', { name, signature })"
      />
    </div>
  </div>
</template>

<style scoped>
.flare-profile-editor {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-md);
  padding: var(--flare-size-spacing-lg) var(--flare-size-spacing-md);
}
.flare-profile-editor__avatar {
  position: relative;
  align-self: center;
  margin: 0 0 var(--flare-size-spacing-sm);
  padding: 0;
  border: 0;
  border-radius: var(--flare-size-radius-full);
  background: none;
  cursor: pointer;
}
.flare-profile-editor__avatar:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
}
.flare-profile-editor__cam {
  position: absolute;
  inset-inline-end: 0;
  inset-block-end: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  width: var(--flare-size-icon-size-lg);
  height: var(--flare-size-icon-size-lg);
  border: 2px solid var(--flare-color-bg-primary);
  border-radius: var(--flare-size-radius-full);
  background: var(--flare-color-primary);
  color: var(--flare-color-message-outgoing-foreground);
}
.flare-profile-editor__actions {
  display: flex;
  gap: var(--flare-size-spacing-md);
  margin-top: var(--flare-size-spacing-sm);
}
</style>
