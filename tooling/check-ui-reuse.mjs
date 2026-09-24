// Architectural guard for migrated surfaces, not a substitute for interaction tests.
import { existsSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
const root = fileURLToPath(new URL('../../', import.meta.url));
const social = 'flare-social/flare-social-sdk/examples/apps';
// Without the sibling checkout (a CI clone of this repository alone) the gate skips, like the
// reference-app consumer gate does.
if (!existsSync(resolve(root, social))) {
  console.log(`ui reuse skipped: no sibling checkout at ${social}`);
  process.exit(0);
}
let failures = 0;
let checked = 0;
function check(path, required, forbidden) {
  const source = readFileSync(resolve(root, path), 'utf8');
  checked++;
  const ok = required.every(pattern => pattern.test(source)) && !forbidden.test(source);
  console.log(`${ok ? 'PASS' : 'FAIL'} ${path}`);
  if (!ok) failures++;
}
for (const page of ['profile_center_screen', 'moments_screen', 'base_shell']) {
  check(`${social}/flare-social-flutter-app/lib/screens/${page}.dart`, [/FlareButton\(/, /package:flare_im_ui/], /\b(?:FilledButton|OutlinedButton|TextButton|TextField|AlertDialog)\s*[.(]/);
}
// The social action host now delegates whole contact/group/request/search surfaces to the kit, so
// it legitimately has no standalone button. Guard the high-level components instead of requiring a
// token FlareButton call that would reward adding redundant app-side chrome.
check(`${social}/flare-social-flutter-app/lib/screens/social_action_screens.dart`, [
  /FlareContactDetail\(/,
  /FlareGroupDetail\(/,
  /FlareNewFriendRequests\(/,
  /package:flare_im_ui/,
], /\b(?:FilledButton|OutlinedButton|TextButton|TextField|AlertDialog)\s*[.(]/);
for (const page of ['chat/ContactChatSettingsPanel', 'chat/GroupChatSettingsPanel', 'settings/AppSettingsDrawer']) {
  // Settings rows come from the kit, either one row at a time or as a whole settings list.
  check(`${social}/flare-social-tauri-app/src/components/${page}.vue`, [/FlareSettingsRow|FlareSettingsList/, /@flare-im\/vue-ui/], /SettingsToggleRow|SettingsMenuItem|settings-toggle-row|settings-menu-item/);
}
for (const page of ['FriendActionScreens', 'MomentsScreen']) {
  // A kit dialog surface: the FormDialog component, or the dialog presenter that replaced it for
  // screens that only need a prompt (`LocalFlareDialog.prompt`, Round 5).
  check(`${social}/flare-social-android-app/app/src/main/kotlin/com/flare/social/app/${page}.kt`, [/com\.flare\.im\.ui\.(?:FormDialog|LocalFlareDialog)/], /\b(?:AlertDialog|TextButton|OutlinedTextField)\s*\(/);
}
check(`${social}/flare-social-ios-app/Sources/FlareSocialApp/AuthView.swift`, [/InputView\(/, /FormFieldView\(/, /ButtonView\(/], /\b(?:TextField|SecureField|glassInput|fieldBackground)\s*\(/);
for (const app of ['web', 'tauri']) {
  check(`${social}/flare-social-${app}-app/src/components/ContactDetailPanel.vue`, [/FlareFormSheet/, /@flare-im\/vue-ui/], /contact-detail-panel__sheet-actions|<FlareBottomSheet/);
}
// Same rule as Android's: the form sheet component, or the kit presenter that replaced it for a
// single prompt (`FlareFeedback.prompt`) with the kit's own sheet.
check(`${social}/flare-social-ios-app/Sources/FlareSocialApp/FriendActionViews.swift`, [/FormSheetView\(|FlareFeedback\.prompt|flareBottomSheet/, /InputView\(/], /TextEditor\(/);
// FR-114: a message row answers to two ids — the one the list draws it with and the core's id for
// it — and locating a quoted message depends on the app filling the second one. Nothing else would
// catch its removal: the natives have no unit test target over their SDK adapters, and every gate
// stays green without it while a quote of your own message reads as "that message is gone".
for (const [app, file] of [
  ['flare-social-flutter-app', 'lib/sdk/im_client.dart'],
  ['flare-social-ios-app', 'Sources/FlareSocialApp/SocialSession.swift'],
  ['flare-social-android-app', 'app/src/main/kotlin/com/flare/social/app/SocialSession.kt'],
]) {
  check(`${social}/${app}/${file}`, [/FlareMessageData\(/, /serverId/], /$^/);
}

// B8: the trip a tapped quote takes when the message it names is not loaded — ask the list, read a page,
// ask again. All five apps had written it, with five different page budgets (48, 48, 24, 20, 5) and five
// different ideas about waiting for the list to draw the page it had just read. It is the kit's now, and
// an app that grows a sixth copy of the loop would pass every other gate.
for (const [app, file, wired] of [
  ['flare-social-web-app', 'src/components/ChatArea.vue', /flareLocateMessage\(/],
  ['flare-social-tauri-app', 'src/components/chat/ChatPanel.vue', /flareLocateMessage\(/],
  ['flare-social-flutter-app', 'lib/screens/chat_screen.dart', /flareLocateMessage\(/],
  ['flare-social-ios-app', 'Sources/FlareSocialApp/ChatView.swift', /FlareLocate\.run\(/],
  ['flare-social-android-app', 'app/src/main/kotlin/com/flare/social/app/ChatScreen.kt', /flareLocateMessage\(/],
]) {
  check(`${social}/${app}/${file}`, [wired], /$^/);
}

// B5: the swipe that starts a reply. The kits raise it; an app that does not take it has a gesture
// that does nothing, which looks exactly like a gesture that was never built. Only the Flutter app
// has a test that drags a row (`chat_screen_test`), so the other two need the gate.
for (const [app, file, wired] of [
  ['flare-social-flutter-app', 'lib/screens/chat_screen.dart', /onSwipeReply:/],
  ['flare-social-ios-app', 'Sources/FlareSocialApp/ChatView.swift', /onSwipeReply:/],
  ['flare-social-android-app', 'app/src/main/kotlin/com/flare/social/app/ChatScreen.kt', /onSwipeReply =/],
]) {
  check(`${social}/${app}/${file}`, [wired], /$^/);
}

// R7-B1: when to tell a conversation "I am typing". Five apps had written it and written it
// differently — the pause that ends typing was 3000, 2800, 1500, 1500 and, on iOS, never; two
// re-reported on every keystroke and two never refreshed the report at all, so a message longer
// than the peer's belief stopped showing as typing while it was still being typed. The rule is the
// kit's now (`FlareTypingSignal`, `spec/typing-vectors.json`); an app that grows a sixth timer
// passes every other gate, because a typing indicator that is wrong is not a typing indicator that
// is missing.
for (const [app, file, wired, forbidden] of [
  ['flare-social-web-app', 'src/components/ChatArea.vue', /new FlareTypingSignal\(/, /TYPING_IDLE_MS|TYPING_IDLE_STOP_MS/],
  ['flare-social-tauri-app', 'src/components/chat/ChatPanel.vue', /new FlareTypingSignal\(/, /TYPING_IDLE_MS|TYPING_IDLE_STOP_MS/],
  ['flare-social-flutter-app', 'lib/screens/chat_screen.dart', /FlareTypingSignal\(\)/, /_reportedTyping/],
  ['flare-social-ios-app', 'Sources/FlareSocialApp/SocialSession.swift', /FlareTypingSignal\(\)/, /$^/],
  ['flare-social-android-app', 'app/src/main/kotlin/com/flare/social/app/SocialSession.kt', /FlareTypingSignal\(\)/, /class TypingReporter/],
]) {
  check(`${social}/${app}/${file}`, [wired], forbidden);
}

// R7-B2: who is typing, the receiving half. Two apps had it, with two different expiries (6000 and
// 5000 ms) and two different sets of facts — the Tauri one only ever heard "someone started", so a
// server listing of who is typing did nothing — and three apps had never subscribed at all: they
// reported their own typing and could not see anyone else's. The rule is the kit's now
// (`FlareTypingRoster`), and an app that grows its own expiry timer passes every other gate.
for (const [app, file, wired, forbidden] of [
  ['flare-social-web-app', 'src/social/store.ts', /new FlareTypingRoster\(/, /TYPING_TTL_MS|function reduceTyping/],
  ['flare-social-tauri-app', 'src/components/chat/ChatPanel.vue', /new FlareTypingRoster\(/, /TYPING_EXPIRE_MS|typingExpireTimers/],
  ['flare-social-flutter-app', 'lib/viewmodels/conversation_signals.dart', /FlareTypingRoster\(/, /$^/],
  ['flare-social-ios-app', 'Sources/FlareSocialApp/SocialSession.swift', /FlareTypingRoster\(/, /$^/],
  ['flare-social-android-app', 'app/src/main/kotlin/com/flare/social/app/SocialSession.kt', /FlareTypingRoster\(/, /$^/],
]) {
  check(`${social}/${app}/${file}`, [wired], forbidden);
}

// An ephemeral signal is not "the local store changed". All three native apps re-read the conversation
// list on every SDK event, typing included — several times a sentence, per peer, for nothing. Each now
// knows which codes are signals about people; losing that means the reload comes back silently.
for (const [app, file, wired] of [
  ['flare-social-web-app', 'src/social/store.ts', /EPHEMERAL_CHANNELS/],
  ['flare-social-flutter-app', 'lib/viewmodels/conversation_signals.dart', /FlareSocialEventCode\.isEphemeral\(/],
  ['flare-social-ios-app', 'Sources/FlareSocialApp/SocialSession.swift', /EventCode\.isEphemeral\(/],
  ['flare-social-android-app', 'app/src/main/kotlin/com/flare/social/app/SocialSession.kt', /isEphemeralEvent\(/],
]) {
  check(`${social}/${app}/${file}`, [wired], /$^/);
}

// R7-B3: presence. Three apps never showed it at all — the Flutter app had no presence code of any
// kind, the iOS app only ever passed `showPresence: false`, and the Android app had the facade and
// never called it. The kit has drawn the dot on four platforms for rounds; nothing fed it.
for (const [app, file, wired] of [
  ['flare-social-web-app', 'src/social/store.ts', /refreshPresenceFor\(/],
  ['flare-social-tauri-app', 'src/components/chat/ChatPanel.vue', /syncPresenceSubscriptions\(/],
  ['flare-social-flutter-app', 'lib/sdk/base_social_client.dart', /presence\.batchGet\(/],
  ['flare-social-ios-app', 'Sources/FlareSocialApp/SocialSession.swift', /sdk\.presence\.batchGet\(/],
  ['flare-social-android-app', 'app/src/main/kotlin/com/flare/social/app/SocialSession.kt', /sdk\.presence\.batchGet\(/],
]) {
  check(`${social}/${app}/${file}`, [wired], /$^/);
}

// And the conversation rows that must carry it. A presence nobody could look up must stay absent, so
// each of these feeds the row only when it knows: the kit draws no dot for an absent presence, which is
// what "unknown" looks like. Reading a failed lookup as 离线 puts a false state in front of a reader.
for (const [app, file, wired] of [
  ['flare-social-web-app', 'src/social/store.ts', /presenceByUser\.get\(/],
  ['flare-social-tauri-app', 'src/components/chat/ChatPanel.vue', /presenceByPeerForRows/],
  ['flare-social-flutter-app', 'lib/screens/base_shell.dart', /presence: c\.isGroup \? null : _signals\.presenceOf\(/],
  ['flare-social-ios-app', 'Sources/FlareSocialApp/ConversationsView.swift', /presence: session\.presenceFor\(/],
  ['flare-social-android-app', 'app/src/main/kotlin/com/flare/social/app/ConversationsScreen.kt', /session\.presenceFor\(/],
]) {
  check(`${social}/${app}/${file}`, [wired], /$^/);
}

// R7-B4: drafts. "Draft" meant four different lifetimes: the web app wrote to the core (so it roamed),
// the Tauri app to localStorage (so it survived a restart on that machine), the Android app to a map in
// memory (so it survived switching conversations), and the Flutter and iOS apps did not save at all.
// The rule is the kit's now (`FlareDraftAutosave`) and the store is the core for all five.
for (const [app, file, wired, forbidden] of [
  ['flare-social-web-app', 'src/components/ChatArea.vue', /new FlareDraftAutosave\(/, /DRAFT_SAVE_DELAY_MS/],
  ['flare-social-tauri-app', 'src/host/chat/composables/useSessionDrafts.ts', /new FlareDraftAutosave\(/, /DRAFT_SAVE_DEBOUNCE_MS|SessionDraftsToStorage/],
  ['flare-social-flutter-app', 'lib/viewmodels/conversation_signals.dart', /FlareDraftAutosave\(\)/, /$^/],
  ['flare-social-ios-app', 'Sources/FlareSocialApp/SocialSession.swift', /FlareDraftAutosave\(\)/, /$^/],
  ['flare-social-android-app', 'app/src/main/kotlin/com/flare/social/app/SocialSession.kt', /FlareDraftAutosave\(\)/, /$^/],
]) {
  check(`${social}/${app}/${file}`, [wired], forbidden);
}

// And the write that makes a draft roam. Without it a draft is a note to this device, which is what four
// of the five were: the core op has existed since the beginning and only the web app ever called it.
for (const [app, file, wired] of [
  ['flare-social-web-app', 'src/social/sdk.ts', /conversations\.updateDraft\(/],
  ['flare-social-tauri-app', 'src/flare-sdk/api/conversation.ts', /sdkConversationUpdateDraft/],
  ['flare-social-flutter-app', 'lib/sdk/base_social_client.dart', /conversations\.updateDraft\(/],
  ['flare-social-ios-app', 'Sources/FlareSocialApp/SocialSession.swift', /sdk\.conversations\.updateDraft\(/],
  ['flare-social-android-app', 'app/src/main/kotlin/com/flare/social/app/SocialSession.kt', /sdk\.conversations\.updateDraft\(/],
]) {
  check(`${social}/${app}/${file}`, [wired], /$^/);
}

// R8-B2: what a client owes the server when the connection comes back. A gap is not a pause — a belief
// formed before it may be stale, a presence stream dies with the socket that carried it, and a change
// that happened during the gap was never delivered — and all five apps were treating it as one: they
// subscribed and read when the list loaded and when a chat opened, and a reconnect is neither.
for (const [app, file, wired] of [
  ['flare-social-web-app', 'src/social/store.ts', /new FlareConnectionRefresh\(/],
  ['flare-social-tauri-app', 'src/components/chat/ChatPanel.vue', /new FlareConnectionRefresh\(/],
  ['flare-social-flutter-app', 'lib/screens/base_shell.dart', /FlareConnectionRefresh\(\)/],
  ['flare-social-ios-app', 'Sources/FlareSocialApp/SocialSession.swift', /FlareConnectionRefresh\(\)/],
  ['flare-social-android-app', 'app/src/main/kotlin/com/flare/social/app/SocialSession.kt', /FlareConnectionRefresh\(\)/],
]) {
  check(`${social}/${app}/${file}`, [wired], /$^/);
}

// The screens that must hand the person's own edits to that rule. `onUserInput` (Vue `user-input`)
// is the kit's "the person typed" seam: a host that drives typing from the controlled value instead
// reports its own housekeeping — restoring a failed send's text into the composer, for one — as
// someone typing.
for (const [app, file, wired] of [
  ['flare-social-web-app', 'src/components/ChatArea.vue', /@user-input="onUserInput"/],
  ['flare-social-tauri-app', 'src/components/chat/ChatPanel.vue', /@user-input="onComposerUserInput"/],
  ['flare-social-flutter-app', 'lib/screens/chat_screen.dart', /onTyping: _onTyping/],
  ['flare-social-ios-app', 'Sources/FlareSocialApp/ChatView.swift', /onUserInput: \{/],
  ['flare-social-android-app', 'app/src/main/kotlin/com/flare/social/app/ChatScreen.kt', /onUserInput = \{/],
]) {
  check(`${social}/${app}/${file}`, [wired], /$^/);
}

// R9 (FR-095): the shell measures its own box, keeps every tab it has shown, and decides when the phone navigation
// steps aside. All five apps had been doing one or more of the three themselves — a window listener, a
// GeometryReader, a LayoutBuilder or a BoxWithConstraints to resolve the mode; a KeepAlive or an opacity ZStack to
// keep tabs; a boolean formula, or a "secondary page" flag threaded up from every tab, to hide the bottom
// navigation — and each of those still compiles beside the kit's own answer.
const shellWork = /resolveApplicationResponsiveMode\s*\(|flareApplicationResponsiveModeForWidth\s*\(|useResponsiveMode\s*\(|hideMobileNavigation|<KeepAlive|IndexedStack\s*\(|tabRoot\s*\(|\bimmersive\b|emit\(\s*["']secondary["']/;
for (const [app, file, wired] of [
  ['flare-social-web-app', 'src/views/MainView.vue', /#destination="\{ id, active \}"/],
  ['flare-social-web-app', 'src/components/ContactsTab.vue', /<FlareScreen/],
  ['flare-social-web-app', 'src/components/MomentsTab.vue', /<FlareScreen/],
  ['flare-social-web-app', 'src/components/MeTab.vue', /<FlareScreen/],
  ['flare-social-tauri-app', 'src/views/Main.vue', /#destination="\{ id \}"/],
  ['flare-social-tauri-app', 'src/components/chat/ChatPanel.vue', /@layout-change="onWorkspaceLayout"/],
  ['flare-social-flutter-app', 'lib/screens/base_shell.dart', /destinationBuilder: _destination/],
  ['flare-social-ios-app', 'Sources/FlareSocialApp/MainShell.swift', /IMAppKitView\(groups: groups, activeID: tab, onNavigate:/],
  ['flare-social-ios-app', 'Sources/FlareSocialApp/ConversationsView.swift', /\.flareDestinationDepth\(!path\.isEmpty\)/],
  ['flare-social-android-app', 'app/src/main/kotlin/com/flare/social/app/FlareSocialApp.kt', /onNavigate = \{ tab = it \},\s*\) \{ id ->/],
]) {
  check(`${social}/${app}/${file}`, [wired], shellWork);
}

for (const path of [
  `${social}/flare-social-web-app/src/host/responsive.ts`,
  `${social}/flare-social-tauri-app/src/utils/responsiveMode.ts`,
  `${social}/flare-social-tauri-app/src/components/settings/SettingsToggleRow.vue`,
  `${social}/flare-social-tauri-app/src/components/settings/SettingsMenuItem.vue`,
  `${social}/flare-social-android-app/app/src/main/kotlin/com/flare/social/app/UiHelpers.kt`,
]) {
  if (existsSync(resolve(root, path))) { console.error(`FAIL obsolete local UI: ${path}`); failures++; }
}
if (failures) process.exitCode = 1;
else console.log(`ui reuse passed: ${checked} migrated app surfaces compose kit components`);
