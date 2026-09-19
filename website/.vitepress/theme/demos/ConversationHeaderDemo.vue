<script setup lang="ts">
import { ref } from "vue";
import {
  FlareConversationHeader,
  type FlareConversationHeaderAction,
} from "@flare-im/vue-ui";
import DemoStage from "./DemoStage.vue";

const lastAction = ref("Select a header action");
const identity = {
  id: "product-room",
  title: "Product room",
  kind: "group" as const,
  memberCount: 18,
  accessibilityLabel: "Product room conversation",
};
const capabilities = {
  availableActionIds: ["search", "addMember", "share", "details", "task", "order"],
};
const actions: FlareConversationHeaderAction[] = [
  { id: "task", label: "Create task", icon: "check", placement: "add", group: "work", order: 60 },
  { id: "order", label: "Create order", icon: "file", placement: "add", group: "work", order: 70, enabled: false, disabledReason: "Read only" },
];

function handleAction(action: FlareConversationHeaderAction) {
  lastAction.value = action.label;
}
</script>

<template>
  <DemoStage>
    <div class="header-demo">
      <FlareConversationHeader
        :identity="identity"
        :capabilities="capabilities"
        :actions="actions"
        @action="handleAction"
      />
      <p role="status">{{ lastAction }}</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.header-demo {
  width: 100%;
  overflow: hidden;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-primary);
}

p {
  min-height: 20px;
  margin: 0;
  padding: 8px 16px;
  color: var(--flare-color-text-tertiary);
  font-size: var(--flare-size-font-size-sm);
}
</style>
