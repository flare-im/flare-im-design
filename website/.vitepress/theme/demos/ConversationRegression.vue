<script setup>
import { FlareConversationList, FlareUiProvider } from "@flare-im/vue-ui/components";
import { conversationFixture } from "./conversation-fixture";
const query = new URLSearchParams(typeof location === "undefined" ? "" : location.search);
const width = Number(query.get("width")) || 320;
const theme = query.get("theme") === "dark" ? "dark" : "light";
const brand = query.get("brand") || "violet";
</script>
<template>
  <FlareUiProvider :theme-mode="theme" :brand-theme="brand" layout-mode="pc">
    <div class="conversation-regression" :style="{ width: width + 'px' }">
      <FlareConversationList :items="conversationFixture" active-id="li" />
    </div>
  </FlareUiProvider>
</template>
