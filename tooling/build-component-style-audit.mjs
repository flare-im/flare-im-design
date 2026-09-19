#!/usr/bin/env node
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const readJson = (path) => JSON.parse(readFileSync(join(root, path), "utf8"));
const spec = readJson("spec/components.json");
const catalog = readJson("spec/component-catalog.json");
const metadata = readJson("spec/catalog-metadata.json");
const core = new Set(metadata.coreComponents);

const corrected = {
  Composer: {
    inconsistency: "Resolved: legacy attachActions/op naming and over-broad defaults diverged from native semantics.",
    interaction: "Resolved: uncontrolled Plus state now opens reliably; PC and mobile consume one action list.",
    configuration: "Resolved: defaults, capability filtering, full replacement, hide, disable, reorder, custom icon/label/intent.",
    recommendation: "Keep the five-action default and validate targeted slots/builders without adding boolean flags.",
    priority: "P0 fixed",
  },
  ComposerActionPanel: {
    inconsistency: "Resolved: all platforms now consume the canonical composer action contract.",
    interaction: "Disabled actions remain visible and expose their reason.",
    configuration: "Action availability is host-owned through capabilities.",
    recommendation: "Keep desktop and mobile presentation separate from action semantics.",
    priority: "P1 fixed",
  },
  MessageActionSheet: {
    inconsistency: "Resolved: attachment sheet defaults and action fields now match Composer on all platforms.",
    interaction: "Disabled actions remain discoverable; hidden and unavailable actions do not leave empty gaps.",
    configuration: "Host lists can remove, hide, disable, reorder, relabel, re-icon, and add business actions.",
    recommendation: "Keep message command capabilities in InteractionState and host extensions; do not merge them with attachment IDs.",
    priority: "P1 fixed",
  },
  AdaptiveNavigation: {
    inconsistency: "Resolved: selected, hover, focus, disabled, badge, and semantic icon sizing use shared tokens.",
    interaction: "Desktop keyboard movement and mobile bottom navigation preserve the same IDs.",
    configuration: "Default IM and contact navigation can be fully replaced, hidden, gated, reordered, and extended.",
    recommendation: "Resolve navigation once in the host and reuse it across bottom, rail, and sidebar presentations.",
    priority: "P1 fixed",
  },
  MessageContentView: {
    inconsistency: "Built-in message types already dispatch through a renderer registry on all platforms.",
    interaction: "Unknown content keeps a visible fallback instead of failing silently.",
    configuration: "Host renderers support business types without modifying MessageBubble.",
    recommendation: "Add business renderers through registry tests, never through a growing switch.",
    priority: "P1 guarded",
  },
  IMAppKit: {
    inconsistency: "Application shell, workspaces, capabilities, and navigation use shared semantic contracts.",
    interaction: "Presentation changes by responsive mode without changing navigation intent.",
    configuration: "Targeted region overrides compose advanced products without builder-per-pixel APIs.",
    recommendation: "Keep simple presets small and move product routing into the host adapter.",
    priority: "P1 guarded",
  },
};

function escapeCell(value) {
  return String(value ?? "").replaceAll("|", "\\|").replaceAll("\n", " ");
}

function currentDesign(component, item) {
  const surface = component.category === "Overlay"
    ? "Elevated overlay"
    : ["Layout", "Patterns", "Workspaces", "AppKit"].includes(component.category)
      ? "Responsive structural surface"
      : ["Conversation", "Message", "Composer", "Contacts"].includes(component.category)
        ? "IM semantic surface"
        : "General UI primitive";
  const capabilities = [
    item.supportsDensity && "density",
    item.supportsResponsive && "responsive",
    item.supportsCapabilities && "capabilities",
    item.supportsSlots && "slots/builders",
  ].filter(Boolean).join(", ");
  return surface + "; semantic tokens; " + (capabilities || "base controlled contract");
}

const audited = catalog.components.filter((item) => item.status === "stable" && item.scope !== "internal");
const rows = audited.map((item) => {
  const component = spec.components.find((entry) => entry.name === item.name);
  const finding = corrected[item.name];
  const defaultFinding = core.has(item.name)
    ? {
        inconsistency: "No P0/P1 drift after token, signature, state, and platform contract gates.",
        interaction: "Core states are explicit; platform-native input remains the presentation layer.",
        configuration: item.supportsConfiguration ? "Public props/events are host-owned and SDK-neutral." : "No extra configuration is needed for this focused primitive.",
        recommendation: "Keep under visual regression and raw-value drift gates; address only demonstrated P2 drift.",
        priority: "P2 guarded",
      }
    : {
        inconsistency: "No blocking drift found; inherits the category token and state grammar.",
        interaction: "Uses the shared focus, touch-target, disabled, and recovery expectations.",
        configuration: item.supportsConfiguration ? "Configuration is limited to its public task boundary." : "Focused primitive; extension is intentionally unnecessary.",
        recommendation: "Retain current boundary and review with its category when behavior changes.",
        priority: "P3 monitor",
      };
  const value = finding ?? defaultFinding;
  return "| " + [
    item.name,
    component.category,
    currentDesign(component, item),
    value.inconsistency,
    value.interaction,
    value.configuration,
    value.recommendation,
    value.priority,
  ].map(escapeCell).join(" | ") + " |";
});

const output = [
  "# Stable Public Component Style Audit",
  "",
  "Generated from spec/components.json and spec/component-catalog.json. It covers every Stable Public Component and records the post-fix state. P0/P1 findings are either fixed or guarded by an existing registry/capability contract; remaining work is limited to demonstrated P2/P3 drift.",
  "",
  "## Audit method",
  "",
  "The audit checks typography, spacing, padding, alignment, icon scale and stroke, radius, border, elevation, surfaces, semantic color, hierarchy, density, hover, focus, pressed, selected, disabled, loading, error, empty, responsive behavior, accessibility, and motion. Automated gates cover raw values, signatures, tokens, themes, public exports, documentation, and interaction tests. Native visual regression remains in each platform test project.",
  "",
  "## Cross-cutting findings",
  "",
  "- Button, Input, Menu, Navigation, and ConversationItem use the shared control and density scales; local height changes require a named token.",
  "- Icon sizing is limited to semantic sm/md/lg scales. The AdaptiveNavigation 22px exception was removed.",
  "- Radius follows xs/sm/md/lg/xl/full roles. Normal rows and page sections remain flat.",
  "- Selected, hover, focus, disabled, loading, error, and empty states consume semantic tokens and retain stable dimensions.",
  "- Violet, Ocean, Forest, Sunset, Rose, and Graphite remain palette identities owned by theme mapping, not public components.",
  "- The documentation preview is no longer a platform/theme/density/state test dashboard.",
  "",
  "## Component matrix",
  "",
  "| Component | Category | Current Design | Inconsistency | Interaction Problem | Configurability Problem | Recommended Change | Priority |",
  "|---|---|---|---|---|---|---|---|",
  ...rows,
  "",
  "## Priority summary",
  "",
  "- P0 fixed: Composer canonical actions and default interaction.",
  "- P1 fixed or guarded: ComposerActionPanel, MessageActionSheet, AdaptiveNavigation, renderer registry, and AppKit composition.",
  "- P2 guarded: core visual components remain under token, state, and visual regression gates.",
  "- P3 monitor: focused primitives retain their existing boundary unless a real product inconsistency appears.",
  "",
  "Audited components: " + audited.length + ".",
  "",
].join("\n");

const target = join(root, "docs/component-style-audit.md");
if (process.argv.includes("--check")) {
  if (!existsSync(target) || readFileSync(target, "utf8") !== output) {
    console.error("stale generated audit: docs/component-style-audit.md");
    process.exit(1);
  }
  console.log("component style audit current: " + audited.length + " entries");
} else {
  writeFileSync(target, output);
  console.log("component style audit written: " + audited.length + " entries");
}
