# Visual Regression

The shared scenario inventory is `spec/scenarios/rc.json`; runner status is `tests/visual/manifest.json`.

Flutter has active checked-in goldens covering General controls, CommandPalette, MessageStatus, and MessageMeta. Run:

```bash
cd packages/flutter-im-ui
flutter test test/goldens/core_components_golden_test.dart
```

Vue has an active Playwright fixture for light, dark, and 200% zoom. SwiftUI has an active macOS host `ImageRenderer` snapshot. Compose has an executable AndroidX capture/compare harness, but its pixel baseline remains `MANUAL_REQUIRED` until the pinned API 35 runner is available.

Shared scenarios vary state, content, interaction, accessibility expectation, and theme. The platform galleries additionally cover text scale, LTR/RTL, motion, and large desktop/desktop/tablet/mobile viewports. Baselines may be updated only after reviewing the rendered diff; updating a baseline solely to make CI green is prohibited.

`node tooling/check-tests/visual.mjs` verifies scenario targets, active baseline files, and honest runner status.
