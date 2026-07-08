# Design tokens

A neutral [`tokens.json`](https://github.com/flare-im/flare-im-design) single source generates four platform outputs: Web `CSS`/`TS`, Dart, Swift and Kotlin. Color, spacing, type and radius are identical, light + dark. The swatches below are read from the **real generated CSS variables** loaded by this site.

## Brand & semantic colors

<div class="tok-grid">
  <div class="tok"><span class="sw" style="background:var(--flare-color-primary)"></span><code>primary</code></div>
  <div class="tok"><span class="sw" style="background:var(--flare-color-success)"></span><code>success</code></div>
  <div class="tok"><span class="sw" style="background:var(--flare-color-warning)"></span><code>warning</code></div>
  <div class="tok"><span class="sw" style="background:var(--flare-color-error)"></span><code>error</code></div>
  <div class="tok"><span class="sw" style="background:var(--flare-color-info)"></span><code>info</code></div>
  <div class="tok"><span class="sw" style="background:var(--flare-color-pinned)"></span><code>pinned</code></div>
</div>

## Bubbles

<div class="tok-grid">
  <div class="tok"><span class="sw" style="background:var(--flare-color-bubble-self)"></span><code>bubble-self</code></div>
  <div class="tok"><span class="sw" style="background:var(--flare-color-bubble-other)"></span><code>bubble-other</code></div>
  <div class="tok"><span class="sw" style="background:var(--flare-color-bubble-robot)"></span><code>bubble-robot</code></div>
  <div class="tok"><span class="sw" style="background:var(--flare-color-bubble-system)"></span><code>bubble-system</code></div>
</div>

## Backgrounds & text

<div class="tok-grid">
  <div class="tok"><span class="sw bd" style="background:var(--flare-color-bg-primary)"></span><code>bg-primary</code></div>
  <div class="tok"><span class="sw bd" style="background:var(--flare-color-bg-secondary)"></span><code>bg-secondary</code></div>
  <div class="tok"><span class="sw bd" style="background:var(--flare-color-bg-selected)"></span><code>bg-selected</code></div>
  <div class="tok"><span class="sw" style="background:var(--flare-color-text-primary)"></span><code>text-primary</code></div>
  <div class="tok"><span class="sw" style="background:var(--flare-color-text-secondary)"></span><code>text-secondary</code></div>
  <div class="tok"><span class="sw" style="background:var(--flare-color-text-tertiary)"></span><code>text-tertiary</code></div>
</div>

## Radius & spacing

<div class="radius-row">
  <div><span class="rbox" style="border-radius:var(--flare-size-radius-sm)"></span><code>radius-sm</code></div>
  <div><span class="rbox" style="border-radius:var(--flare-size-radius-md)"></span><code>radius-md</code></div>
  <div><span class="rbox" style="border-radius:var(--flare-size-radius-lg)"></span><code>radius-lg</code></div>
  <div><span class="rbox" style="border-radius:var(--flare-size-radius-xl)"></span><code>radius-xl</code></div>
</div>

## Consuming on each platform

::: code-group

```css [Web]
@import "flare-im-design-tokens/tokens.css";
.self { background: var(--flare-color-bubble-self); }
```

```dart [Flutter]
final colors = FlareColors.of(Theme.of(context).brightness);
Container(color: colors.bubbleSelf);
SizedBox(height: FlareSizes.spacingMd);
```

```swift [iOS]
let colors = FlareColors.of(colorScheme)
Rectangle().fill(colors.bubbleSelf)
```

```kotlin [Android]
val colors = flareColors()
Box(Modifier.background(colors.bubbleSelf))
```

:::

<style>
.tok-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 14px; margin: 16px 0; }
.tok { display: flex; align-items: center; gap: 10px; }
.tok .sw { width: 34px; height: 34px; border-radius: 8px; flex: none; }
.tok .sw.bd { border: 1px solid var(--vp-c-divider); }
.radius-row { display: flex; flex-wrap: wrap; gap: 24px; margin: 16px 0; }
.radius-row > div { display: flex; flex-direction: column; align-items: center; gap: 8px; }
.rbox { width: 56px; height: 56px; background: var(--flare-color-bubble-other); display: block; }
</style>
