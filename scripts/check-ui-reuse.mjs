// Architectural guard for migrated surfaces, not a substitute for interaction tests.
import { existsSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
const root = fileURLToPath(new URL('../../', import.meta.url));
const social = 'flare-social/flare-social-sdk/examples/apps';
let failures = 0;
function check(path, required, forbidden) {
  const source = readFileSync(resolve(root, path), 'utf8');
  const ok = required.every(pattern => pattern.test(source)) && !forbidden.test(source);
  console.log(`${ok ? 'PASS' : 'FAIL'} ${path}`);
  if (!ok) failures++;
}
for (const page of ['profile_center_screen', 'moments_screen', 'social_action_screens', 'base_shell']) {
  check(`${social}/flare-social-flutter-app/lib/screens/${page}.dart`, [/FlareButton\(/, /package:flare_im_ui/], /\b(?:FilledButton|OutlinedButton|TextButton|TextField|AlertDialog)\s*[.(]/);
}
for (const page of ['chat/ContactChatSettingsPanel', 'chat/GroupChatSettingsPanel', 'settings/AppSettingsDrawer']) {
  check(`${social}/flare-social-tauri-app/src/components/${page}.vue`, [/FlareSettingsRow/, /@flare-im\/vue-ui/], /SettingsToggleRow|SettingsMenuItem|settings-toggle-row|settings-menu-item/);
}
for (const page of ['FriendActionScreens', 'MomentsScreen']) {
  check(`${social}/flare-social-android-app/app/src/main/kotlin/com/flare/social/app/${page}.kt`, [/com\.flare\.im\.ui\.FormDialog/], /\b(?:AlertDialog|TextButton|OutlinedTextField)\s*\(/);
}
check(`${social}/flare-social-ios-app/Sources/FlareSocialApp/AuthView.swift`, [/InputView\(/, /FormFieldView\(/, /ButtonView\(/], /\b(?:TextField|SecureField|glassInput|fieldBackground)\s*\(/);
for (const app of ['web', 'tauri']) {
  check(`${social}/flare-social-${app}-app/src/components/ContactDetailPanel.vue`, [/FlareFormSheet/, /@flare-im\/vue-ui/], /contact-detail-panel__sheet-actions|<FlareBottomSheet/);
}
check(`${social}/flare-social-ios-app/Sources/FlareSocialApp/FriendActionViews.swift`, [/FormSheetView\(/, /InputView\(/], /TextEditor\(/);
for (const path of [
  `${social}/flare-social-tauri-app/src/components/settings/SettingsToggleRow.vue`,
  `${social}/flare-social-tauri-app/src/components/settings/SettingsMenuItem.vue`,
  `${social}/flare-social-android-app/app/src/main/kotlin/com/flare/social/app/UiHelpers.kt`,
]) {
  if (existsSync(resolve(root, path))) { console.error(`FAIL obsolete local UI: ${path}`); failures++; }
}
if (failures) process.exitCode = 1;
