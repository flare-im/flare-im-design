<script setup lang="ts">
import { ref } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareInput from "../general/FlareInput.vue";
import type { FlareUserProfile } from "../../shared/contracts";

const props = withDefaults(defineProps<{ user: FlareUserProfile; busy?: boolean }>(), { busy: false });
const emit = defineEmits<{
  (e: "save", payload: { name: string; signature: string }): void;
  (e: "cancel"): void;
  (e: "pickAvatar"): void;
}>();

const name = ref(props.user.name);
const signature = ref(props.user.signature ?? "");
</script>

<template>
  <div class="flare-profile-editor">
    <div class="flare-profile-editor__avatar" @click="emit('pickAvatar')">
      <FlareAvatar :user-id="user.id" :display-name="name || user.name" :avatar-url="user.avatarUrl" :size="80" />
      <span class="flare-profile-editor__cam">📷</span>
    </div>
    <label class="flare-profile-editor__label">昵称</label>
    <FlareInput v-model="name" placeholder="昵称" :max-length="24" clearable />
    <label class="flare-profile-editor__label">个性签名</label>
    <FlareInput v-model="signature" placeholder="介绍一下自己" multiline :max-length="60" />
    <div class="flare-profile-editor__actions">
      <button @click="emit('cancel')">取消</button>
      <button
        class="is-primary"
        :disabled="!name.trim() || busy"
        @click="emit('save', { name, signature })"
      >{{ busy ? "保存中…" : "保存" }}</button>
    </div>
  </div>
</template>

<style scoped>
.flare-profile-editor { padding: 20px 16px; display: flex; flex-direction: column; gap: 8px; }
.flare-profile-editor__avatar { align-self: center; position: relative; cursor: pointer; margin-bottom: 12px; }
.flare-profile-editor__cam {
  position: absolute; right: -2px; bottom: -2px;
  width: 26px; height: 26px; border-radius: 50%;
  background: var(--flare-color-primary); color: #fff;
  display: flex; align-items: center; justify-content: center; font-size: 13px;
}
.flare-profile-editor__label { font-size: 13px; color: var(--flare-color-text-secondary); margin-top: 8px; }
.flare-profile-editor__actions { display: flex; gap: 12px; margin-top: 16px; }
.flare-profile-editor__actions button {
  flex: 1; padding: 10px; border-radius: var(--flare-size-radius-md, 6px);
  border: 1px solid var(--flare-color-border-primary); background: none;
  color: var(--flare-color-text-primary); font-size: 14px; cursor: pointer;
}
.flare-profile-editor__actions button.is-primary {
  border-color: var(--flare-color-primary); background: var(--flare-color-primary); color: #fff;
}
.flare-profile-editor__actions button:disabled { opacity: 0.5; cursor: default; }
</style>
