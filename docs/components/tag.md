# Tag

The catalog component is **Tag**: Vue `FlareTag`. Native kits: N/A — no Flutter, SwiftUI or Compose app ships an admin console, and the contract says so in `notes`.

## Overview
A short status or category label on a table row or a detail line: frozen, in review, image, owner, a version. `tone` says what the state means; the words carry the meaning and the colour only repeats it.

## When to use
Use it in console tables and detail drawers for a record's status (active, frozen, pending), its kind (text, image, system) or a short identifier (a version, an app code).

## When not to use
Do not use it as a control: a filter a person toggles is FilterTabs, an action is a Button, a removable chip is not this. Do not use it for counts on navigation (AdaptiveNavigation badges) or for a sentence.

## Anatomy
One rounded surface with an optional leading dot and the label.

## Variants
`tone`: `neutral` (default, a category with no judgement), `info`, `success`, `warning`, `danger`. `dot` marks a live state (online, running). `monospace` sets an identifier in the monospaced face.

## Sizes
One size: caption text with a small inline padding, so a tag sits on a table row or a text line without changing its height. A long label is cut with an ellipsis inside the space it is given.

## States
Default only. A tag is not interactive.

## Interactions
None.

## Keyboard
None: a tag is not focusable.

## Accessibility
Plain text. A screen reader reads the label; the tone and the dot are not announced, so the label must say the state on its own ("Frozen", not just a red tag). Each tone writes its text colour on a 6% tint of the tone over the primary surface, which keeps 4.5:1 in every brand and both modes (lowest 4.64:1); the unit tests compute it from the generated tokens, rounded to the channel values a browser paints. Under forced colours the tag draws an outline.

## Responsive
Inline; it never grows its container.

## Platform differences
Vue only. The native kits have no admin console to put it in.

## Code examples
```vue
<FlareTag :label="t('users.status.' + user.status)" :tone="{ active: 'success', frozen: 'danger', pending: 'warning' }[user.status] ?? 'neutral'" />
<FlareTag :label="t('apps.online')" tone="success" dot />
<FlareTag :label="app.version" monospace />
```

## API

### Props

| Prop | Type | Default | Description |
|---|---|---|---|
| `label` | `string` | required | The words. |
| `tone` | `FlareTone` | `'neutral'` | `info`, `success`, `warning`, `danger` or `neutral`. |
| `dot` | `boolean` | `false` | A leading dot for a live state. |
| `monospace` | `boolean` | `false` | The monospaced face, for identifiers. |

### Tokens
The tone text tokens (`--flare-color-*-text`), the tone fills and `--flare-color-bg-primary` / `--flare-color-bg-tertiary`; no component seam.

## Do / Don't
Do map every server state to one tone in the host and translate the label. Don't rely on the colour alone, don't make a tag clickable, and don't invent a sixth tone with your own colour.
