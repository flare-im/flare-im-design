#!/usr/bin/env node
import { existsSync, lstatSync, readFileSync, readdirSync } from "node:fs";
import { dirname, extname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const expectedThemes = ["violet", "ocean", "forest", "sunset", "rose", "graphite"];
const source = JSON.parse(readFileSync(join(root, "tokens/themes.json"), "utf8"));
const scenario = JSON.parse(readFileSync(join(root, "spec/scenarios/theme-switching.json"), "utf8"));
const errors = [];

function deepMerge(base, override) {
  if (!base || typeof base !== "object" || Array.isArray(base)) return override ?? base;
  const result = { ...base };
  for (const [key, value] of Object.entries(override ?? {})) {
    result[key] = value && typeof value === "object" && !Array.isArray(value)
      ? deepMerge(base[key] ?? {}, value)
      : value;
  }
  return result;
}

function get(object, path) {
  return path.split(".").reduce((value, key) => value?.[key], object);
}

function expectExact(label, actual, expected) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    errors.push(`${label}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

expectExact("theme names", Object.keys(source.themes), expectedThemes);
expectExact("scenario themes", scenario.themes, expectedThemes);
expectExact("scenario modes", scenario.modes, ["light", "dark"]);
expectExact("scenario platforms", scenario.platforms, ["vue", "flutter", "compose", "ios"]);

const requiredComponents = new Set([
  "ConversationList", "ConversationRow", "MessageBubble", "MessageStatus",
  "ReactionSummary", "Composer", "Button",
]);
const scenarioComponents = new Set(scenario.components.map(({ name }) => name));
for (const name of requiredComponents) {
  if (!scenarioComponents.has(name)) errors.push(`theme-switching scenario misses ${name}`);
}
for (const state of ["incoming", "outgoing", "failed"]) {
  if (!scenario.components.some((entry) => entry.name === "MessageBubble" && entry.state === state)) {
    errors.push(`theme-switching scenario misses MessageBubble.${state}`);
  }
}

for (const name of expectedThemes) {
  for (const mode of ["light", "dark"]) {
    const resolved = deepMerge(source.semanticDefaults[mode], source.themes[name]?.[mode]);
    for (const path of source.requiredSemanticPaths) {
      if (get(resolved, path) == null) errors.push(`${name}.${mode}: missing ${path}`);
    }
  }
}

const generated = {
  web: readFileSync(join(root, "tokens/theme.js"), "utf8"),
  css: readFileSync(join(root, "tokens/dist/tokens.css"), "utf8"),
  dart: readFileSync(join(root, "packages/flutter-im-ui/lib/src/tokens/flare_tokens.dart"), "utf8"),
  kotlin: readFileSync(join(root, "packages/android-im-ui/src/main/kotlin/com/flare/im/ui/FlareTokens.kt"), "utf8"),
  swift: readFileSync(join(root, "packages/ios-im-ui/Sources/FlareIMUI/Tokens/FlareTokens.swift"), "utf8"),
};

const customThemeFragments = {
  web: ["createFlareCustomTheme", "customRequiredPaths"],
  dart: ["FlareColors copyWith", "final FlareColors? colors"],
  kotlin: ["colors: FlareColors? = null", "colors ?: FlareColors.resolve"],
  swift: ["public init(name: String, light: FlareColors, dark: FlareColors)", "public func copy("],
};
for (const [target, fragments] of Object.entries(customThemeFragments)) {
  for (const fragment of fragments) {
    if (!generated[target].includes(fragment)) errors.push(`${target}: custom theme contract misses ${fragment}`);
  }
}
for (const name of expectedThemes) {
  const title = name[0].toUpperCase() + name.slice(1);
  for (const mode of ["light", "dark"]) {
    const cssSelector = mode === "dark"
      ? `[data-flare-brand="${name}"][data-flare-theme="dark"]`
      : `[data-flare-brand="${name}"]`;
    if (!generated.css.includes(cssSelector)) errors.push(`CSS mapping missing ${name}.${mode}`);
  }
  if (!generated.dart.includes(`${name}Light`)) {
    errors.push(`Dart mapping missing ${name}`);
  }
  if (!generated.kotlin.includes(`${title}Light`)) errors.push(`Kotlin mapping missing ${name}`);
  if (!generated.swift.includes(`${name}Light`)) errors.push(`Swift mapping missing ${name}`);
}

const requiredRuntimeFragments = {
  "Vue outgoing message": ["packages/vue-im-ui/src", "--flare-color-message-outgoing-background"],
  "Vue read status": ["packages/vue-im-ui/src", "--flare-color-message-status-read-on-outgoing"],
  "Flutter outgoing message": ["packages/flutter-im-ui/lib/src", "messageOutgoingBackground"],
  "Flutter read status": ["packages/flutter-im-ui/lib/src", "messageStatusReadOnOutgoing"],
  "Compose outgoing message": ["packages/android-im-ui/src/main", "messageOutgoingBackground"],
  "Compose read status": ["packages/android-im-ui/src/main", "messageStatusReadOnOutgoing"],
  "SwiftUI outgoing message": ["packages/ios-im-ui/Sources", "messageOutgoingBackground"],
  "SwiftUI read status": ["packages/ios-im-ui/Sources", "messageStatusReadOnOutgoing"],
};

function sourceText(directory) {
  const files = [];
  function walk(path) {
    for (const entry of readdirSync(path)) {
      if (["node_modules", ".dart_tool", ".build", "build"].includes(entry)) continue;
      const absolute = join(path, entry);
      const stat = lstatSync(absolute);
      if (stat.isSymbolicLink()) continue;
      if (stat.isDirectory()) walk(absolute);
      else if ([".css", ".dart", ".kt", ".swift", ".ts", ".vue"].includes(extname(entry))) files.push(absolute);
    }
  }
  walk(join(root, directory));
  return files.map((file) => readFileSync(file, "utf8")).join("\n");
}

const sourceCache = new Map();
for (const [label, [directory, fragment]] of Object.entries(requiredRuntimeFragments)) {
  if (!sourceCache.has(directory)) sourceCache.set(directory, sourceText(directory));
  if (!sourceCache.get(directory).includes(fragment)) errors.push(`${label}: missing semantic token consumption`);
}

const themeSensitiveFiles = [
  "packages/vue-im-ui/src/components/conversation/FlareConversationRow.vue",
  "packages/vue-im-ui/src/components/composer/FlareComposerSendButton.vue",
  "packages/vue-im-ui/src/components/messages/FlareReactionSummary.vue",
  "packages/vue-im-ui/src/components/call/FlareCallDock.vue",
  "packages/vue-im-ui/src/components/messages/MessageBubble.vue",
  "packages/vue-im-ui/src/components/messages/MessageStatus.vue",
  "packages/vue-im-ui/src/design-system/styles/chat/message-bubble.css",
  "packages/flutter-im-ui/lib/src/components/flare_conversation_row.dart",
  "packages/flutter-im-ui/lib/src/components/flare_composer.dart",
  "packages/flutter-im-ui/lib/src/components/flare_reaction_summary.dart",
  "packages/flutter-im-ui/lib/src/components/flare_call_dock.dart",
  "packages/flutter-im-ui/lib/src/components/flare_message_bubble.dart",
  "packages/android-im-ui/src/main/kotlin/com/flare/im/ui/ConversationRow.kt",
  "packages/android-im-ui/src/main/kotlin/com/flare/im/ui/Composer.kt",
  "packages/android-im-ui/src/main/kotlin/com/flare/im/ui/ReactionSummary.kt",
  "packages/android-im-ui/src/main/kotlin/com/flare/im/ui/CallDock.kt",
  "packages/android-im-ui/src/main/kotlin/com/flare/im/ui/MessageBubble.kt",
  "packages/ios-im-ui/Sources/FlareIMUI/Components/ConversationRowView.swift",
  "packages/ios-im-ui/Sources/FlareIMUI/Components/ComposerView.swift",
  "packages/ios-im-ui/Sources/FlareIMUI/Components/ReactionSummaryView.swift",
  "packages/ios-im-ui/Sources/FlareIMUI/Components/CallDockView.swift",
  "packages/ios-im-ui/Sources/FlareIMUI/Components/MessageBubbleView.swift",
];
const forbiddenBrandLiterals = /(?:violet|purple|brandPurple|#6D28D9|#7C3AED|#8B5CF6)/i;
for (const path of themeSensitiveFiles) {
  if (!existsSync(join(root, path))) {
    errors.push(`missing theme-sensitive source ${path}`);
  } else if (forbiddenBrandLiterals.test(readFileSync(join(root, path), "utf8"))) {
    errors.push(`${path}: fixed Violet/Purple brand literal leaks into a theme-sensitive component`);
  }
}

if (errors.length) {
  console.error("theme contract errors:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}

console.log("theme contract passed: 6 brands x 2 modes, shared scenario, four generated targets, semantic message consumers");
