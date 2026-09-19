# 2.0 Stable Release Checklist

Candidate remains 2.0.0-rc.1. None of the unchecked items below is waived by a successful build.

- [ ] Freeze one candidate commit for every platform artifact.
- [ ] Run `npm run generate` and verify the worktree contains no unexpected generated drift.
- [ ] Run `npm run check` and `node tooling/check-kit-distribution.mjs`.
- [ ] Run Vue tests, typecheck, SFC compilation, package build, and `npm pack --dry-run`.
- [ ] Run Flutter analyze, widget tests, package dry-run, and the Flutter example build.
- [ ] Run Android unit tests, lint, release assembly, AAR inspection, and the Compose example build.
- [ ] Run Swift package resolve, tests, build, and the SwiftUI example build.
- [ ] Build the VitePress website and run the Playwright theme/core visual suite.
- [ ] Install or build each artifact from `tests/consumers` without sibling product repositories.
- [ ] Review visual diffs; never accept a baseline only to make CI pass.
- [ ] Complete representative device and assistive-technology rows in `docs/device-accessibility-test-matrix.md`.
- [ ] Confirm `COMPATIBILITY.md`, `PUBLIC_API.md`, changelogs, and migration notes match the candidate.
- [ ] Review all entries in `docs/2.0-public-api-freeze.md`; resolve duplicate public semantics and internal leaks.
- [ ] Complete `docs/2.0-reference-app-feature-matrix.md` with real SDK interaction evidence, not catalog-only claims.
- [ ] Verify H5 at 375x667, 390x844 and 430x932; desktop at 1024, 1280, 1440 and wide.
- [ ] Verify all built-in content renderers, metadata, actions, uploads, preview errors, offline recovery and retries.
- [ ] Run consumer public-import, duplicate-UI and style-ownership gates without suppression baselines.
- [ ] Close every automated evidence item in `spec/manual-evidence.json`; retain only genuine hardware review as manual.
- [ ] Confirm P0=0 and P1=0; record non-blocking polish separately.
- [ ] Run `npm run release:check` on the frozen candidate and retain its evidence directory.
- [ ] Only after all gates pass, bump all artifacts and locks to 2.0.0, regenerate and rerun the complete release check.
- [ ] Run `git diff --check` and the full active-path/alias/token search.

Automated checks prove deterministic repository contracts. Physical VoiceOver/TalkBack and hardware performance require genuine device evidence. Keyboard, pointer, large text, reduced motion and simulator-permission flows must not be labelled manual merely because their automation is unfinished.

## Live SDK Gate

The full command includes a real two-account Web SDK flow. It fails closed without explicit send opt-in, distinct isolated `ui2-release-*` accounts and an HTTP(S) app URL. It sends two uniquely marked text messages and leaves them in those test accounts; never use real user conversations. Point the URL at the current candidate, not an older deployment. For local sources, use the app's existing same-origin Vite proxy when the gateway does not support local cross-origin token requests. Preserve the gateway's configured path prefix.

```sh
FLARE_ALLOW_LIVE_SEND=1 \
FLARE_LIVE_BASE_URL=http://127.0.0.1:1498 \
FLARE_LIVE_USER=ui2-release-20260911-a \
FLARE_LIVE_PEER=ui2-release-20260911-b \
npm run release:check
```

The live gate captures desktop/mobile screenshots in the release evidence directory. Login, open conversation, bidirectional text, refreshed history and horizontal overflow are checked. Media, offline recovery, retries, complete receipts and native SDK interactions need separate coverage. A successful live text gate cannot certify them.
