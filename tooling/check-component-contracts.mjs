#!/usr/bin/env node
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const spec = JSON.parse(readFileSync(new URL("../spec/components.json", import.meta.url), "utf8"));
const required = [
  "Button", "IconButton", "Input", "Search", "Textarea", "Select", "Checkbox",
  "Radio", "Switch", "Tabs", "Tag", "Avatar", "Tooltip", "Popover", "Menu",
  "Dialog", "Drawer", "Toast", "Progress", "Skeleton", "List", "ListItem",
  "ConversationItem", "MessageBubble", "MessageList", "Composer", "ReplyPreview",
  "Reaction", "Thread", "UnreadMarker", "TypingIndicator", "ReadReceipt", "Presence",
  "CommandPalette",
];
const fields = [
  "visual", "behavior", "state", "accessibility", "props", "events", "content",
  "responsiveNotes", "platformDifferences", "implementationStatus",
];
const errors = [];
for (const name of required) {
  const contract = spec.componentContracts?.[name];
  if (!contract) {
    errors.push(`${name}: missing contract`);
    continue;
  }
  for (const field of fields) if (!(field in contract)) errors.push(`${name}: missing ${field}`);
  for (const platform of ["vue", "flutter", "compose", "ios"]) {
    if (!contract.platformDifferences?.[platform]) errors.push(`${name}: missing ${platform} difference policy`);
  }
  if (contract.implementationStatus !== "planned" && !contract.component) {
    errors.push(`${name}: stable/alias contract has no public component target`);
  }
}
// Shared geometry. The same control has to be drawn with the same radius token on
// all four platforms, and nothing else checks it: the pixel baselines compare whole
// surfaces at maxDiffPixelRatio 0.002, so a 2px corner on one button is far below
// the threshold — the Vue button sat at radius-md while the other three were at
// radiusLg, invisible to every gate. The token NAME is what is compared, so a
// change to the scale moves all four together.
const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const GEOMETRY = [
  {
    what: "Button box radius",
    sites: {
      vue: ["packages/vue-im-ui/src/components/general/FlareButton.vue", ".flare-button {", /border-radius:\s*var\(--flare-size-radius-(\w+)\)/],
      flutter: ["packages/flutter-im-ui/lib/src/components/flare_button.dart", "class FlareButton", /BorderRadius\.circular\(FlareSizes\.radius(\w+)\)/],
      compose: ["packages/android-im-ui/src/main/kotlin/com/flare/im/ui/FormComponents.kt", "fun Button(", /RoundedCornerShape\(FlareSizes\.radius(\w+)\)/],
      ios: ["packages/ios-im-ui/Sources/FlareIMUI/Components/FormViews.swift", "public struct ButtonView", /cornerRadius:\s*FlareSizes\.radius(\w+)/],
    },
  },
  {
    what: "Input field radius",
    sites: {
      vue: ["packages/vue-im-ui/src/components/general/FlareInput.vue", ".flare-input__field {", /border-radius:\s*var\(--flare-size-radius-(\w+)\)/],
      flutter: ["packages/flutter-im-ui/lib/src/components/flare_input.dart", "class _FlareInputState", /BorderRadius\.circular\(FlareSizes\.radius(\w+)\)/],
      compose: ["packages/android-im-ui/src/main/kotlin/com/flare/im/ui/Input.kt", "fun Input(", /RoundedCornerShape\(FlareSizes\.radius(\w+)\)/],
      ios: ["packages/ios-im-ui/Sources/FlareIMUI/Components/GeneralViews.swift", "public struct InputView", /cornerRadius:\s*FlareSizes\.radius(\w+)/],
    },
  },
];
let geometryChecks = 0;
for (const { what, sites } of GEOMETRY) {
  const found = {};
  for (const [platform, [file, anchorText, pattern]] of Object.entries(sites)) {
    const source = readFileSync(join(root, file), "utf8");
    const start = source.indexOf(anchorText);
    if (start < 0) { errors.push(`${what}: ${platform} anchor ${JSON.stringify(anchorText)} not found in ${file}`); continue; }
    const match = pattern.exec(source.slice(start));
    if (!match) { errors.push(`${what}: ${platform} declares no radius token after ${JSON.stringify(anchorText)} (${file})`); continue; }
    found[platform] = match[1].toLowerCase();
  }
  const values = new Set(Object.values(found));
  if (values.size > 1) {
    errors.push(`${what}: four platforms disagree — ${Object.entries(found).map(([k, v]) => `${k}=${v}`).join(", ")}`);
  } else if (values.size === 1) {
    geometryChecks += 1;
  }
}

if (errors.length) {
  console.error("component contract errors:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
const planned = required.filter((name) => spec.componentContracts[name].implementationStatus === "planned");
console.log(`component contracts passed: ${required.length} complete; ${planned.length} planned (${planned.join(", ")}); ${geometryChecks} shared geometry token(s) equal on four platforms`);
