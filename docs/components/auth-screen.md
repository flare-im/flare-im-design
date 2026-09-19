# Authentication Screen (reference application)

> **Not part of `@flare-im/vue-ui`.** Since 2.0 this screen is product code in the
> reference application —
> `flare-im-core-client-sdk/examples/shared/vue-reference/workbench/app/components/AuthScreen.vue`.
> The kit no longer exports `FlareAuthScreen` (see
> `docs/release/public-api-2.0.md` §2 and the migration guide). It is composed
> from public kit parts — `FlareFormField`, `FlareInput`, `FlareSelect`,
> `FlareButton`, `FlareIcon`, `FlareBrandLogo` — and restyles them only through the
> `--flare-component-form-label-*` and `--flare-component-brand-logo-shadow` seams.
> The notes below describe that reference screen.

The reference `AuthScreen` owns the Vue/Web/Tauri login presentation. Hosts supply
identity and gateway values, loading state, visible connection fields, and the
login handler. Authentication, persistence, SDK initialization, and errors remain
host responsibilities.

## Visual Hierarchy

- Desktop has two full-height regions: a softly tinted brand area with an
  unframed technology illustration, and a login form capped at 400px.
- The violet optical-interconnect artwork is a decorative transparent WebP,
  shipped with the shared kit. Its 3:2 geometry is reserved before loading; it
  has no controls, simulated messages, credentials, or session dependencies.
- Identity and the primary login action come before optional connection settings.
- Brand color is inherited from theme tokens; the Core Web App uses violet.
- Connection settings expand inline without another card or contrasting panel.
- Security information remains secondary. No promotional feature list.

## Adaptation And States

- At 900px and above, the brand and form regions balance the desktop canvas.
  Below 900px the artwork is hidden and login returns to a single column. Phones
  start near the top with safe-area padding.
- Short viewports and expanded settings scroll naturally without horizontal overflow.
- Shared neutral/color tokens support light and dark modes. Chinese and English
  use the same layout, with wrapping for long labels and notes.
- Empty identities and loading disable submission, including keyboard submission.
- Field descriptions, section headings, disclosure state, and keyboard focus have
  accessible semantics. Gateway values stay owned by the host when collapsed.
- Core Web App exposes only WebSocket and HTTP gateways. Other hosts retain the
  complete existing transport/token configuration contract.

## Verification

- `AuthScreen.test.ts` (reference app, next to the component): field binding, disclosure, accessible references,
  empty/loading submission, retry, and the full default field contract.
- Core Web App `tests/e2e/login-surface.spec.ts`: keyboard flow, retained gateway
  edits, 320–1920px widths, short viewport, two locales, and light/dark themes.
- Native Android, iOS, and Flutter authentication layouts are not changed by this
  Vue presentation refinement; this is not a claim of native visual parity.

Artwork provenance and the generation prompt are stored in
`packages/vue-im-ui/src/assets/brand/README.md`.
