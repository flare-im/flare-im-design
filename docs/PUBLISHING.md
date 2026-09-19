# Publishing

All versioned manifests use one release version and artifacts are produced from one commit.

## npm packages

Publish in dependency order:

```bash
npm --prefix tokens run build
npm --prefix tokens publish
npm --prefix spec publish
npm --prefix packages/vue-im-ui publish
```

The public packages are `@flare-im/tokens`, `@flare-im/ui-spec`, and `@flare-im/vue-ui`. Validate each archive with `npm pack --dry-run` before publishing.

## Flutter

From `packages/flutter-im-ui`, run `flutter analyze`, `flutter test`, and `dart pub publish --dry-run`. Publish only after the example build consumes the same package checkout.

## Android

From `packages/android-im-ui`, run unit tests, lint, and `assembleRelease`. Maven publication uses `com.flare.im:im-ui-compose:<version>`. Root `jitpack.yml` exists solely as JitPack's repository entry and delegates to this package.

## Apple

`packages/ios-im-ui` is a self-contained Swift package. Resolve, test, and build that directory directly. The monorepo root is not a SwiftPM package; remote distribution must publish the package subtree as a standalone source artifact or repository from the same candidate commit.

## Final checks

Run `npm run generate`, `npm run check`, `node tooling/check-kit-distribution.mjs`, all platform builds, website visual tests, consumer fixtures, and `git diff --check` before publishing.
