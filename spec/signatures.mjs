// 四端公共签名提取与契约比对。
//
// validate.mjs 长期只校验「符号存在」，props 与三端事件从不校验，契约因此可以声明
// 实现里根本没有的 props（ChatHeader 0/3、MessageActionSheet 0/4 端）而没人发现。
// 这里把四端的公共签名（Vue defineProps/defineEmits/defineModel、Flutter 构造参数、
// SwiftUI public init 参数、Compose 函数参数）提取出来，与契约逐项比对。
//
// 平台惯用名不强改：契约 `eventAliases`/`lexicon` 与组件级 `platformAliases` 记录
// 合法映射；prop 级 `platforms` 字段限定只在某些端存在的 prop。剩余差异记在
// signature-baseline.json 里做棘轮——只允许减少，任何新增差异都会让校验红。
import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join } from "node:path";

export const PLATFORMS = ["vue", "flutter", "ios", "compose"];

// ── 通用 ────────────────────────────────────────────────────────────────
export function stripComments(src, style = "c") {
  // 去掉 // 与 /* */ 注释（保留字符串内容不做解析——签名里不会出现含 // 的字符串）
  let out = "";
  let i = 0;
  while (i < src.length) {
    const two = src.slice(i, i + 2);
    if (two === "//") {
      while (i < src.length && src[i] !== "\n") i++;
    } else if (two === "/*") {
      const end = src.indexOf("*/", i + 2);
      i = end === -1 ? src.length : end + 2;
    } else if (style === "vue" && two === "<!") {
      const end = src.indexOf("-->", i);
      i = end === -1 ? src.length : end + 3;
    } else {
      out += src[i++];
    }
  }
  return out;
}

function walkFiles(root, ext) {
  const out = [];
  if (!existsSync(root)) return out;
  for (const name of readdirSync(root)) {
    const p = join(root, name);
    const st = statSync(p);
    if (st.isDirectory()) out.push(...walkFiles(p, ext));
    else if (p.endsWith(ext)) out.push(p);
  }
  return out;
}

/** 从 index 处取一段括号平衡的块（index 指向开括号），返回块内文本与结束位置。 */
function balanced(src, index, open, close) {
  let depth = 0;
  for (let j = index; j < src.length; j++) {
    const ch = src[j];
    if (ch === open) depth++;
    else if (ch === close) {
      // TS 泛型里的 `=>` 不是闭合
      if (close === ">" && src[j - 1] === "=") continue;
      if (--depth === 0) return { text: src.slice(index + 1, j), end: j };
    }
  }
  return null;
}

/** 按顶层逗号切分参数列表；`->` / `=>` 里的 `>` 不计深度。 */
function splitTopLevel(text) {
  let depth = 0, seg = "", segs = [];
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if ("([<{".includes(ch)) depth++;
    else if (")]}".includes(ch)) depth--;
    else if (ch === ">" && text[i - 1] !== "-" && text[i - 1] !== "=") depth--;
    if (ch === "," && depth === 0) { segs.push(seg); seg = ""; } else seg += ch;
  }
  segs.push(seg);
  return segs;
}

const camel = (n) => String(n).replace(/-([a-zA-Z])/g, (_, c) => c.toUpperCase());
const pascal = (n) => { const c = camel(n); return c.charAt(0).toUpperCase() + c.slice(1); };

// ── Vue ─────────────────────────────────────────────────────────────────
/** index.ts 的 `export { default as X } from "./a/B.vue"` → { X: 绝对路径 } */
export function vueExportMap(vueSrcRoot) {
  const indexPath = join(vueSrcRoot, "components/index.ts");
  const src = readFileSync(indexPath, "utf8");
  const map = {};
  for (const m of src.matchAll(/export\s*\{\s*default\s+as\s+([A-Za-z0-9_$]+)\s*\}\s*from\s*["']([^"']+)["']/g)) {
    map[m[1]] = join(vueSrcRoot, "components", m[2]);
  }
  return map;
}

/** 顶层 key 提取：在 `{ ... }` 文本里找深度 1 的 `name?:` / `name:` / `"name":` */
function topLevelKeys(block) {
  const names = new Set();
  let depth = 0;
  let lineStart = true;
  let i = 0;
  while (i < block.length) {
    const ch = block[i];
    if (ch === "{" || ch === "(" || ch === "[" || ch === "<") { depth++; i++; lineStart = false; continue; }
    if (ch === "}" || ch === ")" || ch === "]" || ch === ">") {
      if (ch === ">" && (block[i - 1] === "=" || block[i - 1] === "-")) { i++; lineStart = false; continue; }
      depth--; i++; continue;
    }
    if (ch === "\n" || ch === ";" || ch === ",") { lineStart = true; i++; continue; }
    if (depth === 0 && lineStart && !/\s/.test(ch)) {
      const m = block.slice(i).match(/^(?:readonly\s+)?(?:["'`]([^"'`]+)["'`]|([A-Za-z_$][\w$]*))\s*\??\s*:/);
      if (m) names.add(m[1] ?? m[2]);
      lineStart = false;
    } else if (!/\s/.test(ch)) lineStart = false;
    i++;
  }
  return names;
}

export function vueSurface(file) {
  const raw = readFileSync(file, "utf8");
  const src = stripComments(raw, "vue");
  const props = new Set();
  const events = new Set();
  // defineModel
  for (const m of src.matchAll(/defineModel\s*(?:<[^<>]*>)?\s*\(\s*(?:["'`]([^"'`]+)["'`])?/g)) {
    const name = m[1] ?? "modelValue";
    props.add(name);
    events.add(`update:${name}`);
  }
  // defineProps<{...}>() / defineProps({...}) / defineProps<Props>()
  let i = 0;
  while ((i = src.indexOf("defineProps", i)) !== -1) {
    i += "defineProps".length;
    while (/\s/.test(src[i])) i++;
    if (src[i] === "<") {
      const g = balanced(src, i, "<", ">");
      if (!g) break;
      let inner = g.text.trim();
      if (/^[A-Za-z_$][\w$]*$/.test(inner)) {
        // 引用类型别名/接口
        const decl = src.match(new RegExp(`(?:interface|type)\\s+${inner}\\s*=?\\s*\\{`));
        if (decl) {
          const b = balanced(src, decl.index + decl[0].length - 1, "{", "}");
          inner = b ? `{${b.text}}` : "";
        } else inner = "";
      }
      const b = inner.startsWith("{") ? balanced(inner, 0, "{", "}") : null;
      if (b) for (const k of topLevelKeys(b.text)) props.add(k);
      i = g.end;
    } else if (src[i] === "(") {
      const p = balanced(src, i, "(", ")");
      if (!p) break;
      const inner = p.text.trim();
      if (inner.startsWith("{")) {
        const b = balanced(inner, 0, "{", "}");
        if (b) for (const k of topLevelKeys(b.text)) props.add(k);
      } else if (inner.startsWith("[")) {
        for (const m of inner.matchAll(/["'`]([^"'`]+)["'`]/g)) props.add(m[1]);
      }
      i = p.end;
    }
  }
  // defineEmits
  i = 0;
  while ((i = src.indexOf("defineEmits", i)) !== -1) {
    i += "defineEmits".length;
    while (/\s/.test(src[i])) i++;
    let block = "";
    if (src[i] === "<") {
      const g = balanced(src, i, "<", ">");
      if (!g) break;
      block = g.text;
      i = g.end;
    } else if (src[i] === "(") {
      const p = balanced(src, i, "(", ")");
      if (!p) break;
      block = p.text;
      i = p.end;
    }
    if (!block) continue;
    for (const m of block.matchAll(/\(\s*[A-Za-z_$][\w$]*\s*:\s*["'`]([^"'`]+)["'`]/g)) events.add(m[1]);
    for (const m of block.matchAll(/(?:^|[;,{\n])\s*(?:["'`]([^"'`]+)["'`]|([A-Za-z_$][\w$-]*))\s*:\s*\[/g)) events.add(m[1] ?? m[2]);
    if (/^\s*\[/.test(block)) for (const m of block.matchAll(/["'`]([^"'`]+)["'`]/g)) events.add(m[1]);
  }
  return { props, events, file };
}

// ── Flutter ─────────────────────────────────────────────────────────────
function findFile(root, ext, regex) {
  for (const f of walkFiles(root, ext)) {
    if (regex.test(readFileSync(f, "utf8"))) return f;
  }
  return null;
}

export function flutterSurface(root, symbol) {
  const file = findFile(root, ".dart", new RegExp(`class ${symbol}\\b`));
  if (!file) return null;
  const src = stripComments(readFileSync(file, "utf8"));
  const props = new Set();
  const events = new Set();
  // 类体范围
  const classIdx = src.search(new RegExp(`class ${symbol}\\b`));
  const bodyStart = src.indexOf("{", classIdx);
  // 括号不平衡（字符串里的花括号）时退化为「声明之后的全部文本」
  const body = balanced(src, bodyStart, "{", "}") ?? { text: src.slice(bodyStart + 1) };
  // 构造函数（含 const / 命名构造）
  for (const m of body.text.matchAll(new RegExp(`(?:const\\s+)?${symbol}(?:\\.[A-Za-z_]\\w*)?\\s*\\(`, "g"))) {
    const p = balanced(body.text, m.index + m[0].length - 1, "(", ")");
    if (!p) continue;
    for (const pm of p.text.matchAll(/this\.([A-Za-z_]\w*)/g)) props.add(pm[1]);
    // 非 this. 的普通参数（少数：如 label 转发）
    for (const pm of p.text.matchAll(/(?:^|[,{(\n])\s*(?:required\s+)?(?:final\s+)?[A-Z][\w<>?, ]*\s+([a-z]\w*)\s*[,=})]/g)) props.add(pm[1]);
  }
  for (const n of props) if (/^on[A-Z]/.test(n)) events.add(n);
  return { props, events, file };
}

// ── iOS ─────────────────────────────────────────────────────────────────
export function iosSurface(root, symbol) {
  const file = findFile(root, ".swift", new RegExp(`(struct|enum|class)\\s+${symbol}\\b`));
  if (!file) return null;
  const src = stripComments(readFileSync(file, "utf8"));
  const props = new Set();
  const events = new Set();
  const declIdx = src.search(new RegExp(`(struct|enum|class)\\s+${symbol}\\b`));
  const bodyStart = src.indexOf("{", declIdx);
  const body = balanced(src, bodyStart, "{", "}") ?? { text: src.slice(bodyStart + 1) };
  let i = 0;
  const text = body.text;
  while ((i = text.indexOf("init(", i)) !== -1) {
    const p = balanced(text, i + "init".length, "(", ")");
    if (!p) break;
    // 参数：`label name: Type` 或 `name: Type`，逐段按顶层逗号切
    const segs = splitTopLevel(p.text);
    for (const s of segs) {
      const m = s.trim().match(/^(?:@\w+(?:\([^)]*\))?\s+)?(?:(_|[A-Za-z_]\w*)\s+)?([A-Za-z_]\w*)\s*:/);
      if (m) props.add(m[1] && m[1] !== "_" ? m[1] : m[2]);
    }
    i = p.end;
  }
  for (const n of props) if (/^on[A-Z]/.test(n) || n === "action") events.add(n);
  return { props, events, file };
}

// ── Compose ─────────────────────────────────────────────────────────────
export function composeSurface(root, symbol) {
  const file = findFile(root, ".kt", new RegExp(`(?<!private\\s)fun ${symbol}\\s*\\(`));
  if (!file) return null;
  const src = stripComments(readFileSync(file, "utf8"));
  const props = new Set();
  const events = new Set();
  for (const m of src.matchAll(new RegExp(`(?<!private\\s)fun ${symbol}\\s*\\(`, "g"))) {
    const p = balanced(src, m.index + m[0].length - 1, "(", ")");
    if (!p) continue;
    const segs = splitTopLevel(p.text);
    for (const s of segs) {
      const mm = s.trim().match(/^(?:@\w+\s+)*(?:vararg\s+|noinline\s+|crossinline\s+)?([A-Za-z_]\w*)\s*:/);
      if (mm) props.add(mm[1]);
    }
  }
  for (const n of props) if (/^on[A-Z]/.test(n)) events.add(n);
  return { props, events, file };
}

// ── 契约比对 ─────────────────────────────────────────────────────────────
/** 平台上一个契约事件可接受的回调名集合 */
function eventCandidates(spec, comp, event, platform) {
  const c = camel(event);
  const out = new Set();
  if (platform === "vue") {
    out.add(c); out.add(event);
    const va = comp.platformAliases?.vue?.events?.[c];
    if (va) for (const a of [].concat(va)) out.add(a);
    return out;
  }
  out.add(`on${pascal(c)}`);
  const alias = spec.eventAliases?.[c]?.[platform];
  if (alias) for (const a of alias) out.add(a);
  const compAlias = comp.platformAliases?.[platform]?.events?.[c];
  if (compAlias) for (const a of [].concat(compAlias)) out.add(a);
  if (c.startsWith("update:")) {
    // v-model 在原生端是 value + onXxxChange / onChanged
    out.add("onChanged"); out.add("onChange"); out.add("onValueChange"); out.add("onSelect"); out.add("onToggle");
  }
  return out;
}

/** 平台上一个契约 prop 可接受的参数名集合 */
function propCandidates(spec, comp, prop, platform) {
  const out = new Set([prop]);
  const lex = spec.lexicon?.[prop]?.[platform];
  if (lex) for (const a of [].concat(lex)) out.add(a);
  const compAlias = comp.platformAliases?.[platform]?.props?.[prop];
  if (compAlias) for (const a of [].concat(compAlias)) out.add(a);
  if (platform === "ios" && /Url$/.test(prop)) out.add(prop.replace(/Url$/, "URL"));
  return out;
}

/**
 * 比对一个组件在一个平台上的契约与实现。
 * 返回 { missingProps, missingEvents, extraEvents }（均为契约视角的名字）。
 */
export function compareComponent(spec, comp, platform, surface) {
  const missingProps = [];
  const missingEvents = [];
  const extraEvents = [];
  const declaredProps = (comp.props ?? []).filter((p) => !p.platforms || p.platforms.includes(platform));
  const declaredEvents = (comp.events ?? []).filter((e) => {
    const scope = comp.eventPlatforms?.[camel(e)];
    return !scope || scope.includes(platform);
  });
  const modelProp = comp.model?.prop;
  for (const p of declaredProps) {
    if (p.name === modelProp && platform !== "vue") continue; // 原生端 model prop 由 lexicon(modelValue) 覆盖
    const cands = propCandidates(spec, comp, p.name, platform);
    if (![...cands].some((n) => surface.props.has(n))) missingProps.push(p.name);
  }
  const bindingProps = new Set([...(modelProp ? propCandidates(spec, comp, modelProp, platform) : []), ...([].concat(spec.lexicon?.modelValue?.[platform] ?? []))]);
  const hasBinding = platform !== "vue" && [...bindingProps].some((n) => surface.props.has(n));
  for (const e of declaredEvents) {
    // 原生端用 Binding / 受控 value 表达 v-model 与 change：有绑定 prop 即视为已实现
    if (hasBinding && (e === "change" || (modelProp && e === `update:${modelProp}`))) continue;
    const cands = eventCandidates(spec, comp, e, platform);
    const have = platform === "vue" ? new Set([...surface.events].map(camel)) : surface.events;
    if (![...cands].some((n) => have.has(n) || have.has(camel(n)))) missingEvents.push(e);
  }
  // 反向：实现里的事件契约没记（只对 vue 精确；原生 onXxx 也报）
  const declaredNorm = new Set();
  for (const e of comp.events ?? []) for (const n of eventCandidates(spec, comp, e, platform)) declaredNorm.add(n);
  if (modelProp) declaredNorm.add(`update:${modelProp}`);
  const declaredPropNames = new Set(declaredProps.map((p) => p.name));
  const deprecated = new Set(comp.deprecatedCallbacks?.[platform] ?? []);
  for (const e of surface.events) {
    if (declaredPropNames.has(e)) continue; // 契约把它当 prop（如文案解析器 onText）
    if (deprecated.has(e)) continue; // 已标 deprecated 的旧回调名，等下个主版本删
    if (platform === "vue" && e.startsWith("update:")) {
      // v-model 事件由 model 字段覆盖；其它 update: 事件按普通事件处理
      if (modelProp && e === `update:${modelProp}`) continue;
    }
    const norm = platform === "vue" ? camel(e) : e;
    if (!declaredNorm.has(norm) && !declaredNorm.has(e)) extraEvents.push(e);
  }
  return { missingProps, missingEvents, extraEvents };
}

export function loadSurface(roots, comp, platform) {
  const sym = comp.platforms?.[platform]?.symbol;
  if (!sym) return null;
  if (platform === "vue") {
    const file = roots.vueExports[sym];
    return file && existsSync(file) ? vueSurface(file) : null;
  }
  if (platform === "flutter") return flutterSurface(roots.flutter, sym);
  if (platform === "ios") return iosSurface(roots.ios, sym);
  if (platform === "compose") return composeSurface(roots.compose, sym);
  return null;
}
