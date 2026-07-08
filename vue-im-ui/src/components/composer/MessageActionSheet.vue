<script setup lang="ts">
import {
  CalendarOutline,
  CheckboxOutline,
  DocumentTextOutline,
  FolderOpenOutline,
  LanguageOutline,
  LinkOutline,
  LocationOutline,
  TextOutline,
  VideocamOutline,
} from "@vicons/ionicons5";
import { NIcon } from "naive-ui";

const actions = [
  { op: "create_file", label: "文件", hint: "File", icon: FolderOpenOutline },
  { op: "create_video", label: "视频", hint: "Video", icon: VideocamOutline },
  { op: "create_location", label: "位置", hint: "Location", icon: LocationOutline },
  { op: "create_card", label: "名片", hint: "Card", icon: DocumentTextOutline },
  { op: "create_schedule", label: "日程", hint: "Schedule", icon: CalendarOutline },
  { op: "create_task", label: "任务", hint: "Task", icon: CheckboxOutline },
  { op: "create_link_card", label: "链接", hint: "Link", icon: LinkOutline },
  { op: "create_mini_program", label: "小程序", hint: "Mini", icon: LinkOutline },
  { op: "create_vote", label: "投票", hint: "Vote", icon: CheckboxOutline },
  { op: "create_thread_reply", label: "话题", hint: "Thread", icon: TextOutline },
  { op: "create_notification", label: "通知", hint: "Notice", icon: TextOutline },
  { op: "create_announcement", label: "公告", hint: "Announce", icon: TextOutline },
  { op: "create_text", label: "边写边译", hint: "Translate", icon: LanguageOutline },
] as const;

const emit = defineEmits<{
  (event: "build", op: string): void;
}>();
</script>

<template>
  <div class="message-action-sheet" aria-label="消息能力">
    <button
      v-for="action in actions"
      :key="action.op"
      type="button"
      class="message-action"
      @click="emit('build', action.op)"
    >
      <span class="message-action__icon">
        <n-icon :component="action.icon" />
      </span>
      <span>{{ action.label }}</span>
      <small>{{ action.hint }}</small>
    </button>
  </div>
</template>
