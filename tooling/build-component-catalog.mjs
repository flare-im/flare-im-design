#!/usr/bin/env node
import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { loadSurface, vueExportMap } from "../spec/signatures.mjs";
import { previewDemoName } from "../website/.vitepress/theme/demos/preview-registry.mjs";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const readJson = (path) => JSON.parse(readFileSync(join(root, path), "utf8"));
const spec = readJson("spec/components.json");
const layers = readJson("spec/component-layers.json");
const metadata = readJson("spec/catalog-metadata.json");
const gallery = readJson("examples/gallery/gallery-manifest.json");
const slug = (name) => name.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
const galleryComponents = new Set([
  ...Object.values(gallery.general ?? {}),
  ...Object.values(gallery.im ?? {}),
]);
const demoRoot = join(root, "website/.vitepress/theme/demos");
const previewDemos = new Set([
  ...readdirSync(demoRoot),
  ...readdirSync(join(demoRoot, "messages/demos")),
].filter((name) => name.endsWith(".vue")).map((name) => name.replace(/\.vue$/, "")));
const roots = {
  vueExports: vueExportMap(join(root, "packages/vue-im-ui/src")),
  flutter: join(root, "packages/flutter-im-ui/lib"),
  ios: join(root, "packages/ios-im-ui/Sources"),
  compose: join(root, "packages/android-im-ui/src/main"),
};

function localized(value, locale) {
  if (typeof value === "string") return value;
  return value?.[locale] ?? value?.en ?? value?.zh ?? "";
}

function sourcePaths(component) {
  const paths = {};
  for (const platform of ["vue", "flutter", "compose", "ios"]) {
    if (!component.platforms?.[platform]) continue;
    const surface = loadSurface(roots, component, platform);
    if (surface?.file) paths[platform] = relative(root, surface.file);
  }
  return paths;
}

const customActionComponents = new Set([
  "AdaptiveNavigation", "IMAppKit", "Composer", "ComposerActionPanel", "MessageActionSheet",
  "ConversationActionSheet", "ConversationBatchToolbar", "MessageBatchToolbar",
  "MomentActionPopover", "RelationActionBar", "MemberRoleSheet", "CallControls",
  "ConversationHeader",
]);
const customContentComponents = new Set([
  "AppLayout", "MobileAppShell", "DesktopAppShell", "AppShell", "ResponsiveLayout",
  "ConversationWorkspace", "ConversationListContainer", "MessageContentView", "MessageBubble",
  "MessageList", "Composer", "ContactsWorkspace", "GroupWorkspace", "SearchWorkspace",
  "MediaWorkspace", "CallWorkspace", "SettingsWorkspace", "SavedMessagesWorkspace", "IMAppKit",
  "ChatWorkspace",
]);
const slotComponents = new Set([
  ...customContentComponents,
  "EmptyState", "StatusBanner", "SearchResults", "SearchPanel", "ConversationList",
  "ContactList", "GroupList", "CommandPalette",
  "ConversationHeader",
]);
const capabilityComponents = new Set([
  "CapabilityBoundary", "IMAppKit", "Composer", "ComposerActionPanel", "MessageActionSheet",
  "ConversationActionSheet", "ConversationBatchToolbar", "MessageBatchToolbar",
  "RelationActionBar", "GroupDetail", "GroupMemberGrid", "GroupPermissionMatrix",
  "MemberRoleSheet", "CallControls", "ScreenShare",
]);
const responsiveComponents = new Set([
  "AppLayout", "MobileAppShell", "DesktopAppShell", "AppShell", "ResponsiveLayout",
  "ScreenHeader", "ConversationWorkspace", "AdaptiveNavigation", "CommandPalette",
  "SearchPanel", "ConversationList", "ConversationRow", "ConversationDetails",
  "StartConversationDialog", "ForwardPicker", "ConversationActionSheet", "MessageBubble",
  "MessageList", "ConversationHeader", "ChatWorkspace", "MessageActionSheet", "ReadReceiptSheet", "Composer",
  "ComposerActionPanel", "ImagePreviewModal", "VideoPlayerModal", "MediaCenter",
  "ContactList", "ContactDetail", "GroupDetail", "GroupList", "GroupMemberGrid",
  "CallView", "IncomingCall", "GroupCallView", "ProfilePanel", "ProfileEditor",
  "ConversationListContainer", "FriendListContainer", "DesktopWorkbench",
  "MasterDetailLayout", "ThreePaneLayout", "ContactsWorkspace", "GroupWorkspace",
  "SearchWorkspace", "MediaWorkspace", "CallWorkspace", "SettingsWorkspace",
  "SavedMessagesWorkspace", "IMAppKit",
]);

function capabilities(component) {
  const names = (component.props ?? []).map((prop) => prop.name);
  return {
    supportsConfiguration: names.length > 0 || (component.events ?? []).length > 0,
    supportsCustomActions: customActionComponents.has(component.name),
    supportsCustomContent: customContentComponents.has(component.name),
    supportsSlots: slotComponents.has(component.name),
    supportsCapabilities: capabilityComponents.has(component.name)
      || names.some((name) => /capabilit/i.test(name)),
    // FR-050: only what really takes a density. The kit has no global density scale, so the
    // catalogue stops advertising one for 22 components that never had the prop.
    supportsDensity: names.includes("density"),
    supportsResponsive: responsiveComponents.has(component.name)
      || names.some((name) => /responsive|breakpoint|viewport/i.test(name)),
  };
}

const previewModes = new Map([
  ...(metadata.preview?.responsive ?? []).map((name) => [name, "responsive"]),
  ...(metadata.preview?.workspace ?? []).map((name) => [name, "workspace"]),
]);
const previewPresentations = new Map(
  Object.entries(metadata.preview?.presentations ?? {})
    .flatMap(([presentation, names]) => names.map((name) => [name, presentation])),
);

function previewMetadata(component) {
  const defaults = metadata.preview?.default ?? {};
  const mode = previewModes.get(component.name) ?? defaults.mode ?? "single";
  const viewports = metadata.preview?.viewports?.[component.name]
    ?? (mode === "single" ? defaults.viewports ?? ["desktop"] : ["desktop", "mobile"]);
  return {
    previewMode: mode,
    previewViewports: viewports,
    previewPresentation: previewPresentations.get(component.name) ?? defaults.presentation ?? "isolated",
    // The control that brings this component's surface into existence, when a click is what creates it.
    // The accessibility sweep scans the preview as it renders and then again with this activated.
    previewOpener: metadata.preview?.openers?.[component.name] ?? null,
  };
}

function documentationMetadata(component, componentCapabilities, preview) {
  const documentationOverride = metadata.documentation?.overrides?.[component.name] ?? {};
  const keyboard = (component.accessibility?.keyboardBehavior ?? []).length > 0;
  const variants = Boolean(documentationOverride.variantExamples?.length)
    || (component.props ?? []).some((prop) => String(prop.type).includes("|") || /variant|size/i.test(prop.name));
  return {
    configuration: componentCapabilities.supportsConfiguration,
    variants,
    states: (component.states ?? []).length > 0,
    interaction: (component.events ?? []).length > 0,
    responsive: preview.previewMode !== "single",
    keyboard,
    density: componentCapabilities.supportsDensity,
    slots: componentCapabilities.supportsSlots,
    customization: componentCapabilities.supportsCustomActions
      || componentCapabilities.supportsCustomContent
      || componentCapabilities.supportsCapabilities,
  };
}

function documentationExamples(component) {
  const documentationOverride = metadata.documentation?.overrides?.[component.name] ?? {};
  const inferredVariants = (component.props ?? [])
    .filter((prop) => String(prop.type).includes("|") || /variant|size/i.test(prop.name))
    .map((prop) => ({
      name: prop.name,
      values: String(prop.type).includes("|")
        ? String(prop.type).split("|").map((value) => value.trim().replace(/^['"]|['"]$/g, ""))
        : [String(prop.type)],
    }));
  return {
    variants: documentationOverride.variantExamples ?? inferredVariants,
    states: documentationOverride.stateExamples ?? component.states ?? [],
  };
}

const components = spec.components.map((component) => {
  const override = metadata.overrides?.[component.name] ?? {};
  const docSlug = slug(component.name);
  const zhPath = join(root, "website/components", `${docSlug}.md`);
  const enPath = join(root, "website/en/components", `${docSlug}.md`);
  const layer = layers.components[component.name];
  const status = override.status ?? metadata.defaultStatus;
  const componentCapabilities = capabilities(component);
  const preview = previewMetadata(component);
  const aliases = [
    ...(metadata.aliases?.[component.name] ?? []),
    component.category,
    ...component.states,
    ...component.events,
  ];
  return {
    name: component.name,
    slug: docSlug,
    category: component.category,
    layer,
    scope: override.scope ?? "public-library",
    status,
    since: override.since ?? metadata.defaultSince,
    replacement: override.replacement ?? null,
    ...componentCapabilities,
    ...preview,
    docsSections: documentationMetadata(component, componentCapabilities, preview),
    docExamples: documentationExamples(component),
    summary: component.summary,
    aliases: [...new Set(aliases)],
    states: component.states,
    interactions: component.events,
    accessibility: "accessibility-contract",
    responsive: "application-layout-vectors",
    platforms: Object.fromEntries(
      ["vue", "flutter", "compose", "ios"].map((platform) => [
        platform,
        component.platforms?.[platform]
          ? { support: "supported", ...component.platforms[platform] }
          : { support: "not-applicable" },
      ]),
    ),
    sourcePaths: sourcePaths(component),
    docs: {
      zh: existsSync(zhPath) ? `website/components/${docSlug}.md` : null,
      en: existsSync(enPath) ? `website/en/components/${docSlug}.md` : null,
    },
    examples: {
      live: previewDemos.has(previewDemoName(component.name)),
      code: existsSync(zhPath) && existsSync(enPath),
      gallery: galleryComponents.has(component.name),
    },
    sourceOfTruth: `spec/components.json#${component.name}`,
    searchText: [
      component.name,
      component.category,
      layer,
      status,
      ...aliases,
      ...Object.entries(componentCapabilities).filter(([, enabled]) => enabled).map(([key]) => key),
      localized(component.summary, "en"),
      localized(component.summary, "zh"),
    ].join(" ").toLowerCase(),
  };
});

const catalog = {
  schemaVersion: 2,
  version: spec.version,
  categories: spec.categories,
  generatedFrom: [
    "spec/components.json",
    "spec/component-layers.json",
    "spec/catalog-metadata.json",
    "examples/gallery/gallery-manifest.json",
    "website/.vitepress/theme/demos/preview-registry.mjs"
  ],
  statusValues: metadata.statusValues,
  capabilityFields: spec.capabilityFields,
  counts: {
    total: components.length,
    stable: components.filter((component) => component.status === "stable").length,
    general: components.filter((component) => component.layer === "general-ui").length,
    im: components.filter((component) => component.layer === "im-ui").length,
  },
  specializedMessageGroups: metadata.specializedMessageGroups,
  components,
};

const json = `${JSON.stringify(catalog, null, 2)}\n`;
const jsonOutputs = ["spec/component-catalog.json", "website/public/component-catalog.json"];
const publicExportMap = `${JSON.stringify({
  schemaVersion: 1,
  version: spec.version,
  sourceOfTruth: "spec/components.json",
  components: components
    .filter((component) => component.status !== "internal")
    .map((component) => ({
      name: component.name,
      status: component.status,
      platforms: Object.fromEntries(Object.entries(component.platforms)
        .filter(([, platform]) => platform.support === "supported")
        .map(([key, platform]) => [key, {
          package: platform.package,
          symbol: platform.symbol,
          sourcePath: component.sourcePaths[key],
        }])),
    })),
}, null, 2)}\n`;
const layerRows = components.map((component) => {
  const current = Object.values(component.sourcePaths).map((path) => `\`${path}\``).join("<br>") || "REVIEW_REQUIRED";
  const target = component.layer === "general-ui" ? "General UI" : "IM UI";
  const dependencies = component.layer === "general-ui" ? "Foundation" : "Foundation, General UI";
  return `| ${component.name} | ${current} | ${target} | ${target} | yes | ${component.status === "stable" ? "yes" : "no"} | ${dependencies} | Low: logical classification only |`;
});
const markdown = `# Component Layer Map\n\nGenerated from the component contract and platform signatures. Do not hand-edit this table; run \`node tooling/build-component-catalog.mjs\`.\n\n| Component | Current path | Target layer | Target package | Public? | Stable? | Dependencies | Migration risk |\n|---|---|---|---|:---:|:---:|---|---|\n${layerRows.join("\n")}\n`;
const outputs = new Map([
  ...jsonOutputs.map((path) => [path, json]),
  ["spec/public-export-map.json", publicExportMap],
  ["docs/component-layer-map.md", markdown],
]);

let stale = false;
for (const [path, content] of outputs) {
  const absolute = join(root, path);
  if (process.argv.includes("--check")) {
    if (!existsSync(absolute) || readFileSync(absolute, "utf8") !== content) {
      console.error(`stale generated catalog: ${path}`);
      stale = true;
    }
  } else {
    mkdirSync(dirname(absolute), { recursive: true });
    writeFileSync(absolute, content);
  }
}
if (stale) process.exit(1);
console.log(`component catalog ${process.argv.includes("--check") ? "current" : "written"}: ${components.length} entries`);
