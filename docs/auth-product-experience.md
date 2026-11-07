# Flare IM authentication experience

Authentication uses `FlareAuthShell` in Vue, Flutter, Compose and SwiftUI. Core,
Social and Console provide their form, copy and existing SDK callbacks; the kit
owns brand presentation, sizing, scrolling and responsive composition.

## Product hierarchy

The primary task is signing in. Registration, recovery, captcha and MFA remain
available only when supported by the host. Brand copy must describe the product,
without invented customer figures, unsupported security promises or demo data.
The brand name is **Flare IM**; Console identifies its administrative audience.

On desktop (900 logical pixels and above), a 44% brand region balances a 56%
form region. The brand area uses the semantic selected/soft-primary background, its wordmark,
a short headline and the linked-message motif. The task surface is capped at 420 logical
pixels and centers vertically when it fits. Short windows scroll without clipping.

On phones the story and artwork are omitted. A compact wordmark precedes the
task heading; form content starts near the safe-area top. The mobile wordmark sits
above a single task surface that groups the heading, form and footer. A soft
primary-tinted canvas, white/themed surface, 18-pixel corners, a quiet border and
small elevation separate the task without introducing nested cards. Surface padding
is 20 on phones and 24 on desktop. Registration and large
text can scroll. The keyboard must leave the active field and primary action
reachable. No fixed footer may cover fields.

## Shared measurements

`tokens/tokens.json` generates all platform values:

- `fontSize.authTitle`: 28; `fontSize.authHeadline`: 36.
- `layout.authFormMaxWidth`: 420.
- `layout.authBrandLogoSize`: 44; `layout.authMobileLogoSize`: 40.
- `layout.authArtworkWidth`: 320.
- Existing `appShellCompactMinWidth`: 900; existing body, caption, spacing and
  touch-target tokens apply. Native text scales with accessibility settings.

The shell accepts optional `eyebrow` and `footer` text. They describe the current
task and account entry, never unsupported links. Hosts may supply a utility slot
for an existing language control. A single task heading identifies the form;
the decorative brand artwork stays out of accessibility navigation.

## Linked-message motif

All platforms draw the same static vector in a 320 by 200 canvas:

- Rear rounded bubble: `(28,24)` to `(220,140)`, radius 20; tail
  `(58,140) → (58,158) → (80,140)`.
- Front rounded bubble: `(120,82)` to `(292,178)`, radius 18; tail
  `(258,178) → (258,194) → (238,178)`.
- Three dots centered at `(166,130)`, `(198,130)`, `(230,130)`.
- Rear fill uses the soft primary/secondary surface; front uses the primary
  surface. Primary-colored strokes use 24% and 55% opacity. No simulated
  messages, movement, unrelated illustration library or network request.

## Interaction and verification

Retain password reveal, password-manager autocomplete, IME-safe Enter submission,
loading and duplicate-submit guards, recoverable errors, invitation rules,
account recovery and MFA. Form controls use shared kit components and sizes;
the page must not redraw their internals. Both themes and both languages use
the same structure. Validate narrow/short phone, tablet and desktop sizes,
keyboard navigation, registration, failure and loading states. Report native
build, widget and actual device verification separately.
