#!/usr/bin/env node
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const platform = JSON.parse(readFileSync(join(root, "spec/im-application-platform.json"), "utf8"));
const components = JSON.parse(readFileSync(join(root, "spec/components.json"), "utf8"));
const layers = JSON.parse(readFileSync(join(root, "spec/component-layers.json"), "utf8"));
const errors = [];

const expectedLayers = [
  "Foundation",
  "General UI",
  "IM UI",
  "Patterns",
  "Workspaces",
  "AppKit",
  "Host Application",
];
const expectedLayerKeys = [
  "foundation",
  "general-ui",
  "im-ui",
  "patterns",
  "workspaces",
  "appkit",
  "host-application",
];
// Every non-conversation scene (contacts, groups, search, media, calls, settings,
// saved messages) is a host composition of the one WorkspaceFrame.
const requiredWorkspaces = ["ConversationWorkspace", "WorkspaceFrame"];
const requiredApplicationComponents = [
  "AppLayout",
  "AdaptiveNavigation",
  "MobileAppShell",
  "DesktopAppShell",
  "ConversationListContainer",
  "FriendListContainer",
  ...requiredWorkspaces,
  "IMAppKit",
];

if (JSON.stringify(platform.layers) !== JSON.stringify(expectedLayers)) {
  errors.push(`application layers must be ${expectedLayers.join(" -> ")}`);
}
if (JSON.stringify(layers.dependencyDirection) !== JSON.stringify(expectedLayerKeys)) {
  errors.push(`component dependency direction must be ${expectedLayerKeys.join(" -> ")}`);
}
for (const workspace of requiredWorkspaces) {
  if (!platform.workspaces.includes(workspace)) errors.push(`application contract missing workspace ${workspace}`);
}
for (const name of requiredApplicationComponents) {
  const component = components.components.find((item) => item.name === name);
  if (!component) {
    errors.push(`component catalog missing ${name}`);
    continue;
  }
  if (component.status === "planned") errors.push(`${name} remains planned`);
  for (const target of ["vue", "flutter", "compose", "ios"]) {
    if (!component.platforms?.[target]?.symbol) errors.push(`${name} missing ${target} public symbol`);
  }
}

for (const capability of platform.capabilities) {
  if (!["P0", "P1"].includes(capability.priority)) continue;
  for (const target of ["vue", "flutter", "compose", "swiftUI"]) {
    if (capability[target] !== "complete") {
      errors.push(`${capability.priority} ${capability.capability} is ${capability[target]} on ${target}`);
    }
  }
}

const sources = {
  vue: [
    "packages/vue-im-ui/src/shared/contracts/application.ts",
    "packages/vue-im-ui/src/components/index.ts",
    "packages/vue-im-ui/src/shared/message-renderers.ts",
  ],
  flutter: [
    "packages/flutter-im-ui/lib/src/application/application_composition.dart",
    "packages/flutter-im-ui/lib/src/components/flare_message_content_view.dart",
  ],
  compose: [
    "packages/android-im-ui/src/main/kotlin/com/flare/im/ui/ApplicationComposition.kt",
    "packages/android-im-ui/src/main/kotlin/com/flare/im/ui/MessageContentView.kt",
  ],
  swiftUI: [
    "packages/ios-im-ui/Sources/FlareIMUI/Application/ApplicationComposition.swift",
    "packages/ios-im-ui/Sources/FlareIMUI/Components/MessageContentView.swift",
  ],
};
const requiredSymbols = {
  vue: ["FlareIMHostAdapter", "FlareNavigationIntent", "resolveMessageActionExtensions", "provideFlareMessageRenderers"],
  flutter: ["FlareIMHostAdapter", "FlareNavigationIntent", "resolveFlareMessageActionExtensions", "FlareContentRegistry"],
  compose: ["FlareIMHostAdapter", "FlareNavigationIntent", "resolveMessageActionExtensions", "FlareContentRegistry"],
  swiftUI: ["FlareIMHostAdapter", "FlareNavigationIntent", "resolveMessageActionExtensions", "FlareContentRegistry"],
};
const forbidden = /@flare-im\/sdk|flare_im_sdk|com\.flare\.im\.sdk|import FlareIMCore|vue-router|androidx\.navigation|NavigationStack\s*\{|Navigator\.(?:of|push)/;

for (const [target, paths] of Object.entries(sources)) {
  let joined = "";
  for (const relative of paths) {
    const absolute = join(root, relative);
    if (!existsSync(absolute)) {
      errors.push(`${target} application source missing: ${relative}`);
      continue;
    }
    const source = readFileSync(absolute, "utf8");
    joined += `\n${source}`;
    if (forbidden.test(source)) errors.push(`${target} application layer binds an SDK or router in ${relative}`);
  }
  for (const symbol of requiredSymbols[target]) {
    if (!joined.includes(symbol)) errors.push(`${target} application extension contract missing ${symbol}`);
  }
}

if (errors.length) {
  console.error("IM application platform violations:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}

const p0p1 = platform.capabilities.filter((item) => ["P0", "P1"].includes(item.priority));
console.log(`IM application platform passed: ${expectedLayers.length} layers, ${requiredApplicationComponents.length} application components, ${requiredWorkspaces.length} workspaces, ${p0p1.length} P0/P1 capabilities complete on four platforms`);
