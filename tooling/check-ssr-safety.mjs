#!/usr/bin/env node
// ssr-safety — no kit component may touch `window` / `document` while it is being
// set up or rendered.
//
// Why this is measured and not grepped: 25 of the kit's modules mention `window`
// or `document`, and every one of them is fine — the access sits in `onMounted`,
// an event handler, or behind a `typeof window === "undefined"` guard. The gap
// analysis recorded "16 components touch the DOM at render time"; parsing the
// modules instead of grepping them put the real number at zero. What would break
// is an access in setup scope or inside a `computed()` — those run during SSR and
// during any render, so they throw on a server and in a DOM-less test.
//
// This is a ratchet at zero: the rule is cheap to keep and silent to lose.
import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { parse as parseSfc } from "@vue/compiler-sfc";
import { parse as parseJs } from "@babel/parser";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const source = join(root, "packages/vue-im-ui/src");
const GLOBALS = new Set(["window", "document"]);
// Handing a function to one of these defers it past setup, so a DOM access inside
// is a client-only access by construction.
const DEFERRED = new Set([
  "onMounted", "onBeforeMount", "onUpdated", "onBeforeUpdate", "onUnmounted",
  "onBeforeUnmount", "onActivated", "onDeactivated", "onErrorCaptured", "nextTick",
  "requestAnimationFrame", "requestIdleCallback", "setTimeout", "setInterval",
  "watch", "watchEffect", "then", "catch", "finally",
]);

function files(directory) {
  const out = [];
  for (const entry of readdirSync(directory)) {
    const path = join(directory, entry);
    if (statSync(path).isDirectory()) out.push(...files(path));
    else if (/\.vue$/.test(entry) || (/\.ts$/.test(entry) && !/\.test\.ts$/.test(entry))) out.push(path);
  }
  return out;
}

function scriptOf(file) {
  const text = readFileSync(file, "utf8");
  if (!file.endsWith(".vue")) return text;
  const { descriptor } = parseSfc(text, { filename: file });
  return [descriptor.scriptSetup?.content, descriptor.script?.content].filter(Boolean).join("\n");
}

const errors = [];
let scanned = 0;
let deferredAccesses = 0;
for (const file of files(source)) {
  const code = scriptOf(file);
  if (!/\b(window|document)\b/.test(code)) continue;
  scanned += 1;
  let ast;
  try {
    ast = parseJs(code, { sourceType: "module", plugins: ["typescript"], errorRecovery: true });
  } catch (error) {
    errors.push(`${relative(root, file)}: could not be parsed (${error.message})`);
    continue;
  }

  const scopes = [{ shadowed: new Set(), kind: "module" }];
  const guarded = new Set();
  const declare = (node) => {
    if (node?.type === "Identifier" && GLOBALS.has(node.name)) scopes.at(-1).shadowed.add(node.name);
    if (node?.type === "ObjectPattern") node.properties.forEach((p) => declare(p.value ?? p.argument));
    if (node?.type === "ArrayPattern") node.elements.forEach((e) => e && declare(e));
  };
  const shadowed = (name) => scopes.some((scope) => scope.shadowed.has(name));

  (function walk(node, parent) {
    if (!node || typeof node.type !== "string") return;
    if (node.type === "UnaryExpression" && node.operator === "typeof" &&
        node.argument?.type === "Identifier" && GLOBALS.has(node.argument.name)) {
      guarded.add(node.argument.name);
    }
    const isFunction = /Function(Declaration|Expression)$|^ArrowFunctionExpression$/.test(node.type);
    if (isFunction) {
      const callee = parent?.type === "CallExpression" ? parent.callee : null;
      const name = callee?.type === "Identifier" ? callee.name
        : callee?.type === "MemberExpression" && callee.property?.type === "Identifier" ? callee.property.name
        : null;
      // `computed(() => …)` is evaluated by the renderer, so it is NOT deferred.
      scopes.push({ shadowed: new Set(), kind: name && DEFERRED.has(name) ? "deferred" : name === "computed" ? "render" : "call-site-unknown" });
      node.params?.forEach(declare);
    }
    if (node.type === "VariableDeclarator") declare(node.id);
    if (node.type === "Identifier" && GLOBALS.has(node.name)) {
      const isPropertyName = parent?.type === "MemberExpression" && parent.property === node && !parent.computed;
      const isKey = parent?.type === "ObjectProperty" && parent.key === node && !parent.computed;
      if (!isPropertyName && !isKey && !shadowed(node.name)) {
        const deferred = scopes.some((scope) => scope.kind === "deferred");
        if (deferred) deferredAccesses += 1;
        else if (!guarded.has(node.name)) {
          const where = scopes.length === 1 ? "setup scope"
            : scopes.some((scope) => scope.kind === "render") ? "a computed(), which the renderer evaluates"
            : null;
          if (where) {
            errors.push(`${relative(root, file)}:${node.loc?.start.line} — \`${node.name}\` is read in ${where}; move it into onMounted/an event handler, or guard it with \`typeof ${node.name} === "undefined"\``);
          }
        }
      }
    }
    for (const key of Object.keys(node)) {
      if (key === "loc" || key === "leadingComments" || key === "trailingComments") continue;
      const value = node[key];
      if (Array.isArray(value)) value.forEach((child) => child && typeof child.type === "string" && walk(child, node));
      else if (value && typeof value.type === "string") walk(value, node);
    }
    if (isFunction) scopes.pop();
  })(ast.program, null);
}

if (errors.length) {
  console.error(`ssr safety check failed (${errors.length})`);
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}
console.log(`ssr safety check passed: ${scanned} module(s) touch window/document, all of it after mount or behind a guard (${deferredAccesses} deferred accesses)`);
