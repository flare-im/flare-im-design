import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const fixture = JSON.parse(readFileSync(new URL('../spec/conversation-state-vectors.json', import.meta.url), 'utf8'));
assert.equal(fixture.cases.length, 72);
assert.equal(new Set(fixture.cases.map(item => item.id)).size, 72);
for (const item of fixture.cases) {
  const kind = item.failed ? 'failed' : item.draft.trim() ? 'draft' : item.typing ? 'typing' : item.mentioned ? 'mention' : 'normal';
  assert.equal(item.expectedKind, kind, item.id);
  assert.equal(item.expectedUnread, item.unreadCount > 999 ? '999+' : String(Math.max(0, item.unreadCount)), item.id);
  assert.equal(item.expectedEmphasis, item.unreadCount > 0 && !(item.muted && !item.mentioned) ? 'strong' : 'quiet', item.id);
}
const commands = [
  ['packages/vue-im-ui', 'npm', ['test', '--', 'FlareConversationRow.test.ts', '--maxWorkers=1']],
  ['packages/flutter-im-ui', 'flutter', ['test', '--no-pub', 'test/conversation_presentation_test.dart']],
  ['packages/ios-im-ui', 'swift', ['test', '--filter', 'ConversationPresentationTests']],
  ['packages/android-im-ui', './gradlew', ['testDebugUnitTest', '--tests', 'com.flare.im.ui.ConversationPresentationTest']],
];
for (const [directory, command, args] of commands) {
  console.log('\nConversation state contract: ' + directory);
  const result = spawnSync(command, args, { cwd: root + directory, stdio: 'inherit', timeout: 600000 });
  if (result.status !== 0) throw new Error(directory + ': state combination check failed (' + result.status + ')');
}
