import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

const root = fileURLToPath(new URL('../../', import.meta.url));
const core = 'flare-im-core-client-sdk/examples';
const social = 'flare-social/flare-social-sdk/examples/apps';
const consumers = [
  [`${core}/flare-core-tauri-app/src/views/ChatView.vue`, /<EnhancedComposer\b/, /FlareComposer as EnhancedComposer/],
  [`${core}/flare-core-ios-app/Sources/FlareImApp/Features/Messaging/Composer/ComposerView.swift`, /FlareIMUI\.ComposerView\(/, /import FlareIMUI/],
  [`${core}/flare-core-android-app/app/src/main/kotlin/com/flare/im/app/features/messaging/composer/ComposerView.kt`, /com\.flare\.im\.ui\.Composer\(/, /com\.flare\.im\.ui/],
  [`${core}/flare-core-flutter-app/lib/interface/widgets/composer/message_composer.dart`, /return FlareComposer\(/, /package:flare_im_ui/],
  [`${social}/flare-social-web-app/src/components/ChatArea.vue`, /<FlareComposer\b/, /@flare-im\/vue-ui/],
  [`${social}/flare-social-tauri-app/src/components/chat/ChatPanel.vue`, /<(?:EnhancedComposer|enhanced-composer)\b/, /@flare-im\/vue-ui/],
  [`${social}/flare-social-ios-app/Sources/FlareSocialApp/ChatView.swift`, /ComposerView\(/, /import FlareIMUI/],
  [`${social}/flare-social-android-app/app/src/main/kotlin/com/flare/social/app/ChatScreen.kt`, /Composer\(/, /import com\.flare\.im\.ui\.Composer/],
  [`${social}/flare-social-flutter-app/lib/screens/chat_screen.dart`, /FlareComposer\(/, /package:flare_im_ui/],
];
let failed = false;
for (const [path, usage, dependency] of consumers) {
  const source = readFileSync(resolve(root, path), 'utf8');
  const ok = usage.test(source) && dependency.test(source);
  console.log(`${ok ? 'PASS' : 'FAIL'} ${path}`);
  failed ||= !ok;
}
// Main Core adapters must not own a second editor implementation. Business form inputs
// are deliberately outside this check; this is an architectural guard, not UI testing.
for (const [path] of consumers.filter(([path]) => path.includes('flare-core-') && !path.endsWith('.vue'))) {
  const source = readFileSync(resolve(root, path), 'utf8');
  const main = source.split('private fun ComposerFormDialog')[0];
  if (/\b(?:BasicTextField|ExtendedTextField|TextEditor|TextField)\s*\(/.test(main)) {
    console.error(`FAIL app-owned composer editor: ${path}`); failed = true;
  }
}
if (failed) process.exitCode = 1;
