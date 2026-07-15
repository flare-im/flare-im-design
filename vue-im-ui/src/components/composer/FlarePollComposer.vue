<script setup lang="ts">
import { ref, computed } from "vue";
import { NIcon } from "naive-ui";
import { AddOutline, CloseOutline, CheckboxOutline } from "@vicons/ionicons5";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(defineProps<{ maxOptions?: number }>(), { maxOptions: 10 });
const emit = defineEmits<{
  (e: "submit", payload: { question: string; options: string[]; multiple: boolean }): void;
  (e: "cancel"): void;
}>();

const { t } = useFlareI18n();
const question = ref("");
const options = ref<string[]>(["", ""]);
const multiple = ref(false);

const canAdd = computed(() => options.value.length < props.maxOptions);
const filledOptions = computed(() => options.value.map((o) => o.trim()).filter(Boolean));
const canSubmit = computed(() => question.value.trim().length > 0 && filledOptions.value.length >= 2);

function addOption(): void {
  if (canAdd.value) options.value.push("");
}
function removeOption(i: number): void {
  if (options.value.length > 2) options.value.splice(i, 1);
}
function submit(): void {
  if (!canSubmit.value) return;
  emit("submit", { question: question.value.trim(), options: filledOptions.value, multiple: multiple.value });
}
</script>

<template>
  <div class="flare-poll-composer">
    <header class="flare-poll-composer__head">
      <span class="flare-poll-composer__title">{{ t("poll.create") }}</span>
      <button type="button" class="flare-poll-composer__close" :aria-label="t('poll.cancel')" @click="emit('cancel')">
        <n-icon :size="18" :component="CloseOutline" />
      </button>
    </header>

    <input
      v-model="question"
      class="flare-poll-composer__question"
      :placeholder="t('poll.questionPlaceholder')"
      maxlength="80"
    />

    <div class="flare-poll-composer__options">
      <div v-for="(_, i) in options" :key="i" class="flare-poll-composer__option">
        <input
          v-model="options[i]"
          class="flare-poll-composer__opt-input"
          :placeholder="t('poll.optionPlaceholder', { index: i + 1 })"
          maxlength="40"
        />
        <button
          v-if="options.length > 2"
          type="button"
          class="flare-poll-composer__opt-remove"
          :aria-label="t('poll.removeOption')"
          @click="removeOption(i)"
        >
          <n-icon :size="16" :component="CloseOutline" />
        </button>
      </div>
    </div>

    <button v-if="canAdd" type="button" class="flare-poll-composer__add" @click="addOption">
      <n-icon :size="16" :component="AddOutline" />{{ t("poll.addOption") }}
    </button>

    <label class="flare-poll-composer__multi">
      <input v-model="multiple" type="checkbox" />
      <n-icon :size="16" :component="CheckboxOutline" />
      {{ t("poll.allowMultiple") }}
    </label>

    <button type="button" class="flare-poll-composer__submit" :disabled="!canSubmit" @click="submit">
      {{ t("poll.send") }}
    </button>
  </div>
</template>

<style scoped>
.flare-poll-composer {
  width: 320px;
  max-width: 100%;
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 16px;
  border-radius: var(--flare-size-radius-xl, 14px);
  background: var(--flare-color-bg-primary, #fff);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  box-shadow: var(--flare-shadow-lg, 0 12px 28px rgba(21, 18, 32, 0.16));
}
.flare-poll-composer__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.flare-poll-composer__title {
  font-size: 15px;
  font-weight: 600;
  color: var(--flare-color-text-primary, #15131c);
}
.flare-poll-composer__close {
  border: none;
  background: transparent;
  color: var(--flare-color-text-tertiary, #a7a2b4);
  cursor: pointer;
  display: inline-flex;
}
.flare-poll-composer__question {
  border: none;
  border-bottom: 1.5px solid var(--flare-color-border-primary, #e9e6f1);
  padding: 6px 2px;
  font-size: 15px;
  font-weight: 500;
  color: var(--flare-color-text-primary, #15131c);
  background: transparent;
  outline: none;
}
.flare-poll-composer__question:focus { border-color: var(--flare-color-primary, #7c3aed); }
.flare-poll-composer__options { display: flex; flex-direction: column; gap: 8px; }
.flare-poll-composer__option {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 0 4px 0 12px;
  border-radius: var(--flare-size-radius-lg, 10px);
  background: var(--flare-color-bg-secondary, #f6f5fb);
}
.flare-poll-composer__opt-input {
  flex: 1;
  min-width: 0;
  border: none;
  outline: none;
  background: transparent;
  padding: 9px 0;
  font-size: 14px;
  color: var(--flare-color-text-primary, #15131c);
}
.flare-poll-composer__opt-remove {
  flex: 0 0 auto;
  border: none;
  background: transparent;
  color: var(--flare-color-text-tertiary, #a7a2b4);
  cursor: pointer;
  display: inline-flex;
  padding: 4px;
}
.flare-poll-composer__add {
  align-self: flex-start;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  border: none;
  background: transparent;
  color: var(--flare-color-primary, #7c3aed);
  font-size: 13px;
  cursor: pointer;
  padding: 2px 0;
}
.flare-poll-composer__multi {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: var(--flare-color-text-secondary, #6b6780);
  cursor: pointer;
}
.flare-poll-composer__multi input { display: none; }
.flare-poll-composer__submit {
  margin-top: 2px;
  height: 40px;
  border: none;
  border-radius: var(--flare-size-radius-lg, 10px);
  background: var(--im-brand-gradient, var(--flare-color-primary, #7c3aed));
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: filter var(--flare-transition-fast, 150ms ease), opacity var(--flare-transition-fast, 150ms ease);
}
.flare-poll-composer__submit:hover:not(:disabled) { filter: brightness(0.97); }
.flare-poll-composer__submit:disabled { opacity: 0.45; cursor: not-allowed; }
</style>
