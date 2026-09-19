# Conversation List 2.0 Finalization

Candidate: 2.0.0-rc.1. This document records implementation and bounded evidence, not a Stable certificate.

## 1. Previous Conversation-List Problems

| Semantic role | Previous owner / problem | Canonical owner | Priority |
| --- | --- | --- | --- |
| Row anatomy | Vue row tags, duplicate mute labels, pin overlay and trailing metadata competed for width | ConversationRow in each kit | P1 |
| List composition | Vue list required a slot, so basic public usage rendered no rows | ConversationList with canonical fallback and stable keys | P1 |
| Pin / unread / selection | Different native layout and badge limits, host avatar sizing | Native kit row and unread primitive | P1 |
| Preview state | Draft text only; typing/failure/mention lacked a common precedence | Typed row state and presentation resolver | P1 |
| Touch actions | Flutter local ListTile/SlidableAction, Swift local quick-action cards, Android popup | Canonical ActionSheet; host supplies capabilities and SDK callbacks | P1 |
| Documentation | Desktop and mobile demos rendered together; frame width did not change viewport queries | Isolated ComponentPreviewFrame | P1 |
| Screen header / filters | Some native host screen composition remains | Existing kit screen/header patterns, follow-up closure | P1 |

No SDK protocol, authentication, relationship directory or new business scope was introduced. Context actions now address their conversation ID without selecting/opening it first; metadata changes no longer reopen its timeline and inadvertently trigger read effects. Rapid menu reuse exposed a closing-transition race that dropped the second action. The canonical row now unmounts its closed desktop menu so reopening starts a fresh menu instance. No second SDK operation queue is introduced.

## 2. Information Hierarchy
P0: identity, unread, mention, actionable failure. P1: preview, time, draft. P2: pin, mute, typing, presence. P3: auxiliary metadata. Establish hierarchy with position and typography before color or a badge.

## 3. ConversationItem Anatomy
The public name remains ConversationRow. Three stable regions: avatar; flexible title and preview; trailing time and unread. No renamed competing component. Titles/previews ellipsize on one line. Full content remains in the accessible name. Tags remain compatible model data but the compact row does not render tag chips.

## 4. Pinned Design
Pinned rows precede normal rows while preserving input order inside each group. The small neutral pin follows the title, not the avatar or trailing time. Selection takes precedence over hover. Pin does not add a bright surface, card, badge or mandatory section header. Explicit host sections retain host order.

## 5. Unread
Rows show positive count, capped at 999+. Zero/negative are hidden; Vue also normalizes non-finite values. Trailing geometry is reserved at zero so incoming counts do not shift the title. Flutter's standalone badge keeps its compatible 99 default; ConversationRow explicitly selects 999.

## 6. Mention
Mention uses an inline localized prefix and normal strong unread count. It does not color the entire title or add another tag. Muted + mention keeps the strong count, even when a higher-priority draft or failure occupies the preview.

## 7. Mute
A small neutral mute icon follows the title. Muted unread uses a neutral count, not a second label. A mention overrides quiet unread. Mute never consumes a preview line.

## 8. Draft
Non-whitespace draft replaces the last-message preview and uses a semantic prefix. Raw host draft text must not already contain the presentation prefix. Explicit Vue draftPreview overrides model draft; an empty override clears it. No draft chip is added.

## 9. Typing
Typing occupies only the preview. It has no badge or looping animation in the list. It does not override failure or a local draft. Vue uses existing localized chat.typing, not an unresolved translation key.

## 10. Failure
Failure wins the preview prefix and is textual as well as semantic-error colored. The normal select action opens the conversation for recovery; the row itself never retries an SDK request. Not every reference SDK projection currently supplies failure/typing state: model support is not evidence of runtime adoption.

## 11. Time
Host-formatted timestampLabel is preferred. Trailing time uses a reserved width and single-line truncation; unread updates do not move it. Vue keeps updatedAt/lastMessage.time fallback for compatibility. Host locale/timezone formatting and all midnight/year-boundary policies are not yet one shared cross-platform formatter.

## 12. State Priority Resolver
Failed > non-empty draft > typing > mention + normal preview > normal preview. spec/conversation-state-vectors.json contains 64 boolean combinations and eight count/draft boundaries. Vue/Flutter/Swift consume that fixture; Compose tests the same independent truth table and count boundaries.

## 13. Meta Priority Resolver
Time and unread retain their own column. Pin and mute are low-emphasis inline marks. Row selection is separate from notification state. No combination creates extra lines, tag collections or a floating pin. Destructive capabilities remain host-approved; confirmations belong to the host flow using shared confirmation UI.

## 14. Desktop
Default row minimum is 72 logical pixels with 40px avatar. Vue supports ArrowUp/ArrowDown/Home/End, Enter, right-click and Shift+F10. Stable IDs preserve identity on reorder; the virtual list restores the first visible anchor. Desktop ConversationActionSheet uses compact flat menu items rather than touch-sized icon discs.

## 15. Mobile
Default row minimum is 80 logical pixels with a touch-sized selection surface. Vue long press opens a BottomSheet; Flutter kit owns swipe presentation and emits enabled host-approved actions. Swift/Compose hosts compose canonical action sheets in native modal containers. SDK callbacks, confirmation and route changes stay in the apps.

All multi-mode website previews mount exactly one iframe: desktop has a real 1024px viewport, mobile a real 390px viewport. Desktop single-component previews compensate the outer fit scale so menu text and controls retain their natural size; full workspace previews retain overall scaling. CSS media queries, adaptive providers, overlays and viewport composables therefore agree. Changing mode destroys the previous frame. DatePicker, TimePicker and Select are included. Single-mode components retain one shared canonical preview; no duplicate mobile/desktop example is rendered.

## 16. Accessibility
The six-theme contrast check caught selected-row timestamps below 4.5:1 in three light themes. Selected time now uses textSecondary on all four platforms, while unselected metadata remains subdued. Browser tests composite the actual ancestor backgrounds and assert every row title, preview, prefix, time and unread label at 4.5:1 or better.

Text labels include identity, full unread count, pin/mute/mention, preview and time. Pin/mute imagery is decorative. Focus is visible and does not change dimensions. Native rows preserve real Button/combinedClickable/InkWell semantics. Flutter tests 2x text at 240/280/320/360px and disabled swipe actions. Compose avatar semantics are excluded from the already merged row label.

Physical VoiceOver/TalkBack, native high-contrast coverage and full native keyboard/gesture matrices are not certified by web screenshots or model tests. They remain explicitly tracked in the readiness matrix and evidence manifest.

## 17. Five-Platform Canonical Ownership

| Consumer | Row / list owner | Action presentation | Host responsibility |
| --- | --- | --- | --- |
| Web | Shared Vue reference -> public ConversationListPanel -> Row/List | Kit context menu / BottomSheet | SDK projection and callbacks |
| Tauri | Same shared Vue reference | Same kit interaction | Desktop bridge and SDK |
| Flutter | FlareConversationRow / list container | Kit swipe + ActionSheet + SettingsRow | Resource spans, sync, pin, confirmed delete |
| iOS | ConversationRowAdapter -> ConversationRowView / list container | ConversationActionSheetView + SettingsRow | DTO mapping and commands |
| Android | Adapter -> com.flare.im.ui.ConversationRow / list container | ActionSheet in native ModalBottomSheet + SettingsRow | DTO mapping and commands |

Swift ConversationCard and quick-action/row renderers were removed, not hidden under an export. Flutter local row swipe styles and ListTile menu were removed. Open, mark-unread, local-history clear and Flutter sync were preserved as host commands composed with shared controls. The ownership scanner checks known canonical entry paths plus all Vue host style blocks; this is a regression guard, not proof that every native screen is free of unrelated duplicates.

## 18. Visual Regression
66 browser cases cover all 46 multi-mode previews, readable desktop controls, actual picker popup/sheet separation, rapid successive conversation actions, context/long-press actions, and six themes x light/dark x four list widths. Violet and Graphite have reviewed light/dark 320px baselines. Translation-key leakage is asserted against. Existing website tests are rerun separately and in the release gate.

MessageActionSheet and MemberRoleSheet no longer render a desktop/mobile comparison inside the selected preview. Branch-level assertions verify content isolation, not just iframe width. Member-role desktop density is owned by the public component; mobile keeps touch-sized actions. Destructive member demo actions use the canonical confirmation.

This is Vue visual coverage. Native model/widget/unit/build tests are not native screenshot equivalence. Full native brand golden matrices remain a release blocker.

The existing macOS SwiftUI large-text baseline was reviewed for the canonical row update. Native snapshots now explicitly render in sRGB and compare decoded RGBA pixels rather than PNG file bytes; previously the active physical monitor's ICC profile changed otherwise identical snapshots. The message-metadata baseline retains the same geometry and status semantics. No fuzzy pixel threshold or excluded region was added.

## 19. State Combinations
The named conversation-state-combination-check runs all four platform tests, not a source-text PASS. conversation-state-visual-check runs Playwright. conversation-reference-ownership-check validates actual consumers and fails on missing owners or known duplicate presentation. Negative fixtures verify the ownership guard rejects a moved Vue style override and legacy/native row presentation.

The isolated-account real Web regression also exercises pin/unpin and unread/read after desktop/mobile bidirectional messages, then reloads history and checks final row state. This is not a full reply/reaction/media/offline certification.

All three checks are part of release:check. Filtering remains diagnostic-only. A complete run records sourceBefore/sourceAfter, logs and result.json; source mutation invalidates that candidate.

## 20. Final 2.0 Release Impact
This pass addresses conversation density, state hierarchy, canonical row/menu adoption and platform-isolated documentation. It does not waive the broader 2.0 blockers: native advanced message mapping, remaining screen/theme presentation, full authenticated media/offline/retry/reaction flows, automatic native accessibility/resource evidence and four hardware gates.

No version bump, registry publication or server deployment is authorized by these narrower results. The final complete runner result owns the current totals and fingerprint. Older uekTHT evidence is historical.

### Final Design Audit
Scores are a bounded engineering review, not coverage percentages.

| Dimensions | Score / 10 | Evidence / remaining limitation |
| --- | --- | --- |
| Information hierarchy, density, metadata priority, avatar alignment | 8 | Three stable regions; reviewed narrow screenshots |
| Pin, unread, mention, mute | 8 | Subdued marks, neutral muted count, strong mentioned unread |
| Draft, typing, failure, time | 8 | Priority fixtures and localized preview; host runtime mapping incomplete |
| Selection, hover, focus | 8 | Separate states; keyboard interaction checks |
| Narrow width, mobile behavior | 8 | Four widths, iframe isolation, long press and Flutter swipe tests |
| Themes | 7 | Six Vue themes verified; native screenshot matrix incomplete |
| Accessibility | 7 | Keyboard and large-text tests; native automation/hardware gaps |
| Canonical ownership, reference adoption | 8 | Kit rows and menus; remaining other screen responsibilities documented |
| Anti-card, anti-badge restraint | 9 | No floating row cards or metadata chip collections |
| Overall 2.0 release readiness | 5 | Broader automatic blockers remain; not Stable |

No known P0 in this reviewed scope. Remaining P1 release groups are listed above. P2: complete native visual/formatting parity without changing SDK behavior. P3-only polish is not a release priority.
