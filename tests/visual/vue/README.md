# Vue screenshot runner

The active Playwright runner renders real VitePress/Vue component demos in
light, dark, and 200% text modes. It waits for fonts, disables motion, and
compares the component fixture with committed PNG baselines.

Run `cd site && npm run test:visual`. Update baselines only after reviewing the
rendered diff with `cd site && npm run test:visual -- --update-snapshots`.
