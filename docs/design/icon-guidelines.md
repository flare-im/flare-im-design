# Icon Guidelines

Rules for the Flare semantic icon system on Vue, Flutter, SwiftUI and Compose. What exists today: `icon-inventory.md`. What an IM app needs and what gets added: `icon-coverage.md`. Platform usage: `../ICON-LIBRARY.md`.

## 1. One vocabulary, four glyph sources

- An icon is named by what it means (`recall`, `end-call`, `mark-unread`), never by how it looks (`arrow-undo`, `phone-rotated`, `mail-open`).
- The four kits share the name set. Each kit maps a name to its native source: Lucide on Web, SF Symbols on iOS, Material Symbols on Flutter and Compose. The concept must match across platforms; the pixels need not.
- Accepted platform idioms: iOS `back` is a chevron and iOS `share` is the share-sheet glyph. Any other difference between platforms is a defect in the mapping.
- Names are kebab-case and stable. Adding a name means adding it on all four kits in one change, with a consumer.

## 2. Who may draw a glyph

- **Apps** render icons only through the kit: a semantic name passed to a kit component, or the kit icon view (`FlareIcon`, Flutter `FlareIcon`, SwiftUI `IconView`, Compose `FlareIcon`). Apps never import a glyph library or name a platform glyph.
- **Kit components** render icons by name. A component that needs a glyph with no cross-platform meaning (a rich-text format button, a brand mark) keeps it in an internal table, not in the public registry.
- **Public kit APIs** take a semantic name type (`FlareIconName` on Vue, a name type on the natives), not `IconData`, SF Symbol strings, `ImageVector` or glyph components. An unknown name is a type error, not visible text.
- Emoji and other characters stay in message content, reaction sets and emoji pickers. They are never control icons: no `×` for close, `←` for back, `★` for starred, `🔍` for search.

## 3. Sizes

| Token | Size | Use |
|---|---:|---|
| `icon-size-sm` | 16 | inline with metadata and captions, badges, list trailing marks |
| `icon-size-md` | 20 | menu items, toolbar and header buttons, composer tools, settings rows |
| `icon-size-lg` | 24 | primary actions, bottom navigation, empty-state leading marks inside lists |
| `icon-size-xl` | 32 | empty and error states, call controls |

- Icon views take the size by token name. A literal size is a defect unless it is a media overlay sized to its media (a play button over a video).
- The same control uses the same token on every platform.

## 4. Icon-only controls

- Every icon-only control has an accessible name that says what happens ("关闭预览", "挂断", "删除选项"), in the product's language. The icon itself stays hidden from assistive technology.
- Use icon-only buttons for familiar, high-frequency actions: close, back, send, search, more, emoji, voice, add. Unfamiliar or destructive actions carry a text label, in a menu or on the button.
- Pointer platforms show the accessible name as a tooltip on hover and focus.
- Touch targets meet the kit minimum (44 pt on iOS, 48 dp on Android, the coarse-pointer target on Web) even when the glyph is 16 or 20.

## 5. Menus and toolbars

- Menu items show icon and label. Items in the same menu either all have icons or none do.
- A destructive item uses the danger colour on both icon and label and sits in its own group, last.
- High-frequency toolbar actions may be icon-only; low-frequency actions go into `more`.
- Two different actions never share a glyph in the same surface (clear history and delete conversation, reply and recall, pin and unpin).

## 6. States

| State | Treatment |
|---|---|
| Disabled | the control's disabled colour token; the name stays; the reason is announced where the kit supports it |
| Selected or on | the selected colour token, and a pressed or checked state for assistive technology |
| Danger | the danger text colour on icon and label |
| Active or in progress | a progress primitive, never a spinning icon |
| Failed | the `error` glyph with the error colour, plus text or an accessible name that says how to recover |

State is never carried by colour alone: selected items also expose pressed or checked state, failures also carry a glyph and a label.

## 7. Adding a name

1. Show a consumer: a kit component or app screen that draws the concept today, with file:line.
2. Pick the meaning-based kebab-case name and one glyph per platform with the same concept.
3. Add it to the four registries and `ICON-LIBRARY.md` in one change, and replace the borrowed or unnamed glyph at every consumer in the same change.
4. Do not add names for completeness. Concepts with no consumer are listed as "Not added" in `icon-coverage.md`.

## 8. Enforcement

Today:

- The accessibility gate requires Vue icons to be labelled or hidden, and the three native registry views to expose a label parameter.
- The Vue package-boundary gate forbids `@vicons` imports. It still lets components import the glyph shim.
- The app kit-reference gate counts visual literals and Material visual widgets in app code. It does not look at icons.

Added with the Round 5 icon work (R5.12):

- A per-kit ratchet that counts glyph references outside the registry and icon sizes off the token scale; counts may only go down.
- Native checks that icon-only controls carry an accessible name.
- An app gate rule that rejects glyph library imports and platform glyph names in app code.
