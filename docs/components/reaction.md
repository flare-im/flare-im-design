# Reaction

## Overview
Show and toggle compact social acknowledgement with optimistic recovery.

## When to use
Show and toggle compact social acknowledgement with optimistic recovery.

## When not to use
Do not use decorative emoji badges without an action or count meaning.

## Anatomy
emoji, count, selected state, picker. Regions use semantic tokens and host-owned content.

## Variants
summary, quick reaction, picker. Choose one variant from task priority, not decoration.

## Sizes
In a reacted message, start the shared footer 4 logical units below the surface. Use 22 logical units as the minimum visual pill height and 4 between pills. Use a tinted fill and readable count for the viewer’s reactions. On touch surfaces, reserve a distinct target of at least 44 × 44 logical units for each pill and align the visible pill to its top. Keyboard and pointer users can activate the visible pill directly.

## States
idle, pickerOpen, optimistic, confirmed, failed. Loading preserves geometry; errors keep a recovery path.

## Interactions
Components emit intent callbacks. The host owns data, permissions, persistence, and side effects.

## Keyboard
Enter/Space toggles; arrow navigation applies inside picker.

## Accessibility
Provide a localized name, role, state, availability, focus order, visible focus, and reduced-motion equivalent. Decorative imagery is hidden.

## Responsive
Align reaction runs with the sender’s side. The timestamp and receipt sit at the trailing edge of the last run when they fit, or on a dedicated trailing line when space runs out. Reserve space for interactive receipt and retry targets so they do not overlap reactions. Unreacted messages use the ordinary metadata placement.

## Platform differences
Vue uses ARIA and pointer conventions; Flutter uses Semantics and Focus; Compose uses semantics and native gestures; SwiftUI uses accessibility traits, Dynamic Type, and native presentation. Semantic states and intents remain identical.

## Code examples
Use the public component named in `spec/components.json`; supply controlled state and intent callbacks. See the shared fixtures in `examples/gallery/gallery-manifest.json` for deterministic examples.

## Do / Don't
Do keep task hierarchy and recovery explicit. Don't duplicate business state, invent platform-only semantics, or introduce local visual constants.
