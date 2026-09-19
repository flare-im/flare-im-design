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

`FlareComposer` has one visual surface owner: `[data-flare-surface-owner="composer"]`. That element alone paints the editor background, outer border, radius, and complete focus ring.

- **Context**: reply, edit, and attachment previews stay inside the surface and do not redraw its outer corners.
- **Input**: plain and rich editors inherit the surface; they start at one line and grow to six lines before scrolling internally.
- **Format**: the rich-text strip is a transparent internal region separated by an inset semantic divider.
- **Action bar**: actions use stable hit targets and an inset divider when placed below the input.
- **Focus**: `:focus-within` highlights the complete surface. An internal control never substitutes a partial edge for focus.

<ComposerSurfaceRegression />

