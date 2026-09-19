# Component Library Maturity

The machine-readable source is `spec/component-maturity.json`. It inventories 64 General capabilities and 86 IM capabilities with four current statuses: `existing`, `composition`, `partial`, and `missing`.

## Decision Rule

1. Reuse an existing public component when its behavior matches.
2. Document a composition when the capability is an arrangement of stable primitives.
3. Extend an existing component when the missing behavior belongs to its responsibility.
4. Add a primitive only when the existing API cannot form a coherent reusable contract.

Names in the capability inventory are search terms, not public aliases. Only symbols exported by a platform package are public API.

## Current Gaps

There are no missing P0 or P1 capabilities. P2 General gaps are SplitButton, Accordion, Collapsible, Tree, and MenuBar. Combobox, inline edit, password input, upload zone, and drop zone remain partial. P3 gaps include Breadcrumb, TreeSelect, and ColorPicker.

P2 IM gaps are calendar-event, mini-app, topic, and merged-forward message bodies. Other partial capabilities remain explicit so package maturity is not inferred from symbol count.

## Ownership

The kit owns presentation, focus, selection affordances, responsive composition, and deterministic UI state reduction. The host supplies authoritative delivery and lifecycle state and owns command execution, navigation, persistence, capability checks, and permissions.

Run `node tooling/check-maturity.mjs` to prevent duplicate capabilities, missing high-priority coverage, boolean API explosion, or undocumented platform gaps.
