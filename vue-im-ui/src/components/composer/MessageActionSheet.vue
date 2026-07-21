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
} from "../../shared/icon-glyphs";
import { NIcon } from "naive-ui";

const actions = [
  { op: "create_file", label: "File", hint: "File", icon: FolderOpenOutline },
  { op: "create_video", label: "Video", hint: "Video", icon: VideocamOutline },
  { op: "create_location", label: "Location", hint: "Location", icon: LocationOutline },
  { op: "create_card", label: "Contact", hint: "Card", icon: DocumentTextOutline },
  { op: "create_schedule", label: "Schedule", hint: "Schedule", icon: CalendarOutline },
  { op: "create_task", label: "Task", hint: "Task", icon: CheckboxOutline },
  { op: "create_link_card", label: "Link", hint: "Link", icon: LinkOutline },
  { op: "create_mini_program", label: "Mini Program", hint: "Mini", icon: LinkOutline },
  { op: "create_vote", label: "Poll", hint: "Vote", icon: CheckboxOutline },
  { op: "create_thread_reply", label: "Thread", hint: "Thread", icon: TextOutline },
  { op: "create_notification", label: "Notification", hint: "Notice", icon: TextOutline },
  { op: "create_announcement", label: "Announcement", hint: "Announce", icon: TextOutline },
  { op: "create_text", label: "Translate as you type", hint: "Translate", icon: LanguageOutline },
] as const;

const emit = defineEmits<{
  (event: "build", op: string): void;
}>();
</script>

<template>
  <div class="message-action-sheet" aria-label="Message features">
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
