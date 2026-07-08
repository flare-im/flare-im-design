<script setup lang="ts">
import { computed, reactive, watch } from "vue";
import { NButton, NModal, NTag } from "naive-ui";
import { resolveComposerAction } from "../messageTypeRegistry";
import type { ComposerPayloadRequest } from "../types";

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
const title = computed(() => action.value?.label ?? "消息");

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
    :title="`发送${title}`"
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
          <span>标题</span>
          <input v-model="form.title" class="composer-payload-modal__input" />
        </label>
        <label class="composer-payload-modal__field">
          <span>富文本 Markdown</span>
          <textarea
            :value="fieldText('markdown')"
            class="composer-payload-modal__textarea composer-payload-modal__textarea--rich"
            @input="setTextField('markdown', $event)"
          />
        </label>
      </template>

      <template v-else-if="action.kind === 'vote'">
        <label class="composer-payload-modal__field">
          <span>投票标题</span>
          <input v-model="form.title" class="composer-payload-modal__input" />
        </label>
        <label class="composer-payload-modal__field">
          <span>选项（每行一个）</span>
          <textarea :value="optionsText()" class="composer-payload-modal__textarea" @input="setOptionsFromEvent" />
        </label>
        <div class="composer-payload-modal__switches">
          <label><input v-model="form.multiple" type="checkbox" /> 多选</label>
          <label><input v-model="form.anonymous" type="checkbox" /> 匿名</label>
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
          <span>名片类型</span>
          <input v-model="form.cardType" class="composer-payload-modal__input" />
        </label>
        <label v-if="'pagePath' in form" class="composer-payload-modal__field">
          <span>路径</span>
          <input v-model="form.pagePath" class="composer-payload-modal__input" />
        </label>
        <label v-if="'title' in form" class="composer-payload-modal__field">
          <span>标题/名称</span>
          <input v-model="form.title" class="composer-payload-modal__input" />
        </label>
        <label v-if="'subtitle' in form" class="composer-payload-modal__field">
          <span>副标题</span>
          <input v-model="form.subtitle" class="composer-payload-modal__input" />
        </label>
        <label v-if="'avatar' in form" class="composer-payload-modal__field">
          <span>头像</span>
          <input v-model="form.avatar" class="composer-payload-modal__input" />
        </label>
        <label v-if="'appName' in form" class="composer-payload-modal__field">
          <span>应用名称</span>
          <input v-model="form.appName" class="composer-payload-modal__input" />
        </label>
        <label v-if="'description' in form" class="composer-payload-modal__field">
          <span>描述</span>
          <textarea
            :value="fieldText('description')"
            class="composer-payload-modal__textarea"
            @input="setTextField('description', $event)"
          />
        </label>
        <label v-if="'text' in form" class="composer-payload-modal__field">
          <span>内容</span>
          <textarea
            :value="fieldText('text')"
            class="composer-payload-modal__textarea"
            @input="setTextField('text', $event)"
          />
        </label>
        <label v-if="'address' in form" class="composer-payload-modal__field">
          <span>地址</span>
          <input v-model="form.address" class="composer-payload-modal__input" />
        </label>
        <label v-if="'url' in form" class="composer-payload-modal__field">
          <span>链接</span>
          <input v-model="form.url" class="composer-payload-modal__input" />
        </label>
        <label v-if="'thumbnailUrl' in form" class="composer-payload-modal__field">
          <span>缩略图</span>
          <input v-model="form.thumbnailUrl" class="composer-payload-modal__input" />
        </label>
        <label v-if="'mimeType' in form" class="composer-payload-modal__field">
          <span>MIME Type</span>
          <input v-model="form.mimeType" class="composer-payload-modal__input" />
        </label>
        <label v-if="'fileName' in form" class="composer-payload-modal__field">
          <span>文件名</span>
          <input v-model="form.fileName" class="composer-payload-modal__input" />
        </label>
        <label v-if="'latitude' in form" class="composer-payload-modal__field">
          <span>纬度</span>
          <input v-model="form.latitude" class="composer-payload-modal__input" />
        </label>
        <label v-if="'longitude' in form" class="composer-payload-modal__field">
          <span>经度</span>
          <input v-model="form.longitude" class="composer-payload-modal__input" />
        </label>
        <label v-if="'assignee' in form" class="composer-payload-modal__field">
          <span>负责人</span>
          <input v-model="form.assignee" class="composer-payload-modal__input" />
        </label>
        <label v-if="'dueTime' in form" class="composer-payload-modal__field">
          <span>截止时间</span>
          <input v-model="form.dueTime" class="composer-payload-modal__input" />
        </label>
        <label v-if="'deadline' in form" class="composer-payload-modal__field">
          <span>截止时间</span>
          <input v-model="form.deadline" class="composer-payload-modal__input" />
        </label>
        <label v-if="'status' in form" class="composer-payload-modal__field">
          <span>状态</span>
          <input v-model="form.status" class="composer-payload-modal__input" />
        </label>
        <label v-if="'time' in form" class="composer-payload-modal__field">
          <span>时间</span>
          <input v-model="form.time" class="composer-payload-modal__input" />
        </label>
        <label v-if="'location' in form" class="composer-payload-modal__field">
          <span>地点</span>
          <input v-model="form.location" class="composer-payload-modal__input" />
        </label>
        <label v-if="'summary' in form" class="composer-payload-modal__field">
          <span>摘要</span>
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
        <n-button :disabled="loading" @click="emit('update:show', false)">取消</n-button>
        <n-button type="primary" :loading="loading" @click="submit">发送</n-button>
      </div>
    </template>
  </n-modal>
</template>
