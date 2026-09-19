#!/usr/bin/env node
/**
 * A preview that needs a click is not covered by rendering it.
 *
 * The accessibility sweep scans a component's preview as it renders. Six demos on the documentation site
 * are a button until someone presses it — the dialog, sheet or menu the component *is* only exists after
 * the click — so for those the sweep was scanning the trigger and reporting it as coverage. B7's
 * `StartConversationDialog` violation was that demo's own trigger button, not the dialog (FR-124).
 *
 * The sweep now clicks an opener declared in `spec/catalog-metadata.json` and scans the overlay too. This
 * gate keeps the declaration honest in the direction the sweep cannot: a demo of a surface that opens —
 * a dialog, a sheet, a modal, a palette, a menu — whose state starts closed and which declares no opener
 * would be scanned as a button again, silently.
 */
import { readFileSync, existsSync } from "node:fs";
import { join, resolve } from "node:path";

const root = resolve(new URL("..", import.meta.url).pathname);
const catalog = JSON.parse(readFileSync(join(root, "spec/component-catalog.json"), "utf8"));
const demos = join(root, "website/.vitepress/theme/demos");

/** Surfaces that come into existence rather than sitting on the page. */
const OPENS = /(Dialog|Sheet|Modal|Palette|Menu|Picker|Popover|Confirm)$/;
const CLOSED_STATE = /\b(?:open|visible|show|shown)\s*=\s*ref\(false\)|ref\(false\)\s*;?\s*\/\/\s*open/i;

const failures = [];
let checked = 0;
for (const component of catalog.components) {
  const overlay = component.previewPresentation === "overlay" || OPENS.test(component.name);
  if (!overlay) continue;
  const demo = join(demos, `${component.name}Demo.vue`);
  if (!existsSync(demo)) continue;
  checked += 1;
  const source = readFileSync(demo, "utf8");
  const startsClosed = CLOSED_STATE.test(source);
  if (startsClosed && !component.previewOpener) {
    failures.push(
      `${component.name}: its demo starts closed and declares no opener — the accessibility sweep would scan the trigger button instead of the surface. Add one to spec/catalog-metadata.json (preview.openers).`,
    );
  }
  if (component.previewOpener && !source.includes(component.previewOpener)) {
    failures.push(
      `${component.name}: the declared opener "${component.previewOpener}" is not in its demo any more.`,
    );
  }
}

if (failures.length > 0) {
  for (const failure of failures) console.error(`FAIL ${failure}`);
  process.exit(1);
}
console.log(`preview openers passed: ${checked} surfaces that open are reachable by the sweep`);
