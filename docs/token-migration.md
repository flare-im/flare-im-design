# Token Migration

Status: generated tokens are the design system source of truth. Edit `tokens/tokens.json`, then run `node tokens/build.mjs`; generated CSS, TypeScript, Dart, Kotlin, and Swift files are never edited directly.

## Supported paths

| Layer | Supported API | Compatibility only |
|---|---|---|
| Vue | `--flare-*` generated custom properties | `--flare-component-*` aliases emitted by `apply-flare-theme.ts` and `im-theme.ts` |
| Flutter | `FlareColors`, `FlareSizes`, and generated theme values | local constants only for derived geometry with no semantic token |
| Compose | generated `FlareColors` and `FlareSizes` | platform adapters at the theme boundary |
| SwiftUI | generated `FlareColors` and `FlareSizes` | platform adapters at the theme boundary |

New component and product code must not introduce `--flare-component-*`, raw palette values, repeated token-sized spacing, magic shadows, or uncontrolled gradients. Existing debt is protected by file-level ratchets and must decrease as files are touched.

## Named product signatures

Three visual signatures may use dedicated component tokens when their product meaning is documented: call overlays, authentication identity surfaces, and diagnostics/status surfaces. Their values stay in a named adapter or token group and cannot become defaults for ordinary IM workspaces.

## Gates

- `node tokens/build.mjs --check` verifies all generated outputs.
- `node tooling/check-token-fallbacks.mjs` verifies Vue fallback values match generated light tokens.
- `node tooling/check-hardcoded-visuals.mjs` is the cross-platform raw-value ratchet.
- `node tooling/check-legacy-im-tokens.mjs` prevents any increase of legacy variables outside compatibility adapters.

The migration order is semantic colour, typography, spacing/radius, layout dimensions, elevation, then motion. Replace a legacy alias only after its light, dark, disabled, focus, and high-contrast behavior is represented by the target semantic token.
