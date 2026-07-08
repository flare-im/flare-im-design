#!/usr/bin/env node
// Generates the component doc pages from the L2 spec (single source:
// flare-im-design/spec/components.json). Bilingual: writes a zh set (root,
// site/components/) and an en set (site/en/components/). Re-run after editing
// the spec.
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { curatedExamples } from "./examples.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const spec = JSON.parse(
  readFileSync(join(here, "../../spec/components.json"), "utf8"),
);

const slug = (name) => name.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
const esc = (s) => String(s).replace(/\|/g, "\\|");
// bilingual field → localized string; plain string → itself (both locales)
const pick = (f, loc) => (f && typeof f === "object" && "en" in f ? f[loc] : f) ?? "";
const catLabel = (cat, loc) => spec.categoryLabels?.[cat]?.[loc] ?? cat;

const LOCALES = [
  { code: "zh", dir: join(here, "../components"), base: "/components" },
  { code: "en", dir: join(here, "../en/components"), base: "/en/components" },
];

const UI = {
  zh: {
    props: "Props", name: "名称", type: "类型", required: "必填", default: "默认", desc: "说明",
    states: "States", events: "Events", impl: "各端实现", usage: "用法", preview: "预览",
    examples: "示例", dataSource: "数据源", planned: "规划中", none: "_无_",
    plannedNote: "该组件契约已定稿，各端实现正在陆续落地（Android 优先）。下方为设计预览。",
    overview: "组件总览",
    overviewLead: (n, c) => `一套契约，四端原生实现。共 **${n}** 个组件、**${c}** 大类。`,
    freeCompose: "自由组合（用 parts 自己拼）", noRequired: "无必填 props",
    refTitle: "数据类型",
    refLead: "组件 props 里用到的共享数据结构。从你自己的数据源把这些对象喂给组件即可——组件不耦合 SDK。",
    fieldsH: "字段", valuesH: "取值", usedByH: "被使用于",
    interfacesH: "接口", enumsH: "枚举 / 联合类型",
  },
  en: {
    props: "Props", name: "Name", type: "Type", required: "Req.", default: "Default", desc: "Description",
    states: "States", events: "Events", impl: "Platform implementations", usage: "Usage", preview: "Preview",
    examples: "Examples", dataSource: "Data source", planned: "Planned", none: "_None_",
    plannedNote: "The contract is finalized; platform implementations are landing incrementally (Android first). A design preview is shown below.",
    overview: "Components",
    overviewLead: (n, c) => `One contract, four native implementations. **${n}** components across **${c}** categories.`,
    freeCompose: "Free composition (assemble from parts)", noRequired: "no required props",
    refTitle: "Data Types",
    refLead: "Shared data structures used by component props. Feed these objects to the components from your own data source — the components carry no SDK coupling.",
    fieldsH: "Fields", valuesH: "Values", usedByH: "Used by",
    interfacesH: "Interfaces", enumsH: "Enums / unions",
  },
};

// ---- data-type linking ---------------------------------------------------
// anchor keyed by both the display name and the real symbol → slug(name)
const typeAnchor = {};
for (const dt of spec.dataTypes ?? []) {
  typeAnchor[dt.name] = slug(dt.name);
  if (dt.symbol) typeAnchor[dt.symbol] = slug(dt.name);
}
const refBaseFor = (loc) => (loc === "zh" ? "/reference/data-types" : "/en/reference/data-types");
const compBaseFor = (loc) => (loc === "zh" ? "/components" : "/en/components");
// strip decorations to find the base type token (Contact[] / readonly X[] / X?)
const baseType = (type) =>
  String(type).replace(/readonly\s+/g, "").replace(/\[\]/g, "").replace(/\?/g, "").trim();
// render a type as a link to the data-types page when it references a known type
function typeCell(type, loc) {
  const anchor = typeAnchor[baseType(type)];
  return anchor ? `[\`${esc(type)}\`](${refBaseFor(loc)}#${anchor})` : `\`${esc(type)}\``;
}

// Resolve the real Vue *public export* name from vue-im-ui's barrel, keyed by
// the .vue file basename (which is the spec's vue symbol).
const vueExportByFile = (() => {
  const map = {};
  try {
    const src = readFileSync(join(here, "../../vue-im-ui/src/components/index.ts"), "utf8");
    const re = /export\s*\{\s*(?:default as\s+)?(\w+)(?:\s+as\s+(\w+))?\s*\}\s*from\s*"([^"]+)"/g;
    let m;
    while ((m = re.exec(src))) {
      const exportName = m[2] || m[1];
      const base = m[3].split("/").pop().replace(/\.(vue|ts)$/, "");
      map[base] = exportName;
    }
  } catch { /* barrel not found → fall back to spec symbol */ }
  return map;
})();
const vueExportFor = (c) => vueExportByFile[c.platforms.vue.symbol] || c.platforms.vue.symbol;

// components with a live demo component registered in the theme (shared Vue demos)
const demoOf = {
  Avatar: "AvatarDemo", TimeStamp: "TimeStampDemo", MessageStatus: "MessageStatusDemo",
  ConversationRow: "ConversationRowDemo", ConversationList: "ConversationListDemo",
  MessageBubble: "MessageBubbleDemo", ChatHeader: "ChatHeaderDemo", PinnedMessageBar: "PinnedBarDemo",
  Composer: "ComposerDemo", MarkdownPreview: "MarkdownPreviewDemo",
  SearchBar: "SearchBarDemo", Input: "InputDemo", EmptyState: "EmptyStateDemo",
  ContactList: "ContactListDemo", ProfilePanel: "ProfilePanelDemo",
  CallView: "CallViewDemo", IncomingCall: "IncomingCallDemo", CallControls: "CallControlsDemo",
  MessageList: "MessageListDemo", MessageContentView: "MessageContentViewDemo",
  ConversationDetails: "ConversationDetailsDemo", StartConversationDialog: "StartConversationDialogDemo",
  RichMarkdownInput: "RichMarkdownInputDemo", MessageActionSheet: "MessageActionSheetDemo",
  ImagePreviewModal: "ImagePreviewModalDemo", VideoPlayerModal: "VideoPlayerModalDemo",
  ContactItem: "ContactItemDemo", ContactDetail: "ContactDetailDemo",
  NewFriendRequests: "NewFriendRequestsDemo", GroupList: "GroupListDemo",
  ProfileEditor: "ProfileEditorDemo", SettingsList: "SettingsListDemo",
  AppShell: "AppShellDemo", ResponsiveLayout: "ResponsiveLayoutDemo",
  // per-type message bodies (decomposed MessageContentView)
  TextMessage: "TextMessageDemo", ImageMessage: "ImageMessageDemo",
  VideoMessage: "VideoMessageDemo", VoiceMessage: "VoiceMessageDemo",
  FileMessage: "FileMessageDemo", LocationMessage: "LocationMessageDemo",
  ContactMessage: "ContactMessageDemo", LinkCardMessage: "LinkCardMessageDemo",
  VoteMessage: "VoteMessageDemo", TaskMessage: "TaskMessageDemo",
  StickerMessage: "StickerMessageDemo", EmojiMessage: "EmojiMessageDemo",
  SystemMessage: "SystemMessageDemo",
  // composer parts
  VoiceHoldButton: "VoiceHoldButtonDemo", ComposerActionPanel: "ComposerActionPanelDemo",
  ComposerSendButton: "ComposerSendButtonDemo", ComposerReplyStrip: "ComposerReplyStripDemo",
};
const partsDemoOf = { Composer: "ComposerPartsDemo" };
const stackDemos = new Set([
  "ConversationList", "MessageBubble", "ChatHeader", "Composer", "PinnedMessageBar",
  "MarkdownPreview", "EmptyState", "ContactList", "ProfilePanel", "CallView",
  "IncomingCall", "SearchBar", "Input",
  "MessageList", "MessageContentView", "ConversationDetails", "StartConversationDialog",
  "RichMarkdownInput", "MessageActionSheet", "ImagePreviewModal", "VideoPlayerModal",
  "ContactItem", "ContactDetail", "NewFriendRequests", "GroupList",
  "ProfileEditor", "SettingsList", "AppShell", "ResponsiveLayout",
]);

function propsTable(props, t, loc) {
  if (!props?.length) return t.none + "\n";
  let out = `| ${t.name} | ${t.type} | ${t.required} | ${t.default} | ${t.desc} |\n|---|---|:---:|---|---|\n`;
  for (const p of props) {
    out += `| \`${esc(p.name)}\` | ${typeCell(p.type, loc)} | ${p.required ? "✔" : ""} | ${p.default ? `\`${esc(p.default)}\`` : "—"} | ${esc(pick(p.description, loc)) || "—"} |\n`;
  }
  return out;
}

const tagList = (items, t) =>
  !items?.length ? t.none : items.map((s) => `<span class="flare-tag">${s}</span>`).join(" ");

function platformGrid(platforms) {
  const label = { vue: "Vue", flutter: "Flutter", ios: "iOS", compose: "Android · Compose" };
  let html = '<div class="flare-platform-grid">\n';
  for (const key of ["vue", "flutter", "ios", "compose"]) {
    const p = platforms[key];
    if (!p) continue;
    const sym = key === "vue" ? vueExportByFile[p.symbol] || p.symbol : p.symbol;
    html += `  <div class="flare-platform-card"><h4>${label[key]}</h4><div><code>${sym}</code></div><div style="color:var(--vp-c-text-3);font-size:12px;margin-top:4px">${p.package}</div></div>\n`;
  }
  return html + "</div>\n";
}

const cap1 = (s) => s.charAt(0).toUpperCase() + s.slice(1);
const camel = (s) => s.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
const onName = (ev) => "on" + cap1(camel(ev));

function exampleProps(c) {
  const req = (c.props ?? []).filter((p) => p.required);
  const opt = (c.props ?? []).filter((p) => !p.required);
  return [...req, ...opt.slice(0, Math.max(0, 3 - req.length))];
}

function usage(c, t) {
  const v = vueExportFor(c);
  const f = c.platforms.flutter.symbol;
  const i = c.platforms.ios.symbol;
  const k = c.platforms.compose.symbol;
  const props = exampleProps(c);
  const events = (c.events ?? []).slice(0, 3);

  const vueAttrs = [
    ...props.map((p) => `  :${p.name}="${p.name}"`),
    ...events.map((e) => `  @${e}="${onName(e)}"`),
  ].join("\n");
  const dartArgs = [
    ...props.map((p) => `  ${p.name}: ${p.name},`),
    ...events.map((e) => `  ${onName(e)}: ${onName(e)},`),
  ].join("\n");
  const swiftArgs = [
    ...props.map((p) => `${p.name}: ${p.name}`),
    ...events.map((e) => `${onName(e)}: ${onName(e)}`),
  ].join(", ");
  const kotlinArgs = [
    ...props.map((p) => `  ${p.name} = ${p.name},`),
    ...events.map((e) => `  ${onName(e)} = ${onName(e)},`),
  ].join("\n");

  return `::: code-group

\`\`\`vue [Vue]
<script setup>
import { ${v} } from "flare-core-vue-im-ui";
</script>
<template>
  <${v}
${vueAttrs || `  <!-- ${t.noRequired} -->`}
  />
</template>
\`\`\`

\`\`\`dart [Flutter]
${f}(
${dartArgs}
);
\`\`\`

\`\`\`swift [iOS]
${i}(${swiftArgs})
\`\`\`

\`\`\`kotlin [Android]
${k}(
${kotlinArgs}
)
\`\`\`

:::
`;
}

function extraExamples(c, t, loc) {
  if (!Array.isArray(c.examples) || c.examples.length === 0) return "";
  let out = `\n## ${t.examples}\n`;
  for (const ex of c.examples) {
    out += `\n### ${pick(ex.title, loc)}\n`;
    const d = pick(ex.description, loc);
    if (d) out += `\n${d}\n`;
    out += "\n::: code-group\n";
    if (ex.vue) out += `\n\`\`\`vue [Vue]\n${ex.vue}\n\`\`\`\n`;
    if (ex.flutter) out += `\n\`\`\`dart [Flutter]\n${ex.flutter}\n\`\`\`\n`;
    if (ex.ios) out += `\n\`\`\`swift [iOS]\n${ex.ios}\n\`\`\`\n`;
    if (ex.compose) out += `\n\`\`\`kotlin [Android]\n${ex.compose}\n\`\`\`\n`;
    out += "\n:::\n";
  }
  return out;
}

function componentPage(c, loc) {
  const t = UI[loc];
  const demo = demoOf[c.name];
  const parts = partsDemoOf[c.name];
  return `---
title: ${c.name}
---

# ${c.name}

<p><span class="flare-tag">${catLabel(c.category, loc)}</span>${c.status === "planned" ? ` <span class="flare-tag planned">${t.planned}</span>` : ""}</p>

> ${pick(c.summary, loc)}

**${t.dataSource}**${loc === "zh" ? "：" : ": "}${pick(c.dataSource, loc)}
${c.status === "planned" ? `\n> [!NOTE]\n> ${t.plannedNote}\n` : ""}
${demo ? `## ${t.preview}\n\n<div class="flare-demo${stackDemos.has(c.name) ? " flare-demo--stack" : ""}">\n  <${demo} />\n</div>\n` : ""}${
    parts ? `\n### ${t.freeCompose}\n\n<div class="flare-demo flare-demo--stack">\n  <${parts} />\n</div>\n` : ""
  }
## ${t.props}

${propsTable(c.props, t, loc)}

## ${t.states}

${tagList(c.states, t)}

## ${t.events}

${tagList(c.events, t)}
${c.notes ? `\n> [!TIP]\n> ${pick(c.notes, loc)}\n` : ""}
## ${t.impl}

${platformGrid(c.platforms)}

## ${t.usage}

${usage(c, t)}
${extraExamples(c, t, loc)}`;
}

function usedByComponents(dt) {
  const names = new Set([dt.name, dt.symbol].filter(Boolean));
  return spec.components
    .filter((c) => (c.props ?? []).some((p) => names.has(baseType(p.type))))
    .map((c) => c.name);
}

function dataTypesPage(loc) {
  const t = UI[loc];
  const dts = spec.dataTypes ?? [];
  const interfaces = dts.filter((d) => d.kind !== "enum");
  const enums = dts.filter((d) => d.kind === "enum");
  const compBase = compBaseFor(loc);
  const usedBy = (dt) => {
    const list = usedByComponents(dt);
    if (!list.length) return "";
    return `\n**${t.usedByH}${loc === "zh" ? "：" : ": "}**` +
      list.map((n) => `[${n}](${compBase}/${slug(n)})`).join(" · ") + "\n";
  };
  let out = `---\ntitle: ${t.refTitle}\n---\n\n# ${t.refTitle}\n\n> ${t.refLead}\n`;
  if (interfaces.length) {
    out += `\n## ${t.interfacesH}\n`;
    for (const dt of interfaces) {
      out += `\n### ${dt.name} {#${slug(dt.name)}}\n\n\`${dt.symbol}\`\n\n> ${pick(dt.summary, loc)}\n${usedBy(dt)}\n`;
      out += `| ${t.name} | ${t.type} | ${t.required} | ${t.desc} |\n|---|---|:---:|---|\n`;
      for (const fld of dt.fields ?? [])
        out += `| \`${esc(fld.name)}\` | ${typeCell(fld.type, loc)} | ${fld.required ? "✔" : ""} | ${esc(pick(fld.description, loc)) || "—"} |\n`;
    }
  }
  if (enums.length) {
    out += `\n## ${t.enumsH}\n`;
    for (const dt of enums) {
      out += `\n### ${dt.name} {#${slug(dt.name)}}\n\n\`${dt.symbol}\`\n\n> ${pick(dt.summary, loc)}\n${usedBy(dt)}\n`;
      out += (dt.values ?? []).map((v) => `\`${esc(v)}\``).join(" · ") + "\n";
    }
  }
  return out;
}

// merge curated examples once
for (const c of spec.components) c.examples = curatedExamples[c.name] ?? c.examples;

for (const { code, dir, base } of LOCALES) {
  const t = UI[code];
  mkdirSync(dir, { recursive: true });
  const byCat = {};
  for (const c of spec.components) {
    writeFileSync(join(dir, `${slug(c.name)}.md`), componentPage(c, code));
    (byCat[c.category] ??= []).push(c);
  }
  let idx = `# ${t.overview}\n\n${t.overviewLead(spec.components.length, spec.categories.length)}\n\n`;
  for (const cat of spec.categories) {
    idx += `## ${catLabel(cat, code)}\n\n`;
    for (const c of byCat[cat] ?? [])
      idx += `- [**${c.name}**](${base}/${slug(c.name)}) — ${pick(c.summary, code)}\n`;
    idx += "\n";
  }
  writeFileSync(join(dir, "index.md"), idx);
  console.log(`generated ${spec.components.length} ${code} component pages + index into ${base}/`);
}

// data-types reference page (both locales)
for (const { code, dir } of [
  { code: "zh", dir: join(here, "../reference") },
  { code: "en", dir: join(here, "../en/reference") },
]) {
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, "data-types.md"), dataTypesPage(code));
  console.log(`generated ${code} data-types reference (${(spec.dataTypes ?? []).length} types)`);
}
