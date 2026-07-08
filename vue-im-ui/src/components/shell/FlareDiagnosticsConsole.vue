<script setup lang="ts">
import { NButton, NDivider, NInput, NInputNumber, NSelect } from "naive-ui";

defineProps<{
  diagnosticsText: string;
  labResultText: string;
  labBusy?: boolean;
  buildOptions: Array<{ label: string; value: string }>;
  dispatchOptions: Array<{ label: string; value: string }>;
  sdkLab: {
    buildOp: string;
    dispatchOp: string;
    messageText: string;
    messageId: string;
    query: string;
    peerUserId: string;
    userIds: string;
    fileId: string;
    reaction?: string;
    capability: string;
    capabilityTargetUserId?: string;
    mediaUrl?: string;
    mediaCacheRoot?: string;
    mediaCacheMaxBytes?: number;
    downloadSubfolder?: string;
    draft?: string;
    jsonParams: string;
  };
  events: readonly {
    id: number;
    label: string;
    detail: string;
  }[];
}>();

const emit = defineEmits<{
  (event: "session"): void;
  (event: "events"): void;
  (event: "open-peer"): void;
  (event: "build-send"): void;
  (event: "dispatch"): void;
  (event: "conversation", kind: string): void;
  (event: "sync", kind: string): void;
  (event: "presence", kind: string): void;
  (event: "media", kind: string): void;
  (event: "capability", kind: string): void;
}>();
</script>

<template>
  <section class="sdk-lab">
    <div class="pane-title">Developer diagnostics</div>
    <div class="lab-grid">
      <n-button size="small" secondary :loading="labBusy" @click="emit('session')">Session</n-button>
      <n-button size="small" secondary @click="emit('events')">Events</n-button>
      <n-button size="small" secondary @click="emit('open-peer')">Open Peer</n-button>
      <n-button size="small" secondary @click="emit('sync', 'conversation')">Sync Conv</n-button>
    </div>

    <div class="lab-field">
      <span>Message Build</span>
      <n-select v-model:value="sdkLab.buildOp" size="small" :options="buildOptions" />
      <n-input v-model:value="sdkLab.messageText" size="small" placeholder="Message / title text" />
      <n-input v-model:value="sdkLab.jsonParams" size="small" placeholder="JSON payload" />
      <n-button size="small" type="primary" block @click="emit('build-send')">Build + Send</n-button>
    </div>

    <div class="lab-field">
      <span>Message Dispatch</span>
      <n-select v-model:value="sdkLab.dispatchOp" size="small" :options="dispatchOptions" />
      <n-input v-model:value="sdkLab.messageId" size="small" placeholder="message id, defaults to latest" />
      <n-input v-model:value="sdkLab.query" size="small" placeholder="Search keyword" />
      <n-input v-model:value="sdkLab.reaction" size="small" placeholder="reaction / mark color" />
      <n-input v-model:value="sdkLab.jsonParams" size="small" placeholder="JSON payload" />
      <n-button size="small" secondary block @click="emit('dispatch')">Dispatch</n-button>
    </div>

    <div class="lab-field">
      <span>Conversation</span>
      <n-input v-model:value="sdkLab.draft" size="small" placeholder="draft text" />
      <div class="lab-grid">
        <n-button size="small" secondary @click="emit('conversation', 'mark_unread')">Unread</n-button>
        <n-button size="small" secondary @click="emit('conversation', 'pin')">Pin</n-button>
        <n-button size="small" secondary @click="emit('conversation', 'unpin')">Unpin</n-button>
        <n-button size="small" secondary @click="emit('conversation', 'mute')">Mute</n-button>
        <n-button size="small" secondary @click="emit('conversation', 'unmute')">Unmute</n-button>
        <n-button size="small" secondary @click="emit('conversation', 'archive')">Archive</n-button>
        <n-button size="small" secondary @click="emit('conversation', 'unarchive')">Unarchive</n-button>
        <n-button size="small" secondary @click="emit('conversation', 'draft')">Save Draft</n-button>
        <n-button size="small" secondary @click="emit('conversation', 'clear_history')">Clear History</n-button>
        <n-button size="small" secondary @click="emit('conversation', 'list')">List</n-button>
      </div>
    </div>

    <div class="lab-grid">
      <n-button size="small" secondary @click="emit('sync', 'messages')">Sync Msg</n-button>
      <n-button size="small" secondary @click="emit('sync', 'read')">Mark Read</n-button>
      <n-button size="small" secondary @click="emit('presence', 'get')">Presence One</n-button>
      <n-button size="small" secondary @click="emit('presence', 'batch')">Presence</n-button>
      <n-button size="small" secondary @click="emit('presence', 'subscribe')">Sub Presence</n-button>
      <n-button size="small" secondary @click="emit('media', 'stats')">Media Stats</n-button>
      <n-button size="small" secondary @click="emit('media', 'url')">Media URL</n-button>
      <n-button size="small" secondary @click="emit('media', 'temp_url')">Temp URL</n-button>
      <n-button size="small" secondary @click="emit('media', 'resolve')">Resolve</n-button>
      <n-button size="small" secondary @click="emit('media', 'display_url')">Display URL</n-button>
      <n-button size="small" secondary @click="emit('media', 'cache_remote')">Cache</n-button>
      <n-button size="small" secondary @click="emit('media', 'clear')">Clear Media</n-button>
      <n-button size="small" secondary @click="emit('capability', 'list')">Caps</n-button>
      <n-button size="small" secondary @click="emit('capability', 'list_user')">User Caps</n-button>
      <n-button size="small" secondary @click="emit('capability', 'dispatch')">Cap Dispatch</n-button>
      <n-button size="small" secondary @click="emit('capability', 'grant')">Grant</n-button>
      <n-button size="small" secondary @click="emit('capability', 'revoke')">Revoke</n-button>
      <n-button size="small" secondary @click="emit('capability', 'call_signal')">Call Signal</n-button>
    </div>

    <div class="lab-field">
      <span>Media / Capability inputs</span>
      <n-input v-model:value="sdkLab.fileId" size="small" placeholder="file id / object key" />
      <n-input v-model:value="sdkLab.mediaUrl" size="small" placeholder="remote media url" />
      <n-input v-model:value="sdkLab.mediaCacheRoot" size="small" placeholder="cache root" />
      <n-input-number v-model:value="sdkLab.mediaCacheMaxBytes" size="small" :min="1048576" :step="1048576" />
      <n-input v-model:value="sdkLab.downloadSubfolder" size="small" placeholder="download subfolder" />
      <n-input v-model:value="sdkLab.capabilityTargetUserId" size="small" placeholder="capability target user id" />
      <div class="lab-grid">
        <n-button size="small" secondary @click="emit('media', 'set_root')">Set Root</n-button>
        <n-button size="small" secondary @click="emit('media', 'set_max')">Set Max</n-button>
        <n-button size="small" secondary @click="emit('media', 'download_subfolder')">Download Folder</n-button>
        <n-button size="small" secondary @click="emit('media', 'saved_path')">Saved Path</n-button>
        <n-button size="small" secondary @click="emit('media', 'delete_download')">Delete Record</n-button>
      </div>
    </div>

    <pre>{{ labResultText }}</pre>

    <n-divider />

    <section>
      <div class="pane-title">Diagnostics</div>
      <pre>{{ diagnosticsText }}</pre>
    </section>

    <n-divider />

    <section>
      <div class="pane-title">Events</div>
      <div class="event-list">
        <div v-for="event in events" :key="event.id" class="event-item">
          <strong>{{ event.label }}</strong>
          <span>{{ event.detail }}</span>
        </div>
      </div>
    </section>
  </section>
</template>
