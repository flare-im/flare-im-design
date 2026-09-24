#!/usr/bin/env node
/**
 * Semantic colours come in pairs: a fill (`primary`, `error`, `success`, `info`, `warning`) and the colour
 * that same meaning takes as text (`primaryText`, `errorText`, …). The pair exists because a fill that reads
 * well as a block of colour does not read well as 12px type — and in dark mode the two diverge completely:
 * the brand fill is #7047D6 in both themes, which is 2.66:1 on the dark page, while `primaryText` lightens
 * to #C4B5FD and reads at 8.5:1.
 *
 * Using the wrong one of the pair is invisible on this repository's usual paths: it type-checks, it renders,
 * and until Round 6 the accessibility sweep only ever scanned light mode. So this gate reads the two
 * mistakes directly — a fill used as a foreground, and a text colour used as a fill — and requires none of
 * either. The web has an axe sweep over both themes as well; the three native kits have only this.
 */
import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join, relative, resolve } from "node:path";

const root = resolve(new URL("..", import.meta.url).pathname);
const FAMILIES = ["primary", "error", "success", "info", "warning"];

function walk(dir, exts, out = []) {
  if (!existsSync(dir)) return out;
  for (const entry of readdirSync(dir)) {
    if (entry === "node_modules" || entry === "build" || entry === "dist" || entry.startsWith(".")) continue;
    const full = join(dir, entry);
    const info = statSync(full);
    if (info.isDirectory()) walk(full, exts, out);
    else if (exts.some((ext) => entry.endsWith(ext))) out.push(full);
  }
  return out;
}

/** The construct a match sits inside, e.g. `TextStyle` for `TextStyle(color: …)`. */
function enclosing(text, index) {
  let depth = 0;
  let i = index;
  while (i > 0) {
    const c = text[i];
    if (c === ")") depth += 1;
    else if (c === "(") {
      if (depth === 0) break;
      depth -= 1;
    }
    i -= 1;
  }
  const head = text.slice(Math.max(0, i - 60), i).match(/([A-Za-z_][\w.]*)\s*$/);
  return head ? head[1] : "?";
}

const group = FAMILIES.join("|");
const findings = [];
function report(file, index, text, message) {
  const line = text.slice(0, index).split("\n").length;
  findings.push(`${relative(root, file)}:${line} ${message}`);
}

function scan(files, rules) {
  for (const file of files) {
    const text = readFileSync(file, "utf8");
    for (const rule of rules) {
      for (const match of text.matchAll(rule.pattern)) {
        if (rule.within && !rule.within.includes(enclosing(text, match.index))) continue;
        report(file, match.index, text, rule.message(match));
      }
    }
  }
}

/**
 * The construct check above only sees a token written straight into the slot. A fill reached through an
 * expression — `color = if (draft) colors.primaryText else colors.error` — walks past it, which is exactly
 * how one was found while this gate was being reverse-validated. So every line that paints a foreground is
 * read as well: if it names a fill anywhere, it is reported.
 *
 * 「涂色的那一行」还不够。前景色常常先落进一个**变量**,过二十行才画出去 —— ghost / text 按钮
 * 在 iOS / Compose / Flutter 上同时用了 `colors.primary` 当文字色(暗色下 2.66:1,AA 正文要 4.5),
 * 三处都从这里溜过去了:Swift 写在 `private func fg(...) -> Color` 的 `return` 里、Kotlin 装进
 * 一个 `Triple` 再解构成 `fg`、Dart 赋给局部 `foreground`。所以「名字就说明自己是前景色」的
 * 变量,赋值与 return 也当作涂色点。
 */
/** 名字就说明自己是前景色的变量:赋给它、或从这样命名的函数里 return,都算一次涂色。 */
const FOREGROUND_SLOTS = ["fg", "foreground", "textColor", "labelColor", "contentColor", "tintColor"];
const FOREGROUND_ASSIGN = FOREGROUND_SLOTS.map((n) => new RegExp(`\\b${n}\\b\\s*[=:]`));
const FOREGROUND_DECL = new RegExp(`\\b(?:func|let|var|val)\\s+(?:${FOREGROUND_SLOTS.join("|")})\\b`, "i");
/**
 * `return colors.X` 只有在外层声明「自己就是前景色」时才算涂色 —— 否则一个
 * `let badge: Color = { ... return colors.error }` 也会被当成文字色报出来,而它画的是底。
 * 判据向上找最近的声明行,窗口 12 行足够盖住一个 switch 或 when。
 */
function returnsForeground(lines, index) {
  if (!/\breturn\s+colors\./.test(lines[index])) return false;
  for (let i = index; i >= Math.max(0, index - 12); i -= 1) if (FOREGROUND_DECL.test(lines[i])) return true;
  return false;
}

function scanLines(files, markers, message) {
  const fill = new RegExp(`colors\\.(${group})(?!Text)\\b`);
  for (const file of files) {
    const text = readFileSync(file, "utf8");
    let offset = 0;
    const lines = text.split("\n");
    for (let lineNo = 0; lineNo < lines.length; lineNo += 1) {
      const line = lines[lineNo];
      const paints = markers.some((marker) => line.includes(marker))
        || FOREGROUND_ASSIGN.some((re) => re.test(line))
        || returnsForeground(lines, lineNo);
      if (paints) {
        const found = line.match(fill);
        if (found) report(file, offset + found.index, text, message(found));
      }
      offset += line.length + 1;
    }
  }
}

const web = [
  ...walk(join(root, "packages/vue-im-ui/src"), [".vue", ".css"]),
  ...walk(join(root, "website/.vitepress"), [".vue", ".css"]),
];
scan(web, [
  {
    pattern: new RegExp(`(?<![-\\w])color\\s*:\\s*[^;{}]*?var\\(--flare-color-(${group})\\)`, "g"),
    message: (m) => `text painted with the ${m[1]} fill — use var(--flare-color-${m[1]}-text)`,
  },
  {
    pattern: new RegExp(`background(?:-color)?\\s*:\\s*[^;{}]*?var\\(--flare-color-(${group})-text\\)`, "g"),
    message: (m) => `fill painted with the ${m[1]} text colour — use var(--flare-color-${m[1]})`,
  },
]);

scan(walk(join(root, "packages/flutter-im-ui/lib"), [".dart"]), [
  {
    pattern: new RegExp(`color:\\s*colors\\.(${group})\\b`, "g"),
    within: ["TextStyle", "Icon", "FlareIcon"],
    message: (m) => `text painted with the ${m[1]} fill — use colors.${m[1]}Text`,
  },
  {
    pattern: new RegExp(`color:\\s*colors\\.(${group})Text\\b`, "g"),
    within: ["BoxDecoration", "Container", "ColoredBox"],
    message: (m) => `fill painted with the ${m[1]} text colour — use colors.${m[1]}`,
  },
]);

scanLines(
  walk(join(root, "packages/flutter-im-ui/lib"), [".dart"]),
  ["TextStyle(", "Icon(", "FlareIcon("],
  (m) => `text painted with the ${m[1]} fill — use colors.${m[1]}Text`,
);

scan(walk(join(root, "packages/ios-im-ui/Sources"), [".swift"]), [
  {
    pattern: new RegExp(`\\b(?:foregroundColor|foregroundStyle|tint)\\(colors\\.(${group})\\)`, "g"),
    message: (m) => `text painted with the ${m[1]} fill — use colors.${m[1]}Text`,
  },
  {
    pattern: new RegExp(`\\.background\\(colors\\.(${group})Text\\)`, "g"),
    message: (m) => `fill painted with the ${m[1]} text colour — use colors.${m[1]}`,
  },
]);

scanLines(
  walk(join(root, "packages/ios-im-ui/Sources"), [".swift"]),
  ["foregroundColor(", "foregroundStyle(", ".tint("],
  (m) => `text painted with the ${m[1]} fill — use colors.${m[1]}Text`,
);

scan(walk(join(root, "packages/android-im-ui/src/main"), [".kt"]), [
  {
    pattern: new RegExp(`\\bcolor\\s*=\\s*colors\\.(${group})\\b`, "g"),
    within: ["Text", "SpanStyle"],
    message: (m) => `text painted with the ${m[1]} fill — use colors.${m[1]}Text`,
  },
  {
    pattern: new RegExp(`\\btint\\s*=\\s*colors\\.(${group})\\b`, "g"),
    message: (m) => `icon painted with the ${m[1]} fill — use colors.${m[1]}Text`,
  },
  {
    pattern: new RegExp(`\\.background\\(colors\\.(${group})Text\\)`, "g"),
    message: (m) => `fill painted with the ${m[1]} text colour — use colors.${m[1]}`,
  },
]);

scanLines(
  walk(join(root, "packages/android-im-ui/src/main"), [".kt"]),
  ["color =", "tint =", "SpanStyle("],
  (m) => `text painted with the ${m[1]} fill — use colors.${m[1]}Text`,
);

if (findings.length > 0) {
  for (const finding of findings) console.error(`FAIL ${finding}`);
  console.error(`semantic colour pairs: ${findings.length} place(s) use the wrong half of a pair`);
  process.exit(1);
}
console.log("semantic colour pairs passed: no fill used as text, no text colour used as a fill (4 kits + docs site)");
