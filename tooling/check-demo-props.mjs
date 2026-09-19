#!/usr/bin/env node
/**
 * The website's demos may only pass props the components actually have.
 *
 * Vue drops an unknown prop onto the root element as an attribute and says nothing, so a prop that
 * was renamed or removed leaves the documentation rendering a component nobody configured. On
 * 2026-09-18 nine demos did exactly that: `conversation-type` on the timeline and the bubble had
 * been `conversation-kind` since the conversation-kind vocabulary landed, `group-start`/`group-end`
 * had become one `group-position`, `count` on the batch toolbar was `total`, `connection-tone` was
 * `tone`, and the avatar demo asked for a `status` dot the component has never had (`presence`).
 * The docs looked right because the defaults looked plausible (FR-155).
 *
 * Nothing else catches this: the demos are plain `<script setup>` with no types, the VitePress build
 * only compiles them, and the Playwright suite only asserts what a handful of pages show.
 *
 * Listeners get the same treatment: `@forward-each` on a toolbar whose event is `action` is attached
 * as a native DOM listener and simply never fires. Real DOM events are allowed through, because
 * forwarding `@click` to the root element is what a host wants.
 *
 * The check reads props and events straight out of each component's `defineProps`/`defineEmits`, the
 * same reader the signature and slot gates use, so it cannot drift the way a hand-written list does.
 */
import { readFileSync, readdirSync, statSync } from "node:fs";
import { extname, join, relative } from "node:path";
import { dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { vueExportMap, vueSurface } from "../spec/signatures.mjs";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const exportsByName = vueExportMap(join(root, "packages/vue-im-ui/src"));
const DEMO_ROOTS = ["website/.vitepress/theme/demos"];

/**
 * Attributes every element takes, or that Vue itself owns. `v-*`, `data-*`, `aria-*` and `#slot` are
 * handled by shape. This list only grows for an attribute a kit component deliberately forwards to
 * its root element; a prop belongs in `defineProps`, not here.
 */
const UNIVERSAL = new Set(["class", "style", "id", "ref", "key", "is", "slot", "role", "tabindex", "hidden", "title", "lang", "dir"]);

/**
 * DOM events a component does not have to declare: Vue forwards an undeclared listener to the root
 * element, which is exactly what a host wants for `@click` and exactly what hides a typo like
 * `@forward-each` on a component whose event is `action`.
 */
const DOM_EVENTS = new Set([
  "click", "dblclick", "contextmenu", "mousedown", "mouseup", "mouseenter", "mouseleave", "mousemove", "mouseover", "mouseout",
  "pointerdown", "pointerup", "pointermove", "pointerenter", "pointerleave", "pointercancel",
  "touchstart", "touchend", "touchmove", "touchcancel",
  "keydown", "keyup", "keypress", "focus", "blur", "focusin", "focusout",
  "input", "change", "submit", "reset", "scroll", "wheel", "copy", "cut", "paste",
  "dragenter", "dragleave", "dragover", "drop", "load", "error", "transitionend", "animationend",
]);

const camel = (name) => name.replace(/[-_](\w)/g, (_, c) => c.toUpperCase());

function demoFiles(path, out = []) {
  for (const entry of readdirSync(path)) {
    const absolute = join(path, entry);
    if (statSync(absolute).isDirectory()) demoFiles(absolute, out);
    else if (extname(entry) === ".vue") out.push(absolute);
  }
  return out;
}

/** Local tag name → kit export name, from the demo's own imports (`X as Y` included). */
function kitTags(source) {
  const tags = new Map();
  for (const m of source.matchAll(/import\s*\{([^}]*)\}\s*from\s*["']@flare-im\/vue-ui[^"']*["']/g)) {
    for (const part of m[1].split(",")) {
      const [imported, local] = part.split(/\s+as\s+/).map((piece) => piece.trim());
      if (!imported) continue;
      tags.set(local || imported, imported);
    }
  }
  return tags;
}

/**
 * Opening tags with their attribute text. A regex cannot do this: `() =>` inside a listener and `>`
 * inside a bound expression both end the tag early, which is how the first draft of this check
 * reported `action:` as a prop.
 */
function openingTags(source) {
  const found = [];
  for (const m of source.matchAll(/<([A-Z][A-Za-z0-9]*)(?=[\s/>])/g)) {
    let i = m.index + m[0].length;
    let quote = "";
    while (i < source.length) {
      const ch = source[i];
      if (quote) {
        if (ch === quote) quote = "";
      } else if (ch === '"' || ch === "'") quote = ch;
      else if (ch === ">") break;
      i++;
    }
    found.push({ tag: m[1], attrs: source.slice(m.index + m[0].length, i), index: m.index });
  }
  return found;
}

/** Attribute names in source order, values consumed so their contents are never read as names. */
function attributeNames(attrs) {
  const names = [];
  const pattern = /([:@#]?[A-Za-z][\w.:-]*)(?:\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>]+))?/g;
  let match;
  while ((match = pattern.exec(attrs))) names.push(match[1]);
  return names;
}

const failures = [];
let checked = 0;
for (const demoRoot of DEMO_ROOTS) {
  for (const file of demoFiles(join(root, demoRoot))) {
    const source = readFileSync(file, "utf8");
    const tags = kitTags(source);
    if (!tags.size) continue;
    for (const { tag, attrs, index } of openingTags(source)) {
      const exported = tags.get(tag);
      if (!exported) continue;
      const componentFile = exportsByName[exported];
      if (!componentFile) {
        failures.push(`${relative(root, file)}: <${tag}> imports "${exported}", which the kit does not export`);
        continue;
      }
      const { props, events } = vueSurface(componentFile);
      const line = source.slice(0, index).split("\n").length;
      for (const raw of attributeNames(attrs)) {
        if (raw.startsWith("@")) {
          const event = raw.slice(1).split(".")[0];
          if (!event || DOM_EVENTS.has(event)) continue;
          checked += 1;
          if (events.has(event) || events.has(camel(event))) continue;
          failures.push(`${relative(root, file)}:${line} <${tag}> does not emit "${event}" (${exported} emits: ${[...events].sort().join(", ") || "nothing"})`);
          continue;
        }
        if (raw.startsWith("#") || raw.startsWith("v-")) continue;
        const name = raw.startsWith(":") ? raw.slice(1) : raw;
        if (name.startsWith("data-") || name.startsWith("aria-") || UNIVERSAL.has(name)) continue;
        checked += 1;
        if (props.has(name) || props.has(camel(name))) continue;
        failures.push(`${relative(root, file)}:${line} <${tag}> has no prop "${name}" (${exported} takes: ${[...props].sort().join(", ") || "none"})`);
      }
    }
  }
}

if (failures.length) {
  for (const failure of failures) console.error(`FAIL ${failure}`);
  console.error(`demo props: ${failures.length} demo attribute(s) name a prop or event the component does not have`);
  console.error(`\n  Vue puts an unknown prop on the root element and an unknown listener on a native event,`);
  console.error(`  and says nothing either way — so the page renders a component nobody configured and a`);
  console.error(`  handler that never runs. Use what the component declares, or delete the line.`);
  process.exit(1);
}
console.log(`demo props passed: ${checked} demo attributes, all declared by the component they are on`);
