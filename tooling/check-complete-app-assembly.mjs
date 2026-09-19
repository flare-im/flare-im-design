#!/usr/bin/env node
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const read = (path) => readFileSync(join(root, path), "utf8");
const errors = [];
const vue = read("examples/vue/src/App.vue");
const flutter = read("examples/flutter/lib/reference_app.dart");
const recipes = read("website/en/recipes/index.md");
const appKit = read("website/en/app-kit/index.md");
const capabilities = read("website/en/capabilities/index.md");
const appTests = read("website/tests/complete-app.spec.ts");
const previewTests = read("website/tests/image-preview-mobile.spec.ts");
const scenarios = JSON.parse(read("spec/scenarios/application.json"));

if (/packages\/vue-im-ui\/src|@flare-im\/vue-ui\/src|\.\.\/\.\.\/packages/.test(vue)) {
  errors.push("Vue reference app imports internal package source");
}
if (/packages\/flutter-im-ui\/lib\/src|package:flare_im_ui\/src|\.\.\/\.\.\/packages/.test(flutter)) {
  errors.push("Flutter reference app imports internal package source");
}
for (const symbol of [
  "FlareIMAppKit",
  "FlareConversationListContainer",
  "FlareFriendListContainer",
  "FlareConversationList",
  "FlareContactList",
  "FlareMessageList",
  "FlareComposerSendButton",
]) if (!vue.includes(symbol)) errors.push(`Vue reference app does not assemble ${symbol}`);
for (const symbol of [
  "FlareIMAppKit",
  "FlareConversationListContainer",
  "FlareFriendListContainer",
  "FlareConversationList",
  "FlareContactList",
  "FlareMessageBubble",
  "FlareTextContent",
  "FlareComposer",
]) if (!flutter.includes(symbol)) errors.push(`Flutter reference app does not assemble ${symbol}`);

const requiredRecipes = [
  "Build a Complete Mobile IM App",
  "Build a Complete Desktop IM App",
  "Build Conversation List",
  "Build Contacts",
  "Build Group Chat",
  "Build Message Timeline",
  "Build Composer",
  "Build Search",
  "Build File / Media Browser",
  "Build Image Preview",
  "Build Calls UI",
  "Build Offline Retry",
  "Build Read Receipts",
  "Build Message Actions",
  "Build Dark Theme IM",
];
for (const title of requiredRecipes) if (!recipes.includes(`## ${title}`)) errors.push(`recipe missing: ${title}`);

for (const step of ["Install", "Theme", "Host Adapter", "Navigation", "Conversation", "Contacts", "Run"]) {
  if (!appKit.includes(step)) errors.push(`Build an IM App missing step: ${step}`);
}
for (const capability of ["Conversation", "Message", "Reply", "Reaction", "Thread", "Forward", "Search", "Contacts", "Groups", "Media", "Calls"]) {
  if (!capabilities.toLowerCase().includes(capability.toLowerCase())) errors.push(`website capability matrix missing ${capability}`);
}

if (scenarios.scenarios.length !== 6) errors.push(`expected scenarios A-F, found ${scenarios.scenarios.length}`);
for (const label of ["Desktop Group Chat App", "Contacts + Chat App", "Search + Chat App"]) {
  if (!scenarios.scenarios.some((scenario) => scenario.label === label)) errors.push(`shared scenario missing ${label}`);
}
for (const interaction of ["openConversation", "sendMessage", "retryFailed", "reply", "react", "search", "jumpToSearchResult", "openContact", "openGroup", "openMedia", "previewImage", "closePreview", "openSettings"]) {
  if (!scenarios.interactionFlow.includes(interaction)) errors.push(`interaction scenario missing ${interaction}`);
}
for (const evidence of ["Chats", "Contacts", "Search", "Settings", "Type a message", "Public AppKit works"]) {
  if (!appTests.includes(evidence)) errors.push(`complete app interaction test missing ${evidence}`);
}
for (const viewport of ["375, height: 667", "390, height: 844", "430, height: 932"]) {
  if (!previewTests.includes(viewport)) errors.push(`H5 image preview evidence missing viewport ${viewport}`);
}
for (const assertion of ["naturalWidth", "naturalHeight", "opacity", "toBeFocused"]) {
  if (!previewTests.includes(assertion)) errors.push(`H5 image preview evidence missing ${assertion}`);
}

if (errors.length) {
  console.error("complete app assembly violations:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
console.log(`complete app assembly passed: 2 public-API reference apps, ${requiredRecipes.length} recipes, 6 shared scenarios, desktop/mobile interactions, and 3 H5 image-preview viewports`);
