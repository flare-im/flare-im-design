# Developer Experience

## Public API rules

- Use controlled value/state plus intent callbacks for navigation, selection, command execution, upload, and message actions.
- Prefer enums or sealed modes over families of overlapping booleans.
- Keep platform names idiomatic while mapping them to one contract in `spec/components.json`.
- Put reusable visual capability in the design kit; keep product apps focused on Core binding and business composition.
- Accept slot/builder/content closures only at documented composition boundaries.
- Localizable user-facing strings are required inputs or come from the platform string provider.

## Adding capability

1. Search `spec/component-maturity.json` for an existing, alias, or composition target.
2. Update `spec/components.json` before exposing a new cross-platform contract.
3. Implement the smallest shared behavior on all required platforms.
4. Add interaction reducer tests and a real Gallery scenario.
5. Add or update a component guide under `docs/components`.
6. Run `node tooling/check-design-system.mjs` and all affected platform suites.

## Generated sources

`spec/build-maturity-model.mjs` generates maturity, interaction, and composition models. `spec/build-component-layers.mjs` generates ownership layers. `tooling/build-component-guides.mjs` generates the 14 core guides. Generated artifacts are checked in and verified with `--check`-style gates rather than silently regenerated in CI.

## Boundary rule

UI packages may depend on tokens and their public UI models. Core models enter through adapters. Components must not import application stores, networking, persistence, or SDK internals. See `docs/package-boundaries.md` and `docs/ui-component-reuse-policy.md`.
