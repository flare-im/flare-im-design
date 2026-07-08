<script setup lang="ts">
import { computed, reactive, watch } from "vue";
import { NButton, NModal, NTag } from "naive-ui";
import { resolveComposerAction } from "../messageTypeRegistry";
import type { ComposerPayloadRequest } from "../types";
import { useFlareI18n } from "../../shared/i18n";
const { t } = useFlareI18n();

const props = defineProps<{
  show: boolean;
  op: string;
  loading?: boolean;
}>();

const emit = defineEmits<{
  (event: "update:show", value: boolean): void;
  (event: "submit", payload: ComposerPayloadRequest): void;
}>();

type ComposerFormValue = string | number | boolean | string[];

const form = reactive<Record<string, ComposerFormValue>>({});

const action = computed(() => {
  const resolved = resolveComposerAction(props.op);
  return resolved?.acceptsFiles ? undefined : resolved;
});
const title = computed(() => action.value?.label ?? t("enhance.messageFallback"));

watch(
  () => props.show,
  (open) => {
    if (!open || !action.value) return;
    Object.keys(form).forEach((key) => delete form[key]);
    Object.assign(form, action.value.defaultParams() as Record<string, ComposerFormValue>);
  },
);

function setOptions(value: string): void {
  form.options = value.split("\n").map((item) => item.trim()).filter(Boolean);
}

function setOptionsFromEvent(event: Event): void {
  setOptions((event.target as HTMLTextAreaElement).value);
}

function fieldText(key: string): string {
  const value = form[key];
  return typeof value === "string" || typeof value === "number" ? String(value) : "";
}

function setTextField(key: string, event: Event): void {
  form[key] = (event.target as HTMLTextAreaElement | HTMLInputElement).value;
}

function optionsText(): string {
  return Array.isArray(form.options) ? form.options.join("\n") : "";
}

function submit(): void {
  const current = action.value;
  if (!current) return;
  emit("submit", current.buildRequest({ ...form }, []));
}
</script>

<template>
  <n-modal
    :show="show"
    preset="card"
    class="composer-payload-modal"
    :title="t('enhance.sendTitle', { title })"
    :bordered="false"
    @update:show="emit('update:show', $event)"
  >
    <div v-if="action" class="composer-payload-modal__body">
      <div class="composer-payload-modal__intro">
        <n-tag size="small" round>{{ action.kind }}</n-tag>
        <span>{{ action.description }}</span>
      </div>

      <template v-if="action.kind === 'richText'">
        <label class="composer-payload-modal__field">
          <span>{{ t('enhance.title') }}</span>
          <input v-model="form.title" class="composer-payload-modal__input" />
        </label>
        <label class="composer-payload-modal__field">
          <span>{{ t('composeType.field.richMarkdown') }}</span>
          <textarea
            :value="fieldText('markdown')"
            class="composer-payload-modal__textarea composer-payload-modal__textarea--rich"
            @input="setTextField('markdown', $event)"
          />
        </label>
      </template>

      <template v-else-if="action.kind === 'vote'">
        <label class="composer-payload-modal__field">
          <span>{{ t('composeType.field.voteTitle') }}</span>
          <input v-model="form.title" class="composer-payload-modal__input" />
        </label>
        <label class="composer-payload-modal__field">
          <span>{{ t('enhance.optionsPerLine') }}</span>
          <textarea :value="optionsText()" class="composer-payload-modal__textarea" @input="setOptionsFromEvent" />
        </label>
        <div class="composer-payload-modal__switches">
          <label><input v-model="form.multiple" type="checkbox" /> {{ t('enhance.multiple') }}</label>
          <label><input v-model="form.anonymous" type="checkbox" /> {{ t('enhance.anonymous') }}</label>
        </div>
      </template>

      <template v-else>
        <label v-if="'id' in form" class="composer-payload-modal__field">
          <span>ID</span>
          <input v-model="form.id" class="composer-payload-modal__input" />
        </label>
        <label v-if="'threadId' in form" class="composer-payload-modal__field">
          <span>Thread ID</span>
          <input v-model="form.threadId" class="composer-payload-modal__input" />
        </label>
        <label v-if="'appId' in form" class="composer-payload-modal__field">
          <span>App ID</span>
          <input v-model="form.appId" class="composer-payload-modal__input" />
        </label>
        <label v-if="'cardType' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.cardType') }}</span>
          <input v-model="form.cardType" class="composer-payload-modal__input" />
        </label>
        <label v-if="'pagePath' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.path') }}</span>
          <input v-model="form.pagePath" class="composer-payload-modal__input" />
        </label>
        <label v-if="'title' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.titleOrName') }}</span>
          <input v-model="form.title" class="composer-payload-modal__input" />
        </label>
        <label v-if="'subtitle' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.subtitle') }}</span>
          <input v-model="form.subtitle" class="composer-payload-modal__input" />
        </label>
        <label v-if="'avatar' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.avatar') }}</span>
          <input v-model="form.avatar" class="composer-payload-modal__input" />
        </label>
        <label v-if="'appName' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.appName') }}</span>
          <input v-model="form.appName" class="composer-payload-modal__input" />
        </label>
        <label v-if="'description' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.description') }}</span>
          <textarea
            :value="fieldText('description')"
            class="composer-payload-modal__textarea"
            @input="setTextField('description', $event)"
          />
        </label>
        <label v-if="'text' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.content') }}</span>
          <textarea
            :value="fieldText('text')"
            class="composer-payload-modal__textarea"
            @input="setTextField('text', $event)"
          />
        </label>
        <label v-if="'address' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.address') }}</span>
          <input v-model="form.address" class="composer-payload-modal__input" />
        </label>
        <label v-if="'url' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.link') }}</span>
          <input v-model="form.url" class="composer-payload-modal__input" />
        </label>
        <label v-if="'thumbnailUrl' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.thumbnail') }}</span>
          <input v-model="form.thumbnailUrl" class="composer-payload-modal__input" />
        </label>
        <label v-if="'mimeType' in form" class="composer-payload-modal__field">
          <span>MIME Type</span>
          <input v-model="form.mimeType" class="composer-payload-modal__input" />
        </label>
        <label v-if="'fileName' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.fileName') }}</span>
          <input v-model="form.fileName" class="composer-payload-modal__input" />
        </label>
        <label v-if="'latitude' in form" class="composer-payload-modal__field">
          <span>{{ t('composeType.field.latitude') }}</span>
          <input v-model="form.latitude" class="composer-payload-modal__input" />
        </label>
        <label v-if="'longitude' in form" class="composer-payload-modal__field">
          <span>{{ t('composeType.field.longitude') }}</span>
          <input v-model="form.longitude" class="composer-payload-modal__input" />
        </label>
        <label v-if="'assignee' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.assignee') }}</span>
          <input v-model="form.assignee" class="composer-payload-modal__input" />
        </label>
        <label v-if="'dueTime' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.dueTime') }}</span>
          <input v-model="form.dueTime" class="composer-payload-modal__input" />
        </label>
        <label v-if="'deadline' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.dueTime') }}</span>
          <input v-model="form.deadline" class="composer-payload-modal__input" />
        </label>
        <label v-if="'status' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.status') }}</span>
          <input v-model="form.status" class="composer-payload-modal__input" />
        </label>
        <label v-if="'time' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.time') }}</span>
          <input v-model="form.time" class="composer-payload-modal__input" />
        </label>
        <label v-if="'location' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.place') }}</span>
          <input v-model="form.location" class="composer-payload-modal__input" />
        </label>
        <label v-if="'summary' in form" class="composer-payload-modal__field">
          <span>{{ t('enhance.summary') }}</span>
          <textarea
            :value="fieldText('summary')"
            class="composer-payload-modal__textarea"
            @input="setTextField('summary', $event)"
          />
        </label>
      </template>
    </div>
    <template #footer>
      <div class="composer-payload-modal__footer">
        <n-button :disabled="loading" @click="emit('update:show', false)">{{ t('common.cancel') }}</n-button>
        <n-button type="primary" :loading="loading" @click="submit">{{ t('enhance.send') }}</n-button>
      </div>
    </template>
  </n-modal>
</template>
