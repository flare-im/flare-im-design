---
title: Composer
outline: [2, 3]
prev: false
next: false
---

# Composer

<!-- flare-component-reference:start -->

<ComponentReference name="Composer" />

<!-- flare-component-reference:end -->

## Surface Anatomy

`FlareComposer` 只有一个视觉表面所有者：`[data-flare-surface-owner="composer"]`。它独立负责编辑器背景、外边框、圆角和完整焦点环。

- **Context**：回复、编辑与附件预览位于表面内部，不重绘外角。
- **Input**：纯文本与富文本编辑器继承表面；默认一行，最多自动增长到六行后内部滚动。
- **Format**：富文本条是透明内部区域，以内缩语义分隔线划分。
- **Action bar**：动作使用稳定点击区域；位于输入区下方时使用内缩分隔线。
- **Focus**：`:focus-within` 高亮完整表面，内部控件不能用局部边线代替焦点状态。

<ComposerSurfaceRegression />

