#!/usr/bin/env node
/**
 * Every slot the contract declares exists on every platform it claims.
 *
 * `spec/components.json` has declared slots per component since the catalogue was written, and nothing
 * ever checked them: on 2026-09-17 the eight slot-bearing components declared 120 slot/platform pairs and
 * 33 of them did not exist — all 33 on the three native kits, including all four of `MessageList`'s, the
 * one the typing indicator needed. A declared slot that nobody implements is worse than an undeclared
 * one: it reads as available in the catalogue, the docs and the migration guide.
 *
 * `slotPlatforms` narrows a slot to the platforms that have it, the same way `eventPlatforms` narrows an
 * event, and `platformAliases.<platform>.slots` (or `.props` — on a native kit a slot IS a prop) names
 * it where a platform calls it something idiomatic (Flutter's `emptyPlaceholder` for `empty`).
 *
 * Narrowing is how a gap is recorded, not how it is hidden, so every narrowed slot must carry a
 * `slotReasons.<slot>` saying why it is not on the platforms it left out. Without that rule the
 * narrowing silently became the answer: on 2026-09-18 two of the 38 recorded gaps were not gaps at all
 * (`ContactList.trailing` was `trailingBuilder`, `ChatWorkspace.context` was `contextBanner`), and
 * nobody had noticed, because a narrowed slot said nothing at all.
 */
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { PLATFORMS, vueExportMap, loadSurface } from "../spec/signatures.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const spec = JSON.parse(readFileSync(join(root, "spec/components.json"), "utf8"));
const roots = {
  vueExports: vueExportMap(join(root, "packages/vue-im-ui/src")),
  flutter: join(root, "packages/flutter-im-ui/lib"),
  ios: join(root, "packages/ios-im-ui/Sources"),
  compose: join(root, "packages/android-im-ui/src/main"),
};

const camel = (name) => name.replace(/[-_](\w)/g, (_, c) => c.toUpperCase());

function implemented(component, platform, surface, slot) {
  // On the three native kits a slot IS a prop — a `Widget?`, a `@ViewBuilder`, a `@Composable` — so
  // an idiomatic name for one can have been recorded under either alias map. Reading only `slots`
  // is how `ContactList.trailing` spent three rounds listed as missing from Flutter while
  // `trailingBuilder` sat in the widget's constructor (FR-129).
  const aliases = [].concat(
    component.platformAliases?.[platform]?.slots?.[slot] ?? [],
    component.platformAliases?.[platform]?.props?.[slot] ?? [],
  );
  if (platform === "vue") {
    const source = readFileSync(surface.file, "utf8");
    return [slot, camel(slot), ...aliases].some((name) => new RegExp(`<slot[^>]*name=["']${name}["']`).test(source));
  }
  return [slot, camel(slot), ...aliases].some((name) => surface.props.has(name));
}

const failures = [];
let checked = 0;
let narrowed = 0;
for (const component of spec.components) {
  if (!component.slots?.length) continue;
  for (const platform of PLATFORMS) {
    if (!component.platforms?.[platform]) continue;
    const surface = loadSurface(roots, component, platform);
    if (!surface) {
      failures.push(`${component.name} · ${platform} — no surface found for the declared symbol`);
      continue;
    }
    for (const slot of component.slots) {
      const scope = component.slotPlatforms?.[slot];
      if (scope && !scope.includes(platform)) {
        // Narrowing records a gap; it does not hide one. Every narrowed slot says why it is not on
        // the platforms it left out, so the next reader does not have to re-derive it from silence.
        const reason = component.slotReasons?.[slot];
        if (!reason || reason.trim().length < 40) {
          failures.push(
            `${component.name} · ${platform} — slot "${slot}" is narrowed away from this platform with no reason`
            + ` (add spec/components.json → ${component.name}.slotReasons.${slot})`,
          );
        }
        narrowed += 1;
        continue;
      }
      checked += 1;
      if (!implemented(component, platform, surface, slot)) {
        failures.push(`${component.name} · ${platform} — slot "${slot}" is declared but the implementation has no such slot`);
      }
    }
  }
}

if (failures.length) {
  for (const failure of failures) console.error(`FAIL ${failure}`);
  console.error(`component slots: ${failures.length} declared slot(s) do not exist`);
  process.exitCode = 1;
} else {
  console.log(`component slots passed: ${checked} declared slot/platform pairs implemented; ${narrowed} narrowed away, each with a written reason`);
}
