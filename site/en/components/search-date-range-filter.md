---
title: SearchDateRangeFilter
---

# SearchDateRangeFilter

Time-range filter for search. The host supplies preset ranges (today, last 7 days, last 30 days…) which the component shows as chips, plus a "custom" entry that expands a start/end date pair. The output is always one `FlareSearchTimeRange` — inclusive UTC epoch milliseconds — that the host folds into its search criteria. The component holds no clock: it never computes "today" itself, so it can never disagree with the host about the time zone.

<div class="flare-demo flare-demo--stack"><SearchDateRangeFilterDemo /></div>

<ComponentApi name="SearchDateRangeFilter" />

States: **unrestricted** (both bounds absent) shows `unlimitedText` in the summary and offers no clear button; a **matched preset** marks its chip selected — border and label together, never colour alone — and names it in the summary; a **custom range** expands the custom area, refills both DatePickers and summarises as "from X · to Y"; **from-only / to-only** leave the other end blank; an **illegal range** (`from > to`) shows a warning icon with `invalidText`, keeps the dates the user picked on screen and emits **no** change; `disabled` disables every chip, picker and button. Chip selection is decided by value with `sameSearchTimeRange(value, option)`, never by `id`, because a host may rebuild its option objects on every render.

Date-to-timestamp conversion lives in the pure `shared/contracts/search-date-range.ts`, reimplemented under the same names and covered by unit tests on all four platforms: `dayStartMs(date, tzOffsetMinutes?)` is **00:00:00.000** of that day, `dayEndMs(date, tzOffsetMinutes?)` is **23:59:59.999**, `rangeFromDates(from, to, tzOffsetMinutes?)` assembles the range (both blank is the unrestricted `{}`, while an unparsable date, an instant before the epoch or `from > to` return `null`), `datesFromRange(range, tzOffsetMinutes?)` refills the pickers, `matchedOptionId(value, options)` finds the selected preset, `unrestrictedRange(range)` reports the no-limit state and `shouldOpenCustomRange(...)` decides whether the custom area is expanded. Both ends are inclusive, so a single day spans 86,399,999 ms rather than 0. `tzOffsetMinutes` is **minutes east of UTC** (UTC+8 → 480, UTC-5 → -300) — note that JavaScript's `Date#getTimezoneOffset()` uses the opposite sign, so pass `-new Date().getTimezoneOffset()`; omit it to resolve the calendar date in the viewer's own zone, DST included. Date strings are validated strictly: `2026-02-30` and `2026-13-01` are rejected.

The component is controlled. The host owns `value`, `change` carries only the new range and `clear` expresses only the intent to drop the time condition; there are no requests, retries or self-mutations. **Query, type and time range are one indivisible submission.** After folding `change` into `FlareSearchCriteria` the host must re-run the search and make sure a result snapshot taken under the old criteria is never rendered under the new filter — SearchPanel already arbitrates this with `sameSearchCriteria(submitted, snapshot.criteria)` and renders the waiting state when they differ. Latest-request arbitration stays the host's job.

This component does **not** modify SearchPanel. Place it above the panel as a standalone filter bar or in the sidebar of a search workbench; SearchPanel's own `timeRanges` presets still work, but a single screen should have exactly one source of truth for the time range.

Vue binds `@change` / `@clear` and declares the clear capability with `has-clear` (default true); Flutter, SwiftUI and Compose take `onChange` (required) and an optional `onClear` — without it the clear button is not shown. With `allowCustom = false` the custom entry disappears entirely, leaving presets only.

The host controls how many presets exist; chips wrap and long labels wrap rather than truncate. The component itself does not scroll — put it in the settings or filter scroll container. Date entry reuses each platform's existing DatePicker (a popover on desktop web, a bottom sheet on mobile and native) instead of a new calendar. Chips, the clear button and the per-field reset are all at least 48 logical units; chips expose `aria-pressed` / `isSelected` and the custom entry adds `aria-expanded`; the illegal-range hint is a `role="alert"` and the summary is a polite live region, so a screen reader announces the current range. The demo runs on local state and does not stand in for a real search pipeline or on-device screen-reader acceptance. See the [full integration guide](/components/search-date-range-filter).
