#!/usr/bin/env node
/**
 * The Android app's copy of the shared presence table is byte-identical to the source of truth.
 *
 * `sdk-spec/golden/presence-projection.json` is the one table four platform packages answer to. Three of
 * them read it from the repository; an Android instrumented test cannot — it runs on a device — so the
 * app carries a copy in its test assets. A copy that drifts is worse than no copy: the test would keep
 * passing against a rule nobody else follows. Same discipline as the R6 iOS logic harness, whose
 * `ChatRules.swift` is checked byte-for-byte against the app's.
 */
import { readFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const socialSdk = join(here, "../../flare-social/flare-social-sdk");
const source = join(socialSdk, "sdk-spec/golden/presence-projection.json");
const copy = join(socialSdk, "examples/apps/flare-social-android-app/app/src/androidTest/assets/presence-projection.json");

if (!existsSync(source) || !existsSync(copy)) {
  // The sibling repository is not always checked out beside this one (the same reason the kit aliases
  // fall back to the published package). Nothing to compare is not a drift.
  console.log("presence golden: the social SDK repository is not beside this one; nothing to compare");
  process.exit(0);
}

const a = readFileSync(source);
const b = readFileSync(copy);
if (a.equals(b)) {
  const table = JSON.parse(a.toString("utf8"));
  console.log(
    `presence golden passed: the Android test asset matches sdk-spec byte for byte (${table.fromDto.length} lookups, ${table.fromStatus.length} pushes)`,
  );
} else {
  console.error("FAIL the Android test asset has drifted from sdk-spec/golden/presence-projection.json");
  console.error(`      source ${a.length} bytes, copy ${b.length} bytes — copy the source over it`);
  process.exitCode = 1;
}
