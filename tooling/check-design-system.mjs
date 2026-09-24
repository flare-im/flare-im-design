#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const checks = [
  ["repository scope", "node", ["tooling/check-repository-scope.mjs"]],
  ["legacy and temporary paths", "node", ["tooling/check-legacy-paths.mjs"]],
  ["spec validation", "node", ["spec/validate.mjs"]],
  ["platform signature drift", "node", ["spec/signature-report.mjs", "--json"]],
  ["generated tokens", "node", ["tokens/build.mjs", "--check"]],
  ["cross-platform visual contract", "node", ["tooling/check-cross-platform-visual.mjs"]],
  ["generated English strings", "node", ["strings/build.mjs", "--check"]],
  ["theme contract", "node", ["tooling/check-theme-contract.mjs"]],
  ["component layer map", "node", ["spec/build-component-layers.mjs", "--check"]],
  ["package boundaries", "node", ["tooling/check-package-boundaries.mjs"]],
  ["IM application platform", "node", ["tooling/check-im-application-platform.mjs"]],
  ["complete app assembly", "node", ["tooling/check-complete-app-assembly.mjs"]],
  ["reference app consumers", "node", ["tooling/check-reference-app-consumers.mjs"]],
  ["migrated app surfaces", "node", ["tooling/check-ui-reuse.mjs"]],
  ["public component exports", "node", ["tooling/check-public-exports.mjs"]],
  ["published Vue export map", "node", ["tooling/check-package-exports.mjs"]],
  ["accessibility contract", "node", ["tooling/check-accessibility.mjs"]],
  ["semantic colour pairs", "node", ["tooling/check-contrast-tokens.mjs"]],
  ["preview openers", "node", ["tooling/check-preview-openers.mjs"]],
  ["component slots", "node", ["tooling/check-component-slots.mjs"]],
  ["presence golden", "node", ["tooling/check-presence-golden.mjs"]],
  ["icon registry parity", "node", ["tooling/check-icon-registry.mjs"]],
  ["form keyboard contract", "node", ["tooling/check-form-keyboard.mjs"]],
  ["security boundary", "node", ["tooling/check-security-boundary.mjs"]],
  ["ssr safety", "node", ["tooling/check-ssr-safety.mjs"]],
  ["release report", "node", ["tooling/check-release-report.mjs"]],
  ["component contracts", "node", ["tooling/check-component-contracts.mjs"]],
  ["component maturity and interactions", "node", ["tooling/check-maturity.mjs"]],
  ["component guides", "node", ["tooling/check-component-guides.mjs"]],
  ["component documentation coverage", "node", ["tooling/check-component-doc-coverage.mjs"]],
  ["website productization", "node", ["tooling/check-website-productization.mjs"]],
  ["demo props", "node", ["tooling/check-demo-props.mjs"]],
  ["documentation preview simplicity", "node", ["tooling/docs-preview-simplicity-check.mjs"]],
  ["component example coverage", "node", ["tooling/check-component-example-coverage.mjs"]],
  ["documentation code samples", "node", ["tooling/check-doc-code.mjs"]],
  ["documentation links", "node", ["tooling/check-doc-links.mjs"]],
  ["feature matrix tally", "node", ["tooling/check-feature-matrix.mjs"]],
  ["friction register tally", "node", ["tooling/check-friction-register.mjs"]],
  ["generated files", "node", ["tooling/check-generated-files.mjs"]],
  ["token fallbacks", "node", ["tooling/check-token-fallbacks.mjs"]],
  ["browser baseline", "node", ["tooling/check-browser-baseline.mjs"]],
  ["token raw values", "node", ["tooling/check-hardcoded-visuals.mjs"]],
  ["localized string ownership", "node", ["tooling/check-hardcoded-strings.mjs"]],
  ["legacy tokens", "node", ["tooling/check-legacy-im-tokens.mjs"]],
  ["gallery coverage", "node", ["tooling/check-gallery.mjs"]],
  ["visual regression", "node", ["tooling/check-visual-regression.mjs"]],
  ["performance budgets", "node", ["tooling/check-performance.mjs"]],
  ["resource lifecycle", "node", ["tooling/check-resource-lifecycle.mjs"]],
  ["website build", "node", ["tooling/check-website-build.mjs"]],
];

for (const [label, command, args] of checks) {
  console.log(`\n== ${label}`);
  const result = spawnSync(command, args, { cwd: root, stdio: "inherit" });
  if (result.status !== 0) process.exit(result.status ?? 1);
}
console.log(`\nall ${checks.length} design-system gates passed`);
