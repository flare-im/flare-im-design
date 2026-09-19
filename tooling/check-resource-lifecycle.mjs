#!/usr/bin/env node
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const requirements = {
  "packages/vue-im-ui/src/components/conversation/FlareConversationList.vue": ["disconnect()"],
  "packages/flutter-im-ui/lib/src/components/flare_composer.dart": ["removeListener", "dispose()"],
  "packages/flutter-im-ui/lib/src/components/flare_inline_voice.dart": ["cancel()", "dispose()"],
  "packages/ios-im-ui/Sources/FlareIMUI/Components/InlineVoiceComposerView.swift": ["onDisappear", "invalidate()", "cancel()"],
};

const errors = [];
for (const [path, needles] of Object.entries(requirements)) {
  const source = readFileSync(join(root, path), "utf8");
  for (const needle of needles) if (!source.includes(needle)) errors.push(`${path}: missing lifecycle cleanup ${needle}`);
}
if (errors.length) {
  console.error("resource lifecycle errors:");
  errors.forEach((error) => console.error(`  ${error}`));
  process.exit(1);
}
console.log(`resource lifecycle passed: ${Object.keys(requirements).length} long-lived observer/controller/voice owners expose cleanup`);
