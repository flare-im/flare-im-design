# CodeBlock

The catalog component is **CodeBlock**: Vue `FlareCodeBlock`. Native kits: N/A — no Flutter, SwiftUI or Compose app ships an admin console, and the contract says so in `notes`.

## Overview
Text a person reads exactly and usually copies — a raw payload, an initialisation snippet, a webhook body — in a monospaced, bounded scroll box with a copy key. The host formats the text and decides what may be shown; the block keeps it as written.

## When to use
Use it for a message's raw payload in a detail drawer, the quick-start snippet that initialises an SDK, a webhook's request body, an API call to copy into a terminal.

## When not to use
Do not use it for prose or for rich text a person composed (MarkdownPreview renders Markdown), for an identifier on one line (DescriptionList with `monospace` and `copyable`), or for anything secret the person should not see in full.

## Anatomy
A header with the `language` label and the copy key (drawn when either is present), then the scroll box (`pre` / `code`) on the secondary surface.

## Variants
`wrap` folds long lines instead of scrolling sideways. `copyable` (default true) draws the copy key. `language` is a label only: nothing is highlighted.

## Sizes
The block fills its container. The box scrolls inside `--flare-component-code-block-max-height` (360px) or the host's `maxHeight`. Text is the kit's small size at normal line height in the monospaced face.

## States
Default; with an empty `code` the copy key is disabled.

## Interactions
The copy key writes the whole text to the clipboard and emits `copy(copied)`; `copied` is false when the browser refused. The host shows the toast.

## Keyboard
Tab reaches the copy key, then the scroll box; arrow keys scroll the box. Enter or Space on the copy key copies.

## Accessibility
The scroll box is a named, focusable `region` (its name is `label`, else `language`, else the kit's "Code"), so a keyboard can scroll it and a screen reader can find it. The copy key is named "Copy code". The focus ring uses the selected-border token.

## Responsive
The box never widens its container: long lines scroll inside it (or wrap with `wrap`).

## Platform differences
Vue only. The native kits have no admin console to put it in.

## Code examples
```vue
<FlareCodeBlock language="JSON" :code="JSON.stringify(detail, null, 2)" @copy="(copied) => toast(copied ? t('common.copied') : t('common.copyFailed'))" />
<FlareCodeBlock language="TypeScript" :label="t('quickStart.init')" :code="initSnippet" wrap />
```

## API

### Props

| Prop | Type | Default | Description |
|---|---|---|---|
| `code` | `string` | required | The text, exactly as it should be read and copied. |
| `language` | `string` | — | What the text is, shown over it. |
| `label` | `string` | `language`, else kit "Code" | Accessible name of the scroll box. |
| `copyable` | `boolean` | `true` | Draw the copy key. |
| `wrap` | `boolean` | `false` | Wrap long lines. |
| `maxHeight` | `string` | token | Height cap as a CSS length. |

### Emits

| Event | Payload | When |
|---|---|---|
| `copy` | `(copied: boolean)` | The copy key was pressed. |

### Tokens
`--flare-component-code-block-max-height` and `--flare-component-font-family-mono`; everything else is the semantic palette.

## Do / Don't
Do format the text in the host (`JSON.stringify(value, null, 2)`), label what it is, and show a toast for `copy`. Don't put secrets in it, don't use it for prose, and don't add your own highlighter colours on top — the palette would no longer be checked against every brand.
