# Cross-platform Component Contract

`spec/components.json` owns two complementary contracts:

- `components`: executable public signatures, states, events, platform symbols, and accessibility metadata.
- `componentContracts`: visual, behavior, state, accessibility, content, responsive, focus, keyboard, and platform-difference policy for the priority General and IM vocabulary.

An alias is intentional vocabulary convergence, not a duplicate implementation. Examples include `Search -> SearchBar`, `ConversationItem -> ConversationRow`, `ReplyPreview -> ComposerReplyStrip`, and `Reaction -> ReactionSummary`. A planned entry documents the target contract but is not counted as a shipped component.

## Rules

Visual parity means semantic token and hierarchy parity, not identical pixels. Behavior uses controlled values and intent callbacks; protocol, persistence, upload, and routing stay in Core or the host. Loading must preserve geometry. Disabled controls suppress intent. Error and empty states remain distinct. Long text and large text reflow without overlap.

Every interactive component exposes a role, accessible name, state/value, visible focus, keyboard path, 48 logical-pixel minimum target where applicable, and reduced-motion behavior. Platform-native presentation is retained for dialogs, drawers, menus, scrolling, text input, and system accessibility.

The completeness gate is `node tooling/check-component-contracts.mjs`. Public signature drift remains independently enforced by `node spec/signature-report.mjs --json`.
