#!/usr/bin/env node
import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => readFileSync(join(root, rel), "utf8");
const errors = [];
const requireText = (rel, values) => {
  const source = read(rel);
  for (const value of values) if (!source.includes(value)) errors.push(`${rel}: missing ${JSON.stringify(value)}`);
};

const spec = JSON.parse(read("spec/components.json"));
const required = spec.accessibilityContract?.requiredFields ?? [];
for (const component of spec.components) {
  if (!(component.events ?? []).length) continue;
  for (const field of required) if (component.accessibility?.[field] == null)
    errors.push(`spec: ${component.name}.${field} is missing`);
}

requireText("packages/vue-im-ui/src/components/general/FlareSearchBar.vue", [
  'type="search"', ':aria-label="strings.placeholder"', 'class="flare-search__clear"', ':aria-label="strings.clear"',
  ":focus-visible", "prefers-reduced-motion",
]);
requireText("packages/vue-im-ui/src/components/general/FlareButton.vue", [":focus-visible", "prefers-reduced-motion", ':aria-busy="loading"']);
requireText("packages/flutter-im-ui/lib/src/components/flare_button.dart", ["disableAnimations", "Duration.zero"]);
requireText("packages/flutter-im-ui/lib/src/components/flare_search_bar.dart", ["focusNode", "disableAnimations", "Semantics("]);
requireText("packages/flutter-im-ui/lib/src/components/flare_rich_markdown_input.dart", ["FlareRichMarkdownLabels", "widget.labels.bold"]);
requireText("packages/android-im-ui/src/main/kotlin/com/flare/im/ui/Controls.kt", ["role = Role.Tab", "onClickLabel = label", "selected = active"]);
requireText("packages/android-im-ui/src/main/kotlin/com/flare/im/ui/MessageStatus.kt", ["role = Role.Button", "onClickLabel = retry"]);
requireText("packages/android-im-ui/src/main/kotlin/com/flare/im/ui/RichMarkdownInput.kt", ["FlareRichMarkdownLabels", "Icon(icon, label)"]);
if (read("packages/android-im-ui/src/main/kotlin/com/flare/im/ui/FormControls.kt").includes("animateFloatAsState"))
  errors.push("Compose FormControls: custom slider motion must honor reduced motion or be immediate");
if (read("packages/android-im-ui/src/main/kotlin/com/flare/im/ui/SearchBar.kt").includes('"Clear"'))
  errors.push("Compose SearchBar: raw English accessibility label found");
// The icon contract, one rule four platforms: decorative unless the caller names
// it. Flutter has a runtime semantics test (test/icon_semantics_test.dart); the
// Compose and SwiftUI unit-test paths cannot mount a UI offline, so their half is
// asserted here on the source.
requireText("packages/android-im-ui/src/main/kotlin/com/flare/im/ui/IconLibrary.kt", [
  "contentDescription: String? = null", "contentDescription = contentDescription,",
]);
requireText("packages/ios-im-ui/Sources/FlareIMUI/Components/IconLibrary.swift", [
  "accessibilityLabel: String? = nil", ".accessibilityHidden(accessibilityLabel == nil)",
]);
requireText("packages/flutter-im-ui/lib/src/components/flare_icon.dart", ["this.semanticLabel", "semanticLabel: semanticLabel,"]);
requireText("packages/ios-im-ui/Sources/FlareIMUI/Components/FormViews.swift", ["accessibilityReduceMotion", "reduceMotion ? nil"]);
requireText("packages/ios-im-ui/Sources/FlareIMUI/Components/RichMarkdownInputView.swift", ["FlareRichMarkdownLabels", ".accessibilityLabel(label)"]);

// Every icon the kit renders is decorative unless it carries its own name: an
// `<n-icon>` is an `<i role="img">`, and an unnamed one is an axe `role-img-alt`
// violation (serious) on every screen that shows it. So each tag must declare
// `aria-hidden` (decorative — the common case, the control around it is named)
// or `aria-label` (the icon itself is the content).
function vueFiles(directory) {
  const out = [];
  for (const entry of readdirSync(directory)) {
    const path = join(directory, entry);
    if (statSync(path).isDirectory()) out.push(...vueFiles(path));
    else if (entry.endsWith(".vue")) out.push(path);
  }
  return out;
}

/**
 * Tag spans of the naive icon in both spellings (`<n-icon>` and `<NIcon>`),
 * skipping `>` inside quoted attribute values (`:component="a > b ? x : y"`).
 */
function iconTags(source) {
  const spans = [];
  for (const name of ["<n-icon", "<NIcon"]) {
    for (let index = source.indexOf(name); index >= 0; index = source.indexOf(name, index + 1)) {
      const next = source[index + name.length];
      if (/[A-Za-z0-9-]/.test(next ?? "")) continue;
      let cursor = index + name.length;
      let quote = null;
      for (; cursor < source.length; cursor += 1) {
        const char = source[cursor];
        if (quote) { if (char === quote) quote = null; continue; }
        if (char === '"' || char === "'") { quote = char; continue; }
        if (char === ">") break;
      }
      spans.push(source.slice(index, cursor + 1));
    }
  }
  return spans;
}

const vueRoot = join(root, "packages/vue-im-ui/src");
let iconTagCount = 0;
for (const file of vueFiles(vueRoot)) {
  for (const tag of iconTags(readFileSync(file, "utf8"))) {
    iconTagCount += 1;
    if (tag.includes("aria-hidden") || tag.includes("aria-label")) continue;
    errors.push(`${relative(root, file)}: naive icon without aria-hidden or aria-label (unnamed role="img"): ${tag.split("\n")[0].slice(0, 80)}`);
  }
}

// Inline UI text comes from the platform's strings provider, never from a literal
// in the widget: a literal cannot be translated by a host, and an English one in a
// Chinese UI is also an assistive-tech defect. These are the call sites that were
// still hardcoded on 2026-09-13 (the CJK side is ratcheted separately by
// tooling/check-hardcoded-strings.mjs, which only sees Chinese literals).
requireText("packages/flutter-im-ui/lib/src/components/flare_call_view.dart", [
  "strings.callReconnecting", "strings.callFailed", "strings.callConnected",
  "strings.callRinging", "strings.callWaitingAnswer", "strings.callCalling",
]);
requireText("packages/flutter-im-ui/lib/src/components/flare_call_dock.dart", ["strings.callConnected"]);
requireText("packages/flutter-im-ui/lib/src/components/flare_voice_recording_bar.dart", ["strings.releaseToCancel"]);
requireText("packages/flutter-im-ui/lib/src/components/flare_conversation_row.dart", [
  "strings.conversationRowDraft", "strings.conversationRowMention",
]);
requireText("packages/android-im-ui/src/main/kotlin/com/flare/im/ui/ConversationRow.kt", [
  "strings.conversationRowDraft", "strings.conversationRowMention",
]);
requireText("packages/vue-im-ui/src/components/form/FlareStepper.vue", ["t('stepper.decrease')", "t('stepper.increase')"]);
requireText("packages/vue-im-ui/src/components/form/FlareSlider.vue", ["t('slider.label')"]);
// The two native string tables are documented as mirrors of each other; a key
// added to one and forgotten on the other is how they drift apart.
{
  const dart = read("packages/flutter-im-ui/lib/src/tokens/flare_strings.dart");
  const kotlin = read("packages/android-im-ui/src/main/kotlin/com/flare/im/ui/FlareStrings.kt");
  for (const key of ["conversationRowDraft", "conversationRowMention"]) {
    // Match the declaration, not a mention: a renamed field still contains the old
    // name as a prefix, and `includes` would call that present.
    if (!dart.includes(`final String ${key};`)) errors.push(`Flutter FlareStrings: missing \`final String ${key};\``);
    if (!kotlin.includes(`val ${key}: String`)) errors.push(`Compose FlareStrings: missing \`val ${key}: String\` (it mirrors the Flutter table)`);
  }
}

// A focus outline is the whole affordance, so it has to clear WCAG 2.4.11's 3:1
// on its own. `--flare-color-focus-ring` is a 35-40% alpha GLOW (measured 1.47-2.97:1
// over the seven themes x light/dark) and `--flare-color-primary` fails every dark
// theme (1.80-2.66:1); only `--flare-color-border-selected` clears 3:1 in all
// fourteen combinations (min 3.30). So the glow token may only appear in a
// box-shadow next to a solid ring, never as the outline colour itself.
const FOCUS_OUTLINE_VARS = new Set(["--flare-color-border-selected", "--studio-focus"]);
// White, on the two surfaces that float over arbitrary media (photo viewer, call
// chrome), where a violet ring has no defined backdrop to contrast against.
const FOCUS_OUTLINE_ON_MEDIA = new Set([
  "packages/vue-im-ui/src/components/message-preview/ImagePreviewModal.vue",
  "packages/vue-im-ui/src/components/call/FlareCallControls.vue",
]);
function styleFiles(directory) {
  const out = [];
  for (const entry of readdirSync(directory)) {
    const path = join(directory, entry);
    if (statSync(path).isDirectory()) out.push(...styleFiles(path));
    else if (entry.endsWith(".vue") || entry.endsWith(".css")) out.push(path);
  }
  return out;
}
// 注释不是声明。这条规则扫的是 `outline:` 后面那一截,而一句解释「为什么这里不画
// outline:...」会被原样当成值读出来 —— 门禁于是报一个它自己造出来的违规,而真正的
// 声明就在同一个文件里好好地引用着 token。剥掉注释再扫:只会少匹配,不会漏真声明。
const stripComments = (text) => text.replace(/\/\*[\s\S]*?\*\//g, "").replace(/<!--[\s\S]*?-->/g, "");
let focusOutlineCount = 0;
for (const file of styleFiles(vueRoot)) {
  const rel = relative(root, file);
  const source = stripComments(readFileSync(file, "utf8"));
  for (const match of source.matchAll(/outline:\s*([^;}]+)/g)) {
    const value = match[1].trim();
    if (/^(none|0|inherit|initial|unset)\b/.test(value)) continue;
    focusOutlineCount += 1;
    const vars = [...value.matchAll(/var\(\s*(--[\w-]+)/g)].map((m) => m[1]);
    if (!vars.length) {
      // currentColor is self-contrasting: it is the element's own text colour, which
      // already has to clear 4.5:1 against the same backdrop the ring sits on. It is
      // the right choice on tinted surfaces (status banner, vote bubble) where the
      // one violet would fight the semantic tint.
      if (/\bcurrentColor\b/.test(value)) continue;
      if (/\bwhite\b|#fff/i.test(value) && FOCUS_OUTLINE_ON_MEDIA.has(rel)) continue;
      if (/\bHighlight\b|\bMark\b/.test(value)) continue; // forced-colors system colours
      errors.push(`${rel}: focus outline with a literal colour (${value}) — use var(--flare-color-border-selected)`);
      continue;
    }
    for (const name of vars) {
      if (FOCUS_OUTLINE_VARS.has(name)) continue;
      errors.push(`${rel}: outline colour ${name} is not a solid focus token — WCAG 2.4.11 needs 3:1, and only var(--flare-color-border-selected) clears it in every theme (outline: ${value})`);
    }
  }
}
// A :hover rule must not move the element's box. `transform: translate…` shifts
// the border box, so a cursor resting in the strip the element vacates lands
// outside it: hover drops, the element returns, hover fires again. Growing in
// place (`scale(> 1)`) is fine — the hit area only gets bigger. Centering
// (`translate(…-50%)`) and reveal end-states (`translateY(0)`) do not move
// anything on hover.
const HOVER_RULE = /([^{}]*:hover[^{}]*)\{([^{}]*)\}/g;
let hoverRules = 0;
for (const file of styleFiles(vueRoot)) {
  const rel = relative(root, file);
  for (const match of readFileSync(file, "utf8").matchAll(HOVER_RULE)) {
    const transform = /transform:\s*([^;]+)/.exec(match[2]);
    if (!transform) continue;
    hoverRules += 1;
    const value = transform[1].trim();
    if (!/\btranslate/.test(value)) continue;
    if (/-50%|translateY\(0\)|translate\(0/.test(value)) continue;
    const selector = match[1].trim().split("\n").pop().slice(-70);
    errors.push(`${rel}: :hover moves the element (${value}) on \`${selector}\` — hovering the edge it vacates drops hover and re-fires it; use background/border/shadow, or scale to grow in place`);
  }
}

// Same rule on the three native implementations: the ring/border that marks focus
// is `colors.borderSelected`. `colors.primary` fails every dark theme (1.80-2.66:1)
// and `colors.focusRing` is the glow, never the ring. The one allowed pairing is a
// solid 1px ring with the glow stroked outside it (iOS form fields).
const NATIVE_FOCUS_ROOTS = [
  "packages/flutter-im-ui/lib",
  "packages/ios-im-ui/Sources",
  "packages/android-im-ui/src/main/kotlin",
];
const NATIVE_FOCUS_GLOW_ALLOWED = new Set([
  ".stroke(colors.focusRing, lineWidth: focused ? 3 : 0)",
]);
function sourceFiles(directory) {
  const out = [];
  for (const entry of readdirSync(directory)) {
    const path = join(directory, entry);
    if (statSync(path).isDirectory()) out.push(...sourceFiles(path));
    else if (/\.(dart|swift|kt)$/.test(entry)) out.push(path);
  }
  return out;
}
let nativeFocusCount = 0;
for (const directory of NATIVE_FOCUS_ROOTS) {
  for (const file of sourceFiles(join(root, directory))) {
    const rel = relative(root, file);
    for (const line of readFileSync(file, "utf8").split("\n")) {
      const text = line.trim();
      if (!/(?<![\w$])_?focused\b/.test(text)) continue; // `focused` or `_focused`, never `unfocused…`
      if (text.includes("colors.borderSelected")) nativeFocusCount += 1;
      if (text.includes("colors.primary"))
        errors.push(`${rel}: focus indicator uses colors.primary — it fails 3:1 in every dark theme; use colors.borderSelected (${text.slice(0, 90)})`);
      if (text.includes("colors.focusRing") && !NATIVE_FOCUS_GLOW_ALLOWED.has(text))
        errors.push(`${rel}: focus indicator uses colors.focusRing — that token is the glow, not the ring; use colors.borderSelected (${text.slice(0, 90)})`);
    }
  }
}

// The one indirection: the composer's scoped alias must resolve to that same solid.
requireText("packages/vue-im-ui/src/components/composer/composer-studio.css", [
  "--studio-focus: var(--flare-color-border-selected);",
]);

if (errors.length) {
  console.error(`accessibility check failed (${errors.length})`);
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}
console.log(`accessibility check passed: ${spec.components.filter((c) => (c.events ?? []).length).length} interactive contracts, ${iconTagCount} icon tags named or hidden, ${focusOutlineCount} focus outlines on a solid 3:1 token, ${nativeFocusCount} native focus rings on borderSelected, ${hoverRules} hover transform(s) that keep the box still`);
