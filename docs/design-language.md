# Flare UI Design Language

Flare UI is a clean, calm, modern, professional IM system. It is content-first and task-first, with low cognitive load, high information clarity, and consistent semantics across Vue, Flutter, Android Compose, and SwiftUI. Platform presentation may differ; product meaning must not.

## Core principles

1. **Content before chrome.** Conversation, message, and task content own the visual center.
2. **Task before decoration.** Every visible control must advance or clarify a user task.
3. **Hierarchy before color.** Size, weight, placement, and spacing establish order before accent color.
4. **Spacing before borders.** Separate related regions with rhythm before adding rules.
5. **Grouping before cards.** Use lists, sections, and alignment before introducing containers.
6. **Semantic colors.** Components consume role-based tokens, never palette identities.
7. **Minimal elevation.** Shadows are reserved for popovers, menus, dialogs, drawers, floating panels, and call overlays.
8. **Predictable interaction.** Hover, focus, pressed, selected, disabled, loading, and error states follow one grammar.
9. **High-frequency actions visible.** Send, search, reply, and primary navigation remain discoverable.
10. **Low-frequency actions contextual.** Destructive and advanced actions live in menus, sheets, or progressive disclosure.
11. **Sensible defaults.** A normal IM works without assembling configuration objects.
12. **Progressive disclosure.** Advanced controls appear only when the task requires them.
13. **Accessibility by default.** Labels, focus, contrast, touch targets, reduced motion, and scalable text are contract requirements.
14. **Responsive by design.** Semantics survive presentation changes from multi-pane PC to single-pane mobile.
15. **Configuration over hardcoding.** Capabilities and host-owned item lists decide business availability.
16. **Composition over giant components.** Focused primitives and targeted extension points build complex experiences.

## Visual system

### Typography

| Role | Purpose |
|---|---|
| display | Product-level identity only, never compact application panels |
| titleLarge | Workspace or route title |
| titleMedium | Major section or detail heading |
| titleSmall | Row group, sheet, or popover heading |
| bodyLarge | Long-form or emphasized message content |
| bodyMedium | Default UI and message content |
| bodySmall | Secondary explanations and metadata |
| labelLarge | Primary button and prominent control |
| labelMedium | Menu, tab, and compact control |
| labelSmall | Dense auxiliary control |
| caption | Time, delivery state, hint, and supporting metadata |

Components use semantic typography tokens. Local font sizes are allowed only where a platform primitive cannot consume a token directly, and then must map to the same named scale.

### Spacing

Use the shared spacing scale for inset, stack, and inline rhythm. Prefer xs, sm, md, lg, and xl relationships over one-off values. Dense components may use compact tokens, but unrelated values such as 13, 17, 19, or 22 must not become local spacing systems.

### Radius

| Token | Typical use |
|---|---|
| xs | Tiny indicators and dense utility surfaces |
| sm | Inputs, menu rows, compact controls |
| md | Buttons, list selection, message attachments |
| lg | Sheets, dialogs, composer panels |
| xl | Rare large media or immersive surfaces |
| full | Avatars, circular icon buttons, badges, and intentional pills |

Large radius is not a default. A row or page section does not become a card merely because it contains grouped content.

### Border and surface

Primary surfaces carry content. Secondary surfaces group tools. Tertiary surfaces distinguish timeline or background context. Borders use semantic border tokens and are one logical pixel unless focus or validation requires stronger emphasis. Selected state uses bgSelected plus readable foreground; hover uses bgHover; neither introduces a new brand color.

### Surface integrity

1. One visual object has one surface owner and one border owner.
2. Radius follows surface ownership; internal sections do not redraw the outer radius.
3. Context, content, and action regions remain transparent unless they are independently elevated objects.
4. Focus is expressed around the complete surface, never as an unexplained partial edge.
5. Internal dividers are inset from rounded corners and use semantic border tokens.
6. Child backgrounds must not cover the antialiased pixels of a parent border.
7. Clipping is intentional and limited to media or content that must conform to the owning radius; focus rings, menus, tooltips, and shadows must remain visible.
8. Surface geometry is checked in light and dark themes, at browser zoom, and on both standard and high-density displays.

### Elevation

Elevation communicates stacking, not importance. Normal panes, rows, settings sections, messages, and content bands remain flat. Popovers, menus, dialogs, drawers, floating panels, and call overlays may use the shared elevation scale.

### Icons

Use semantic icon names and the sm, md, or lg scale. Icons align to text baselines or the center of a stable touch target. Stroke style stays consistent within a platform. Decorative icons are hidden from assistive technology; icon-only actions require a localized label and tooltip where hover exists.

### Density

comfortable, default, and compact apply only to repeated operational surfaces such as Button, Input, Menu, Navigation, ConversationItem, List, and Table. Density changes spacing and control height without shrinking touch targets below the accessibility contract or changing business capability.

### Motion

Motion is functional: it preserves spatial continuity, confirms state change, or explains entry and exit. Use shared fast/default/slow durations and standard easing. Reduced-motion mode removes non-essential translation, scale, pulse, and autoplay while preserving immediate state feedback.

## State grammar

| State | Expression |
|---|---|
| Default | Primary semantic surface and foreground |
| Hover | Subtle hover surface, no layout movement |
| Focus | Shared focus ring with visible offset |
| Pressed | Stronger surface or opacity feedback, no resize |
| Selected | Selected semantic surface plus selected foreground |
| Disabled | Remains legible, blocks intent, exposes reason where needed |
| Loading | Stable dimensions, progress semantics, duplicate intent blocked |
| Error | Error role near the failed task with a recovery path |
| Empty | Explains absence and offers the next relevant action |

## IM product grammar

- Incoming and outgoing messages share typography and spacing; direction changes alignment and semantic surface.
- Delivery state is secondary metadata. Read state uses the current brand semantic token and remains distinguishable without color alone.
- Composer defaults are Image, File, Voice, Location, and Contact. Camera is optional. Poll, Task, Event, and MiniApp are advanced host capabilities.
- Message, conversation, navigation, contact, and composer actions use stable IDs, visible/enabled state, order, intent, accessibility label, and targeted domain fields.
- Business availability comes from capabilities. UI components do not infer permissions from current-user role, sender identity, or SDK models.
- Built-in message renderers cover common IM content. A renderer registry accepts host types such as OrderCard, PaymentCard, ProductCard, RobotCard, and ApprovalCard without expanding MessageBubble switches.

## Responsive grammar

PC favors hover, keyboard, context menus, tooltips, multi-pane context, drag, and resize. Mobile/H5 favors touch, long press, bottom sheets, swipe, safe areas, and soft-keyboard continuity. Both use the same action lists, renderer registration, selection, and capability contracts.

Responsive decisions follow the component container, not device names. Text wraps, fixed-format controls retain stable dimensions, and active tasks are not obscured by overlays, safe areas, or the keyboard.

## Extension model

Complex components resolve:

**Library Defaults → Capabilities → Host Configuration → Final Presentation**

A host list is a full replacement when removal and ordering must be explicit. Targeted extension points cover Header, Footer, Leading, Trailing, Empty, Loading, Error, Message Renderer, Composer Action, and Navigation Item. Vue uses slots, Flutter uses widgets/builders, Compose uses composable lambdas, and SwiftUI uses ViewBuilder or view values. Extension points do not expose every pixel.

## Anti-AI restraint

Avoid nested cards, decorative gradients, floating pill labels, excessive shadows, ornamental blobs, oversized headings in tools, invented metrics, and explanatory text that describes the interface instead of serving the task. A Flare screen should look authored for messaging work: dense enough to scan, calm enough to stay in all day, and specific enough that content remains the strongest signal.

## Governance

The component contract and generated tokens are the source of truth. Public components must pass raw-color, token, signature, accessibility, responsive, documentation, and platform tests. New visual roles require a cross-platform need; new business actions or message types should prefer host configuration or registries.
