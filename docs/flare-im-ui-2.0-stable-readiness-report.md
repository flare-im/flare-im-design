# Flare IM UI 2.0 Stable Readiness Report

Candidate: **2.0.0-rc.1**. Review date: 2026-09-11.
Decision: **NOT_READY**. This report distinguishes implementation, compilation, automated interaction, and hardware review. It is not a Stable release certificate.

## 1. Executive Summary
This closure pass fixed canonical native message dispatch, missing typed business content, duplicate native bubble chrome, Flutter light-only theme aliases, unsafe Vue text link construction and the fail-open RTC stub. It also restored native media callbacks, adopted canonical player chrome, bounded Swift animated decoding and hardened Flutter static asset caching. Swift's unused local composer controls were deleted and its live emoji picker now consumes the public pack picker. Compose Material typography now comes from the kit provider. The serial, fail-closed release runner retains candidate fingerprints and rejects source changes during validation. Remaining automatic blockers are real implementation/evidence work, not manual exemptions. Version 2.0.0 has not been assigned or published.

## 2. Final Architecture
The retained architecture is Foundation -> General UI -> IM UI -> Patterns/Workspaces -> optional AppKit -> host composition. Tokens/spec are authoritative. SDK lifecycle, transport, upload/download, permissions and application state remain outside UI packages. No directory migration or second framework was introduced.

## 3. Final Package Layout
- tokens/: generated CSS/TypeScript and native semantic constants.
- spec/: component, capability, state, scenario and API contracts.
- packages/vue-im-ui/: Vue public package.
- packages/flutter-im-ui/: Flutter public package.
- packages/android-im-ui/: Compose library artifact.
- packages/ios-im-ui/: standalone Swift package with resources.
- website/: Vue previews and multilingual documentation.
- examples/ and tests/consumers/: library examples and independent package consumers.
The five real Core consumers remain in the sibling SDK repository.

## 4. Canonical Component Registry
See [the complete registry](2.0-public-api-freeze.md): 154 semantic entries. Vue has 154 symbols, Flutter 153 and Compose/SwiftUI 152; ConfigProvider and native DesktopWorkbench omissions are declared platform scope. These counts are contract coverage, not proof of canonical runtime ownership.

## 5. Public API Freeze
REVIEW_REQUIRED. Public-import scanning currently reports no private imports, but header naming, remaining standalone/business renderer duplication and native adapter completeness still prevent final freeze. EnhancedComposer is a Vue implementation filename; the public entry is FlareComposer. Native content model additions are documented in the API review.

## 6. Message Renderer Matrix

| Type | Canonical role | Presentation / metadata | Customizable | Vue | Flutter / Compose / SwiftUI |
| --- | --- | --- | --- | --- | --- |
| Text | TextMessage | Bubble + MessageMeta | Link intent, selection | Runtime/public unified; safe Markdown | Public body dispatch |
| RichText / RichDoc | RichText content | Bubble + MessageMeta | Host custom content | Existing rich renderer | PARTIAL: collapsed/unsupported schema paths |
| Image | ImageMessage | Media overlay policy | Media resolver/open | Existing runtime renderer; standalone review | Canonical body; host loading/error review |
| MultiImage | ImageGrid | One media container/meta | Open index | Existing grid | PARTIAL: adapter/data coverage |
| Video | VideoMessage | Media overlay, duration separate | Play intent | Existing media runtime | Canonical body; host playback incomplete |
| Voice | VoiceMessage | Bubble footer meta | Playback state/intent | Public runtime path | Public body; host playback incomplete |
| File | FileMessage | Bubble footer meta | Open/download | Standalone/runtime consolidation pending | Public body; download wiring incomplete |
| Sticker / GIF | StickerMessage | Bare media, external meta | Pack/URL/open | Existing canonical media policy | Public pack body; resource budgets pending |
| LargeEmoji | EmojiMessage | Bare content, external meta | Emoji key/open | Existing canonical media policy | Public pack body |
| Location | LocationMessage | Bubble footer meta | Open location | Existing runtime | Public body |
| ContactCard | ContactMessage | Bubble footer meta | Open contact | Existing runtime | Public body |
| LinkPreview | LinkCardMessage | Bubble footer meta | Open link | Runtime/standalone review pending | Typed model, public body |
| Poll | VoteMessage | Bubble footer meta | Selection/results | Public/runtime unified; unknown != zero | Public body, read-only dispatcher |
| Task | TaskMessage | Bubble footer meta | Toggle intent | Existing runtime | Public body, read-only dispatcher |
| Calendar | LinkCardMessage | Semantic leading icon + meta | Open intent | Existing runtime | Typed content and canonical body |
| MiniApp | LinkCardMessage | Thumbnail/title + meta | Host app routing | Existing runtime | Typed content and canonical body |
| Reply | Reply presentation + content | One quoted block + one meta | Jump intent | Existing runtime | PARTIAL |
| Forward | Forward content | Summary + one meta | Open/jump | Existing runtime | PARTIAL |
| MergedForward | Merged-forward content | Summary + one meta | Open thread | Existing runtime | PARTIAL |
| System | SystemMessage | Neutral system presentation | Host text | Existing runtime | Public body |
| Notice / Announcement | LinkCardMessage or system notice | Semantic content + one meta | Open intent | Existing runtime | Typed announcement, complete body text |

Native business payload retention is improved but is not equivalent to complete interaction support. Built-in content must not silently fall back to misleading text or omit nested content.

## 7. Composer
Public Composer retains simple draft/send and advanced action/capability paths. Existing Vue tests cover surface, formatting menu, expansion, focus and action events. Flutter actual reference tests preserve rich input and outbound dispatch. Swift's unused ComposerControls.swift (local rich editor, recording toolbar, send controls and more panel) was removed; FlareEmojiStickerPicker now emits catalog keys and sticker IDs to the existing SDK send path. Data-only rich serialization tests remain, but that serializer is not proof of current composer interaction coverage. Remaining local native forms/sheets and complete runtime upload/recording paths require consolidation and interaction evidence.

## 8. Conversation Header
Identity, presence, actions and responsive action resolution are public contracts. Header behavior tests exist on the packages. ChatHeader/ConversationHeader semantic overlap and remaining consumer presentation require final ownership review.

## 9. Navigation
Public adaptive navigation and AppKit navigation configuration exist. Web/Tauri share the same composition. Native integration must not duplicate rail/sidebar/bottom-navigation styling. Permission/capability state comes from the host.

## 10. Contacts
Public contact/list/detail/relationship components exist. Core examples intentionally do not provide the Social contacts directory. This N/A does not waive library component testing.

## 11. Groups
Public group/member/permission/workspace components exist. Core group conversations are distinct from the Social group directory. Full group interactions require library/appropriate Social-host evidence.

## 12. Search
Public search workspace/panel/results/date-range contracts and tests exist. Actual native examples retain presentation fragments; keyboard, empty/error and jump-to-result flows are not fully certified.

## 13. Media
Image/voice/file/sticker bodies now share native implementations. Swift file actions are no longer nested buttons. Flutter now routes voice/video into the public player with host video_player decoding, controlled play/pause/seek/speed/mute, error/retry and disposal. Swift uses a stable AVPlayer inside the public player rather than constructing a player on every body update; Android uses a released-on-dismiss VideoView/system controller inside the same semantic public modal. Native file taps route to SDK download operations. Flutter controller tests cover playback, seeking, speed, invalid URLs, retry and disposal; actual native codecs, protected media access, completion/error presentation and file delivery still need broader runtime evidence.

Swift remote animation downloads are bounded at 8 MB, decoded thumbnails at 256 px, decoded animation at 32 MB / 180 frames; oversized animations fall back to the first frame. Local decoding rejects remote URLs, reduced motion uses first-frame-only decoding, and the decoded cache is bounded. Animated ImageIO decoding now runs on a serial non-UI actor, checks cancellation between frames and publishes platform images only after checking cancellation on the UI actor. Four focused budget/cancellation tests pass. Synchronous first-frame catalog lookups remain a separate performance review item.

Flutter static asset decoding rejects oversized encoded input, keys caches by decode size, rejects stale completions and disposes codecs/images. The reference media adapter now bounds initialization/commands at 20 seconds and teardown waiting at five seconds, contains teardown failures and prevents stale command errors from replacing a new player. Five media-controller tests pass, including timeout/retry and dismissal during initialization. A timed-out native platform creation still depends on the plugin eventually completing cleanup; these focused protections do not certify all media resource paths.

## 14. Calls
UI remains independent of RTC. Flutter's bundled stub now reports unavailable and start throws UnsupportedError without dispatching a call. The app does not expose a working call controller from that stub. Real RTC/plugin integration must not be inferred from UI coverage.

## 15. Workspaces
Conversation, contacts, group, search, media, settings and related workspaces retain public state contracts. Complete loading/empty/error/offline and responsive runtime coverage across all native consumers remains PARTIAL.

## 16. AppKit
Optional, SDK-agnostic composition is retained. Independent examples consume public entries. The assembly gate now checks Flutter MessageBubble plus typed content instead of requiring a second standalone text body alongside the dispatcher.

## 17. Themes
Generated theme checks passed six brands x light/dark and shared semantic consumers. Flutter Core light-only aliases have been removed in favor of FlareColors.of(context). Compose FlareThemeProvider now supplies Material colors and token-derived typography; the real app no longer declares FlareType or a parallel Material typography mapping. Two unit tests verify all twelve brand/appearance combinations, a custom primary color and every typography role's zero tracking. Swift/Compose local color facades and custom-theme flow still need consolidation. Token generation passing does not prove every consumer follows context correctly.

## 18. Responsive
Web login tests now include 375x667, 390x844, 430x932, 768x900, 1024x768, 1280x800, 1440x900 and 1920x1080. Swift contact/poll/task/location bodies no longer force minimum widths; message text participates in Dynamic Type. These improvements do not certify full chat, soft-keyboard or multi-pane flows.

## 19. Accessibility
Automated semantics, keyboard, contrast, large text and reduced motion are required, not manual exceptions. Swift Switch/Checkbox/Radio now use actual Buttons, enforce disabled actions, expose selected/value semantics and reserve 44 pt minimum targets. Three ViewInspector tests verify actions, disabled state and targets; this dependency is test-target-only. An offscreen AppKit accessibility-tree experiment did not expose a valid tree and was discarded, not reported as passing. Existing Swift snapshot evidence runs on macOS and must not be labelled iOS device evidence. Physical VoiceOver/TalkBack remain MANUAL_RELEASE_GATE. System-level native semantics/keyboard coverage is still incomplete.

## 20. Performance
Existing budgets and lazy/virtualized list contracts remain. Large-history/prepend anchoring, search/composer responsiveness and media decode limits must be measured on the candidate. Hardware traces remain manual; simulator/resource automation does not.

## 21. Vue
A focused security regression verifies malicious text cannot create onclick/onerror/img/script nodes or unsafe link protocols. Runtime text uses the public body. Poll rendering also delegates publicly and separates unknown/known results. A full intermediate suite passed 328 tests; three additional poll tests passed afterward. The final release runner is authoritative for the candidate count.

## 22. Flutter
The kit's canonical dispatch tests verify real public body types, media callbacks, outgoing text color, metadata ownership and narrow poll text. The actual Core app passed static analysis and 73 tests after alias removal and RTC hardening; three additional media-controller tests pass. Nine remaining typography files now use kit size tokens, and the composer panel uses the contextual surface color. Remaining local presentation and advanced message mapping still block Stable.

## 23. Compose
Kit compilation and earlier unit/lint/release assembly passed. Native content now maps into public bodies including typed business content. Compilation is not an instrumentation pass. Full device/emulator interaction and remaining theme facade work are still required.

## 24. SwiftUI
The full u3QF82 run passed 176 package tests and 53 Core app tests with six explicitly skipped live-service tests, plus the simulator build. Three subsequent public-control tests pass for canonical PrimaryButton delegation, Toast actions/targets and the pack picker. The app still passes its 53-test suite after deleting the unused composer UI and adopting public login controls. The final sources require renewed full-suite/simulator validation. Large text on macOS does not certify VoiceOver or iOS gestures.

## 25. Website
The website continues to use Vue visual previews with native usage examples. Generated docs cover 154 components in both languages. The Vue example now uses the canonical MessageList, restores outgoing alignment, and provides viewport context. All 79 Playwright cases pass using isolated CI servers on ports 4191/4192; existing dev servers are not reused. Documentation import checking resolves the complete TypeScript public entry (including type-only imports and composable re-exports), with rejection tests for invented/private names. Full metadata coverage does not prove every native usage sample or renderer is complete. The production build and Playwright suites are part of the release command.

## 26. Reference Apps
See [the feature matrix](2.0-reference-app-feature-matrix.md). Web/Tauri share real SDK-backed composition. Native adapters retain SDK responsibilities. All three source scans now pass over 244 files after removing FlareType, FlarePanel, the loading modifier and literal typography findings. No suppression baseline was added. These bounded pattern checks are not a complete semantic audit: native action sheets, pills, color facades and other local presentation still require review and consolidation. Swift conversation rows now delegate pinned/selected presentation to ConversationRowView and use a public more-action button.

## 27. Tests
release:check runs repository contracts, Vue tests/build, Flutter tests/analyze, Compose unit/lint/assembly, Swift tests, website visual/interaction, package inspection, independent consumers, all five apps and git diff checks. Filtered runs are diagnostic only. Results and individual logs are retained even when a subprocess fails. Before/after SHA-256 source fingerprints include tracked and untracked nonignored files across the design, SDK and five app roots; changed source fails candidate integrity. Ignored build caches do not affect the fingerprint.

The latest complete run `uekTHT` passed **36/36 executed checks**, including 331 Vue kit tests, 180 Swift kit tests, all 79 website cases, the real two-account Web SDK flow, the five consumer builds/checks and all seven diff checks. Its before/after source digest is `fdf0fe2fe11a618fe897a4be0d7024e08bfcecb2e6785d490d7060b437b218fc`. The iOS simulator build was clean, not incremental. The six skipped Swift app live tests remain skipped, not passed. The overall command correctly returned `RELEASE_CHECK_NOT_READY`: incomplete capability/ownership rows, nine automatic evidence items and four hardware review items are still unresolved.

Evidence: `/var/folders/jp/dskk882x3h92ljssl74w64tm0000gn/T/flare-ui-release-uekTHT/result.json`; per-check logs and desktop/mobile real-service screenshots are beside it. The post-run edits to this report and readiness matrix only record that result and are not represented as a new full-candidate certificate. The temporary 1498 server was stopped, existing development servers were left running, and the completed Flutter macOS build cache was removed for disk space. No deployment or registry publication occurred.

The complete u3QF82 run finished with 33/34 checks passing and only reference-ownership failing (subsequently fixed within that scanner's scope). Its before/after digest was a440d3b7dce788459745e32f424e71007cbdccb14c6c08453db66ba9aee15950. Evidence is retained under the macOS temporary directory `flare-ui-release-u3QF82/result.json`, with individual logs. This is prior-candidate evidence after subsequent edits; the next full result is authoritative and must retain all unresolved matrix/evidence blockers.

Subsequent isolated checks passed all 32 design gates, 179 Swift kit tests, Compose kit unit/lint/AAR/instrumentation compilation and Android app unit/lint/APK checks. Android app instrumentation remains NO-SOURCE. An independent iOS build exposed a hardcoded arm64-simulator FFI link path plus exhausted temporary disk space; the XcodeGen source now selects each SDK/architecture slice. A clean generic simulator build then passed and its binary contains arm64 and x86_64. The runner regenerates the Xcode project and performs a clean build so a stale incremental product cannot certify this path. Temporary derived products were removed; source and SDK artifacts were preserved. The final full run contains 36 checks including the explicit opt-in live Web SDK flow and candidate integrity. Subsequent media changes add one Swift test and two Flutter app tests; the final runner result owns the totals.

## 28. Visual Regression
Existing Vue website and native golden/snapshot suites are executable release gates. Changed text/poll/body layouts require screenshot inspection; no baseline is to be accepted just to silence a failure. Full native Light/Dark Violet/Graphite coverage is not yet certified.

## 29. Interaction Regression
The actual Web browser suite is now included on an isolated port and records viewport screenshots. Existing tests verify login/guards/surfaces, not the entire requested send/reply/edit/retry/upload/contacts/groups matrix. Missing flows remain AUTOMATION_REQUIRED.

Fresh production same-origin login against the deployed gateway passed (real token response 200 and ready conversation route). The current local sources also passed using the existing Vite same-origin media proxy and the real WSS endpoint. Two isolated `ui2-release-*` accounts exchanged real text messages in both directions at 1440x900 and 390x844; refreshed history reappeared and neither viewport overflowed horizontally. Screenshots were inspected. `scripts/check-release-live-web.mjs` makes this narrow flow repeatable and requires explicit send opt-in; it is now a release command gate.

An earlier local cross-origin attempt failed at OPTIONS 501. That was not evidence of a broken production gateway: the configured `/api` prefix is intentional, and `/api/api/v1/auth/tokens` accepts same-origin token requests. Removing the prefix incorrectly reaches a 404. No gateway configuration was changed, no deployment was made and no existing user conversation was used for sends. Full media, offline, retry, receipt-state and native interaction matrices remain AUTOMATION_REQUIRED; the successful text flow does not waive them.

## 30. Package Contents
The package audit and all four independent consumers passed again in the complete `uekTHT` run. Tokens/Vue/spec npm tarballs were inspected; Flutter pub dry-run returned zero warnings and approximately 66 MB compressed; the release AAR had 267 inspected entries; Swift Sources were inspected. Flutter test/cache/report exclusions were added. A future candidate or version bump requires renewed checks; no registry upload was performed.

## 31. Compatibility
See COMPATIBILITY.md for current source-declared versions. Flutter's Dart constraint is stricter than its nominal Flutter minimum. Browser targets are build targets, not proof of minimum-browser runtime testing. Native artifact/toolchain combinations must be locked to the same candidate.

## 32. Migration
See [migration-to-2.0.md](migration-to-2.0.md). It covers observed imports, Composer name, voice bodies, header, bubble chrome, semantic theme and new typed content. Incomplete native mappings are explicitly identified.

## 33. Changelog
CHANGELOG.md and CHANGELOG.zh-CN.md now describe the unreleased 2.0 target, breaking body ownership changes, themes, accessibility, responsive work, release process and known limitations. They do not claim 2.0.0 was published.

## 34. Release Checklist
See [release-checklist.md](release-checklist.md). The order is source/spec -> generation -> tests/consumers -> package and runtime evidence -> zero P0/P1 -> version bump -> complete revalidation. The runner rejects readiness with any blocking matrix row or unresolved evidence.

## 35. P0/P1/P2/P3
Known open P0: 0 in the reviewed scope; this is not a comprehensive security certification. The unsafe Vue attribute-construction path was fixed and tested.

Release-blocking P1 groups:
1. Remaining duplicate consumer presentation and public semantic overlap.
2. Incomplete built-in rich/multi-image/reply/forward mappings.
3. Incomplete native media and business action integration.
4. Missing full real-consumer mobile/desktop interaction evidence.
5. Remaining automated native accessibility and general-control verification.
6. Unbounded/insufficiently tested animated media resource behavior.
7. Candidate-wide release verification and final API freeze.
8. Physical VoiceOver/TalkBack and hardware performance evidence (manual only).
9. Full authenticated consumer coverage is still incomplete despite successful real Web login, bidirectional desktop/mobile text and history recovery. This is remaining automation work, not a gateway failure or manual QA exemption.

P2/P3 polish can be deferred only when it does not affect normal IM flows, consistency, accessibility, API or release integrity. No such severity label is used to waive the P1 groups above.

### Design/Architecture Review Scores
Provisional engineering review scores, not measured coverage percentages or acceptance gates. Areas without final executable evidence cannot score as release-certified.

| Dimension | Score / 10 | Main Constraint |
| --- | --- | --- |
| Architecture | 7 | Remaining consumer ownership |
| Design Language | 7 | Native legacy fragments |
| Foundation | 8 | Generated themes pass; consumer adoption partial |
| General Components | 6 | Native control accessibility |
| Conversation | 7 | Consumer header/list remnants |
| Messages | 6 | Built-in mapping and duplicates |
| Composer | 7 | Native forms and advanced runtime paths |
| Contacts | 7 | Library exists; full runtime evidence missing |
| Groups | 7 | Library exists; full runtime evidence missing |
| Search | 7 | Native flow verification |
| Media | 5 | Host actions and resource bounds |
| Calls | 6 | Honest unavailable stub; RTC not certified |
| Workspaces | 7 | State contract versus actual flows |
| AppKit | 8 | Optional composition; native evidence incomplete |
| Flexibility | 7 | Override paths not all verified |
| Public API | 6 | Freeze review unresolved |
| Themes | 7 | Native theme facade adoption |
| Responsive | 6 | Full H5/native flows missing |
| Accessibility | 5 | Automatic and hardware evidence gaps |
| Performance | 6 | Candidate workloads/hardware traces |
| Vue | 8 | Runtime/public consolidation incomplete |
| Flutter | 6 | Local presentation and media gaps |
| Compose | 6 | Instrumentation and theme facade |
| SwiftUI | 6 | Runtime actions and accessibility |
| Website | 8 | Generated coverage versus live usage |
| Reference Apps | 6 | Ownership and feature gaps |
| Testing | 7 | Strong unit checks; E2E incomplete |
| Documentation | 7 | Honest closure docs; final freeze pending |
| Release Process | 7 | Fail-closed runner; unresolved gates |
| Maintainability | 7 | Canonical direction; old paths remain |
| Developer Experience | 7 | Independent package verification |
| Anti-AI Restraint | 8 | No cosmetic framework rewrite or decorative expansion |

## 36. Manual Verification Still Required
Only these hardware-dependent items are MANUAL_RELEASE_GATE:
- Physical iOS VoiceOver reading order, actions and announcements.
- Physical Android TalkBack reading order, actions and announcements.
- Representative iOS hardware performance traces.
- Representative Android hardware performance traces.

Large text, contrast, keyboard, reduced motion, simulator gestures and resource limits remain automatic work. They are tracked separately in spec/manual-evidence.json and are not excused as manual.

## 37. Final Release Decision
**FLARE_IM_UI_2_0_STABLE_NOT_READY**

The version remains 2.0.0-rc.1. Do not deploy, publish or label Stable based on this report. Resolve all automatic blockers, collect hardware evidence, run the complete release check, then bump and revalidate. No test result is substituted for missing runtime functionality.

## 38. Conversation Refinement and Preview Isolation
See [conversation-list-2.0-finalization.md](conversation-list-2.0-finalization.md) for the audit, state precedence, four-kit implementation, five-consumer adapters and evidence limits. This pass adds one canonical row anatomy, 999+ bounds, quiet muted unread, draft/typing/failure priority, stable pinned ordering, keyboard and touch actions, and removes native local conversation menu renderers. The SDK command ownership is unchanged.

Every multi-mode website component now renders in one isolated viewport. Desktop is 1024px and mobile is 390px, so both media queries and provider layout agree. The former dual-device demo wrapper is removed. The targeted browser run passed 62 cases including actual picker/long-press interactions and six-theme narrow-list checks; Vue row tests passed 75, Flutter conversation tests passed 77, Swift app tests passed with the same six explicit live-test skips, and Android app Kotlin compilation passed. These are scoped runs, not a fresh complete-candidate certificate.

The release runner now includes conversation-state-visual-check, conversation-reference-ownership-check and conversation-state-combination-check, plus negative ownership tests. A new full run is required after generation and all edits. The old uekTHT digest above no longer describes current source. Broader automatic/hardware blockers remain unchanged; no Stable marker or version bump is justified.

Rapid context-menu reuse exposed a closing-transition race that dropped the second action. The canonical row now destroys the closed menu before reopening; SDK tracing confirmed the missing action was at the UI boundary. Context metadata actions also no longer first open/mark-read the conversation. The live gate includes pin/unpin, unread/read and post-reload metadata assertions using isolated release accounts. Development HMR can interrupt an active live test, so candidate validation must run after source generation has finished. Final candidate logs, not this scoped result, determine release status.
