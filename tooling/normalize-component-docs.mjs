#!/usr/bin/env node
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const spec = JSON.parse(readFileSync(join(root, "spec/components.json"), "utf8"));
const slug = (name) => name.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
const errors = [];
let changed = 0;

function composerSurfaceAnatomy(localeDir) {
  if (localeDir === "website/components") {
    return `
## Surface Anatomy

\`FlareComposer\` 只有一个视觉表面所有者：\`[data-flare-surface-owner="composer"]\`。它独立负责编辑器背景、外边框、圆角和完整焦点环。

- **Context**：回复、编辑与附件预览位于表面内部，不重绘外角。
- **Input**：纯文本与富文本编辑器继承表面；默认一行，最多自动增长到六行后内部滚动。
- **Format**：富文本条是透明内部区域，以内缩语义分隔线划分。
- **Action bar**：动作使用稳定点击区域；位于输入区下方时使用内缩分隔线。
- **Focus**：\`:focus-within\` 高亮完整表面，内部控件不能用局部边线代替焦点状态。

<ComposerSurfaceRegression />
`;
  }

  return `
## Surface Anatomy

\`FlareComposer\` has one visual surface owner: \`[data-flare-surface-owner="composer"]\`. That element alone paints the editor background, outer border, radius, and complete focus ring.

- **Context**: reply, edit, and attachment previews stay inside the surface and do not redraw its outer corners.
- **Input**: plain and rich editors inherit the surface; they start at one line and grow to six lines before scrolling internally.
- **Format**: the rich-text strip is a transparent internal region separated by an inset semantic divider.
- **Action bar**: actions use stable hit targets and an inset divider when placed below the input.
- **Focus**: \`:focus-within\` highlights the complete surface. An internal control never substitutes a partial edge for focus.

<ComposerSurfaceRegression />
`;
}

function canonicalPage(component, localeDir) {
  const extra = component.name === "Composer" ? composerSurfaceAnatomy(localeDir) : "";
  return `---
title: ${component.name}
outline: [2, 3]
prev: false
next: false
---

# ${component.name}

<!-- flare-component-reference:start -->

<ComponentReference name="${component.name}" />

<!-- flare-component-reference:end -->
${extra}
`;
}

for (const localeDir of ["website/components", "website/en/components"]) {
  for (const component of spec.components) {
    const path = join(root, localeDir, `${slug(component.name)}.md`);
    if (!existsSync(path)) {
      errors.push(`missing component page: ${localeDir}/${slug(component.name)}.md`);
      continue;
    }
    const source = readFileSync(path, "utf8");
    const next = canonicalPage(component, localeDir);
    if (source === next) continue;
    if (process.argv.includes("--check")) errors.push(`component reference is stale: ${localeDir}/${slug(component.name)}.md`);
    else {
      writeFileSync(path, next);
      changed += 1;
    }
  }
}

if (errors.length) {
  console.error("component documentation normalization failed:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
console.log(`component documentation ${process.argv.includes("--check") ? "current" : "normalized"}: ${spec.components.length * 2} pages (${changed} changed)`);
