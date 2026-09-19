#!/usr/bin/env node
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const readJson = (path) => JSON.parse(readFileSync(join(root, path), "utf8"));
const spec = readJson("spec/components.json");
const maturity = readJson("spec/component-maturity.json");
const interactions = readJson("spec/interaction-contracts.json");
const patterns = readJson("spec/composition-patterns.json");
const errors = [];

for (const [groupName, group] of [["general", maturity.general], ["im", maturity.im]]) {
  const seen = new Set();
  for (const entry of group) {
    const key = groupName === "im" ? `${entry.group}:${entry.capability}` : entry.capability;
    if (seen.has(key)) errors.push(`duplicate maturity capability: ${key}`);
    seen.add(key);
    if (!entry.status || !entry.priority) errors.push(`${key}: status and priority are required`);
    if (entry.status === "missing" && ["P0", "P1"].includes(entry.priority)) errors.push(`${key}: unresolved ${entry.priority} capability`);
  }
}

for (const [platform, model] of Object.entries(interactions.platformModels)) {
  const path = join(root, model.path);
  if (!existsSync(path)) { errors.push(`${platform}: missing interaction model ${model.path}`); continue; }
  const source = readFileSync(path, "utf8");
  for (const symbol of model.symbols) if (!source.includes(symbol)) errors.push(`${platform}: missing interaction symbol ${symbol}`);
}

for (const required of ["Composer", "MessageBubble", "ConversationItem", "MessageList", "Search", "Thread", "Reaction", "Upload", "CallDock", "ContextMenu", "MultiSelect"]) {
  const machine = interactions.stateMachines[required];
  if (!machine?.states?.length || !machine?.events?.length) errors.push(`${required}: incomplete state machine`);
}
for (const action of interactions.desktopShortcuts.actions) {
  if (!["vue", "flutter", "compose", "ios"].every((platform) => interactions.desktopShortcuts.platformMapping[platform])) errors.push(`${action}: incomplete desktop platform mapping`);
}
for (const [name, pattern] of Object.entries(patterns.patterns)) {
  for (const field of ["requiredRegions", "optionalRegions", "responsiveRules", "stateModel", "accessibility", "keyboard", "platformAdaptations"]) {
    if (!pattern[field] || (Array.isArray(pattern[field]) && !pattern[field].length)) errors.push(`${name}: missing ${field}`);
  }
  for (const platform of ["vue", "flutter", "compose", "ios"]) if (!pattern.platformAdaptations?.[platform]) errors.push(`${name}: missing ${platform} adaptation`);
}

const command = spec.components.find((component) => component.name === "CommandPalette");
if (!command || !["vue", "flutter", "compose", "ios"].every((platform) => command.platforms?.[platform])) errors.push("CommandPalette: incomplete public platform mapping");

const booleanFamilies = [
  ["loading", "isLoading", "showLoading", "loadingState"],
  ["disabled", "isDisabled"],
  ["open", "isOpen", "show", "visible"],
  ["selected", "isSelected"],
];
for (const component of spec.components) {
  const props = new Set((component.props ?? []).map((prop) => prop.name));
  if (props.size !== (component.props ?? []).length) errors.push(`${component.name}: duplicate prop`);
  if (new Set(component.events ?? []).size !== (component.events ?? []).length) errors.push(`${component.name}: duplicate event`);
  for (const family of booleanFamilies) {
    const overlap = family.filter((name) => props.has(name));
    if (overlap.length > 1) errors.push(`${component.name}: boolean explosion ${overlap.join("/")}`);
  }
}

if (errors.length) {
  console.error("maturity contract errors:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
console.log(`maturity passed: ${maturity.general.length} General capabilities, ${maturity.im.length} IM capabilities, ${Object.keys(interactions.stateMachines).length} state machines, ${Object.keys(patterns.patterns).length} patterns`);
